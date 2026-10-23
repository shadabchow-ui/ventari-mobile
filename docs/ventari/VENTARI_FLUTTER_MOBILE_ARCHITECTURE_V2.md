# Ventari Flutter mobile architecture V2

**Status:** PROPOSAL, pending OD-41/OD-42/OD-43 and the VJ-142 measured spike. Supersedes the React Native + Expo default in `ventari-v2-plan/VENTARI_MOBILE_ARCHITECTURE_COMPARISON.md`; that comparison stays as the fallback analysis.
**Decision recorded:** the owner chose one Flutter codebase from the Bagisto fork (`shadabchow-ui/ventari-mobile`) for both iOS and Android. This document designs that path and states the conditions under which it should be reconsidered.

## 1. Shape of the system

```
 iOS app ─┐                         ┌─ /api/ventari/v2/*  catalog BFF v2 (exists) ── gateway v2 / R2 / D1 (canonical catalog)
          ├─ one Flutter codebase ──┤
 Android ─┘   (ventari-mobile)      └─ /api/ventari/m/v1/* mobile commerce BFF (VJ-170, new, Nitro)
                                          └─ Shopware Store API + VentariExternalCatalog plugin routes
                                             (offers, reservations, cart, tax, promotions, orders, refunds)
```

- **One origin:** the app talks only to the Nitro BFF. Shopware stays private, as it is for the web today: `VENTARI_SHOPWARE_URL` is server-only in `server/utils/ventariShop.ts`.
- **No second backend:** Bagisto/Laravel is not deployed. There is no catalog copy in the app beyond a bounded read cache, and no native Shopware product rows.
- **Same contracts as the web:**
  - Catalog: the same v2 routes the storefront uses.
  - Commerce: the same plugin routes (`/store-api/ventari/external-line-item`, `promotion`, `saved-items`) behind a header-token bridge instead of the web's cookie bridge.

## 2. Layering inside the app

| Layer | Source | Rule |
|---|---|---|
| Presentation (widgets, pages) | Bagisto, adapted | Reused; Ventari theme and component kit (VJ-173); no business logic |
| State (BLoC + equatable) | Bagisto, adapted | Bloc events and states reused where the flow matches; checkout state machine rewritten (VJ-150) |
| Repository interfaces | Bagisto signatures | Kept so blocs do not change; implementations switch per feature behind a flag |
| **Ventari data layer `lib/ventari/`** | **New (this branch)** | Typed clients and models from OpenAPI (VJ-131/132/133); Money in integer cents, display-only; availability as server classes; error envelope; idempotency keys |
| Session | New | Opaque token in Keychain/Keystore; refresh; revocation; biometric gate (VJ-145) |
| Platform channels | Flutter plugins | PSP SDK, push, secure storage, biometrics, app links |

What exists on this branch today (`lib/ventari/`, 48 tests passing):

- `VentariConfig`: endpoints come from `--dart-define`. The config refuses an empty, cleartext or credentialed endpoint.
- `Money`: integer cents and USD only. Display formatting uses integer arithmetic.
- `VentariCatalogClient`: wraps search, product (including the redirect outcome) and suggest. It retries only idempotent GETs, once, on retryable errors, and rejects off-contract responses.
- Catalog models: these mirror `ventariCatalogV2.ts` at `3ce4c2a` and keep `raw` JSON so no field is dropped.
- `IdempotencyKey` / `ActionKeys`: one key per user action, reused across retries.
- `VentariSessionStore`: interface only. The in-memory version is for tests. The Keychain/Keystore implementation is VJ-145.
- Guardrail tests: they fail CI on money arithmetic, SharedPreferences tokens, GraphQL imports or hard-coded endpoints inside `lib/ventari`.

## 3. Session and auth (OD-42)

1. **Guest:** `POST /m/v1/session/guest` returns an opaque token, an HMAC-signed id. The BFF maps it to a Shopware context token server-side.
2. **Login:** `POST /m/v1/session/login` rotates the token and merges the guest cart (VJ-057 semantics).
3. **Storage:** the token is stored with `flutter_secure_storage`: Keychain on iOS (`first_unlock_this_device`) and Keystore-backed EncryptedSharedPreferences on Android. It is never kept in plain preferences, logs or crash reports.
4. **Refresh:** on a 401 the app refreshes once, single-flight. A failed refresh logs the user out locally and keeps the guest cart where possible.
5. **Revocation:** logout, password change and account deletion revoke the token server-side.
6. **Biometrics:** `local_auth` can gate opening the account area and starting checkout. It never replaces server authentication. It is off by default, with a setting to enable it.

## 4. Commerce truth

- **Prices:** the app renders `priceCents`, `listPriceCents` and discount exactly as returned. Cart and checkout totals are server fields.
  - A guardrail test (extended from `lib/ventari` to `lib/` by VJ-149) forbids arithmetic on money.
  - The Bagisto client-side computations listed in the source audit §5 are removed.
