#!/usr/bin/env python3
"""Valida los destinos de Tailscale Serve sin depender de su salida para humanos."""

import argparse
import json
import sys


HOST = "macmini-server.tailf553c4.ts.net"
EXPECTED = {
    "443": "http://127.0.0.1:18789",
    "8443": "http://127.0.0.1:5678",
    "10000": "http://127.0.0.1:3000",
}


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("legacy", "published"))
    args = parser.parse_args()

    try:
        config = json.load(sys.stdin)
    except (json.JSONDecodeError, TypeError) as exc:
        fail(f"JSON de Tailscale no válido: {exc}")

    required_ports = ("443", "8443")
    if args.mode == "published":
        required_ports += ("10000",)

    tcp = config.get("TCP", {})
    web = config.get("Web", {})
    for port in required_ports:
        if tcp.get(port) != {"HTTPS": True}:
            fail(f"el listener HTTPS {port} falta o cambió")

        handler = web.get(f"{HOST}:{port}", {}).get("Handlers", {}).get("/", {})
        actual_proxy = handler.get("Proxy")
        if actual_proxy != EXPECTED[port]:
            fail(
                f"el destino de {port} es {actual_proxy!r}; "
                f"se esperaba {EXPECTED[port]!r}"
            )

    print(f"Configuración Tailscale ({args.mode}): OK")


if __name__ == "__main__":
    main()
