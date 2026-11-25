/// Funções de formatação no padrão brasileiro.
///
/// Feitas à mão (sem o pacote `intl`) para o projeto ter menos dependências
/// e para ficar fácil de explicar como funcionam.
library;

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// 123456 -> "R$ 1.234,56"
String formatarMoeda(int centavos) {
  final negativo = centavos < 0;
  final absoluto = centavos.abs();
  final reais = (absoluto ~/ 100).toString();
  final resto = (absoluto % 100).toString().padLeft(2, '0');

  final comPontos = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    if (i > 0 && (reais.length - i) % 3 == 0) comPontos.write('.');
    comPontos.write(reais[i]);
  }
  return '${negativo ? '-' : ''}R\$ $comPontos,$resto';
}

/// 123456 -> "1234,56" (para preencher o campo de valor ao editar)
String centavosParaCampo(int centavos) {
  final reais = centavos ~/ 100;
  final resto = (centavos % 100).toString().padLeft(2, '0');
  return '$reais,$resto';
}

/// Converte o texto digitado em centavos. Retorna `null` se for inválido.
///
/// Aceita: "12", "12,5", "12,50", "1.234,56", "1234.56", "R$ 10,00".
int? lerValorEmCentavos(String texto) {
  var t = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (t.isEmpty) return null;

  if (t.contains(',')) {
    // Padrão brasileiro: ponto = milhar, vírgula = decimal.
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(t)) {
    // "1.234" sem vírgula: o ponto é separador de milhar.
    t = t.replaceAll('.', '');
  }

  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(t)) return null;
  final valor = double.parse(t);
  return (valor * 100).round();
}

/// 2026-11-24 -> "24/11/2026"
String formatarData(DateTime d) {
  final dia = d.day.toString().padLeft(2, '0');
  final mes = d.month.toString().padLeft(2, '0');
  return '$dia/$mes/${d.year}';
}

/// -> "Novembro de 2026"
String formatarMes(DateTime d) => '${_meses[d.month - 1]} de ${d.year}';
