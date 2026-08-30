[CmdletBinding()]
param(
    [string]$InstallRoot = 'C:\ProgramData\HomepageMetricsAgent',
    [string]$UserStateRoot = (Join-Path $env:LOCALAPPDATA 'HomepageMetricsAgent')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

function Get-PlainText {
    param([Parameter(Mandatory = $true)][Security.SecureString]$SecureValue)
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function Invoke-AgentApi {
    param(
        [Parameter(Mandatory = $true)][string]$BaseUri,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Authorization
    )
    return Invoke-RestMethod -UseBasicParsing -TimeoutSec 10 -Uri ($BaseUri + $Path) -Headers @{ Authorization = $Authorization }
}

function Get-AgentHttpStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Authorization
    )
    try {
        $response = Invoke-WebRequest -UseBasicParsing -TimeoutSec 10 -Uri $Uri -Headers @{ Authorization = $Authorization }
        return [int]$response.StatusCode
    } catch {
        if ($_.Exception.Response) {
            return [int]$_.Exception.Response.StatusCode
        }
        throw
    }
}

function Convert-UptimeToSeconds {
    param([Parameter(Mandatory = $true)][string]$Value)
    $days = 0
    $clock = $Value.Trim()
    if ($clock -match '^(\d+) day(?:s)?,\s*(.+)$') {
        $days = [int64]$Matches[1]
        $clock = $Matches[2]
    }
    return [int64]($days * 86400 + [TimeSpan]::Parse($clock).TotalSeconds)
}

$metadataPath = Join-Path $InstallRoot 'agent.json'
$secretPath = Join-Path $UserStateRoot 'secret.dpapi'
Assert-True (Test-Path -LiteralPath $metadataPath -PathType Leaf) "Falta $metadataPath"
Assert-True (Test-Path -LiteralPath $secretPath -PathType Leaf) "Falta $secretPath"

$metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
$tailIp = [string]$metadata.tailscale_ipv4
$macIp = [string]$metadata.macmini_tailscale_ipv4
$username = [string]$metadata.username
$baseUri = "http://${tailIp}:61208"

$task = Get-ScheduledTask -TaskName 'HomepageMetricsAgent' -ErrorAction SilentlyContinue
Assert-True ($null -ne $task) 'No existe la tarea HomepageMetricsAgent.'
Assert-True ($task.State -eq 'Running') "La tarea no esta ejecutandose: $($task.State)"
$taskAction = @($task.Actions)[0]
$startScriptPath = Join-Path $InstallRoot 'Start-HomepageMetricsAgent.ps1'
Assert-True ([string]$taskAction.Arguments -match 'Start-HomepageMetricsAgent[.]ps1') 'La tarea no usa el lanzador controlado.'
$startScript = Get-Content -LiteralPath $startScriptPath -Raw
Assert-True ($startScript -match '--disable-process') 'El lanzador no deshabilita procesos.'
Assert-True ($startScript -match '--disable-plugin all') 'El lanzador no usa allowlist de plugins.'
Assert-True ($startScript -match '--enable-plugin quicklook,system,cpu,mem,fs,uptime') 'El lanzador no fija los plugins permitidos.'
Assert-True ($startScript -match '--disable-webui') 'El lanzador no deshabilita la WebUI.'
Assert-True ($startScript -match '--disable-autodiscover') 'El lanzador no deshabilita autodiscovery.'

$listeners = @(Get-NetTCPConnection -State Listen -LocalPort 61208 -ErrorAction SilentlyContinue)
Assert-True ($listeners.Count -eq 1) "Se esperaba un listener 61208 y hay $($listeners.Count)."
Assert-True ($listeners[0].LocalAddress -eq $tailIp) "61208 escucha en $($listeners[0].LocalAddress), no solo en $tailIp."

$firewall = Get-NetFirewallRule -DisplayName 'Homepage Metrics Agent - Tailscale' -ErrorAction SilentlyContinue
Assert-True ($null -ne $firewall) 'No existe la regla de firewall dedicada.'
Assert-True (($firewall.Enabled -contains 'True') -or ($firewall.Enabled -contains $true)) 'La regla de firewall no esta activa.'
$addressFilter = $firewall | Get-NetFirewallAddressFilter
Assert-True (@($addressFilter.LocalAddress) -contains $tailIp) 'El firewall no limita la IP local de Tailscale.'
Assert-True (@($addressFilter.RemoteAddress) -contains $macIp) 'El firewall no limita el origen al Mac mini.'

# /status es intencionadamente publico en Glances y solo revela la version.
$status = Invoke-RestMethod -UseBasicParsing -TimeoutSec 10 -Uri ($baseUri + '/api/4/status')
Assert-True ([string]$status.version -eq [string]$metadata.glances_version) 'La version API no coincide con la fijada.'

$unauthorized = $false
try {
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 10 -Uri ($baseUri + '/api/4/cpu') | Out-Null
} catch {
    if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 401) {
        $unauthorized = $true
    } else {
        throw
    }
}
Assert-True $unauthorized 'La API CPU acepto una consulta sin autenticacion.'

