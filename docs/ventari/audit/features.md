# Feature / module inventory: ventari-mobile (Bagisto Flutter fork)

Repo `/home/claude/ventari-mobile`, branch `main`, HEAD `18a2c27`. Package `bagisto_flutter`, pubspec version `2.4.7+247` (CHANGELOG top entry is v2.5.2; Android gradle `versionName 2.4.6`/`versionCode 246`; iOS `MARKETING_VERSION 2.56.0`; three different version numbers). Flutter SDK installed at /opt/flutter is 3.47.7; Dart constraint `^3.10.8`.

All paths below are relative to repo root. Line counts come from `wc -l` on `*.dart` files, excluding the generated `lib/l10n/app_localizations*.dart` (23,919 lines, 10 locales: ar de en es fr it nl ru tr uk).

**Total Dart in lib/ excluding generated l10n: 73,882 lines** (features 65,661; core 7,532; `lib/main.dart` 682; `lib/driver_main.dart` 7). Tests: 82 files in `test/`, 359 `test`/`testWidgets` cases.

GraphQL operation inventory (101 operations + 4 fragments = 105 rows) is in `graphql_operations.csv`. Operation names are not unique: `GetProductById` (x2), `countries`/`countryStates` (account + checkout), `Categories` (x2 query names differ in root use), `createCustomerProfileUpdate` (x3: profile/email/password).

Upstream notes (CLAUDE.md, plan.md) summarised as data only: they mandate GraphQL-only, no REST, no hardcoded values, 10-language l10n, bloc+equatable house style, mandatory "skills" invocation on each prompt, and list backend-blocked features (return image/video attach, return message attach, refund numbers/adjustments). plan.md also lists unbuilt `storeConfig` fields (backorders, search min/max length, gdpr, cookie consent, tax display, etc.).

---------------------------------------------------------------------------

## Cross-cutting findings (cited)

### Where the client computes or reformats money
The server supplies almost all amounts and `formatted*` strings; the client mostly displays them. Client-side arithmetic and formatting that exists:

