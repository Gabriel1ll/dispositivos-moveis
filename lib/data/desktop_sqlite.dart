import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// No Android, iOS e macOS o plugin `sqflite` funciona direto.
/// No Windows e no Linux é preciso usar a implementação FFI.
/// Isso só existe para facilitar testes no computador.
void configurarSqliteNoDesktop() {
  if (kIsWeb) return;
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
