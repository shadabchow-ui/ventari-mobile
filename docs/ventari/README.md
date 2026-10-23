# Ventari on the Bagisto Flutter fork — proposal index

**Status: PROPOSAL, not accepted.** Branch `proposal/ventari-flutter-adaptation-20261023`, based on `main` at
`18a2c27c6d25a2e98a1bc84b69328e72d6a5bded`. Nothing here changes how the existing Bagisto app behaves: the new code
under `lib/ventari/` is not wired into any screen yet.

| Document | Purpose |
|---|---|
| [VENTARI_BAGISTO_SOURCE_AUDIT.md](VENTARI_BAGISTO_SOURCE_AUDIT.md) | Licence, assets, dependencies, security, commerce-truth findings; KEEP/ADAPT/REPLACE/REMOVE per module |
| [VENTARI_FLUTTER_MOBILE_ARCHITECTURE_V2.md](VENTARI_FLUTTER_MOBILE_ARCHITECTURE_V2.md) | One Flutter codebase on Ventari contracts; session, payments, links, risks |
| [VENTARI_BAGISTO_TO_VENTARI_API_MAPPING.md](VENTARI_BAGISTO_TO_VENTARI_API_MAPPING.md) + [.csv](VENTARI_BAGISTO_TO_VENTARI_API_MAPPING.csv) | All 105 Bagisto GraphQL operations mapped to Ventari endpoints |
| [VENTARI_IOS_ANDROID_TEST_AND_RELEASE_PLAN.md](VENTARI_IOS_ANDROID_TEST_AND_RELEASE_PLAN.md) | Test layers, commerce matrix, Android/iOS checks, macOS path, release gates |
| [audit/](audit/) | Mechanical inventory with file:line citations |

The job pack (prompts, manifests, registry rows for VJ-102…VJ-175) lives with the registry in
`shadabchow-ui/ventari-shopware`, branch `proposal/opus-job-refinements-bagisto-mobile-20261023`,
`docs/proposals/opus-2026-10-23/VENTARI_MOBILE_JOB_PACK_AND_M16_V2/`.

## Code on this branch

- `lib/ventari/` — Ventari data-layer seed: config, Money (integer cents), catalog BFF v2 client and models,
  idempotency keys, session-store interface.
- `test/ventari/` + `test/fixtures/ventari/` — 48 tests: contract decoding, fail-closed behaviour, retry rules,
  and static guardrails (no money arithmetic, no token in SharedPreferences, no GraphQL, no hard-coded endpoints).

Run: `flutter test test/ventari` and `flutter analyze lib/ventari test/ventari`.
