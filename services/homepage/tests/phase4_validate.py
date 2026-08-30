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

by_name = {group.get("name"): group for group in groups}
expected_groups = {
    "🏠 HOME SERVER",
    "🚨 PRODUCCIÓN",
    "🧪 DESARROLLO / DEV",
    "🧠 LLM Y CHAT IA",
    "🧑‍💻 IDE Y EDITORES",
    "🤖 AGENTES Y CLI",
    "⌨️ TERMINALES Y SHELLS",
    "🧪 PLATAFORMAS IA",
    "🛠 ADMINISTRACIÓN",
}
if set(by_name) != expected_groups:
    fail(f"grupos inesperados: {sorted(by_name)}")

expected_links = {
    "🧠 LLM Y CHAT IA": {
        "ChatGPT": "https://chatgpt.com/",
        "Gemini": "https://gemini.google.com/",
        "Claude": "https://claude.ai/",
        "Perplexity": "https://www.perplexity.ai/",
        "Grok": "https://grok.com/",
        "Microsoft Copilot": "https://copilot.microsoft.com/",
        "Mistral Vibe": "https://chat.mistral.ai/",
    },
    "🧑‍💻 IDE Y EDITORES": {
        "Visual Studio Code": "homeserver-launch://vscode",
        "Cursor": "homeserver-launch://cursor",
        "Antigravity": "homeserver-launch://antigravity",
        "Zed": "homeserver-launch://zed",
        "Visual Studio Community": "homeserver-launch://visual-studio",
        "JetBrains IDEs": "homeserver-launch://jetbrains",
    },
    "🤖 AGENTES Y CLI": {
        "Hermes Desktop": "homeserver-launch://hermes",
        "Codex CLI": "homeserver-launch://codex",
        "OpenCode": "homeserver-launch://opencode",
        "Aider": "homeserver-launch://aider",
        "GitHub Copilot": "https://github.com/copilot",
    },
    "⌨️ TERMINALES Y SHELLS": {
        "Warp": "homeserver-launch://warp",
        "PowerShell": "homeserver-launch://powershell",
        "Windows Terminal": "homeserver-launch://windows-terminal",
        "WSL": "homeserver-launch://wsl",
    },
    "🧪 PLATAFORMAS IA": {
        "Google AI Studio": "https://aistudio.google.com/",
        "NVIDIA Build": "https://build.nvidia.com/",
    },
    "🛠 ADMINISTRACIÓN": {
        "Tailscale Admin": "https://login.tailscale.com/admin/machines",
        "Uptime Kuma Admin": "http://100.72.206.57:3001/",
        "GitHub": "https://github.com/",
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

serialized = json.dumps(
    [by_name[group_name] for group_name in expected_links], ensure_ascii=False
).lower()
for secret_word in ("api_key", "apikey", "token", "password", "secret_key"):
    if secret_word in serialized:
        fail(f"se detectó un patrón sensible: {secret_word}")

print("Configuración runtime de herramientas y Administración: OK")
