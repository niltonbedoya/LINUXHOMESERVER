[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Uri,

    [switch]$ResolveOnly
)

$ErrorActionPreference = 'Stop'
$catalogPath = Join-Path $PSScriptRoot 'tools.json'

function Stop-Launcher {
    param([string]$Message, [int]$ExitCode = 1)
    [Console]::Error.WriteLine("Homepage Launcher: $Message")
    exit $ExitCode
}

try {
    $parsedUri = [Uri]$Uri
} catch {
    Stop-Launcher 'URI no válida.' 2
}

if ($parsedUri.Scheme -cne 'homeserver-launch' -or
    [string]::IsNullOrWhiteSpace($parsedUri.Host) -or
    ($parsedUri.AbsolutePath -notin @('', '/')) -or
    -not [string]::IsNullOrEmpty($parsedUri.Query) -or
    -not [string]::IsNullOrEmpty($parsedUri.Fragment) -or
    -not [string]::IsNullOrEmpty($parsedUri.UserInfo) -or
    -not $parsedUri.IsDefaultPort) {
    Stop-Launcher 'El protocolo solo admite homeserver-launch://<identificador>.' 2
}

$toolId = $parsedUri.Host.ToLowerInvariant()
if ($toolId -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
    Stop-Launcher 'Identificador no permitido.' 2
}

try {
    $catalog = @(Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json)
} catch {
    Stop-Launcher "No se pudo leer el catálogo: $($_.Exception.Message)"
}

$tool = @($catalog | Where-Object { $_.id -ceq $toolId })
if ($tool.Count -ne 1) {
    Stop-Launcher "Herramienta no autorizada: $toolId" 2
}
$tool = $tool[0]

$startApps = @(Get-StartApps -ErrorAction SilentlyContinue)
$registeredApp = $null
foreach ($appId in @($tool.appIds)) {
    $registeredApp = $startApps | Where-Object { $_.AppID -ceq $appId } | Select-Object -First 1
    if ($registeredApp) { break }
}

$resolvedCommand = $null
if (-not $registeredApp) {
    foreach ($commandName in @($tool.commands)) {
        $candidate = Get-Command $commandName -CommandType Application, ExternalScript -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($candidate) {
            $resolvedCommand = $candidate
            break
        }
    }
}

if ($registeredApp) {
    $resolution = [ordered]@{
        id = $tool.id
        name = $tool.name
        action = 'app'
        target = $registeredApp.AppID
    }
} elseif ($resolvedCommand) {
    $resolution = [ordered]@{
        id = $tool.id
        name = $tool.name
        action = $tool.mode
        target = $resolvedCommand.Source
    }
} else {
    $resolution = [ordered]@{
        id = $tool.id
        name = $tool.name
        action = 'web'
        target = $tool.fallbackUrl
    }
}

if ($ResolveOnly) {
    [pscustomobject]$resolution | ConvertTo-Json -Compress
    exit 0
}

try {
    switch ($resolution.action) {
        'app' {
            Start-Process -FilePath 'explorer.exe' -ArgumentList "shell:AppsFolder\$($resolution.target)"
        }
        'cli' {
            $windowsTerminal = Get-Command wt -CommandType Application -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($windowsTerminal) {
                Start-Process -FilePath $windowsTerminal.Source -ArgumentList '--', $resolution.target
            } else {
                Start-Process -FilePath $resolution.target
            }
        }
        default {
            Start-Process -FilePath $resolution.target
        }
    }
} catch {
    Stop-Launcher "No se pudo abrir $($tool.name): $($_.Exception.Message)"
}
