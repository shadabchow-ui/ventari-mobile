/// Where the opaque Ventari session token lives (VJ-145, OD-42).
///
/// Implementations must use the platform keystore (iOS Keychain, Android
/// Keystore) — never SharedPreferences, files or logs. The Bagisto fork's
/// AuthStorage keeps its token in SharedPreferences; VJ-145 migrates it.
abstract class VentariSessionStore {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> clear();
}

/// In-memory store for tests and the VJ-142 spike only.
class InMemorySessionStore implements VentariSessionStore {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
