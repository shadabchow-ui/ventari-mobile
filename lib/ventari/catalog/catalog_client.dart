import '../config/ventari_config.dart';
import '../core/transport.dart';
import '../core/ventari_error.dart';
import 'catalog_models.dart';

/// Read-only client for the public Ventari catalog BFF v2 (`/api/ventari/v2/*`).
///
/// Catalog reads are idempotent GETs, so a single retry is allowed for
/// retryable failures (503, network). The app never calls R2, D1, the catalog
/// gateway or Shopware directly.
class VentariCatalogClient {
  VentariCatalogClient(this._config, this._transport, {this.maxRetries = 1});

  final VentariConfig _config;
  final VentariTransport _transport;
  final int maxRetries;

  Uri _uri(String path, [Map<String, Object?> query = const {}]) {
    final params = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        if (value.isNotEmpty) params[key] = value.map((e) => '$e').toList();
      } else {
        params[key] = '$value';
      }
    });
    return _config.apiBase.replace(path: '/api/ventari/v2$path', queryParameters: params.isEmpty ? null : params);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    VentariError? last;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      VentariResponse response;
      try {
        response = await _transport.send('GET', uri, headers: {'X-Ventari-App-Version': _config.appVersion});
      } on VentariError {
        rethrow;
      } catch (_) {
        last = const VentariError(code: 'NETWORK', message: 'Network unavailable', retryable: true);
        continue;
      }
      if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
        return response.body as Map<String, dynamic>;
      }
      if (response.statusCode == 200) throw VentariError.invalidResponse;
      last = VentariError.fromResponse(response.statusCode, response.body, requestId: response.headers['x-request-id']);
      if (!last.retryable) throw last;
    }
    throw last!;
  }

  /// Search or category listing with facets and cursor pagination.
  Future<SearchResult> search({
    String? query,
    String? category,
    List<String> brands = const [],
    bool inStockOnly = false,
    String? sort,
    int? limit,
    String? cursor,
  }) async {
    if (limit != null && (limit < 1 || limit > 48)) {
      throw ArgumentError.value(limit, 'limit', 'must be 1..48 (contract limit)');
    }
    final json = await _get(_uri('/search', {
      'q': query,
      'category': category,
      'brand': brands,
      'inStock': inStockOnly ? '1' : null,
      'sort': sort,
      'limit': limit,
      'cursor': cursor,
    }));
    try {
      return SearchResult.fromJson(json);
    } on FormatException {
      throw VentariError.invalidResponse;
    }
  }

  Future<ProductOutcome> product(String slug) async {
    final json = await _get(_uri('/products/${Uri.encodeComponent(slug.toLowerCase())}'));
    try {
      final data = json['data'];
      return switch (json['kind']) {
        'product' when data is Map<String, dynamic> => ProductFound(Product.fromJson(data)),
        'redirect' when data is Map<String, dynamic> && data['canonicalSlug'] is String =>
          ProductRedirect(data['canonicalSlug'] as String),
        _ => throw const FormatException('Unknown product outcome'),
      };
    } on FormatException {
      throw VentariError.invalidResponse;
    }
  }

  Future<List<Suggestion>> suggest(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final json = await _get(_uri('/suggest', {'q': trimmed}));
    final list = json['suggestions'];
    if (list is! List) throw VentariError.invalidResponse;
    try {
      return [for (final s in list.whereType<Map<String, dynamic>>()) Suggestion.fromJson(s)];
    } on FormatException {
      throw VentariError.invalidResponse;
    }
  }
}
