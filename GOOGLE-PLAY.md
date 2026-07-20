# Google Play release path

The free APK test path and Google Play publication are different:

- **APK from GitHub Actions:** free and installable directly on your own Android phones.
- **Google Play:** requires a Google Play Console developer account, identity verification, store listing, privacy/data-safety forms, testing requirements for eligible new personal accounts, and a signed `.aab`.

This project is already configured for Android API 36 so it is ready for the Android 16 target requirement scheduled for new apps and updates from 31 August 2026.

Before production publication:

1. Confirm the final product name and package id. A Play package id cannot be reused after another app claims it.
2. Create and securely store an upload keystore. Never commit the keystore or its passwords.
3. Add release signing through local `keystore.properties` or encrypted GitHub secrets.
4. Generate a signed release bundle: `gradle :app:bundleRelease`.
5. Complete App content, Data safety, privacy policy URL, content rating, target audience and ads declaration.
6. Upload Russian and English store copy, icon, feature graphic, phone screenshots and the signed AAB.
7. Use internal testing first; then complete any closed-testing requirement shown by Play Console before production access.

Draft copy and forms are in `play/`.