| Location | What |
|---|---|
| `lib/core/currency/currency_formatter.dart:12-23` | Hardcoded currency symbol map (USD, INR, EUR, GBP, JPY, CNY, AED, SAR, CAD, AUD), merged with symbols synced from the channel (`syncCurrencySymbols`, :60-72) |
| `lib/core/currency/currency_formatter.dart:74-86` | `symbolFor`: falls back to `$` (USD) when no code is known, or `"<CODE> "` when the symbol is unknown |
| `lib/core/currency/currency_formatter.dart:88-95` | `formatAmount`: `symbol + value.toStringAsFixed(fractionDigits)` (default 2). No grouping separators, no locale/decimal rules, symbol always prefix |
| `lib/features/cart/data/models/cart_model.dart:276` | `totalPrice => price * quantity` (line total) |
| `lib/features/cart/data/models/cart_model.dart:282-283` | `displayTotal` uses API `formattedTotal`, else `formatAmount(total > 0 ? total : totalPrice)` (client fallback) |
| `lib/features/cart/presentation/pages/cart_page.dart:1237-1293, 1391` | Cart summary rows: API `formatted*` else `CurrencyFormatter.formatAmount(cart.subtotal/discountAmount/shippingAmount/taxAmount/grandTotal)`; discount rendered as `-<amount>` |
| `lib/features/checkout/presentation/pages/checkout_page.dart:2723-2739, 2832` | Same fallback pattern for checkout summary and grand total |
| `lib/features/checkout/data/models/checkout_model.dart:227` | `displayPrice => formattedPrice ?? formatAmount(price)` (shipping/payment rows) |
| `lib/core/store_config/store_config.dart:147-168` | `minimumOrderTotal`: `subtotal` minus `discount` (if `minimumOrderIncludesDiscount`) plus `tax` (if `minimumOrderIncludesTax`); `meetsMinimumOrder` compares to `minimumOrderAmount` |
| `lib/features/cart/presentation/pages/cart_page.dart:1345, 1367, 1419, 1448` | Uses `meetsMinimumOrder`; blocks the "Pay Now" tap client-side when below minimum; message at :135-141 |
| `lib/features/category/data/models/product_model.dart:101-106` | `_hasRegularPriceDiscount` (minimumPrice < regularMinimumPrice) |
| `lib/features/category/data/models/product_model.dart:108-125` | `discountPercent` = round((regular - final)/regular * 100), two branches (min/regular and price/special) |
| `lib/features/category/data/models/product_model.dart:127-130, 150-159` | `displayPrice` picks special > minimum > price; `originalPrice` selection |
| `lib/features/category/data/models/product_model.dart:1470-1483` | Variant `displayPrice`/`originalPrice` (special if > 0 else price) |
| `lib/features/home/data/models/home_models.dart:302-321` | Home card discount percent, same formula (`(price - specialPrice)/price*100`) |
| `lib/features/product/presentation/widgets/product_info_section.dart:130-132` | PDP discount % recomputed from original/display price |
| `lib/features/product/presentation/bloc/product_detail_bloc.dart:227-230` | `effectiveDisplayPrice` = variant price else product price (no bundle/option price summation found; selected customizable/bundle/booking prices are not summed client-side) |
| `lib/features/account/data/models/account_models.dart:2095-2105` | Order `formatAmount` = order-currency symbol + `toStringAsFixed(2)`; `formattedTotal` |
| `lib/features/account/data/models/account_models.dart:2164-2167` | `totalDue = grandTotal - totalPaid`, floored at 0 (client-derived) |
| `lib/features/account/data/models/account_models.dart:421, 578-582, 868, 1228-1232` | `formatAmount` fallbacks when API formatted strings are missing |
| `lib/features/account/presentation/pages/order_detail_page.dart:829-831` | Refund row amount fallback `item.amountRefunded ?? item.price * item.qtyRefunded` |
| `lib/features/account/presentation/pages/order_detail_page.dart:1197-1199` and `invoice_detail_page.dart:494, 1103-1106` | Local `symbol + toStringAsFixed(2)` formatters |
| `lib/features/category/presentation/bloc/product_list_bloc.dart:229-235` | Price-range filter string `"min,max"` via `toStringAsFixed(0)`; default max `99999` hardcoded |
| `lib/features/category/presentation/widgets/filter_bottom_sheet.dart:453-506` | Price slider divisions and labels (`formatAmount(..., fractionDigits: 0)`) |

No client-side tax, shipping or coupon-discount calculation was found; tax/shipping/discount/grand total come from API fields (`taxAmount`, `shippingAmount`, `discountAmount`, `grandTotal` in cart/coupon payloads).

### Where stock/availability is decided client-side
All based on API fields (`isSaleable`, `qty`, `guestCheckout`), with client defaults:
- `lib/features/product/presentation/bloc/product_detail_bloc.dart:217-224` `isOutOfStock`: variant `isSaleable` string not `1`/`true` => out of stock; else `product.isSaleable == false`. Missing value is treated as in stock.
- `lib/features/product/presentation/widgets/product_info_section.dart:292` `inStock = product.isSaleable ?? true`.
- `lib/features/product/presentation/widgets/product_action_bar.dart:72-138` disables Add to Cart / Buy Now when `isOutOfStock`.
- `lib/features/product/presentation/bloc/product_detail_bloc.dart:380-381, 441-442` grouped item max qty from `associatedProduct.qty ?? grouped.qty`.
- `lib/features/product/presentation/widgets/product_booking_options_section.dart:964` event ticket increase capped by `ticket.qty`.
- `lib/features/product/presentation/widgets/product_attributes_section.dart:138-154` configurable option values disabled when no variant combination exists.
- `lib/features/home/data/models/home_models.dart:261` `isSaleable: json['isSaleable'] == true` (missing => false on home cards); `lib/core/recently_viewed/recently_viewed_products_service.dart:36,72` filters/default `isSaleable ?? true`.
- `lib/features/cart/data/repository/cart_repository.dart:62-90` `guestCheckoutAllowed` queries `product.guestCheckout` per cart item; only an explicit `0` blocks (:92-98); `cart_page.dart:79-95,1423` also checks `StoreConfig.allowGuestCheckout`.
- Add-to-cart `success:false` from server is treated as error (`test/add_to_cart_response_test.dart`). No client-side stock-quantity validation for simple/configurable items (the cart bloc sends quantities to the API).

