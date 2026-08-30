#!/usr/bin/env python3
"""Valida Nilton PC desde el consumidor real sin mostrar sus credenciales."""

from __future__ import annotations

import json
import subprocess
import sys
import urllib.parse
import urllib.request


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def command(*args: str) -> str:
    return subprocess.run(
        args,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout.strip()


node_probe = r"""
const base = 'http://nilton-pc.tailf553c4.ts.net:61208/api/4';
const username = process.env.HOMEPAGE_VAR_NILTON_PC_GLANCES_USERNAME || '';
const password = process.env.HOMEPAGE_VAR_NILTON_PC_GLANCES_PASSWORD || '';
const authorization = `Basic ${Buffer.from(`${username}:${password}`).toString('base64')}`;

async function request(endpoint, authenticated) {
  const response = await fetch(`${base}/${endpoint}`, {
    headers: authenticated ? {Authorization: authorization} : {},
    signal: AbortSignal.timeout(10000),
  });
  const text = await response.text();
  let data = null;
  try { data = text ? JSON.parse(text) : null; } catch (_) { data = text; }
  return {status: response.status, data};
}

(async () => {
  const result = {
    credentials: {
      username: username === 'homepage',
      password: /^[A-Za-z0-9_-]{43}$/.test(password),
    },
    unauthenticated: {
      status: (await request('status', false)).status,
      cpu: (await request('cpu', false)).status,
    },
    authenticated: {},
    forbidden: {},
  };
  for (const endpoint of ['status', 'quicklook', 'system', 'cpu', 'mem', 'fs', 'uptime', 'pluginslist']) {
    result.authenticated[endpoint] = await request(endpoint, true);
  }
  for (const endpoint of ['processcount', 'processlist', 'programlist']) {
    result.forbidden[endpoint] = (await request(endpoint, true)).status;
  }
  console.log(JSON.stringify(result));
})().catch(error => {
  console.error(error.message);
  process.exit(1);
});
"""

try:
    payload = json.loads(command("docker", "exec", "homepage", "node", "-e", node_probe))
except (subprocess.CalledProcessError, json.JSONDecodeError) as error:
    fail(f"la consulta desde Homepage falló: {error}")

if payload["credentials"] != {"username": True, "password": True}:
    fail("las variables de credenciales no están inyectadas correctamente")
if payload["unauthenticated"] != {"status": 200, "cpu": 401}:
    fail(f"respuesta sin credenciales inesperada: {payload['unauthenticated']}")

authenticated = payload["authenticated"]
for endpoint, response in authenticated.items():
    if response["status"] != 200:
        fail(f"{endpoint} autenticado devolvió HTTP {response['status']}")

cpu_total = float(authenticated["cpu"]["data"]["total"])
if not 0 <= cpu_total <= 100:
    fail(f"CPU fuera de rango: {cpu_total}")

expected_ram = 16_840_433_664
observed_ram = int(authenticated["mem"]["data"]["total"])
if abs(observed_ram - expected_ram) / expected_ram > 0.05:
    fail(f"RAM remota fuera de tolerancia: {observed_ram}")

filesystems = authenticated["fs"]["data"]
system_disks = [item for item in filesystems if item.get("mnt_point") == "C:\\"]
if len(system_disks) != 1:
    fail(f"se esperó un filesystem C:\\ y se obtuvieron {len(system_disks)}")
expected_disk = 510_513_188_864
observed_disk = int(system_disks[0]["size"])
if abs(observed_disk - expected_disk) / expected_disk > 0.02:
    fail(f"disco remoto fuera de tolerancia: {observed_disk}")

system = authenticated["system"]["data"]
if str(system.get("hostname", "")).lower() != "nilton-pc":
    fail(f"hostname remoto inesperado: {system.get('hostname')!r}")
if not authenticated["uptime"]["data"]:
    fail("uptime remoto vacío")

plugin_data = authenticated["pluginslist"]["data"]
plugins = {
    item if isinstance(item, str) else item.get("plugin", item.get("name"))
    for item in plugin_data
}
plugins.discard(None)
expected_plugins = {"quicklook", "system", "cpu", "mem", "fs", "uptime"}
if plugins != expected_plugins:
    fail(f"allowlist remota inesperada: {sorted(plugins)}")
if payload["forbidden"] != {
    "processcount": 400,
    "processlist": 400,
    "programlist": 400,
}:
    fail(f"endpoints privados inesperados: {payload['forbidden']}")

try:
    with urllib.request.urlopen("http://127.0.0.1:3000/api/services", timeout=10) as response:
        groups = json.load(response)
except Exception as error:  # noqa: BLE001 - mensaje operativo compacto
    fail(f"no se pudo leer /api/services: {error}")

def find(items, name):
    for item in items:
        if item.get("name") == name: return item
        found = find(item.get("groups", []), name)
        if found: return found
group = find(groups, "HOME SERVER")
if group is None:
    fail("Homepage no publicó el grupo HOME SERVER")
services = [item for item in group.get("services", []) if item.get("name") == "Nilton PC"]
if len(services) != 1:
    fail(f"Homepage publicó {len(services)} tarjetas Nilton PC")
serialized_service = json.dumps(services[0], ensure_ascii=False).lower()
if '"username"' in serialized_service or '"password"' in serialized_service:
    fail("la API pública de servicios conservó campos de credenciales")

query = urllib.parse.urlencode(
    {"group": "HOME SERVER", "service": "Nilton PC", "index": "0", "endpoint": "4/quicklook"}
)
try:
    with urllib.request.urlopen(
        f"http://127.0.0.1:3000/api/services/proxy?{query}", timeout=10
    ) as response:
        proxied = json.load(response)
except Exception as error:  # noqa: BLE001 - mensaje operativo compacto
    fail(f"el proxy autenticado del widget falló: {error}")
if not 0 <= float(proxied["cpu"]) <= 100 or not 0 <= float(proxied["mem"]) <= 100:
    fail("el proxy del widget devolvió CPU o RAM fuera de rango")

print(
    "Nilton PC: API privada, métricas, privacidad y widget OK; "
    f"CPU={cpu_total:.1f}%; RAM={observed_ram}; disco={observed_disk}"
)
