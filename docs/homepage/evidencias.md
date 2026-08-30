# Evidencias de ejecución de Homepage

## Fase 1A — 29 de agosto de 2026

Estado: **completada; G1A aprobada posteriormente**.

### Cambios realizados

- Creado `/home/bedvil/server/services/homepage` dentro del repositorio.
- Creado `/home/bedvil/docker/homepage` como enlace al directorio versionado.
- Añadido Compose estático con un único servicio Homepage.
- Añadida configuración HOME SERVER con n8n, Uptime Kuma, OpenClaw y Tailscale.
- Añadidos validadores Bash para configuración estática y Compose.
- No se descargaron imágenes ni se iniciaron contenedores.

### Resultado de pruebas

```text
==> Ejecutando static.sh
Pruebas estáticas: OK
==> Ejecutando compose.sh
Pruebas de Compose: OK
Validación de Homepage completada correctamente.
```

La primera ejecución detectó un error de comillas en una expresión regular del propio
test estático. La puerta quedó bloqueada, se corrigió el test y se repitieron desde cero
la sintaxis Bash y todas las pruebas, ya con resultado correcto.

### Propiedades verificadas

- Imagen fijada: `ghcr.io/gethomepage/homepage:v2.1.2`.
- Puerto futuro: `127.0.0.1:3000:3000`.
- Host permitido exacto: `macmini-server.tailf553c4.ts.net:10000`.
- Un único servicio y un único grupo HOME SERVER.
- Sin Docker socket, `latest`, secretos, PROD, DEV ni herramientas IA.
- El enlace operativo resuelve a `/home/bedvil/server/services/homepage`.
- Puertos 3000 y 10000 siguen sin listeners.
- Tailscale Serve conserva únicamente las reglas anteriores de 443 y 8443.
- n8n continúa activo y Uptime Kuma continúa activo/healthy.

### Rollback de esta fase

Como no hay contenedores ni reglas nuevas, el rollback consiste únicamente en retirar el
enlace `/home/bedvil/docker/homepage` y los archivos nuevos de
`/home/bedvil/server/services/homepage`. No debe ejecutarse salvo petición explícita.

### Siguiente puerta

G1A requiere aprobación del usuario antes de descargar la imagen o ejecutar
`docker compose up -d` en la Fase 1B.

## Fase 1B — 29 de agosto de 2026

Estado: **completada; G1B aprobada posteriormente**.

### Cambios realizados

- Añadidos `deploy.sh` y `smoke-test.sh`.
- Añadidas pruebas de runtime y regresión.
- Descargada y arrancada únicamente la imagen fijada de Homepage.
- Creada la red aislada `homepage_default` por Docker Compose.
- No se modificaron n8n, Uptime Kuma, OpenClaw ni Tailscale Serve.

### Identidad de imagen

```text
ghcr.io/gethomepage/homepage:v2.1.2
sha256:da9dca9ec258c628146bed1445da0853f2b88f0b10bafd97c091de807c363d60
```

### Resultado final de pruebas

```text
Pruebas estáticas: OK
Pruebas de Compose: OK
Pruebas de runtime: OK
Pruebas de regresión: OK
```

### Propiedades verificadas

- Contenedor `homepage`: `healthy`, cero reinicios.
- Publicación: `127.0.0.1:3000->3000/tcp`.
- `/api/healthcheck`: HTTP 200.
- Portada con el Host MagicDNS previsto: HTTP 200.
- `/api/services`: exactamente HOME SERVER con n8n, Uptime Kuma, OpenClaw y Tailscale.
- Acceso a `192.168.1.43:3000`: conexión rechazada.
- Sin montaje de `/var/run/docker.sock` en Homepage.
- Uso observado tras arrancar: aproximadamente 103 MiB de RAM y 0 % CPU en reposo.
- Logs de arranque sin errores de YAML, permisos ni validación de host.
- n8n y OpenClaw: HTTP 200 por sus endpoints HTTPS actuales.
- Uptime Kuma: accesible, contenedor `healthy`.
- Tailscale Serve conserva exclusivamente las reglas existentes 443 y 8443; 10000 aún
  no está configurado.

El primer smoke test recibió un reset transitorio mientras Next.js terminaba de arrancar.
Homepage quedó sano y sin reinicios. Se corrigió el test para reintentar también errores
transitorios, y luego se repitió la batería completa con resultado correcto.

### Rollback de esta fase

El rollback operativo, si se solicita, es ejecutar `docker compose down` únicamente en
el proyecto `/home/bedvil/server/services/homepage`. No afecta los demás proyectos.

### Siguiente puerta

G1B requiere aprobación antes de añadir docker-socket-proxy o cambiar `docker.yaml` en la
Fase 1C.

