#!/usr/bin/env python3
"""Valida que los accesos DEV retirados no reaparezcan en Homepage."""

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
    fail(f"faltan grupos requeridos: {sorted(required_groups - set(by_name))}")

if "🧪 DESARROLLO / DEV" in by_name:
    fail("el grupo DESARROLLO / DEV ya no debe mostrarse")

node = "tickets-server-dev.tailf553c4.ts.net"
home = {service.get("name"): service for service in by_name["HOME SERVER"]["services"]}
dev_service = home.get("Servidor DEV", {})
# Homepage oculta URL y credenciales en /api/services; el test estático comprueba
# MagicDNS y este test runtime comprueba el widget publicado sin exponer secretos.
if dev_service.get("widget"):
    if dev_service["widget"].get("url") != f"http://{node}:61208":
        fail("la tarjeta de métricas DEV no usa MagicDNS")
else:
    widgets = dev_service.get("widgets", [])
    if len(widgets) != 1 or widgets[0].get("type") != "glances" or widgets[0].get("metric") != "info":
        fail("la tarjeta de métricas DEV no publica el widget Glances compacto")
serialized = json.dumps(groups, ensure_ascii=False)
for forbidden in ("Servidor Ubuntu DEV", "Tickets DEV", "API DEV", f"http://{node}:5173", f"http://{node}:18000/docs"):
    if forbidden in serialized:
        fail(f"reapareció un acceso DEV retirado: {forbidden}")

print("Configuración runtime sin accesos DEV: OK")
