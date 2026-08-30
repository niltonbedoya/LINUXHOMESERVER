#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOMEPAGE_HOST="macmini-server.tailf553c4.ts.net:10000"
DEV_NODE="tickets-server-dev.tailf553c4.ts.net"
DEV_FRONTEND="http://${DEV_NODE}:5173/"
DEV_API="http://${DEV_NODE}:18000"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

services_json="$(curl --fail --silent --show-error --retry 10 --retry-all-errors \
    --retry-delay 1 --max-time 10 --header "Host: ${HOMEPAGE_HOST}" \
    http://127.0.0.1:3000/api/services)"
python3 "${HOMEPAGE_PROJECT_DIR}/tests/development_validate.py" <<<"${services_json}"

frontend_html="$(curl --fail --silent --show-error --noproxy '*' --connect-timeout 5 \
    --max-time 15 "${DEV_FRONTEND}")"
frontend_title="$(tr '\n' ' ' <<<"${frontend_html}" | \
    rg -o -i '<title[^>]*>[^<]*</title>' | head -n 1)"
[[ "${frontend_title}" == '<title>Servicio Tickets</title>' ]] || \
    fail "El frontend DEV no presenta la aplicación esperada"

asset_path="$(rg -o '/assets/index-[A-Za-z0-9_-]+\.js' <<<"${frontend_html}" | head -n 1)"
[[ -n "${asset_path}" ]] || fail "No se encontró el bundle del frontend DEV"
frontend_bundle="$(curl --fail --silent --show-error --noproxy '*' --max-time 20 \
    "http://${DEV_NODE}:5173${asset_path}")"
grep -Fq "http://${DEV_NODE}:18000" <<<"${frontend_bundle}" || \
    fail "El bundle no contiene la API MagicDNS canónica"
if grep -Fq 'http://127.0.0.1:18000' <<<"${frontend_bundle}"; then
    fail "El bundle conserva la API loopback inválida"
fi

health_result="$(curl --silent --show-error --noproxy '*' --connect-timeout 5 \
    --max-time 15 --output /dev/null --write-out '%{http_code} %{content_type}' \
    "${DEV_API}/health")"
[[ "${health_result}" == 200\ application/json* ]] || \
    fail "Healthcheck DEV inesperado: ${health_result}"

docs_title="$(curl --silent --show-error --noproxy '*' --max-time 15 \
    "${DEV_API}/docs" | tr '\n' ' ' | \
    rg -o -i '<title[^>]*>[^<]*</title>' | head -n 1)"
[[ "${docs_title}" == '<title>Sistema de Tickets Servicio Técnico - Swagger UI</title>' ]] || \
    fail "Swagger DEV no presenta la API esperada"

cors_headers="$(curl --silent --show-error --noproxy '*' --connect-timeout 5 \
    --max-time 15 --request OPTIONS --dump-header - --output /dev/null \
    --header "Origin: http://${DEV_NODE}:5173" \
    --header 'Access-Control-Request-Method: POST' \
    --header 'Access-Control-Request-Headers: content-type,authorization' \
    "${DEV_API}/api/auth/login" | tr -d '\r')"
grep -Fq 'HTTP/1.1 200 OK' <<<"${cors_headers}" || \
    fail "El preflight CORS DEV no devolvió 200"
grep -Fiq "access-control-allow-origin: http://${DEV_NODE}:5173" \
    <<<"${cors_headers}" || fail "CORS no admite el origen MagicDNS DEV"

docker exec homepage ping -c 2 -W 3 "${DEV_NODE}" >/dev/null || \
    fail "Homepage no alcanza por ICMP el nodo DEV"

echo "Pruebas de DESARROLLO: OK"
