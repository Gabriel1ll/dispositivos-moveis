import 'package:cofrinho/app.dart';
import 'package:cofrinho/models/categoria.dart';
import 'package:cofrinho/models/despesa.dart';
import 'package:cofrinho/state/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  testWidgets('mostra as despesas do mês e reage a mudanças no store',
      (tester) async {
    final hoje = DateTime.now();
    final categorias = FakeCategoriaRepository(const [
      Categoria(id: 1, nome: 'Mercado', cor: 0xFF2E7D32),
    ]);
    final despesas = FakeDespesaRepository([
      Despesa(
        id: 1,
        descricao: 'Feira',
        valorCentavos: 4590,
        data: DateTime(hoje.year, hoje.month, 1),
        categoriaId: 1,
      ),
    ]);
    final store = AppStore(categoriaRepo: categorias, despesaRepo: despesas);
    await store.carregar();

    await tester.pumpWidget(CofrinhoApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Feira'), findsOneWidget);
    expect(find.text(r'R$ 45,90'), findsWidgets);

    // Mudar o signal fora da interface reconstrói a tela sozinho.
    await store.salvarDespesa(Despesa(
      descricao: 'Padaria',
      valorCentavos: 1000,
      data: DateTime(hoje.year, hoje.month, 1),
      categoriaId: 1,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Padaria'), findsOneWidget);
    expect(find.text(r'R$ 55,90'), findsWidgets);

    // Aba Categorias
    await tester.tap(find.byIcon(Icons.category_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Nova categoria'), findsOneWidget);
  });
}
