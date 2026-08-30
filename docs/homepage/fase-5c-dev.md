# Fase 5C — Servidor DEV

Estado: **completada; G5C cerrada**.

## Alcance

Desplegar un agente Glances aislado en la VM `tickets-server-dev` sin modificar el
Compose, los contenedores, los puertos ni la configuración de Servicio Tickets. El
agente usará Tailscale, autenticación propia, un entorno Python independiente y un
servicio systemd dedicado.

## Evidencia inicial verificada

- MagicDNS: `tickets-server-dev.tailf553c4.ts.net`.
- Tailscale respondió desde `100.80.93.74` con trayecto directo de 25 ms.
- La huella SSH ED25519 anunciada fue comparada desde la consola de la VM y coincidió:
  `SHA256:WnVIU16z7F7rr5ebJkBQhzE72wCsljzzrdqud9mGSQg`.
- Se añadió esa única clave de host a `/home/bedvil/.ssh/known_hosts` tras crear un
  backup recuperable en `backups/20260830-fase-5c-dev-ssh/known_hosts.before`.
- La autenticación posterior falla con `Permission denied (publickey,password)`: la
  clave pública del Mac mini todavía no está autorizada para el usuario `nilton`.

## Inventario del sistema

| Elemento | Resultado verificado |
|---|---|
| Sistema | Ubuntu 26.04, kernel 7.0.0-30-generic, x86_64 |
| Usuario remoto | `nilton`, miembro de `sudo` y `docker` |
| Tailscale | `100.80.93.74` (`tickets-server-dev.tailf553c4.ts.net`) |
| Python | 3.14.4; `pip` 25.1.1 y `venv` disponibles |
| Glances / 61208 | ausentes; ningún servicio de métricas existente |
| Recursos | 2 CPU; 7.785.455.616 bytes RAM; raíz 51.460.472.832 bytes |
| Sensores | `sensors` ausente; no se mostrará temperatura |
| Tickets | backend 18000, frontend 5173 y PostgreSQL 55432 activos |

Glances 4.5.6 declara soporte para Python 3.14, por lo que se fijará la misma versión
que en 5B dentro de un venv propio. El Python global, Docker y el proyecto Tickets no se
usarán ni modificarán para instalar el agente.

No se ha modificado la aplicación Tickets, Docker, systemd, firewall, Tailscale ni
Homepage. La consulta de firewall sin elevación fue rechazada como corresponde.

## Puerta 5C-SSH

La clave pública del Mac mini ya fue autorizada y la conexión por clave funciona. Antes
de diseñar la regla mínima se necesita observar con `sudo` el firewall realmente activo
(UFW, firewalld o nftables). Solo entonces se prepararán instalación, pruebas, secreto,
tarjeta y rollback.

## Paquete operativo preparado

Ruta: `clients/linux/homepage-metrics-agent/`.

- `Install-HomepageMetricsAgent.sh`: crea un venv propio, usuario de sistema, hash de
  credencial, servicio Glances y firewall; falla sin sobrescribir instalaciones previas.
- `homepage-metrics-agent-firewall.sh`: añade una cadena `iptables` dedicada que solo
  acepta `100.72.206.57` hacia 61208 en `tailscale0` y descarta al resto de la tailnet.
- `Test-HomepageMetricsAgent.py`: prueba unidades, listener, firewall, autenticación,
  métricas nativas, allowlist y privacidad de procesos.
- `Uninstall-HomepageMetricsAgent.sh`: detiene sus dos unidades y mueve las rutas a
  nombres fechados `.removed-*` en vez de borrar datos.

Validación previa en Mac mini: validador estático Linux, validación Homepage/Compose y
los tests sintéticos existentes terminaron correctamente. La instalación requiere la
contraseña sudo de `nilton`; no se automatiza ni se solicita esa contraseña.

## Primer intento de instalación

Glances 4.5.6, Python 3.14 y dependencias se instalaron correctamente y `pip check`
terminó limpio. El servicio no llegó a abrir 61208: el directorio staging de `mktemp`
conservó modo 700 al moverse a `/opt`, por lo que el usuario de sistema no podía ejecutar
el Python del venv (`status=203/EXEC`, permiso denegado). No afectó Tickets.

La corrección fija permisos de travesía 755 solo para el árbol de aplicación y corrige el
trap de rollback para que también se ejecute ante un timeout producido por `exit`. La
instalación actual se reparará con ese cambio mínimo y se volverá a validar antes de
transferir ningún secreto o modificar Homepage.

El primer arreglo permitió iniciar Glances y dejó el listener privado activo. La prueba
instalada reveló una segunda ruta incorrecta hacia su propio Python: apuntaba fuera de
`app/`. Se corrige antes de aceptar cualquier resultado; el reemplazo de ese único
lanzador llevará una copia recuperable.

La inspección elevada confirmó que la cadena firewall ya es exacta: acepta solo al Mac
mini `100.72.206.57` y descarta los demás orígenes Tailscale para 61208. El test incluyó
por error la línea declarativa `-N` que `iptables -S` añade antes de las reglas `-A`; se
filtra esa declaración sin cambiar el firewall.

La transferencia del secreto DEV por stdin se completó y `.env` quedó con modo 600,
cuatro variables esperadas e ignorado por Git; no se leyeron valores. Un detalle del
cleanup devolvía código no cero después de una escritura correcta; se corrigió antes de
la siguiente ejecución sin cambiar el secreto almacenado.

## Integración con Homepage

Se creó backup recuperable en `services/homepage/backups/20260830-fase-5c-dev/` antes de
modificar la configuración. La tarjeta `🖥 EQUIPOS / Servidor DEV` usa MagicDNS,
Glances v4, credenciales `HOMEPAGE_VAR_DEV_*`, vista compacta y refresco de 5 segundos.
Solo se recreó el contenedor `homepage`: quedó `running`, `healthy` y con cero reinicios.

La prueba desde el contenedor Homepage confirmó ruta, credenciales inyectadas, 401
anónimo, CPU/RAM/disco, hostname, allowlist de seis plugins, procesos HTTP 400 y proxy
del widget. La regresión completa posterior pasó para Homepage, Tickets DEV, Nilton PC,
PROD, n8n, Kuma, OpenClaw y Tailscale.

El usuario confirmó que la tarjeta DEV se visualiza correctamente.

## Prueba de caída aislada y cierre G5C

Se detuvo solo `homepage-metrics-agent.service`. El servicio quedó inactivo, 61208 dejó
de escuchar y los tres contenedores Tickets continuaron `running`. Desde Homepage, DEV
devolvió `ECONNREFUSED`; Homepage siguió `running`, `healthy`, sin reinicios y su prueba
runtime pasó.

Tras iniciar de nuevo el servicio, el test local devolvió OK y Homepage volvió a validar
API autenticada, métricas, privacidad y proxy del widget. La regresión Tailscale/n8n/
Kuma/OpenClaw pasó. El usuario confirmó además la tarjeta visualmente.

Estado: **Fase 5C completada; G5C cerrada**.
