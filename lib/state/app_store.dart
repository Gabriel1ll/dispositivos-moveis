import 'package:signals/signals_flutter.dart';

import '../data/categoria_repository.dart';
import '../data/despesa_repository.dart';
import '../models/categoria.dart';
import '../models/despesa.dart';

/// Estado global do app, construído com Flutter Signals.
///
/// Organização:
///  * **Signals de origem** (`signal`): o estado "bruto" que muda por ação do
///    usuário: listas carregadas do banco, mês selecionado e filtro.
///  * **Signals derivados** (`computed`): valores calculados a partir dos de
///    origem. São recalculados sozinhos, e só quando uma dependência muda.
///    Ninguém precisa lembrar de "atualizar o total" depois de salvar uma
///    despesa: basta trocar a lista e todos os totais se ajustam.
///  * **Ações** (métodos `Future`): gravam no SQLite através dos repositórios
///    e depois atualizam os signals. O banco é a fonte da verdade; os signals
///    são a cópia em memória que a interface observa.
class AppStore {
  AppStore({required this.categoriaRepo, required this.despesaRepo});

  final CategoriaRepository categoriaRepo;
  final DespesaRepository despesaRepo;

  // ---------------------------------------------------------------------------
  // Signals de origem
  // ---------------------------------------------------------------------------

  /// Todas as categorias, ordenadas por nome.
  final categorias = signal<List<Categoria>>(const []);

  /// Todas as despesas (de todos os meses), da mais recente para a mais antiga.
  final despesas = signal<List<Despesa>>(const []);

  /// Mês exibido nas abas "Despesas" e "Resumo" (sempre no dia 1).
  final mesSelecionado = signal<DateTime>(_inicioDoMes(DateTime.now()));

  /// Filtro opcional por categoria na aba "Despesas". `null` = todas.
  final filtroCategoriaId = signal<int?>(null);

  // ---------------------------------------------------------------------------
  // Signals derivados
  // ---------------------------------------------------------------------------

  /// Busca rápida de categoria pelo id.
  late final categoriaPorId = computed<Map<int, Categoria>>(() {
    return {for (final c in categorias.value) c.id!: c};
  });

  /// Despesas do mês selecionado.
  late final despesasDoMes = computed<List<Despesa>>(() {
    final mes = mesSelecionado.value;
    return despesas.value
        .where((d) => d.data.year == mes.year && d.data.month == mes.month)
        .toList();
  });

  /// O que aparece na lista: despesas do mês, aplicando o filtro de categoria.
  late final despesasVisiveis = computed<List<Despesa>>(() {
    final filtro = filtroCategoriaId.value;
    final doMes = despesasDoMes.value;
    if (filtro == null) return doMes;
    return doMes.where((d) => d.categoriaId == filtro).toList();
  });

  /// Soma das despesas visíveis (respeita o filtro).
  late final totalVisivel = computed<int>(() {
    return _somar(despesasVisiveis.value);
  });

  /// Soma de todas as despesas do mês.
  late final totalDoMes = computed<int>(() => _somar(despesasDoMes.value));

  /// Quanto foi gasto em cada categoria no mês selecionado (id -> centavos).
  late final totalPorCategoria = computed<Map<int, int>>(() {
    final totais = <int, int>{};
    for (final d in despesasDoMes.value) {
      totais.update(
        d.categoriaId,
        (atual) => atual + d.valorCentavos,
        ifAbsent: () => d.valorCentavos,
      );
    }
    return totais;
  });

  /// Quantas despesas cada categoria tem no total (todos os meses).
  /// Usado para avisar o usuário antes de excluir uma categoria.
  late final quantidadePorCategoria = computed<Map<int, int>>(() {
    final quantidades = <int, int>{};
    for (final d in despesas.value) {
      quantidades.update(d.categoriaId, (q) => q + 1, ifAbsent: () => 1);
    }
    return quantidades;
  });

  /// Soma dos orçamentos mensais de todas as categorias.
  late final orcamentoTotal = computed<int>(() {
    return categorias.value.fold<int>(0, (s, c) => s + c.orcamentoCentavos);
  });

  /// Categorias que passaram do orçamento no mês selecionado.
  late final categoriasEstouradas = computed<List<Categoria>>(() {
    final totais = totalPorCategoria.value;
    return categorias.value
        .where((c) => c.temOrcamento && (totais[c.id] ?? 0) > c.orcamentoCentavos)
        .toList();
  });

  /// Maior despesa do mês selecionado (ou `null` se não houver).
  late final maiorDespesa = computed<Despesa?>(() {
    final lista = despesasDoMes.value;
    if (lista.isEmpty) return null;
    return lista.reduce((a, b) => a.valorCentavos >= b.valorCentavos ? a : b);
  });

