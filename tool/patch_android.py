#!/usr/bin/env python3
"""Patch the CI-generated Android project for AdMob.

The Android project is not committed (its Gradle wrapper is a binary that
can't be hand-authored), so CI regenerates it with `flutter create` on every
run. This script re-applies the two customisations google_mobile_ads needs,
idempotently:

  1. The app's launcher display name.
  2. The Play Store applicationId (com.pitchcode.skein).
  3. The AdMob application id, as <meta-data> in AndroidManifest.xml.
     Defaults to Google's official *test* app id; a release build sets the
     ADMOB_APP_ID environment variable to override it.
  4. minSdk 23 — google_mobile_ads 5.x refuses to build below it.
  5. A pinned Gradle + AGP toolchain (see below).

Run after `flutter create`, before `flutter build apk`.
"""

import glob
import os
import re
import sys

# The AdMob application id injected into the manifest. Defaults to Google's
# official **test** app id; a release build overrides it by setting the
# ADMOB_APP_ID environment variable before running this script.
TEST_ADMOB_APP_ID = "ca-app-pub-3940256099942544~3347511713"
ADMOB_APP_ID = os.environ.get("ADMOB_APP_ID", TEST_ADMOB_APP_ID)

# The app's display name under the launcher icon (short brand).
APP_LABEL = "Skein"

# The Play Store package / Android applicationId. Globally unique and permanent
# once published. The internal Dart package stays "unwind"; only the Android
# app identity is this. flutter create derives it from --org/--project-name, so
# we override it here.
APPLICATION_ID = "com.pitchcode.skein"

MANIFEST = "android/app/src/main/AndroidManifest.xml"

# `flutter create` on the floating `stable` channel now provisions Gradle 9,
# but google_mobile_ads' Android build script still uses the eager
# `configurations.all` API that Gradle 9 removed, so the build fails. Pin the
# whole Android toolchain to a known-good pair that builds the plugin cleanly.
GRADLE_VERSION = "8.14.3"
AGP_VERSION = "8.11.1"


def patch_manifest() -> None:
    with open(MANIFEST, encoding="utf-8") as f:
        xml = f.read()

    # Set the launcher display name (flutter create uses the project name).
    new_xml, n = re.subn(
        r'android:label="[^"]*"', f'android:label="{APP_LABEL}"', xml, count=1
    )
    if n:
        xml = new_xml
        print(f'Set app label -> "{APP_LABEL}".')

    if "com.google.android.gms.ads.APPLICATION_ID" not in xml:
        meta = (
            "        <meta-data\n"
            '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
            f'            android:value="{ADMOB_APP_ID}"/>\n'
        )
        if "</application>" not in xml:
            sys.exit(f"error: no </application> tag found in {MANIFEST}")
        xml = xml.replace("</application>", meta + "    </application>", 1)
        print(f"Patched {MANIFEST} with AdMob app id.")
    else:
        print("Manifest already has AdMob app id; skipping.")

    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write(xml)


def patch_min_sdk() -> None:
    # Newer Flutter uses build.gradle.kts, older uses build.gradle. Handle both,
    # and both the `flutter.minSdkVersion` reference and any literal minSdk.
    paths = glob.glob("android/app/build.gradle") + glob.glob(
        "android/app/build.gradle.kts"
    )
    if not paths:
        sys.exit("error: no android/app/build.gradle(.kts) found")

    for path in paths:
        with open(path, encoding="utf-8") as f:
            g = f.read()
        patched = g.replace("flutter.minSdkVersion", "23")
        if patched != g:
            with open(path, "w", encoding="utf-8") as f:
                f.write(patched)
            print(f"Patched minSdk -> 23 in {path}.")
        else:
            print(f"No flutter.minSdkVersion reference in {path}; left as is.")


def patch_application_id() -> None:
    # Set the Play Store applicationId without touching the namespace (which
    # matches the generated MainActivity's package). Handles Kotlin DSL
    # (`applicationId = "..."`) and Groovy (`applicationId "..."`).
    paths = glob.glob("android/app/build.gradle") + glob.glob(
        "android/app/build.gradle.kts"
    )
    if not paths:
        sys.exit("error: no android/app/build.gradle(.kts) found")

    pattern = re.compile(r'(applicationId\s*=?\s*")[^"]*(")')
    for path in paths:
        with open(path, encoding="utf-8") as f:
            s = f.read()
        patched, n = pattern.subn(rf"\g<1>{APPLICATION_ID}\g<2>", s)
        if n:
            with open(path, "w", encoding="utf-8") as f:
                f.write(patched)
            print(f"Set applicationId -> {APPLICATION_ID} in {path}.")
        else:
            print(f"No applicationId declaration in {path}; left as is.")


def patch_gradle_wrapper() -> None:
    path = "android/gradle/wrapper/gradle-wrapper.properties"
    with open(path, encoding="utf-8") as f:
        props = f.read()
    patched = re.sub(
        r"gradle-[0-9]+(?:\.[0-9]+)+-(all|bin)\.zip",
        f"gradle-{GRADLE_VERSION}-\\1.zip",
        props,
    )
    if patched != props:
        with open(path, "w", encoding="utf-8") as f:
            f.write(patched)
        print(f"Pinned Gradle -> {GRADLE_VERSION} in {path}.")
    else:
        print(f"No distributionUrl match in {path}; left as is.")


def patch_agp_version() -> None:
    # Recent Flutter declares the Android Gradle Plugin version in
    # settings.gradle(.kts) via a plugins {} block.
    paths = glob.glob("android/settings.gradle") + glob.glob(
        "android/settings.gradle.kts"
    )
    if not paths:
        sys.exit("error: no android/settings.gradle(.kts) found")

    pattern = re.compile(
        r'(id\s*\(?\s*["\']com\.android\.application["\']\s*\)?\s+version\s+["\'])'
        r'[^"\']+'
        r'(["\'])'
    )
    for path in paths:
        with open(path, encoding="utf-8") as f:
            s = f.read()
        patched, n = pattern.subn(rf"\g<1>{AGP_VERSION}\g<2>", s)
        if n:
            with open(path, "w", encoding="utf-8") as f:
                f.write(patched)
            print(f"Pinned AGP -> {AGP_VERSION} in {path}.")
        else:
            print(f"No AGP version declaration in {path}; left as is.")


if __name__ == "__main__":
    patch_manifest()
    patch_application_id()
    patch_min_sdk()
    patch_gradle_wrapper()
    patch_agp_version()
