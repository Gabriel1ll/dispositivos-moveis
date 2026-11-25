import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/categoria.dart';

/// Abre (e cria, na primeira vez) o banco SQLite do app.
///
/// O arquivo fica na pasta privada do app no aparelho, por isso os dados
/// continuam lá depois que o app é fechado e reaberto.
class AppDatabase {
  static const _nomeArquivo = 'cofrinho.db';
  static const _versao = 1;

  static Future<Database> abrir() async {
    final pasta = await getDatabasesPath();
    return openDatabase(
      join(pasta, _nomeArquivo),
      version: _versao,
      // O SQLite vem com chaves estrangeiras DESLIGADAS por padrão.
      // Sem isso, o ON DELETE CASCADE abaixo não funcionaria.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _criarTabelas,
    );
  }

  static Future<void> _criarTabelas(Database db, int versao) async {
    await db.execute('''
      CREATE TABLE categorias (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        nome               TEXT    NOT NULL,
        cor                INTEGER NOT NULL,
        orcamento_centavos INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE despesas (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao      TEXT    NOT NULL,
        valor_centavos INTEGER NOT NULL CHECK (valor_centavos > 0),
        data           TEXT    NOT NULL,
        categoria_id   INTEGER NOT NULL
                       REFERENCES categorias(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_despesas_data ON despesas(data)');

    // Dados iniciais para o app não abrir vazio.
    final lote = db.batch();
    for (final categoria in categoriasIniciais) {
      lote.insert('categorias', categoria.toMap());
    }
    await lote.commit(noResult: true);
  }
}
