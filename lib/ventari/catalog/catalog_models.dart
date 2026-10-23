import '../core/money.dart';

/// Dart mirrors of the Ventari catalog BFF v2 contract
/// (server/utils/ventariCatalogV2.ts at integration 3ce4c2a; OpenAPI arrives with VJ-131
/// and generated models with VJ-133). Decoding is defensive and fails closed: a missing
/// price or an unknown availability never becomes "in stock" or "free".
///
/// Every model keeps its `raw` JSON so fields the UI does not read yet are preserved,
/// not dropped (DEC-08: never flatten or discard catalog fields).

T _req<T>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! T) throw FormatException('Field "$key" missing or not ${T.toString()}');
  return value;
}

List<Map<String, dynamic>> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Field "$key" is not a list');
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

/// Server availability classes. `unknown` is never shown as purchasable.
enum AvailabilityStatus { inStock, lowStock, outOfStock, unknown }

AvailabilityStatus parseAvailability(Object? value) => switch (value) {
      'in_stock' => AvailabilityStatus.inStock,
      'low_stock' => AvailabilityStatus.lowStock,
      'out_of_stock' => AvailabilityStatus.outOfStock,
      _ => AvailabilityStatus.unknown,
    };

class Discount {
  const Discount({required this.amount, required this.percentOff, this.label});

  final Money amount;
  final num percentOff;
  final String? label;

  static Discount? fromJson(Object? json, String currency) {
    if (json is! Map<String, dynamic> || json['kind'] != 'sale') return null;
    return Discount(
      amount: Money.fromCents(json['amountCents'], currency),
      percentOff: json['percentOff'] is num ? json['percentOff'] as num : 0,
      label: json['label'] is String ? json['label'] as String : null,
    );
  }
}

class Rating {
  const Rating(this.average, this.count);

  final num average;
  final int count;

  /// Ratings render only when the envelope carries them (no fabricated social proof).
  static Rating? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final avg = json['average'];
    final count = json['count'];
    if (avg is! num || count is! int || count < 0) return null;
    return Rating(avg, count);
  }
}

class ImageRef {
  const ImageRef({required this.url, required this.width, required this.height, required this.alt});

  final String url;
  final int width;
  final int height;
  final String alt;

  static ImageRef? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['url'] is! String) return null;
    final uri = Uri.tryParse(json['url'] as String);
    if (uri == null || uri.scheme != 'https') return null; // never load cleartext media
    return ImageRef(
      url: json['url'] as String,
      width: json['width'] is int ? json['width'] as int : 0,
      height: json['height'] is int ? json['height'] as int : 0,
      alt: json['alt'] is String ? json['alt'] as String : (json['altText'] is String ? json['altText'] as String : ''),
    );
  }
}

class ProductCard {
  const ProductCard({
    required this.id,
    required this.slug,
    required this.title,
    required this.brand,
    required this.price,
    required this.listPrice,
    required this.discount,
    required this.inStock,
    required this.rating,
    required this.image,
    required this.variantCount,
    required this.raw,
  });

  final String id;
  final String slug;
  final String title;
  final String brand;
  final Money price;
  final Money? listPrice;
  final Discount? discount;
  final bool inStock;
  final Rating? rating;
  final ImageRef? image;
  final int variantCount;
  final Map<String, dynamic> raw;

  factory ProductCard.fromJson(Map<String, dynamic> json) {
    final currency = _req<String>(json, 'currency');
    return ProductCard(
      id: _req<String>(json, 'id'),
      slug: _req<String>(json, 'slug'),
      title: _req<String>(json, 'title'),
      brand: json['brand'] is String ? json['brand'] as String : '',
      price: Money.fromCents(json['priceCents'], currency),
      listPrice: json['listPriceCents'] == null ? null : Money.fromCents(json['listPriceCents'], currency),
      discount: Discount.fromJson(json['discount'], currency),
      inStock: json['inStock'] == true,
      rating: Rating.fromJson(json['rating']),
      image: ImageRef.fromJson(json['image']),
      variantCount: json['variantCount'] is int ? json['variantCount'] as int : 1,
      raw: json,
    );
  }
}

class FacetValue {
  const FacetValue(this.value, this.label, this.count, this.selected);

  final String value;
  final String label;
  final int count;
  final bool selected;
}

class Facet {
  const Facet({required this.key, required this.label, required this.approximate, required this.values});

  final String key;
  final String label;
  final bool approximate;
  final List<FacetValue> values;

  factory Facet.fromJson(Map<String, dynamic> json) => Facet(
        key: _req<String>(json, 'key'),
        label: _req<String>(json, 'label'),
        approximate: json['approximate'] == true,
        values: [
          for (final v in _list(json, 'values'))
            FacetValue(_req<String>(v, 'value'), _req<String>(v, 'label'),
                v['count'] is int ? v['count'] as int : 0, v['selected'] == true),
        ],
      );
}

class SearchResult {
  const SearchResult({
    required this.items,
    required this.total,
    required this.totalIsLowerBound,
    required this.nextCursor,
    required this.facets,
    required this.sort,
    required this.raw,
  });

  final List<ProductCard> items;
  final int total;

  /// `relation: gte` — show "1,000+" rather than an exact count.
  final bool totalIsLowerBound;
  final String? nextCursor;
  final List<Facet> facets;
  final String sort;
  final Map<String, dynamic> raw;

