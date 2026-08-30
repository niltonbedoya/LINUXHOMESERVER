#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOMEPAGE_CONFIG_DIR="${HOMEPAGE_PROJECT_DIR}/config"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

required_files=(
    compose.yaml
    config/settings.yaml
    config/services.yaml
    config/widgets.yaml
    config/bookmarks.yaml
    config/docker.yaml
    config/kubernetes.yaml
    config/proxmox.yaml
    config/custom.css
    config/custom.js
    scripts/validate.sh
    scripts/deploy.sh
    scripts/publish-tailscale.sh
    scripts/smoke-test.sh
    scripts/set-nilton-pc-metrics-secret.sh
    tests/static.sh
    tests/compose.sh
    tests/runtime.sh
    tests/docker-proxy.sh
    tests/development.sh
    tests/development_validate.py
    tests/metrics.sh
    tests/metrics_validate.py
    tests/phase4.sh
    tests/phase4_validate.py
    tests/launcher_catalog_validate.py
    tests/windows_metrics_agent_validate.py
    tests/nilton-pc.sh
    tests/nilton_pc_validate.py
    tests/production.sh
    tests/production_validate.py
    tests/tailscale.sh
    tests/tailscale_validate.py
    tests/regression.sh
)

for required_file in "${required_files[@]}"; do
    [[ -s "${HOMEPAGE_PROJECT_DIR}/${required_file}" ]] || \
        fail "Falta el archivo requerido o está vacío: ${required_file}"
done

if rg -n $'\t' "${HOMEPAGE_PROJECT_DIR}/compose.yaml" "${HOMEPAGE_CONFIG_DIR}"; then
    fail "Se encontraron tabuladores en la configuración"
fi

rg -q '^\s*image: ghcr\.io/gethomepage/homepage:v2\.1\.2$' \
    "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || fail "La imagen de Homepage no está fijada"

rg -q '^\s*- "127\.0\.0\.1:3000:3000"$' \
    "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || fail "El puerto 3000 no está limitado a loopback"

rg -q '^\s*HOMEPAGE_ALLOWED_HOSTS: macmini-server\.tailf553c4\.ts\.net:10000$' \
    "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || fail "HOMEPAGE_ALLOWED_HOSTS no es exacto"

if rg -n ':latest|HOMEPAGE_ALLOWED_HOSTS:.*\*' \
    "${HOMEPAGE_PROJECT_DIR}/compose.yaml"; then
    fail "Se encontró una configuración prohibida en Compose"
fi

rg -q '^\s*image: ghcr\.io/tecnativa/docker-socket-proxy:v0\.5\.0$' \
    "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || fail "La imagen del proxy no está fijada"
rg -q '^\s*POST: "0"$' "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || \
    fail "El proxy no bloquea POST"
rg -q '^\s*CONTAINERS: "1"$' "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || \
    fail "El proxy no habilita solo la API de contenedores requerida"
rg -q '^\s*- /var/run/docker\.sock:/var/run/docker\.sock:ro$' \
    "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || fail "El socket no está montado como RO"

socket_count="$(rg -c '/var/run/docker\.sock' "${HOMEPAGE_PROJECT_DIR}/compose.yaml")"
[[ "${socket_count}" == "1" ]] || fail "Solo el docker-socket-proxy debe montar el socket"

rg -q '^\s*image: nicolargo/glances:4\.5\.6-full$' \
    "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || fail "La imagen de Glances no está fijada"
rg -q '^\s*pid: host$' "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || \
    fail "Glances no usa el namespace PID del host"
rg -q '^\s*- /home/bedvil/server:/hostfs:ro$' \
    "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || fail "Falta el montaje restringido del disco"

rg -q '^\s*url: http://glances:61208$' "${HOMEPAGE_CONFIG_DIR}/widgets.yaml" || \
    fail "El widget Glances no usa la red interna"
rg -q '^\s*cputemp: true$' "${HOMEPAGE_CONFIG_DIR}/widgets.yaml" || \
    fail "La temperatura validada no está habilitada"
rg -q '^\s*cpuSensorLabel: Package id$' "${HOMEPAGE_CONFIG_DIR}/widgets.yaml" || \
    fail "El widget no prioriza Package id"
if rg -q '^- resources:' "${HOMEPAGE_CONFIG_DIR}/widgets.yaml"; then
    fail "No se deben presentar recursos del contenedor como métricas del host"
fi

group_count="$(rg -c '^- ' "${HOMEPAGE_CONFIG_DIR}/services.yaml")"
[[ "${group_count}" == "10" ]] || fail "services.yaml debe contener exactamente diez grupos"
rg -q '^- 🏠 HOME SERVER:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo HOME SERVER"
rg -q '^- 🖥 EQUIPOS:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo EQUIPOS"
rg -q '^    - Nilton PC:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta la tarjeta de Nilton PC"
rg -q '^          url: http://nilton-pc\.tailf553c4\.ts\.net:61208$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Nilton PC no usa MagicDNS privado"
rg -q '^          username: "\{\{HOMEPAGE_VAR_NILTON_PC_GLANCES_USERNAME\}\}"$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta placeholder de usuario de Nilton PC"
rg -q '^          password: "\{\{HOMEPAGE_VAR_NILTON_PC_GLANCES_PASSWORD\}\}"$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta placeholder de password de Nilton PC"
rg -q '^          metric: info$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Nilton PC no usa la métrica compacta info"
rg -q '^          chart: false$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Nilton PC no usa vista compacta"
rg -q '^  🖥 EQUIPOS:$' "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || \
    fail "Falta el layout de EQUIPOS"
