# Homepage Metrics Agent — Linux / DEV

Paquete específico de Fase 5C para `tickets-server-dev`. No modifica el proyecto
Servicio Tickets ni sus contenedores.

- Glances 4.5.6 dentro de `/opt/homepage-metrics-agent/venv`.
- Usuario de sistema sin login `homepage-metrics`.
- Servicio systemd y firewall propios; escucha únicamente en `100.80.93.74:61208`.
- `iptables` permite solo a `100.72.206.57` por `tailscale0`; no habilita UFW.
- Plugins mínimos: quicklook, system, CPU, RAM, filesystem y uptime.
- Contraseña generada localmente; hash para Glances y copia 600 disponible solo para
  `nilton`, que la transferirá al Mac mini mediante stdin SSH.

Instalación (tras copiar este directorio a DEV):

```bash
sudo ./Install-HomepageMetricsAgent.sh
```

Prueba posterior:

```bash
sudo /opt/homepage-metrics-agent/app/Test-HomepageMetricsAgent.sh
```

Rollback recuperable:

```bash
sudo /opt/homepage-metrics-agent/app/Uninstall-HomepageMetricsAgent.sh
```

Si una prueba de instalación falla, sus unidades y cadena firewall se retiran y las
rutas operativas se conservan con un sufijo `.failed-*` para diagnóstico.
