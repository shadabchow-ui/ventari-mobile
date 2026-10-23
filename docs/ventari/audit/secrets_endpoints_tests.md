# Secrets, endpoints, tests, E2E, CI

Repo `/home/claude/ventari-mobile` @ `18a2c27`. Secret-like values are redacted to first 4 characters + length. A scan (AIza keys, AKIA, sk_live/test, PEM blocks, `eyJ` JWTs, `Bearer <token>`, password/secret literals) over the whole tree except `.git`, `pubspec.lock`, `package-lock.json` found **no real credentials**; every key-like value is a template placeholder.

## 1. Hardcoded endpoints, keys, tokens

| Location | Item | Value (redacted) | Notes |
|---|---|---|---|
| `lib/core/constants/api_constants.dart:1-3` | `bagistoEndpoint` | `http…` (len 38) = `https://your-bagisto-domain.com/graphql` | Placeholder; the file is **tracked in git** (`git ls-files` lists it) while plan.md says "never commit" real values. All GraphQL traffic, plus REST origin derivations (`Uri.parse(bagistoEndpoint).origin` in `account_models.dart:8`, `returns_models.dart:9`, `invoice_detail_page.dart:1531`, `downloadable_products_page.dart:810-814`) come from this one constant |
| `lib/core/constants/api_constants.dart:6-7` | `storefrontKey` | `your…` (len 24) = `your_storefront_key_here` | Placeholder. Sent as `X-STOREFRONT-KEY` header on all GraphQL clients (`graphql_client.dart:206,279,318`) and on Dio file downloads |
| `lib/core/constants/api_constants.dart:9-16` | `channelCode='default'`, `channelId=1`, `companyName='Your Company Name'` | n/a | `X-CHANNEL: default` header (`graphql_client.dart:121`); `channel(id: 1)` bootstrap query |
| `lib/core/notifications/firebase_options.dart:11-17` | Firebase `apiKey` | `A123…` (len 39) | Dummy sequential-digit key; `senderId` `0000…` (12), `projectId` `plac…` (28) `placeholder-firebase-project`, android/ios app ids `1:00…` (len 43), iOS bundle id `com.webkul.bagistoApp.iOS` |
| `android/app/google-services.json` | api_key `current_key` | `A123…` (len 39) | project_number `0000…` (12); package `com.webkul.bagisto.mobikul`; tracked |
| `ios/Runner/GoogleService-Info.plist` | API_KEY | `A123…` (len 39) | CLIENT_ID `0000…` (54), REVERSED_CLIENT_ID `com.…` (54), ANDROID_CLIENT_ID `0000…` (58), GOOGLE_APP_ID `1:00…` (43); tracked |
| `lib/features/search/data/services/vision_ai_service.dart:22` | Google Cloud Vision URL `https://vision.googleapis.com/v1/images:annotate`, key appended as `?key=$apiKey` (:95) | constructor param, no literal key | `GoogleVisionAIService` is defined but never constructed in lib/ |
| `maestro/config.yaml:10-14`, `maestro/env/sample.yaml` | Test credentials `demo.user@example.com` / `ExamplePass123!` (len 15), new user `new.user@example.com` | example values | Not real accounts as far as the repo shows |
| `test/store_config_account_test.dart:151` | `password: 'secret123'` | fixture | |
| `android/local.properties` (untracked, working tree) | `flutter.sdk` path | local path | not committed |

Token/secret *handling* facts (not literals): auth token and guest cart token are stored in SharedPreferences (plain text; see features.md); debug logs print token prefixes (`auth_bloc.dart:217`, `auth_repository.dart` login/register, `cart_bloc.dart:231-233`, `checkout_repository.dart:~135`). `_maskSensitiveHeaders` in the three Dio download helpers masks `Authorization` and `x-storefront-key` before logging (`invoice_detail_page.dart:1596`, `downloadable_products_page.dart:949`, `product_attributes_section.dart:1128`).

