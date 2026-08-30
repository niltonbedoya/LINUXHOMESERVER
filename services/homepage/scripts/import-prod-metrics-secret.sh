#!/usr/bin/env bash
set -Eeuo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes \
  ab@servicio-tickets-definitivo.tailf553c4.ts.net \
  'cat /home/ab/.local/share/homepage-metrics-agent-prod/secret' | \
  "${project_dir}/scripts/set-prod-metrics-secret.sh"
