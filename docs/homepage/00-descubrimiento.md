# Descubrimiento previo de Homepage

Fecha de inspección: 29 de agosto de 2026.

No se creó ningún directorio, contenedor, red ni regla de Tailscale para Homepage durante
esta inspección.

## Estado real comprobado

| Área | Estado observado |
|---|---|
| Homepage | No existe `/home/bedvil/docker/homepage` ni un contenedor con ese nombre |
| Contenedores | `n8n` y `uptime-kuma` activos |
| n8n | `127.0.0.1:5678`; HTTPS privado en `:8443` mediante Tailscale Serve |
| Uptime Kuma | Publicado por Docker en `0.0.0.0:3001` y `[::]:3001` |
| Redes Docker | `n8n_default` y `uptime-kuma_default`, separadas |
| Tailscale 443 | Proxy existente a `http://127.0.0.1:18789` |
| Tailscale 8443 | Proxy existente a `http://127.0.0.1:5678` |
| Puertos 3000/10000 | Sin listeners durante la inspección |
| MagicDNS | `macmini-server.tailf553c4.ts.net` → `100.72.206.57` |
| Docker socket | `root:docker`, modo `660` |
| Recursos | 15 GiB de RAM; raíz de 916 GiB con 2 % usado en la inspección |
| Git | Repositorio en `main`, pero todavía sin commits; todos los archivos están sin seguimiento |

URLs verificadas desde el host:

- OpenClaw/servicio actual: `https://macmini-server.tailf553c4.ts.net/` → HTTP 200.
- n8n: `https://macmini-server.tailf553c4.ts.net:8443/healthz` → HTTP 200.
- Uptime Kuma: `http://100.72.206.57:3001/` → HTTP 302 hacia su interfaz.

La imagen oficial `ghcr.io/gethomepage/homepage:v2.1.2` existe para `amd64`. La última
release oficial consultada fue v2.1.2, publicada el 21 de agosto de 2026.

## Diferencias entre el prompt y el sistema

| Contexto del prompt | Fuente de verdad encontrada | Consecuencia |
|---|---|---|
| `service-ab-electronics.com` | El monitor activo se llama y apunta a `service-ab-electronic.com` (singular) | No usar el dominio plural sin confirmación |
| Se desea integrar Uptime Kuma | No existe ninguna página de estado en su tabla `status_page` | El widget oficial no puede configurarse aún porque exige un `slug`; se usará enlace + estado Docker |
| Se esperan métricas del Mac mini con Homepage | El widget oficial `resources` muestra CPU/RAM del contenedor | Para métricas reales hay que añadir Glances o renunciar a etiquetarlas como métricas del host |
| Homepage debe vivir en `/home/bedvil/docker/homepage` dentro de un único repositorio | `/home/bedvil/docker` está fuera del Git y `server/docker` es solo un enlace | Los archivos no se versionarían si se crean directamente allí; se propone un directorio versionado con enlace operativo |
| Homepage debe usar HTTPS/Tailscale | Los puertos HTTPS 443 y 8443 ya están ocupados | Se propone Tailscale Serve en 10000, sin sobrescribir reglas existentes |
| Hay servidor PROD y servidor DEV en Tailscale | Se ve `servicio-tickets-definitivo`, pero no un nodo inequívoco de DEV | No se crearán enlaces PROD/DEV hasta identificar y validar ambos destinos |
| Integración Docker montando socket RO si basta | Un socket Unix montado `:ro` sigue exponiendo una API muy privilegiada | Se propone un socket-proxy interno con `POST=0`, sin montar el socket en Homepage |

## Otros hallazgos

- El Mac mini aparece como Exit Node.
- Tailscale avisa de rutas anunciadas mientras `--accept-routes` está desactivado. No es
  un bloqueo para Homepage y no se cambiará durante este proyecto.
- El nodo `servicio-tickets-definitivo` aparece en la tailnet, pero su función exacta y
  sus URLs administrativas deben confirmarse antes de la fase PROD.
- La Raspberry Pi ya aparece en Tailscale, pero el futuro NAS es otro proyecto y queda
  fuera del alcance.

## Decisiones aprobadas

El usuario aprobó el 29 de agosto de 2026:

1. Usar `https://macmini-server.tailf553c4.ts.net:10000/` para Homepage.
2. Mantener el contenido versionado en `/home/bedvil/server/services/homepage` y crear
   `/home/bedvil/docker/homepage` como enlace a ese directorio.
3. Usar `ghcr.io/gethomepage/homepage:v2.1.2`, no `latest`.
4. Usar un docker-socket-proxy con operaciones de escritura deshabilitadas.
5. Incorporar Glances en una subfase independiente para métricas reales del host.
6. Confiar inicialmente en el acceso privado de la tailnet, sin autenticación propia de
   Homepage. La autenticación de Homepage puede evaluarse después.
