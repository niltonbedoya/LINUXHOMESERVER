# SDD — Homepage para el Mac mini

Estado: **primera entrega completada y confirmada por el usuario**.

## 1. Objetivo

Crear un portal privado, persistente y mantenible para acceder a los servicios del Mac
mini. La primera entrega solo mostrará HOME SERVER y métricas básicas reales. Uptime Kuma
seguirá siendo la fuente de monitorización, histórico y alertas.

## 2. Alcance de la primera entrega

- Homepage ejecutado con Docker Compose.
- Acceso local de la aplicación solo por `127.0.0.1:3000`.
- Acceso remoto privado por Tailscale Serve en HTTPS 10000.
- Tarjetas para n8n, Uptime Kuma, OpenClaw y administración de Tailscale.
- Estado de contenedores mediante un proxy Docker de solo lectura lógica.
- CPU, memoria, disco, temperatura si es fiable y uptime reales del Mac mini mediante
  Glances.
- Configuración legible, persistente, versionable y sin credenciales.
- Pruebas automáticas de configuración, ejecución, conectividad y aislamiento.

## 3. Fuera de alcance

- PROD, DEV, herramientas IA y enlaces administrativos adicionales.
- Modificar los Compose o datos de n8n y Uptime Kuma.
- Modificar OpenClaw, Tailscale existente o SSH.
- Crear una página de estado de Uptime Kuma.
- Abrir puertos del router, usar Tailscale Funnel o publicar Homepage en Internet.
- Crear una APK; Android usará navegador/PWA en una fase posterior.
- Resolver el proyecto de backups/NAS.

## 4. Requisitos

### Funcionales

- **FR-01:** Homepage debe responder localmente en `127.0.0.1:3000`.
- **FR-02:** debe responder desde la tailnet en
  `https://macmini-server.tailf553c4.ts.net:10000/` con TLS válido.
- **FR-03:** la pantalla inicial solo debe contener HOME SERVER.
- **FR-04:** n8n debe enlazar a su URL HTTPS actual en 8443.
- **FR-05:** OpenClaw debe enlazar al servicio HTTPS actual en 443.
- **FR-06:** Uptime Kuma debe enlazar a su dirección Tailscale actual en 3001.
- **FR-07:** debe mostrarse el estado de `n8n` y `uptime-kuma` obtenido de Docker.
- **FR-08:** debe mostrar métricas del host, no métricas mal etiquetadas del contenedor.
- **FR-09:** Uptime Kuma debe conservar la responsabilidad de alertas e histórico.

### No funcionales

- **NFR-01:** ningún cambio sobre n8n, Uptime Kuma, OpenClaw o SSH.
- **NFR-02:** no sobrescribir Tailscale Serve 443 ni 8443.
- **NFR-03:** no montar `/var/run/docker.sock` dentro de Homepage.
- **NFR-04:** el socket-proxy debe prohibir POST y no publicar su puerto en el host.
- **NFR-05:** usar tags de imagen fijados y registrar sus digests al desplegar.
- **NFR-06:** no almacenar API keys, tokens o contraseñas en YAML versionado.
- **NFR-07:** todo cambio debe pasar pruebas y una puerta de aprobación.
- **NFR-08:** el contenedor Homepage no debe publicar 3000 en `0.0.0.0` ni `[::]`.
- **NFR-09:** `HOMEPAGE_ALLOWED_HOSTS` debe contener el host exacto con `:10000`; nunca `*`.

## 5. Diseño de rutas y persistencia

Propuesta para conservar un único repositorio:

```text
/home/bedvil/server/services/homepage/       # contenido real y versionado
├── compose.yaml
├── config/
├── scripts/
└── tests/

/home/bedvil/docker/homepage
    -> /home/bedvil/server/services/homepage
```

El enlace mantiene la ruta operativa solicitada. Su creación forma parte de la Fase 1A.

## 6. Arquitectura propuesta

```text
Dispositivo de la tailnet
        │ HTTPS :10000
        ▼
Tailscale Serve (host)
        │ HTTP 127.0.0.1:3000
        ▼
Homepage v2.1.2
   │                    │
   │ red interna        │ red interna
   ▼                    ▼
docker-socket-proxy     Glances API
   │ GET limitado          │ métricas host RO
   ▼                       ▼
/var/run/docker.sock    /proc, /sys y raíz montada RO
```

### Homepage

