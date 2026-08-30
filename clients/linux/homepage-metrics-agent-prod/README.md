# Homepage Metrics Agent — Linux / PROD

Paquete específico para `servicio-tickets-definitivo`. No modifica Docker, Tickets ni
ningún puerto existente. Instala Glances 4.5.6 en un venv aislado, con listener exclusivo
en `100.113.199.93:61208` y firewall iptables que solo permite al Mac mini
`100.72.206.57` por Tailscale.

Se instala únicamente tras la puerta SSH y el backup documentado:

```bash
sudo ./Install-HomepageMetricsAgentProd.sh
```

Prueba y rollback recuperable:

```bash
sudo /opt/homepage-metrics-agent-prod/app/Test-HomepageMetricsAgentProd.sh
sudo /opt/homepage-metrics-agent-prod/app/Uninstall-HomepageMetricsAgentProd.sh
```
