#!/usr/bin/env bash
set -Eeuo pipefail
readonly CHAIN='HOMEPAGE_METRICS_AGENT_PROD' INTERFACE='tailscale0' PORT='61208' MAC='100.72.206.57'
remove_jump() { while iptables -C INPUT -i "$INTERFACE" -p tcp --dport "$PORT" -j "$CHAIN" 2>/dev/null; do iptables -D INPUT -i "$INTERFACE" -p tcp --dport "$PORT" -j "$CHAIN"; done; }
case "${1:-}" in
 start) iptables -N "$CHAIN" 2>/dev/null || true; iptables -F "$CHAIN"; iptables -A "$CHAIN" -s "$MAC/32" -p tcp --dport "$PORT" -j ACCEPT; iptables -A "$CHAIN" -p tcp --dport "$PORT" -j DROP; iptables -C INPUT -i "$INTERFACE" -p tcp --dport "$PORT" -j "$CHAIN" 2>/dev/null || iptables -I INPUT 1 -i "$INTERFACE" -p tcp --dport "$PORT" -j "$CHAIN" ;;
 stop) remove_jump; iptables -F "$CHAIN" 2>/dev/null || true; iptables -X "$CHAIN" 2>/dev/null || true ;;
 *) echo "usage: $0 {start|stop}" >&2; exit 2 ;;
esac
