#!/usr/bin/env bash
set -Eeuo pipefail

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

n8n_code="$(curl --silent --show-error --max-time 10 --output /dev/null \
    --write-out '%{http_code}' \
    https://macmini-server.tailf553c4.ts.net:8443/healthz)"
[[ "${n8n_code}" == "200" ]] || fail "La regresión de n8n devolvió ${n8n_code}"

openclaw_code="$(curl --silent --show-error --max-time 10 --output /dev/null \
    --write-out '%{http_code}' \
    https://macmini-server.tailf553c4.ts.net/)"
[[ "${openclaw_code}" == "200" ]] || fail "La regresión de OpenClaw devolvió ${openclaw_code}"

kuma_code="$(curl --silent --show-error --max-time 10 --output /dev/null \
    --write-out '%{http_code}' http://100.72.206.57:3001/)"
[[ "${kuma_code}" == "200" || "${kuma_code}" == "302" ]] || \
    fail "La regresión de Uptime Kuma devolvió ${kuma_code}"

[[ "$(docker inspect n8n --format '{{.State.Status}}')" == "running" ]] || \
    fail "n8n no está en ejecución"
[[ "$(docker inspect uptime-kuma --format '{{.State.Status}}')" == "running" ]] || \
    fail "Uptime Kuma no está en ejecución"
[[ "$(docker inspect uptime-kuma --format '{{.State.Health.Status}}')" == "healthy" ]] || \
    fail "Uptime Kuma no está healthy"

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tailscale serve status --json | \
    python3 "${HOMEPAGE_PROJECT_DIR}/tests/tailscale_validate.py" legacy

echo "Pruebas de regresión: OK"