Other external endpoints named in lib/: `https://vision.googleapis.com/...` (unused path), `https://www.google.com/maps/search/?api=1&query=...` (`product_booking_options_section.dart:1057`), `https://api-docs.bagisto.com/...` (comments), Play/App Store links only in README. Everything else is derived from `bagistoEndpoint` (invoice PDF: `<origin>/api/shop/customer-invoices/{id}/pdf`; media/storage URLs resolved against the origin).

## 2. Tests under `test/`

82 Dart files (81 with cases + 1 helper `store_config_fakes.dart`), **359** `test(`/`testWidgets(` declarations (loop-generated cases such as `for (final ...) test(...)` run more than once, so the runtime count is higher). Style: fake repositories subclass the real repository with a dummy `GraphQLClient`; blocs seeded through `seedState` subclasses (see `test/orders_bloc_test.dart`). `flutter test` was not run in this inventory (read-only task). CLAUDE.md states `test/address_debug_payload_test.dart` fails on a clean tree and `flutter analyze` reports ~49 info/warnings in category/home/search.

| File | Cases | Covers (first group/case names) |
|---|---|---|
| `test/account_address_input_test.dart` | 2 | Cases: buildCustomerAddressMutationInput omits useForShipping for account add edit flow; buildSetDefaultCustomerAddressMutationInput includes full address payload and omits useForShipping |
| `test/account_dashboard_helper_test.dart` | 4 | Groups: resolveDashboardDefaultAddress. Cases: returns null when address list is empty; returns the default address when one exists |
| `test/account_dashboard_refresh_test.dart` | 1 | Cases: RefreshAccountDashboard completes its completer when done |
| `test/account_models_test.dart` | 24 | Groups: CustomerProfile; CustomerAddress. Cases: fromJson parses correctly; displayName trims correctly |
| `test/account_pull_to_refresh_test.dart` | 6 | Cases: orders list: pulling down reloads with the current filter; orders empty state: pulling down reloads |
| `test/add_address_page_test.dart` | 2 | Cases: account add address form shows only one Set as Default toggle; account edit address form also shows only one Set as Default toggle |
| `test/add_review_page_test.dart` | 9 | Groups: media attachments. Cases: required review fields are marked before submission; submitting an empty review shows inline required errors and does not submit |
| `test/add_to_cart_response_test.dart` | 2 | Cases: success:false from addProductInCart is an error with its message; successful payload parses into the cart |
| `test/address_book_navigation_helper_test.dart` | 2 | Cases: refreshes address book when address form returns true; does not refresh address book when address form returns false or null |
| `test/address_debug_payload_test.dart` | 1 | Cases: buildEditAddressDebugPayload includes saved address data and address id |
| `test/address_state_field_behavior_test.dart` | 2 | Cases: resolveStateFieldText preserves saved state text when country has no states; shouldUseStateDropdown is false when country has no states |
| `test/april_10_fixes_test.dart` | 2 | Groups: April 10 fixes. Cases: address book no longer exposes a select address action; image carousel uses contain fit so banners are never cropped |
| `test/bloc_refresh_test.dart` | 2 | Cases: refreshBloc waits for the finishing state; refreshBloc gives up after the timeout |
| `test/booking_availability_test.dart` | 5 | Cases: default "one" booking is bookable on the from_day..to_day ranges; per-day slots allow only days that have slots |
| `test/booking_event_ticket_test.dart` | 1 | Groups: BookingEventTicket. Cases: reads name and description from translation when top-level fields are absent |
| `test/cancel_order_bloc_test.dart` | 10 | Groups: OrderDetail.canCancel. Cases: is true for pending/processing, false otherwise; CancelOrder success emits cancelSuccess with refreshed order |
| `test/cart_page_test.dart` | 2 | Cases: tapping a red cart heart removes from wishlist without removing cart item; coupon code stays in the field while it is being applied |
| `test/category_show_category_test.dart` | 2 | Cases: ShowCategory loads categories first and selects the requested one; ShowCategory ignores ids that are not top-level categories |
| `test/category_status_filter_test.dart` | 5 | Cases: home categories query requests status; CategoryModel.isActiveStatus |
| `test/category_tab_categories_test.dart` | 7 | Cases: category tab query uses the categories API with parent and children; tab shows top-level active categories except Root, sorted by position |
| `test/channel_locale_refresh_test.dart` | 2 | Cases: preferences refresh the channel locales and currencies; channel locale codes resolve to a supported UI locale |
| `test/channel_logo_test.dart` | 3 | Cases: bootstrap caches the channel logo and clears it when removed; logo falls back to the bundled one without a channel logo |
| `test/checkout_address_sheet_test.dart` | 14 | Cases: findNewlyAddedSelectableAddress resolves the new saved address from customer ids; findNewlyAddedCheckoutAddress returns the first new address by id |
| `test/checkout_customer_email_test.dart` | 3 | Cases: logged-in checkout addresses carry the account email; without an account email the input is unchanged |
| `test/checkout_flow_test.dart` | 41 | Groups: CheckoutAddressResponse; CheckoutShippingMethodResponse. Cases: parses cartToken (user ID) from createCheckoutAddress response; handles null cartToken gracefully |
| `test/checkout_interaction_blocker_test.dart` | 2 | Cases: allows taps when not blocking; blocks taps and shows progress while blocking |
| `test/checkout_suspended_customer_test.dart` | 2 | Cases: suspended customer cannot start checkout; active customer continues to the address step |
| `test/contact_us_page_test.dart` | 3 | Cases: required contact fields are marked with an asterisk; texts match the storefront contact form |
| `test/create_product_review_repository_test.dart` | 3 | Cases: omits attachments when none are given; sends attachments as a JSON string of data URIs |
| `test/create_return_bloc_test.dart` | 2 | Cases: order picker lists only orders eligible for a return; items with nothing left to return are not offered |
| `test/customer_order_query_test.dart` | 1 | Cases: customerOrder query requests the order id |
| `test/customizable_options_test.dart` | 5 | Groups: ProductModel customizableOptions; Cart custom option payload. Cases: parses Bagisto customizable option connection with prices; normalizes supported file extensions |
| `test/default_addresses_section_test.dart` | 1 | Cases: shows only the resolved default address without billing or shipping labels |
| `test/edit_account_required_fields_test.dart` | 2 | Cases: phone and gender are required before saving the profile; empty gender and invalid phone from the profile are rejected |
| `test/error_mapper_context_test.dart` | 3 | Cases: unmapped GraphQL errors keep the step context; untranslated server keys are not shown to users |
| `test/eu_withdrawal_repository_test.dart` | 3 | Cases: reads whether EU withdrawal is enabled; finds the withdrawal request for an order |
| `test/guest_checkout_check_test.dart` | 1 | Cases: only an explicit "0" guestCheckout blocks guest checkout |
| `test/guest_eu_withdrawal_test.dart` | 4 | Cases: form uses the app input field style; guest submits order number, email and reason |
| `test/home_category_carousel_test.dart` | 4 | Cases: carousel without filters shows every active category, like the web; carousel parent_id filter keeps only that parent\'s children |
| `test/home_product_carousel_filters_test.dart` | 3 | Cases: carousel with empty filter list has no filters and the admin title; title falls back to the section name |
| `test/home_refresh_test.dart` | 2 | Cases: home pull-to-refresh reloads home and store config; home refresh still works without a store config cubit |
| `test/home_theme_fixes_test.dart` | 9 | Cases: homepage sections use the sections API and refetch fresh content; home categories keep only direct children of the carousel parent |
| `test/image_carousel_ratio_test.dart` | 2 | Cases: banner is 1920:700 at width $width; tapping a linked banner reports it |
| `test/invoice_detail_page_test.dart` | 1 | Cases: invoice item uses More info flow for selected options |
| `test/login_redirect_test.dart` | 2 | Cases: admin login redirect picks the tab to open; store config query asks for loginRedirectTo |
| `test/main_shell_navigation_helper_test.dart` | 4 | Cases: cart tab request is ignored when the cart page is disabled; re-requesting cart tab while already on cart still refreshes cart |
| `test/numeric_id_parsing_test.dart` | 16 | Groups: CategoryModel; product child models accept string _id. Cases: fromTreeJson accepts string _id and position; fromTreeJson still accepts int _id and position |
| `test/order_detail_page_test.dart` | 9 | Cases: Refunds tab matches the storefront view; Reorder is hidden when the cart page is disabled |
| `test/order_shipment_query_test.dart` | 1 | Cases: shipment detail query takes an ID! and sends the shipment IRI |
| `test/orders_bloc_test.dart` | 1 | Cases: LoadMoreOrders uses the current end cursor and appends the next page |
| `test/phone_validation_test.dart` | 1 | Cases: phone numbers follow the storefront rule, not a fixed length |
| `test/product_info_section_test.dart` | 4 | Cases: shows short description for a simple product; short description sits between price and stock |
| `test/product_out_of_stock_test.dart` | 3 | Cases: out-of-stock state follows isSaleable from the API; out-of-stock product cannot be added to cart or bought |
| `test/recent_orders_section_test.dart` | 1 | Cases: tapping a recent order opens it by database id |
| `test/recently_viewed_products_service_test.dart` | 2 | Cases: tracks products when the preference has never been written; does not track products when recently viewed is disabled |
| `test/returnable_items_repository_test.dart` | 1 | Cases: returnable items request uses only orderId and reads a plain list |
| `test/returnable_orders_repository_test.dart` | 1 | Cases: returnable orders keep only orders with returnable quantity |
| `test/returns_bloc_test.dart` | 2 | Cases: LoadMoreReturns uses the current end cursor and appends the next page; LoadReturns surfaces repository errors as error status |
| `test/returns_models_test.dart` | 9 | Groups: CustomerReturn.fromJson; ReturnableItem. Cases: parses a full node with decoded item and images; parses item/images sent as JSON-encoded strings |
| `test/returns_mutations_repository_test.dart` | 2 | Cases: create return uses the server input type and submits the form values; cancel return wraps the return IRI in the required input object |
| `test/returns_navigation_test.dart` | 8 | Cases: a pending cancellation disables actions and ignores duplicate requests; View opens a solved return and Cancel asks for confirmation |
| `test/returns_refresh_test.dart` | 3 | Cases: pagination can recover after a refresh fails with existing returns; refresh ignores a stale pagination ${fails ?  |
| `test/review_attachment_encoder_test.dart` | 6 | Cases: mimeTypeFor maps supported image and video extensions; encode returns a JSON string array of data URIs |
| `test/review_attachment_test.dart` | 5 | Groups: ReviewAttachment.parseList. Cases: parses the JSON string returned by the API; parses an already decoded list |
| `test/review_attachments_strip_test.dart` | 2 | Cases: renders nothing when there are no attachments; renders an image tile and a video tile with play icon |
| `test/review_card_navigation_test.dart` | 1 | Cases: tapping a review card reports the reviewed product |
| `test/review_models_attachments_test.dart` | 5 | Cases: account ProductReview parses attachments; account ProductReview defaults to no attachments |
| `test/review_video_thumbnail_test.dart` | 3 | Cases: falls back to a play tile when the video cannot load; file source renders a play tile |
| `test/static_content_offer_test.dart` | 6 | Cases: renders the home offer text like the storefront; decodes entities and strips inner tags |
| `test/static_content_sections_test.dart` | 4 | Cases: collection card titles show text, not HTML tags; __media__ image paths resolve to the storage folder |
| `test/store_config_account_test.dart` | 5 | Cases: account menu hides Wishlist and Compare when switched off; account menu keeps Wishlist and Compare by default |
| `test/store_config_buy_now_test.dart` | 4 | Cases: buy now flag reads both API key names; Buy Now is hidden when the admin toggle is off |
| `test/store_config_cart_test.dart` | 9 | Cases: cart item has no wishlist heart when wishlist is off; guest Pay Now opens login when guest checkout is off |
| `test/store_config_fakes.dart` | 0 | Shared fake repositories/cubit for store_config tests (helper, no cases) |
| `test/store_config_product_actions_test.dart` | 3 | Cases: Share is hidden when social share is off in admin; Share shows when social share is on |
| `test/store_config_reviewer_name_test.dart` | 3 | Cases: censored names match the storefront format; reviewer name shows as Censored when admin censors names |
| `test/store_config_reviews_test.dart` | 4 | Groups: reviewEntryFor. Cases: logged-in customer follows customerReviewEnabled; guest writes, signs in, or sees nothing |
| `test/store_config_search_test.dart` | 1 | Cases: search page ${hidden ?  |
| `test/store_config_test.dart` | 14 | Groups: StoreConfig.fromJson; StoreConfig getters. Cases: parses the server payload; keeps missing fields null |
| `test/store_config_wishlist_test.dart` | 2 | Cases: ${entry.key} hides the heart when wishlist is off; ${entry.key} shows the heart when the API is silent |
| `test/strikethrough_price_test.dart` | 4 | Cases: home cards strike the regular price for discounted products; product model strikes the regular price for discounted products |
| `test/widget_test.dart` | 1 | Smoke test: app starts without errors |
## 3. Maestro E2E (`maestro/`)

- `maestro/config.yaml`: global env for flows (CLI example: `maestro test maestro/flows/android/full_app_flow.yaml --config maestro/config.yaml --device emulator-5554`): app ids `com.webkul.bagisto.mobikul` / `com.webkul.bagistoApp.iOS`; sample credentials; product under test "Apple iPhone Smartphone" (Medium/Blue); filter "In Stock"; sort "Price: Low to High"; checkout fixture address (QA User, 123 Test Street, Testville, CA 94105, +14155550123, United States); shipping "Flat Rate"; payment "Cash On Delivery"; label selectors for tabs/buttons; some percent-coordinate `*_point` values (the label-based instructions file says not to use `point:`).
- `maestro/env/sample.yaml`: template env file to copy (`--env`). `maestro/scripts/generate_signup_email.js`: generates a unique signup email. `maestro/LABEL_BASED_INSTRUCTIONS.md`: rule to use label selectors, not points.
- Flows, all Android only (`maestro/flows/android/`, 1,209 lines of YAML incl. helpers): `auth_login_valid`, `auth_login_invalid`, `auth_signup`, `auth_logout`, `auth_forgot_password`, `home_navigation`, `category_catalog`, `product_simple`, `product_configurable`, `cart_flow`, `checkout_guest`, `checkout_customer`, `order_flow`, `full_app_flow` (85 lines), `full_app_flow_attached` (300 lines; attaches to a running app), `debug_buy_now_path`; helpers: `dismiss_runtime_permissions`, `ensure_guest_account_screen`, `login_existing_customer`, `normalize_to_home_attached`, `open_login_from_account`. No iOS flows. Flows require a live Bagisto backend with demo data (they reference demo product names and "Cash On Delivery"). Some flows hardcode `appId: com.webkul.bagisto.mobikul` rather than `${APP_ID_ANDROID}`.
- `maestroContext/instruction.md` and `.agents|.claude|.kilocode/skills/maestro-mobile-testing` are AI-agent skill documents (third-party `tovimx/maestro-mobile-testing-skill`, hash in `skills-lock.json`).

## 4. CI configuration

**None.** `.github/` contains only `ISSUE_TEMPLATE/{bug_report,custom,feature_request}.md`. There is no `.github/workflows/`, no Codemagic/Fastlane/Bitrise/GitLab CI file, and no pre-commit config in the repo root. Docs: `Docs/` has setup guides (`installationGuide.md`, `ConfigGuide.md`, `ServerConfig.md`, Firebase guides for Android/iOS, `LanguageConfiguration.md`, `ColorSetUp.md`, `PlaceholderSetup.md`), `Docs/ai-memory/` (3 dated fix notes), `Docs/backend-issues/` (2 notes), `Docs/superpowers/{specs,plans}`.

## 5. Other repository hygiene facts
- Git: 51 commits, branches `main` and `claude/project-thread-wxblpa` (+ their `origin/` refs); `.git` is 5.3 MB.
- Committed placeholder Firebase config means FCM is effectively disabled until replaced (iOS code explicitly skips registration for the placeholder project id).
- `test/home_theme_fixes_test.dart` contains a private LAN IP (`192.168.15.239`) in fixtures; Docs mention `api-demo.bagisto.com` and `test-delivery.bagisto.com`.
