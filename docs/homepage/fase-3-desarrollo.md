# Fase 3 — DESARROLLO / DEV

Fecha: 30 de agosto de 2026.

Estado: **completada; G3 aprobada por el usuario**.

## Descubrimiento verificado

- La VM Ubuntu usa red NAT de VirtualBox con dirección interna `10.0.2.15`.
- NAT tenía salida y DNS; Tailscale no estaba instalado/activo en el invitado.
- El usuario instaló y autorizó Tailscale y renombró el nodo para evitar ambigüedad.
- Nodo: `tickets-server-dev.tailf553c4.ts.net`.
- IP Tailscale observada: `100.80.93.74`.
- Usuario SSH informado por el usuario: `nilton`; puerto 22 accesible.
- Frontend: `http://tickets-server-dev.tailf553c4.ts.net:5173/`, HTTP 200 y título
  `Servicio Tickets`.
- Backend Docker canónico: puerto host 18000 hacia el 8000 del contenedor; `/health`
  devuelve HTTP 200 y JSON.
- Swagger: `:18000/docs`, HTTP 200 y título de la API del sistema de tickets.
- Se observó además un Uvicorn independiente en el puerto host 8000. No se modificó ni
  se usa en Homepage porque su propiedad/función no está confirmada.

La VM y PROD son nodos diferentes. DEV no reutiliza el dominio, MagicDNS ni IP de
PRODUCCIÓN.

## Diseño aplicado

Grupo azul `🧪 DESARROLLO / DEV`, separado del grupo rojo de PRODUCCIÓN:

1. `Servidor Ubuntu DEV`: ping al MagicDNS privado.
2. `Tickets DEV`: frontend de pruebas en 5173 con `siteMonitor`.
3. `API DEV`: enlace a Swagger y monitor independiente sobre `/health` en el backend
   Docker 18000.

Las URLs DEV usan HTTP dentro de Tailscale: la aplicación no ofrece TLS propio, pero el
tráfico entre nodos viaja por la tailnet. No se abrió ningún puerto del router ni se
publicó el entorno DEV en Internet.

## Pruebas

- Configuración: exactamente HOME SERVER, PRODUCCIÓN y DESARROLLO / DEV.
- Runtime: tres tarjetas DEV exactas y destinos separados de PROD.
- Ping desde Homepage al nodo DEV.
- Frontend 5173: HTTP 200 y aplicación esperada.
- API Docker 18000 `/health`: HTTP 200 y `application/json`.
- Swagger 18000 `/docs`: interfaz esperada.
- Bundle: contiene MagicDNS `:18000` y rechaza la antigua API `127.0.0.1:18000`.
- CORS: preflight real desde el origen MagicDNS DEV devuelve 200 y `allow-origin` exacto.
- Regresiones completas de PROD, Docker proxy, Glances, Tailscale, n8n, Uptime Kuma y
  OpenClaw.
- Homepage: `healthy`, cero reinicios y sin errores bloqueantes nuevos en logs.

## Backup y rollback

Backup previo, ignorado por Git:

```text
services/homepage/backups/20260830-fase-3/
```

Para volver al cierre de la Fase 2, restaurar desde ese directorio `services.yaml`,
`settings.yaml`, `static.sh`, `production_validate.py` y `smoke-test.sh`; retirar además
`development.sh` y `development_validate.py`. No tocar la VM, PROD ni Tailscale Serve.
No ejecutar sin petición explícita.

## Puerta G3

La primera validación del usuario detectó que el frontend DEV no podía usar el backend.
El diagnóstico confirmó:

- Backend Docker sano en `:18000/health`.
- Bundle del frontend compilado con API base `http://127.0.0.1:18000`.
- CORS admite `http://localhost:5173` y `http://127.0.0.1:5173`.
- CORS rechaza el origen real
  `http://tickets-server-dev.tailf553c4.ts.net:5173` y la IP Tailscale.

Se corrigió `docker-compose.virtualbox.yml` en la VM, previa copia recuperable: el bundle
usa ahora `http://tickets-server-dev.tailf553c4.ts.net:18000` y CORS admite el origen
MagicDNS 5173. Solo se reconstruyeron backend y frontend; PostgreSQL permaneció activo.

El usuario confirmó el 30 de agosto de 2026 que el flujo frontend→backend funciona tras
la corrección. G3 queda aprobada. La Fase 4 requiere una nueva autorización explícita.

## Cambio visual posterior

Durante 5F el usuario retiró de Homepage las tarjetas de acceso DEV para reducir ruido
en el uso diario. La VM, sus endpoints y su agente de métricas no se modificaron;
`Servidor DEV` continúa apareciendo únicamente en `🖥 EQUIPOS`.
