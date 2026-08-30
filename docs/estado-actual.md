# Estado actual

Última revisión: 30 de agosto de 2026, zona `Europe/Madrid`.

Este documento separa lo observado directamente en el host de lo heredado del contexto
histórico. Los valores dinámicos deben volver a comprobarse antes de tomar decisiones.

## Verificado directamente

| Elemento | Estado observado |
|---|---|
| Sistema | Linux Mint 22.3 (Zena), kernel 6.14.0-37-generic x86_64 |
| Docker | 29.1.3 |
| Docker Compose | 2.40.3 |
| n8n | contenedor activo, `Up 10 hours` durante la revisión |
| Uptime Kuma | contenedor activo y healthy, `Up 10 hours` durante la revisión |
| Tailscale | servicio `active` |
| HTTPS de n8n | activo en `https://macmini-server.tailf553c4.ts.net:8443` |
| Bot Telegram | crontab `@reboot` ejecuta `telegram_bot_loop.sh` |
| Comando `/servidor` | funcionamiento correcto confirmado por el usuario |
| Docker para `bedvil` | acceso confirmado fuera del sandbox; usuario en grupo `docker` |
| Homepage | v2.1.2 healthy; HTTPS privado activo en `https://macmini-server.tailf553c4.ts.net:10000/`; diez grupos configurados, incluido Nilton PC |

El lanzador observado es:

```text
@reboot cd /home/bedvil/.openclaw/workspace && ./telegram_bot_loop.sh >/dev/null 2>&1
```

No es obligatorio ver un proceso `telegram_bot.py` permanente: el script Python hace
una consulta de actualizaciones y termina, mientras el loop externo vuelve a invocarlo.

## Métricas comprobadas durante la revisión

- `uptime -p`: funcionó.
- `/proc/loadavg`: proporcionó las tres cargas.
- `/proc/meminfo` y `free -h`: funcionaron; se observaron unos 15 GiB totales.
- `df -hP /`: funcionó; raíz de 916 GiB y 2 % usado en ese momento.
- `sensors`: expuso `Package id 0` desde `coretemp` (48 °C en ese momento).
- `docker ps`: mostró `n8n` y `uptime-kuma` fuera del sandbox.

El sandbox de Codex devolvió errores falsos al acceder al socket Docker, systemd, netlink
y crontab. No diagnosticar esos errores como fallos del host sin repetir la comprobación
con acceso apropiado.

## Estado heredado que debe verificarse si resulta relevante

- IP LAN registrada: `192.168.1.43`.
- IP Tailscale registrada: `100.72.206.57`.
- El Mac mini funciona como Exit Node.
- SSH con clave ED25519 desde el alias Windows `macmini` funciona sin contraseña.
- Uptime Kuma tiene notificaciones de Telegram activadas.
- El monitor de Service AB Electronic estaba funcionando.
- El workflow básico de Gemini en n8n funcionaba.

## Diferencias encontradas respecto al contexto antiguo

- El archivo real `openclaw/telegram_bot.py` ya contenía una implementación parcial de
  `/servidor` que lee carga y memoria desde `/proc`, usa `df`, `sensors` y `docker ps`.
- Su texto de `/help` seguía mencionando `/estado` y omitía `/servidor` durante la
  inspección. No se corrigió porque OpenClaw quedó fuera de alcance por orden del usuario.
- `bedvil` sí pertenece actualmente al grupo `docker`; la consulta real a Docker funciona.
- El bot se mantiene mediante `telegram_bot_loop.sh` desde crontab, no como servicio
  systemd permanente.

## Confirmaciones posteriores

- El usuario confirmó que `/servidor` ya funciona correctamente. Su implementación se
  considera estable y no debe modificarse sin una nueva petición explícita.
- Los backups quedan aplazados hasta construir un NAS independiente basado en Raspberry
  Pi con varios discos. Ese NAS se gestionará como otro proyecto.
- n8n quedó publicado de forma privada mediante Tailscale Serve en el puerto HTTPS 8443.
  La prueba `/healthz` devolvió HTTP 200 con certificado válido. El puerto Docker 5678
  quedó ligado únicamente a `127.0.0.1`.
- El puerto HTTPS 443 ya estaba asignado a otro servicio local en `127.0.0.1:18789` y se
  conservó intacto; respondió HTTP 200 después del cambio.
- El monitor `n8n` de Uptime Kuma se actualizó a
  `https://macmini-server.tailf553c4.ts.net:8443/healthz`. El usuario confirmó que volvió
  a funcionar correctamente.
