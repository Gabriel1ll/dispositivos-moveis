import 'package:cofrinho/data/categoria_repository.dart';
import 'package:cofrinho/data/despesa_repository.dart';
import 'package:cofrinho/models/categoria.dart';
import 'package:cofrinho/models/despesa.dart';

/// Repositórios em memória: testam o store sem precisar do SQLite.

class FakeCategoriaRepository implements CategoriaRepository {
  FakeCategoriaRepository([List<Categoria> iniciais = const []]) {
    for (final c in iniciais) {
      final id = c.id ?? ++_ultimoId;
      if (id > _ultimoId) _ultimoId = id;
      _dados[id] = c.copyWith(id: id);
    }
  }

  final _dados = <int, Categoria>{};
  int _ultimoId = 0;

  /// Simula o ON DELETE CASCADE, avisando o repositório de despesas.
  FakeDespesaRepository? despesas;

  @override
  Future<List<Categoria>> listar() async => _dados.values.toList();

  @override
  Future<Categoria> inserir(Categoria categoria) async {
    final nova = categoria.copyWith(id: ++_ultimoId);
    _dados[nova.id!] = nova;
    return nova;
  }

  @override
  Future<void> atualizar(Categoria categoria) async {
    _dados[categoria.id!] = categoria;
  }

  @override
  Future<void> remover(int id) async {
    _dados.remove(id);
    despesas?.removerDaCategoria(id);
  }
}

class FakeDespesaRepository implements DespesaRepository {
  FakeDespesaRepository([List<Despesa> iniciais = const []]) {
    for (final d in iniciais) {
      final id = d.id ?? ++_ultimoId;
      if (id > _ultimoId) _ultimoId = id;
      dados[id] = d.copyWith(id: id);
    }
  }

  final dados = <int, Despesa>{};
  int _ultimoId = 0;
  bool falharAoRemover = false;

  void removerDaCategoria(int categoriaId) {
    dados.removeWhere((_, d) => d.categoriaId == categoriaId);
  }

  @override
  Future<List<Despesa>> listar() async => dados.values.toList();

  @override
  Future<Despesa> inserir(Despesa despesa) async {
    final nova = despesa.copyWith(id: ++_ultimoId);
    dados[nova.id!] = nova;
    return nova;
  }

  @override
  Future<void> atualizar(Despesa despesa) async {
    dados[despesa.id!] = despesa;
  }

  @override
  Future<void> remover(int id) async {
    if (falharAoRemover) throw Exception('falha simulada');
    dados.remove(id);
  }
}
