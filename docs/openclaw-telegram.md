# OpenClaw y bot de Telegram

> Área protegida: esta documentación no autoriza cambios dentro de `openclaw/`. Solo se
> modifica ese destino cuando el usuario lo pide explícitamente.

## Rutas y ejecución

- Workspace real: `/home/bedvil/.openclaw/workspace`.
- Enlace de consulta: `/home/bedvil/server/openclaw`.
- Implementación usada: `telegram_bot.py`.
- Lanzador: `telegram_bot_loop.sh`, iniciado por crontab con `@reboot`.
- Archivos relacionados conocidos: `TOOLS.md`, `todolist.md`, `.telegram_offset` y log.

Los secretos de Telegram se leen de `TOOLS.md`; nunca deben copiarse a documentación,
código nuevo, logs compartidos ni Git.

## Comandos deseados

- `/start`
- `/help`
- `/tareas`
- `/servidor`

`/estado` fue retirado conceptualmente porque Uptime Kuma asumió la monitorización del
servicio web. El archivo Python observado aún lo menciona en la ayuda, una inconsistencia
pendiente si el usuario autoriza editar OpenClaw.

`/tareas` lee `todolist.md` y debe preservarse intacto.

La última respuesta histórica que motivó la tarea mostraba uptime, Internet y Tailscale,
pero devolvía `N/D` para carga, RAM, disco, temperatura y Docker. Posteriormente el usuario
confirmó que `/servidor` funciona correctamente. Se considera terminado y no debe tocarse
sin una nueva petición explícita.

## Objetivo de `/servidor`

La respuesta buscada es compacta y debe incluir:

```text
🖥️ MAC MINI

🟢 Estado: Online
⏱ Uptime: …
⚙️ Carga: …
🧠 RAM: usada / total
💾 Disco: usado / total (porcentaje)
🌡 CPU: … °C

🐳 DOCKER
🟢 n8n — estado
🟢 uptime-kuma — estado

🌐 RED
🟢 Internet
🟢 Tailscale
```

Fuentes apropiadas ya comprobadas:

- Uptime: `uptime -p`.
- Carga: tres primeros campos de `/proc/loadavg`.
- RAM: `/proc/meminfo` o `free -h`.
- Disco: `df -hP /`.
- CPU: `sensors`, priorizando exactamente `Package id 0` de `coretemp`.
- Docker: `docker ps --format ...`, sin `sudo`.
- Tailscale: `systemctl is-active tailscaled`.
- Internet: ping breve; distinguir `Offline` de error de herramienta cuando sea posible.

No usar sensores anómalos de `applesmc` (`-127 °C`, valores cercanos a 98 °C, etc.) para
representar la temperatura de CPU.

## Procedimiento seguro para cambios futuros

1. Confirmar que el usuario ha pedido modificar OpenClaw.
2. Leer completo `telegram_bot.py` y el loop real.
3. Comprobar dependencias y permisos bajo `bedvil` fuera del sandbox si es necesario.
4. Crear un backup con fecha o una copia `.bak` antes de editar.
5. Hacer el cambio mínimo; conservar token/chat, polling, offsets y `/tareas`.
6. Validar con `python3 -m py_compile` y el loop con `bash -n` si se toca.
7. Identificar el proceso exacto antes de reiniciar; no reiniciar servicios ajenos.
8. Probar `/servidor` desde Telegram y revisar el log sin exponer secretos.

Mejoras posteriores posibles: CPU %, ventilador, espacio disponible, estados visuales y
mostrar solo datos útiles.
