#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOMEPAGE_URL="https://macmini-server.tailf553c4.ts.net:10000"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

tailscale serve status --json | \
    python3 "${HOMEPAGE_PROJECT_DIR}/tests/tailscale_validate.py" published

serve_status="$(tailscale serve status)"
for endpoint in \
    'https://macmini-server.tailf553c4.ts.net (tailnet only)' \
    'https://macmini-server.tailf553c4.ts.net:8443 (tailnet only)' \
    'https://macmini-server.tailf553c4.ts.net:10000 (tailnet only)'; do
    grep -Fq "${endpoint}" <<<"${serve_status}" || \
        fail "El endpoint no figura como privado: ${endpoint}"
done

https_result=""
for attempt in {1..12}; do
    if https_result="$(curl --silent --show-error --noproxy '*' \
        --connect-timeout 5 --max-time 10 --output /dev/null \
        --write-out '%{http_code} %{ssl_verify_result}' \
        "${HOMEPAGE_URL}/api/healthcheck")"; then
        break
    fi
    [[ "${attempt}" == "12" ]] || sleep 2
done
[[ "${https_result}" == "200 0" ]] || \
    fail "Healthcheck HTTPS inesperado (HTTP/TLS): ${https_result:-sin respuesta}"

root_code="$(curl --silent --show-error --noproxy '*' --max-time 10 \
    --output /dev/null --write-out '%{http_code}' "${HOMEPAGE_URL}/")"
[[ "${root_code}" == "200" ]] || fail "La portada HTTPS devolvió ${root_code}"

local_code="$(curl --silent --show-error --noproxy '*' --max-time 10 \
    --output /dev/null --write-out '%{http_code}' \
    http://127.0.0.1:3000/api/healthcheck)"
[[ "${local_code}" == "200" ]] || fail "El healthcheck local devolvió ${local_code}"

if curl --silent --show-error --noproxy '*' --connect-timeout 2 --max-time 4 \
    --output /dev/null http://192.168.1.43:3000/; then
    fail "Homepage es accesible directamente por la LAN en 192.168.1.43:3000"
fi

echo "Pruebas HTTPS/Tailscale: OK"
