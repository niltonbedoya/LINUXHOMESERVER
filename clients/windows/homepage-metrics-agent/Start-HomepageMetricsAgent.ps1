[CmdletBinding()]
param(
    [string]$InstallRoot = 'C:\ProgramData\HomepageMetricsAgent',
    [string]$ExpectedTailscaleIPv4 = '100.105.88.14'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$python = Join-Path $InstallRoot 'venv\Scripts\python.exe'
$config = Join-Path $InstallRoot 'glances.conf'
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    throw "No existe el Python aislado: $python"
}
if (-not (Test-Path -LiteralPath $config -PathType Leaf)) {
    throw "No existe la configuracion: $config"
}

# Tailscale puede tardar unos segundos en crear su interfaz tras arrancar Windows.
$deadline = (Get-Date).AddMinutes(5)
do {
    $address = Get-NetIPAddress -AddressFamily IPv4 -IPAddress $ExpectedTailscaleIPv4 -ErrorAction SilentlyContinue
    if ($address) {
        break
    }
    Start-Sleep -Seconds 5
} while ((Get-Date) -lt $deadline)

if (-not $address) {
    throw "Tailscale no presento $ExpectedTailscaleIPv4 durante cinco minutos."
}

& $python -m glances `
    -C $config `
    -w `
    --disable-webui `
    --disable-autodiscover `
    --disable-process `
    --disable-plugin all `
    --enable-plugin quicklook,system,cpu,mem,fs,uptime `
    --hide-public-info `
    --disable-config-exec `
    --disable-check-update `
    -B $ExpectedTailscaleIPv4 `
    -p 61208 `
    -u homepage

exit $LASTEXITCODE
