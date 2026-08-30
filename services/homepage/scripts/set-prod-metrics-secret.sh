#!/usr/bin/env bash
set -Eeuo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${project_dir}/.env"
backup_dir="${project_dir}/backups/20260830-fase-5e-prod"
fail() { echo "ERROR: $*" >&2; exit 1; }
umask 077
secret=''
IFS= read -r secret || fail 'No se recibió el secreto PROD por stdin'
secret="${secret%$'\r'}"
[[ "$secret" =~ ^[A-Za-z0-9_-]{43}$ ]] || fail 'El secreto PROD no tiene el formato esperado'
install -d -m 700 "$backup_dir"
[[ -e "$env_file" ]] && cp -a --update=none "$env_file" "$backup_dir/.env.before-prod" || true
temporary_file="$(mktemp "${project_dir}/.env.tmp.XXXXXX")"
cleanup() {
    secret=''
    [[ -n "${temporary_file:-}" && -e "$temporary_file" ]] && unlink "$temporary_file"
    return 0
}
trap cleanup EXIT
[[ -e "$env_file" ]] && awk '!/^HOMEPAGE_VAR_PROD_GLANCES_(USERNAME|PASSWORD)=/' "$env_file" >"$temporary_file"
{
  printf '%s\n' 'HOMEPAGE_VAR_PROD_GLANCES_USERNAME=homepage'
  printf 'HOMEPAGE_VAR_PROD_GLANCES_PASSWORD=%s\n' "$secret"
} >>"$temporary_file"
chmod 600 "$temporary_file"
mv -f "$temporary_file" "$env_file"
temporary_file=''; secret=''
echo 'Secreto local PROD guardado con modo 600; contenido no mostrado.'
