#!/usr/bin/env bash
set -Eeuo pipefail

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

[[ "$(docker inspect homepage-dockerproxy --format '{{.State.Status}}' 2>/dev/null || true)" \
    == "running" ]] || fail "El docker-socket-proxy no está en ejecución"

proxy_ports="$(docker port homepage-dockerproxy 2>/dev/null || true)"
[[ -z "${proxy_ports}" ]] || fail "El proxy publica puertos en el host: ${proxy_ports}"

proxy_env="$(docker inspect homepage-dockerproxy --format '{{range .Config.Env}}{{println .}}{{end}}')"
grep -Fxq 'CONTAINERS=1' <<<"${proxy_env}" || fail "CONTAINERS no está habilitado"
grep -Fxq 'POST=0' <<<"${proxy_env}" || fail "POST no está deshabilitado"

socket_mount="$(docker inspect homepage-dockerproxy --format \
    '{{range .Mounts}}{{if eq .Destination "/var/run/docker.sock"}}{{.RW}}{{end}}{{end}}')"
[[ "${socket_mount}" == "false" ]] || fail "El socket del proxy no está montado RO"

if docker inspect homepage --format '{{range .Mounts}}{{println .Destination}}{{end}}' | \
    grep -Fxq '/var/run/docker.sock'; then
    fail "Homepage tiene acceso directo al socket Docker"
fi

proxy_get="$(docker exec homepage node -e '
fetch("http://dockerproxy:2375/containers/json")
  .then(async response => {
    const body = await response.text();
    console.log(response.status + "|" + body);
    process.exit(response.status === 200 ? 0 : 1);
  })
  .catch(error => { console.error(error); process.exit(1); });
')"
grep -q '^200|' <<<"${proxy_get}" || fail "El GET de contenedores fue rechazado"
grep -q '"/n8n"' <<<"${proxy_get}" || fail "El proxy no devuelve n8n"
grep -q '"/uptime-kuma"' <<<"${proxy_get}" || fail "El proxy no devuelve Uptime Kuma"

proxy_post_code="$(docker exec homepage node -e '
fetch("http://dockerproxy:2375/_ping", {method: "POST"})
  .then(response => console.log(response.status))
  .catch(error => { console.error(error); process.exit(1); });
')"
[[ "${proxy_post_code}" == "403" || "${proxy_post_code}" == "405" ]] || \
    fail "El proxy aceptó o procesó POST con código ${proxy_post_code}"

services_payload="$(curl --silent --show-error --max-time 5 \
    --header 'Host: macmini-server.tailf553c4.ts.net:10000' \
    http://127.0.0.1:3000/api/services)"
grep -q '"server":"local-docker","container":"n8n"' <<<"${services_payload}" || \
    fail "Homepage no asocia n8n con Docker"
grep -q '"server":"local-docker","container":"uptime-kuma"' <<<"${services_payload}" || \
    fail "Homepage no asocia Uptime Kuma con Docker"

echo "Pruebas del docker-socket-proxy: OK"
