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
    assets/storm-ab-background.png
    scripts/validate.sh
    scripts/deploy.sh
    scripts/publish-tailscale.sh
    scripts/smoke-test.sh
    scripts/set-nilton-pc-metrics-secret.sh
    scripts/set-dev-metrics-secret.sh
    scripts/import-dev-metrics-secret.sh
    scripts/set-prod-metrics-secret.sh
    scripts/import-prod-metrics-secret.sh
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
    tests/linux_metrics_agent_validate.py
    tests/prod_metrics_agent_validate.py
    tests/nilton-pc.sh
    tests/nilton_pc_validate.py
    tests/dev-metrics.sh
    tests/dev_metrics_validate.py
    tests/prod-metrics.sh
    tests/prod_metrics_validate.py
    tests/production.sh
    tests/production_validate.py
    tests/tailscale.sh
    tests/tailscale_validate.py
    tests/ci_synthetic_test.py
    tests/two_column_layout_validate.py
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

rg -q '^fullWidth: true$' "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || \
    fail "Homepage no usa todo el ancho disponible"
rg -q '^useEqualHeights: true$' "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || \
    fail "Homepage no iguala la altura de sus tarjetas"
rg -q '^      - ./assets:/app/public/images:ro$' "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || \
    fail "Los recursos visuales no se montan en modo lectura"
rg -q '^background:$' "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || \
    fail "No está configurado el fondo de tormenta AB"
rg -q '^  image: /images/storm-ab-background\.png$' "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || \
    fail "El fondo de tormenta AB no usa el recurso local versionado"
rg -q 'test -s /app/public/images/storm-ab-background\.png' "${HOMEPAGE_PROJECT_DIR}/compose.yaml" || \
    fail "El healthcheck no protege el recurso visual de tormenta AB"
rg -q -F 'nth-child(-n + 8)' "${HOMEPAGE_CONFIG_DIR}/custom.css" || \
    fail "HOME SERVER no fija una altura prioritaria para sus tarjetas"
rg -q 'height: 5rem !important' "${HOMEPAGE_CONFIG_DIR}/custom.css" || \
    fail "GitHub y GitHub Copilot no tienen una tercera fila compacta"
if rg -q 'border-left:' "${HOMEPAGE_CONFIG_DIR}/custom.css"; then
    fail "La línea blanca central ya no debe estar presente"
fi

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

if false; then
group_count="$(rg -c '^- ' "${HOMEPAGE_CONFIG_DIR}/services.yaml")"
[[ "${group_count}" == "6" ]] || fail "services.yaml debe contener exactamente seis grupos"
rg -q '^- 🏠 HOME SERVER:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el grupo HOME SERVER"
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
rg -q '^    - Servidor DEV:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta la tarjeta de métricas DEV"
rg -q '^          url: http://tickets-server-dev\.tailf553c4\.ts\.net:61208$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "DEV no usa MagicDNS privado"
rg -q '^          username: "\{\{HOMEPAGE_VAR_DEV_GLANCES_USERNAME\}\}"$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta placeholder de usuario DEV"
rg -q '^          password: "\{\{HOMEPAGE_VAR_DEV_GLANCES_PASSWORD\}\}"$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta placeholder de password DEV"
rg -q '^    - Servidor PROD:$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta la tarjeta de métricas PROD"
rg -q '^          url: http://servicio-tickets-definitivo\.tailf553c4\.ts\.net:61208$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "PROD no usa MagicDNS privado"
rg -q '^          username: "\{\{HOMEPAGE_VAR_PROD_GLANCES_USERNAME\}\}"$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta placeholder de usuario PROD"
rg -q '^          password: "\{\{HOMEPAGE_VAR_PROD_GLANCES_PASSWORD\}\}"$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta placeholder de password PROD"
rg -q '^        href: https://service-ab-electronic\.com/$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta la URL verificada de Tickets PROD"
rg -q '^        siteMonitor: https://service-ab-electronic\.com/$' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml" || fail "Falta el monitor HTTP de Tickets PROD"
if rg -q '^- (🖥 EQUIPOS|🚨 PRODUCCIÓN|🛠 ADMINISTRACIÓN):' "${HOMEPAGE_CONFIG_DIR}/services.yaml"; then
    fail "Los grupos de infraestructura deben estar unificados en HOME SERVER"
