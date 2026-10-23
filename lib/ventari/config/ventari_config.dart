/// Build-time Ventari endpoints, supplied per flavor with --dart-define.
///
///   flutter run --dart-define=VENTARI_API_BASE=https://staging.example.com
///
/// No endpoint, key or token is committed (the Bagisto fork's
/// api_constants.dart pattern is replaced by this in VJ-144).
class VentariConfig {
  const VentariConfig({required this.apiBase, required this.appVersion});

  /// Origin of the Nitro BFF serving /api/ventari/v2 (catalog) and
  /// /api/ventari/m/v1 (mobile commerce). Shopware is never called directly.
  final Uri apiBase;
  final String appVersion;

  static VentariConfig fromEnvironment() {
    const base = String.fromEnvironment('VENTARI_API_BASE');
    const version = String.fromEnvironment('VENTARI_APP_VERSION', defaultValue: '0.0.0-dev');
    return parse(base, version);
  }

  /// Fails closed: an empty, non-HTTPS (except loopback) or credentialed URL is refused.
  static VentariConfig parse(String base, String version) {
    final uri = Uri.tryParse(base);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('VENTARI_API_BASE is not set to an absolute URL');
    }
    final loopback = uri.host == '127.0.0.1' || uri.host == 'localhost' || uri.host == '10.0.2.2';
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback)) {
      throw StateError('VENTARI_API_BASE must use https outside local development');
    }
    if (uri.userInfo.isNotEmpty) {
      throw StateError('VENTARI_API_BASE must not embed credentials');
    }
    return VentariConfig(
      apiBase: Uri(scheme: uri.scheme, host: uri.host, port: uri.hasPort ? uri.port : null),
      appVersion: version,
    );
  }
}
