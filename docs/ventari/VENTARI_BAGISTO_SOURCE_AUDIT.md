# Bagisto Flutter source audit for Ventari

**Status:** PROPOSAL, not accepted. Branch `proposal/ventari-flutter-adaptation-20261023`.
**Source pinned:** `shadabchow-ui/ventari-mobile` `main` = upstream `bagisto/opensource-ecommerce-mobile-app` at `18a2c27c6d25a2e98a1bc84b69328e72d6a5bded` (51 commits, all by the upstream author `SocialMobikul`, last 2026-10-19). Fork and upstream were identical when inspected on 2026-10-23.
**Toolchain used:** Flutter 3.47.7 (Dart 3.13.5) on Linux. No Android SDK, Xcode or device was available here, so no platform build was run.
**Raw inventory (mechanical, cited file:line):** [`audit/`](audit/): `graphql_operations.csv`, `features.md`, `dependencies.csv`, `assets_and_branding.md`, `platform_config.md`, `secrets_endpoints_tests.md`.

## 1. Verdict

The fork is a credible starting point for Ventari's presentation layer, but not for its data, auth or checkout layers.

- **Reuse:** screens, widgets, BLoC state machines, l10n plumbing and the Maestro flow structure.
- **Replace:** the whole Bagisto GraphQL data layer (105 operations), auth/token storage, cart and checkout logic, store configuration and branding.
- **Remove:** product types, EU features and native SDKs that Ventari does not ship at v1.

Flutter itself fits Ventari's requirement of one codebase that is native-feeling on both platforms. It compiles to native ARM code, is not a WebView, and has mature accessibility semantics on both platforms. The main costs of Flutter are:

- a larger binary than fully native apps;
- platform-specific work for Apple Pay and Google Pay, universal links and push;
- a less "native" feel by default, which needs Cupertino-aware widgets where iOS users expect them.

None of these blocks the plan. VJ-142 measures them before scaling.

## 2. Baseline as checked (2026-10-23)

| Check | Result |
|---|---|
| `flutter pub get` | OK (Flutter 3.47.7 rewrites `pubspec.lock` and `analysis_options.yaml`; reverted, not committed) |
| `flutter test` at 18a2c27 | **288 pass, 19 test files fail to compile** |
| Root cause of the compile failures | `lib/core/constants/api_constants.dart` is a committed placeholder that lacks `bagistoPublicBaseUrl`, which `home_page.dart:201,583` and `image_carousel.dart:80` require. `pubspec.yaml` also declares `assets/ml/`, which `.gitignore:58-59` excludes, so the directory is missing. **A fresh clone does not compile.** |
| `flutter analyze lib/ventari test/ventari` (new code on this branch) | No issues |
| `flutter test test/ventari` (new code on this branch) | **48 pass, 0 fail** |
| Android build | **NOT RUN** (no Android SDK in this environment) |
| iOS build | **NOT RUN** (requires macOS and Xcode) |
| CI | none (only `.github/ISSUE_TEMPLATE`) |

## 3. Licence and attribution

- `LICENSE`: MIT, © Webkul Software Private Limited. It must stay in the repository and in the app's licence screen (`showLicensePage` already aggregates package licences).
  - Add a `NOTICE` crediting Bagisto/Webkul (VJ-144).
  - Android `res` files carry a comment citing a Webkul store licence. Replace these files rather than keep them.
- Bundled assets:
  - `bagisto_logo.svg`, `splash.png` and every launcher icon are Webkul/Mobikul artwork. The splash even reads "This is demo store…". All must be replaced (VJ-172).
  - The Google, Facebook and Apple glyphs are third-party marks shown without their sign-in SDKs. Remove them unless social login is approved.
- No fonts are bundled. Roboto and Material Icons come from the platform or SDK under Apache-2.0.
- `assets/ml/mobilenet_v2.tflite` is expected but absent, so its origin and licence are unknown. The feature should be disabled (§6).
- Dependency licences are listed in `audit/dependencies.csv`. All are permissive where verified (MIT/BSD/Apache-2.0). `intl` is not verified. VJ-172 adds a CI licence gate.

## 4. Security findings

