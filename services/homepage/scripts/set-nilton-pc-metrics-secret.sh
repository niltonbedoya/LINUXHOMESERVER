#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOMEPAGE_ENV_FILE="${HOMEPAGE_PROJECT_DIR}/.env"
HOMEPAGE_BACKUP_DIR="${HOMEPAGE_PROJECT_DIR}/backups/20260830-fase-5b-nilton-pc"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

umask 077
secret=''
IFS= read -r secret || fail "No se recibió el secreto por stdin"
secret="${secret%$'\r'}"

[[ "${secret}" =~ ^[A-Za-z0-9_-]{43}$ ]] || \
    fail "El secreto no tiene el formato esperado; no se escribió ningún archivo"

install -d -m 700 "${HOMEPAGE_BACKUP_DIR}"
if [[ -e "${HOMEPAGE_ENV_FILE}" ]]; then
    cp -a --update=none "${HOMEPAGE_ENV_FILE}" \
        "${HOMEPAGE_BACKUP_DIR}/.env.before-nilton-pc" || true
fi

temporary_file="$(mktemp "${HOMEPAGE_PROJECT_DIR}/.env.tmp.XXXXXX")"
cleanup() {
    secret=''
    if [[ -n "${temporary_file:-}" && -e "${temporary_file}" ]]; then
        unlink "${temporary_file}"
    fi
}
trap cleanup EXIT

if [[ -e "${HOMEPAGE_ENV_FILE}" ]]; then
    awk '!/^HOMEPAGE_VAR_NILTON_PC_GLANCES_(USERNAME|PASSWORD)=/' \
        "${HOMEPAGE_ENV_FILE}" >"${temporary_file}"
fi

{
    printf '%s\n' 'HOMEPAGE_VAR_NILTON_PC_GLANCES_USERNAME=homepage'
    printf 'HOMEPAGE_VAR_NILTON_PC_GLANCES_PASSWORD=%s\n' "${secret}"
} >>"${temporary_file}"

chmod 600 "${temporary_file}"
mv -f "${temporary_file}" "${HOMEPAGE_ENV_FILE}"
temporary_file=''
secret=''

echo "Secreto local de Nilton PC guardado con modo 600; contenido no mostrado."