## Fase 1C — 29 de agosto de 2026

Estado: **completada; continuación automática a 1D autorizada por el usuario**.

### Cambios realizados

- Añadido `homepage-dockerproxy` con la imagen fijada v0.5.0.
- Creada la red interna `homepage_docker_api`, sin gateway externo.
- Montado el socket Docker únicamente en el proxy y como read-only.
- Habilitada exclusivamente la sección `CONTAINERS`; `POST=0` y el resto de secciones
  sensibles permanecen deshabilitadas.
- Configurado `docker.yaml` para usar `dockerproxy:2375` dentro de la red interna.
- Asociadas las tarjetas n8n y Uptime Kuma a sus contenedores, con estadísticas visibles.
- Añadido `docker-proxy.sh` a la batería obligatoria.

### Identidad de imagen

```text
ghcr.io/tecnativa/docker-socket-proxy:v0.5.0
sha256:1f5038b54f06c3e18422902cf00ba21803d1c97805aae032e5e6673d532d3459
```

### Resultado de pruebas

- GET `/containers/json`: HTTP 200 y contiene n8n/Uptime Kuma.
- POST `/_ping`: rechazado por el proxy.
- Puerto 2375: solo interno, sin publicación en el host.
- Socket: `RW=false` en el proxy y ausente en Homepage.
- Homepage: asociaciones `local-docker` presentes en `/api/services`.
- Runtime y regresión: OK.
- n8n, Uptime Kuma, OpenClaw y Tailscale: sin cambios funcionales.

La imagen oficial registra advertencias de HAProxy porque ejecuta su proceso como root y
sin chroot. No se concedió `privileged`; se añadió `no-new-privileges`, la red es interna,
no hay puerto de host y la API está limitada a GET/HEAD de contenedores. El riesgo
residual queda documentado para futuras revisiones.

### Backup y rollback

Backup previo: `services/homepage/backups/20260829-fase-1c/` (ignorado por Git).

Para volver a 1B se restauran `compose.yaml`, `services.yaml` y `docker.yaml` desde esa
copia y se aplica únicamente el Compose de Homepage. No ejecutar sin petición explícita.

## Fase 1D — 29 de agosto de 2026

Estado: **completada; G1D aprobada posteriormente**.

### Cambios realizados

- Añadido `homepage-glances` con Glances 4.5.6 full.
- Creada la red interna independiente `homepage_metrics_api`.
- Homepage es el único consumidor de la API interna `glances:61208`.
- Glances usa `pid: host` para métricas reales y no monta el socket Docker.
- Montajes RO: `/home/bedvil/server` como `/hostfs`, `/sys` y `/etc/os-release`.
- Se evitó montar `/` completo para reducir lectura innecesaria del host.
- Añadido widget Glances con CPU, RAM, uptime, disco y temperatura `Package id`.
- Añadidos `metrics.sh` y `metrics_validate.py` a la batería obligatoria.

### Identidad de imagen

```text
nicolargo/glances:4.5.6-full
sha256:28e015d1ea437e4ed12c118b8a206991cfabdfc5c8c1a79af1bf39946066ad37
```

### Comparación con el host

Última ejecución registrada:

```text
CPU válida: 6.7 %
RAM total válida: 16641294336 bytes
Disco /hostfs válido: 982820896768 bytes
Temperatura fiable: 55.0 °C
```

- RAM: dentro del 5 % permitido frente a `/proc/meminfo`.
- Disco: dentro del 2 % permitido frente al filesystem real.
- CPU: dentro del rango 0–100 %.
- Uptime: API disponible.
- Temperatura: `Package id` coincide dentro de 5 °C con `sensors`.

### Seguridad y runtime

- Glances no publica 61208/61209 en el host.
- No tiene acceso al socket Docker.
- Todos sus bind mounts son read-only.
- Tiene `no-new-privileges`.
- Homepage continúa `healthy`, ligado solo a `127.0.0.1:3000`.
- Docker proxy y todas las regresiones continúan en OK.
- Consumo aproximado observado: Homepage 105 MiB, proxy 18 MiB y Glances 83 MiB.

### Backup y rollback

Backup previo: `services/homepage/backups/20260829-fase-1d/` (ignorado por Git).

Para volver a 1C se restauran `compose.yaml` y `widgets.yaml` desde esa copia y se aplica
solo el Compose de Homepage. No ejecutar sin petición explícita.

### Siguiente puerta

G1D fue aprobada al solicitar el usuario continuar con las fases restantes de la Fase 1.

## Fase 1E — 29 de agosto de 2026

Estado: **completada; G1E confirmada por el usuario**.

### Estado previo y backup

