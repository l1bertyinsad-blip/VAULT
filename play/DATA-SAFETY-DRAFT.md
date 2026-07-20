# Google Play Data safety draft

Verify this against the exact release build before submitting.

- Data collected by the developer: **No**, for the current local-only build.
- Data shared with third parties: **No**.
- Required account: **No**.
- Ads: **No**.
- Analytics SDK: **No**.
- User content: stored inside the app's private local storage; may be included in Android cloud backup/device transfer if the user enables that OS feature.
- Deletion: Profile → Delete all data; uninstalling the app also removes its private local storage, subject to the user's Android backup settings.
- Network permission: not requested by the current manifest.

If analytics, crash reporting, cloud sync, authentication, subscriptions or ad SDKs are added later, this declaration and the privacy policy must be updated before shipping that build.
