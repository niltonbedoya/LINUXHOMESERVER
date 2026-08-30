#!/usr/bin/env bash
set -Eeuo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ssh -o BatchMode=yes -o ConnectTimeout=10 nilton@tickets-server-dev.tailf553c4.ts.net \
    'cat /home/nilton/.local/share/homepage-metrics-agent/secret' | \
    "${project_dir}/scripts/set-dev-metrics-secret.sh"
