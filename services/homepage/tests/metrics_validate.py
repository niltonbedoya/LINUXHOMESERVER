#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys
import time


def fail(message):
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def command(*args):
    return subprocess.run(
        args,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout.strip()


if command("docker", "inspect", "homepage-glances", "--format", "{{.State.Status}}") != "running":
    fail("Glances no está en ejecución")

if command("docker", "port", "homepage-glances"):
    fail("Glances publica un puerto en el host")

mounts = json.loads(command("docker", "inspect", "homepage-glances", "--format", "{{json .Mounts}}"))
if any(mount["Destination"] == "/var/run/docker.sock" for mount in mounts):
    fail("Glances tiene acceso al socket Docker")
if any(mount["RW"] for mount in mounts):
    fail("Glances tiene un montaje de host con escritura")

fetch_script = r"""
const plugins = ["cpu", "mem", "fs", "uptime", "sensors"];
Promise.all(plugins.map(async plugin => {
  const response = await fetch(`http://glances:61208/api/4/${plugin}`);
  if (!response.ok) throw new Error(`${plugin}: HTTP ${response.status}`);
  return [plugin, await response.json()];
})).then(entries => console.log(JSON.stringify(Object.fromEntries(entries))));
"""

payload = None
last_error = None
for _ in range(20):
    try:
        raw_payload = command("docker", "exec", "homepage", "node", "-e", fetch_script)
        payload = json.loads(raw_payload)
        break
    except (subprocess.CalledProcessError, json.JSONDecodeError) as error:
        last_error = error
        time.sleep(1)
if payload is None:
    fail(f"La API interna de Glances no respondió: {last_error}")

cpu_total = float(payload["cpu"]["total"])
if not 0 <= cpu_total <= 100:
    fail(f"CPU fuera de rango: {cpu_total}")

with open("/proc/meminfo", encoding="utf-8") as meminfo_file:
    meminfo = meminfo_file.read()
host_mem = int(re.search(r"^MemTotal:\s+(\d+) kB$", meminfo, re.MULTILINE).group(1)) * 1024
glances_mem = int(payload["mem"]["total"])
mem_delta = abs(glances_mem - host_mem) / host_mem
if mem_delta > 0.05:
    fail(f"RAM de Glances difiere {mem_delta:.1%} del host")

host_stat = os.statvfs("/home/bedvil/server")
host_disk = host_stat.f_blocks * host_stat.f_frsize
filesystem = next((item for item in payload["fs"] if item.get("mnt_point") == "/hostfs"), None)
if filesystem is None:
    fail("Glances no expone el montaje /hostfs")
glances_disk = int(filesystem["size"])
disk_delta = abs(glances_disk - host_disk) / host_disk
if disk_delta > 0.02:
    fail(f"Disco de Glances difiere {disk_delta:.1%} del host")

if not payload["uptime"]:
    fail("Glances no devuelve uptime")

def host_package_temperature():
    try:
        sensors_output = command("sensors")
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None
    match = re.search(
        r"^Package id 0:\s*\+?(-?\d+(?:\.\d+)?)",
        sensors_output,
        re.MULTILINE,
    )
    return float(match.group(1)) if match else None


def package_temperature(sensors_payload):
    for sensor in sensors_payload:
        if str(sensor.get("label", "")).startswith("Package id"):
            return float(sensor["value"])
    return None


sensor_fetch_script = r"""
fetch('http://glances:61208/api/4/sensors')
  .then(response => {
    if (!response.ok) throw new Error(`sensors: HTTP ${response.status}`);
    return response.json();
  })
  .then(value => console.log(JSON.stringify(value)));
"""

temperature_samples = []
glances_sensors = payload["sensors"]
for attempt in range(6):
    host_temperature = host_package_temperature()
    glances_temperature = package_temperature(glances_sensors)
    temperature_samples.append((glances_temperature, host_temperature))
    if host_temperature is None:
        fail("sensors no devuelve Package id 0 en el host")
    if glances_temperature is None:
        fail("Glances no devuelve un sensor Package id")
    if abs(host_temperature - glances_temperature) <= 5:
        break
    if attempt < 5:
        time.sleep(1)
        glances_sensors = json.loads(
            command("docker", "exec", "homepage", "node", "-e", sensor_fetch_script)
        )
else:
    samples = ", ".join(
        f"Glances={glances:.1f}/host={host:.1f}"
        for glances, host in temperature_samples
    )
    fail(f"Temperatura fuera de tolerancia durante seis muestras: {samples}")

print(f"Temperatura fiable: {glances_temperature:.1f} °C")

print(f"CPU válida: {cpu_total:.1f} %")
print(f"RAM total válida: {glances_mem} bytes")
print(f"Disco /hostfs válido: {glances_disk} bytes")
print("Pruebas de métricas: OK")
