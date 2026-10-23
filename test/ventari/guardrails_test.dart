import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guardrails over the Ventari layer (Ventari invariants, enforced in CI).
void main() {
  final sources = Directory('lib/ventari')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('Ventari layer exists', () => expect(sources, isNotEmpty));

  for (final file in sources) {
    final text = file.readAsStringSync();
    test('${file.path}: no client-side money arithmetic', () {
      // Money is display-only; totals come from the server.
      expect(RegExp(r'amountCents\s*[\+\-\*/]|[\+\-\*/]\s*\w*\.amountCents').hasMatch(text), isFalse);
      expect(RegExp(r'double\s+\w*(price|total|amount)', caseSensitive: false).hasMatch(text), isFalse);
    });
    test('${file.path}: no token persistence in SharedPreferences', () {
      expect(text.contains('package:shared_preferences'), isFalse);
    });
    test('${file.path}: no Bagisto GraphQL or hard-coded endpoint', () {
      expect(text.contains('package:graphql'), isFalse);
      expect(RegExp(r'''['"]https?://(?!example\.com)''').hasMatch(text), isFalse);
    });
  }
}
