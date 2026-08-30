# Decisiones técnicas vigentes

| Fecha/contexto | Decisión | Motivo |
|---|---|---|
| Inicial | Usar `/home/bedvil/server` como workspace central | Evita abrir todo el home y reúne documentación y accesos |
| Inicial | Mantener `docker` y `openclaw` como enlaces simbólicos | Ofrece una vista conjunta sin mover los árboles operativos |
| Inicial | Priorizar Tailscale para acceso remoto | Reduce exposición pública y simplifica el acceso privado |
| Inicial | Usar Docker para servicios permanentes | Aislamiento suficiente con poca carga para el Mac mini |
| Inicial | Evitar Kubernetes, VM pesadas y LLM locales grandes | Hardware de 2014 y objetivo de servidor ligero |
| Monitorización | Asignar Service AB Electronic a Uptime Kuma | La monitorización no debe duplicarse en OpenClaw |
| Automatización | Usar n8n como orquestador principal | Centraliza workflows e integraciones |
| OpenClaw | Administrar su workspace desde la app | Desde este repositorio no se modifica sin petición explícita |
| n8n actual | Permitir temporalmente HTTP y cookies no seguras | Acceso LAN funcional mientras se diseña HTTPS |
| Documentación | Separar estado verificado de contexto histórico | Evita tratar recuerdos antiguos como hechos actuales |
| Estado actual | Dar por terminado `/servidor` | El usuario confirmó su funcionamiento correcto |
| Backups | Aplazar su implementación al proyecto NAS | El destino será una Raspberry Pi con varios discos en red |
| HTTPS n8n | Usar Tailscale Serve en el puerto 8443 | El 443 ya sirve otro componente y 8443 permite HTTPS privado sin interferir |
| Exposición n8n | Ligar Docker a `127.0.0.1:5678` | Evita conservar el antiguo acceso HTTP directo por LAN |
| Homepage | Aprobar el SDD y ejecutar por puertas | Reduce riesgo y permite contrastar cada subfase |
| Homepage | Versionar en `server/services/homepage` y enlazar desde `/home/bedvil/docker/homepage` | Mantiene la ruta operativa dentro del único repositorio |
| Homepage | Reservar HTTPS 10000 mediante Tailscale Serve | 443 y 8443 ya están ocupados y no deben alterarse |
| Homepage desplegado | Mantener 10000 como endpoint privado `tailnet only` | Proporciona TLS válido sin publicar el dashboard en Internet ni en la LAN |
| Homepage PROD | Usar `service-ab-electronic.com` en singular | Es el dominio que resuelve y coincide con el origen; el plural del prompt no existe |
| Homepage PROD | Mostrar servidor por ping y Tickets por `siteMonitor` | Aporta estado sin credenciales, cambios remotos ni URLs administrativas inventadas |
| Homepage DEV | Renombrar el nodo a `tickets-server-dev` | Evita confundir la VM de pruebas con el servidor definitivo |
| Homepage DEV | Usar azul, nombres DEV y destinos MagicDNS propios | Hace visible la separación operativa respecto al bloque PROD rojo |
| Homepage DEV | Enlazar frontend 5173 y backend Docker 18000 | Es el Compose canónico; evita usar el Uvicorn adicional 8000 sin propietario confirmado |
| Homepage DEV | Probar bundle y CORS, no solo healthchecks | Un backend sano no detecta una API compilada con loopback ni un origen rechazado |
| Homepage IA | Usar únicamente enlaces oficiales sin widgets ni claves | Centraliza accesos sin ampliar permisos ni duplicar integraciones |
| Homepage IA | Usar `antigravity.google.com` como URL canónica | La página declara ese dominio como canónico |
| Homepage Admin | Duplicar accesos de Kuma/Tailscale sin mover HOME | Conserva la base aprobada y crea un bloque administrativo predecible |
| Homepage | Usar v2.1.2 y evitar `latest` | Hace el despliegue reproducible |
| Homepage | Usar socket-proxy y Glances en fases separadas | Limita privilegios y evita confundir métricas del contenedor con el host |

## Cómo registrar nuevas decisiones

Añadir una fila cuando una elección cambie arquitectura, seguridad, propiedad de un
componente o procedimientos operativos. Actualizar también el documento afectado y el
estado actual después de comprobar el resultado.
