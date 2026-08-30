# Fases y puertas de control

Cada fase se ejecutó con su validación y evidencia independiente. Las continuaciones
automáticas de 1C a 1D y de 1E hasta cerrar la Fase 1 fueron autorizadas expresamente por
el usuario.

## Fase 0 — Descubrimiento y SDD (completada)

### Trabajo

- Leer contexto y documentación existente.
- Inspeccionar Docker, redes, puertos, Tailscale y URLs.
- Contrastar documentación oficial de Homepage.
- Crear SDD y plan de pruebas.

### Salida

- `docs/homepage/00-descubrimiento.md`.
- `docs/homepage/SDD.md`.
- `docs/homepage/fases.md`.
- `docs/homepage/pruebas.md`.

### Puerta G0

El usuario aprobó expresamente el SDD y las seis decisiones el 29 de agosto de 2026.

## Fase 1A — Estructura versionada y configuración estática (completada)

### Trabajo propuesto

- Crear `/home/bedvil/server/services/homepage`.
- Crear el enlace `/home/bedvil/docker/homepage`.
- Añadir Compose solo con Homepage, configuración HOME SERVER, scripts y pruebas.
- No iniciar contenedores.

### Validación

- Destino del enlace exacto.
- YAML válido.
- `docker compose config --quiet` correcto.
- Imagen fijada, host permitido exacto y puerto ligado a loopback.
- Ausencia de secretos, PROD, DEV e IA.

### Puerta G1A

Mostrar todos los archivos y el Compose renderizado. Esperar confirmación para arrancar.

Estado: pruebas superadas; G1A aprobada al autorizar el inicio de 1B.

## Fase 1B — Arranque local mínimo (completada)

### Trabajo propuesto

- Descargar la imagen fijada.
- Ejecutar solo Homepage.
- No configurar todavía Docker, Glances ni Tailscale Serve.

### Validación

- Contenedor `healthy` o estable.
- Healthcheck local HTTP 200.
- Logs sin errores de YAML ni `Host validation`.
- Puerto 3000 únicamente en `127.0.0.1`.
- n8n y Uptime Kuma continúan activos y sus healthchecks pasan.

### Puerta G1B

Mostrar estado, logs relevantes y regresión de servicios. Esperar confirmación.

Estado: pruebas superadas; G1B aprobada al autorizar el inicio de 1C.

## Fase 1C — Estado Docker con mínimo privilegio (completada)

### Trabajo propuesto

- Añadir docker-socket-proxy a una red interna.
- Configurar `docker.yaml` y estados de n8n/Uptime Kuma.
- No modificar los Compose de esos servicios.

### Validación

- GET de listado/estadísticas permitido.
- POST de prueba no destructivo rechazado por el proxy.
- Proxy sin puerto publicado en el host.
- Homepage sin montaje del socket.
- Tarjetas muestran estado sin credenciales.

### Puerta G1C

Presentar la matriz de permisos efectiva y los resultados de seguridad. Esperar confirmación.

Estado: pruebas superadas. El usuario autorizó continuar automáticamente a 1D si 1C no
presentaba fallos; se inicia 1D.

## Fase 1D — Métricas reales del Mac mini (completada)

### Trabajo propuesto

- Añadir Glances aislado.
- Configurar CPU, RAM, uptime, disco raíz y temperatura solo si es fiable.

### Validación

- Comparar API de Glances con `free`, `df`, `uptime` y `sensors` del host.
- Establecer tolerancias en `pruebas.md`.
- Confirmar que no se muestran métricas del contenedor como si fueran del host.
- Glances sin puerto publicado ni socket Docker.

### Puerta G1D

Mostrar valores comparados y omitir cualquier métrica no fiable. Esperar confirmación.

Estado: CPU, RAM, disco, uptime y temperatura validados; G1D aprobada al autorizar la
continuación de todas las subfases restantes de la Fase 1.

## Fase 1E — HTTPS privado y validación de cliente (completada)

### Trabajo propuesto

- Añadir solo la regla Tailscale Serve HTTPS 10000 → `127.0.0.1:3000`.
- No modificar las reglas 443 y 8443.

### Validación automática

- Certificado válido y healthcheck HTTPS 200.
- `tailscale serve status` conserva 443 y 8443 exactamente.
- Homepage no es accesible desde la LAN por `192.168.1.43:3000`.

### Validación manual

- El usuario abre Homepage desde Windows conectado a Tailscale.
- Confirma diseño, enlaces, estado Docker y métricas.
- Opcional: Android por Tailscale y “Añadir a pantalla de inicio”.

