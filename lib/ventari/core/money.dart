/// Server-authoritative money for Ventari.
///
/// Amounts are integer cents exactly as the Ventari BFF returns them. The app
/// formats money for display and never adds, multiplies or discounts it: cart
/// lines, subtotals, tax, shipping and order totals always come from the
/// server response (Ventari invariant: the client never computes a charged
/// total).
class Money {
  const Money._(this.amountCents, this.currency);

  /// Integer minor units (cents). Never a floating-point value.
  final int amountCents;

  /// ISO 4217 code. USD only at launch.
  final String currency;

  static const supportedCurrencies = {'USD'};

  /// Parses `{amountCents: int, currency: 'USD'}` or a bare integer cents
  /// field plus a currency. Rejects non-integers, negatives and unsupported
  /// currencies instead of guessing.
  factory Money.fromCents(Object? cents, Object? currency) {
    if (cents is! int || cents < 0) {
      throw FormatException('Money must be non-negative integer cents, got $cents');
    }
    if (currency is! String || !supportedCurrencies.contains(currency)) {
      throw FormatException('Unsupported currency $currency');
    }
    return Money._(cents, currency);
  }

  factory Money.fromJson(Map<String, dynamic> json) =>
      Money.fromCents(json['amountCents'], json['currency']);

  /// Display only: `$1,234.56`. Uses integer division so no float rounding.
  String format() {
    final whole = amountCents ~/ 100;
    final fraction = (amountCents % 100).toString().padLeft(2, '0');
    final digits = whole.toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
      grouped.write(digits[i]);
    }
    return '\$$grouped.$fraction';
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.amountCents == amountCents && other.currency == currency;

  @override
  int get hashCode => Object.hash(amountCents, currency);

  @override
  String toString() => '$currency $amountCents';
}
