#!/usr/bin/env bash
set -Eeuo pipefail

readonly INSTALL_ROOT='/opt/homepage-metrics-agent'
readonly CONFIG_ROOT='/etc/homepage-metrics-agent'
readonly STATE_ROOT='/home/nilton/.local/share/homepage-metrics-agent'
readonly SERVICE_NAME='homepage-metrics-agent'
readonly FIREWALL_SERVICE_NAME='homepage-metrics-agent-firewall'
readonly TAILSCALE_IP='100.80.93.74'
readonly MAC_MINI_IP='100.72.206.57'
readonly GLANCES_VERSION='4.5.6'
readonly USERNAME='homepage'

fail() { echo "ERROR: $*" >&2; exit 1; }
[[ "${EUID}" -eq 0 ]] || fail 'ejecuta mediante sudo'
id nilton >/dev/null || fail 'no existe el usuario nilton'
ip -4 addr show tailscale0 | grep -Fq "${TAILSCALE_IP}/32" || fail "tailscale0 no presenta ${TAILSCALE_IP}"
[[ ! -e "${INSTALL_ROOT}" && ! -e "${CONFIG_ROOT}" && ! -e "${STATE_ROOT}" ]] || \
    fail 'ya existe una instalación o estado previo; usa primero el desinstalador'
! ss -ltnH | grep -Eq ":61208[[:space:]]" || fail 'el puerto 61208 ya está ocupado'
! systemctl cat "${SERVICE_NAME}.service" >/dev/null 2>&1 || fail 'ya existe la unidad del agente'
! systemctl cat "${FIREWALL_SERVICE_NAME}.service" >/dev/null 2>&1 || fail 'ya existe la unidad de firewall'
! iptables -S | grep -Fq 'HOMEPAGE_METRICS_AGENT' || fail 'ya existe una cadena firewall reservada'

stage_root="$(mktemp -d /opt/.homepage-metrics-agent.new.XXXXXX)"
activated=0
completed=0
cleanup() {
    result="$?"
    if [[ "${result}" -ne 0 && "${activated}" -eq 1 ]]; then
        systemctl disable --now "${SERVICE_NAME}.service" "${FIREWALL_SERVICE_NAME}.service" >/dev/null 2>&1 || true
        rm -f "/etc/systemd/system/${SERVICE_NAME}.service" "/etc/systemd/system/${FIREWALL_SERVICE_NAME}.service"
        systemctl daemon-reload || true
        if [[ -e "${INSTALL_ROOT}" ]]; then
            mv "${INSTALL_ROOT}" "${INSTALL_ROOT}.failed-$(date +%Y%m%d-%H%M%S)" || true
        fi
        if [[ -e "${CONFIG_ROOT}" ]]; then
            mv "${CONFIG_ROOT}" "${CONFIG_ROOT}.failed-$(date +%Y%m%d-%H%M%S)" || true
        fi
        if [[ -e "${STATE_ROOT}" ]]; then
            mv "${STATE_ROOT}" "${STATE_ROOT}.failed-$(date +%Y%m%d-%H%M%S)" || true
        fi
    fi
    [[ -n "${stage_root}" && -d "${stage_root}" ]] && rm -rf -- "${stage_root}"
    return "${result}"
}
trap cleanup EXIT

install -d -m 0755 "${stage_root}/app"
cp "${BASH_SOURCE%/*}/Write-GlancesPassword.py" "${stage_root}/app/"
cp "${BASH_SOURCE%/*}/Test-HomepageMetricsAgent.py" "${stage_root}/app/"
cp "${BASH_SOURCE%/*}/Test-HomepageMetricsAgent.sh" "${stage_root}/app/"
cp "${BASH_SOURCE%/*}/homepage-metrics-agent-firewall.sh" "${stage_root}/app/"
python3 -m venv "${stage_root}/venv"
"${stage_root}/venv/bin/python" -m pip install --disable-pip-version-check --no-input "glances[web]==${GLANCES_VERSION}"
"${stage_root}/venv/bin/python" -m pip check
"${stage_root}/venv/bin/python" -m glances --version

