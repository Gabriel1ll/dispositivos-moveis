import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../models/categoria.dart';
import '../state/app_store.dart';
import '../state/store_scope.dart';
import '../util/formatadores.dart';
import '../widgets/dialogos.dart';
import '../widgets/seletor_mes.dart';
import 'categoria_form_screen.dart';

/// Aba "Categorias": READ + DELETE do CRUD de categorias.
/// CREATE pelo botão "+" e UPDATE tocando num item.
///
/// A barra de progresso de cada categoria vem de `store.totalPorCategoria`
/// (um computed). Lançar uma despesa na outra aba atualiza esta tela sozinho.
class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-categorias',
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
      body: Column(
        children: [
          // O gasto exibido em cada categoria é do mês escolhido aqui.
          const SeletorMes(),
          const Divider(height: 1),
          Expanded(
            child: SignalBuilder(
              builder: (context) {
                final categorias = store.categorias.value;
                if (categorias.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma categoria cadastrada.'),
                  );
                }
                final totais = store.totalPorCategoria.value;
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: categorias.length,
                  separatorBuilder: (context, i) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = categorias[i];
                    return _ItemCategoria(
                      categoria: c,
                      gastoNoMes: totais[c.id] ?? 0,
                      onEditar: () => _abrirFormulario(context, categoria: c),
                      onExcluir: () => _excluir(context, store, c),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFormulario(
    BuildContext context, {
    Categoria? categoria,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoriaFormScreen(categoria: categoria),
      ),
    );
  }

  Future<void> _excluir(
    BuildContext context,
    AppStore store,
    Categoria categoria,
  ) async {
    final qtd = store.quantidadePorCategoria.value[categoria.id] ?? 0;
    final aviso = qtd == 0
        ? 'Esta categoria não tem despesas.'
        : qtd == 1
            ? 'A despesa desta categoria também será excluída.'
            : 'As $qtd despesas desta categoria também serão excluídas.';

    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Excluir "${categoria.nome}"?',
      mensagem: aviso,
    );
    if (!confirmou || !context.mounted) return;

    try {
      await store.removerCategoria(categoria.id!);
      if (context.mounted) mostrarMensagem(context, 'Categoria excluída');
    } catch (_) {
      if (context.mounted) {
        mostrarMensagem(context, 'Erro ao excluir a categoria');
      }
    }
  }
}

class _ItemCategoria extends StatelessWidget {
  const _ItemCategoria({
    required this.categoria,
    required this.gastoNoMes,
    required this.onEditar,
    required this.onExcluir,
  });

  final Categoria categoria;
  final int gastoNoMes;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cor = Color(categoria.cor);
    final orcamento = categoria.orcamentoCentavos;
    final proporcao = categoria.temOrcamento ? gastoNoMes / orcamento : 0.0;
    final estourou = proporcao > 1;

    return ListTile(
      onTap: onEditar,
      leading: CircleAvatar(
        backgroundColor: cor,
        foregroundColor: Colors.white,
        child: Text(categoria.nome.isEmpty ? '?' : categoria.nome[0]),
      ),
      title: Text(categoria.nome),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoria.temOrcamento
                ? '${formatarMoeda(gastoNoMes)} de ${formatarMoeda(orcamento)}'
                : '${formatarMoeda(gastoNoMes)} no mês · sem orçamento',
            style: estourou
                ? TextStyle(
                    color: tema.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  )
                : null,
          ),
          if (categoria.temOrcamento) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: proporcao.clamp(0.0, 1.0).toDouble(),
                minHeight: 6,
                color: estourou ? tema.colorScheme.error : cor,
                backgroundColor: cor.withAlpha(40),
              ),
            ),
          ],
        ],
      ),
      trailing: IconButton(
        tooltip: 'Excluir',
        icon: const Icon(Icons.delete_outline),
        onPressed: onExcluir,
      ),
    );
  }
}
