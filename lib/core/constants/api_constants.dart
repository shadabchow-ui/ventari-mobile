/// Bagisto API endpoint
const String bagistoEndpoint =
    'https://your-bagisto-domain.com/graphql';

/// Public storefront origin used to resolve relative links and image URLs.
/// Placeholder like [bagistoEndpoint]; a fresh clone must compile without
/// local edits. Ventari builds take their origins from VentariConfig
/// (`--dart-define`), not from this file.
const String bagistoPublicBaseUrl = 'https://your-bagisto-domain.com';

/// Storefront key for Bagisto API
const String storefrontKey =
    'your_storefront_key_here';

/// Default channel code used by request headers.
const String channelCode = 'default';

/// Default Bagisto channel ID used during app bootstrap.
const int channelId = 1;

/// Company name
const String companyName = 'Your Company Name';
