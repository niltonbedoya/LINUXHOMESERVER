# Fase 5E — Servidor PROD

Estado: **descubrimiento completado; pendiente de acceso SSH por clave**.

## Alcance y protección

Desplegar un agente Glances aislado en el servidor de producción, sin modificar sus
contenedores, aplicación Tickets, puertos existentes, Tailscale Serve ni firewall ajeno
al puerto privado de métricas. PROD es el último nodo de esta fase por criticidad.

La Raspberry Pi y el teléfono están fuera de este proyecto. No se desplegará un agente
ni se añadirá una tarjeta para ellos.

## Inventario verificado el 30 de agosto de 2026

| Elemento | Resultado |
|---|---|
| Usuario remoto habitual | `ab` |
| Host del sistema | `tickets-utuntu-01` |
| MagicDNS operativo | `servicio-tickets-definitivo.tailf553c4.ts.net` |
| Tailscale | `100.113.199.93` |
| Huella SSH ED25519 | `SHA256:3XF/dKeixLAE47KKDbjKb2mWFP5ndyL+GAxzlqHHkGM` |
| Sistema | Ubuntu 26.04 LTS, kernel `7.0.0-28-generic` |
| Python | `/usr/bin/python3`, versión 3.14.4 |
| Glances / puerto 61208 | ausentes; ningún listener detectado |
| SSH | escucha en 22; la clave del Mac mini aún no está autorizada para `ab` |
| UFW / firewalld | UFW inactivo; `firewall-cmd` ausente |
| Firewall efectivo | iptables con cadenas Docker y Tailscale; `INPUT` ACCEPT y `FORWARD` DROP |

La huella fue leída desde la consola de PROD. No se conserva ninguna entrada SSH de
PROD en el Mac mini hasta que se añada de forma explícita tras esta verificación.

## Puerta 5E-SSH

Antes de copiar o instalar cualquier archivo, el usuario `ab` debe autorizar la clave
pública ED25519 del Mac mini. Después se hará lo siguiente, en este orden:

1. Crear un backup recuperable de `known_hosts` en el Mac mini.
2. Añadir y comprobar exclusivamente la huella documentada.
3. Confirmar `ssh -o BatchMode=yes ab@…` sin contraseña.
4. Repetir inventario de solo lectura: grupos de `ab`, venv/pip, servicios, listener,
   Docker y reglas iptables.

Si cualquiera de esas comprobaciones falla, 5E se detiene sin alterar PROD.

## Primer intento de instalación

La huella SSH se añadió al Mac mini solo después de compararla, con backup local previo,
y `ab` autentica por clave correctamente. El staging del paquete se corrigió a modo 700:
los archivos creados inicialmente no tenían el bit ejecutable; no era una restricción de
`/tmp` ni un cambio en PROD.

El instalador se detuvo antes de crear rutas operativas, servicios, listener o firewall
porque falta `ensurepip` en el Python del sistema. Ubuntu provee ese componente mediante
`python3.14-venv`. El instalador incorpora ahora una precomprobación explícita para
fallar antes de crear su staging si vuelve a faltar este requisito.

## Instalación e integración

Se instaló el paquete oficial `python3.14-venv` junto con sus dependencias de venv y se
repitió el instalador. Glances 4.5.6, `pip check`, el servicio, el listener privado y el
test local terminaron correctamente. La API escucha únicamente en
`100.113.199.93:61208`; tanto `homepage-metrics-agent-prod.service` como su servicio
de firewall están activos.

Antes de modificar Homepage se guardó un backup recuperable de Compose, servicios,
layout y `.env` en `services/homepage/backups/20260830-fase-5e-prod/`. El secreto se
transfirió por stdin SSH a un `.env` ignorado por Git y con modo 600; solo se comprobó
la estructura de sus variables, nunca el valor.

La tarjeta `🖥 EQUIPOS / Servidor PROD` usa MagicDNS, Glances v4, variables
`HOMEPAGE_VAR_PROD_*`, vista compacta y refresco de 5 segundos. Se recreó únicamente el
contenedor Homepage, que volvió a `running`, `healthy` y cero reinicios. Las pruebas
desde el contenedor validaron autenticación, CPU, RAM, filesystem, uptime, hostname,
allowlist de seis plugins, bloqueo de procesos y proxy del widget. Pasaron también las
regresiones de Nilton PC, DEV, Tickets PROD/DEV, n8n, Kuma, OpenClaw y Tailscale.

## Prueba de caída aislada y cierre G5E

Se detuvo únicamente `homepage-metrics-agent-prod.service`. El agente quedó inactivo y
61208 dejó de escuchar; los siete contenedores de Tickets continuaron `running`. Desde
Homepage, el endpoint privado devolvió la indisponibilidad esperada (`ECONNREFUSED`),
mientras Homepage siguió `running`, `healthy` y sin reinicios; n8n y Kuma tampoco se
vieron afectados.

Después de iniciar el servicio de nuevo, el test local de PROD, la consulta autenticada
desde Homepage, el widget, la regresión y el listener volvieron a pasar. El usuario
confirmó visualmente la tarjeta `Servidor PROD`.

Estado: **Fase 5E completada; G5E cerrada**.

## Diseño previsto, aún no aplicado

El paquete de PROD será específico y no reutilizará rutas ni constantes de DEV:

- Glances 4.5.6 fijado en un venv propio bajo `/opt`.
- Usuario de sistema sin inicio de sesión para el proceso.
- Listener solo en `100.113.199.93:61208` por `tailscale0`.
- Cadena iptables dedicada que permitirá únicamente al Mac mini `100.72.206.57` y
  descartará cualquier otro origen Tailscale para ese puerto.
- Plugins mínimos: quicklook, system, CPU, RAM, filesystem y uptime; sin procesos,
  Docker socket ni autodetección.
- Secreto generado en PROD y transferido por stdin SSH a un `.env` local ignorado y con
  modo 600 en el Mac mini.
- Tarjeta compacta en `🖥 EQUIPOS`, con MagicDNS y variables `HOMEPAGE_VAR_PROD_*`.

La instalación requerirá una copia recuperable previa de los archivos locales afectados
y pruebas de listener, firewall, autenticación, API, privacidad, métricas nativas,
widget y regresión. Se probará además una caída controlada que detenga solo el agente,
nunca los servicios de Tickets.
