import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../models/categoria.dart';
import '../models/despesa.dart';
import '../state/store_scope.dart';
import '../util/formatadores.dart';
import '../widgets/seletor_mes.dart';

/// Aba "Resumo": só leitura, feita inteiramente de signals `computed`.
///
/// Nenhum número aqui é calculado na tela: total, orçamento, média, maior
/// despesa e ranking vêm prontos do store e se atualizam sozinhos.
class ResumoScreen extends StatelessWidget {
  const ResumoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SeletorMes(),
          // Os `.value` são lidos dentro de cada builder (é isso que inscreve
          // o SignalBuilder) e passados prontos para os widgets filhos.
          SignalBuilder(
            builder: (context) => _Indicadores(
              total: store.totalDoMes.value,
              orcamento: store.orcamentoTotal.value,
              mediaDiaria: store.mediaDiaria.value,
              maior: store.maiorDespesa.value,
            ),
          ),
          SignalBuilder(
            builder: (context) =>
                _Alertas(estouradas: store.categoriasEstouradas.value),
          ),
          SignalBuilder(
            builder: (context) => _PorCategoria(
              total: store.totalDoMes.value,
              totais: store.totalPorCategoria.value,
              categorias: store.categorias.value,
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicadores extends StatelessWidget {
  const _Indicadores({
    required this.total,
    required this.orcamento,
    required this.mediaDiaria,
    required this.maior,
  });

  final int total;
  final int orcamento;
  final int mediaDiaria;
  final Despesa? maior;

  @override
  Widget build(BuildContext context) {
    final saldo = orcamento - total;
    final maior = this.maior;
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              _Indicador(titulo: 'Gasto no mês', valor: formatarMoeda(total)),
              _Indicador(
                titulo: 'Orçamento',
                valor: orcamento == 0 ? '—' : formatarMoeda(orcamento),
              ),
            ],
          ),
          Row(
            children: [
              _Indicador(
                titulo: saldo >= 0 ? 'Ainda pode gastar' : 'Passou do orçamento',
                valor: orcamento == 0 ? '—' : formatarMoeda(saldo.abs()),
                cor: saldo < 0 ? tema.colorScheme.error : null,
              ),
              _Indicador(
                titulo: 'Média por dia',
                valor: formatarMoeda(mediaDiaria),
              ),
            ],
          ),
          if (maior != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Maior despesa'),
                subtitle: Text('${maior.descricao} · ${formatarData(maior.data)}'),
                trailing: Text(
                  formatarMoeda(maior.valorCentavos),
                  style: tema.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({required this.titulo, required this.valor, this.cor});

  final String titulo;
  final String valor;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: tema.textTheme.labelMedium),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valor,
                  style: tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Alertas extends StatelessWidget {
  const _Alertas({required this.estouradas});

  final List<Categoria> estouradas;

  @override
  Widget build(BuildContext context) {
    if (estouradas.isEmpty) return const SizedBox.shrink();
    final tema = Theme.of(context);
    final nomes = estouradas.map((c) => c.nome).join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        color: tema.colorScheme.errorContainer,
        child: ListTile(
          leading: Icon(
            Icons.warning_amber_rounded,
            color: tema.colorScheme.onErrorContainer,
          ),
          title: Text(
            estouradas.length == 1
                ? 'Orçamento estourado'
                : '${estouradas.length} orçamentos estourados',
            style: TextStyle(color: tema.colorScheme.onErrorContainer),
          ),
          subtitle: Text(
            nomes,
            style: TextStyle(color: tema.colorScheme.onErrorContainer),
          ),
        ),
      ),
    );
  }
}

class _PorCategoria extends StatelessWidget {
  const _PorCategoria({
    required this.total,
    required this.totais,
    required this.categorias,
  });

  final int total;
  final Map<int, int> totais;
  final List<Categoria> categorias;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    // Só categorias com gasto no mês, da maior para a menor.
    final ranking = <(Categoria, int)>[
      for (final c in categorias)
        if ((totais[c.id] ?? 0) > 0) (c, totais[c.id]!),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gastos por categoria', style: tema.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (ranking.isEmpty)
            Text(
              'Sem despesas neste mês.',
              style: TextStyle(color: tema.colorScheme.outline),
            ),
          for (final (categoria, valor) in ranking)
            _BarraCategoria(
              categoria: categoria,
              valor: valor,
              proporcao: total == 0 ? 0.0 : valor / total,
            ),
        ],
      ),
    );
  }
}

class _BarraCategoria extends StatelessWidget {
  const _BarraCategoria({
    required this.categoria,
    required this.valor,
    required this.proporcao,
  });

  final Categoria categoria;
  final int valor;
  final double proporcao;

  @override
  Widget build(BuildContext context) {
    final cor = Color(categoria.cor);
    final pct = (proporcao * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 6, backgroundColor: cor),
              const SizedBox(width: 8),
              Expanded(child: Text(categoria.nome)),
              Text('${formatarMoeda(valor)}  ($pct%)'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: proporcao,
              minHeight: 10,
              color: cor,
              backgroundColor: cor.withAlpha(40),
            ),
          ),
        ],
      ),
    );
  }
}
