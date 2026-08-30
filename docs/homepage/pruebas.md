# Estrategia de pruebas de Homepage

## 1. Política

- Cada comando operativo crítico debe tener una comprobación posterior objetiva.
- Los scripts futuros usarán `set -Eeuo pipefail`, rutas absolutas derivadas de su propia
  ubicación, mensajes claros y códigos de salida distintos de cero ante fallo.
- Ningún test puede detener o recrear n8n, Uptime Kuma u OpenClaw.
- Los tests de seguridad son bloqueantes: no se continúa si se abre un puerto inesperado,
  se pierde una regla Tailscale o el proxy admite escritura.
- Las pruebas se ejecutarán al final de cada subfase y como regresión en las siguientes.

## 2. Estructura implementada

```text
services/homepage/
├── scripts/
│   ├── validate.sh          # solo lectura; ejecuta pruebas estáticas
│   ├── deploy.sh            # valida, despliega Homepage y llama smoke tests
│   ├── publish-tailscale.sh # publica solo HTTPS 10000 y valida el resultado
│   └── smoke-test.sh        # salud, red, logs y regresión
└── tests/
    ├── static.sh
    ├── compose.sh
    ├── runtime.sh
    ├── docker-proxy.sh
    ├── development.sh
    ├── metrics.sh
    ├── phase4.sh
    ├── nilton-pc.sh
    ├── nilton_pc_validate.py
    ├── windows_metrics_agent_validate.py
    ├── production.sh
    ├── tailscale.sh
    └── regression.sh
```

`deploy.sh` no oculta comandos destructivos ni usa `sudo`; se limita al proyecto Compose
de Homepage. `publish-tailscale.sh` protege primero 443/8443 y solo gestiona la regla
dedicada 10000.

## 3. Matriz comando → prueba vital

| Comando/acción crítica | Prueba obligatoria | Resultado esperado |
|---|---|---|
| Renderizar Compose | `docker compose config --quiet` | salida 0 antes de cualquier `up` |
| Resolver imagen | `docker manifest inspect` o `docker image inspect` | tag/digest amd64 disponible |
| Arrancar Homepage | `docker compose up -d` | solo servicios del proyecto creados; salida 0 |
| Estado de proyecto | `docker compose ps` | servicios esperados `Up`; sin reinicios continuos |
| Salud local | `curl http://127.0.0.1:3000/api/healthcheck` | HTTP 200 |
| Validación de host | solicitud con host MagicDNS exacto + revisión de logs | sin error `Host validation` |
| Logs | `docker compose logs --no-color` filtrado | sin errores YAML, permisos o bucles |
| Exposición local | `docker port homepage` y `ss -lnt` | solo `127.0.0.1:3000`, nunca `0.0.0.0`/`[::]` |
| Docker GET | consulta proxy a `/_ping` y `/containers/json` | 200 y solo datos necesarios |
| Docker POST | `POST /_ping` a través del proxy | 403, 405 o conexión denegada; nunca 2xx |
| Montajes | `docker inspect homepage` | no contiene `/var/run/docker.sock` |
| Proxy | `docker inspect dockerproxy` | socket RO, `POST=0`, sin puerto de host |
| Glances CPU/RAM | API Glances frente a host | valores razonablemente próximos, no del contenedor |
| Glances disco | API frente a `df -hP /` | mismo filesystem/capacidad dentro de tolerancia |
| Glances temperatura | API frente a `Package id 0` | diferencia ≤ 5 °C o se deshabilita la métrica |
| Configuración PROD | `/api/services` + validador | grupo y dos tarjetas exactas; HOME sin cambios |
| Nodo PROD | ping desde Homepage al MagicDNS | respuesta ICMP sin exponer puertos nuevos |
| Tickets PROD | HTTPS público + origen privado | HTTP 200, TLS válido y misma aplicación |
| Configuración DEV | `/api/services` + validador | tres tarjetas exactas; ningún destino PROD reutilizado |
| Nodo DEV | ping desde Homepage al MagicDNS | respuesta ICMP privada |
| Frontend DEV | HTTP 5173 + título | HTTP 200 y aplicación de tickets esperada |
| API DEV | `/health` y `/docs` en 18000 | backend Docker sano y Swagger esperado |
| Bundle DEV | inspección del JS servido | MagicDNS 18000 presente; loopback 18000 ausente |
| CORS DEV | preflight desde MagicDNS 5173 | HTTP 200 y `allow-origin` exacto |
| Configuración Fase 4 | `/api/services` + validador | grupos de herramientas y destinos exactos |
| Enlaces externos | GET con redirecciones | TLS válido y 2xx/3xx; 401/403 de acceso permitido |
| Enlaces IA/Admin | inspección runtime | sin widgets activos, integraciones ni patrones secretos |
| Catálogo Windows | validador Python | 13 IDs únicos, fallbacks HTTPS y AppID verificados |
| Protocolo Windows | test PowerShell local | allowlist completa; rutas, query e IDs desconocidos rechazados |
| Aplicación instalada | resolución PowerShell | acción local para los seis AppID observados |
| Aplicación ausente | resolución PowerShell | abre únicamente el fallback HTTPS oficial |
| Agente remoto | listener y API en cada nodo | solo IP Tailscale; autenticado; nunca LAN/`0.0.0.0` |
| Métricas remotas base | API frente a comandos nativos | RAM 5 %, disco 2 %, uptime 60 s, CPU 0–100 % |
| Consumo desde Homepage | consulta desde contenedor | `/api/4/status` y métricas responden autenticadas |
| Fallo de nodo remoto | detener/bloquear solo agente de prueba | solo su tarjeta degrada; Homepage sigue healthy |
| Secretos de métricas | Git + configuración renderizada | ninguna contraseña o token versionado |
| Instalador Nilton PC | test PowerShell + validador estático | tarea, firewall, API, tolerancias y rollback seguros |
| Regla HTTPS | `tailscale serve status --json` | 10000→3000 y 443/8443 sin cambios |
| TLS/HTTPS | `curl https://...:10000/api/healthcheck` | HTTP 200 y verificación TLS 0 |
| No LAN | conexión a `192.168.1.43:3000` | rechazada |
| Regresión n8n | curl a `/healthz` en 8443 | HTTP 200, TLS válido |
| Regresión Uptime Kuma | consulta HTTP actual y `docker ps` | respuesta válida y contenedor healthy |
| Regresión OpenClaw | consulta HTTPS 443 | HTTP 200 |

