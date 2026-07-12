param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[^,=\r\n]+$')]
    [string]$CommonName,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
    [string]$Email,

    [ValidatePattern('^[A-Z]{2}$')]
    [string]$Country = 'KZ'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$signingDirectory = Join-Path $projectRoot 'Signing'
$requestConfiguration = Join-Path $signingDirectory 'AppleDistribution.inf'
$request = Join-Path $signingDirectory 'AppleDistribution.csr'

New-Item -ItemType Directory -Path $signingDirectory -Force | Out-Null
$configuration = @"
[Version]
Signature="`$Windows NT`$"

[NewRequest]
Subject = "CN=$CommonName, E=$Email, C=$Country"
KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = FALSE
SMIME = FALSE
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft Software Key Storage Provider"
ProviderType = 0
RequestType = PKCS10
KeyUsage = 0xa0
HashAlgorithm = sha256
"@
[IO.File]::WriteAllText($requestConfiguration, $configuration, [Text.UTF8Encoding]::new($false))

& certreq.exe -new $requestConfiguration $request
if ($LASTEXITCODE -ne 0) { throw 'Failed to create the certificate signing request.' }

Write-Host "Created: $request" -ForegroundColor Green
Write-Host 'Upload this CSR when creating an Apple Distribution certificate.'
Write-Host 'Windows stored the matching private key in the current user certificate store.' -ForegroundColor Yellow
Write-Host 'Complete the certificate on this same Windows account and computer.' -ForegroundColor Yellow
