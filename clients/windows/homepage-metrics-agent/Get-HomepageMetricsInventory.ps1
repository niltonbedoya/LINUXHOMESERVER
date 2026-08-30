[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Write-Section {
    param([Parameter(Mandatory = $true)][string]$Name)
    Write-Output ""
    Write-Output "=== $Name ==="
}

function Find-TailscaleCommand {
    $command = Get-Command tailscale.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidate = Join-Path $env:ProgramFiles 'Tailscale\tailscale.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return $candidate
    }

    return $null
}

Write-Output 'Inventario Homepage Metrics Agent (solo lectura)'
Write-Output ("Fecha: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))

Write-Section 'SISTEMA'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$processor = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpu = @(Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name)
$systemDrive = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $env:SystemDrive)

Write-Output ("Usuario: {0}" -f $identity.Name)
Write-Output ("Administrador: {0}" -f $isAdmin)
Write-Output ("Equipo: {0}" -f $env:COMPUTERNAME)
Write-Output ("Windows: {0} ({1})" -f $os.Caption, $os.Version)
Write-Output ("Arquitectura: {0}" -f $os.OSArchitecture)
Write-Output ("PowerShell: {0}" -f $PSVersionTable.PSVersion)
Write-Output ("CPU: {0}" -f $processor.Name)
Write-Output ("RAM bytes: {0}" -f [uint64]$computer.TotalPhysicalMemory)
Write-Output ("Disco {0} bytes: {1}" -f $env:SystemDrive, [uint64]$systemDrive.Size)
Write-Output ("GPU: {0}" -f ($gpu -join ' | '))

Write-Section 'TAILSCALE'
$tailscale = Find-TailscaleCommand
if ($tailscale) {
    Write-Output ("Ejecutable: {0}" -f $tailscale)
    & $tailscale version 2>&1 | ForEach-Object { Write-Output $_ }
    $tailscaleIPs = @(& $tailscale ip -4 2>$null)
    Write-Output ("IPv4: {0}" -f ($tailscaleIPs -join ', '))
} else {
    Write-Output 'Ejecutable: NO ENCONTRADO'
    Write-Output 'IPv4: NO DISPONIBLE'
}

Write-Section 'PYTHON'
$pythonCandidates = @('py.exe', 'python.exe', 'python3.exe')
$foundPython = $false
foreach ($name in $pythonCandidates) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $command) {
        continue
    }
    $foundPython = $true
    Write-Output ("{0}: {1}" -f $name, $command.Source)
    try {
        & $command.Source --version 2>&1 | ForEach-Object { Write-Output $_ }
    } catch {
        Write-Output ("No se pudo consultar {0}: {1}" -f $name, $_.Exception.Message)
    }
}
if (-not $foundPython) {
    Write-Output 'Python: NO ENCONTRADO'
}

$pyLauncher = Get-Command py.exe -ErrorAction SilentlyContinue
if ($pyLauncher) {
    try {
        Write-Output 'Instalaciones registradas por py.exe:'
        & $pyLauncher.Source -0p 2>&1 | ForEach-Object { Write-Output $_ }
    } catch {
        Write-Output ("py.exe -0p no disponible: {0}" -f $_.Exception.Message)
    }
}

Write-Section 'GLANCES Y PUERTO'
$glancesCommand = Get-Command glances.exe -ErrorAction SilentlyContinue
if ($glancesCommand) {
    Write-Output ("Glances global: {0}" -f $glancesCommand.Source)
    & $glancesCommand.Source --version 2>&1 | ForEach-Object { Write-Output $_ }
} else {
    Write-Output 'Glances global: NO ENCONTRADO'
}

$listeners = @(Get-NetTCPConnection -State Listen -LocalPort 61208 -ErrorAction SilentlyContinue)
if ($listeners.Count -eq 0) {
    Write-Output 'Listener 61208: LIBRE'
} else {
    foreach ($listener in $listeners) {
        Write-Output ("Listener 61208: {0}:{1} PID={2}" -f $listener.LocalAddress, $listener.LocalPort, $listener.OwningProcess)
    }
}

Write-Section 'CONFIGURACION EXISTENTE'
$installRoot = Join-Path $env:ProgramData 'HomepageMetricsAgent'
Write-Output ("Directorio: {0}" -f $installRoot)
Write-Output ("Existe: {0}" -f (Test-Path -LiteralPath $installRoot))

$task = Get-ScheduledTask -TaskName 'HomepageMetricsAgent' -ErrorAction SilentlyContinue
if ($task) {
    Write-Output ("Tarea: EXISTE ({0})" -f $task.State)
} else {
    Write-Output 'Tarea: NO EXISTE'
}

$firewall = Get-NetFirewallRule -DisplayName 'Homepage Metrics Agent - Tailscale' -ErrorAction SilentlyContinue
if ($firewall) {
    Write-Output ("Firewall: EXISTE ({0})" -f (($firewall | Select-Object -ExpandProperty Enabled) -join ', '))
    $firewall | Get-NetFirewallAddressFilter | ForEach-Object {
        Write-Output ("Firewall direcciones: local={0}; remoto={1}" -f ($_.LocalAddress -join ','), ($_.RemoteAddress -join ','))
    }
} else {
    Write-Output 'Firewall: NO EXISTE'
}

Write-Section 'RESULTADO'
Write-Output 'Inventario completado. Este script no ha cambiado el sistema.'
