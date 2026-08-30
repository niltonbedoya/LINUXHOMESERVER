#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$UserStateRoot = (Join-Path $env:LOCALAPPDATA 'HomepageMetricsAgent'),
    [string]$SshHost = 'macmini'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

if ($SshHost -notmatch '^[A-Za-z0-9._-]+$') {
    throw "Alias SSH no valido: $SshHost"
}

$secretPath = Join-Path $UserStateRoot 'secret.dpapi'
if (-not (Test-Path -LiteralPath $secretPath -PathType Leaf)) {
    throw "No existe el secreto local cifrado: $secretPath"
}

$sshCommand = Get-Command ssh.exe -CommandType Application -ErrorAction Stop |
    Select-Object -First 1
$remoteScript = '/home/bedvil/server/services/homepage/scripts/set-nilton-pc-metrics-secret.sh'

$encryptedSecret = (Get-Content -LiteralPath $secretPath -Raw).Trim()
$securePassword = ConvertTo-SecureString $encryptedSecret
$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$plainPassword = $null
$process = $null

try {
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    if ($plainPassword -notmatch '^[A-Za-z0-9_-]{43}$') {
        throw 'El secreto DPAPI descifrado no tiene el formato esperado.'
    }

    $startInfo = New-Object Diagnostics.ProcessStartInfo
    $startInfo.FileName = $sshCommand.Source
    $startInfo.Arguments = "$SshHost $remoteScript"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = New-Object Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw 'No se pudo iniciar ssh.exe.'
    }

    $process.StandardInput.WriteLine($plainPassword)
    $process.StandardInput.Close()
    $standardOutput = $process.StandardOutput.ReadToEnd().Trim()
    $standardError = $process.StandardError.ReadToEnd().Trim()
    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($standardError)) {
            throw "SSH devolvio el codigo $($process.ExitCode)."
        }
        throw "SSH devolvio el codigo $($process.ExitCode): $standardError"
    }

    if (-not [string]::IsNullOrWhiteSpace($standardOutput)) {
        Write-Output $standardOutput
    }
    # Windows PowerShell 5.1 convierte '' en null y Set-Clipboard lo rechaza.
    # Un espacio reemplaza cualquier secreto previo sin conservarlo.
    Set-Clipboard -Value ' '
    Write-Output 'Transferencia verificada por SSH; portapapeles sobrescrito.'
} finally {
    $plainPassword = $null
    $encryptedSecret = $null
    if ($null -ne $process) {
        $process.Dispose()
    }
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
}
