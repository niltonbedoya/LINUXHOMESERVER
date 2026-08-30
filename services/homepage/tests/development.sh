#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
services_json="$(curl --fail --silent --show-error --retry 10 --retry-all-errors \
    --retry-delay 1 --max-time 10 --header 'Host: macmini-server.tailf553c4.ts.net:10000' \
    http://127.0.0.1:3000/api/services)"
python3 "${HOMEPAGE_PROJECT_DIR}/tests/development_validate.py" <<<"${services_json}"
echo "Pruebas de interfaz sin accesos DEV: OK"
