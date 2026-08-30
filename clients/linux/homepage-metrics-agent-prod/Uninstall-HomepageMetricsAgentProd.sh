#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'ERROR: ejecuta mediante sudo' >&2; exit 1; }
stamp="$(date +%Y%m%d-%H%M%S)"
systemctl disable --now homepage-metrics-agent-prod.service homepage-metrics-agent-prod-firewall.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/homepage-metrics-agent-prod{,-firewall}.service
systemctl daemon-reload
for path in /opt/homepage-metrics-agent-prod /etc/homepage-metrics-agent-prod /home/ab/.local/share/homepage-metrics-agent-prod; do [[ -e "$path" ]] && mv "$path" "${path}.removed-${stamp}"; done
echo "Agente PROD retirado; las rutas se conservaron con sufijo .removed-${stamp}."
