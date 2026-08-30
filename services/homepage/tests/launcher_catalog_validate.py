#!/usr/bin/env python3
"""Valida en Linux el catálogo y la superficie de ataque del lanzador Windows."""

import json
import pathlib
import re


project_root = pathlib.Path(__file__).resolve().parents[3]
launcher_root = project_root / "clients/windows/homepage-launcher"
catalog_path = launcher_root / "tools.json"
handler_path = launcher_root / "HomepageLauncher.ps1"

catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
if not isinstance(catalog, list) or not catalog:
    raise SystemExit("ERROR: el catálogo del lanzador está vacío")

ids = [tool.get("id") for tool in catalog]
if len(ids) != len(set(ids)):
    raise SystemExit("ERROR: hay identificadores duplicados en el lanzador")

for tool in catalog:
    tool_id = tool.get("id", "")
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", tool_id):
        raise SystemExit(f"ERROR: identificador no permitido: {tool_id!r}")
    if tool.get("mode") not in {"app", "cli", "warp-tab"}:
        raise SystemExit(f"ERROR: modo no permitido para {tool_id}")
    fallback = tool.get("fallbackUrl", "")
    if not fallback.startswith("https://"):
        raise SystemExit(f"ERROR: fallback no HTTPS para {tool_id}")
    if not isinstance(tool.get("appIds"), list) or not isinstance(
        tool.get("commands"), list
    ):
        raise SystemExit(f"ERROR: resolución no válida para {tool_id}")

expected_installed = {
    "vscode": "Microsoft.VisualStudioCode",
    "cursor": "Anysphere.Cursor",
    "antigravity": "com.google.antigravity",
    "hermes": "com.nousresearch.hermes",
    "warp": "dev.warp.Warp",
    "powershell": (
        "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}"
        "\\WindowsPowerShell\\v1.0\\powershell.exe"
    ),
}
by_id = {tool["id"]: tool for tool in catalog}
for tool_id, app_id in expected_installed.items():
    tool = by_id.get(tool_id)
    if not tool or not tool.get("expectedInstalled") or app_id not in tool["appIds"]:
        raise SystemExit(f"ERROR: AppID verificado ausente para {tool_id}")

opencode = by_id.get("opencode", {})
if (
    opencode.get("mode") != "warp-tab"
    or opencode.get("commands", [None])[0] != "opencode.cmd"
    or opencode.get("tabConfig") != "homepage_opencode"
    or not opencode.get("expectedInstalled")
):
    raise SystemExit("ERROR: OpenCode no está fijado a su Tab Config de Warp")

warp_tab_config = launcher_root / "warp-homepage-opencode.toml"
warp_tab_text = warp_tab_config.read_text(encoding="utf-8")
if 'shell = "bash"' not in warp_tab_text or 'commands = ["opencode.cmd"]' not in warp_tab_text:
    raise SystemExit("ERROR: la Tab Config no fija Bash y opencode.cmd")

handler = handler_path.read_text(encoding="utf-8")
for guard in (
    "homeserver-launch",
    "IsDefaultPort",
    "AbsolutePath",
    "parsedUri.Query",
    "parsedUri.Fragment",
    "Herramienta no autorizada",
):
    if guard not in handler:
        raise SystemExit(f"ERROR: falta la protección del lanzador: {guard}")
for forbidden in ("Invoke-Expression", "iex ", "cmd /c"):
    if forbidden.lower() in handler.lower():
        raise SystemExit(f"ERROR: construcción prohibida en el lanzador: {forbidden}")

if len(catalog) != 13:
    raise SystemExit(f"ERROR: se esperaban 13 destinos y hay {len(catalog)}")

print(f"Catálogo estático del lanzador: OK ({len(catalog)} destinos)")