| # | Finding | Evidence | Ventari action |
|---|---|---|---|
| S1 | Customer and guest tokens are stored in plain `shared_preferences`; no secure storage | `auth_storage.dart`; keys `bagisto_guest_cart_token`, `bagisto_guest_cart_id` | VJ-145: Keychain/Keystore only, refresh + revocation |
| S2 | Debug logs print token prefixes | `features.md` §Auth | Remove; MASVS check (VJ-166) |
| S3 | No 401 handling or refresh | `features.md` §Auth | Single-flight refresh (VJ-145) |
| S4 | Logout runs on the unauthenticated client | `main.dart:476` | Server revocation via BFF (VJ-145/VJ-170) |
| S5 | Android release builds are signed with the debug key; R8 disabled | `platform_config.md` | VJ-159 signing, VJ-164 R8 |
| S6 | Placeholder Firebase configs are tracked (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) | `secrets_endpoints_tests.md` | Per-flavor configs injected by CI (VJ-159) |
| S7 | Upstream iOS `DEVELOPMENT_TEAM` (MPFH69ZV5Q) is committed | `platform_config.md` | Replace with the Ventari team (OD-44) |
| S8 | No real secrets found (values redacted in audit) | `secrets_endpoints_tests.md` | Keep a secret scan in CI |
| S9 | `graphql_flutter` and `flutter_html` use beta constraints | `dependencies.csv` | Removed with the GraphQL layer; `flutter_html` replaced by plain text rendering of envelope descriptions |

## 5. Commerce-truth findings (against Ventari invariants)

| Ventari invariant | Bagisto behaviour | Location | Ventari action |
|---|---|---|---|
| Client never computes a charged total | Line total = price × quantity; minimum-order arithmetic gates Pay Now; `discountPercent` computed in three places; order `totalDue` and refund fallback derived | `cart_model.dart:276-283`, `store_config.dart:147-168`, `cart_page.dart:1345-1419`, `product_model.dart:108-125`, `home_models.dart:314-321`, `product_info_section.dart:130`, `account_models.dart:2164`, `order_detail_page.dart:829` | Server fields only; guardrail test forbids money arithmetic in `lib/ventari` (VJ-171), extended to `lib/` in VJ-149 |
| Availability is a server decision; fail closed | `isSaleable`/`qty`/`guestCheckout` decided client-side; missing `isSaleable` = in stock | `product_detail_bloc.dart:217`, `product_info_section.dart:292`, `cart_repository.dart:62` | `Variant.canAddToCart` requires sellable + price + in/low stock; unknown = not purchasable |
| Server-quoted price with signed re-quote | Prices from GraphQL product fields | — | Offer minted by the plugin on add-to-cart; the app sends slug/sku/quantity only |
| Idempotent mutations | None | — | `ActionKeys` per user action (VJ-134/136/149/150) |
| No WebView checkout; PSP sheet | Places orders directly; `paymentGatewayUrl` parsed but unused, so redirect gateways cannot complete | `features.md` §Checkout | PSP SDK sheet (VJ-151/152) |
| No fabricated social proof | Ratings shown from the Bagisto API | — | Shown only when the envelope carries them; reviews deferred to first-party data (VJ-169) |

## 6. Feature inventory and classification

Line counts exclude generated l10n. KEEP means reuse unchanged; ADAPT means reuse the UI and state while rewiring data; REPLACE means rewrite against Ventari contracts; REMOVE means delete or disable.

| Module | Lines | Contents (summary) | Class | Ventari job |
|---|---:|---|---|---|
| `features/home` | 3,904 | home page, image carousel, Bagisto theme "sections" | ADAPT | VJ-146 (rails from catalog BFF; drop CMS sections) |
| `features/category` | 8,349 | category tree, tabs, PLP, attribute filters | ADAPT | VJ-146 |
| `features/search` | 3,962 | text search, suggestions, **image search (ML Kit), voice search** | ADAPT / REMOVE (image + voice) | VJ-147, VJ-172 |
| `features/product` | 7,814 | PDP, gallery, configurable options, reviews, related; **booking, downloadable, grouped, bundle types** | ADAPT / REMOVE (non-simple types) | VJ-148 |
| `features/cart` | 3,510 | cart page, coupons, guest cart token | REPLACE (data) / ADAPT (UI) | VJ-149 |
| `features/checkout` | 6,446 | address, shipping, payment, place order | REPLACE | VJ-150, VJ-151 |
| `features/auth` | 2,459 | login, sign-up, forgot password, social icons | ADAPT (UI) / REPLACE (token) | VJ-145, VJ-153 |
| `features/account` | 29,165 | profile, addresses, orders, invoices, shipments, reviews, wishlist, compare, downloadables, **returns (RMA)**, **EU withdrawal**, GDPR, contact, CMS pages | ADAPT (profile, addresses, orders, returns UI) / REMOVE (downloadables, EU withdrawal) / DEFER (compare, reviews) | VJ-153, VJ-175, VJ-169 |
| `features/splash` | 52 | splash | REPLACE (branding) | VJ-172 |
| `core/graphql` | 4,077 | client and 7 query files | REPLACE → `lib/ventari` | VJ-171 |
| `core/store_config`, `core/channel`, `core/currency`, `core/locale` | 648 | Bagisto admin configuration, channels, currencies | REPLACE (config endpoint) / REMOVE | VJ-160, VJ-144 |
| `core/theme`, `core/widgets` | 1,081 | colours, shared widgets | ADAPT to Ventari tokens | VJ-173 |
| `core/notifications` | 856 | FCM + local notifications, topic `bagisto_mobikul` | ADAPT | VJ-106, VJ-155 |
| `core/navigation` | 100 | imperative navigation helpers | ADAPT (+ declarative deep-link router) | VJ-154 |
| `core/recently_viewed`, `core/wishlist` | 339 | local recently viewed; wishlist service | KEEP (recently viewed) / ADAPT (saved items) | VJ-146, VJ-153 |
| `core/error`, `core/utils` | 415 | error mapper, helpers | ADAPT to the Ventari error envelope | VJ-171 |
| `l10n` (10 locales) | generated | ARB files + generated localizations | KEEP plumbing; ship en-US at launch | VJ-144 |
| `maestro/` | — | label-based E2E flows | ADAPT for Ventari journeys | VJ-167 |
| `test/` | 82 files / 359 tests | unit + widget tests for Bagisto models/blocs | KEEP where the bloc is reused; retire tests of removed features | VJ-144 |
| `linux/`, `macos/`, `windows/`, `web/` | — | desktop/web runners | REMOVE (no product need; reduces CI surface) | VJ-144 |

