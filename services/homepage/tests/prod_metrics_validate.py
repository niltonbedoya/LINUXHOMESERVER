#!/usr/bin/env python3
"""Valida las métricas de PROD desde el consumidor Homepage sin imprimir secretos."""
from __future__ import annotations
import json, subprocess, urllib.parse, urllib.request

def fail(message: str) -> None: raise SystemExit(f'ERROR: {message}')
def run(*args: str) -> str: return subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.strip()
probe = r'''
const base='http://servicio-tickets-definitivo.tailf553c4.ts.net:61208/api/4';
const user=process.env.HOMEPAGE_VAR_PROD_GLANCES_USERNAME||''; const password=process.env.HOMEPAGE_VAR_PROD_GLANCES_PASSWORD||'';
const authorization=`Basic ${Buffer.from(`${user}:${password}`).toString('base64')}`;
async function request(endpoint,auth){const response=await fetch(`${base}/${endpoint}`,{headers:auth?{Authorization:authorization}:{},signal:AbortSignal.timeout(10000)});const text=await response.text();let data=null;try{data=text?JSON.parse(text):null}catch(_){data=text}return {status:response.status,data}}
(async()=>{const result={credentials:{username:user==='homepage',password:/^[A-Za-z0-9_-]{43}$/.test(password)},unauth:{},auth:{},forbidden:{}};result.unauth.status=(await request('status',false)).status;result.unauth.cpu=(await request('cpu',false)).status;for(const endpoint of ['status','quicklook','system','cpu','mem','fs','uptime','pluginslist'])result.auth[endpoint]=await request(endpoint,true);for(const endpoint of ['processcount','processlist','programlist'])result.forbidden[endpoint]=(await request(endpoint,true)).status;console.log(JSON.stringify(result))})().catch(error=>{console.error(error.message);process.exit(1)})
'''
try: payload=json.loads(run('docker','exec','homepage','node','-e',probe))
except (subprocess.CalledProcessError,json.JSONDecodeError) as error: fail(f'la consulta PROD desde Homepage falló: {error}')
if payload['credentials'] != {'username': True, 'password': True}: fail('las credenciales PROD no están inyectadas')
if payload['unauth'] != {'status': 200, 'cpu': 401}: fail(f'respuesta anónima PROD inesperada: {payload["unauth"]}')
if any(response['status'] != 200 for response in payload['auth'].values()): fail('una API autenticada PROD no devolvió HTTP 200')
cpu=float(payload['auth']['cpu']['data']['total']); ram=int(payload['auth']['mem']['data']['total'])
if not 0 <= cpu <= 100: fail('CPU PROD fuera de rango')
if abs(ram-7_785_410_560)/7_785_410_560 > .05: fail('RAM PROD fuera de tolerancia')
root=[item for item in payload['auth']['fs']['data'] if item.get('mnt_point')=='/']
if len(root)!=1 or abs(int(root[0]['size'])-104_028_168_192)/104_028_168_192 > .02: fail('disco raíz PROD fuera de tolerancia')
if str(payload['auth']['system']['data'].get('hostname')) != 'tickets-utuntu-01': fail('hostname PROD inesperado')
plugins={item if isinstance(item,str) else item.get('plugin',item.get('name')) for item in payload['auth']['pluginslist']['data']}; plugins.discard(None)
if plugins != {'quicklook','system','cpu','mem','fs','uptime'}: fail(f'allowlist PROD inesperada: {sorted(plugins)}')
if payload['forbidden'] != {'processcount':400,'processlist':400,'programlist':400}: fail('la privacidad de procesos PROD no se conserva')
with urllib.request.urlopen('http://127.0.0.1:3000/api/services',timeout=10) as response: groups=json.load(response)
def find(items,name):
    for item in items:
        if item.get('name')==name:return item
        found=find(item.get('groups',[]),name)
        if found:return found
group=find(groups,'HOME SERVER'); services=[] if group is None else [item for item in group.get('services',[]) if item.get('name')=='Servidor PROD']
if len(services)!=1: fail('Homepage no publicó exactamente una tarjeta PROD')
if '"username"' in json.dumps(services[0]).lower() or '"password"' in json.dumps(services[0]).lower(): fail('la API pública expone credenciales PROD')
query=urllib.parse.urlencode({'group':'HOME SERVER','service':'Servidor PROD','index':'0','endpoint':'4/quicklook'})
with urllib.request.urlopen(f'http://127.0.0.1:3000/api/services/proxy?{query}',timeout=10) as response: proxied=json.load(response)
if not 0 <= float(proxied['cpu']) <= 100 or not 0 <= float(proxied['mem']) <= 100: fail('el proxy del widget PROD devolvió valores inválidos')
print(f'PROD: API privada, métricas, privacidad y widget OK; CPU={cpu:.1f}%; RAM={ram}; disco={int(root[0]["size"])}')
