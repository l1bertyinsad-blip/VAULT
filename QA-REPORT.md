# SAVIO Android v1.0.0 — QA report

Date: 2026-07-20

## Result

GitHub Actions run [29754863663](https://github.com/l1bertyinsad-blip/VAULT/actions/runs/29754863663) completed successfully on Ubuntu with JDK 17, Android SDK 36 and Gradle 9.3.1.

- Kotlin/Compose compilation: passed.
- Debug unit-test task: passed.
- Android Lint (`lintDebug`): passed.
- Installable debug APK (`assembleDebug`): passed.
- Minified release Android App Bundle (`bundleRelease`): passed.
- Artifact upload: passed.
- Local XML parse: 12/12 resource and manifest files passed.
- Manifest requests no internet, broad photo-library or external-storage permission.

## Artifacts

- `SAVIO-Android-v1.0.0-debug.apk`
  - Size: 11,774,121 bytes
  - SHA-256: `2ae2582041f96ce98bd727bfec0db37b517e38afbc61302c68f5da915c14382d`
  - Purpose: direct installation and testing on Android.
- `SAVIO-Android-v1.0.0-unsigned.aab`
  - Size: 3,568,195 bytes
  - SHA-256: `b0bd0858a7b90411dec6214605af5c949320c32e178a870dc580c5a43e3ffb1f`
  - Purpose: release-build validation; sign with the owner's upload key before Google Play submission.

The hashes calculated after downloading the GitHub artifact match the hashes produced on the build runner.

## Remaining device QA

Automated build QA cannot replace a real-phone pass. Before a public release, test Sharesheet imports from Instagram/browser/gallery, large videos, file opening, process restart, Android backup behavior, dark theme, RU/EN, and multiple screen sizes on physical Android devices.

The Node.js 20 deprecation annotation belongs to third-party GitHub Actions and did not affect the successful build. GitHub forced those actions to its Node.js 24 runtime.