### Puerta G1E — fin de primera entrega

Estado: publicación y validaciones automáticas completadas. El usuario confirmó el 29 de
agosto de 2026 que Homepage funciona desde el cliente. G1E cerrada; Android/PWA continúa
como prueba opcional.

No continuar con PROD, DEV o IA sin confirmación explícita.

## Fase 2 — PRODUCCIÓN (completada)

- Confirmado que `servicio-tickets-definitivo` sirve el sistema PROD.
- Confirmado el dominio singular `service-ab-electronic.com`; el plural no resuelve.
- Añadido el grupo rojo `🚨 PRODUCCIÓN` con servidor privado y Tickets PROD.
- No se añadió una URL administrativa porque no existe ninguna verificada.
- No se integró el widget Uptime Kuma porque no hay un status page apropiado verificado.

Estado: configuración y pruebas automáticas completadas. El usuario autorizó el 30 de
agosto de 2026 avanzar a la Fase 3; G2 queda aprobada.

## Fase 3 — DESARROLLO (completada)

- Identificado y renombrado el nodo como `tickets-server-dev`.
- Verificados frontend 5173, API/health y Swagger en el backend Docker 18000.
- Añadido el grupo azul `🧪 DESARROLLO / DEV`, separado del rojo de PRODUCCIÓN.
- Los tests prohíben que DEV reutilice dominio, nodo o IP PROD.

Estado: la validación del usuario descubrió una API loopback y CORS antiguo. Se corrigió
el override de VirtualBox, se reconstruyeron solo frontend/backend y se añadieron pruebas
del bundle y preflight CORS. Todo pasa y el usuario confirmó el funcionamiento real el
30 de agosto de 2026; G3 queda cerrada.

## Fase 4 — Herramientas y administración (completada; G4 cerrada)

- 4A: URLs oficiales verificadas sin iniciar sesión.
- 4B: primera selección de siete enlaces IA.
- 4C: Tailscale Admin, Uptime Kuma Admin y GitHub en `🛠 ADMINISTRACIÓN`.
- 4D: validación runtime, enlaces/TLS y regresiones completas.
- 4E: clasificación ampliada en LLM, IDE, agentes/CLI, terminales y plataformas IA.
- 4F: lanzador Windows con allowlist, AppID/comandos conocidos y fallback HTTPS.

Estado: servidor y catálogo de 13 destinos validados; lanzador instalado en Windows.
Windows Terminal se retiró por duplicar PowerShell y OpenCode se corrigió con una Tab
Config fija de Warp. El usuario confirmó el funcionamiento y la presentación; G4 queda
cerrada y la Fase 5 puede iniciarse cuando se solicite.

## Fase 5 — Métricas de equipos y refinamiento (en curso)

### 5A — Descubrimiento y SDD (completada)

- Verificados Nilton PC, DEV, Raspberry Pi y PROD en Tailscale.
- Confirmado que ninguno expone todavía Glances 61208 al contenedor Homepage.
- Definidos aislamiento, autenticación, métricas, tolerancias y rollback.
- Teléfono y futuro NAS excluidos expresamente.
- No se modificó configuración operativa ni se reinició ningún servicio.

Documento: `fase-5a-monitorizacion-equipos.md`.

### 5B — Nilton PC (completada; G5B cerrada)

- Agente Glances 4.5.6 instalado y validado con allowlist sin procesos.
- Listener y firewall limitados a Tailscale/Mac mini; secreto fuera de Git.
- Grupo `🖥 EQUIPOS` y tarjeta compacta Nilton PC desplegados.
- Homepage healthy, proxy autenticado y regresión completa aprobados.
- El usuario confirmó la tarjeta. La caída controlada produjo `ECONNREFUSED` solo para
  Nilton PC; Homepage siguió healthy y sin reinicios. La recuperación pasó tanto en
  Windows como desde el proxy autenticado de Homepage.

### Fases siguientes

- 5C: servidor DEV y patrón Linux, completada; G5C cerrado. La caída aislada no afectó
  Tickets ni Homepage y la recuperación pasó local/remota.
- 5D: descartada. Raspberry Pi y su instalación desde cero pasan a un proyecto separado.
- 5E: servidor PROD, último por criticidad.
- 5F: integración completa de los tres nodos de este proyecto en `🖥 EQUIPOS`, pruebas conjuntas de
  fallo aislado y refinamiento visual.

Cada subfase tendrá una puerta y evidencia separada. No se monitorizará el teléfono ni
se desarrollará una APK/PWA específica para recopilar sus métricas.
