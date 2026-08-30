[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'HomepageLauncher'
$protocolRoot = 'HKCU:\Software\Classes\homeserver-launch'
$requiredFiles = @(
    'HomepageLauncher.ps1',
    'tools.json',
    'Test-HomepageLauncher.ps1',
    'Uninstall-HomepageLauncher.ps1',
    'warp-homepage-opencode.toml'
)

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

$warpTabConfigRoot = Join-Path $env:APPDATA 'warp\Warp\data\tab_configs'
$warpTabConfigPath = Join-Path $warpTabConfigRoot 'homepage_opencode.toml'
$warpTabConfigSource = Join-Path $installRoot 'warp-homepage-opencode.toml'
New-Item -ItemType Directory -Path $warpTabConfigRoot -Force | Out-Null
if (Test-Path -LiteralPath $warpTabConfigPath -PathType Leaf) {
    $existingHash = (Get-FileHash -LiteralPath $warpTabConfigPath -Algorithm SHA256).Hash
    $sourceHash = (Get-FileHash -LiteralPath $warpTabConfigSource -Algorithm SHA256).Hash
    if ($existingHash -ne $sourceHash) {
        $backupPath = '{0}.backup-{1}' -f $warpTabConfigPath, (Get-Date -Format 'yyyyMMdd-HHmmss')
        Copy-Item -LiteralPath $warpTabConfigPath -Destination $backupPath
        Write-Host "Backup de la configuración Warp: $backupPath"
    }
}
Copy-Item -LiteralPath $warpTabConfigSource -Destination $warpTabConfigPath -Force

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

Write-Host "Homepage Launcher instalado para $env:USERNAME."
Write-Host 'Protocolo registrado: homeserver-launch://'
