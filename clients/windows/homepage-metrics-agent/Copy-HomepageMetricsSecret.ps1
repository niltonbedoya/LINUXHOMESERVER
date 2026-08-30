[CmdletBinding()]
param(
    [string]$UserStateRoot = (Join-Path $env:LOCALAPPDATA 'HomepageMetricsAgent')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$secretPath = Join-Path $UserStateRoot 'secret.dpapi'
if (-not (Test-Path -LiteralPath $secretPath -PathType Leaf)) {
    throw "No existe el secreto local cifrado: $secretPath"
}

$encryptedSecret = (Get-Content -LiteralPath $secretPath -Raw).Trim()
$securePassword = ConvertTo-SecureString $encryptedSecret
$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try {
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    Set-Clipboard -Value $plainPassword
} finally {
    $plainPassword = $null
    $encryptedSecret = $null
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
}

Write-Output 'Secreto copiado temporalmente al portapapeles. No lo pegues en el chat ni en un comando visible.'
