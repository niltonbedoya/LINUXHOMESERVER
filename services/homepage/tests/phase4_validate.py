#!/usr/bin/env python3
"""Valida la clasificación y los destinos de IA, IDE, CLI y administración."""

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
expected_groups = {
    "IZQUIERDA", "DERECHA", "HOME SERVER", "LLM Y CHAT IA", "IDE Y EDITORES", "AGENTES Y CLI", "TERMINALES Y SHELLS", "PLATAFORMAS IA",
}
if set(by_name) != expected_groups:
    fail(f"grupos inesperados: {sorted(by_name)}")

expected_links = {
    "LLM Y CHAT IA": {
        "ChatGPT": "https://chatgpt.com/",
        "Gemini": "https://gemini.google.com/",
        "Claude": "https://claude.ai/",
        "Perplexity": "https://www.perplexity.ai/",
        "Grok": "https://grok.com/",
        "Microsoft Copilot": "https://copilot.microsoft.com/",
        "Mistral Vibe": "https://chat.mistral.ai/",
    },
    "IDE Y EDITORES": {
        "Visual Studio Code": "homeserver-launch://vscode",
        "Cursor": "homeserver-launch://cursor",
        "Antigravity": "homeserver-launch://antigravity",
        "Zed": "homeserver-launch://zed",
        "Visual Studio Community": "homeserver-launch://visual-studio",
        "JetBrains IDEs": "homeserver-launch://jetbrains",
    },
    "AGENTES Y CLI": {
        "Hermes Desktop": "homeserver-launch://hermes",
        "Codex CLI": "homeserver-launch://codex",
        "OpenCode": "homeserver-launch://opencode",
        "Aider": "homeserver-launch://aider",
    },
    "TERMINALES Y SHELLS": {
        "Warp": "homeserver-launch://warp",
        "PowerShell": "homeserver-launch://powershell",
        "WSL": "homeserver-launch://wsl",
    },
    "PLATAFORMAS IA": {
        "Google AI Studio": "https://aistudio.google.com/",
        "NVIDIA Build": "https://build.nvidia.com/",
        "Azure Dashboard": "https://portal.azure.com/",
    },
}

for group_name, expected in expected_links.items():
    services = {
        service.get("name"): service for service in by_name[group_name]["services"]
    }
    if set(services) != set(expected):
        fail(f"servicios inesperados en {group_name}: {sorted(services)}")

    forbidden_fields = {"widget", "server", "container", "ping", "siteMonitor"}
    for name, expected_url in expected.items():
        service = services[name]
        if service.get("href") != expected_url:
            fail(f"URL incorrecta para {name}: {service.get('href')!r}")
        configured_forbidden = forbidden_fields.intersection(service)
        if configured_forbidden:
            fail(
                f"{name} contiene integraciones no autorizadas: "
                f"{sorted(configured_forbidden)}"
            )
        if service.get("widgets"):
            fail(f"{name} contiene widgets no autorizados")

home_services = {
    service.get("name"): service for service in by_name["HOME SERVER"]["services"]
}
for name, expected_url, expected_id in (
    ("GitHub", "https://github.com/", "github"),
    ("GitHub Copilot", "https://github.com/copilot", "github-copilot"),
):
    service = home_services.get(name)
    if service is None or service.get("href") != expected_url or service.get("id") != expected_id:
        fail(f"{name} no está correctamente integrado en HOME SERVER")

serialized = json.dumps(
    [by_name[group_name] for group_name in expected_links], ensure_ascii=False
).lower()
for secret_word in ("api_key", "apikey", "token", "password", "secret_key"):
    if secret_word in serialized:
        fail(f"se detectó un patrón sensible: {secret_word}")

print("Configuración runtime de herramientas y Administración: OK")