## 4. Pruebas estáticas

Bloqueantes antes del primer arranque:

- Existen `compose.yaml` y los YAML requeridos por Homepage.
- No hay tabs, YAML vacío ni placeholders sin resolver.
- Tras la segunda iteración de 5F aparecen exactamente seis grupos; HOME SERVER reúne
  infraestructura, equipos, Tickets PROD y GitHub. Tailscale y Kuma aparecen una sola vez.
- DEV solo usa su MagicDNS verificado; IA/Admin solo contienen enlaces confirmados.
- No aparecen patrones de tokens, API keys, passwords o claves privadas.
- `HOMEPAGE_ALLOWED_HOSTS` no es `*` y contiene `:10000`.
- La imagen no usa `latest`.
- El puerto 3000 está ligado explícitamente a `127.0.0.1`.

## 5. Pruebas de métricas

Las comparaciones se capturan en una ventana corta para reducir variación:

- RAM total: diferencia máxima 5 % respecto a `/proc/meminfo`.
- Disco total: diferencia máxima 2 % respecto a `df -B1 /`.
- Uptime: diferencia máxima 60 segundos.
- CPU instantánea: solo se valida rango 0–100 %, porque cambia rápidamente.
- Temperatura: diferencia máxima 5 °C respecto a `Package id 0`; si Glances no expone
  ese sensor o devuelve lecturas Apple SMC anómalas, no se publica temperatura. Para
  absorber únicamente el intervalo de refresco de Glances se permiten hasta seis
  muestras en cinco segundos; el margen por muestra no se amplía.

## 6. Pruebas manuales

- Windows conectado a Tailscale abre la URL HTTPS sin advertencias.
- Las cuatro tarjetas abren el destino correcto.
- PROD y DEV no aparecen durante la primera entrega.
- El diseño sigue legible con anchura de escritorio y móvil.
- El teléfono no forma parte de la monitorización ni ejecuta agentes de métricas.
- Tras la Fase 2, PRODUCCIÓN aparece separada, en rojo y sin confusión con HOME SERVER.
- Tras la Fase 3, DEV aparece en azul y sus enlaces no reutilizan ningún destino PROD.
- Tras 5F, los seis grupos son legibles y no contienen credenciales.
- El instalador Windows termina con `Pruebas del lanzador: OK (13 destinos)`.
- VS Code, Cursor, Antigravity, Hermes Desktop, Warp y PowerShell se abren localmente.
- Al menos una herramienta ausente abre su web oficial en lugar de ejecutar código.
- Cada tarjeta de `🖥 EQUIPOS` identifica claramente PC, DEV o PROD.
- Un equipo apagado no impide usar el resto del dashboard.

## 7. Evidencia por puerta

Cada cierre de fase debe guardar en la respuesta, sin secretos:

- fecha y fase;
- archivos creados/modificados;
- salida resumida de pruebas;
- contenedores y puertos;
- URL disponible;
- desviaciones y riesgos;
- instrucción exacta de rollback;
- confirmación pendiente del usuario.
