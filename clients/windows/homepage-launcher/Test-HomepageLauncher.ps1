[CmdletBinding()]
param(
    [string]$InstalledPath = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$launcherPath = Join-Path $InstalledPath 'HomepageLauncher.ps1'
$catalogPath = Join-Path $InstalledPath 'tools.json'
$protocolRoot = 'HKCU:\Software\Classes\homeserver-launch'

foreach ($path in @($launcherPath, $catalogPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Falta el archivo requerido: $path"
    }
}

$catalogDocument = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$catalog = @()
foreach ($catalogItem in $catalogDocument) {
    $catalog += $catalogItem
}
if ($catalog.Count -lt 1) { throw 'El catálogo está vacío.' }

$ids = @($catalog | ForEach-Object { $_.id })
if (@($ids | Sort-Object -Unique).Count -ne $ids.Count) {
    throw 'Hay identificadores duplicados en el catálogo.'
}

foreach ($tool in $catalog) {
    if ($tool.id -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
        throw "Identificador no permitido: $($tool.id)"
    }
    try {
        $fallbackUri = [Uri][string]$tool.fallbackUrl
    } catch {
        throw "Fallback no válido para $($tool.id)"
    }
    if (-not $fallbackUri.IsAbsoluteUri -or $fallbackUri.Scheme -ne 'https') {
        throw "Fallback no HTTPS para $($tool.id)"
    }

    $resolved = & $launcherPath "homeserver-launch://$($tool.id)" -ResolveOnly |
        ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $resolved.id -cne $tool.id) {
        throw "No se pudo resolver $($tool.id)"
    }
    if ($resolved.action -notin @('app', 'cli', 'executable', 'warp-tab', 'web')) {
        throw "Acción inesperada para $($tool.id): $($resolved.action)"
    }
    if ($tool.expectedInstalled -and $resolved.action -eq 'web') {
        throw "$($tool.name) constaba como instalado, pero solo se encontró el fallback web."
    }
}

$opencode = $catalog | Where-Object { $_.id -ceq 'opencode' } | Select-Object -First 1
$opencodeCommand = Get-Command 'opencode.cmd' -CommandType Application `
    -ErrorAction SilentlyContinue | Select-Object -First 1
$warpTabConfigPath = Join-Path $env:APPDATA `
    'warp\Warp\data\tab_configs\homepage_opencode.toml'
if (-not $opencodeCommand) {
    throw 'No se encontró opencode.cmd en PATH.'
}
if (-not (Test-Path -LiteralPath $warpTabConfigPath -PathType Leaf)) {
    throw 'Falta la Tab Config de OpenCode para Warp.'
}
$warpTabConfig = Get-Content -LiteralPath $warpTabConfigPath -Raw
if ($warpTabConfig -notmatch 'commands\s*=\s*\["opencode[.]cmd"\]' -or
    $warpTabConfig -notmatch 'shell\s*=\s*"bash"') {
    throw 'La Tab Config de Warp no fija Bash y opencode.cmd.'
}
$opencodeResolution = & $launcherPath 'homeserver-launch://opencode' -ResolveOnly |
    ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $opencodeResolution.action -ne 'warp-tab' -or
    $opencodeResolution.target -ne 'warp://tab_config/homepage_opencode') {
    throw 'OpenCode no resuelve a su Tab Config fija de Warp.'
}

& $launcherPath 'homeserver-launch://vscode/argumento' -ResolveOnly 2>$null
if ($LASTEXITCODE -eq 0) { throw 'El lanzador aceptó una ruta no autorizada.' }
& $launcherPath 'homeserver-launch://vscode?command=calc.exe' -ResolveOnly 2>$null
if ($LASTEXITCODE -eq 0) { throw 'El lanzador aceptó parámetros no autorizados.' }
& $launcherPath 'homeserver-launch://no-existe' -ResolveOnly 2>$null
if ($LASTEXITCODE -eq 0) { throw 'El lanzador aceptó una herramienta fuera de la lista.' }

if (Test-Path -LiteralPath $protocolRoot) {
    $registeredCommand = (Get-Item (Join-Path $protocolRoot 'shell\open\command')).GetValue('')
    if ($registeredCommand -notmatch [regex]::Escape($launcherPath)) {
        throw 'El protocolo no apunta al lanzador instalado.'
    }
}

Write-Host "Pruebas del lanzador: OK ($($catalog.Count) destinos)"
exit 0
