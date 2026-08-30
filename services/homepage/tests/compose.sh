#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOMEPAGE_COMPOSE_FILE="${HOMEPAGE_PROJECT_DIR}/compose.yaml"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

export HOMEPAGE_VAR_NILTON_PC_GLANCES_USERNAME="${HOMEPAGE_VAR_NILTON_PC_GLANCES_USERNAME:-homepage}"
export HOMEPAGE_VAR_NILTON_PC_GLANCES_PASSWORD="${HOMEPAGE_VAR_NILTON_PC_GLANCES_PASSWORD:-mock_ci_secret_012345678901234567890123456789}"

docker compose \
    --project-directory "${HOMEPAGE_PROJECT_DIR}" \
    -f "${HOMEPAGE_COMPOSE_FILE}" \
    config --quiet

rendered_compose="$(docker compose \
    --project-directory "${HOMEPAGE_PROJECT_DIR}" \
    -f "${HOMEPAGE_COMPOSE_FILE}" \
    config)"

grep -Fq 'image: ghcr.io/gethomepage/homepage:v2.1.2' <<<"${rendered_compose}" || \
    fail "La imagen renderizada no coincide"
grep -Fq 'host_ip: 127.0.0.1' <<<"${rendered_compose}" || \
    fail "Compose no conserva el bind a loopback"
grep -Fq 'published: "3000"' <<<"${rendered_compose}" || \
    fail "Compose no publica el puerto esperado"
grep -Fq 'HOMEPAGE_ALLOWED_HOSTS: macmini-server.tailf553c4.ts.net:10000' \
    <<<"${rendered_compose}" || fail "Compose no conserva el host permitido"

service_count="$(docker compose \
    --project-directory "${HOMEPAGE_PROJECT_DIR}" \
    -f "${HOMEPAGE_COMPOSE_FILE}" \
    config --services | wc -l)"
[[ "${service_count}" == "3" ]] || fail "La Fase 1D debe contener tres servicios"

grep -Fq 'image: ghcr.io/tecnativa/docker-socket-proxy:v0.5.0' \
    <<<"${rendered_compose}" || fail "La imagen renderizada del proxy no coincide"
grep -Fq 'source: /var/run/docker.sock' <<<"${rendered_compose}" || \
    fail "Falta el socket Docker en el proxy"
grep -Fq 'read_only: true' <<<"${rendered_compose}" || \
    fail "El socket Docker no está renderizado como read-only"
grep -Fq 'internal: true' <<<"${rendered_compose}" || \
    fail "La red del proxy no es interna"

grep -Fq 'image: nicolargo/glances:4.5.6-full' <<<"${rendered_compose}" || \
    fail "La imagen renderizada de Glances no coincide"
grep -Fq 'pid: host' <<<"${rendered_compose}" || fail "Glances no conserva pid: host"
grep -Fq 'source: /home/bedvil/server' <<<"${rendered_compose}" || \
    fail "Glances no conserva el montaje restringido del host"
grep -Fq 'target: /hostfs' <<<"${rendered_compose}" || \
    fail "Glances no monta el filesystem en /hostfs"

echo "Pruebas de Compose: OK"
