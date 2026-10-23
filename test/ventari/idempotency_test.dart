import 'package:bagisto_flutter/ventari/ventari.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one key per action, reused across retries, new after completion', () {
    final keys = ActionKeys();
    final first = keys.keyFor('add:TB-7');
    expect(keys.keyFor('add:TB-7'), same(first));
    expect(keys.keyFor('add:TB-8').value, isNot(first.value));
    keys.complete('add:TB-7');
    expect(keys.keyFor('add:TB-7').value, isNot(first.value));
    expect(first.value, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(first.header, {'Idempotency-Key': first.value});
  });
}
