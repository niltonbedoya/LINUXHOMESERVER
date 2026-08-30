#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath))
    $process = Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    exit $process.ExitCode
}

$installRoot = Join-Path $env:ProgramData 'HomepageMetricsAgent'
$userStateRoot = Join-Path $env:LOCALAPPDATA 'HomepageMetricsAgent'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$task = Get-ScheduledTask -TaskName 'HomepageMetricsAgent' -ErrorAction SilentlyContinue
if ($task) {
    Stop-ScheduledTask -TaskName 'HomepageMetricsAgent' -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName 'HomepageMetricsAgent' -Confirm:$false
}
Get-NetFirewallRule -DisplayName 'Homepage Metrics Agent - Tailscale' -ErrorAction SilentlyContinue |
    Remove-NetFirewallRule -ErrorAction SilentlyContinue

if (Test-Path -LiteralPath $installRoot) {
    $removedRoot = Join-Path $env:ProgramData ("HomepageMetricsAgent-removed-$timestamp")
    Move-Item -LiteralPath $installRoot -Destination $removedRoot
    Write-Output "Archivos movidos de forma recuperable a $removedRoot"
}
if (Test-Path -LiteralPath $userStateRoot) {
    $removedState = "$userStateRoot-removed-$timestamp"
    Move-Item -LiteralPath $userStateRoot -Destination $removedState
    Write-Output "Secreto DPAPI movido de forma recuperable a $removedState"
}

Write-Output 'Homepage Metrics Agent deshabilitado y retirado. No se ha borrado su backup recuperable.'
