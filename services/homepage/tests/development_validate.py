#!/usr/bin/env python3
"""Valida que DEV sea exacto y permanezca separado de PRODUCCIÓN."""

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
required_groups = {"🏠 HOME SERVER", "🚨 PRODUCCIÓN", "🧪 DESARROLLO / DEV"}
if not required_groups.issubset(by_name):
    fail(f"faltan grupos anteriores: {sorted(required_groups - set(by_name))}")

dev_services = {
    service.get("name"): service
    for service in by_name["🧪 DESARROLLO / DEV"]["services"]
}
expected_services = {"Servidor Ubuntu DEV", "Tickets DEV", "API DEV"}
if set(dev_services) != expected_services:
    fail(f"servicios DEV inesperados: {sorted(dev_services)}")

node = "tickets-server-dev.tailf553c4.ts.net"
server = dev_services["Servidor Ubuntu DEV"]
if server.get("ping") != node or server.get("href"):
    fail("el servidor DEV no usa exclusivamente el MagicDNS verificado")

frontend_url = f"http://{node}:5173/"
tickets = dev_services["Tickets DEV"]
if tickets.get("href") != frontend_url or tickets.get("siteMonitor") != frontend_url:
    fail("Tickets DEV no usa el frontend 5173 verificado")

api = dev_services["API DEV"]
if api.get("href") != f"http://{node}:18000/docs":
    fail("API DEV no enlaza al Swagger verificado")
if api.get("siteMonitor") != f"http://{node}:18000/health":
    fail("API DEV no usa el healthcheck verificado")

dev_serialized = json.dumps(dev_services, ensure_ascii=False).lower()
for forbidden in ("service-ab-electronic.com", "servicio-tickets-definitivo", "100.113.199.93"):
    if forbidden in dev_serialized:
        fail(f"DEV reutiliza un destino PROD prohibido: {forbidden}")

print("Configuración runtime de DESARROLLO: OK")
