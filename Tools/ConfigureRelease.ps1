param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$')]
    [string]$BundleId,

    [ValidatePattern('^\d+\.\d+(\.\d+)?$')]
    [string]$Version = '1.6.0',

    [ValidateRange(1, 2147483647)]
    [int]$Build = 8
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$oldBundleId = 'com.nevsk1y.vault'
$oldAppGroup = "group.$oldBundleId"
$newAppGroup = "group.$BundleId"
$utf8 = [System.Text.UTF8Encoding]::new($false)

$paths = @(
    (Join-Path $projectRoot 'VAULT.xcodeproj\project.pbxproj'),
    (Join-Path $projectRoot 'VAULT\VAULT.entitlements'),
    (Join-Path $projectRoot 'VAULT\Services\MediaImportService.swift'),
    (Join-Path $projectRoot 'VAULTShareExtension\VAULTShareExtension.entitlements'),
    (Join-Path $projectRoot 'VAULTShareExtension\ShareViewController.swift'),
    (Join-Path $projectRoot 'README.md')
)

foreach ($path in $paths) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required project file is missing: $path"
    }
    $content = [IO.File]::ReadAllText($path)
    $content = $content.Replace($oldAppGroup, $newAppGroup).Replace($oldBundleId, $BundleId)
    if ($path.EndsWith('project.pbxproj')) {
        $content = [regex]::Replace($content, 'MARKETING_VERSION = [^;]+;', "MARKETING_VERSION = $Version;")
        $content = [regex]::Replace($content, 'CURRENT_PROJECT_VERSION = \d+;', "CURRENT_PROJECT_VERSION = $Build;")
    }
    [IO.File]::WriteAllText($path, $content, $utf8)
}

Write-Host "Configured VAULT for App Store:" -ForegroundColor Green
Write-Host "  Bundle ID:       $BundleId"
Write-Host "  Share Extension: $BundleId.share"
Write-Host "  App Group:       $newAppGroup"
Write-Host "  Version:         $Version ($Build)"
