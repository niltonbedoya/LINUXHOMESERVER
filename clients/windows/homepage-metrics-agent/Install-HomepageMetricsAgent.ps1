#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$BasePythonPath = (Join-Path $env:APPDATA 'uv\python\cpython-3.11.15-windows-x86_64-none\python.exe'),
    [string]$ExpectedTailscaleIPv4 = '100.105.88.14',
    [string]$MacMiniTailscaleIPv4 = '100.72.206.57'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-IPv4 {
    param([Parameter(Mandatory = $true)][string]$Value)
    $parsed = $null
    if (-not ([Net.IPAddress]::TryParse($Value, [ref]$parsed)) -or $parsed.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
        throw "IPv4 no valida: $Value"
    }
}

if (-not (Test-IsAdministrator)) {
    $arguments = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', ('"{0}"' -f $PSCommandPath),
        '-BasePythonPath', ('"{0}"' -f $BasePythonPath),
        '-ExpectedTailscaleIPv4', $ExpectedTailscaleIPv4,
        '-MacMiniTailscaleIPv4', $MacMiniTailscaleIPv4
    )
    $process = Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    exit $process.ExitCode
}

Assert-IPv4 $ExpectedTailscaleIPv4
Assert-IPv4 $MacMiniTailscaleIPv4

if (-not (Test-Path -LiteralPath $BasePythonPath -PathType Leaf)) {
    throw "No existe la Python base validada: $BasePythonPath"
}
$pythonVersion = (& $BasePythonPath -c 'import platform; print(platform.python_version())' 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $pythonVersion -notmatch '^3[.]11[.]') {
    throw "Se esperaba CPython 3.11 y se obtuvo: $pythonVersion"
}

$tailscale = Join-Path $env:ProgramFiles 'Tailscale\tailscale.exe'
if (-not (Test-Path -LiteralPath $tailscale -PathType Leaf)) {
    throw "No existe Tailscale CLI: $tailscale"
}
$observedIPs = @(& $tailscale ip -4 2>$null)
if (-not ($observedIPs -contains $ExpectedTailscaleIPv4)) {
    throw "Tailscale no presenta la IP esperada $ExpectedTailscaleIPv4. Observadas: $($observedIPs -join ', ')"
}

