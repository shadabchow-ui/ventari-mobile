import 'package:bagisto_flutter/ventari/ventari.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('formats integer cents without float rounding', () {
      expect(Money.fromCents(0, 'USD').format(), r'$0.00');
      expect(Money.fromCents(5, 'USD').format(), r'$0.05');
      expect(Money.fromCents(8999, 'USD').format(), r'$89.99');
      expect(Money.fromCents(129900, 'USD').format(), r'$1,299.00');
      expect(Money.fromCents(123456789, 'USD').format(), r'$1,234,567.89');
    });

    test('rejects floats, negatives, strings and non-USD currencies', () {
      expect(() => Money.fromCents(89.99, 'USD'), throwsFormatException);
      expect(() => Money.fromCents(-1, 'USD'), throwsFormatException);
      expect(() => Money.fromCents('8999', 'USD'), throwsFormatException);
      expect(() => Money.fromCents(100, 'EUR'), throwsFormatException);
      expect(() => Money.fromCents(100, null), throwsFormatException);
    });

    test('parses the BFF money object', () {
      expect(Money.fromJson({'amountCents': 1500, 'currency': 'USD'}), Money.fromCents(1500, 'USD'));
    });
  });
}
