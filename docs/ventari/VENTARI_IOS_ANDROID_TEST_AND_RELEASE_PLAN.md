# Ventari iOS and Android test and release plan

**Status:** PROPOSAL. No App Store or Google Play release is authorized by this plan.
**Rule:** a result counts only if it was run at a named commit, in a named environment, and its evidence is recorded. An iOS check that was not run on macOS is reported as **NOT RUN**, never as passing.

## 1. What was run for this proposal (2026-10-23, Linux, Flutter 3.47.7)

| Check | Result |
|---|---|
| `flutter test` on upstream `18a2c27` | 288 pass; 19 test files fail to compile (fork does not build from a clean clone; see the source audit §2) |
| `flutter test test/ventari` on this branch | **48 pass, 0 fail** |
| `flutter analyze lib/ventari test/ventari` | **No issues** |
| Android build | **NOT RUN**: no Android SDK in this environment |
| iOS build, simulator, VoiceOver, signing | **NOT RUN**: requires macOS and Xcode |
| Device E2E (Maestro) | **NOT RUN** |

## 2. Test layers

| Layer | Tooling | Runs on | Gate | Owner job |
|---|---|---|---|---|
| Unit (models, money, idempotency, config) | `flutter_test` | Linux CI | G-FLUTTER-TEST | VJ-171 |
| Contract | recorded BFF fixtures + OpenAPI examples decoded by generated models; nightly read-only staging drift check | Linux CI; nightly (owner-enabled) | G-FLUTTER-CONTRACT | VJ-131, VJ-133, VJ-162 |
| State (BLoC) | `bloc_test`-style tests with fake repositories (house style) | Linux CI | G-FLUTTER-TEST | each feature job |
| Widget | `flutter_test` + `meetsGuideline` (labeled tap targets, 48 dp targets, text contrast) at text scale 1.0 and 2.0, light and dark | Linux CI | G-FLUTTER-TEST | VJ-157 |
| Golden | pinned fonts; component kit and key screens | Linux CI (one renderer) | G-FLUTTER-TEST | VJ-173 |
| Static guardrails | money arithmetic, token storage, GraphQL imports, hard-coded endpoints, licences | Linux CI | G-FLUTTER-CONTRACT | VJ-171, VJ-172 |
| Integration (in-app, fixture BFF) | `integration_test` | Android emulator; iOS simulator | G-FLUTTER-APK / G-FLUTTER-IOS | VJ-142, VJ-158 |
| Device E2E | Maestro flows (`maestro/ventari/`), reusing the fork's label-based structure | Android emulator; iOS simulator; optional device farm | G-MAESTRO | VJ-167 |
| Performance | cold start (`adb shell am start -W`, `xcrun simctl launch` timing), frame raster p90, memory, size | physical mid-tier devices, profile/release mode only | VJ-158 budgets | VJ-158 |
| Security | MASVS L1 + selected L2 checklist with evidence; static checks as tests | both platforms | VJ-166 report | VJ-166 |
| Manual accessibility | VoiceOver and TalkBack scripts per journey, recorded | physical or simulated device per platform | VJ-157 | VJ-157 |

## 3. Cross-platform commerce test matrix

Every row runs against the fixture BFF in CI and against staging before VJ-104/VJ-105 certification.

| Scenario | Expected | How |
|---|---|---|
| Price shown on PDP vs cart vs checkout | Identical to server values in every state | Contract fixtures + E2E screenshot assertions |
| Variant change | Offer refreshed; unavailable option labelled; no client price | Bloc test + E2E |
| Add-to-cart timeout then retry | One line (same Idempotency-Key) | Fault-injecting fake transport; E2E against the fixture BFF |
| Quantity increase beyond stock | Typed error, cart unchanged | VJ-135 E2E + app flow |
| Repriced line (60 s re-quote) | Notice shown verbatim; new total from server | Fixture BFF scripted repricing |
| Place order, connection drops after commit | Same order id via lookup; one payment session | VJ-136 + app fault injection |
| Double-tap place order | One order | Bloc test + E2E |
| Session expiry mid-checkout | Single refresh; if refresh fails, user returns to login with cart preserved | Fake 401 sequence |
| Guest → login | Cart merged once | VJ-057 + app E2E |
| Offline on PDP | Cached content labelled; add-to-cart disabled until online and re-fetched | Airplane-mode E2E |
| Kill switch on | Checkout disabled within one config cache period | VJ-160 + E2E |
| Customer cancel before shipment | Server preview shown; refund equals capture; replay idempotent | VJ-117 + VJ-175 E2E |
| Return request | Eligible items only; server refund preview | VJ-033 + VJ-175 |
| Order status after refund | Order, payment and return states agree with the web account page | Cross-surface parity test (web + app on the same staging order) |