$encryptedSecret = (Get-Content -LiteralPath $secretPath -Raw).Trim()
$securePassword = ConvertTo-SecureString $encryptedSecret
$plainPassword = Get-PlainText $securePassword
try {
    $pair = "${username}:${plainPassword}"
    $authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))

    $cpuResponse = @(Invoke-AgentApi $baseUri '/api/4/cpu' $authorization)
    $memResponse = @(Invoke-AgentApi $baseUri '/api/4/mem' $authorization)
    $fsDocument = Invoke-AgentApi $baseUri '/api/4/fs' $authorization
    $fs = @()
    foreach ($fsItem in $fsDocument) {
        $fs += $fsItem
    }
    $uptimeResponse = @(Invoke-AgentApi $baseUri '/api/4/uptime' $authorization)

    Assert-True ($cpuResponse.Count -eq 1) "CPU devolvio $($cpuResponse.Count) objetos."
    Assert-True ($memResponse.Count -eq 1) "RAM devolvio $($memResponse.Count) objetos."
    Assert-True ($uptimeResponse.Count -eq 1) "Uptime devolvio $($uptimeResponse.Count) objetos."
    $cpu = $cpuResponse[0]
    $mem = $memResponse[0]
    $uptime = [string]$uptimeResponse[0]

    $cpuValues = @($cpu.total)
    Assert-True ($cpuValues.Count -eq 1) "CPU.total devolvio $($cpuValues.Count) valores."
    $cpuTotal = [Convert]::ToDouble($cpuValues[0], [Globalization.CultureInfo]::InvariantCulture)
    Assert-True ($cpuTotal -ge 0 -and $cpuTotal -le 100) "CPU fuera de rango: $cpuTotal"

    $computerSystems = @(Get-CimInstance Win32_ComputerSystem)
    Assert-True ($computerSystems.Count -eq 1) "Win32_ComputerSystem devolvio $($computerSystems.Count) objetos."
    $nativeRam = [Convert]::ToDouble($computerSystems[0].TotalPhysicalMemory, [Globalization.CultureInfo]::InvariantCulture)
    $memTotals = @($mem.total)
    Assert-True ($memTotals.Count -eq 1) "RAM.total devolvio $($memTotals.Count) valores."
    $apiRam = [Convert]::ToDouble($memTotals[0], [Globalization.CultureInfo]::InvariantCulture)
    $ramDifference = [Math]::Abs($apiRam - $nativeRam) / $nativeRam
    Assert-True ($ramDifference -le 0.05) ("RAM difiere {0:P2}." -f $ramDifference)

    $systemDrive = $env:SystemDrive
    $nativeDisks = @(Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $systemDrive))
    Assert-True ($nativeDisks.Count -eq 1) "Win32_LogicalDisk devolvio $($nativeDisks.Count) objetos para $systemDrive."
    $nativeDisk = [Convert]::ToDouble($nativeDisks[0].Size, [Globalization.CultureInfo]::InvariantCulture)
    $expectedMountPoint = $systemDrive + '\'
    $systemFilesystems = @($fs | Where-Object { [string]$_.mnt_point -ieq $expectedMountPoint })
    Assert-True ($systemFilesystems.Count -eq 1) "Glances devolvio $($systemFilesystems.Count) entradas para $expectedMountPoint."
    $apiDisk = $systemFilesystems[0]
    $apiDiskSizes = @($apiDisk.size)
    Assert-True ($apiDiskSizes.Count -eq 1) "Filesystem.size devolvio $($apiDiskSizes.Count) valores."
    $apiDiskSize = [Convert]::ToDouble($apiDiskSizes[0], [Globalization.CultureInfo]::InvariantCulture)
    $diskDifference = [Math]::Abs($apiDiskSize - $nativeDisk) / $nativeDisk
    Assert-True ($diskDifference -le 0.02) ("Disco difiere {0:P2}." -f $diskDifference)

    $nativeUptime = ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalSeconds
    $apiUptime = Convert-UptimeToSeconds $uptime
    $uptimeDifference = [Math]::Abs($apiUptime - $nativeUptime)
    Assert-True ($uptimeDifference -le 60) "Uptime difiere $([int]$uptimeDifference) segundos."

    $pluginsDocument = Invoke-AgentApi $baseUri '/api/4/pluginslist' $authorization
    $plugins = @()
    foreach ($pluginItem in $pluginsDocument) {
        $plugins += [string]$pluginItem
    }
    foreach ($requiredPlugin in @('quicklook', 'system', 'cpu', 'mem', 'fs', 'uptime')) {
        Assert-True ($plugins -contains $requiredPlugin) "Falta el plugin permitido $requiredPlugin."
    }
    foreach ($forbiddenPlugin in @('processcount', 'processlist', 'programlist')) {
        Assert-True (-not ($plugins -contains $forbiddenPlugin)) "El plugin prohibido $forbiddenPlugin sigue cargado."
        $forbiddenStatus = Get-AgentHttpStatus ($baseUri + '/api/4/' + $forbiddenPlugin) $authorization
        Assert-True ($forbiddenStatus -eq 400) "La API $forbiddenPlugin devolvio HTTP $forbiddenStatus en vez de 400."
    }
} finally {
    $plainPassword = $null
    $encryptedSecret = $null
}

Write-Output ("Pruebas del agente: OK; CPU={0:N1}%; RAM={1}; disco={2}; uptime_delta={3}s" -f $cpuTotal, [uint64]$apiRam, [uint64]$apiDiskSize, [int]$uptimeDifference)
