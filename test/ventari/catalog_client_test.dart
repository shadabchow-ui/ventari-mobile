import 'package:bagisto_flutter/ventari/ventari.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('VentariCatalogClient', () {
    test('builds the v2 search URL with contract parameters only', () async {
      final transport = FakeTransport([VentariResponse(200, fixture('search_page.json'))]);
      final client = VentariCatalogClient(testConfig, transport);
      final result = await client.search(query: 'boots', brands: ['fixture-co'], inStockOnly: true, limit: 24);
      final uri = transport.requests.single.uri;
      expect(uri.origin, 'https://api.example.com');
      expect(uri.path, '/api/ventari/v2/search');
      expect(uri.queryParametersAll, {'q': ['boots'], 'brand': ['fixture-co'], 'inStock': ['1'], 'limit': ['24']});
      expect(transport.requests.single.headers['X-Ventari-App-Version'], '1.2.3');
      expect(result.items, hasLength(2));
    });

    test('rejects limits outside the contract before any request', () async {
      final transport = FakeTransport([]);
      final client = VentariCatalogClient(testConfig, transport);
      expect(() => client.search(limit: 49), throwsArgumentError);
      expect(transport.requests, isEmpty);
    });

    test('maps product and redirect outcomes', () async {
      final client = VentariCatalogClient(
          testConfig,
          FakeTransport([
            VentariResponse(200, fixture('product.json')),
            VentariResponse(200, fixture('product_redirect.json')),
          ]));
      expect(await client.product('Trail-Boot-Womens'), isA<ProductFound>());
      final redirect = await client.product('old-slug');
      expect((redirect as ProductRedirect).canonicalSlug, 'trail-boot-womens');
    });

    test('retries a 503 once (GET is idempotent) and then succeeds', () async {
      final transport = FakeTransport([
        const VentariResponse(503, {'statusMessage': 'CATALOG_UNAVAILABLE'}),
        VentariResponse(200, fixture('suggest.json')),
      ]);
      final suggestions = await VentariCatalogClient(testConfig, transport).suggest('boo');
      expect(transport.requests, hasLength(2));
      expect(suggestions.map((s) => s.text), ['boots', 'Trail Boot']);
    });

    test('404 is not retried and surfaces the typed error', () async {
      final transport = FakeTransport([const VentariResponse(404, {'statusMessage': 'NOT_FOUND'})]);
      await expectLater(
        VentariCatalogClient(testConfig, transport).product('missing'),
        throwsA(isA<VentariError>().having((e) => e.code, 'code', 'NOT_FOUND').having((e) => e.retryable, 'retryable', false)),
      );
      expect(transport.requests, hasLength(1));
    });

    test('off-contract 200 bodies fail closed', () async {
      final transport = FakeTransport([const VentariResponse(200, {'kind': 'mystery'})]);
      await expectLater(VentariCatalogClient(testConfig, transport).product('x'),
          throwsA(isA<VentariError>().having((e) => e.code, 'code', 'INVALID_RESPONSE')));
    });

    test('empty suggestion query makes no request', () async {
      final transport = FakeTransport([]);
      expect(await VentariCatalogClient(testConfig, transport).suggest('   '), isEmpty);
      expect(transport.requests, isEmpty);
    });
  });

  group('VentariConfig', () {
    test('fails closed on missing, cleartext or credentialed endpoints', () {
      expect(() => VentariConfig.parse('', '1'), throwsStateError);
      expect(() => VentariConfig.parse('http://api.example.com', '1'), throwsStateError);
      expect(() => VentariConfig.parse('https://user:pw@api.example.com', '1'), throwsStateError);
      expect(VentariConfig.parse('http://10.0.2.2:3000', '1').apiBase.toString(), 'http://10.0.2.2:3000');
    });
  });
}
