# Platform configuration

Repo `/home/claude/ventari-mobile` @ `18a2c27`. Flutter SDK present at `/opt/flutter` is **3.47.7** (stable); Android values marked "Flutter default" were read from `/opt/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`.

Platform folders present: `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` (all six exist and appear to be Flutter-template scaffolding). Several dependencies are mobile-only (ML Kit, camera, speech_to_text, in_app_update, firebase native pods), so desktop/web targets are not realistic builds. `lib/driver_main.dart` (7 lines) is a flutter_driver entry.

## Android (`android/`)

| Item | Value | Source |
|---|---|---|
| applicationId | `com.webkul.bagisto.mobikul` (TODO comment from template still present) | `android/app/build.gradle.kts:25` |
| namespace | `com.bagisto.bagisto_flutter` (differs from applicationId; `MainActivity.kt` is in this package) | `build.gradle.kts:7` |
| versionCode / versionName | `246` / `2.4.6` hardcoded (pubspec says 2.4.7+247) | `build.gradle.kts:31-32` |
| compileSdk | `flutter.compileSdkVersion` = 36 (Flutter 3.47.7 default) | `build.gradle.kts:8` |
| minSdk | `flutter.minSdkVersion` = 24 (Flutter default) | `build.gradle.kts:28` |
| targetSdk | `flutter.targetSdkVersion` = 36 (Flutter default) | `build.gradle.kts:29` |
| NDK | `28.2.13676358` | `build.gradle.kts:9` |
| Android Gradle Plugin | 8.9.2 | `android/settings.gradle.kts:22` |
| Kotlin plugin | 2.2.20 | `settings.gradle.kts:23` |
| Gradle wrapper | 8.14 (`gradle-8.14-all.zip`) | `android/gradle/wrapper/gradle-wrapper.properties` |
| Java/Kotlin target | 17 (core library desugaring enabled, `desugar_jdk_libs:2.1.4`) | `build.gradle.kts:12-19, 55` |
| Gradle props | `-Xmx8G`, `android.useAndroidX=true`, `android.builtInKotlin=false`, `android.newDsl=false` (Flutter migrator flags) | `android/gradle.properties` |
| Extra deps | `androidx.constraintlayout:2.1.4`, `com.google.android.material:1.12.0`; excludes `com.google.firebase:firebase-iid` globally | `build.gradle.kts:50-58` |
| Source code | only `MainActivity.kt` (5 lines, `FlutterActivity`) plus generated `GeneratedPluginRegistrant.java` | `android/app/src/main` |

### Permissions
Declared in `android/app/src/main/AndroidManifest.xml`: `INTERNET`, `CAMERA`, `RECORD_AUDIO`; `uses-feature android.hardware.camera required=false`. `android/app/src/debug/AndroidManifest.xml` adds `INTERNET` (Flutter tooling). Plugin manifests (from `~/.pub-cache`, not a built merge) add: firebase_messaging `INTERNET, WAKE_LOCK, ACCESS_NETWORK_STATE, POST_NOTIFICATIONS, BIND_JOB_SERVICE` + `FlutterFirebaseMessagingService`; flutter_local_notifications `VIBRATE, POST_NOTIFICATIONS`; open_filex `READ_EXTERNAL_STORAGE, READ_MEDIA_IMAGES, READ_MEDIA_VIDEO, READ_MEDIA_AUDIO`; camera `CAMERA, RECORD_AUDIO`; share_plus `SharePlusPendingIntent` receiver. Not verified: a real merged manifest (requires an Android build).
Application label: `Mobikul Bagisto Laravel App` (hardcoded in manifest). Activity `.MainActivity` exported, `launchMode=singleTop`, theme `LaunchTheme`.

### Intent filters / deep links
Only the standard `MAIN`/`LAUNCHER` filter. **No VIEW/BROWSABLE intent filters, no App Links, no custom scheme.** A `<queries>` block for `PROCESS_TEXT` is present. Notification taps are routed in Dart (`fcm_service.dart`, `main.dart`), not by manifest filters.
`android/app/src/main/res/xml/network_security_config.xml` exists (cleartext allowed for placeholder domain `api.example.com(to be adjusted)`) but the manifest has no `android:networkSecurityConfig` attribute, so it is not applied. `res/xml/provider_paths.xml` (external-path) exists, but the manifest declares no `<provider>`/FileProvider (open_filex ships its own).

### Firebase
`android/app/google-services.json` is **committed** (tracked in git; `.gitignore:69-72` lines that would ignore it are commented out). Content is placeholder: project_id `placeholder-firebase-project`, project_number `0000…` (12 digits), package `com.webkul.bagisto.mobikul`, api_key `A123…` (39 chars, sequential-digit dummy). The Gradle `com.google.gms.google-services` plugin is **not applied** (no reference in `settings.gradle.kts`/`build.gradle.kts`/`app/build.gradle.kts`), so the JSON is not processed by the build; Firebase is initialised from Dart `lib/core/notifications/firebase_options.dart` (placeholder values).