$foreignListeners = @(Get-NetTCPConnection -State Listen -LocalPort 61208 -ErrorAction SilentlyContinue)
$existingTask = Get-ScheduledTask -TaskName 'HomepageMetricsAgent' -ErrorAction SilentlyContinue
$installRoot = Join-Path $env:ProgramData 'HomepageMetricsAgent'
$userStateRoot = Join-Path $env:LOCALAPPDATA 'HomepageMetricsAgent'
$existingFirewall = Get-NetFirewallRule -DisplayName 'Homepage Metrics Agent - Tailscale' -ErrorAction SilentlyContinue
if ($foreignListeners.Count -gt 0 -or $existingTask -or $existingFirewall -or (Test-Path -LiteralPath $installRoot)) {
    throw 'Ya existe una instalacion o el puerto 61208 esta ocupado. Ejecuta primero el test o el desinstalador; no se sobrescribira.'
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stageRoot = Join-Path $env:ProgramData ("HomepageMetricsAgent.new-$timestamp-$([Guid]::NewGuid().ToString('N'))")
$venvPython = Join-Path $stageRoot 'venv\Scripts\python.exe'
$passwordDir = Join-Path $stageRoot 'passwords'
$username = 'homepage'
$glancesVersion = '4.5.6'
$activated = $false

try {
    New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
    & $BasePythonPath -m venv (Join-Path $stageRoot 'venv')
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el venv independiente.' }

    & $venvPython -m pip install --disable-pip-version-check --no-input "glances[web]==$glancesVersion"
    if ($LASTEXITCODE -ne 0) { throw 'pip no pudo instalar Glances.' }
    & $venvPython -m pip check
    if ($LASTEXITCODE -ne 0) { throw 'pip check encontro dependencias inconsistentes.' }
    & $venvPython -m glances --version
    if ($LASTEXITCODE -ne 0) { throw 'Glances instalado no puede iniciarse.' }
    & $venvPython -m pip freeze | Set-Content -LiteralPath (Join-Path $stageRoot 'requirements.lock.txt') -Encoding ASCII

    foreach ($name in @(
        'Write-GlancesPassword.py',
        'Start-HomepageMetricsAgent.ps1',
        'Test-HomepageMetricsAgent.ps1',
        'Copy-HomepageMetricsSecret.ps1',
        'Send-HomepageMetricsSecret.ps1',
        'Uninstall-HomepageMetricsAgent.ps1'
    )) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $stageRoot $name) -Force
    }

    New-Item -ItemType Directory -Path $passwordDir -Force | Out-Null
    $randomBytes = New-Object byte[] 32
    $random = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $random.GetBytes($randomBytes)
    } finally {
        $random.Dispose()
    }
    $plainPassword = [Convert]::ToBase64String($randomBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    try {
        $plainPassword | & $venvPython (Join-Path $stageRoot 'Write-GlancesPassword.py') $passwordDir $username
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el hash de autenticacion.' }

        if (Test-Path -LiteralPath $userStateRoot) {
            $failedState = "$userStateRoot-failed-$timestamp"
            Move-Item -LiteralPath $userStateRoot -Destination $failedState
        }
        New-Item -ItemType Directory -Path $userStateRoot -Force | Out-Null
        ConvertTo-SecureString $plainPassword -AsPlainText -Force |
            ConvertFrom-SecureString |
            Set-Content -LiteralPath (Join-Path $userStateRoot 'secret.dpapi') -Encoding ASCII
    } finally {
        $plainPassword = $null
        [Array]::Clear($randomBytes, 0, $randomBytes.Length)
    }

    @"
[outputs]
cors_origins=https://macmini-server.tailf553c4.ts.net:10000
cors_credentials=False
webui_allowed_hosts=nilton-pc.tailf553c4.ts.net,$ExpectedTailscaleIPv4

[passwords]
local_password_path=C:\ProgramData\HomepageMetricsAgent\passwords
"@ | Set-Content -LiteralPath (Join-Path $stageRoot 'glances.conf') -Encoding ASCII

    [ordered]@{
        schema = 1
        hostname = 'Nilton-PC'
        tailscale_dns = 'nilton-pc.tailf553c4.ts.net'
        tailscale_ipv4 = $ExpectedTailscaleIPv4
        macmini_tailscale_ipv4 = $MacMiniTailscaleIPv4
        port = 61208
        username = $username
        glances_version = $glancesVersion
        python_version = $pythonVersion
        installed_at = (Get-Date).ToString('o')
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stageRoot 'agent.json') -Encoding ASCII

    & icacls.exe $passwordDir /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron restringir las ACL de passwords.' }

    Move-Item -LiteralPath $stageRoot -Destination $installRoot
    $activated = $true

    $firewallParams = @{
        DisplayName = 'Homepage Metrics Agent - Tailscale'
        Direction = 'Inbound'
        Action = 'Allow'
        Enabled = 'True'
        Profile = 'Any'
        Protocol = 'TCP'
        LocalAddress = $ExpectedTailscaleIPv4
        LocalPort = 61208
        RemoteAddress = $MacMiniTailscaleIPv4
        Program = (Join-Path $installRoot 'venv\Scripts\python.exe')
        Description = 'Permite Glances solo desde el Mac mini a traves de Tailscale.'
    }
    New-NetFirewallRule @firewallParams | Out-Null

    $taskAction = New-ScheduledTaskAction `
        -Execute 'powershell.exe' `
        -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -InstallRoot `"{1}`" -ExpectedTailscaleIPv4 {2}" -f (Join-Path $installRoot 'Start-HomepageMetricsAgent.ps1'), $installRoot, $ExpectedTailscaleIPv4) `
        -WorkingDirectory $installRoot
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $taskSettings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskName 'HomepageMetricsAgent' -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings -Description 'Glances privado para Homepage sobre Tailscale.' | Out-Null
    Start-ScheduledTask -TaskName 'HomepageMetricsAgent'

    $deadline = (Get-Date).AddSeconds(45)
    do {
        Start-Sleep -Seconds 2
        $listener = Get-NetTCPConnection -State Listen -LocalPort 61208 -ErrorAction SilentlyContinue
    } while (-not $listener -and (Get-Date) -lt $deadline)
    if (-not $listener) {
        throw 'El agente no abrio 61208 dentro de 45 segundos.'
    }

    & (Join-Path $installRoot 'Test-HomepageMetricsAgent.ps1') -InstallRoot $installRoot -UserStateRoot $userStateRoot
    if ($LASTEXITCODE -ne 0) { throw 'Las pruebas del agente devolvieron error.' }

    & (Join-Path $installRoot 'Copy-HomepageMetricsSecret.ps1') -UserStateRoot $userStateRoot
    Write-Output 'Homepage Metrics Agent instalado. El secreto esta en el portapapeles; no lo publiques.'
} catch {
    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
    if ($activated) {
        Stop-ScheduledTask -TaskName 'HomepageMetricsAgent' -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName 'HomepageMetricsAgent' -Confirm:$false -ErrorAction SilentlyContinue
        Get-NetFirewallRule -DisplayName 'Homepage Metrics Agent - Tailscale' -ErrorAction SilentlyContinue |
            Remove-NetFirewallRule -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $installRoot) {
            $failedRoot = Join-Path $env:ProgramData ("HomepageMetricsAgent-failed-$timestamp")
            Move-Item -LiteralPath $installRoot -Destination $failedRoot -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $userStateRoot) {
            $failedUserState = "$userStateRoot-failed-install-$timestamp"
            Move-Item -LiteralPath $userStateRoot -Destination $failedUserState -ErrorAction SilentlyContinue
        }
    }
    throw
}