- Imagen propuesta: `ghcr.io/gethomepage/homepage:v2.1.2`.
- Puerto: `127.0.0.1:3000:3000`.
- Configuración: `./config:/app/config`.
- `HOMEPAGE_ALLOWED_HOSTS=macmini-server.tailf553c4.ts.net:10000`.
- Sin Docker socket y sin secretos.
- Política de reinicio: `unless-stopped`.

### Docker socket proxy

- Único componente con `/var/run/docker.sock:/var/run/docker.sock:ro`.
- `CONTAINERS=1` y `POST=0`; permisos adicionales desactivados por defecto.
- Puerto 2375 solo dentro de una red Docker interna, sin `ports:` al host.
- Homepage consultará `dockerproxy:2375` desde `docker.yaml`.
- Imagen validada: `ghcr.io/tecnativa/docker-socket-proxy:v0.5.0`.

El montaje RO protege el archivo del socket, pero no limita por sí solo los métodos de la
API. La protección efectiva es `POST=0` y el aislamiento de red.

### Glances

- Subfase separada y contenedor sin puerto publicado al host.
- API disponible solo para Homepage en la red interna.
- Montajes de host estrictamente RO; no necesita el socket Docker para CPU/RAM/disco.
- Imagen validada: `nicolargo/glances:4.5.6-full`.
- Usa `pid: host`, `/sys:ro`, `/etc/os-release:ro` y el repositorio como `/hostfs:ro`.
  No monta la raíz completa ni el socket Docker.
- CPU, RAM, disco, uptime y `Package id` se validaron frente al host.

## 7. Configuración inicial visible

Grupo único `🏠 HOME SERVER`:

| Tarjeta | URL inicial | Estado adicional |
|---|---|---|
| n8n | `https://macmini-server.tailf553c4.ts.net:8443/` | estado Docker |
| Uptime Kuma | `http://100.72.206.57:3001/` | estado Docker; sin widget Kuma |
| OpenClaw | `https://macmini-server.tailf553c4.ts.net/` | enlace únicamente |
| Tailscale | `https://login.tailscale.com/admin/machines` | enlace administrativo |

No se usará el widget oficial de Uptime Kuma hasta que exista una página de estado con
slug y el usuario autorice esa configuración.

## 8. Seguridad

- El control de acceso inicial será la tailnet; no se habilitará Funnel.
- Homepage 2.x permite autenticación propia, pero no se activará en la primera entrega
  para no crear contraseñas en esta fase. Se puede añadir después con secretos fuera de
  Git.
- El proxy Docker no tendrá puerto de host ni operaciones POST.
- Glances no tendrá puerto de host ni credenciales porque solo será accesible por la red
  interna de Compose.
- El dashboard no contendrá claves de n8n, Uptime Kuma, Tailscale ni herramientas IA.
- Los links con HTTP se limitarán a servicios privados ya existentes; Homepage seguirá
  servido por HTTPS.

## 9. Disponibilidad y rollback

- Homepage es un componente nuevo: detenerlo no afecta los servicios enlazados.
- Cada subfase guardará evidencia de `docker compose config`, `ps`, logs y smoke tests.
- Antes de cambiar archivos ya existentes de Homepage se crearán backups fechados.
- Para retirar el acceso HTTPS de Homepage se desactivará solo la regla 10000; nunca se
  usará `tailscale serve reset` porque borraría 443 y 8443.
- El rollback no tocará n8n, Uptime Kuma ni OpenClaw.

## 10. Observabilidad

- Uptime Kuma continuará realizando monitorización y alertas.
- Homepage mostrará visión general y accesos; un indicador visual no sustituye una alerta.
- Tras validar Homepage se podrá crear un monitor HTTP(s) de su `/api/healthcheck`, pero
  eso requiere autorización para editar Uptime Kuma y queda fuera de la primera subfase.

## 11. Criterio de finalización

Todas las pruebas automáticas de `pruebas.md` pasan y el usuario confirmó el acceso desde
cliente el 29 de agosto de 2026. La primera entrega está cerrada. Android/PWA puede
probarse después sin APK.

## 12. Referencias oficiales

- [Instalación Docker de Homepage](https://gethomepage.dev/installation/docker/)
- [Hosts permitidos y autenticación](https://gethomepage.dev/installation/)
- [Integración Docker y socket-proxy](https://gethomepage.dev/configs/docker/)
- [Widget Resources](https://gethomepage.dev/widgets/info/resources/)
- [Widget Glances](https://gethomepage.dev/widgets/info/glances/)
- [Widget Uptime Kuma](https://gethomepage.dev/widgets/services/uptime-kuma/)
- [Tailscale Serve](https://tailscale.com/kb/1242/tailscale-serve)
