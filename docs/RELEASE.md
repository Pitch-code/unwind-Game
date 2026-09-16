# Releasing Skein to Google Play

_Store brand **Skein** (title "Skein: Untangle & Grow"), package
`com.pitchcode.skein`. The internal Flutter/Dart project stays named `unwind`;
`tool/patch_android.py` sets the Android applicationId + launcher label._

A practical runbook. Nothing here is required to *develop* — debug builds run
with Google's test ad units and no signing. This is only for shipping.

## How the Android project is built

We do **not** commit the `android/` folder: `flutter create` regenerates it in
CI, and `tool/patch_android.py` re-applies our customisations (app name, AdMob
app id, minSdk 23, a pinned Gradle 8.14.3 + AGP 8.11.1 toolchain). CI builds a
debug APK and a debug-signed release `.aab` on every push, so the release path
stays verified.

For a real release you build locally. Two supported ways:

- **Quick:** generate the project the same way CI does, then build:
  ```sh
  flutter create --platforms=android --org com.pitchcode --project-name unwind .
  ADMOB_APP_ID=ca-app-pub-XXXXX~YYYYY python3 tool/patch_android.py
  # add your signing config (below), then build.
  ```
- **Durable (recommended once you ship):** generate `android/` once, commit it
  (including `gradle/wrapper/gradle-wrapper.jar`), add the signing config and
  the AdMob app id directly, and keep it under version control. From then on
  the patch script is optional.

## Versioning

`pubspec.yaml` holds `version: <name>+<code>` (currently `0.2.0+2`). Bump the
**build code** (the number after `+`) on every upload to Play — Play rejects a
reused code. Bump the name when it's a user-visible release.

## Real AdMob ids

Test ids are the defaults so we never risk a policy strike in development.
For release, create an AdMob account → app → interstitial unit, then supply:

- **App id** → the `ADMOB_APP_ID` env var when running `tool/patch_android.py`
  (or hard-code it in a committed manifest).
- **Interstitial unit id** → a dart-define at build time:
  ```sh
  flutter build appbundle --release \
    --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXXXX/ZZZZZ
  ```

## Signing

Prefer **Play App Signing**: you keep an *upload* key, Google holds the app
signing key.

1. Create an upload keystore (once, keep it safe and backed up):
   ```sh
   keytool -genkey -v -keystore ~/unwind-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Add `android/key.properties` (git-ignored — see `.gitignore`):
   ```properties
   storeFile=/absolute/path/to/unwind-upload.jks
   storePassword=…
   keyAlias=upload
   keyPassword=…
   ```
3. In `android/app/build.gradle.kts`, load it and wire the release
   `signingConfig` (replace the template's `signingConfigs.getByName("debug")`):
   ```kotlin
   import java.util.Properties
   import java.io.FileInputStream

   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String?
               keyPassword = keystoreProperties["keyPassword"] as String?
               storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
               storePassword = keystoreProperties["storePassword"] as String?
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

## Play Console

1. **Create the app** — name **Skein: Untangle & Grow**, package
   `com.pitchcode.skein` (set for you by `tool/patch_android.py`; if you commit
   `android/` durably, put `applicationId = "com.pitchcode.skein"` there).
2. **Create the in-app product** — Monetize → Products → In-app products:
   - Product id: **`unwind_premium`** (must match the code exactly).
   - Type: one-time (managed) product. Price ~$3–5. **Activate** it.
   - The purchase button in-app does nothing useful until this exists and the
     build is on a test track.
3. **Internal testing** — upload the signed `.aab`, add tester emails
   (e.g. `labellens.dev@gmail.com`). Testers install via the opt-in link.
4. **Store listing / policy** — complete the listing (see
   `docs/store-listing.md`), content rating, and **Data safety**: declare that
   the app uses ads (Advertising ID) and processes purchases.
5. **AdMob** — link the Play app to AdMob; serve real ads only after the
   listing is live on a track.

## Sanity checklist before uploading

- [ ] Build code bumped in `pubspec.yaml`.
- [ ] Built with real `ADMOB_APP_ID` + `--dart-define=ADMOB_INTERSTITIAL_ID`.
- [ ] Release signed with the upload key (not the debug key).
- [ ] `unwind_premium` product created and active in Play Console.
- [ ] Tested a real purchase + "Remove ads" + "Restore" on a test track.
