#!/usr/bin/env python3
"""Static safety checks for the Linux DEV metrics-agent bundle."""

from __future__ import annotations

import pathlib
import py_compile
import re
import subprocess
import tempfile


root = pathlib.Path(__file__).resolve().parents[3]
bundle = root / "clients/linux/homepage-metrics-agent"
required = {
    "Install-HomepageMetricsAgent.sh",
    "Uninstall-HomepageMetricsAgent.sh",
    "Test-HomepageMetricsAgent.sh",
    "Test-HomepageMetricsAgent.py",
    "Write-GlancesPassword.py",
    "homepage-metrics-agent-firewall.sh",
    "README.md",
}
for name in required:
    path = bundle / name
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit(f"ERROR: falta el archivo Linux de métricas: {name}")

for name in required:
    if name.endswith(".sh"):
        subprocess.run(["bash", "-n", str(bundle / name)], check=True)
for name in ("Test-HomepageMetricsAgent.py", "Write-GlancesPassword.py"):
    with tempfile.TemporaryDirectory(prefix="homepage-linux-agent-") as temp_dir:
        py_compile.compile(str(bundle / name), cfile=str(pathlib.Path(temp_dir) / f"{name}c"), doraise=True)

installer = (bundle / "Install-HomepageMetricsAgent.sh").read_text(encoding="utf-8")
firewall = (bundle / "homepage-metrics-agent-firewall.sh").read_text(encoding="utf-8")
tester = (bundle / "Test-HomepageMetricsAgent.py").read_text(encoding="utf-8")
test_launcher = (bundle / "Test-HomepageMetricsAgent.sh").read_text(encoding="utf-8")
uninstaller = (bundle / "Uninstall-HomepageMetricsAgent.sh").read_text(encoding="utf-8")
combined = "\n".join((installer, firewall, tester, uninstaller))

for forbidden in ("sudo ", "0.0.0.0", "tailscale serve reset", "--enable-plugin all"):
    if forbidden in combined:
        raise SystemExit(f"ERROR: construcción prohibida: {forbidden}")

for marker in (
    "glances[web]==${GLANCES_VERSION}",
    "GLANCES_VERSION='4.5.6'",
    "TAILSCALE_IP='100.80.93.74'",
    "MAC_MINI_IP='100.72.206.57'",
    "User=homepage-metrics",
    "ProtectSystem=strict",
    "--disable-plugin all",
    "--enable-plugin quicklook,system,cpu,mem,fs,uptime",
    "-B ${TAILSCALE_IP}",
    "-p 61208",
    "-u ${USERNAME}",
    "Test-HomepageMetricsAgent.sh",
    "trap cleanup EXIT",
    "chmod 0755 \"${INSTALL_ROOT}\" \"${INSTALL_ROOT}/venv\" \"${INSTALL_ROOT}/venv/bin\"",
):
    if marker not in installer:
        raise SystemExit(f"ERROR: falta protección de instalación: {marker}")

for marker in (
    "-s \"${MAC_MINI_TAILSCALE_IP}/32\"",
    "-p tcp --dport \"${PORT}\" -j DROP",
    "-i \"${INTERFACE}\"",
    "iptables -I INPUT 1",
    "iptables -X \"${CHAIN}\"",
):
    if marker not in firewall:
        raise SystemExit(f"ERROR: falta protección de firewall: {marker}")

for marker in (
    "systemctl", "iptables", "CPU no rechaza", "pluginslist", "processcount",
    "processlist", "programlist", "RAM fuera de tolerancia", "disco raíz fuera de tolerancia",
    "line.startswith(f\"-A {CHAIN} \")",
):
    if marker not in tester:
        raise SystemExit(f"ERROR: falta prueba vital Linux: {marker}")
if re.search(r"print\([^\n]*(secret|authorization)", tester, re.IGNORECASE):
    raise SystemExit("ERROR: el test podría imprimir una credencial")
if "/app/Test-HomepageMetricsAgent.py" not in test_launcher:
    raise SystemExit("ERROR: el lanzador de pruebas Linux no apunta al archivo instalado")
if "removed-${timestamp}" not in uninstaller or "rm -rf" in uninstaller:
    raise SystemExit("ERROR: el rollback Linux no es recuperable")
if 'result="$?"' not in installer or 'return "${result}"' not in installer:
    raise SystemExit("ERROR: el instalador no protege el rollback ante exit explícito")

print("Agente Linux DEV de métricas: validación estática OK")
