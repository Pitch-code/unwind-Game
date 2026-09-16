#!/usr/bin/env python3
"""Patch the CI-generated Android project for AdMob.

The Android project is not committed (its Gradle wrapper is a binary that
can't be hand-authored), so CI regenerates it with `flutter create` on every
run. This script re-applies the two customisations google_mobile_ads needs,
idempotently:

  1. The AdMob application id, as <meta-data> in AndroidManifest.xml.
     During development this is Google's official *test* app id.
  2. minSdk 23 — google_mobile_ads 5.x refuses to build below it.

Run after `flutter create`, before `flutter build apk`.
"""

import glob
import re
import sys

# Google's official Android **test** AdMob application id.
ADMOB_APP_ID = "ca-app-pub-3940256099942544~3347511713"

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

    if "com.google.android.gms.ads.APPLICATION_ID" in xml:
        print("Manifest already has AdMob app id; skipping.")
        return

    meta = (
        "        <meta-data\n"
        '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
        f'            android:value="{ADMOB_APP_ID}"/>\n'
    )
    if "</application>" not in xml:
        sys.exit(f"error: no </application> tag found in {MANIFEST}")

    xml = xml.replace("</application>", meta + "    </application>", 1)
    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write(xml)
    print(f"Patched {MANIFEST} with AdMob app id.")


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
    patch_min_sdk()
    patch_gradle_wrapper()
    patch_agp_version()
