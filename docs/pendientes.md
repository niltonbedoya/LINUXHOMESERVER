# Pendientes priorizados

## Alta prioridad

- Confirmar visualmente los bloques IA y Administración, sus iconos y los diez enlaces
  antes de iniciar la Fase 5.
- Probar desde otro dispositivo conectado a Tailscale el inicio de sesión, el editor de
  n8n y un workflow que reciba un webhook mediante la nueva URL HTTPS.

## Aplazado: proyecto NAS

- Los backups de OpenClaw, n8n y Uptime Kuma se diseñarán cuando exista un NAS conectado
  a la red.
- El NAS será otro proyecto: una Raspberry Pi con varios discos duros conectados.
- Cuando esté disponible habrá que definir frecuencia, retención, cifrado y pruebas de
  restauración; no basta con copiar los datos.

## Media prioridad

- Probar opcionalmente Homepage desde Android y añadirlo a la pantalla de inicio.
- Volver a probar los modelos NVIDIA desde n8n ahora que HOST y WEBHOOK están corregidos.
- Revisar con calma los avisos de deprecación mostrados por n8n 2.36.8 sobre paquetes no
  verificados, timeout de runners y límites de descompresión. No fijar valores sin decidir
  qué comportamiento se desea conservar.
- Confirmar periódicamente IP LAN, IP Tailscale y funcionamiento del Exit Node.
- Posibles mejoras futuras de `/servidor`: CPU %, ventilador, espacio libre, estado
  individual y semáforos visuales. El comando actual ya funciona y no requiere cambios.
- Diseñar el chatbot WhatsApp + n8n + clasificador de intención + IA + fuentes de
  conocimiento. Verificar primero APIs oficiales y disponibilidad real de NotebookLM.

## Aplicaciones futuras; no instalar sin decisión explícita

Orden histórico considerado:

1. Homepage.
2. AdGuard Home (afecta DNS y toda la red).
3. Syncthing.
4. Vaultwarden (requiere especial cuidado con HTTPS y backups).
5. Paperless-ngx.
6. Home Assistant.
7. Jellyfin.
8. Immich.

Evaluar carga, almacenamiento, seguridad, mantenimiento y backup antes de añadir cada
servicio. El objetivo sigue siendo no sobrecargar el Mac mini.
