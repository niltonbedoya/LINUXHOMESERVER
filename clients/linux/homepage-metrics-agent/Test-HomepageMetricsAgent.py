#!/usr/bin/env python3
"""Root-only verification of the isolated DEV Homepage metrics agent."""

from __future__ import annotations

import base64
import json
import os
import pathlib
import subprocess
import sys
import time
import urllib.error
import urllib.request


TAILSCALE_IP = "100.80.93.74"
MAC_MINI_IP = "100.72.206.57"
PORT = 61208
USERNAME = "homepage"
VERSION = "4.5.6"
CHAIN = "HOMEPAGE_METRICS_AGENT"
SECRET_PATH = pathlib.Path("/home/nilton/.local/share/homepage-metrics-agent/secret")


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def command(*args: str) -> str:
    result = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        fail(f"comando falló ({' '.join(args)}): {result.stderr.strip()}")
    return result.stdout.strip()


def status(url: str, headers: dict[str, str] | None = None) -> int:
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers or {}), timeout=10) as response:
            response.read()
            return response.status
    except urllib.error.HTTPError as error:
        return error.code


def api(path: str, headers: dict[str, str]) -> object:
    request = urllib.request.Request(f"http://{TAILSCALE_IP}:{PORT}/api/4/{path}", headers=headers)
    with urllib.request.urlopen(request, timeout=10) as response:
        if response.status != 200:
            fail(f"API {path} devolvió HTTP {response.status}")
        return json.load(response)


if os.geteuid() != 0:
    fail("ejecuta esta prueba mediante sudo")

if command("systemctl", "is-active", "homepage-metrics-agent.service") != "active":
    fail("el servicio de métricas no está activo")
if command("systemctl", "is-active", "homepage-metrics-agent-firewall.service") != "active":
    fail("el servicio de firewall no está activo")

listeners = command("ss", "-ltnH")
expected_listener = f"{TAILSCALE_IP}:{PORT}"
matching = [line for line in listeners.splitlines() if f":{PORT}" in line]
if len(matching) != 1 or expected_listener not in matching[0]:
    fail(f"listener inesperado para {PORT}: {matching}")

command("iptables", "-C", "INPUT", "-i", "tailscale0", "-p", "tcp", "--dport", str(PORT), "-j", CHAIN)
chain_rules = command("iptables", "-S", CHAIN)
chain_rules = "\n".join(line for line in chain_rules.splitlines() if line.startswith(f"-A {CHAIN} "))
expected_rules = (
    f"-A {CHAIN} -s {MAC_MINI_IP}/32 -p tcp -m tcp --dport {PORT} -j ACCEPT",
    f"-A {CHAIN} -p tcp -m tcp --dport {PORT} -j DROP",
)
if tuple(chain_rules.splitlines()) != expected_rules:
    fail("la cadena de firewall no limita exactamente Mac mini y el resto de tailnet")

base = f"http://{TAILSCALE_IP}:{PORT}/api/4"
if status(f"{base}/status") != 200:
    fail("status no respondió HTTP 200")
if status(f"{base}/cpu") != 401:
    fail("CPU no rechaza peticiones anónimas")

secret = SECRET_PATH.read_text(encoding="ascii").strip()
if len(secret) != 43 or not all(char.isalnum() or char in "_-" for char in secret):
    fail("el secreto local no tiene el formato esperado")
authorization = base64.b64encode(f"{USERNAME}:{secret}".encode("utf-8")).decode("ascii")
headers = {"Authorization": f"Basic {authorization}"}
secret = ""

status_document = api("status", headers)
if str(status_document.get("version")) != VERSION:
    fail("la versión de Glances no coincide")
cpu = api("cpu", headers)
mem = api("mem", headers)
filesystem = api("fs", headers)
uptime = api("uptime", headers)
plugins_document = api("pluginslist", headers)
api("quicklook", headers)
api("system", headers)

cpu_total = float(cpu["total"])
if not 0 <= cpu_total <= 100:
    fail(f"CPU fuera de rango: {cpu_total}")
native_ram = int(next(line.split()[1] for line in pathlib.Path("/proc/meminfo").read_text().splitlines() if line.startswith("MemTotal:"))) * 1024
api_ram = int(mem["total"])
if abs(api_ram - native_ram) / native_ram > 0.05:
    fail("RAM fuera de tolerancia")
root_entries = [item for item in filesystem if item.get("mnt_point") == "/"]
if len(root_entries) != 1:
    fail("Glances no devolvió exactamente el filesystem raíz")
native_disk = os.statvfs("/").f_blocks * os.statvfs("/").f_frsize
api_disk = int(root_entries[0]["size"])
if abs(api_disk - native_disk) / native_disk > 0.02:
    fail("disco raíz fuera de tolerancia")
if not uptime:
    fail("uptime vacío")

plugins = {item if isinstance(item, str) else item.get("plugin", item.get("name")) for item in plugins_document}
plugins.discard(None)
expected_plugins = {"quicklook", "system", "cpu", "mem", "fs", "uptime"}
if plugins != expected_plugins:
    fail(f"allowlist inesperada: {sorted(plugins)}")
for endpoint in ("processcount", "processlist", "programlist"):
    if status(f"{base}/{endpoint}", headers) != 400:
        fail(f"{endpoint} no está bloqueado")

print(f"Pruebas DEV: OK; CPU={cpu_total:.1f}%; RAM={api_ram}; disco={api_disk}")
