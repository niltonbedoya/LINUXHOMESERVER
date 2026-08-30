#!/usr/bin/env bash
set -Eeuo pipefail

readonly INSTALL_ROOT='/opt/homepage-metrics-agent-prod'
readonly CONFIG_ROOT='/etc/homepage-metrics-agent-prod'
readonly STATE_ROOT='/home/ab/.local/share/homepage-metrics-agent-prod'
readonly SERVICE='homepage-metrics-agent-prod'
readonly FIREWALL_SERVICE='homepage-metrics-agent-prod-firewall'
readonly TAILSCALE_IP='100.113.199.93'
readonly MAC_MINI_IP='100.72.206.57'
readonly HOST='servicio-tickets-definitivo.tailf553c4.ts.net'
readonly VERSION='4.5.6'
readonly USERNAME='homepage'

fail() { echo "ERROR: $*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'ejecuta mediante sudo'
id ab >/dev/null || fail 'no existe el usuario ab'
ip -4 addr show tailscale0 | grep -Fq "${TAILSCALE_IP}/32" || fail 'IP Tailscale inesperada'
python3 -c 'import ensurepip' >/dev/null 2>&1 || \
  fail 'falta ensurepip; instala primero el paquete oficial: sudo apt install python3.14-venv'
for path in "$INSTALL_ROOT" "$CONFIG_ROOT" "$STATE_ROOT"; do [[ ! -e "$path" ]] || fail "ya existe: $path"; done
! ss -ltnH | grep -Eq ':61208[[:space:]]' || fail '61208 ya está ocupado'
! systemctl cat "${SERVICE}.service" >/dev/null 2>&1 || fail 'ya existe la unidad del agente'
! systemctl cat "${FIREWALL_SERVICE}.service" >/dev/null 2>&1 || fail 'ya existe la unidad firewall'
! iptables -S | grep -Fq HOMEPAGE_METRICS_AGENT_PROD || fail 'ya existe la cadena firewall PROD'

stage="$(mktemp -d /opt/.homepage-metrics-agent-prod.new.XXXXXX)"
activated=0
cleanup() {
  result=$?
  if [[ $result -ne 0 && $activated -eq 1 ]]; then
    systemctl disable --now "${SERVICE}.service" "${FIREWALL_SERVICE}.service" >/dev/null 2>&1 || true
    rm -f "/etc/systemd/system/${SERVICE}.service" "/etc/systemd/system/${FIREWALL_SERVICE}.service"
    systemctl daemon-reload || true
    for path in "$INSTALL_ROOT" "$CONFIG_ROOT" "$STATE_ROOT"; do [[ -e "$path" ]] && mv "$path" "${path}.failed-$(date +%Y%m%d-%H%M%S)" || true; done
  fi
  [[ -d ${stage:-} ]] && rm -rf -- "$stage"
  return "$result"
}
trap cleanup EXIT

install -d -m 0755 "$stage/app"
cp "${BASH_SOURCE%/*}"/{Test-HomepageMetricsAgentProd.py,Test-HomepageMetricsAgentProd.sh,Write-GlancesPassword.py,homepage-metrics-agent-prod-firewall.sh,Uninstall-HomepageMetricsAgentProd.sh} "$stage/app/"
python3 -m venv "$stage/venv"
"$stage/venv/bin/python" -m pip install --disable-pip-version-check --no-input "glances[web]==${VERSION}"
"$stage/venv/bin/python" -m pip check
"$stage/venv/bin/python" -m glances --version

id homepage-metrics >/dev/null 2>&1 || useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin homepage-metrics
install -d -m 0750 -o root -g homepage-metrics "$stage/config/passwords"
secret="$("$stage/venv/bin/python" -c 'import secrets; print(secrets.token_urlsafe(32))')"
[[ ${#secret} -eq 43 ]] || fail 'secreto generado inválido'
printf %s "$secret" | "$stage/venv/bin/python" "$stage/app/Write-GlancesPassword.py" "$stage/config/passwords" "$USERNAME"
install -d -m 0700 -o ab -g ab "$STATE_ROOT"
printf '%s\n' "$secret" | install -m 0600 -o ab -g ab /dev/stdin "$STATE_ROOT/secret"
secret=''
cat >"$stage/config/glances.conf" <<EOF
[outputs]
cors_origins=https://macmini-server.tailf553c4.ts.net:10000
cors_credentials=False
webui_allowed_hosts=${HOST},${TAILSCALE_IP}

[passwords]
local_password_path=${CONFIG_ROOT}/passwords
EOF
chmod 0640 "$stage/config/glances.conf" "$stage/config/passwords/${USERNAME}.pwd"
chown root:homepage-metrics "$stage/config/glances.conf" "$stage/config/passwords/${USERNAME}.pwd"
mv "$stage" "$INSTALL_ROOT"; stage=''
mv "$INSTALL_ROOT/config" "$CONFIG_ROOT"
chown -R root:root "$INSTALL_ROOT"
chmod 0755 "$INSTALL_ROOT" "$INSTALL_ROOT/venv" "$INSTALL_ROOT/venv/bin" "$INSTALL_ROOT/app/"*.sh
chown root:homepage-metrics "$CONFIG_ROOT" "$CONFIG_ROOT/passwords"
chmod 0750 "$CONFIG_ROOT" "$CONFIG_ROOT/passwords"

cat >"/etc/systemd/system/${FIREWALL_SERVICE}.service" <<EOF
[Unit]
Description=Firewall privado Homepage Metrics PROD
Requires=tailscaled.service
After=tailscaled.service
Before=${SERVICE}.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${INSTALL_ROOT}/app/homepage-metrics-agent-prod-firewall.sh start
ExecStop=${INSTALL_ROOT}/app/homepage-metrics-agent-prod-firewall.sh stop
EOF
cat >"/etc/systemd/system/${SERVICE}.service" <<EOF
[Unit]
Description=Glances privado Homepage Metrics PROD
Requires=${FIREWALL_SERVICE}.service
After=network-online.target tailscaled.service ${FIREWALL_SERVICE}.service
[Service]
Type=simple
User=homepage-metrics
Group=homepage-metrics
Environment=HOME=/var/lib/homepage-metrics-agent-prod
StateDirectory=homepage-metrics-agent-prod
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
systemctl enable --now "${FIREWALL_SERVICE}.service" "${SERVICE}.service"
activated=1
deadline=$((SECONDS + 45))
until ss -ltnH | grep -Fq "${TAILSCALE_IP}:61208"; do ((SECONDS < deadline)) || fail 'el agente no abrió 61208 en 45 segundos'; sleep 1; done
"$INSTALL_ROOT/app/Test-HomepageMetricsAgentProd.sh"
trap - EXIT
echo 'Agente de métricas PROD instalado y validado; secreto disponible solo para ab.'
