#!/usr/bin/env bash
set -Eeuo pipefail
exec /opt/homepage-metrics-agent-prod/venv/bin/python /opt/homepage-metrics-agent-prod/app/Test-HomepageMetricsAgentProd.py
