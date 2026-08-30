[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'HomepageLauncher'
$protocolRoot = 'HKCU:\Software\Classes\homeserver-launch'

if (Test-Path -LiteralPath $protocolRoot) {
    Remove-Item -LiteralPath $protocolRoot -Recurse -Force
}
if (Test-Path -LiteralPath $installRoot) {
    Remove-Item -LiteralPath $installRoot -Recurse -Force
}

Write-Host 'Homepage Launcher desinstalado para el usuario actual.'