- **Offers and quotes:** add-to-cart sends `{slug, sku, quantity}` plus an Idempotency-Key. The plugin mints the signed offer and the 60-second re-quote. A repriced notice is shown verbatim.
- **Availability:** `unknown` is not purchasable. Stock is never inferred from a missing field (the Bagisto default treated a missing `isSaleable` as in stock).
- **Orders:** the place-order request carries an Idempotency-Key. If the response is lost, the app recovers through `GET /m/v1/orders/lookup?key=` (VJ-136). Duplicate orders are therefore impossible by construction and tested by fault injection.
- **Payment (OD-43):** the PSP's official Flutter SDK sheet is used, with Apple Pay and Google Pay. The amount comes from the Shopware order (VJ-152). Success is shown only after the server confirms the payment event.
  - There is no WebView checkout and no in-app purchase for physical goods.
- **Offline:** catalog reads can be served from cache with an "may be outdated" label. No write is ever queued offline. Price and availability are re-fetched before add-to-cart.

## 5. Navigation and deep links

- Bagisto uses imperative `Navigator.push`. That is kept for in-app flows.
- A `go_router` table is added for the deep-link contract (VJ-139): `/p/<slug>`, `/c/<path>`, `/s?q=`, `/account/order/details/<id>`, `/saved`, `/checkout/cart`. It also handles push payloads (VJ-154).
- Unknown links fall back to search.
- Association files are served by the web (VJ-103).

## 6. Platform-specific work (kept separate, implemented once where shared)

| Concern | Shared Flutter | iOS-specific | Android-specific |
|---|---|---|---|
| Payments | checkout state machine | Apple Pay merchant id, entitlement | Google Pay manifest meta-data |
| Links | router | associated domains, AASA | intent filters, assetlinks, autoVerify |
| Push | handling, consent, routing | APNs entitlement, provisional auth option | POST_NOTIFICATIONS (API 33+), channels |
| Privacy | consent store, scrubbing | PrivacyInfo.xcprivacy, no ATT | Data safety form |
| Lifecycle | state restoration | scene restoration | process-death restore, predictive back, edge-to-edge |
| Accessibility | Semantics, text scaling, contrast | VoiceOver scripts | TalkBack scripts |
| Release | CI build | Xcode signing, TestFlight | Play App Signing, internal track |

## 7. Performance plan

- **Budgets** (VJ-158, measured in profile/release builds only):
  - cold start p90 ≤ 2 s on a mid-tier Android device and an iPhone two generations old;
  - PLP scroll raster p90 ≤ 16 ms;
  - no frame over 100 ms in core journeys;
  - Android release APK ≤ 40 MB after the VJ-172 removals.
- **Levers:**
  - remove ML Kit, camera and speech;
  - deferred loading of rarely used screens;
  - `cached_network_image` with server-provided sizes (VJ-119);
  - list item extents fixed where possible;
  - keep the Impeller renderer (Flutter default).

## 8. Risks and how they are handled

| Risk | Likelihood / impact | Mitigation | Re-decision trigger |
|---|---|---|---|
| The fork's data layer is deeply coupled to Bagisto models (account alone is 29k lines) | High / Medium | Keep repository interfaces; migrate feature by feature behind flags; delete Bagisto-only screens instead of adapting them | VJ-142 finds less than 40% of the slice's presentation reusable |
| A clean fork does not compile today (placeholder constants, missing ML assets) | Certain / Low | VJ-144 establishes a green baseline before any feature work | — |
| Flutter accessibility gaps (custom widgets without Semantics) | Medium / High | Automated guideline tests per screen plus manual VoiceOver/TalkBack scripts (VJ-157) | Serious issues persist after one remediation pass |
| PSP Flutter SDK maturity for Apple Pay/Google Pay | Medium / High | Choose the PSP (OD-06) with an official Flutter SDK; spike in VJ-151 | No supported SDK means OD-43 falls back to a hosted page in an SFSafariViewController/Custom Tab (not a WebView) |
| iOS cannot be built or tested on Linux | Certain / Medium | MACOS_XCODE resource lock; owner Mac or a budgeted hosted runner (OD-46); iOS gates never reported as passing from Linux | — |
| Upstream drift (Bagisto keeps changing) | Medium / Low | Treat upstream as a reference after VJ-144; cherry-pick security fixes only | — |
| Binary size and cold start vs fully native apps | Medium / Medium | Budgets enforced from VJ-158; removals in VJ-172 | Budget breach after optimisation means RN/native fallback analysis (VJ-102) |
| Licence/branding residue | Low / High (store rejection, trademark) | VJ-172 asset replacement and a licence gate in CI | — |

## 9. What does not change

- Mobile never blocks web launch. Every mobile job is LONG_TERM or LAUNCH_PARALLEL, and no launch-critical job depends on one.
- Foundations that also improve the web come early (M8–M12): idempotent add-to-cart (VJ-134), atomic quantity (VJ-135), retry-safe orders (VJ-136) and deletion completeness (VJ-137). Contracts (VJ-130–133) are also early because they are cheap and remove ambiguity.
- App feature work starts after the VJ-142 spike passes and the owner decides OD-41.
