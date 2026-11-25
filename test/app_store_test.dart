import 'package:cofrinho/models/categoria.dart';
import 'package:cofrinho/models/despesa.dart';
import 'package:cofrinho/state/app_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeCategoriaRepository categoriasRepo;
  late FakeDespesaRepository despesasRepo;
  late AppStore store;

  const mercado = Categoria(
    id: 1,
    nome: 'Mercado',
    cor: 0xFF2E7D32,
    orcamentoCentavos: 10000, // R$ 100,00
  );
  const lazer = Categoria(id: 2, nome: 'Lazer', cor: 0xFF6A1B9A);

  setUp(() async {
    categoriasRepo = FakeCategoriaRepository([mercado, lazer]);
    despesasRepo = FakeDespesaRepository([
      Despesa(
        id: 1,
        descricao: 'Feira',
        valorCentavos: 6000,
        data: DateTime(2026, 11, 3),
        categoriaId: 1,
      ),
      Despesa(
        id: 2,
        descricao: 'Supermercado',
        valorCentavos: 5000,
        data: DateTime(2026, 11, 10),
        categoriaId: 1,
      ),
      Despesa(
        id: 3,
        descricao: 'Cinema',
        valorCentavos: 3000,
        data: DateTime(2026, 11, 12),
        categoriaId: 2,
      ),
      Despesa(
        id: 4,
        descricao: 'Show',
        valorCentavos: 2800,
        data: DateTime(2026, 2, 20),
        categoriaId: 2,
      ),
    ]);
    categoriasRepo.despesas = despesasRepo;

    store = AppStore(categoriaRepo: categoriasRepo, despesaRepo: despesasRepo);
    await store.carregar();
    store.irParaMes(DateTime(2026, 11));
  });

  test('carrega categorias em ordem alfabética', () {
    expect(store.categorias.value.map((c) => c.nome), ['Lazer', 'Mercado']);
  });

  test('computeds do mês: total, por categoria e maior despesa', () {
    expect(store.despesasDoMes.value.length, 3);
    expect(store.totalDoMes.value, 14000);
    expect(store.totalPorCategoria.value, {1: 11000, 2: 3000});
    expect(store.maiorDespesa.value?.descricao, 'Feira');
  });

  test('despesas ficam da mais recente para a mais antiga', () {
    expect(
      store.despesasDoMes.value.map((d) => d.descricao),
      ['Cinema', 'Supermercado', 'Feira'],
    );
  });

  test('trocar o mês recalcula tudo sozinho', () {
    store.irParaMes(DateTime(2026, 2));
    expect(store.totalDoMes.value, 2800);
    expect(store.maiorDespesa.value?.descricao, 'Show');
    // fevereiro/2026 tem 28 dias: 2800 / 28 = 100
    expect(store.mediaDiaria.value, 100);

    store.mudarMes(-3); // novembro/2025
    expect(store.despesasDoMes.value, isEmpty);
    expect(store.maiorDespesa.value, isNull);
  });

  test('mudarMes atravessa a virada de ano', () {
    store.irParaMes(DateTime(2026, 12));
    store.mudarMes(1);
    expect(store.mesSelecionado.value, DateTime(2027, 1));
  });

  test('filtro por categoria afeta só a lista visível', () {
    store.alternarFiltro(2);
    expect(store.despesasVisiveis.value.map((d) => d.descricao), ['Cinema']);
    expect(store.totalVisivel.value, 3000);
    expect(store.totalDoMes.value, 14000); // o total do mês não muda

    store.alternarFiltro(2); // tocar de novo remove o filtro
    expect(store.filtroCategoriaId.value, isNull);
  });

  test('orçamento estourado é detectado', () {
    // Mercado: gastou 110,00 de 100,00
    expect(store.categoriasEstouradas.value.map((c) => c.nome), ['Mercado']);
  });

  test('CRUD de despesa atualiza os computeds', () async {
    await store.salvarDespesa(Despesa(
      descricao: 'Pipoca',
      valorCentavos: 1500,
      data: DateTime(2026, 11, 12),
      categoriaId: 2,
    ));
    expect(store.totalDoMes.value, 15500);
    expect(despesasRepo.dados.length, 5);

    final pipoca =
        store.despesas.value.firstWhere((d) => d.descricao == 'Pipoca');
    await store.salvarDespesa(pipoca.copyWith(valorCentavos: 2000));
    expect(store.totalPorCategoria.value[2], 5000);

    await store.removerDespesa(pipoca.id!);
    expect(store.totalDoMes.value, 14000);
    expect(despesasRepo.dados.containsKey(pipoca.id), isFalse);
  });

  test('remover despesa desfaz a mudança se o banco falhar', () async {
    despesasRepo.falharAoRemover = true;
    await expectLater(store.removerDespesa(1), throwsException);
    expect(store.despesas.value.length, 4);
  });

  test('CRUD de categoria', () async {
    await store.salvarCategoria(
      const Categoria(nome: 'Academia', cor: 0xFF1565C0),
    );
    expect(store.categorias.value.map((c) => c.nome),
        ['Academia', 'Lazer', 'Mercado']);

    await store.salvarCategoria(mercado.copyWith(orcamentoCentavos: 20000));
    expect(store.orcamentoTotal.value, 20000);
    expect(store.categoriasEstouradas.value, isEmpty);
  });

  test('excluir categoria leva junto as despesas dela', () async {
    store.alternarFiltro(1);
    await store.removerCategoria(1);

    expect(store.categorias.value.map((c) => c.nome), ['Lazer']);
    expect(store.despesas.value.every((d) => d.categoriaId == 2), isTrue);
    expect(store.filtroCategoriaId.value, isNull);
    expect(despesasRepo.dados.values.any((d) => d.categoriaId == 1), isFalse);
  });

  test('nome de categoria repetido é detectado', () {
    expect(store.nomeDeCategoriaEmUso('  mercado '), isTrue);
    expect(store.nomeDeCategoriaEmUso('Mercado', ignorarId: 1), isFalse);
    expect(store.nomeDeCategoriaEmUso('Viagem'), isFalse);
  });
}
