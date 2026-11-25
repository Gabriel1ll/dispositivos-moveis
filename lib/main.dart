import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/categoria_repository.dart';
import 'data/desktop_sqlite.dart';
import 'data/despesa_repository.dart';
import 'state/app_store.dart';

Future<void> main() async {
  // Necessário antes de usar plugins (sqflite) antes do runApp.
  WidgetsFlutterBinding.ensureInitialized();
  configurarSqliteNoDesktop();

  final db = await AppDatabase.abrir();
  final store = AppStore(
    categoriaRepo: SqliteCategoriaRepository(db),
    despesaRepo: SqliteDespesaRepository(db),
  );

  // Lê o que está salvo no SQLite antes de mostrar a primeira tela.
  await store.carregar();

  runApp(CofrinhoApp(store: store));
}
