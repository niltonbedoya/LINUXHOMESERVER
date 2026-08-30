#!/usr/bin/env python3
"""Valida la representación runtime de PRODUCCIÓN devuelta por Homepage."""

import json
import sys


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


try:
    groups = json.load(sys.stdin)
except (json.JSONDecodeError, TypeError) as exc:
    fail(f"respuesta /api/services no válida: {exc}")

if not isinstance(groups, list):
    fail("/api/services no devolvió una lista")

def flatten(items):
    return {group.get("name"): group for group in items for group in [group] + list(flatten(group.get("groups", [])).values())}
by_name = flatten(groups)
required_groups = {"HOME SERVER"}
if not required_groups.issubset(by_name):
    fail(f"faltan grupos anteriores: {sorted(required_groups - set(by_name))}")

home_names = [service.get("name") for service in by_name["HOME SERVER"]["services"]]
if home_names != ["Nilton PC", "Servidor DEV", "Servidor PROD", "Tickets PROD", "n8n", "Uptime Kuma", "OpenClaw", "Tailscale", "GitHub", "GitHub Copilot"]:
    fail(f"HOME SERVER cambió: {home_names}")

tickets = next((service for service in by_name["HOME SERVER"]["services"] if service.get("name") == "Tickets PROD"), None)
if tickets is None:
    fail("falta Tickets PROD en HOME SERVER")
expected_url = "https://service-ab-electronic.com/"
if tickets.get("href") != expected_url or tickets.get("siteMonitor") != expected_url:
    fail("Tickets PROD no usa el dominio singular verificado")

prod_serialized = json.dumps(tickets, ensure_ascii=False).lower()
if "service-ab-electronics.com" in prod_serialized:
    fail("aparece el dominio plural que no resuelve")
if "desarrollo" in prod_serialized or '"dev' in prod_serialized:
    fail("PRODUCCIÓN contiene referencias de DEV")

print("Configuración runtime de PRODUCCIÓN: OK")