## 7. Dependencies to remove or replace at v1

| Package | Why | Job |
|---|---|---|
| `graphql_flutter`, `graphql` (beta constraint) | Bagisto data layer replaced | VJ-171 |
| `google_mlkit_image_labeling`, `google_mlkit_object_detection`, `camera`, `image_picker`*, `image`, `flutter_image_compress` | image search and return-attachment upload; model asset missing; heavy binaries and permissions | VJ-172 (*keep `image_picker` only if returns need photos) |
| `speech_to_text` | voice search; microphone permission | VJ-172 |
| `flutter_inappwebview` | zero imports; Ventari forbids WebView checkout | VJ-172 |
| `carousel_slider`, `flutter_staggered_grid_view`, `flutter_rating_bar`, `provider`, `device_info_plus`, `package_info_plus` (if unused), `cupertino_icons` (if unused) | no imports in `lib/` or `test/` | VJ-172 |
| `in_app_update`, `upgrader` | replaced by the server-driven minimum version (VJ-160) | VJ-160 |
| `flutter_html` (beta) | descriptions render as text from the envelope | VJ-148 |
| `shared_preferences` | keep for non-sensitive preferences only; never tokens | VJ-145 |
| add `flutter_secure_storage`, `local_auth`, `go_router`, PSP SDK | session, biometrics, deep links, payments | VJ-145, VJ-154, VJ-151 |

## 8. Platform configuration to change

- **Identity:** the Android `applicationId` `com.webkul.bagisto.mobikul` and iOS bundle id `com.webkul.bagistoApp.iOS` become Ventari ids (OD-44). Display names are currently "Mobikul Bagisto Laravel App" and "Bagisto Store".
- **Versions:** they disagree (pubspec 2.4.7, Android 2.4.6, iOS 2.56.0, CHANGELOG 2.5.2). Make CI the single source of build numbers.
- **Android:**
  - Current state: minSdk 24, target/compile 36, AGP 8.9.2, Kotlin 2.2.20.
  - Missing: App Links intent filters, R8, and the google-services plugin.
  - `namespace` differs from `applicationId`.
- **iOS:**
  - The deployment target is inconsistent: the Podfile says 15.5 while the project says 13.0. Settle on 16.0 and check it in VJ-165.
  - `aps-environment` is development.
  - Missing: associated domains, URL schemes and a privacy manifest.
- **Upstream sync policy:** after VJ-144 renames and restructures the code, treat upstream as a reference rather than a merge source. Cherry-pick only security and widget fixes, through reviewed PRs, and record the upstream SHA in `NOTICE`.

## 9. Repository instruction conflict (needs owner confirmation)

The fork carries upstream's own agent rules (`CLAUDE.md`, `plan.md`): "Bagisto GraphQL API only", "never REST", "validate against the configured Bagisto server". These rules directly contradict the owner's Ventari decision to replace the Bagisto backend.

This branch adds a Ventari override section at the top of `CLAUDE.md`, which points to `docs/ventari/README.md`, and leaves `plan.md` intact as upstream history. When the proposal is merged, replace both files with Ventari rules (VJ-144).
