import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'state/app_store.dart';
import 'state/store_scope.dart';

class CofrinhoApp extends StatelessWidget {
  const CofrinhoApp({super.key, required this.store});

  final AppStore store;

  static const _corBase = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Cofrinho',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: _corBase),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: _corBase,
          brightness: Brightness.dark,
        ),
        // Português do Brasil no calendário e nos textos padrão do Material.
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeScreen(),
      ),
    );
  }
}