id homepage-metrics >/dev/null 2>&1 || useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin homepage-metrics
install -d -m 0750 -o root -g homepage-metrics "${stage_root}/config/passwords"
secret="$("${stage_root}/venv/bin/python" -c 'import secrets; print(secrets.token_urlsafe(32))')"
[[ "${#secret}" -eq 43 ]] || fail 'la generación de secreto no produjo 43 caracteres'
printf '%s' "${secret}" | "${stage_root}/venv/bin/python" "${stage_root}/app/Write-GlancesPassword.py" "${stage_root}/config/passwords" "${USERNAME}"
install -d -m 0700 -o nilton -g nilton "${STATE_ROOT}"
printf '%s\n' "${secret}" | install -m 0600 -o nilton -g nilton /dev/stdin "${STATE_ROOT}/secret"
secret=''

cat >"${stage_root}/config/glances.conf" <<EOF
[outputs]
cors_origins=https://macmini-server.tailf553c4.ts.net:10000
cors_credentials=False
webui_allowed_hosts=tickets-server-dev.tailf553c4.ts.net,${TAILSCALE_IP}

[passwords]
local_password_path=${CONFIG_ROOT}/passwords
EOF
chmod 0640 "${stage_root}/config/glances.conf" "${stage_root}/config/passwords/${USERNAME}.pwd"
chown root:homepage-metrics "${stage_root}/config/glances.conf" "${stage_root}/config/passwords/${USERNAME}.pwd"

mv "${stage_root}" "${INSTALL_ROOT}"
stage_root=''
mv "${INSTALL_ROOT}/config" "${CONFIG_ROOT}"
chown -R root:root "${INSTALL_ROOT}"
chmod 0755 "${INSTALL_ROOT}" "${INSTALL_ROOT}/venv" "${INSTALL_ROOT}/venv/bin"
chown root:homepage-metrics "${CONFIG_ROOT}" "${CONFIG_ROOT}/passwords"
chmod 0750 "${CONFIG_ROOT}" "${CONFIG_ROOT}/passwords"
chmod 0755 "${INSTALL_ROOT}/app/homepage-metrics-agent-firewall.sh" "${INSTALL_ROOT}/app/Test-HomepageMetricsAgent.sh"

cat >"/etc/systemd/system/${FIREWALL_SERVICE_NAME}.service" <<EOF
[Unit]
Description=Firewall privado para Homepage Metrics Agent DEV
Requires=tailscaled.service
After=tailscaled.service
Before=${SERVICE_NAME}.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${INSTALL_ROOT}/app/homepage-metrics-agent-firewall.sh start
ExecStop=${INSTALL_ROOT}/app/homepage-metrics-agent-firewall.sh stop
EOF
cat >"/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Glances privado para Homepage Metrics Agent DEV
Requires=${FIREWALL_SERVICE_NAME}.service
After=network-online.target tailscaled.service ${FIREWALL_SERVICE_NAME}.service

[Service]
Type=simple
User=homepage-metrics
Group=homepage-metrics
Environment=HOME=/var/lib/homepage-metrics-agent
StateDirectory=homepage-metrics-agent
ExecStart=${INSTALL_ROOT}/venv/bin/python -m glances -C ${CONFIG_ROOT}/glances.conf -w --disable-webui --disable-autodiscover --disable-process --disable-plugin all --enable-plugin quicklook,system,cpu,mem,fs,uptime --hide-public-info --disable-config-exec --disable-check-update -B ${TAILSCALE_IP} -p 61208 -u ${USERNAME}
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectSystem=strict
ProtectHome=true
ProtectKernelTunables=true
ProtectControlGroups=true
RestrictAddressFamilies=AF_INET AF_UNIX

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "${FIREWALL_SERVICE_NAME}.service" "${SERVICE_NAME}.service"
activated=1
deadline=$((SECONDS + 45))
until ss -ltnH | grep -Fq "${TAILSCALE_IP}:61208"; do
    (( SECONDS < deadline )) || fail 'el agente no abrió 61208 en 45 segundos'
    sleep 1
done
"${INSTALL_ROOT}/app/Test-HomepageMetricsAgent.sh"
completed=1
trap - EXIT
echo 'Homepage Metrics Agent DEV instalado y validado; secreto disponible solo para nilton.'
