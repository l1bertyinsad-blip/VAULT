# VAULT: quickest App Store upload path

## The payment constraint

An individual Apple Account can develop and test for free, but cannot submit a public App Store app. Public distribution requires an active Apple Developer Program team.

The legal zero-payment routes for the developer are:

1. An eligible nonprofit legal entity, accredited educational institution, or government entity receives Apple's fee waiver. Individuals, sole proprietors, and one-person businesses are not eligible.
2. An existing paid publisher invites you to its Apple Developer team and agrees to publish VAULT under that publisher's seller name. The publisher controls the App Store record until it transfers the app.
3. An accredited university publishes it using its institutional developer team.

There is no legitimate “free individual App Store upload” loophole. A free personal team can install a development build on an iPhone for testing, but that is not an App Store release. Apple's review and fee-waiver approval also cannot be guaranteed on the same day.

Official references: [program enrollment](https://developer.apple.com/help/account/membership/program-enrollment/), [fee waiver requirements](https://developer.apple.com/help/account/membership/fee-waivers/), [membership comparison](https://developer.apple.com/support/compare-memberships/).

## What is already automated

- Xcode 26.3 build and tests on GitHub macOS.
- Privacy manifest and required-reason API declarations.
- Own Privacy Policy, Support, and Marketing pages.
- Real UI screenshots and 1320×2868 App Store marketing cards.
- Signed archive, IPA export, validation, and App Store Connect upload.
- Russian and English product-page text and App Review notes.

## Publish this package to GitHub

The project contains a one-command publisher. Install GitHub CLI once, authorize it, and run:

```powershell
winget install --id GitHub.cli
gh auth login
.\Tools\Publish-To-GitHub.ps1
```

It creates an isolated release branch and pull request without committing signing keys. Merge the pull request after the **Build and test VAULT** check is green.

## Actions only the Apple account holder can perform

### 1. Enroll or join a team

Use [Apple Developer enrollment](https://developer.apple.com/programs/enroll/). Turn on two-factor authentication. If using a publisher, ask its Account Holder or Admin to invite your Apple Account in App Store Connect and the developer team.

### 2. Register identifiers

In [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list):

1. Register App Group `group.com.nevsk1y.vault`.
2. Register explicit App ID `com.nevsk1y.vault`, enable App Groups, and assign that group.
3. Register explicit App ID `com.nevsk1y.vault.share`, enable App Groups, and assign the same group.

If `com.nevsk1y.vault` is unavailable, choose a unique base ID and run from the project folder:

```powershell
.\Tools\ConfigureRelease.ps1 -BundleId "com.yourbrand.vault" -Version "1.6.0" -Build 8
```

Then register the values printed by the script.

### 3. Create the App Store Connect record

Open [App Store Connect → Apps](https://appstoreconnect.apple.com/apps), press `+` → **New App**, and use the values in `AppStore/APP_STORE_CONNECT_VALUES.md`. The Bundle ID must match the project.

### 4. Create the App Store Connect API key

In App Store Connect open **Users and Access → Integrations → App Store Connect API**. Create a team key with Admin access and download the `.p8` file once. Record its Key ID and Issuer ID.

### 5. Create an Apple Distribution certificate on Windows

From PowerShell in the project folder:

```powershell
.\Tools\New-AppleSigningRequest.ps1 -CommonName "YOUR LEGAL NAME" -Email "YOUR APPLE ACCOUNT EMAIL"
```

In the Apple Developer portal create a certificate of type **Apple Distribution**, upload `Signing/AppleDistribution.csr`, and download the resulting `.cer`. Then run:

```powershell
.\Tools\Complete-AppleSigningCertificate.ps1 -CertificatePath "C:\path\distribution.cer"
```

Never commit the `Signing` folder.

### 6. Add GitHub Secrets

Open repository **Settings → Secrets and variables → Actions → New repository secret** and add:

- `APPLE_TEAM_ID`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY_BASE64`
- `APPLE_DISTRIBUTION_CERTIFICATE_BASE64`
- `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD`
- `KEYCHAIN_PASSWORD` — any new strong temporary keychain password

Generate the two Base64 values locally and paste only the results into GitHub Secrets:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\AuthKey_ABC123.p8")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".\Signing\AppleDistribution.p12")) | Set-Clipboard
```

### 7. Publish the required web pages

In GitHub open **Settings → Pages** and select **GitHub Actions** as the source. Run the **Publish support pages** workflow. Confirm these URLs open before review:

- `https://l1bertyinsad-blip.github.io/VAULT/privacy.html`
- `https://l1bertyinsad-blip.github.io/VAULT/support.html`

If the repository owner or name changes, update these URLs in `SettingsView.swift` and `AppStore/APP_STORE_CONNECT_VALUES.md`.

### 8. Generate screenshots

Open **Actions → App Store screenshots → Run workflow**. Download the `VAULT-App-Store-Screenshots-RU` artifact and upload the five PNG files to the 6.9-inch iPhone screenshot slot.

### 9. Upload the build

Open **Actions → App Store release → Run workflow** with upload enabled. The workflow signs the app, creates an IPA, validates it, and uploads it to App Store Connect. Build processing can take several minutes.

### 10. Submit for review

In App Store Connect:

1. Copy the localized metadata from `AppStore/metadata`.
2. Add the screenshots.
3. Complete App Privacy, Age Rating, Content Rights, and Export Compliance using `AppStore/APP_STORE_CONNECT_VALUES.md`.
4. Select the processed build.
5. Paste the prepared Review Notes.
6. Press **Add for Review**, then **Submit for Review**.

Submitting today is realistic once the Apple team is active. Approval and public availability today are controlled by Apple and cannot be promised.
