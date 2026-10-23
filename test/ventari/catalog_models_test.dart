import 'package:bagisto_flutter/ventari/ventari.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('SearchResult', () {
    final result = SearchResult.fromJson(fixture('search_page.json'));

    test('decodes cards, server money and cursor', () {
      expect(result.items, hasLength(2));
      expect(result.items.first.price.format(), r'$89.99');
      expect(result.items.first.listPrice!.amountCents, 11999);
      expect(result.items.first.discount!.amount.amountCents, 3000);
      expect(result.hasMore, isTrue);
      expect(result.totalIsLowerBound, isTrue);
      expect(result.facets.single.values.single.label, 'Fixture Co');
    });

    test('keeps unknown fields instead of dropping them', () {
      expect(result.items.first.raw['futureField'], {'kept': true});
    });

    test('does not invent ratings and refuses cleartext images', () {
      expect(result.items[1].rating, isNull);
      expect(result.items[1].image, isNull);
    });

    test('rejects pages larger than the contract and malformed cursors', () {
      final big = fixture('search_page.json');
      big['items'] = List.generate(49, (_) => (big['items'] as List).first);
      expect(() => SearchResult.fromJson(big), throwsFormatException);
      final badCursor = fixture('search_page.json')..['nextCursor'] = 'not a cursor!';
      expect(() => SearchResult.fromJson(badCursor), throwsFormatException);
    });

    test('a card without integer price fails closed', () {
      final json = fixture('search_page.json');
      (json['items'] as List).first['priceCents'] = 89.99;
      expect(() => SearchResult.fromJson(json), throwsFormatException);
    });
  });

  group('Product', () {
    final product = Product.fromJson(fixture('product.json')['data'] as Map<String, dynamic>);

    test('decodes variants, axes and default variant', () {
      expect(product.variants, hasLength(3));
      expect(product.axes.single.options.map((o) => o.value), ['7', '8']);
      expect(product.variantFor(null)!.sku, 'TB-7');
    });

    test('purchasability is the server decision', () {
      expect(product.variantFor('TB-7')!.canAddToCart, isTrue);
      expect(product.variantFor('TB-8')!.canAddToCart, isFalse, reason: 'unknown availability is not in stock');
      expect(product.variantFor('TB-9')!.canAddToCart, isFalse, reason: 'unpriced and not sellable');
    });

    test('unsupported schema versions and inactive products are refused', () {
      final json = Map<String, dynamic>.from(fixture('product.json')['data'] as Map<String, dynamic>);
      expect(() => Product.fromJson({...json, 'schemaVersion': 3}), throwsFormatException);
      expect(() => Product.fromJson({...json, 'status': 'removed'}), throwsFormatException);
    });
  });
}
