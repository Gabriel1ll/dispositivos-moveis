import 'package:flutter/widgets.dart';

import 'app_store.dart';

/// Disponibiliza o [AppStore] para qualquer tela da árvore de widgets.
///
/// É uma injeção de dependência simples, sem pacote extra. A reatividade
/// não vem daqui: vem dos signals dentro do store. Este widget só entrega
/// a referência do store.
class StoreScope extends InheritedWidget {
  const StoreScope({super.key, required this.store, required super.child});

  final AppStore store;

  /// Use dentro de `build`.
  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope não encontrado na árvore de widgets');
    return scope!.store;
  }

  /// Use fora de `build` (ex.: `initState`, callbacks).
  static AppStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope não encontrado na árvore de widgets');
    return scope!.store;
  }

  @override
  bool updateShouldNotify(StoreScope oldWidget) => store != oldWidget.store;
}