### Auth tokens: obtain, store, refresh, send
- Obtain: `createCustomerLogin` mutation (`lib/core/graphql/auth_mutations.dart:4-16`) returns `apiToken`/`token`; `registerCustomer` also returns tokens. `AuthBloc._onLogin` uses `token ?? apiToken` (`lib/features/auth/presentation/bloc/auth_bloc.dart:199`). Login/register send the FCM `deviceToken` in the input (`auth_repository.dart:37, ~90`).
- Store: `shared_preferences` plain text (`lib/features/auth/domain/services/auth_storage.dart`: keys `auth_token`, `user_name`, `user_email`, `user_id`). No `flutter_secure_storage` or keychain/keystore package in pubspec.
- Refresh: none. No refresh-token flow, no 401/expiry interceptor on GraphQL (grep for `refreshToken`/`401` finds only REST download handlers in `invoice_detail_page.dart:1567` and `downloadable_products_page.dart:920`). Session ends only on explicit logout or `AuthCheckStatus` finding no stored token (`auth_bloc.dart:165-179`).
- Send: `Authorization: Bearer <token>` via `AuthLink` in `GraphQLClientProvider.buildClient(token:)` (`lib/core/graphql/graphql_client.dart:212`), `authenticatedClient(token)` (:322), plus headers `X-STOREFRONT-KEY` (all clients, :206/279/318), `X-CHANNEL` (value `channelCode`='default'), `X-LOCALE`, `X-CURRENCY` (added per request from SharedPreferences, :116-127), `Content-Type: application/json`. REST file downloads (Dio) send `Authorization` + `X-STOREFRONT-KEY` manually (`invoice_detail_page.dart:1436`, `downloadable_products_page.dart:727`, `product_attributes_section.dart:898`).
- The app-wide `AuthRepository`/`CategoryRepository`/`CartRepository`/`HomeRepository` are created with the unauthenticated `GraphQLClientProvider.client` (`lib/main.dart:470-480`; e.g. `AuthRepository(client: clientNotifier.value)` at :476); `AuthRepository.logout` (comment says "requires authenticated client") therefore posts via that unauthenticated client (`auth_repository.dart:~166-180`). Account/order pages build per-token clients (`account_page.dart:94`, `main.dart:238,400`, `thankyou_page.dart:241`, `add_review_page.dart:70`). Cart and checkout repositories use `buildClient(token: _token)` per call.
- Logging: `auth_repository.dart` debug-prints login token prefix (first 10 chars) and device token prefix (first 20 chars); `AuthBloc` prints token prefix (`auth_bloc.dart:217`). `_logApiMessage` gates GraphQL logging with `kDebugMode`; many `debugPrint` calls in repositories are not release-gated (Flutter `debugPrint` still prints in release unless overridden).
- Logout clears the four prefs keys, calls `createLogout` (sends deviceToken), clears the Hive cache (`graphql_client.dart:169-176`; note it constructs a new `HiveStore()` and resets it).

### Guest cart handling
- `createCartToken` mutation (`queries.dart:1382`, op name `CreateCart`) returns `sessionToken`/`cartToken`/`id`. `CartBloc._createFreshGuestCartState` (`cart_bloc.dart:270-287`) stores `bagisto_guest_cart_token` and `bagisto_guest_cart_id` in SharedPreferences (`cart_bloc.dart:206-207, 228-263`), and sends the guest token as `Authorization: Bearer <sessionToken>` (CartRepository doc, `cart_repository.dart:15-30`).
- On login `OnUserLoggedIn` switches the repository token to the access token and calls `createMergeCart` with the guest cart id; on logout `OnUserLoggedOut` clears the guest session and creates a new one (`main.dart:525-600`).
- Checkout uses two tokens: the Bearer (access or guest session) and a `cartToken` returned by `createCheckoutAddress` (for users equals user id per code comment) passed as `$token` to `collectionShippingRates`/`collectionPaymentMethods` (`checkout_repository.dart:105-135, 414, 451`).
- Guest checkout gating: `StoreConfig.allowGuestCheckout` (`guestCheckoutEnabled != false`) and per-product `guestCheckout` (see above); guest checkout skips saved addresses (`checkout_bloc.dart:428-440`).

