[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'HomepageLauncher'
$protocolRoot = 'HKCU:\Software\Classes\homeserver-launch'
$warpTabConfigPath = Join-Path $env:APPDATA `
    'warp\Warp\data\tab_configs\homepage_opencode.toml'
$warpTabConfigSource = Join-Path $installRoot 'warp-homepage-opencode.toml'

if (Test-Path -LiteralPath $protocolRoot) {
    Remove-Item -LiteralPath $protocolRoot -Recurse -Force
}
if ((Test-Path -LiteralPath $warpTabConfigPath -PathType Leaf) -and
    (Test-Path -LiteralPath $warpTabConfigSource -PathType Leaf)) {
    $installedHash = (Get-FileHash -LiteralPath $warpTabConfigPath -Algorithm SHA256).Hash
    $sourceHash = (Get-FileHash -LiteralPath $warpTabConfigSource -Algorithm SHA256).Hash
    if ($installedHash -eq $sourceHash) {
        Remove-Item -LiteralPath $warpTabConfigPath -Force
    } else {
        Write-Warning 'La Tab Config de OpenCode fue modificada y se conserva.'
    }
}
if (Test-Path -LiteralPath $installRoot) {
    Remove-Item -LiteralPath $installRoot -Recurse -Force
}

Write-Host 'Homepage Launcher desinstalado para el usuario actual.'
