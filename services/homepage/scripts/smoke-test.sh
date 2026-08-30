#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

for homepage_test in runtime.sh docker-proxy.sh metrics.sh production.sh development.sh phase4.sh nilton-pc.sh tailscale.sh regression.sh; do
    echo "==> Ejecutando ${homepage_test}"
    "${HOMEPAGE_PROJECT_DIR}/tests/${homepage_test}"
done

echo "Smoke tests de Homepage completados correctamente."
