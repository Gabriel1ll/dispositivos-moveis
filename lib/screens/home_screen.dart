import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'categorias_screen.dart';
import 'despesas_screen.dart';
import 'resumo_screen.dart';

/// Tela principal com três abas.
///
/// A aba selecionada é um signal **local** desta tela. Repare que não há
/// nenhum `setState`: trocar `_aba.value` já reconstrói o `SignalBuilder`.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _aba = signal(0);

  @override
  void dispose() {
    _aba.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final aba = _aba.value;
        return Scaffold(
          // IndexedStack mantém as três abas vivas (preserva a rolagem).
          body: IndexedStack(
            index: aba,
            children: const [
              DespesasScreen(),
              CategoriasScreen(),
              ResumoScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: aba,
            onDestinationSelected: (i) => _aba.value = i,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Despesas',
              ),
              NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: 'Categorias',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: 'Resumo',
              ),
            ],
          ),
        );
      },
    );
  }
}
