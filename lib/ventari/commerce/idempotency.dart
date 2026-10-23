import 'dart:math';

/// One idempotency key per user action (VJ-134/VJ-136).
///
/// The key is created when the shopper taps (add to cart, place order) and is
/// reused for every retry of that same action, so a timeout followed by a
/// retry can never add a line twice or place two orders. A new tap gets a new
/// key. Non-idempotent requests are never retried without their key.
class IdempotencyKey {
  IdempotencyKey._(this.value);

  final String value;

  static final _random = Random.secure();

  factory IdempotencyKey.newAction() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return IdempotencyKey._(bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
  }

  Map<String, String> get header => {'Idempotency-Key': value};

  @override
  String toString() => value;
}

/// Tracks the in-flight key for an action so repeated taps or automatic
/// retries reuse it until the server has answered definitively.
class ActionKeys {
  final Map<String, IdempotencyKey> _inflight = {};

  /// Same [actionId] (for example `add:<sku>`) returns the same key until [complete].
  IdempotencyKey keyFor(String actionId) => _inflight.putIfAbsent(actionId, IdempotencyKey.newAction);

  /// Call after a definitive server answer (success or non-retryable error).
  void complete(String actionId) => _inflight.remove(actionId);
}