### Checkout and payment
- Flow (`checkout_bloc.dart`): `InitCheckout` -> address (`createCheckoutAddress`) -> shipping rates (`collectionShippingRates`) -> `createCheckoutShippingMethod` -> payment methods (`collectionPaymentMethods`) -> on `PlaceOrder`: `createCheckoutPaymentMethod` then `createCheckoutOrder` (:1405-1460). Coupons via `createApplyCoupon`/`createRemoveCoupon` (checkout) and `ApplyCoupon`/`RemoveCoupon` (cart).
- Payment methods are whatever the server returns in `collectionPaymentMethods` (`PaymentMethod` model, `checkout_model.dart:233`). The UI maps icons only for codes `paypal_smart_button`, `paypal_standard`, `cashondelivery`, `moneytransfer` (`checkout_page.dart:2347-2363`); Maestro flows assume "Cash On Delivery"/"Flat Rate".
- `createCheckoutPaymentMethod` selects `paymentGatewayUrl` and `paymentData`; they are parsed into `CheckoutPaymentMethodResponse` (`checkout_model.dart:310-332`) but **never read anywhere else in lib/** (grep). There is no redirect/WebView step: after `createCheckoutOrder` succeeds the state moves to `orderPlaced` and `ThankyouPage` is shown. `flutter_inappwebview` is in pubspec but has zero imports in lib/ or test/. `url_launcher` is used only in `home_page.dart:203` (banner links, external app) and `product_booking_options_section.dart:1060` (Google Maps). No card-entry UI, no Stripe/PayPal SDK. Redirect-type gateways (PayPal etc.) would therefore not complete a payment in-app.
- `createCheckoutOrder` returns `id`, `orderId`, `success`, `message` (`orderIncrementId` removed because the server schema rejects it; comment at `checkout_queries.dart:155-162`).
- Suspended customers are blocked via `customerSuspension` query (`checkout_bloc` `isAccountSuspended`).

### Offline / caching
- No connectivity detection, no offline mode, no request queue (grep for connectivity/offline/SocketException finds only a Settings toggle). Settings "Offline Data" toggle (`settings_cubit.dart:124-134`) only toggles recently-viewed tracking and the search tag, and clears recently viewed.
- GraphQL cache: `initHiveForFlutter()` at startup (`main.dart:56`). Two client families: (a) `GraphQLClientProvider.client` / `authenticatedClient` use `HiveStore` (fallback `InMemoryStore`) with default query policy `networkOnly`; (b) `buildClient()` (10 call sites) uses `InMemoryStore` with default `noCache` for query and mutate. Per-call overrides across lib: `networkOnly` 34, `noCache` 23, `cacheAndNetwork` 14 (category/product queries in `category_repository.dart`), `cacheFirst` 6 (countries/states, one filter-products case). Because the shared category/home/cart/auth repositories are built with the Hive-backed `client`, `cacheAndNetwork` there can serve stale persisted data; user-specific caches are cleared on logout.
- SharedPreferences caches: channel locales/currencies/logo (`channel_bootstrap_service.dart:16-20`), currency symbols (`currency_formatter.dart:7`), selected locale/currency/theme, recently viewed products (`recently_viewed_products_service.dart:12`), recent searches (`search_bloc.dart:115`), FCM device token (`device_token_service.dart:9-10`), settings toggles, guest cart token/id.
- Image caching via `cached_network_image`. ML model is copied from assets to app documents dir (`mlkit_vision_service.dart:28-55`).

---------------------------------------------------------------------------

## lib/main.dart and lib/driver_main.dart
682 + 7 lines. `main()` initialises Firebase (placeholder options), Hive, SharedPreferences, `ChannelBootstrapService.bootstrap()` (`channel` query for id `channelId=1`), FCM (non-blocking), then `BagistoApp`. Provides repositories (Category, Cart, Auth, Home), blocs (Theme/Currency/Locale cubits, AuthBloc, CategoryBloc, CartBloc, HomeBloc, WishlistCubit, StoreConfigCubit), and `_AppWithAuthCartSync` for login/logout cart sync and notification navigation. A `_sendTestNotification` debug helper is called 2s after startup (`main.dart:115-120`, defined at :427; it only prints log lines). Notification topic `bagisto_mobikul` is subscribed in `fcm_service.dart:83,93,275`.

## lib/features/account (29,165 lines)
Largest feature; repository + models shared by dashboard, orders, invoices, shipments, returns, EU withdrawal, wishlist, compare, reviews, addresses, profile, downloads, CMS, contact, locales/currencies.
- Repository: `data/repository/account_repository.dart` (1,955 lines, `AccountRepository`). Models: `account_models.dart` (2,345), `returns_models.dart` (435), `review_attachment.dart` (75); util `review_attachment_encoder.dart` (62).
- Blocs/cubits (one file each, events then states):
  - `AccountDashboardBloc` (LoadAccountDashboard, RefreshAccountDashboard / AccountDashboardState)
  - `AddReviewBloc` (SubmitReview, ClearAddReviewMessage)
  - `AddressBookBloc` (LoadAddresses, RefreshAddresses, SetDefaultAddress, DeleteAddress, CreateAddress, UpdateAddress)
  - `CompareBloc` (LoadCompareItems, RemoveCompareItem, RemoveAllCompareItems, ClearCompareMessage)
  - `ContactUsCubit` (ContactUsState); `GuestEuWithdrawalCubit` (GuestEuWithdrawalState); `PreferencesCubit`, `SettingsCubit`
  - `CreateReturnBloc` (LoadCreateReturn, LoadMoreCreateReturnOrders, SelectOrderForReturn, BackToOrderPicker, ChangeResolutionType, SubmitReturn, ClearCreateReturnMessage)
  - `DownloadableProductsBloc` (LoadDownloadableProducts, LoadMoreDownloadableProducts, ClearDownloadableProductsMessage)
  - `EditAccountBloc` (LoadEditAccount, SaveProfile, ChangeEmail, ChangePassword, DeleteAccount, ClearEditAccountMessage)
  - `OrderDetailBloc` (LoadOrderDetail, LoadOrderInvoices, LoadOrderShipments, LoadShipmentDetail, ReorderOrder, CancelOrder, WithdrawFromContract, ClearOrderDetailMessage)
  - `OrdersBloc` (LoadOrders, LoadMoreOrders, ClearOrderMessage)
  - `ReturnDetailBloc` (LoadReturnDetail, LoadReturnMessages, SendReturnMessage, CancelReturn, CloseReturn, ReopenReturn, ClearReturnDetailMessage); `ReturnsBloc` (LoadReturns, LoadMoreReturns, CancelListedReturn, ClearReturnsMessage)
  - `ReviewBloc` (LoadReviews, LoadMoreReviews, ClearReviewMessage); `WishlistBloc` (LoadWishlist, LoadMoreWishlist, RemoveWishlistItem, MoveWishlistItemToCart, UpdateWishlistItemQuantity, ClearWishlistMessage)
- Pages (23): AccountMenuPage, AccountDashboardPage, EditAccountPage, AddressBookPage, AddAddressPage, OrdersPage, OrderDetailPage (2,298 lines), InvoiceDetailPage (1,640), ShipmentDetailBottomSheet, ReturnsPage, ReturnDetailPage, CreateReturnPage, ReviewsPage, AddReviewPage, ReviewVideoPlayerPage, WishlistPage, ComparePage (CompareProductsPage), DownloadableProductsPage, ContactUsPage, CmsPageDetailPage, GuestEuWithdrawalPage, PreferencesBottomSheet, SettingsBottomSheet. Widgets (13): AccountMenuItem, AddressCard, AddressFormField, DefaultAddressesSection, EditAccountFormField, ProductReviewsSection, ProfileHeader, QuickActionChips, RecentOrdersSection, ReviewAttachmentsStrip, ReviewVideoThumbnail, SectionHeader, WishlistSection.
- GraphQL ops used: 51 rows from account/returns/EU-withdrawal (see CSV features account, address, orders, wishlist, compare, reviews, returns, other).
- Money: client formatting/fallbacks at `account_models.dart:421,578-582,868,1228-1232,2095-2105,2164-2167`, `order_detail_page.dart:829-831,1197-1199`, `invoice_detail_page.dart:494,1103-1106`.
- Other: REST invoice PDF at `<origin>/api/shop/customer-invoices/{id}/pdf` via Dio (`invoice_detail_page.dart:1449, 1532`); downloadable product files via Dio (`downloadable_products_page.dart:738`). Review/return attachments are base64 data URIs in a JSON string in the GraphQL input (`review_attachment_encoder.dart`). Image upload for returns is not possible via GraphQL (plan.md).

## lib/features/auth (2,459 lines)
- Repository `auth_repository.dart` (221); model `auth_models.dart` (97); `AuthStorage` (`domain/services/auth_storage.dart`, 68, SharedPreferences); `auth_redirect.dart` (28; maps admin `loginRedirectTo` to a tab).
- Bloc: `AuthBloc` (events AuthLoginRequested, AuthRegisterRequested, AuthForgotPasswordRequested, AuthLogoutRequested, AuthCheckStatus; states AuthInitial, AuthLoading, AuthAuthenticated, AuthUnauthenticated, AuthRegistrationSuccess, AuthForgotPasswordSuccess, AuthError).
- Pages: LoginPage, SignUpPage, ForgotPasswordPage, AccountPage (logged-out view + dashboard host). Widgets: SocialLoginIcons (Google/Facebook/Apple SVG icons; display-only, no social SDK). `widgets/auth_button.dart` and `auth_text_field.dart` are empty (0 lines).
- Ops: loginCustomer, registerCustomer, forgotPassword, createLogout. Uses `bagisto_logo.svg` on login/signup/forgot/account pages.

## lib/features/cart (3,510 lines)
- `CartRepository` (541), `cart_model.dart` (460), `CartBloc` (903; events LoadCart, AddToCart, UpdateCartItemQuantity, RemoveFromCart, ClearCart, ApplyCoupon, RemoveCoupon, ClearCartMessage, OnUserLoggedIn, OnUserLoggedOut; single `CartState` with `CartStatus`), `CartPage` (1,606).
- Ops: productGuestCheckout; CreateCart; AddSimple/Configurable/Downloadable/Grouped/Bundle/BookingProductToCart (all root `createAddProductInCart`; mutation chosen per product type in `CartRepository.buildAddToCartRequest`, `cart_repository.dart:202`); GetCartItem (mutation root `createReadCart`); UpdateCartItem; RemoveCartItem; ApplyCoupon; RemoveCoupon; createMergeCart.
- Money: see cross-cutting table (cart_model.dart:276-283, cart_page.dart:1237-1293, 1345-1448). Success/error strings in `cart_bloc.dart` ('Item removed from cart', 'Coupon removed') are hardcoded English (not l10n).

## lib/features/category (8,349 lines)
- `CategoryRepository` (533, also hosts product listing/detail/related/filter/booking-slot queries), models `category_model.dart` (140), `filter_model.dart` (258), `product_model.dart` (1,865; products, variants, bundle, grouped, booking, downloadable, customizable options, reviews).
- Blocs: `CategoryBloc` (LoadCategories, SelectCategory, ShowCategory, LoadSubCategories, LoadCategoryProducts, LoadMoreProducts), `ProductListBloc` (LoadProductList, ApplySort, ToggleFilter, ClearAttributeFilters, ClearAllFilters, ApplyFilters, UpdatePriceRange, LoadMoreProductList).
- Pages: CategoryPage, CategoryProductsGridPage (1,407). Widgets: ProductGridSection, FilterBottomSheet (888), SortBottomSheet, BottomSortFilterBar, FilterChipRow, CategoryChipRow, SubCategorySection, CategoryBanner, CategorySearchBar, CategoryShimmer.
- Ops: treeCategories, CategoryTabCategories, Categories, GetProducts, getProducts (filter), GetRelatedProducts, GetProductById, GetProductByUrlKey, GetBooking* (5), FetchAttribute, CategoryAttributeFilter. `ProductQueries.getProductByUrlKey` (queries.dart:1296) has no references outside `lib/core/graphql` (unused).
- Money: `product_model.dart:101-159, 1470-1503`, `product_list_bloc.dart:229-235` (price range), `filter_bottom_sheet.dart:453-506`.
- Pagination: cursor-based (`first`/`after`, `pageInfo`), sort keys `NEWEST`/`PRICE`/`TITLE` + `reverse` (mapped in `home_bloc.dart:205-222`).

## lib/features/checkout (6,446 lines)
- `CheckoutRepository` (747), `checkout_model.dart` (427; BagistoCountry, BagistoCountryState, addresses, ShippingMethod, PaymentMethod, responses), `CheckoutBloc` (1,682; events InitCheckout, SyncCheckoutCart, SaveCheckoutAddressEvent, SelectSavedAddress, SelectShippingMethod, SelectPaymentMethod, ApplyCheckoutCoupon, RemoveCheckoutCoupon, ToggleSameAddress, PlaceOrder, ClearCheckoutMessage, ResetAddressConfirmation, FetchCountries, RefreshSavedAddresses, FetchCountryStates; single `CheckoutState`), pages CheckoutPage (2,938 lines), ThankyouPage (313), widgets CheckoutAddressSelectionSheet, CheckoutInteractionBlocker, helper `checkout_address_sheet_helpers.dart`.
- Ops (14 incl. shared address/country ones): see CSV feature checkout. `CheckoutPage` hardcodes English error strings in bloc (`'Please save your address first'` etc., `checkout_bloc.dart:1409-1420`).

## lib/features/home (3,904 lines)
- `HomeRepository` (135), `home_models.dart` (518), `HomeBloc` (LoadHome, RefreshHome; 255), `MainShell` (bottom tabs; 288), `HomePage` (836), widgets: ImageCarousel (banner ratio 1920:700), CategoryCarousel, ProductCardLarge/Small, StaticContentWidget (746; renders admin theme sections with `__media__` paths), ServicesContentSection, FooterLinksSection, RecentlyViewedProductsSection, SectionHeader.
- Ops: `sections` (theme customization sections), `Categories`, `GetProducts` (carousels with server-supplied filter/sort JSON).
- Money: discount % at `home_models.dart:302-321`.

## lib/features/product (7,814 lines)
- No repository of its own (uses `CategoryRepository`/`CartRepository`). Model `customizable_file_selection.dart` (32). `ProductDetailBloc` (913; events LoadProductDetail, RefreshProductDetail, SelectAttributeOption, SelectDownloadableLink, UpdateQuantity, UpdateGroupedProductQuantity, SelectBundleOptionProduct, UpdateBundleOptionProductQuantity, UpdateBookingField, UpdateCustomizableOption, UpdateBookingTicketQuantity, LoadBookingSlots, ToggleDescriptionExpanded, ToggleMoreInfoExpanded). `ProductDetailPage` (440).
- Widgets (15): ProductActionBar (sticky Add to Cart / Buy Now bar; wishlist/compare/share action row is in `product_attributes_section.dart` (Share via share_plus at :668)), ProductAttributesSection (configurable options, also sample download via Dio :910), ProductBookingOptionsSection (1,215; default, appointment, event tickets, rental, table), ProductBundleOptionsSection, ProductCustomizableOptionsSection (incl. file picker), ProductGroupedProductsSection, ProductInfoSection, ProductImageCarousel, FullscreenImageViewer (photo_view), ProductDescriptionSection (flutter_html), ProductMoreInfoSection, ProductRelatedSection, ProductReviewsSection, ProductDetailShimmer, review_entry.
- Ops: via category repository (product detail by type, booking, related) and cart add mutations.

## lib/features/search (3,962 lines)
- Text search: `SearchBloc` (InitSearch, SearchQueryChanged, SubmitSearch, ClearSearch, RemoveRecentSearch, ClearAllRecentSearches), `SearchPage` (1,113; voice input via speech_to_text), recent searches in SharedPreferences. Uses `GetProducts` with `$query`.
- Image search: `ImageSearchBloc` (InitImageSearch, CaptureImageEvent, SelectImageEvent, ProcessImageEvent, SelectLabelEvent, DeselectLabelEvent, ClearImageSearchEvent, RetryImageProcessingEvent), `ImageSearchScreen`, `LabelSelectionScreen`, services `MlKitVisionService` (on-device ML Kit labeling + object detection with `assets/ml/mobilenet_v2.tflite`), `GoogleVisionAIService` (Google Cloud Vision REST client in `vision_ai_service.dart:21-95`, takes an `apiKey`; **never instantiated** anywhere in lib/), `ImagePickerService`, `PermissionService`, `ImageSearchRepository`. Image search is feature-flagged by `storeConfig.imageSearchEnabled`.
- The model asset `assets/ml/mobilenet_v2.tflite` is gitignored (`.gitignore:58-59`) and absent from the repo, while `pubspec.yaml` lists `assets/ml/` as an asset directory.

## lib/features/splash (52 lines)
`SplashScreen` shows `assets/images/splash.png` (mobikul "For Bagisto" / "This is demo store..." artwork) full screen.

---------------------------------------------------------------------------

## lib/core/* modules

| Dir | Lines | Contents |
|---|---|---|
| `core/channel` | 181 | `ChannelBootstrapService`: `channel(id: channelId)` query at startup; caches locales, currencies, logo URL in SharedPreferences; picks default locale/currency |
| `core/constants` | 16 | `api_constants.dart` (tracked placeholders: `bagistoEndpoint`, `storefrontKey`, `channelCode='default'`, `channelId=1`, `companyName`) |
| `core/currency` | 127 | `CurrencyCubit`, `CurrencyFormatter` (see money table) |
| `core/error` | 322 | `ErrorMapper.getUserMessage` maps GraphQL/network errors to messages |
| `core/graphql` | 4,077 | `graphql_client.dart` (345; `GraphQLClientProvider`, `TimeoutHttpClient` 60s, `LoggingHttpClient`, header injection), `queries.dart` (2,025), `account_queries.dart` (1,096), `checkout_queries.dart` (221), `returns_queries.dart` (259), `eu_withdrawal_queries.dart` (70), `auth_mutations.dart` (61) |
| `core/locale` | 47 | `LocaleCubit` (`app_locale_code` pref), `locale_resolution.dart` |
| `core/navigation` | 100 | `app_navigator.dart` (InheritedWidget for bottom-tab switching), `route_observer.dart` |
| `core/notifications` | 856 | `FCMService` (522; FCM init, local notifications, topic `bagisto_mobikul`, tap routing), `FirebaseService`, `firebase_options.dart` (placeholder Firebase config), `DeviceTokenService` (prefs `fcm_device_token`), `notification_models.dart` |
| `core/recently_viewed` | 98 | `RecentlyViewedProductsService` (SharedPreferences JSON) |
| `core/store_config` | 293 | `StoreConfig` model (admin toggles, minimum order, buy-now, guest checkout, reviews...), `StoreConfigCubit`, `StoreConfigRepository` (`storeConfig` query, `networkOnly`) |
| `core/theme` | 313 | `app_theme.dart` (primary color #FF6900 per CLAUDE.md; `fontFamily: 'Roboto'` strings in some widgets, no bundled fonts), `ThemeCubit` |
| `core/utils` | 93 | `bloc_refresh.dart`, `file_download_helper.dart` (download path: external storage dir on Android, documents dir elsewhere; open via open_filex), `phone_validation.dart` |
| `core/widgets` | 768 | `AppBackButton`, `AppUpdateGate` (Android `in_app_update` immediate update; iOS `upgrader` store alert), `ChannelLogo` (channel logo else `bagisto_logo.svg`), `SelectionSheet` |
| `core/wishlist` | 241 | `WishlistCubit` (uses `AccountRepository` wishlist ops; requires auth token from `AuthStorage`) |

GraphQL ops by core module: `core/channel` -> getChannelByID; `core/store_config` -> storeConfig; the rest of `lib/core/graphql` only defines strings.
