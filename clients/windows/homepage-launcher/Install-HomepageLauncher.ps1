[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'HomepageLauncher'
$protocolRoot = 'HKCU:\Software\Classes\homeserver-launch'
$requiredFiles = @('HomepageLauncher.ps1', 'tools.json', 'Test-HomepageLauncher.ps1')

foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $requiredFile) -PathType Leaf)) {
        throw "Falta el archivo requerido: $requiredFile"
    }
}

New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
foreach ($requiredFile in $requiredFiles) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $requiredFile) `
        -Destination (Join-Path $installRoot $requiredFile) -Force
}

New-Item -Path $protocolRoot -Force | Out-Null
Set-Item -Path $protocolRoot -Value 'URL:Home Server Launcher'
New-ItemProperty -Path $protocolRoot -Name 'URL Protocol' -Value '' `
    -PropertyType String -Force | Out-Null

$commandKey = New-Item -Path (Join-Path $protocolRoot 'shell\open\command') -Force
$launcherPath = Join-Path $installRoot 'HomepageLauncher.ps1'
$powershellPath = Join-Path $PSHOME 'powershell.exe'
$protocolCommand = ('"{0}" -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "{1}" "%1"' -f `
    $powershellPath, $launcherPath)
Set-Item -Path $commandKey.PSPath -Value $protocolCommand

& (Join-Path $installRoot 'Test-HomepageLauncher.ps1') -InstalledPath $installRoot
if ($LASTEXITCODE -ne 0) {
    throw 'Las pruebas del lanzador no finalizaron correctamente.'
}

Write-Host "Homepage Launcher instalado para $env:USERNAME."
Write-Host 'Protocolo registrado: homeserver-launch://'
