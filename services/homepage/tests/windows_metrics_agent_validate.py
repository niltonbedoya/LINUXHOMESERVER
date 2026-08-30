#!/usr/bin/env python3
"""Static safety checks for the Windows metrics agent bundle."""

from __future__ import annotations

import pathlib
import py_compile
import re
import tempfile


project_root = pathlib.Path(__file__).resolve().parents[3]
agent_root = project_root / "clients/windows/homepage-metrics-agent"

required = {
    "Get-HomepageMetricsInventory.ps1",
    "Install-HomepageMetricsAgent.ps1",
    "Start-HomepageMetricsAgent.ps1",
    "Test-HomepageMetricsAgent.ps1",
    "Copy-HomepageMetricsSecret.ps1",
    "Send-HomepageMetricsSecret.ps1",
    "Uninstall-HomepageMetricsAgent.ps1",
    "Write-GlancesPassword.py",
    "README.md",
}
for name in required:
    path = agent_root / name
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit(f"ERROR: falta el archivo Windows de métricas: {name}")

texts = {
    name: (agent_root / name).read_text(encoding="utf-8")
    for name in required
    if name.endswith(".ps1")
}
combined = "\n".join(texts.values())

for forbidden in ("Invoke-Expression", "iex ", "0.0.0.0", "tailscale serve reset"):
    if forbidden.lower() in combined.lower():
        raise SystemExit(f"ERROR: construcción prohibida en agente Windows: {forbidden}")

installer = texts["Install-HomepageMetricsAgent.ps1"]
starter = texts["Start-HomepageMetricsAgent.ps1"]
tester = texts["Test-HomepageMetricsAgent.ps1"]
uninstaller = texts["Uninstall-HomepageMetricsAgent.ps1"]
secret_export = texts["Copy-HomepageMetricsSecret.ps1"]
secret_sender = texts["Send-HomepageMetricsSecret.ps1"]

for marker in (
    "glances[web]==$glancesVersion",
    "$glancesVersion = '4.5.6'",
    "$ExpectedTailscaleIPv4 = '100.105.88.14'",
    "$MacMiniTailscaleIPv4 = '100.72.206.57'",
    "RemoteAddress = $MacMiniTailscaleIPv4",
    "LocalAddress = $ExpectedTailscaleIPv4",
    "secret.dpapi",
    "Write-GlancesPassword.py",
    "no se sobrescribira",
):
    if marker not in installer:
        raise SystemExit(f"ERROR: falta protección del instalador Windows: {marker}")

for flag in (
    "--disable-webui",
    "--disable-autodiscover",
    "--disable-process",
    "--disable-plugin all",
    "--enable-plugin quicklook,system,cpu,mem,fs,uptime",
    "--hide-public-info",
    "--disable-config-exec",
    "--disable-check-update",
    "-B $ExpectedTailscaleIPv4",
    "-u homepage",
):
    if flag not in starter:
        raise SystemExit(f"ERROR: falta flag seguro de Glances: {flag}")

for endpoint in ("/api/4/status", "/api/4/cpu", "/api/4/mem", "/api/4/fs", "/api/4/uptime", "/api/4/pluginslist"):
    if endpoint not in tester:
        raise SystemExit(f"ERROR: falta prueba vital del agente: {endpoint}")
for marker in (
    "Get-NetTCPConnection",
    "Get-NetFirewallAddressFilter",
    "-le 0.05",
    "-le 0.02",
    "-le 60",
    "$cpuResponse.Count -eq 1",
    "$memResponse.Count -eq 1",
    "$uptimeResponse.Count -eq 1",
    "[Convert]::ToDouble",
    "foreach ($fsItem in $fsDocument)",
    "$expectedMountPoint = $systemDrive + '\\'",
    "$systemFilesystems.Count -eq 1",
    "foreach ($pluginItem in $pluginsDocument)",
    "@('processcount', 'processlist', 'programlist')",
    "$forbiddenStatus -eq 400",
):
    if marker not in tester:
        raise SystemExit(f"ERROR: falta validación del agente: {marker}")

if "Set-Clipboard" not in secret_export or "Write-Output $plainPassword" in secret_export:
    raise SystemExit("ERROR: la exportación del secreto no está controlada")
for marker in (
    "RedirectStandardInput = $true",
    "StandardInput.WriteLine($plainPassword)",
    "ZeroFreeBSTR($pointer)",
    "Set-Clipboard -Value ' '",
    "set-nilton-pc-metrics-secret.sh",
):
    if marker not in secret_sender:
        raise SystemExit(f"ERROR: falta protección del envío SSH: {marker}")
for forbidden in ("Write-Output $plainPassword", "Arguments = $plainPassword"):
    if forbidden in secret_sender:
        raise SystemExit(f"ERROR: el envío podría exponer el secreto: {forbidden}")
for name in ("Test-HomepageMetricsAgent.ps1", "Copy-HomepageMetricsSecret.ps1"):
    if ").Trim()" not in texts[name]:
        raise SystemExit(f"ERROR: {name} no elimina el salto final del secreto DPAPI")

for marker in ("Unregister-ScheduledTask", "Remove-NetFirewallRule", "HomepageMetricsAgent-removed-"):
    if marker not in uninstaller:
        raise SystemExit(f"ERROR: rollback incompleto: {marker}")
if re.search(r"Remove-Item\s+[^\r\n]*HomepageMetricsAgent", uninstaller, re.IGNORECASE):
    raise SystemExit("ERROR: el desinstalador debe mover, no borrar, los datos")

password_helper = agent_root / "Write-GlancesPassword.py"
with tempfile.TemporaryDirectory(prefix="homepage-metrics-pycompile-") as temp_dir:
    py_compile.compile(
        str(password_helper),
        cfile=str(pathlib.Path(temp_dir) / "Write-GlancesPassword.pyc"),
        doraise=True,
    )
helper_text = password_helper.read_text(encoding="utf-8")
if "sys.stdin.read()" not in helper_text or "hash_password" not in helper_text:
    raise SystemExit("ERROR: el helper no recibe por stdin y almacena un hash")

print("Agente Windows de métricas: validación estática OK")
