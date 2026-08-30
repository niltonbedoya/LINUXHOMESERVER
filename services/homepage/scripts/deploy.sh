#!/usr/bin/env bash
set -Eeuo pipefail

HOMEPAGE_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOMEPAGE_COMPOSE_FILE="${HOMEPAGE_PROJECT_DIR}/compose.yaml"

"${HOMEPAGE_PROJECT_DIR}/scripts/validate.sh"

docker compose \
    --project-directory "${HOMEPAGE_PROJECT_DIR}" \
    -f "${HOMEPAGE_COMPOSE_FILE}" \
    pull

docker compose \
    --project-directory "${HOMEPAGE_PROJECT_DIR}" \
    -f "${HOMEPAGE_COMPOSE_FILE}" \
    up -d

"${HOMEPAGE_PROJECT_DIR}/scripts/smoke-test.sh"
