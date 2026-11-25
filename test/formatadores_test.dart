import 'package:cofrinho/util/formatadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatarMoeda', () {
    test('valores comuns', () {
      expect(formatarMoeda(0), r'R$ 0,00');
      expect(formatarMoeda(5), r'R$ 0,05');
      expect(formatarMoeda(1250), r'R$ 12,50');
      expect(formatarMoeda(123456), r'R$ 1.234,56');
      expect(formatarMoeda(100000000), r'R$ 1.000.000,00');
      expect(formatarMoeda(-1050), r'-R$ 10,50');
    });
  });

  group('lerValorEmCentavos', () {
    test('formatos aceitos', () {
      expect(lerValorEmCentavos('12'), 1200);
      expect(lerValorEmCentavos('12,5'), 1250);
      expect(lerValorEmCentavos('12,50'), 1250);
      expect(lerValorEmCentavos('1.234,56'), 123456);
      expect(lerValorEmCentavos('1234.56'), 123456);
      expect(lerValorEmCentavos('1.234'), 123400);
      expect(lerValorEmCentavos(r'R$ 10,00'), 1000);
      expect(lerValorEmCentavos('0,10'), 10);
    });

    test('formatos rejeitados', () {
      expect(lerValorEmCentavos(''), isNull);
      expect(lerValorEmCentavos('abc'), isNull);
      expect(lerValorEmCentavos('12,345'), isNull);
      expect(lerValorEmCentavos('-5'), isNull);
      expect(lerValorEmCentavos('1,2,3'), isNull);
    });

    test('ida e volta com centavosParaCampo', () {
      for (final v in [1, 99, 100, 1250, 123456]) {
        expect(lerValorEmCentavos(centavosParaCampo(v)), v);
      }
    });
  });

  test('datas', () {
    expect(formatarData(DateTime(2026, 3, 7)), '07/03/2026');
    expect(formatarMes(DateTime(2026, 11)), 'Novembro de 2026');
  });
}
