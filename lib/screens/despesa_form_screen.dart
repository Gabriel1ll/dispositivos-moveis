import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../models/despesa.dart';
import '../state/store_scope.dart';
import '../util/formatadores.dart';
import '../widgets/dialogos.dart';

/// CREATE / UPDATE de despesa (e DELETE pelo ícone de lixeira na edição).
class DespesaFormScreen extends StatefulWidget {
  const DespesaFormScreen({super.key, this.despesa});

  /// `null` = nova despesa.
  final Despesa? despesa;

  @override
  State<DespesaFormScreen> createState() => _DespesaFormScreenState();
}

class _DespesaFormScreenState extends State<DespesaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricao;
  late final TextEditingController _valor;

  // Estado local do formulário em signals.
  // `peek()` lê o valor de um signal sem se inscrever nele.
  late final _data = signal<DateTime>(widget.despesa?.data ?? _dataSugerida());
  late final _categoriaId = signal<int?>(
    widget.despesa?.categoriaId ??
        StoreScope.read(context).filtroCategoriaId.peek(),
  );
  final _erroCategoria = signal(false);
  final _salvando = signal(false);

  bool get _editando => widget.despesa != null;

  @override
  void initState() {
    super.initState();
    final d = widget.despesa;
    _descricao = TextEditingController(text: d?.descricao ?? '');
    _valor = TextEditingController(
      text: d == null ? '' : centavosParaCampo(d.valorCentavos),
    );
  }

  /// Nova despesa: se o usuário está vendo outro mês, sugere o dia 1 dele;
  /// se está no mês atual, sugere hoje. (Se havia um filtro de categoria,
  /// `_categoriaId` já começa com ela marcada.)
  DateTime _dataSugerida() {
    final hoje = DateTime.now();
    final mes = StoreScope.read(context).mesSelecionado.peek();
    final ehMesAtual = mes.year == hoje.year && mes.month == hoje.month;
    return ehMesAtual ? DateTime(hoje.year, hoje.month, hoje.day) : mes;
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    _data.dispose();
    _categoriaId.dispose();
    _erroCategoria.dispose();
    _salvando.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) {
      _data.value = DateTime(escolhida.year, escolhida.month, escolhida.day);
    }
  }

  Future<void> _salvar() async {
    final formularioOk = _formKey.currentState!.validate();
    _erroCategoria.value = _categoriaId.value == null;
    if (!formularioOk || _erroCategoria.value) return;

    final store = StoreScope.read(context);
    final despesa = Despesa(
      id: widget.despesa?.id,
      descricao: _descricao.text.trim(),
      valorCentavos: lerValorEmCentavos(_valor.text)!,
      data: _data.value,
      categoriaId: _categoriaId.value!,
    );

    _salvando.value = true;
    try {
      await store.salvarDespesa(despesa);
      // Mostra o mês da despesa salva, para ela aparecer na lista.
      store.irParaMes(despesa.data);
      if (!mounted) return;
      Navigator.of(context).pop();
      mostrarMensagem(context, _editando ? 'Despesa atualizada' : 'Despesa salva');
    } catch (_) {
      if (mounted) mostrarMensagem(context, 'Erro ao salvar a despesa');
    } finally {
      if (mounted) _salvando.value = false;
    }
  }

  Future<void> _excluir() async {
    final store = StoreScope.read(context);
    final d = widget.despesa!;
    final confirmou = await confirmarExclusao(
      context,
      titulo: 'Excluir despesa?',
      mensagem: '"${d.descricao}" (${formatarMoeda(d.valorCentavos)}) '
          'será excluída.',
    );
    if (!confirmou || !mounted) return;
    await store.removerDespesa(d.id!);
    if (!mounted) return;
    Navigator.of(context).pop();
    mostrarMensagem(context, 'Despesa excluída');
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar despesa' : 'Nova despesa'),
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
            TextFormField(
              controller: _descricao,
              autofocus: !_editando,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'ex.: Almoço, Uber, Conta de luz',
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                final texto = valor?.trim() ?? '';
                if (texto.isEmpty) return 'Informe a descrição';
                if (texto.length > 60) return 'Use no máximo 60 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valor,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                hintText: '0,00',
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                final centavos = lerValorEmCentavos(valor ?? '');
                if (centavos == null) return 'Informe um valor válido';
                if (centavos <= 0) return 'O valor deve ser maior que zero';
                return null;
              },
            ),
            const SizedBox(height: 16),
            SignalBuilder(
              builder: (context) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Data'),
                subtitle: Text(formatarData(_data.value)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _escolherData,
              ),
            ),
            const SizedBox(height: 8),
            Text('Categoria', style: tema.textTheme.titleSmall),
            const SizedBox(height: 8),
            SignalBuilder(
              builder: (context) {
                final selecionada = _categoriaId.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in store.categorias.value)
                          ChoiceChip(
                            avatar: CircleAvatar(backgroundColor: Color(c.cor)),
                            label: Text(c.nome),
                            selected: selecionada == c.id,
                            onSelected: (_) {
                              _categoriaId.value = c.id;
                              _erroCategoria.value = false;
                            },
                          ),
                      ],
                    ),
                    if (_erroCategoria.value)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Escolha uma categoria',
                          style: TextStyle(
                            color: tema.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
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
                label: Text(_editando ? 'Salvar alterações' : 'Salvar despesa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
