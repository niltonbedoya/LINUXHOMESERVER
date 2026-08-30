#!/usr/bin/env python3
"""Prueba root-only del agente de métricas aislado de PROD."""
from __future__ import annotations
import base64, json, os, pathlib, subprocess, urllib.error, urllib.request
IP='100.113.199.93'; MAC='100.72.206.57'; PORT=61208; USER='homepage'; VERSION='4.5.6'; CHAIN='HOMEPAGE_METRICS_AGENT_PROD'; SECRET=pathlib.Path('/home/ab/.local/share/homepage-metrics-agent-prod/secret')
def fail(message): raise SystemExit(f'ERROR: {message}')
def cmd(*args):
    output=subprocess.run(args,text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    if output.returncode: fail(f"comando falló ({' '.join(args)}): {output.stderr.strip()}")
    return output.stdout.strip()
def status(url, headers=None):
    try:
        with urllib.request.urlopen(urllib.request.Request(url,headers=headers or {}),timeout=10) as response: response.read(); return response.status
    except urllib.error.HTTPError as error: return error.code
def api(path, headers):
    with urllib.request.urlopen(urllib.request.Request(f'http://{IP}:{PORT}/api/4/{path}',headers=headers),timeout=10) as response:
        if response.status != 200: fail(f'API {path} devolvió HTTP {response.status}')
        return json.load(response)
if os.geteuid()!=0: fail('ejecuta esta prueba mediante sudo')
if cmd('systemctl','is-active','homepage-metrics-agent-prod.service')!='active': fail('el agente PROD no está activo')
if cmd('systemctl','is-active','homepage-metrics-agent-prod-firewall.service')!='active': fail('el firewall PROD no está activo')
listeners=[line for line in cmd('ss','-ltnH').splitlines() if f':{PORT}' in line]
if len(listeners)!=1 or f'{IP}:{PORT}' not in listeners[0]: fail(f'listener inesperado: {listeners}')
cmd('iptables','-C','INPUT','-i','tailscale0','-p','tcp','--dport',str(PORT),'-j',CHAIN)
rules='\n'.join(line for line in cmd('iptables','-S',CHAIN).splitlines() if line.startswith(f'-A {CHAIN} '))
expected=f'-A {CHAIN} -s {MAC}/32 -p tcp -m tcp --dport {PORT} -j ACCEPT\n-A {CHAIN} -p tcp -m tcp --dport {PORT} -j DROP'
if rules!=expected: fail('firewall no limita exactamente Mac mini y resto de tailnet')
base=f'http://{IP}:{PORT}/api/4'
if status(f'{base}/status')!=200 or status(f'{base}/cpu')!=401: fail('autenticación anónima inesperada')
secret=SECRET.read_text(encoding='ascii').strip()
if len(secret)!=43 or not all(c.isalnum() or c in '_-' for c in secret): fail('secreto local inválido')
headers={'Authorization':'Basic '+base64.b64encode(f'{USER}:{secret}'.encode()).decode()}; secret=''
status_doc=api('status',headers); cpu=api('cpu',headers); mem=api('mem',headers); fs=api('fs',headers); uptime=api('uptime',headers); plugins=api('pluginslist',headers); api('quicklook',headers); api('system',headers)
if str(status_doc.get('version'))!=VERSION: fail('versión Glances inesperada')
if not 0<=float(cpu['total'])<=100: fail('CPU fuera de rango')
native_ram=int(next(line.split()[1] for line in pathlib.Path('/proc/meminfo').read_text().splitlines() if line.startswith('MemTotal:')))*1024
if abs(int(mem['total'])-native_ram)/native_ram>.05: fail('RAM fuera de tolerancia')
root=[item for item in fs if item.get('mnt_point')=='/']
native_disk=os.statvfs('/').f_blocks*os.statvfs('/').f_frsize
if len(root)!=1 or abs(int(root[0]['size'])-native_disk)/native_disk>.02: fail('disco raíz fuera de tolerancia')
if not uptime: fail('uptime vacío')
enabled={item if isinstance(item,str) else item.get('plugin',item.get('name')) for item in plugins}; enabled.discard(None)
if enabled!={'quicklook','system','cpu','mem','fs','uptime'}: fail(f'allowlist inesperada: {sorted(enabled)}')
if any(status(f'{base}/{endpoint}',headers)!=400 for endpoint in ('processcount','processlist','programlist')): fail('procesos no están bloqueados')
print(f'Pruebas PROD: OK; CPU={float(cpu["total"]):.1f}%; RAM={int(mem["total"])}; disco={int(root[0]["size"])}')
