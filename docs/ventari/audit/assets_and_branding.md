# Assets and branding inventory

Repo `/home/claude/ventari-mobile` @ `18a2c27`. Sizes are bytes on disk.

## 1. assets/ (declared in pubspec.yaml as `assets/images/` and `assets/ml/`)

| Path | Size | Type | Used by | Branding assessment |
|---|---|---|---|---|
| `assets/images/bagisto_logo.svg` | 786 | SVG 36x36, blue (#2563EB) bag glyph | `home_page.dart:415`, `login_page.dart:375`, `sign_up_page.dart:419`, `forgot_password_page.dart:270`, `account_page.dart:210`; fallback in `core/widgets/channel_logo.dart` | **Bagisto branding** (file name and logo shape). Replaced at runtime only if the channel has a logo URL |
| `assets/images/splash.png` | 26,560 | PNG 720x1460 RGBA | `lib/features/splash/presentation/splash_screen.dart:44`; duplicated for iOS at `ios/Runner/Assets.xcassets/splash.imageset/assets_images_splash.png` (identical size) | **Webkul/Mobikul branding**: text "mobikul For Bagisto", "An award winning product from Webkul Software", and "This is demo store any requests made through this app will not be fulfilled." (viewed) |
| `assets/images/google_icon.svg` | 12,570 | SVG | `social_login_icons.dart:20` | Third-party (Google) brand glyph; icon is display only (no Google sign-in SDK) |
| `assets/images/facebook_icon.svg` | 1,414 | SVG | `social_login_icons.dart:29` | Third-party (Facebook) brand glyph |
| `assets/images/apple_icon.svg` | 887 | SVG | `social_login_icons.dart:38` | Third-party (Apple) brand glyph |
| `assets/ml/` (declared) | n/a | **directory missing in repo** | `mlkit_vision_service.dart:28` expects `assets/ml/mobilenet_v2.tflite` | Excluded by `.gitignore:58-59` ("ML models - large files not needed in git"). No file, size, origin or license can be determined from the repo. Because pubspec declares a non-existent asset directory, `flutter build` emits an asset-directory-not-found error/warning until the folder exists. Model name suggests Google MobileNet V2 (Apache-2.0 for the reference model) but this is unverified |

No other raster/demo/stock imagery is bundled under `assets/`. No custom fonts are bundled (`pubspec.yaml` has the `fonts:` block commented out; `find` finds no .ttf/.otf/.woff). Some widgets request `fontFamily: 'Roboto'` (e.g. `category_page.dart:268`); Roboto is the Android system font and Flutter's Material default on Android (Apache-2.0 license), not bundled here. `uses-material-design: true` includes MaterialIcons (Apache-2.0) and `cupertino_icons` is declared (MIT).

`Docs/features_images/` (3.5 MB, 7 files, not packaged into the app): `All Type Product Supported.png`, `Dark Mode and Push Notification.png`, `Discount Coupons and Guest Checkout.png`, `Interactive Home Page and Search.png`, `Order Details and Product Reviews.png`, `Wishlist and Product Category.png`, `installation_configuration_video_thumbnail.jpg` (README marketing screenshots of the Mobikul/Bagisto app; README also hot-links `https://bagisto.com/wp-content/themes/bagisto/images/logo.png`).

## 2. Native launcher/app icons and launch images

Visual check: `android/app/src/main/res/ic_launcher-playstore.png` (512x512) and `ios/.../AppIcon.appiconset/iTunesArtwork-1024.png` (1024x1024) are the same artwork: a white stylised "m" on a blue (#0033FF-ish) rounded square = **Mobikul / Webkul app icon** (viewed). Android adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`, `ic_launcher_round.xml`) = `@drawable/ic_launcher_background` (vector; solid #3DDC84 Android-green base plus grid lines, i.e. the stock Flutter template background) + `@mipmap/ic_launcher_foreground`. The foreground PNGs are the same "m" mark.

| File | Bytes | Pixels |
|---|---|---|
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | 544 | 72x72 |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png` | 1980 | 162x162 |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png` | 3381 | 72x72 |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | 442 | 48x48 |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png` | 1221 | 108x108 |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png` | 2122 | 48x48 |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | 721 | 96x96 |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png` | 2862 | 216x216 |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png` | 4826 | 96x96 |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | 1031 | 144x144 |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png` | 4983 | 324x324 |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png` | 7586 | 144x144 |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | 1443 | 192x192 |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png` | 7552 | 432x432 |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png` | 10969 | 192x192 |
| `android/app/src/main/res/ic_launcher-playstore.png` | 12993 | 512x512 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-20.png` | 391 | 20x20 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-20@2x-1.png` | 762 | 40x40 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-20@2x.png` | 762 | 40x40 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-20@3x.png` | 1336 | 60x60 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-29.png` | 517 | 29x29 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-29@2x-1.png` | 1270 | 58x58 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-29@2x.png` | 1270 | 58x58 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-29@3x.png` | 1981 | 87x87 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-30.png` | 517 | 29x29 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-40.png` | 647 | 40x40 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-40@2x-1.png` | 1757 | 80x80 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-40@2x.png` | 1757 | 80x80 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-40@3x.png` | 3277 | 120x120 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-50.png` | 924 | 50x50 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-50@2x.png` | 2425 | 100x100 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-57.png` | 1132 | 57x57 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-57@2x.png` | 2954 | 114x114 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-60@2x.png` | 3277 | 120x120 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-60@3x.png` | 5102 | 180x180 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-72.png` | 1288 | 72x72 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-72@2x.png` | 3731 | 144x144 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-76.png` | 1399 | 76x76 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-76@2x.png` | 3951 | 152x152 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-83.5@2x.png` | 4554 | 167x167 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/iTunesArtwork-1024.png` | 71820 | 1024x1024 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` | 68 | 1x1 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` | 68 | 1x1 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` | 68 | 1x1 |
| `ios/Runner/Assets.xcassets/splash.imageset/assets_images_splash 1.png` | 26560 | 720x1460 |
| `ios/Runner/Assets.xcassets/splash.imageset/assets_images_splash 2.png` | 26560 | 720x1460 |
| `ios/Runner/Assets.xcassets/splash.imageset/assets_images_splash.png` | 26560 | 720x1460 |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png` | 102994 | 1024x1024 |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png` | 5680 | 128x128 |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png` | 520 | 16x16 |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png` | 14142 | 256x256 |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png` | 1066 | 32x32 |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png` | 36406 | 512x512 |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png` | 2218 | 64x64 |
| `web/icons/Icon-192.png` | 5292 | 192x192 |
| `web/icons/Icon-512.png` | 8252 | 512x512 |
| `web/icons/Icon-maskable-192.png` | 5594 | 192x192 |
| `web/icons/Icon-maskable-512.png` | 20998 | 512x512 |
| `web/favicon.png` | 917 | 16x16 |
| `windows/runner/resources/app_icon.ico` | 33772 |  |

Other Android drawable/res items: `drawable-*/cart|person|reorder|search.(png|xml)` (tab icons, unreferenced by Dart; carry the Webkul XML header), `drawable/ic_flash_on|off.xml`, `ic_switch_camera.xml`, `ic_close.png`, `flash_toggle_bg.xml`, `toggle_style.xml`, `opening_screen.xml`, layouts `layout/activity_ar.xml`, `activity_camera_search.xml`, `camera_simple_spinner_item.xml` and strings for an "AR View"/"3D Model" feature (`values/strings.xml`). There is no Kotlin/Java source in `android/app/src/main` other than `MainActivity.kt` (5 lines) and the generated plugin registrant, so these layouts/strings are leftover native resources from the upstream Mobikul app (not wired to code in this repo). `drawable/launch_background.xml` and `drawable-v21/launch_background.xml` reference `@mipmap/launch_image`, which does not exist in any mipmap folder (dangling reference).

iOS: `LaunchImage.imageset` = three 68-byte 1x1 placeholder PNGs (default Flutter template); `splash.imageset/assets_images_splash.png` = the Mobikul splash (26,560 bytes). `Base.lproj/LaunchScreen.storyboard` present (3 image references).

macOS/Windows/Web/Linux icons are Flutter-template defaults, not verified visually: `macos/.../app_icon_*.png`, `web/icons/Icon-*.png`, `web/favicon.png`, `windows/runner/resources/app_icon.ico`.

## 3. Brand-term grep (whole repo excluding `.git`, `build`, `.dart_tool`)

Counts are matching lines (`grep -c`, summed per top-level dir), alternation (`Bagisto|bagisto`, `Webkul|webkul`, `Mobikul|mobikul`).

| Term | Total matches | Files | Distribution (matches / files) |
|---|---|---|---|
| Bagisto/bagisto | 727 matching lines | 201 files | test 320/82, lib 188/61, Docs 99/20, root files 45/6, maestro 21/13, macos 16/3, ios 12/3, android 9/6, windows 9/3, linux 4/2, web 4/2 |
| Webkul/webkul | 136 matching lines | 44 files | android 110/23 (license header comments in res XML + google-services), maestro 15/13, root 3/3 (README, LICENSE, Configuration_guide), ios 4/2, lib 1/1, test 2/1, Docs 1/1 |
| Mobikul/mobikul | 79 matching lines | 44 files | android 46/24, maestro 17/13, ios 4/2, lib 4/2, root 6/2, Docs 2/1 |

Note: most `bagisto` hits in lib/ and test/ are the Dart package name (`package:bagisto_flutter/...` imports), not display strings. Display-relevant ones in lib/ are: class names `BagistoApp`, `BagistoCountry`, `BagistoCountryState`; constant `bagistoEndpoint`; asset `bagisto_logo.svg` (5 references); prefs key `bagisto_guest_cart_token`/`bagisto_guest_cart_id`; FCM topic `bagisto_mobikul` (`fcm_service.dart:83,93,275`, `main.dart:431`); `firebase_options.dart:17` iosBundleId `com.webkul.bagistoApp.iOS`; l10n `appTitle` = "Bagisto Store" (`lib/l10n/app_en.arb:3`; 9 of 10 arb files contain "Bagisto", `app_ar.arb` has 0 hits).

### Important locations: app name strings, bundle ids, endpoints
| What | Value | Location |
|---|---|---|
| Android label | `Mobikul Bagisto Laravel App` | `android/app/src/main/AndroidManifest.xml` (`android:label`) |
| iOS display name | `Mobikul Bagisto Laravel App`; `CFBundleName` `bagisto_flutter` | `ios/Runner/Info.plist`; `Runner.xcodeproj/project.pbxproj:518,708,738` |
| In-app title | "Bagisto Store" | `lib/l10n/app_en.arb:3` (`appTitle`, used `main.dart:644`) |
| Android applicationId | `com.webkul.bagisto.mobikul` | `android/app/build.gradle.kts:25` (namespace is `com.bagisto.bagisto_flutter`, :7) |
| iOS bundle id | `com.webkul.bagistoApp.iOS` (RunnerTests `com.bagisto.bagistoFlutter.RunnerTests`) | `project.pbxproj:524,714,744` |
| macOS/Windows/Linux/Web names | `bagisto_flutter` | `web/manifest.json`, `web/index.html:26,32`, `windows/runner/Runner.rc:97`, `linux/CMakeLists.txt` |
| Store listing links | Play `com.webkul.bagisto.mobikul`; App Store `mobikul-bagisto-laravel-app/id6447519140` | `README.md:20,22` |
| License | MIT, `Copyright (c) 2026 Webkul Software Private Limited` | `LICENSE:3` |
| Webkul license headers | `@license https://store.webkul.com/license.html` in 21 Android res files (colors, strings, drawables, layouts, xml configs) | `android/app/src/main/res/**` (note: Android res files cite a Webkul store license, while the repo LICENSE is MIT) |
| Backend endpoint (placeholder) | `https://your-bagisto-domain.com/graphql`; storefront key `your_storefront_key_here` | `lib/core/constants/api_constants.dart:1-7` |
| Demo hostnames in repo | `api-demo.bagisto.com` (comment `lib/core/graphql/account_queries.dart:190`, `Docs/ai-memory/2026-09-30-qa-issue-fixes.md`), `test-delivery.bagisto.com` (Docs/backend-issues, Docs/superpowers/plans), `192.168.15.239` (LAN IP in `test/home_theme_fixes_test.dart` x3, Docs), `bagisto.yourdomain.com`/`your-bagisto-server.com`/`your-bagisto-domain.com` (README, Docs/ServerConfig.md, Configuration_guide.md), `api-docs.bagisto.com` (10 doc-link comments in lib/ and Docs) |
| Firebase | placeholder project `placeholder-firebase-project`; android package in google-services.json `com.webkul.bagisto.mobikul`; iOS `com.webkul.bagistoApp.iOS` | `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `lib/core/notifications/firebase_options.dart` |
| Maestro app ids | `com.webkul.bagisto.mobikul`, `com.webkul.bagistoApp.iOS` | `maestro/config.yaml:6-7` |
| iOS signing team | `DEVELOPMENT_TEAM = MPFH69ZV5Q` | `project.pbxproj:704,734` (upstream/Webkul's team id, left in project) |
| Other external hostnames | `store.webkul.com` (42 refs, Android res headers), `webkul.com` (21), `mobikul.com` (README Firebase guides), `ethereal.email` (.agents skill) | |
| Agent/tooling dirs | `.agents/skills`, `.claude/skills`, `.kilocode/skills` (flutter-expert, maestro-mobile-testing; `.kilocode/package-lock.json` has 29 registry.npmjs.org refs), `skills-lock.json`, `maestroContext/instruction.md` | repo root |

Version strings across the repo are inconsistent: pubspec `2.4.7+247`, Android `versionName 2.4.6`/`versionCode 246` (hardcoded, overriding Flutter build-name/number), iOS `MARKETING_VERSION 2.56.0` (but `Info.plist` uses `$(FLUTTER_BUILD_NAME)`), CHANGELOG v2.5.2.