### Signing
- Release build type signs with the **debug key**: `signingConfig = signingConfigs.getByName("debug")` with the template TODO (`build.gradle.kts:36-38`). No `signingConfigs {}` block, no `key.properties`, no `storeFile`/`storePassword`/`keyAlias` anywhere.
- `.gitignore:54-56` ignores `*.jks`, `*.keystore`, `jks_details/`. `git ls-files` shows no keystore/jks/key.properties tracked. `android/local.properties` exists in the working tree (contains `flutter.sdk=<local path>`) but is not tracked.

### ProGuard / R8
`release` lists `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")` but sets neither `isMinifyEnabled` nor `isShrinkResources`, so code shrinking/obfuscation is off by default. `android/app/proguard-rules.pro` has one rule: `-dontwarn com.google.firebase.iid.FirebaseInstanceId`. Dart code obfuscation flags are not configured in the repo.

## iOS (`ios/`)

| Item | Value | Source |
|---|---|---|
| Bundle identifier | `com.webkul.bagistoApp.iOS` (Runner, 3 build configs); RunnerTests `com.bagisto.bagistoFlutter.RunnerTests` | `Runner.xcodeproj/project.pbxproj:524,714,744,560,576` |
| Display name | `Mobikul Bagisto Laravel App` (`CFBundleDisplayName`); `CFBundleName` = `bagisto_flutter` | `Info.plist` |
| Version | `CFBundleShortVersionString=$(FLUTTER_BUILD_NAME)`, `CFBundleVersion=$(FLUTTER_BUILD_NUMBER)`; `MARKETING_VERSION = 2.56.0` in Release/Profile (pbxproj:713,743), `CURRENT_PROJECT_VERSION=$(FLUTTER_BUILD_NUMBER)` | |
| Deployment target | Project: `IPHONEOS_DEPLOYMENT_TARGET = 13.0` (pbxproj:495,632,683). `Podfile` line 2: `platform :ios, '15.5'`. `Podfile` post_install forces every pod target to `IPHONEOS_DEPLOYMENT_TARGET = 13.0` (conflicts with the 15.5 platform line; ML Kit pods in Podfile.lock: MLKitCommon 14.0.0, MLKitImageLabeling 8.0.0) | |
| Pods (from Podfile.lock) | FirebaseCore/Installations/Messaging 11.15.0, ML Kit (image labeling, object detection), permission_handler with `PERMISSION_CAMERA/PHOTOS/MICROPHONE/SPEECH_RECOGNIZER=1` macros set in Podfile post_install | `ios/Podfile`, `ios/Podfile.lock` |
| Signing | `CODE_SIGN_STYLE = Automatic`, `CODE_SIGN_IDENTITY = "Apple Development"`, `DEVELOPMENT_TEAM = MPFH69ZV5Q` (a team id committed; not a secret but not this fork's team), `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements`, empty provisioning specifier; Swift 5.0 | `project.pbxproj:700-748` |
| Entitlements | `aps-environment = development` (push, dev environment only); `com.apple.developer.associated-domains` = **empty array** | `ios/Runner/Runner.entitlements` |
| URL schemes | **None** (`CFBundleURLTypes` absent in `Info.plist`). `GoogleService-Info.plist` carries a `REVERSED_CLIENT_ID` (placeholder) but it is not registered as a URL scheme | `Info.plist` |
| Background modes | `UIBackgroundModes` not present (no `remote-notification`) | `Info.plist` |
| Orientations | Portrait, upside down, landscape left/right | `Info.plist` |
| Scenes | UIScene manifest, `SceneDelegate.swift`, `AppDelegate` implements `FlutterImplicitEngineDelegate`; skips native push registration when `GoogleService-Info.plist` `PROJECT_ID == "placeholder-firebase-project"` (`AppDelegate.swift:62-72`) | |
| GoogleService-Info.plist | **Present and tracked** (`ios/Runner/GoogleService-Info.plist`), placeholder: PROJECT_ID `plac…` (28 chars), API_KEY `A123…` (39), GCM_SENDER_ID `0000…` (12), BUNDLE_ID `com.webkul.bagistoApp.iOS`, GOOGLE_APP_ID `1:00…` (43) | |

### Info.plist permission usage strings
- `NSCameraUsageDescription`: "This app needs camera access to capture photos for image-based product search."
- `NSMicrophoneUsageDescription`: "This app needs microphone access for voice search functionality."
- `NSPhotoLibraryUsageDescription`: "This app needs access to your photo library to select images for product search."
- `NSPhotoLibraryAddOnlyUsageDescription`: "This app needs permission to save photos from your camera."
- `NSSpeechRecognitionUsageDescription`: "This app uses speech recognition for voice search."
No Face ID, location, contacts, tracking (ATT) or notification-specific strings. These strings mention only image search and voice search; review attachment/file picking uses the same photo library permission.

## Other platforms
- Web: `web/manifest.json` and `web/index.html` still say `bagisto_flutter` / "A new Flutter project." with Flutter-default colors (#0175C2).
- macOS: bundle id `com.bagisto.bagistoFlutter` (`macos/Runner/Configs/AppInfo.xcconfig:11`), `platform :osx, '10.15'`.
- Linux: `APPLICATION_ID "com.bagisto.bagisto_flutter"` (`linux/CMakeLists.txt:10`). Windows: `bagisto_flutter.exe` (`windows/runner/Runner.rc:97`).
