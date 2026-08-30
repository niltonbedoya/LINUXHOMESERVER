# Arquitectura

## Host

- Equipo: Mac mini 2014.
- Sistema: Linux Mint.
- Memoria: 16 GB físicos (el sistema presenta aproximadamente 15 GiB utilizables).
- Disco: 1 TB; la raíz está en `/dev/sda2` con unos 916 GiB utilizables.
- Usuario operativo: `bedvil`.
- Zona horaria: `Europe/Madrid`.

## Mapa lógico

```text
Mac mini / Linux Mint
├── Tailscale (acceso remoto y Exit Node)
├── SSH (principalmente sobre Tailscale)
├── OpenClaw
│   └── Bot de Telegram
└── Docker
    ├── n8n :5678
    ├── Uptime Kuma :3001
    └── Homepage :3000
```

## Workspace central

`/home/bedvil/server` es el directorio que se abre mediante VS Code Remote SSH. Contiene:

- `openclaw` → `/home/bedvil/.openclaw/workspace`.
- `docker` → `/home/bedvil/docker`.
- documentación y reglas que coordinan el proyecto completo.

Los enlaces simbólicos conservan una vista conjunta, pero sus destinos siguen siendo
árboles operativos externos. Git registra el enlace, no recorre ni incorpora su destino.

## Servicios Docker

### n8n

- Compose: `/home/bedvil/docker/n8n/compose.yaml`.
- Contenedor: `n8n`.
- Imagen actual declarada: `docker.n8n.io/n8nio/n8n:latest`.
- Reinicio: `unless-stopped`.
- Puerto interno: 5678, publicado solo en `127.0.0.1:5678`.
- Datos: `/home/bedvil/docker/n8n/n8n_data`.
- Acceso actual: `https://macmini-server.tailf553c4.ts.net:8443`, solo en la tailnet.
- Acceso LAN anterior, retirado: `http://192.168.1.43:5678`.

Tailscale termina TLS y reenvía a `http://127.0.0.1:5678`. n8n anuncia el dominio
MagicDNS con HTTPS, usa el puerto externo 8443 para editor y webhooks, confía en un proxy
con `N8N_PROXY_HOPS=1`, usa `Europe/Madrid` y mantiene cookies seguras activadas.

El volumen tuvo anteriormente problemas de permisos que se corrigieron asignando el
ownership adecuado al UID 1000. No cambiar ownership de forma recursiva sin revisar el
usuario efectivo del contenedor y preparar una recuperación.

### Uptime Kuma

- Compose: `/home/bedvil/docker/uptime-kuma/compose.yaml`.
- Contenedor: `uptime-kuma`.
- Imagen actual declarada: `louislam/uptime-kuma:1`.
- Reinicio: `unless-stopped`.
- Puerto: 3001.
- Datos: `/home/bedvil/docker/uptime-kuma/uptime-kuma-data`.
- Acceso LAN histórico: `http://192.168.1.43:3001`.

El contexto histórico indica que el administrador inicial ya fue creado.

### Homepage

- Configuración: `/home/bedvil/server/services/homepage`.
- Ruta operativa: `/home/bedvil/docker/homepage` (enlace al directorio versionado).
- Imagen: `ghcr.io/gethomepage/homepage:v2.1.2`.
- Puerto Docker: `127.0.0.1:3000`, sin exposición directa por LAN.
- Acceso actual: `https://macmini-server.tailf553c4.ts.net:10000/`, solo en la tailnet.
- Estado Docker: proxy v0.5.0 en red interna, GET/HEAD de contenedores y `POST=0`.
- Métricas: Glances 4.5.6 en otra red interna, sin puertos ni socket Docker.
- Métricas verificadas: CPU, RAM, disco, uptime y temperatura CPU `Package id`.
- Grupos: HOME SERVER, PRODUCCIÓN, DESARROLLO / DEV, INTELIGENCIA ARTIFICIAL y
  ADMINISTRACIÓN.

## Tailscale Serve

- `https://macmini-server.tailf553c4.ts.net/` (443) → `http://127.0.0.1:18789`.
- `https://macmini-server.tailf553c4.ts.net:8443/` → `http://127.0.0.1:5678` (n8n).
- `https://macmini-server.tailf553c4.ts.net:10000/` → `http://127.0.0.1:3000`
  (Homepage).

Los tres endpoints son privados para la tailnet. No confundir Tailscale Serve con Funnel;
no se habilitó exposición pública.

## Servidor Ubuntu PRODUCCIÓN

- Nodo Tailscale: `servicio-tickets-definitivo.tailf553c4.ts.net`.
- Sistema público: `https://service-ab-electronic.com/`.
- El dominio público y el origen privado sirven la misma aplicación `Servicio Tickets`.
- Homepage comprueba el nodo mediante ICMP privado y el servicio mediante HTTPS público.
- No se ha identificado una URL administrativa segura adicional.

## Servidor Ubuntu DESARROLLO

- VM VirtualBox con red NAT y Tailscale instalado dentro del invitado.
- Nodo: `tickets-server-dev.tailf553c4.ts.net`; IP observada `100.80.93.74`.
- SSH: usuario `nilton`, puerto 22.
- Frontend privado: HTTP 5173.
- Backend Docker privado: HTTP 18000 en el host hacia 8000 del contenedor; healthcheck
  `/health` y Swagger `/docs`.
- Existe un Uvicorn adicional en el puerto host 8000; no se usa ni se modificó porque su
  función no está confirmada.
- No comparte dominio, MagicDNS ni dirección con PRODUCCIÓN.

## Automatización e IA

Homepage funciona como launchpad de enlaces para ChatGPT, Codex, Antigravity, GitHub
Copilot, Google AI Studio, Gemini y NVIDIA Build. No ejecuta modelos ni almacena claves;
la autenticación ocurre en cada proveedor.

En n8n existe un workflow básico comprobado históricamente:

```text
When chat message received → AI Agent → Google Gemini Chat Model
```

El modelo que funcionó fue `gemini-3.5-flash`. Las pruebas anteriores con Gemini 2.5
Flash dieron problemas. También existe acceso a modelos NVIDIA; deben probarse de nuevo
porque los fallos pudieron deberse a la antigua configuración HOST/WEBHOOK de n8n.

Modelos NVIDIA registrados en el contexto histórico:

- `nvidia/minimaxai/minimax-m2.5`
- `nvidia/minimaxai/minimax-m2.7`
- `nvidia/moonshotai/kimi-k2.5`
- `nvidia/nemotron-3-super-120b-a12b`
- `nvidia/nemotron-3-ultra-550b-a55b`
- `nvidia/z-ai/glm-5.1`
- `nvidia/z-ai/glm5`
