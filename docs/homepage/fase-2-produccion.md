# Fase 2 — PRODUCCIÓN

Fecha: 29 de agosto de 2026.

Estado: **completada; G2 aprobada por el usuario el 30 de agosto de 2026**.

## Descubrimiento verificado

- La tailnet contiene el nodo Linux `servicio-tickets-definitivo`, con MagicDNS
  `servicio-tickets-definitivo.tailf553c4.ts.net` e IP observada `100.113.199.93`.
- El nodo responde por ICMP y tiene HTTP 80 y SSH 22 accesibles desde la tailnet.
- `https://service-ab-electronic.com/` (singular) responde HTTP 200 con TLS válido y
  presenta `Servicio Tickets`.
- La misma aplicación se obtiene directamente del nodo PROD cuando Caddy recibe
  `Host: service-ab-electronic.com`; esto confirma la relación dominio-origen.
- `service-ab-electronics.com` (plural, escrito en el prompt inicial) no resuelve y no se
  utiliza.
- No se encontró una URL administrativa adicional verificada. No se inventó ninguna.
- No se ha verificado una página de estado pública de Uptime Kuma con `slug`; Kuma
  continúa siendo la fuente de alertas, pero no se añade su widget oficial a PRODUCCIÓN.

## Diseño aplicado

Grupo `🚨 PRODUCCIÓN`, separado visualmente de HOME SERVER y con iconos rojos:

1. `Servidor Ubuntu PROD`: indicador ICMP al MagicDNS privado, sin enlace administrativo.
2. `Tickets PROD`: enlace HTTPS público y `siteMonitor` al dominio singular verificado.

No se añadieron credenciales, secretos, DEV ni herramientas IA. Tampoco se modificaron
el servidor PROD, Uptime Kuma, n8n, OpenClaw, Docker Compose ni Tailscale Serve.

## Pruebas

- Configuración estática: exactamente HOME SERVER y PRODUCCIÓN.
- Runtime `/api/services`: cuatro tarjetas HOME sin cambios y dos tarjetas PROD exactas.
- HTTPS de Tickets PROD: HTTP 200 y verificación TLS 0.
- Nodo PROD: ping correcto desde el contenedor Homepage.
- Identidad: título público y título servido por el origen coincidentes.
- Regresiones completas de Docker proxy, Glances, Tailscale, n8n, Uptime Kuma y OpenClaw.
- Homepage: `healthy`, cero reinicios y sin errores bloqueantes nuevos en logs.

## Backup y rollback

Backup previo ignorado por Git:

```text
services/homepage/backups/20260829-fase-2/
```

Para volver al cierre de la Fase 1, restaurar desde ese directorio únicamente
`services.yaml`, `settings.yaml`, `static.sh` y `smoke-test.sh`; retirar además los tests
`production.sh` y `production_validate.py`. No es necesario tocar Tailscale ni reiniciar
otros servicios. No ejecutar sin petición explícita.

## Puerta G2

El usuario autorizó avanzar a la Fase 3 el 30 de agosto de 2026. G2 queda cerrada.
