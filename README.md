# SAVIO for Android

Native Android version of SAVIO: a private, local-first place for ideas, recipes, reels, photos, videos, links, files and notes.

## What already works

- Android Sharesheet target: share a link, image, video or file into SAVIO.
- System Photo Picker: import selected photos/videos without requesting access to the entire gallery.
- File picker, link saving and quick notes from the central `+` button.
- Inbox and custom folders, favorites, archive and local full-text search.
- Editable title, description and “why I saved this” thought for every item.
- A finite seven-card “Useful scrolling” feed — no infinite feed.
- Russian-first interface with instant RU/EN switching.
- Light, dark and system themes.
- On-device JSON metadata and private copied files; no account, advertising SDK or analytics tracker.
- Android-adapted SAVIO icon, system splash and in-app logo animation.

## Technology

- Kotlin with Jetpack Compose and Material 3.
- `minSdk 26`, `compileSdk 37`, `targetSdk 36`.
- AGP 9.1.1, Gradle 9.3.1, JDK 17.
- Package: `com.nevsk1y.savio`; debug package: `com.nevsk1y.savio.debug`.

## Build

Open this folder in Android Studio and run the `app` configuration. No API keys are required.

For a free cloud build, upload the folder contents to a GitHub repository. The included workflow produces:

- `app-debug.apk` — install directly on an Android phone.
- `app-release.aab` — release bundle template for Google Play (must be signed for publication).

See [TEST-ON-PHONE.md](TEST-ON-PHONE.md) and [GOOGLE-PLAY.md](GOOGLE-PLAY.md).
