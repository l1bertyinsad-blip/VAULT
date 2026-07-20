# Test SAVIO on an Android phone — free

## GitHub Actions method

1. Create a GitHub repository and upload **the contents of this folder** so `settings.gradle.kts` is at the repository root.
2. Open the repository’s **Actions** tab.
3. Select **Build SAVIO Android** and click **Run workflow**. A push to `main` also starts it automatically.
4. Open the completed green run. At the bottom, download the `SAVIO-Android-Test-Package` artifact.
5. Unzip it and send `app-debug.apk` to the Android phone (Telegram Saved Messages, USB, cloud drive or browser download).
6. On the phone, open the APK. Android may ask you to allow “Install unknown apps” for the app you opened it from; allow it for that source, install SAVIO, then turn the permission back off if desired.

The debug APK is free to build and install. Google Play is not needed for this test.

## What to test first

1. Complete the three onboarding screens and check RU/EN in Profile.
2. Tap `+`, choose a photo/video, and confirm it appears in Inbox.
3. In Instagram or a browser, open **Share**, choose **SAVIO**, return to SAVIO, and confirm the link appears in Inbox.
4. Add a description and “why I saved this” text, then find a word from it using Search.
5. Move the item to a folder, favorite it, archive it and restore it.
6. Restart the app and confirm everything remains available.

## Updating a test build

Download the newer `app-debug.apk` from GitHub and install it over the old one. Because the package id stays the same, Android updates the app and preserves local SAVIO data.
