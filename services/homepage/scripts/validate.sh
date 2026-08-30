#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

for homepage_test in static.sh compose.sh; do
    echo "==> Ejecutando ${homepage_test}"
    "${HOMEPAGE_PROJECT_DIR}/tests/${homepage_test}"
done

echo "Validación de Homepage completada correctamente."