- Tailscale Serve exponía únicamente 443 y 8443.
- 443 apuntaba a `http://127.0.0.1:18789`.
- 8443 apuntaba a `http://127.0.0.1:5678`.
- 10000 no tenía listener ni regla.
- Backup previo: `services/homepage/backups/20260829-fase-1e/` (ignorado por Git), con
  la salida JSON real de Serve y copias de los tests modificados.

### Cambios realizados

- Añadido `publish-tailscale.sh`, que valida las reglas heredadas antes de publicar.
- Añadidos `tailscale.sh` y `tailscale_validate.py` para validar estructura JSON, TLS,
  healthcheck, privacidad tailnet y aislamiento LAN.
- Publicada exclusivamente la regla HTTPS 10000 hacia `http://127.0.0.1:3000`.
- Adaptada la regresión histórica: protege los destinos 443 y 8443 y deja de prohibir
  el puerto correspondiente a la nueva fase.

### Resultado final de pruebas

```text
Configuración Tailscale (published): OK
Pruebas HTTPS/Tailscale: OK
Pruebas de runtime: OK
Pruebas del docker-socket-proxy: OK
Pruebas de métricas: OK
Pruebas de regresión: OK
homepage_https=200 tls=0
```

### Propiedades verificadas

- URL: `https://macmini-server.tailf553c4.ts.net:10000/`.
- Certificado válido y `/api/healthcheck` con HTTP 200.
- El endpoint figura como `tailnet only`; no se habilitó Funnel.
- 443 y 8443 conservan exactamente sus destinos anteriores.
- Docker publica Homepage solo en `127.0.0.1:3000`.
- La conexión directa a `192.168.1.43:3000` es rechazada.
- `homepage` está healthy; Homepage, proxy y Glances tienen cero reinicios.
- n8n, Uptime Kuma y OpenClaw continúan respondiendo correctamente.

### Rollback exacto

Para retirar solo el acceso HTTPS de Homepage:

```bash
tailscale serve --https=10000 off
```

No usar `tailscale serve reset`, porque eliminaría también 443 y 8443.

### Validación manual

- El usuario confirmó el 29 de agosto de 2026 que Homepage funciona desde el cliente.
- Con esta confirmación se cierra la puerta G1E y la primera entrega.
- La prueba desde Android y “Añadir a pantalla de inicio” permanece opcional.

## Fase 2 — 29 de agosto de 2026

Estado: **completada; G2 aprobada por el usuario**.

### Diferencias resueltas

- El dominio del prompt, `service-ab-electronics.com`, no resuelve.
- El dominio real comprobado es `https://service-ab-electronic.com/` (singular).
- El HTML servido públicamente coincide con el origen
  `servicio-tickets-definitivo` al enviar la cabecera de host correcta.
- No se verificó ninguna URL administrativa adicional ni un status page público de Kuma;
  ambos elementos se omitieron en lugar de adivinarlos.

### Cambios

- Añadido el grupo `🚨 PRODUCCIÓN` con dos columnas e iconos rojos.
- Añadido `Servidor Ubuntu PROD` con ping al MagicDNS privado.
- Añadido `Tickets PROD` con enlace y `siteMonitor` HTTPS.
- Añadidos `production.sh` y `production_validate.py` a la batería obligatoria.
- No se reinició ningún contenedor; Homepage recargó los YAML automáticamente.

### Resultado

```text
Configuración runtime de PRODUCCIÓN: OK
Pruebas de PRODUCCIÓN: OK
Pruebas de runtime: OK
Pruebas del docker-socket-proxy: OK
Pruebas de métricas: OK
Pruebas HTTPS/Tailscale: OK
Pruebas de regresión: OK
```

Homepage quedó `healthy`, con cero reinicios. Las reglas Tailscale 443, 8443 y 10000
conservaron exactamente sus destinos.

### Backup y siguiente puerta

Backup: `services/homepage/backups/20260829-fase-2/` (ignorado por Git).

El usuario autorizó el 30 de agosto de 2026 avanzar a la Fase 3; G2 queda cerrada.

## Fase 3 — 30 de agosto de 2026

Estado: **completada; G3 aprobada por el usuario**.

### Descubrimiento y diferencias

- La VM NAT tenía red y DNS, pero no disponía del comando Tailscale activo.
- El usuario instaló Tailscale y obtuvo acceso SSH con `nilton` por `100.80.93.74`.
- El nombre apareció primero como `tickets-server`; se renombró a
  `tickets-server-dev` para diferenciarlo inequívocamente de PROD.
- Puertos verificados: 22 SSH, 5173 frontend y 18000 backend Docker canónico. También se
  observó un Uvicorn adicional en 8000 que quedó fuera de alcance.

### Cambios