## 4. Android

- **Builds:**
  - `flutter build apk --debug --flavor dev` on Linux CI for every PR.
  - `flutter build appbundle --release --flavor staging` with R8 on main.
- **Emulator smoke:** API 35 and API 36 AVDs running the Maestro suite. Also test process death (`adb shell am kill`) during cart and checkout.
- **TalkBack:** scripted traversal per journey. Focus order, labels and actions are recorded.
- **App Links:**
  - `adb shell pm verify-app-links --re-verify <pkg>`;
  - `adb shell am start -a android.intent.action.VIEW -d https://<host>/p/<slug>` for each contract path;
  - verification status recorded.
- **Push:** FCM test message to a consented device. Checks: no prompt before a meaningful action, POST_NOTIFICATIONS handling on API 33+, and a tap opens the right screen.
- **Play requirements:** current target API level, Data safety form (VJ-163), account deletion URL and in-app path, Play App Signing, internal testing track. Run the pre-launch report and review it.

## 5. iOS (requires the MACOS_XCODE resource: owner Mac or a budgeted hosted runner, OD-46)

- **Builds:**
  - `flutter build ios --simulator --debug --flavor dev` on the macOS CI job for every PR;
  - `flutter build ipa --flavor staging` with signing, only in the release workflow.
- **Simulator smoke:** current and previous iOS major version, running the Maestro suite. Also test scene restoration.
- **VoiceOver:** scripted traversal per journey. Dynamic Type is tested up to the accessibility sizes.
- **Universal links:**
  - AASA served by VJ-103;
  - `xcrun simctl openurl booted https://<host>/p/<slug>` for each contract path;
  - one real-device check, because simulators cache AASA differently.
- **APNs:** a physical device is required. Test the development and production environments separately, with no PII in payloads.
- **App Store requirements:** PrivacyInfo.xcprivacy for the app and dependencies, App Privacy labels (VJ-163), account deletion in-app, Apple Pay merchant id (OD-43), and a review demo account.
- **TestFlight readiness:** internal group first. Export compliance is answered as standard encryption only.

## 6. macOS validation path (because this environment has no Xcode)

1. **Short term (VJ-142, VJ-144):** the owner's Mac runs `flutter test`, `flutter build ios --simulator` and the Maestro iOS suite through a Remote Control session. The output is committed as evidence.
2. **Steady state (VJ-159):** a GitHub Actions `macos-latest` job runs the iOS simulator build and tests on every PR. Hosted macOS minutes need an owner budget (OD-46); the default is the owner Mac as a self-hosted runner.
3. **Signing:** signing happens only in the release workflow, with credentials in the CI secret store (APPLE_SIGNING lock). It is never in the repository or in evidence.

## 7. Release engineering (prepared, not executed)

| Step | Gate | Authorization |
|---|---|---|
| Internal builds (TestFlight internal, Play internal) | VJ-159 + VJ-104/105 evidence | Owner (OD-44 accounts) |
| Closed beta | VJ-166 no open high findings; VJ-157 pass | Owner |
| Store submission | VJ-107 checklist | Separate owner authorization |
| Staged rollout | 1% → 10% → 50% → 100%; crash-free sessions ≥ 99.8% and no P1 before each step; minimum-version and kill switch ready (VJ-160) | Owner per step |

## 8. Release metrics

- Crash-free sessions ≥ 99.8%.
- Cold start p90 ≤ 2 s.
- Checkout success rate tracked against the web.
- Duplicate orders = 0.
- Quote = charge in 100% of orders.
- Accessibility serious issues = 0.
