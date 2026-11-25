import 'package:sqflite/sqflite.dart';

import '../models/despesa.dart';

/// Contrato do CRUD de despesas.
abstract class DespesaRepository {
  Future<List<Despesa>> listar();
  Future<Despesa> inserir(Despesa despesa);
  Future<void> atualizar(Despesa despesa);
  Future<void> remover(int id);
}

class SqliteDespesaRepository implements DespesaRepository {
  SqliteDespesaRepository(this._db);

  final Database _db;
  static const _tabela = 'despesas';

  @override
  Future<List<Despesa>> listar() async {
    final linhas = await _db.query(_tabela, orderBy: 'data DESC, id DESC');
    return linhas.map(Despesa.fromMap).toList();
  }

  @override
  Future<Despesa> inserir(Despesa despesa) async {
    final id = await _db.insert(_tabela, despesa.toMap());
    return despesa.copyWith(id: id);
  }

  @override
  Future<void> atualizar(Despesa despesa) async {
    await _db.update(
      _tabela,
      despesa.toMap(),
      where: 'id = ?',
      whereArgs: [despesa.id],
    );
  }

  @override
  Future<void> remover(int id) async {
    await _db.delete(_tabela, where: 'id = ?', whereArgs: [id]);
  }
}
