# Operaciones y comprobaciones

Ejecutar primero acciones de solo lectura. Los resultados del sandbox pueden no reflejar
el host para sockets, systemd, red o crontab.

## Inventario rápido

```bash
uname -srm
sed -n '1,12p' /etc/os-release
docker --version
docker compose version
systemctl is-active tailscaled
```

## Servicios Docker

```bash
docker ps --format '{{.Names}} | {{.Status}}'
docker compose -f /home/bedvil/docker/n8n/compose.yaml config --quiet
docker compose -f /home/bedvil/docker/uptime-kuma/compose.yaml config --quiet
```

Comprobación HTTPS de n8n:

```bash
curl --fail https://macmini-server.tailf553c4.ts.net:8443/healthz
tailscale serve status
```

El monitor `n8n` de Uptime Kuma debe usar esta URL y no la antigua dirección LAN:

```text
https://macmini-server.tailf553c4.ts.net:8443/healthz
```

La copia previa a la migración HTTPS se guardó como
`/home/bedvil/docker/n8n/compose.yaml.bak-20260829-https-tailscale`.

Antes de cualquier cambio Compose:

1. leer el archivo completo;
2. comprobar que no contiene secretos que puedan acabar en Git o en la conversación;
3. respaldar configuración y datos;
4. validar con `docker compose ... config --quiet`;
5. actuar solo sobre el proyecto solicitado.

## Métricas del host

```bash
uptime -p
head -c 160 /proc/loadavg
free -h
df -hP /
sensors
```

Para CPU se usa `Package id 0` de `coretemp`, no lecturas atípicas de Apple SMC.

## Bot de Telegram

Comprobaciones de solo lectura:

```bash
ps -eo user,pid,ppid,lstart,args | grep -E '[t]elegram_bot\.(py|sh)'
crontab -l
tail -n 100 /home/bedvil/.openclaw/workspace/telegram_bot.log
```

El bot puede no aparecer entre iteraciones. El arranque vigente se realiza mediante
crontab y `telegram_bot_loop.sh`. Consultar `docs/openclaw-telegram.md` antes de tocarlo.

## Backups aplazados hasta disponer del NAS

Datos prioritarios:

- `/home/bedvil/.openclaw/workspace`
- `/home/bedvil/docker/n8n/n8n_data`
- `/home/bedvil/docker/uptime-kuma/uptime-kuma-data`

La estrategia se desarrollará como parte de otro proyecto: un NAS de red construido con
una Raspberry Pi y varios discos duros. Cuando esté disponible deberá especificar destino,
frecuencia, retención, cifrado, exclusión segura de ficheros en uso y prueba de
restauración. Una copia no está validada hasta probar una restauración.

## Uptime Kuma: monitor registrado

Service AB Electronic debe monitorizarse en Uptime Kuma, no en OpenClaw:

- Tipo: HTTP(s) Keyword.
- URL: `https://service-ab-electronic.com/login`.
- Palabra: `Servicio Tickets`.
- Intervalo histórico: unos 60 segundos.
- Reintentos: 3.
- Notificación: Telegram.
