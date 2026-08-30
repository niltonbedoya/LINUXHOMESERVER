#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOMEPAGE_HOST="macmini-server.tailf553c4.ts.net:10000"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

services_json="$(curl --fail --silent --show-error --retry 10 --retry-all-errors \
    --retry-delay 1 --max-time 10 --header "Host: ${HOMEPAGE_HOST}" \
    http://127.0.0.1:3000/api/services)"
python3 "${HOMEPAGE_PROJECT_DIR}/tests/phase4_validate.py" <<<"${services_json}"

external_urls=(
    'https://chatgpt.com/'
    'https://gemini.google.com/'
    'https://claude.ai/'
    'https://www.perplexity.ai/'
    'https://grok.com/'
    'https://copilot.microsoft.com/'
    'https://chat.mistral.ai/'
    'https://github.com/copilot'
    'https://aistudio.google.com/'
    'https://build.nvidia.com/'
    'https://login.tailscale.com/admin/machines'
    'https://github.com/'
)

for external_url in "${external_urls[@]}"; do
    result="$(curl --silent --show-error --location --noproxy '*' \
        --connect-timeout 8 --max-time 25 --output /dev/null \
        --write-out '%{http_code} %{ssl_verify_result}' "${external_url}")"
    if [[ ! "${result}" =~ ^([23][0-9]{2}|401|403|429)\ 0$ ]]; then
        fail "Enlace externo no válido: ${external_url} (${result})"
    fi
done

kuma_code="$(curl --silent --show-error --noproxy '*' --max-time 10 \
    --output /dev/null --write-out '%{http_code}' http://100.72.206.57:3001/)"
[[ "${kuma_code}" == "200" || "${kuma_code}" == "302" ]] || \
    fail "Uptime Kuma Admin devolvió ${kuma_code}"

echo "Pruebas de herramientas y Administración: OK"
