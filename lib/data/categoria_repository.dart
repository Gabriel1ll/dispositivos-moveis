import 'package:sqflite/sqflite.dart';

import '../models/categoria.dart';

/// Contrato do CRUD de categorias.
///
/// A interface permite trocar o SQLite por uma versão em memória nos testes.
abstract class CategoriaRepository {
  Future<List<Categoria>> listar();
  Future<Categoria> inserir(Categoria categoria);
  Future<void> atualizar(Categoria categoria);
  Future<void> remover(int id);
}

class SqliteCategoriaRepository implements CategoriaRepository {
  SqliteCategoriaRepository(this._db);

  final Database _db;
  static const _tabela = 'categorias';

  @override
  Future<List<Categoria>> listar() async {
    final linhas = await _db.query(_tabela, orderBy: 'nome COLLATE NOCASE');
    return linhas.map(Categoria.fromMap).toList();
  }

  @override
  Future<Categoria> inserir(Categoria categoria) async {
    final id = await _db.insert(_tabela, categoria.toMap());
    return categoria.copyWith(id: id);
  }

  @override
  Future<void> atualizar(Categoria categoria) async {
    await _db.update(
      _tabela,
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  @override
  Future<void> remover(int id) async {
    // As despesas dessa categoria são apagadas pelo ON DELETE CASCADE.
    await _db.delete(_tabela, where: 'id = ?', whereArgs: [id]);
  }
}
