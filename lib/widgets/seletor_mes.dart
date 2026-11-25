import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../state/store_scope.dart';
import '../util/formatadores.dart';

/// "‹  Novembro de 2026  ›"
///
/// Usado nas abas Despesas e Resumo. As duas leem o MESMO signal
/// (`store.mesSelecionado`), então trocar o mês numa aba muda a outra também.
class SeletorMes extends StatelessWidget {
  const SeletorMes({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => store.mudarMes(-1),
          ),
          Expanded(
            child: SignalBuilder(
              builder: (context) => Text(
                formatarMes(store.mesSelecionado.value),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => store.mudarMes(1),
          ),
        ],
      ),
    );
  }
}
