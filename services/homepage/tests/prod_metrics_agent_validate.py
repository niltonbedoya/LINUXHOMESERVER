#!/usr/bin/env python3
"""Valida que el paquete de métricas PROD sea específico y conservador."""
from __future__ import annotations
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[3] / 'clients/linux/homepage-metrics-agent-prod'
required = {'Install-HomepageMetricsAgentProd.sh','Uninstall-HomepageMetricsAgentProd.sh','Test-HomepageMetricsAgentProd.sh','Test-HomepageMetricsAgentProd.py','Write-GlancesPassword.py','homepage-metrics-agent-prod-firewall.sh','README.md'}
actual = {entry.name for entry in root.iterdir() if entry.is_file()} if root.is_dir() else set()
if actual != required: raise SystemExit(f'ERROR: paquete PROD inesperado: {sorted(actual)}')
text = '\n'.join(path.read_text(encoding='utf-8') for path in root.iterdir() if path.is_file())
for expected in ('100.113.199.93','100.72.206.57','servicio-tickets-definitivo.tailf553c4.ts.net','/home/ab/','HOMEPAGE_METRICS_AGENT_PROD','import ensurepip','glances[web]==${VERSION}','--disable-process','--disable-autodiscover','-B ${TAILSCALE_IP}','-p 61208'):
    if expected not in text: raise SystemExit(f'ERROR: falta control PROD: {expected}')
for forbidden in ('100.80.93.74','tickets-server-dev','/home/nilton/','HOMEPAGE_METRICS_AGENT\'\n'):
    if forbidden in text: raise SystemExit(f'ERROR: fuga DEV detectada: {forbidden}')
if re.search(r'(^|\n)\s*(curl|wget).*http', text): raise SystemExit('ERROR: el paquete no debe descargar ejecutables arbitrarios')
print('Agente Linux PROD de métricas: validación estática OK')
