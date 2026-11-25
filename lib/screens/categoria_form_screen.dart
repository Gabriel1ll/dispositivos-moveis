import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../models/categoria.dart';
import '../state/store_scope.dart';
import '../util/formatadores.dart';
import '../widgets/dialogos.dart';

/// CREATE / UPDATE de categoria (e DELETE pelo ícone de lixeira na edição).
///
/// Estado local do formulário com signals:
///  * `_cor`: cor escolhida na paleta
///  * `_nomeDigitado`: espelho do campo de nome, para a prévia reagir
///  * `_salvando`: desabilita o botão enquanto grava no banco
/// E um `computed` (`_rotuloPreview`) com o texto da prévia.
class CategoriaFormScreen extends StatefulWidget {
  const CategoriaFormScreen({super.key, this.categoria});

  /// `null` = nova categoria.
  final Categoria? categoria;

  @override
  State<CategoriaFormScreen> createState() => _CategoriaFormScreenState();
}

class _CategoriaFormScreenState extends State<CategoriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _orcamento;

  late final _cor = signal<int>(widget.categoria?.cor ?? paletaCategorias.first);
  late final _nomeDigitado = signal<String>(widget.categoria?.nome ?? '');
  final _salvando = signal(false);

  /// Texto da prévia: recalculado só quando o nome digitado muda.
  late final _rotuloPreview = computed<String>(() {
    final nome = _nomeDigitado.value.trim();
    return nome.isEmpty ? 'Nova categoria' : nome;
  });

  bool get _editando => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    final c = widget.categoria;
    _nome = TextEditingController(text: c?.nome ?? '');
    _orcamento = TextEditingController(
      text: (c != null && c.temOrcamento)
          ? centavosParaCampo(c.orcamentoCentavos)
          : '',
    );
    // Liga o campo de texto ao signal para a prévia reagir à digitação.
    _nome.addListener(() => _nomeDigitado.value = _nome.text);
  }

  @override
  void dispose() {
    _nome.dispose();
    _orcamento.dispose();
    _rotuloPreview.dispose();
    _cor.dispose();
    _nomeDigitado.dispose();
    _salvando.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final store = StoreScope.read(context);
    final textoOrcamento = _orcamento.text.trim();

    final categoria = Categoria(
      id: widget.categoria?.id,
      nome: _nome.text.trim(),
      cor: _cor.value,
      orcamentoCentavos:
          textoOrcamento.isEmpty ? 0 : lerValorEmCentavos(textoOrcamento)!,
    );

    _salvando.value = true;
    try {
      await store.salvarCategoria(categoria);
      if (!mounted) return;
      Navigator.of(context).pop();
      mostrarMensagem(
        context,
        _editando ? 'Categoria atualizada' : 'Categoria criada',
      );
    } catch (_) {
      if (mounted) mostrarMensagem(context, 'Erro ao salvar a categoria');
    } finally {
      // O signal pode já ter sido descartado se a tela fechou.
      if (mounted) _salvando.value = false;
    }
  }

  Future<void> _excluir() async {
    final store = StoreScope.read(context);
    final c = widget.categoria!;
    final qtd = store.quantidadePorCategoria.value[c.id] ?? 0;
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Excluir "${c.nome}"?',
      mensagem: qtd == 0
          ? 'Esta categoria não tem despesas.'
          : 'Ela tem $qtd despesa(s), que também serão excluídas.',
    );
    if (!confirmou || !mounted) return;
    await store.removerCategoria(c.id!);
    if (!mounted) return;
    Navigator.of(context).pop();
    mostrarMensagem(context, 'Categoria excluída');
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar categoria' : 'Nova categoria'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _excluir,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Prévia ao vivo
            SignalBuilder(
              builder: (context) => Center(
                child: Chip(
                  avatar: CircleAvatar(backgroundColor: Color(_cor.value)),
                  label: Text(_rotuloPreview.value),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nome,
              autofocus: !_editando,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                final nome = valor?.trim() ?? '';
                if (nome.isEmpty) return 'Informe o nome';
                if (nome.length > 30) return 'Use no máximo 30 caracteres';
                if (store.nomeDeCategoriaEmUso(
                  nome,
                  ignorarId: widget.categoria?.id,
                )) {
                  return 'Já existe uma categoria com esse nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _orcamento,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Orçamento mensal (opcional)',
                prefixText: 'R\$ ',
                hintText: 'ex.: 500,00',
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                final texto = valor?.trim() ?? '';
                if (texto.isEmpty) return null;
                final centavos = lerValorEmCentavos(texto);
                if (centavos == null) return 'Valor inválido';
                if (centavos <= 0) return 'Use um valor maior que zero';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Cor', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SignalBuilder(
              builder: (context) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final cor in paletaCategorias)
                    _BolinhaCor(
                      cor: cor,
                      selecionada: _cor.value == cor,
                      onTap: () => _cor.value = cor,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SignalBuilder(
              builder: (context) => FilledButton.icon(
                onPressed: _salvando.value ? null : _salvar,
                icon: _salvando.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_editando ? 'Salvar alterações' : 'Criar categoria'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BolinhaCor extends StatelessWidget {
  const _BolinhaCor({
    required this.cor,
    required this.selecionada,
    required this.onTap,
  });

  final int cor;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(cor),
          shape: BoxShape.circle,
          border: Border.all(
            color: selecionada
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: selecionada
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
