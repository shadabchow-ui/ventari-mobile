/// Ventari adapter layer for the Bagisto-derived Flutter app.
///
/// Replaces the Bagisto GraphQL data layer feature by feature (VJ-171). The
/// presentation layer (blocs, widgets) is reused; data comes only from the
/// Ventari BFF. See docs/ventari/VENTARI_BAGISTO_TO_VENTARI_API_MAPPING.md.
library;

export 'catalog/catalog_client.dart';
export 'catalog/catalog_models.dart';
export 'commerce/idempotency.dart';
export 'config/ventari_config.dart';
export 'core/money.dart';
export 'core/transport.dart';
export 'core/ventari_error.dart';
export 'session/session_store.dart';