  /// Média gasta por dia no mês selecionado.
  /// No mês atual divide pelos dias já passados; nos outros, pelos dias do mês.
  late final mediaDiaria = computed<int>(() {
    final mes = mesSelecionado.value;
    final hoje = DateTime.now();
    final diasNoMes = DateTime(mes.year, mes.month + 1, 0).day;
    final ehMesAtual = mes.year == hoje.year && mes.month == hoje.month;
    final dias = ehMesAtual ? hoje.day : diasNoMes;
    return (totalDoMes.value / dias).round();
  });

  // ---------------------------------------------------------------------------
  // Ações: carregamento
  // ---------------------------------------------------------------------------

  Future<void> carregar() async {
    final cats = await categoriaRepo.listar();
    final desps = await despesaRepo.listar();
    // batch: as duas atualizações viram UMA notificação, então a interface
    // reconstrói uma vez só, sem passar por um estado "meio carregado".
    batch(() {
      categorias.value = _ordenarCategorias(cats);
      despesas.value = _ordenarDespesas(desps);
    });
  }

  // ---------------------------------------------------------------------------
  // Ações: CRUD de categorias
  // ---------------------------------------------------------------------------

  /// Cria (se `id == null`) ou atualiza uma categoria.
  Future<void> salvarCategoria(Categoria categoria) async {
    if (categoria.id == null) {
      final nova = await categoriaRepo.inserir(categoria);
      categorias.value = _ordenarCategorias([...categorias.value, nova]);
    } else {
      await categoriaRepo.atualizar(categoria);
      categorias.value = _ordenarCategorias([
        for (final c in categorias.value) c.id == categoria.id ? categoria : c,
      ]);
    }
  }

  /// Exclui a categoria e, junto, todas as despesas dela.
  Future<void> removerCategoria(int id) async {
    await categoriaRepo.remover(id); // o banco apaga as despesas (CASCADE)
    batch(() {
      categorias.value = categorias.value.where((c) => c.id != id).toList();
      despesas.value = despesas.value.where((d) => d.categoriaId != id).toList();
      if (filtroCategoriaId.value == id) filtroCategoriaId.value = null;
    });
  }

  /// Verifica se já existe outra categoria com o mesmo nome.
  bool nomeDeCategoriaEmUso(String nome, {int? ignorarId}) {
    final alvo = nome.trim().toLowerCase();
    return categorias.value.any(
      (c) => c.id != ignorarId && c.nome.trim().toLowerCase() == alvo,
    );
  }

  // ---------------------------------------------------------------------------
  // Ações: CRUD de despesas
  // ---------------------------------------------------------------------------

  /// Cria (se `id == null`) ou atualiza uma despesa.
  Future<void> salvarDespesa(Despesa despesa) async {
    if (despesa.id == null) {
      final nova = await despesaRepo.inserir(despesa);
      despesas.value = _ordenarDespesas([...despesas.value, nova]);
    } else {
      await despesaRepo.atualizar(despesa);
      despesas.value = _ordenarDespesas([
        for (final d in despesas.value) d.id == despesa.id ? despesa : d,
      ]);
    }
  }

  /// Exclui uma despesa com **atualização otimista**: tira da tela na hora e
  /// depois grava no banco. Se o banco falhar, a lista volta ao que era.
  ///
  /// Precisa ser assim porque o `Dismissible` (deslizar para excluir) exige
  /// que o item saia da lista imediatamente.
  Future<void> removerDespesa(int id) async {
    final anterior = despesas.value;
    despesas.value = anterior.where((d) => d.id != id).toList();
    try {
      await despesaRepo.remover(id);
    } catch (_) {
      despesas.value = anterior;
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Ações: navegação e filtro
  // ---------------------------------------------------------------------------

  /// Avança (`+1`) ou volta (`-1`) o mês exibido.
  void mudarMes(int delta) {
    final atual = mesSelecionado.value;
    // DateTime ajusta sozinho: mês 13 vira janeiro do ano seguinte.
    mesSelecionado.value = DateTime(atual.year, atual.month + delta);
  }

  void irParaMes(DateTime data) {
    mesSelecionado.value = _inicioDoMes(data);
  }

  /// Seleciona o filtro; tocar de novo no mesmo filtro remove a seleção.
  void alternarFiltro(int? categoriaId) {
    filtroCategoriaId.value =
        filtroCategoriaId.value == categoriaId ? null : categoriaId;
  }

  // ---------------------------------------------------------------------------
  // Auxiliares
  // ---------------------------------------------------------------------------

  static DateTime _inicioDoMes(DateTime d) => DateTime(d.year, d.month);

  static int _somar(List<Despesa> lista) =>
      lista.fold<int>(0, (soma, d) => soma + d.valorCentavos);

  static List<Categoria> _ordenarCategorias(List<Categoria> lista) {
    return [...lista]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  static List<Despesa> _ordenarDespesas(List<Despesa> lista) {
    return [...lista]
      ..sort((a, b) {
        final porData = b.data.compareTo(a.data);
        if (porData != 0) return porData;
        return (b.id ?? 0).compareTo(a.id ?? 0);
      });
  }
}
