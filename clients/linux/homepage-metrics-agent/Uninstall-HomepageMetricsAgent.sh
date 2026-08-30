#!/usr/bin/env bash
set -Eeuo pipefail

readonly INSTALL_ROOT='/opt/homepage-metrics-agent'
readonly CONFIG_ROOT='/etc/homepage-metrics-agent'
readonly STATE_ROOT='/home/nilton/.local/share/homepage-metrics-agent'
readonly SERVICE_NAME='homepage-metrics-agent'
readonly FIREWALL_SERVICE_NAME='homepage-metrics-agent-firewall'

[[ "${EUID}" -eq 0 ]] || { echo 'ERROR: ejecuta mediante sudo' >&2; exit 1; }
timestamp="$(date +%Y%m%d-%H%M%S)"
systemctl disable --now "${SERVICE_NAME}.service" "${FIREWALL_SERVICE_NAME}.service" >/dev/null 2>&1 || true
rm -f "/etc/systemd/system/${SERVICE_NAME}.service" "/etc/systemd/system/${FIREWALL_SERVICE_NAME}.service"
systemctl daemon-reload
for path in "${INSTALL_ROOT}" "${CONFIG_ROOT}" "${STATE_ROOT}"; do
    [[ -e "${path}" ]] && mv "${path}" "${path}.removed-${timestamp}"
done
echo "Agente DEV retirado; archivos movidos a rutas .removed-${timestamp}."