  bool get hasMore => nextCursor != null;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final total = _req<Map<String, dynamic>>(json, 'total');
    final cursor = json['nextCursor'];
    if (cursor != null && (cursor is! String || !RegExp(r'^[A-Za-z0-9_-]{1,512}$').hasMatch(cursor))) {
      throw const FormatException('Invalid cursor');
    }
    final items = _list(json, 'items');
    if (items.length > 48) throw const FormatException('Page larger than the contract allows');
    return SearchResult(
      items: [for (final i in items) ProductCard.fromJson(i)],
      total: total['value'] is int ? total['value'] as int : 0,
      totalIsLowerBound: total['relation'] == 'gte',
      nextCursor: cursor as String?,
      facets: [for (final f in _list(json, 'facets')) Facet.fromJson(f)],
      sort: json['sort'] is String ? json['sort'] as String : 'relevance',
      raw: json,
    );
  }
}

class VariantAvailability {
  const VariantAvailability(this.status, this.quantity);

  final AvailabilityStatus status;
  final int? quantity;
}

class Variant {
  const Variant({
    required this.sku,
    required this.name,
    required this.options,
    required this.price,
    required this.listPrice,
    required this.discount,
    required this.sellable,
    required this.availability,
    required this.maxOrderQuantity,
  });

  final String sku;
  final String name;
  final Map<String, String> options;

  /// Null when the catalog has no price: the variant cannot be added to the cart.
  final Money? price;
  final Money? listPrice;
  final Discount? discount;
  final bool sellable;
  final VariantAvailability availability;
  final int maxOrderQuantity;

  /// Purchasability is a server decision: sellable, priced and not out of stock or unknown.
  bool get canAddToCart =>
      sellable &&
      price != null &&
      (availability.status == AvailabilityStatus.inStock || availability.status == AvailabilityStatus.lowStock) &&
      maxOrderQuantity > 0;

  factory Variant.fromJson(Map<String, dynamic> json, String currency) {
    final availability = json['availability'] is Map<String, dynamic>
        ? json['availability'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final options = json['options'] is Map ? (json['options'] as Map) : const {};
    return Variant(
      sku: _req<String>(json, 'sku'),
      name: _req<String>(json, 'name'),
      options: {for (final e in options.entries) '${e.key}': '${e.value}'},
      price: json['priceCents'] == null ? null : Money.fromCents(json['priceCents'], currency),
      listPrice: json['listPriceCents'] == null ? null : Money.fromCents(json['listPriceCents'], currency),
      discount: Discount.fromJson(json['discount'], currency),
      sellable: json['sellable'] == true,
      availability: VariantAvailability(
        parseAvailability(availability['status']),
        availability['quantity'] is int ? availability['quantity'] as int : null,
      ),
      maxOrderQuantity: json['maxOrderQuantity'] is int ? json['maxOrderQuantity'] as int : 0,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.slug,
    required this.canonicalUrl,
    required this.title,
    required this.brand,
    required this.description,
    required this.bullets,
    required this.media,
    required this.rating,
    required this.axes,
    required this.variants,
    required this.defaultSku,
    required this.contentVersion,
    required this.raw,
  });

  final String id;
  final String slug;
  final String canonicalUrl;
  final String title;
  final String brand;
  final String description;
  final List<String> bullets;
  final List<ImageRef> media;
  final Rating? rating;
  final List<({String name, List<({String value, String label})> options})> axes;
  final List<Variant> variants;
  final String? defaultSku;
  final String contentVersion;
  final Map<String, dynamic> raw;

  Variant? variantFor(String? sku) {
    for (final v in variants) {
      if (v.sku == (sku ?? defaultSku)) return v;
    }
    return variants.isEmpty ? null : variants.first;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 2) throw const FormatException('Unsupported product schemaVersion');
    if (json['status'] != 'active') throw const FormatException('Inactive product returned');
    final currency = _req<String>(json, 'currency');
    final variants = _list(json, 'variants');
    if (variants.isEmpty) throw const FormatException('Product without variants');
    return Product(
      id: _req<String>(json, 'id'),
      slug: _req<String>(json, 'slug'),
      canonicalUrl: _req<String>(json, 'canonicalUrl'),
      title: _req<String>(json, 'title'),
      brand: json['brand'] is String ? json['brand'] as String : '',
      description: json['description'] is String ? json['description'] as String : '',
      bullets: (json['bullets'] is List ? json['bullets'] as List : const []).whereType<String>().toList(),
      media: [for (final m in _list(json, 'media')) ?ImageRef.fromJson(m)],
      rating: Rating.fromJson(json['rating']),
      axes: [
        for (final a in _list(json, 'axes'))
          (
            name: _req<String>(a, 'name'),
            options: [for (final o in _list(a, 'options')) (value: _req<String>(o, 'value'), label: _req<String>(o, 'label'))],
          ),
      ],
      variants: [for (final v in variants) Variant.fromJson(v, currency)],
      defaultSku: json['defaultSku'] is String ? json['defaultSku'] as String : null,
      contentVersion: _req<String>(json, 'contentVersion'),
      raw: json,
    );
  }
}

/// `{kind: product}` or `{kind: redirect, canonicalSlug}` (alias slugs 301 on the web).
sealed class ProductOutcome {
  const ProductOutcome();
}

class ProductFound extends ProductOutcome {
  const ProductFound(this.product);
  final Product product;
}

class ProductRedirect extends ProductOutcome {
  const ProductRedirect(this.canonicalSlug);
  final String canonicalSlug;
}

class Suggestion {
  const Suggestion({required this.type, required this.text, this.slug, this.categorySlug});

  final String type;
  final String text;
  final String? slug;
  final String? categorySlug;

  factory Suggestion.fromJson(Map<String, dynamic> json) => Suggestion(
        type: _req<String>(json, 'type'),
        text: _req<String>(json, 'text'),
        slug: json['slug'] is String ? json['slug'] as String : null,
        categorySlug: json['categorySlug'] is String ? json['categorySlug'] as String : null,
      );
}