- Añadido el grupo azul `🧪 DESARROLLO / DEV` con tres columnas.
- Añadidos Servidor Ubuntu DEV, Tickets DEV y API DEV/Swagger.
- Añadidos `development.sh` y `development_validate.py` a la batería obligatoria.
- Actualizado el test PROD para admitir fases posteriores sin relajar sus destinos.
- No se reinició Homepage ni se modificó Compose, PROD, n8n, Kuma, OpenClaw o Serve.

### Resultado

```text
Configuración runtime de DESARROLLO: OK
Pruebas de DESARROLLO: OK
Configuración runtime de PRODUCCIÓN: OK
Pruebas de PRODUCCIÓN: OK
Pruebas de runtime: OK
Pruebas del docker-socket-proxy: OK
Pruebas de métricas: OK
Pruebas HTTPS/Tailscale: OK
Pruebas de regresión: OK
```

Homepage quedó `healthy`, con cero reinicios. Las tres reglas Tailscale Serve del Mac mini
permanecieron exactas.

### Backup y siguiente puerta

Backup: `services/homepage/backups/20260830-fase-3/` (ignorado por Git).

G3 requiere que el usuario compruebe visualmente el bloque DEV antes de comenzar la
Fase 4.

### Hallazgo de validación funcional

El usuario comprobó después que el backend no era utilizable desde el frontend. La
inspección mostró que Uvicorn y `/health` sí responden, pero el bundle apunta a
`http://127.0.0.1:18000`. Además, el preflight CORS devuelve 400 para el origen MagicDNS
DEV y solo acepta los orígenes localhost antiguos. La batería de Fase 3 se ampliará para
validar la URL compilada y el preflight CORS antes de cerrar G3.

### Corrección frontend/backend DEV

- Fuente del fallo: `docker-compose.virtualbox.yml` forzaba API
  `http://127.0.0.1:18000` y CORS conservaba orígenes antiguos.
- Backup en la VM: `docker-compose.virtualbox.yml.backup-20260830-before-tailscale-dev`.
- Nueva API compilada: `http://tickets-server-dev.tailf553c4.ts.net:18000`.
- CORS añadió MagicDNS 5173 e IP Tailscale 5173 sin retirar orígenes anteriores.
- Compose se validó antes de aplicar.
- Solo se reconstruyeron backend y frontend; el backend quedó `healthy` y PostgreSQL
  permaneció `Running`.
- Homepage cambió API DEV de 8000 al backend Docker canónico 18000.
- `development.sh` ahora inspecciona el bundle y ejecuta un preflight CORS real.
- Backup local previo: `services/homepage/backups/20260830-fase-3-fix-backend/`.

La batería completa volvió a pasar. El usuario confirmó el 30 de agosto de 2026 que el
frontend y el backend funcionan correctamente; G3 queda cerrada.

## Fase 4 — 30 de agosto de 2026

Estado: **servidor completado; validación visual pendiente**.

### 4A — Descubrimiento

- Verificadas las siete URLs de IA y tres administrativas.
- Antigravity usa su dominio canónico `antigravity.google.com`.
- ChatGPT/Codex devuelven 403 al cliente automatizado, con TLS válido; se considera
  protección anti-bot y se mantiene su URL web oficial.
- No se solicitaron ni almacenaron cuentas, claves o perfiles personales.

### 4B — IA

- Añadido `🤖 INTELIGENCIA ARTIFICIAL`, cuatro columnas y siete tarjetas.
- ChatGPT, Codex, Antigravity, GitHub Copilot, Google AI Studio, Gemini y NVIDIA Build.
- Todos son enlaces simples sin widgets ni credenciales.

### 4C — Administración

- Añadido `🛠 ADMINISTRACIÓN`, tres columnas.
- Tailscale Admin, Uptime Kuma Admin y GitHub.
- No se movieron ni alteraron las tarjetas de HOME SERVER.

### 4D — Resultado

```text
Configuración runtime de IA y Administración: OK
Pruebas de IA y Administración: OK
Pruebas de runtime: OK
Pruebas del docker-socket-proxy: OK
Pruebas de métricas: OK
Pruebas de PRODUCCIÓN: OK
Pruebas de DESARROLLO: OK
Pruebas HTTPS/Tailscale: OK
Pruebas de regresión: OK
```

Los primeros tests revelaron dos errores de expectativa en los validadores y una muestra
térmica transitoria fuera de tolerancia. Se corrigieron los validadores, se repitió la
métrica sin cambiar tolerancias y la batería completa terminó correctamente.

Homepage quedó `healthy`, con cero reinicios. Las reglas Serve y los servicios anteriores
permanecieron intactos.

### Backup y puerta

Backup: `services/homepage/backups/20260830-fase-4/` (ignorado por Git).

G4 requiere comprobación visual de iconos, distribución y enlaces antes de Fase 5.
