# App Store Connect values

## Product page

- Primary language: Russian
- Bundle ID: `com.nevsk1y.vault` (must be registered and available)
- SKU: `vault-ios-2026`
- Primary category: Productivity
- Secondary category: Photo & Video
- Copyright: `2026 VAULT`
- Privacy Policy URL: `https://l1bertyinsad-blip.github.io/VAULT/privacy.html`
- Support URL: `https://l1bertyinsad-blip.github.io/VAULT/support.html`
- Marketing URL: `https://l1bertyinsad-blip.github.io/VAULT/`

The localized product-page text is in `AppStore/metadata`.

## App Privacy answers

- Does this app collect data? **No**.
- Tracking: **No**.
- Third-party advertising: **No**.
- Analytics: **No**.

This is accurate for the current source tree: there is no account, developer backend, advertising SDK, analytics SDK, or crash-reporting SDK. Link previews can contact the source website from the device, but the developer does not receive that data.

Recheck these answers if analytics, sync, accounts, ads, or a backend are added.

## Age Rating questionnaire

For the current app, answer **None/No** for developer-provided objectionable content, gambling, contests, simulated gambling, violence, sexual content, drugs, and unrestricted embedded web access. Users may save their own local content and open source URLs in the system browser. Let App Store Connect calculate the final rating.

## Export compliance

The build declares `ITSAppUsesNonExemptEncryption = NO`. VAULT uses Apple system networking and SHA-256 hashing for duplicate detection; it does not implement proprietary or non-exempt encryption. Confirm the generated App Store Connect questionnaire before submission.

## App Review notes

Copy the following into Review Notes:

> VAULT is a local-only personal media and idea organizer. No account or demo login is required. To test the Share Extension: open Safari or Photos, choose Share, select “Добавить в VAULT”, choose a destination folder, and return to VAULT. If a social app provides only a URL, VAULT stores a link card and does not download protected media. OCR, duplicate detection, notes, search, and Face ID run on-device. The Privacy Policy and Support links are available under Profile → Settings.

## Content rights

The app contains only the VAULT logo, SF Symbols, code-owned UI, and user-provided content. Do not upload App Store screenshots containing third-party trademarks, private photos, or copyrighted social-media posts without permission. The automated screenshot data uses generic demonstration links and text.