- Homepage quedó publicado mediante Tailscale Serve en HTTPS 10000 hacia
  `127.0.0.1:3000`. El certificado, healthcheck, aislamiento LAN y las regresiones de
  443/8443 se validaron automáticamente. El usuario confirmó después que funciona desde
  el cliente; la Fase 1 está cerrada.
- La Fase 2 añadió PRODUCCIÓN sin reiniciar Homepage. El nodo privado
  `servicio-tickets-definitivo.tailf553c4.ts.net` responde a ping desde Homepage y el
  dominio real `https://service-ab-electronic.com/` responde HTTP 200 con TLS válido.
  El dominio plural del prompt no resuelve y no se utilizó.
- La Fase 3 añadió la VM `tickets-server-dev` (`100.80.93.74`) y verificó frontend 5173,
  backend Docker y Swagger 18000. La validación funcional detectó una API loopback y CORS
  antiguo; ambos se corrigieron y las pruebas de bundle/preflight pasan. Homepage recargó
  la tarjeta canónica 18000 sin reinicios. El usuario confirmó después el funcionamiento
  real frontend→backend; G3 está cerrada.
- La Fase 4 se amplió a grupos separados de LLM/chat, IDE, agentes/CLI, terminales,
  plataformas IA y Administración. Homepage sigue healthy y todas las pruebas del
  servidor pasan.
- El protocolo local `homeserver-launch://` está instalado y validado en Windows
  PowerShell 5.1. El catálogo final tiene 13 destinos; Windows Terminal se retiró por
  duplicar PowerShell y OpenCode abre correctamente una Tab Config fija de Warp con Bash
  y `opencode.cmd`. El usuario confirmó el resto de aplicaciones, fallbacks, iconos y
  distribución; G4 y la Fase 4 quedan cerradas.
- La Fase 5A verificó en Tailscale cuatro objetivos de métricas: `Nilton-PC`
  (`100.105.88.14`), DEV (`100.80.93.74`), Raspberry Pi (`100.65.215.4`) y PROD
  (`100.113.199.93`). Todos estaban online; la IP es solo evidencia y MagicDNS será el
  identificador operativo.
- Ninguno de esos cuatro equipos exponía Glances 61208 al contenedor Homepage. No se
  instaló nada todavía. El teléfono queda excluido para evitar consumo de batería.
- La Raspberry Pi actual existe y está online; esto no cambia que los discos, backups y
  diseño del futuro NAS pertenezcan a otro proyecto.
- Al iniciar 5B, Nilton PC respondió a `tailscale ping`, pero rechazó TCP 22. No se
  habilitó SSH: se preparó un inventario PowerShell local y no se aplicaron cambios al PC.
- El inventario 5B confirmó Windows 11 Pro, PowerShell 5.1, Tailscale `100.105.88.14`,
  Glances ausente y 61208 libre. La sesión no estaba elevada. `py.exe` conserva una
  entrada 3.13 rota; el Python privado de Hermes no se tocará y se validará por separado
  la CPython 3.11.15 registrada por `uv` antes de instalar.
- La CPython 3.11.15 de `uv` quedó validada y el bundle 5B usa Glances 4.5.6,
  autenticación, listener/firewall Tailscale, tarea de inicio, pruebas y rollback.
- El agente 5B está instalado y sus pruebas locales pasan: CPU, RAM, disco, uptime,
  allowlist y privacidad. Escucha solo en `100.105.88.14:61208`; el firewall acepta
  únicamente al Mac mini `100.72.206.57`.
- El secreto se transfirió por stdin de SSH y quedó en `services/homepage/.env`, modo
  600, ignorado por Git. La inspección comprobó solo estructura y permisos, no valores.
- Homepage se recreó de forma exclusiva, quedó healthy y sin reinicios. La tarjeta
  compacta Nilton PC usa MagicDNS, autenticación y muestra CPU/RAM; la prueba remota
  validó también disco, uptime, rechazo anónimo y ausencia de plugins de procesos.
- La regresión completa posterior pasó para Homepage, n8n, Kuma, OpenClaw, PROD, DEV y
  Tailscale. Quedan la confirmación visual del usuario y la prueba manual de caída
  aislada antes de cerrar formalmente G5B.
- Se ha configurado GitHub Actions CI (`.github/workflows/ci.yml`) para ejecutar
  automáticamente en GitHub la validación estática, seguridad, Compose, unit tests de
  validadores sintéticos (`ci_synthetic_test.py`), scripts de PowerShell y health checks
  de URLs externas en cada `push` y `pull_request`.

