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

by_name = {group.get("name"): group for group in groups}
required_groups = {"🏠 HOME SERVER", "🚨 PRODUCCIÓN"}
if not required_groups.issubset(by_name):
    fail(f"faltan grupos anteriores: {sorted(required_groups - set(by_name))}")

home_names = [service.get("name") for service in by_name["🏠 HOME SERVER"]["services"]]
if home_names != ["n8n", "Uptime Kuma", "OpenClaw", "Tailscale"]:
    fail(f"HOME SERVER cambió: {home_names}")

prod_services = {
    service.get("name"): service for service in by_name["🚨 PRODUCCIÓN"]["services"]
}
if set(prod_services) != {"Servidor Ubuntu PROD", "Tickets PROD"}:
    fail(f"servicios PROD inesperados: {sorted(prod_services)}")

server = prod_services["Servidor Ubuntu PROD"]
if server.get("ping") != "servicio-tickets-definitivo.tailf553c4.ts.net":
    fail("el servidor PROD no usa el MagicDNS verificado")
if server.get("href"):
    fail("el servidor PROD no debe inventar una URL administrativa")

tickets = prod_services["Tickets PROD"]
expected_url = "https://service-ab-electronic.com/"
if tickets.get("href") != expected_url or tickets.get("siteMonitor") != expected_url:
    fail("Tickets PROD no usa el dominio singular verificado")

prod_serialized = json.dumps(by_name["🚨 PRODUCCIÓN"], ensure_ascii=False).lower()
if "service-ab-electronics.com" in prod_serialized:
    fail("aparece el dominio plural que no resuelve")
if "desarrollo" in prod_serialized or '"dev' in prod_serialized:
    fail("PRODUCCIÓN contiene referencias de DEV")

print("Configuración runtime de PRODUCCIÓN: OK")
