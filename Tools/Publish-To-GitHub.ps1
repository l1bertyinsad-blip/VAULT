param(
    [string]$Repository = 'l1bertyinsad-blip/VAULT'
)

$ErrorActionPreference = 'Stop'
$source = (Split-Path -Parent $PSScriptRoot)
$gh = Get-Command gh -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $gh) {
    throw 'GitHub CLI is missing. Install it with: winget install --id GitHub.cli'
}

$gitCandidates = @(
    (Get-Command git -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
    (Join-Path $HOME '.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe')
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
$git = $gitCandidates | Select-Object -First 1
if (-not $git) { throw 'Git is missing.' }

& $gh auth status
if ($LASTEXITCODE -ne 0) { throw 'Run gh auth login first, then start this script again.' }

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("vault-release-" + [guid]::NewGuid().ToString('N'))
$checkout = Join-Path $temporaryRoot 'repo'
$branch = 'agent/app-store-ready-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

try {
    & $git clone "https://github.com/$Repository.git" $checkout
    if ($LASTEXITCODE -ne 0) { throw 'Unable to clone the GitHub repository.' }

    & robocopy.exe $source $checkout /MIR /XD .git Signing DerivedData /XF *.p8 *.p12 *.cer *.csr *.key *.ipa *.xcarchive *.xcresult | Out-Host
    if ($LASTEXITCODE -gt 7) { throw "Robocopy failed with exit code $LASTEXITCODE." }

    Push-Location $checkout
    try {
        & $git checkout -b $branch
        & $git add -A
        & $git commit -m 'Prepare VAULT for App Store release'
        if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }
        & $git push -u origin $branch
        if ($LASTEXITCODE -ne 0) { throw 'Git push failed.' }

        $body = @"
## What changed

- update CI to Xcode 26.3 and iOS 26 SDK
- add App Store signing, archive, validation, and upload workflow
- add real UI screenshot capture and 1320x2868 marketing-card generation
- add privacy manifest, Privacy Policy, Support page, and App Store metadata
- add Windows signing and release helpers

## Validation

- Swift lexical and tree-sitter parse audit
- Xcode project parser
- plist, entitlements, privacy manifest, and workflow YAML parsing
- screenshot-card generator smoke test

The signed archive still requires the Apple account holder's Team ID, API key, and Apple Distribution certificate in GitHub Secrets.
"@
        & $gh pr create --repo $Repository --base main --head $branch --title 'Prepare VAULT for App Store release' --body $body
        if ($LASTEXITCODE -ne 0) { throw 'Pull request creation failed.' }
    } finally {
        Pop-Location
    }
} finally {
    $resolvedTemp = (Resolve-Path -LiteralPath $temporaryRoot -ErrorAction SilentlyContinue).Path
    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedTemp -and $resolvedTemp.StartsWith($systemTemp, [StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
    }
}
