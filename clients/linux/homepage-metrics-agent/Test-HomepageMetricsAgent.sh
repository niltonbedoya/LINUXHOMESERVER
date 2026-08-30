#!/usr/bin/env bash
set -Eeuo pipefail

exec /opt/homepage-metrics-agent/venv/bin/python \
    /opt/homepage-metrics-agent/app/Test-HomepageMetricsAgent.py
