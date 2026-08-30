#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOMEPAGE_HOST="macmini-server.tailf553c4.ts.net:10000"
PROD_NODE="servicio-tickets-definitivo.tailf553c4.ts.net"
PROD_URL="https://service-ab-electronic.com/"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

services_json="$(curl --fail --silent --show-error --retry 10 --retry-all-errors \
    --retry-delay 1 --max-time 10 --header "Host: ${HOMEPAGE_HOST}" \
    http://127.0.0.1:3000/api/services)"
python3 "${HOMEPAGE_PROJECT_DIR}/tests/production_validate.py" <<<"${services_json}"

prod_result="$(curl --silent --show-error --noproxy '*' --connect-timeout 5 \
    --max-time 15 --output /dev/null --write-out '%{http_code} %{ssl_verify_result}' \
    "${PROD_URL}")"
[[ "${prod_result}" == "200 0" ]] || \
    fail "Tickets PROD no responde correctamente (HTTP/TLS: ${prod_result})"

docker exec homepage ping -c 2 -W 3 "${PROD_NODE}" >/dev/null || \
    fail "Homepage no alcanza por ICMP el nodo PROD"

public_title="$(curl --silent --show-error --noproxy '*' --max-time 15 \
    "${PROD_URL}" | tr '\n' ' ' | rg -o -i '<title[^>]*>[^<]*</title>' | head -n 1)"
origin_title="$(curl --silent --show-error --noproxy '*' --max-time 15 \
    --header 'Host: service-ab-electronic.com' \
    http://100.113.199.93/ | tr '\n' ' ' | \
    rg -o -i '<title[^>]*>[^<]*</title>' | head -n 1)"
[[ "${public_title}" == "${origin_title}" && -n "${public_title}" ]] || \
    fail "El dominio público y el nodo PROD no presentan la misma aplicación"

echo "Pruebas de PRODUCCIÓN: OK"
