#!/usr/bin/env python3
"""Valida la estructura nativa de dos columnas de Homepage."""
from __future__ import annotations
import pathlib, sys, yaml
root = pathlib.Path(__file__).resolve().parents[1]
services = yaml.safe_load((root / 'config/services.yaml').read_text())
settings = yaml.safe_load((root / 'config/settings.yaml').read_text())
outer = {next(iter(g)): next(iter(g.values())) for g in services}
if set(outer) != {'IZQUIERDA','DERECHA'}: raise SystemExit('ERROR: faltan las dos columnas')
left = [next(iter(item)) for item in outer['IZQUIERDA']]
right = [next(iter(item)) for item in outer['DERECHA']]
if left != ['HOME SERVER','IDE Y EDITORES'] or right != ['LLM Y CHAT IA','AGENTES Y CLI','TERMINALES Y SHELLS','PLATAFORMAS IA']:
    raise SystemExit('ERROR: orden de columnas inesperado')
layout = settings['layout']
for column in ('IZQUIERDA','DERECHA'):
    if layout[column].get('header') is not False: raise SystemExit('ERROR: encabezado de columna visible')
for name in ('HOME SERVER','IDE Y EDITORES','LLM Y CHAT IA','AGENTES Y CLI','TERMINALES Y SHELLS','PLATAFORMAS IA'):
    parent = 'IZQUIERDA' if name in ('HOME SERVER','IDE Y EDITORES') else 'DERECHA'
    if layout[parent][name].get('columns') != 4: raise SystemExit(f'ERROR: {name} no usa 4 columnas')
home = outer['IZQUIERDA'][0]['HOME SERVER']
home_names = [next(iter(card)) for card in home]
if home_names[:8] != ['Nilton PC','Servidor DEV','Servidor PROD','Tickets PROD','n8n','Uptime Kuma','OpenClaw','Tailscale']:
    raise SystemExit('ERROR: HOME SERVER no prioriza equipos y servicios')
for name, card_id in (('GitHub', 'github'), ('GitHub Copilot', 'github-copilot')):
    card = next(card[name] for card in home if name in card)
    if card.get('id') != card_id: raise SystemExit(f'ERROR: {name} no conserva su id visual')
for group in outer.values():
    for nested in group:
        for card in next(iter(nested.values())):
            for name, data in card.items():
                if not data.get('description') or ' ' in data['description'].strip(): raise SystemExit(f'ERROR: descripción inválida: {name}')
expected_pings = {
    'Nilton PC': 'nilton-pc.tailf553c4.ts.net',
    'Servidor DEV': 'tickets-server-dev.tailf553c4.ts.net',
    'Servidor PROD': 'servicio-tickets-definitivo.tailf553c4.ts.net',
}
for name, expected_ping in expected_pings.items():
    card = next(card[name] for card in outer['IZQUIERDA'][0]['HOME SERVER'] if name in card)
    if card.get('ping') != expected_ping: raise SystemExit(f'ERROR: {name} no tiene su ping privado')
    if not card.get('id'): raise SystemExit(f'ERROR: {name} no tiene selector visual estable')
print('Diseño de dos columnas: OK')
