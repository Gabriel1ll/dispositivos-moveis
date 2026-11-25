import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../models/categoria.dart';
import '../models/despesa.dart';
import '../state/app_store.dart';
import '../state/store_scope.dart';
import '../util/formatadores.dart';
import '../widgets/dialogos.dart';
import '../widgets/seletor_mes.dart';
import 'despesa_form_screen.dart';

/// Aba "Despesas": READ (lista) + DELETE (deslizar) do CRUD de despesas.
/// CREATE pelo botão "+" e UPDATE tocando num item.
class DespesasScreen extends StatelessWidget {
  const DespesasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Despesas')),
      floatingActionButton: FloatingActionButton.extended(
        // Hero tags diferentes: as abas ficam vivas no IndexedStack e dois
        // FABs com a mesma tag quebrariam a animação de navegação.
        heroTag: 'fab-despesas',
        onPressed: () => abrirFormularioDespesa(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova despesa'),
      ),
      body: Column(
        children: [
          const SeletorMes(),
          // Cada SignalBuilder reconstrói só o seu pedaço da tela.
          //
          // IMPORTANTE: o SignalBuilder só "enxerga" os signals lidos DENTRO
          // da função builder. Por isso os `.value` são lidos aqui e passados
          // prontos para os widgets filhos, que apenas desenham.
          SignalBuilder(
            builder: (context) {
              final filtroId = store.filtroCategoriaId.value;
              final categoria = filtroId == null
                  ? null
                  : store.categoriaPorId.value[filtroId];
              return _CartaoTotal(
                titulo: categoria == null
                    ? 'Total do mês'
                    : 'Total em ${categoria.nome}',
                total: store.totalVisivel.value,
                quantidade: store.despesasVisiveis.value.length,
              );
            },
          ),
          SignalBuilder(
            builder: (context) => _FiltroCategorias(
              categorias: store.categorias.value,
              filtroId: store.filtroCategoriaId.value,
              onSelecionar: store.alternarFiltro,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SignalBuilder(
              builder: (context) => _ListaDespesas(
                despesas: store.despesasVisiveis.value,
                categorias: store.categoriaPorId.value,
                store: store,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre o formulário. Sem `despesa` = criar; com `despesa` = editar.
Future<void> abrirFormularioDespesa(
  BuildContext context, {
  Despesa? despesa,
}) async {
  final store = StoreScope.read(context);
  if (store.categorias.value.isEmpty) {
    mostrarMensagem(context, 'Crie uma categoria antes de lançar despesas.');
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DespesaFormScreen(despesa: despesa),
    ),
  );
}

class _CartaoTotal extends StatelessWidget {
  const _CartaoTotal({
    required this.titulo,
    required this.total,
    required this.quantidade,
  });

  final String titulo;
  final int total;
  final int quantidade;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: tema.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: tema.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    formatarMoeda(total),
                    style: tema.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Text(
              quantidade == 1 ? '1 despesa' : '$quantidade despesas',
              style: tema.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltroCategorias extends StatelessWidget {
  const _FiltroCategorias({
    required this.categorias,
    required this.filtroId,
    required this.onSelecionar,
  });

  final List<Categoria> categorias;
  final int? filtroId;
  final void Function(int? categoriaId) onSelecionar;

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('Todas'),
              selected: filtroId == null,
              onSelected: (_) => onSelecionar(null),
            ),
          ),
          for (final c in categorias)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                avatar: CircleAvatar(backgroundColor: Color(c.cor)),
                label: Text(c.nome),
                selected: filtroId == c.id,
                onSelected: (_) => onSelecionar(c.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListaDespesas extends StatelessWidget {
  const _ListaDespesas({
    required this.despesas,
    required this.categorias,
    required this.store,
  });

  final List<Despesa> despesas;
  final Map<int, Categoria> categorias;

  /// Usado só para chamar ações (excluir), nunca para ler `.value` aqui.
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    if (despesas.isEmpty) {
      return const _ListaVazia();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88), // espaço para o FAB
      itemCount: despesas.length,
      itemBuilder: (context, i) {
        final d = despesas[i];
        final categoria = categorias[d.categoriaId];
        final cor = Color(categoria?.cor ?? 0xFF9E9E9E);

        return Dismissible(
          key: ValueKey('despesa-${d.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          confirmDismiss: (_) => confirmarExclusao(
            context,
            titulo: 'Excluir despesa?',
            mensagem: '"${d.descricao}" (${formatarMoeda(d.valorCentavos)}) '
                'será excluída.',
          ),
          onDismissed: (_) async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await store.removerDespesa(d.id!);
              messenger.showSnackBar(
                const SnackBar(content: Text('Despesa excluída')),
              );
            } catch (_) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Erro ao excluir a despesa')),
              );
            }
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cor,
              foregroundColor: Colors.white,
              child: Text(
                (categoria?.nome.isNotEmpty ?? false)
                    ? categoria!.nome[0].toUpperCase()
                    : '?',
              ),
            ),
            title: Text(d.descricao),
            subtitle: Text(
              '${categoria?.nome ?? 'Sem categoria'} · ${formatarData(d.data)}',
            ),
            trailing: Text(
              formatarMoeda(d.valorCentavos),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            onTap: () => abrirFormularioDespesa(context, despesa: d),
          ),
        );
      },
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia();

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.savings_outlined, size: 64, color: cor),
            const SizedBox(height: 12),
            Text(
              'Nenhuma despesa neste mês.\nToque em "Nova despesa" para lançar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cor),
            ),
          ],
        ),
      ),
    );
  }
}
