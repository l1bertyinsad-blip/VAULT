param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$CertificatePath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$signingDirectory = Join-Path $projectRoot 'Signing'
$p12Certificate = Join-Path $signingDirectory 'AppleDistribution.p12'

New-Item -ItemType Directory -Path $signingDirectory -Force | Out-Null
& certreq.exe -accept $CertificatePath
if ($LASTEXITCODE -ne 0) { throw 'Windows could not match the Apple certificate to the pending private key.' }

$downloadedCertificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new(
    (Resolve-Path -LiteralPath $CertificatePath).Path
)
$certificate = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.Thumbprint -eq $downloadedCertificate.Thumbprint -and $_.HasPrivateKey } |
    Select-Object -First 1
if (-not $certificate) {
    throw 'The accepted certificate has no matching private key. Run both scripts on the same Windows account and computer.'
}

$securePassword = Read-Host 'Choose a password for AppleDistribution.p12' -AsSecureString
Export-PfxCertificate -Cert $certificate -FilePath $p12Certificate -Password $securePassword -Force | Out-Null

Write-Host "Created: $p12Certificate" -ForegroundColor Green
Write-Host 'Use the same password in the APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD GitHub secret.'
