#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

"${HOMEPAGE_PROJECT_DIR}/scripts/validate.sh"

tailscale serve status --json | \
    python3 "${HOMEPAGE_PROJECT_DIR}/tests/tailscale_validate.py" legacy

tailscale serve --bg --https=10000 --yes http://127.0.0.1:3000

"${HOMEPAGE_PROJECT_DIR}/scripts/smoke-test.sh"

echo "Homepage publicado de forma privada en:"
echo "https://macmini-server.tailf553c4.ts.net:10000/"