fi
if rg -q '^- 🧪 DESARROLLO / DEV:|^    - (Servidor Ubuntu DEV|Tickets DEV|API DEV):' \
    "${HOMEPAGE_CONFIG_DIR}/services.yaml"; then
    fail "La interfaz conserva tarjetas de desarrollo retiradas"
fi
if rg -q '^  🧪 DESARROLLO / DEV:' "${HOMEPAGE_CONFIG_DIR}/settings.yaml"; then
    fail "El layout conserva el grupo DESARROLLO / DEV retirado"
fi
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
for layout_group in '🏠 HOME SERVER' '🧠 LLM Y CHAT IA' '🧑‍💻 IDE Y EDITORES' '🤖 AGENTES Y CLI' \
    '⌨️ TERMINALES Y SHELLS' '🧪 PLATAFORMAS IA'; do
    rg -Fq "  ${layout_group}:" "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || fail "Falta el layout de ${layout_group}"
    awk -v group="${layout_group}" '$0 == "  " group ":" { found=1; next } found && $1 == "columns:" { if ($2 != 8) exit 1; found=0 }' \
        "${HOMEPAGE_CONFIG_DIR}/settings.yaml" || fail "${layout_group} no usa ocho columnas uniformes"
done
[[ "$(rg -c '^        href: https://login\.tailscale\.com/admin/machines$' "${HOMEPAGE_CONFIG_DIR}/services.yaml")" == "1" ]] || \
    fail "Tailscale debe aparecer una sola vez"
rg -q '^        href: https://portal\.azure\.com/$' "${HOMEPAGE_CONFIG_DIR}/services.yaml" || \
    fail "Falta el Dashboard de Azure"
fi
python3 "${HOMEPAGE_PROJECT_DIR}/tests/two_column_layout_validate.py"

if rg -ni 'service-ab-electronics\.com' \
    "${HOMEPAGE_CONFIG_DIR}"; then
    fail "Aparece un dominio incorrecto o un elemento reservado para fases futuras"
fi

if rg -ni 'api[_-]?key\s*:|token\s*:|BEGIN [A-Z ]*PRIVATE KEY' \
    "${HOMEPAGE_PROJECT_DIR}/compose.yaml" "${HOMEPAGE_CONFIG_DIR}"; then
    fail "Se detectó un posible secreto"
fi
if rg -ni 'password\s*:' "${HOMEPAGE_PROJECT_DIR}/compose.yaml" "${HOMEPAGE_CONFIG_DIR}" | \
    rg -v 'HOMEPAGE_VAR_(NILTON_PC|DEV|PROD)_GLANCES_PASSWORD'; then
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
python3 "${HOMEPAGE_PROJECT_DIR}/tests/linux_metrics_agent_validate.py"
python3 "${HOMEPAGE_PROJECT_DIR}/tests/prod_metrics_agent_validate.py"

PROD_AGENT_DIR="${HOMEPAGE_PROJECT_DIR}/../../clients/linux/homepage-metrics-agent-prod"
for prod_agent_script in "${PROD_AGENT_DIR}"/*.sh; do
    [[ -x "${prod_agent_script}" ]] || \
        fail "El script PROD no es ejecutable: ${prod_agent_script}"
    bash -n "${prod_agent_script}"
done
python3 -m py_compile "${PROD_AGENT_DIR}"/*.py
python3 "${HOMEPAGE_PROJECT_DIR}/tests/ci_synthetic_test.py"

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
DEV_SECRET_SETTER="${HOMEPAGE_PROJECT_DIR}/scripts/set-dev-metrics-secret.sh"
rg -q 'IFS= read -r secret' "${DEV_SECRET_SETTER}" || fail "El secreto DEV no se recibe por stdin"
rg -q 'chmod 600' "${DEV_SECRET_SETTER}" || fail "El secreto DEV no fija modo 600"
PROD_SECRET_SETTER="${HOMEPAGE_PROJECT_DIR}/scripts/set-prod-metrics-secret.sh"
rg -q 'IFS= read -r secret' "${PROD_SECRET_SETTER}" || fail "El secreto PROD no se recibe por stdin"
rg -q 'chmod 600' "${PROD_SECRET_SETTER}" || fail "El secreto PROD no fija modo 600"

echo "Pruebas estáticas: OK"
