#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOMEPAGE_COMPOSE_FILE="${HOMEPAGE_PROJECT_DIR}/compose.yaml"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

container_status="$(docker inspect homepage --format '{{.State.Status}}' 2>/dev/null || true)"
[[ "${container_status}" == "running" ]] || fail "Homepage no está en ejecución"

restart_count="$(docker inspect homepage --format '{{.RestartCount}}')"
[[ "${restart_count}" == "0" ]] || fail "Homepage ha reiniciado ${restart_count} veces"

published_port="$(docker port homepage 3000/tcp)"
[[ "${published_port}" == "127.0.0.1:3000" ]] || \
    fail "Publicación inesperada del puerto: ${published_port}"

if docker inspect homepage --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}' | \
    rg -q '/var/run/docker\.sock'; then
    fail "Homepage tiene montado el socket Docker"
fi

health_code="$(curl --fail --silent --show-error --retry 15 --retry-all-errors \
    --retry-delay 1 --max-time 5 --output /dev/null --write-out '%{http_code}' \
    http://127.0.0.1:3000/api/healthcheck)"
[[ "${health_code}" == "200" ]] || fail "Healthcheck local devolvió ${health_code}"

docker exec homepage test -s /app/public/images/storm-ab-background.png || \
    fail "El recurso visual de tormenta AB no existe dentro de Homepage"
background_code="$(curl --silent --show-error --max-time 5 --output /dev/null \
    --write-out '%{http_code}' \
    --header 'Host: macmini-server.tailf553c4.ts.net:10000' \
    http://127.0.0.1:3000/images/storm-ab-background.png)"
[[ "${background_code}" == "200" ]] || \
    fail "El recurso visual de tormenta AB devolvió HTTP ${background_code}"

homepage_code="$(curl --silent --show-error --max-time 5 --output /dev/null \
    --write-out '%{http_code}' \
    --header 'Host: macmini-server.tailf553c4.ts.net:10000' \
    http://127.0.0.1:3000/)"
[[ "${homepage_code}" == "200" ]] || fail "La página principal devolvió ${homepage_code}"

if ss -lnt | rg -q '0\.0\.0\.0:3000|\[::\]:3000|\*:3000'; then
    fail "Homepage está expuesto fuera de loopback"
fi
ss -lnt | rg -q '127\.0\.0\.1:3000' || fail "No existe listener local en 3000"

homepage_logs="$(docker compose \
    --project-directory "${HOMEPAGE_PROJECT_DIR}" \
    -f "${HOMEPAGE_COMPOSE_FILE}" \
    logs --no-color --tail 120 homepage)"

if rg -ni 'host validation|yaml.*error|permission denied|EACCES|fatal' \
    <<<"${homepage_logs}"; then
    fail "Los logs contienen un error bloqueante"
fi

echo "Pruebas de runtime: OK"