rg -q '^- 🚨 PRODUCCIÓN:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo inequívoco de PRODUCCIÓN"
rg -q '^    - Servidor Ubuntu PROD:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el nodo PROD"
rg -q '^        ping: servicio-tickets-definitivo\.tailf553c4\.ts\.net$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "El nodo PROD no usa MagicDNS"
rg -q '^        href: https://service-ab-electronic\.com/$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta la URL verificada de Tickets PROD"
rg -q '^        siteMonitor: https://service-ab-electronic\.com/$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta el monitor HTTP de Tickets PROD"
rg -q '^  🚨 PRODUCCIÓN:$' "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || \
    fail "Falta el layout de PRODUCCIÓN"
rg -q '^- 🧪 DESARROLLO / DEV:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo inequívoco de DESARROLLO"
rg -q '^        ping: tickets-server-dev\.tailf553c4\.ts\.net$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "El nodo DEV no usa MagicDNS"
rg -q '^        href: http://tickets-server-dev\.tailf553c4\.ts\.net:5173/$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta el frontend DEV verificado"
rg -q '^        href: http://tickets-server-dev\.tailf553c4\.ts\.net:18000/docs$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta Swagger DEV"
rg -q '^        siteMonitor: http://tickets-server-dev\.tailf553c4\.ts\.net:18000/health$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta el healthcheck DEV"
rg -q '^  🧪 DESARROLLO / DEV:$' "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || \
    fail "Falta el layout de DESARROLLO"
rg -q '^- 🧠 LLM Y CHAT IA:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo de LLM y chat"
rg -q '^- 🧑‍💻 IDE Y EDITORES:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo de IDE y editores"
rg -q '^- 🤖 AGENTES Y CLI:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo de agentes y CLI"
rg -q '^- ⌨️ TERMINALES Y SHELLS:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo de terminales y shells"
rg -q '^- 🧪 PLATAFORMAS IA:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo de plataformas IA"
rg -q '^- 🛠 ADMINISTRACIÓN:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo de ADMINISTRACIÓN"
for layout_group in '🧠 LLM Y CHAT IA' '🧑‍💻 IDE Y EDITORES' '🤖 AGENTES Y CLI' \
    '⌨️ TERMINALES Y SHELLS' '🧪 PLATAFORMAS IA'; do
    rg -Fq "  ${layout_group}:" "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || \
        fail "Falta el layout de ${layout_group}"
done
rg -q '^  🛠 ADMINISTRACIÓN:$' "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || \
    fail "Falta el layout de ADMINISTRACIÓN"

if rg -ni 'service-ab-electronics\.com' \
    "${HOMEPAGE_CONFIG_DIR}"; then
    fail "Aparece un dominio incorrecto o un elemento reservado para fases futuras"
fi

if rg -ni 'api[_-]?key\s*:|token\s*:|BEGIN [A-Z ]*PRIVATE KEY' \
    "${HOMEPAGE_PROJECT_DIR}/compose.yaml" "${HOMEPAGE_CONFIG_DIR}"; then
    fail "Se detectó un posible secreto"
fi
if rg -ni 'password\s*:' "${HOMEPAGE_PROJECT_DIR}/compose.yaml" "${HOMEPAGE_CONFIG_DIR}" | \
    rg -v 'HOMEPAGE_VAR_NILTON_PC_GLANCES_PASSWORD'; then
    fail "Se detectó un password sin placeholder controlado"
fi

LAUNCHER_DIR="${HOMEPAGE_PROJECT_DIR}/../../clients/windows/homepage-launcher"
for launcher_file in tools.json HomepageLauncher.ps1 Install-HomepageLauncher.ps1 \
    Uninstall-HomepageLauncher.ps1 Test-HomepageLauncher.ps1 \
    warp-homepage-opencode.toml README.md; do
    [[ -s "${LAUNCHER_DIR}/${launcher_file}" ]] || \
        fail "Falta el archivo del lanzador: ${launcher_file}"
done
python3 "${HOMEPAGE_PROJECT_DIR}/tests/launcher_catalog_validate.py"
python3 "${HOMEPAGE_PROJECT_DIR}/tests/windows_metrics_agent_validate.py"

SECRET_SETTER="${HOMEPAGE_PROJECT_DIR}/scripts/set-nilton-pc-metrics-secret.sh"
rg -q 'IFS= read -r secret' "${SECRET_SETTER}" || \
    fail "El secreto de Nilton PC no se recibe por stdin"
rg -q 'chmod 600' "${SECRET_SETTER}" || \
    fail "El archivo local de secretos no fija modo 600"
if rg -n 'echo.*\$\{?secret|printf.*%s.*\$\{?secret' "${SECRET_SETTER}" | \
    rg -v 'HOMEPAGE_VAR_NILTON_PC_GLANCES_PASSWORD'; then
    fail "El setter podría imprimir el secreto"
fi
git -C "${HOMEPAGE_PROJECT_DIR}" check-ignore -q .env || \
    fail "services/homepage/.env no está ignorado por Git"

echo "Pruebas estáticas: OK"
