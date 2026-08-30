# Fase 5B — Nilton PC

Estado: **completada; G5B cerrada**.

## Estado previo verificado

- `nilton-pc.tailf553c4.ts.net` responde por Tailscale como `100.105.88.14`.
- El trayecto observado fue directo por la LAN Tailscale y respondió con baja latencia.
- El puerto TCP 22 rechaza conexiones; no existe acceso SSH desde el Mac mini.
- No se instalará ni habilitará OpenSSH solo para desplegar métricas.

## Siguiente puerta

Se creó `clients/windows/homepage-metrics-agent/Get-HomepageMetricsInventory.ps1`, que
obtiene sin modificar el equipo:

- versión/arquitectura de Windows y PowerShell;
- privilegios de la sesión;
- Tailscale e IP real;
- Python y lanzadores disponibles;
- Glances o listener 61208 previos;
- tarea, firewall o directorio con el nombre reservado;
- CPU, RAM, disco y GPU para decidir qué métricas son verificables.

La instalación no se construirá sobre supuestos. Tras revisar esa salida se fijarán
versión de Python/Glances, tarea programada, ACL, regla de firewall, autenticación,
pruebas y rollback.

## Inventario recibido

Ejecutado por `NILTON-PC\NILTO` el 30 de agosto de 2026 a las 09:14 CEST:

| Elemento | Resultado real |
|---|---|
| Sesión | usuario estándar, no elevada |
| Windows | Windows 11 Pro 10.0.26200, 64 bits |
| PowerShell | 5.1.26100.9278 |
| CPU / RAM | Intel i9-11900H / 16.840.433.664 bytes |
| Disco del sistema | 510.513.188.864 bytes |
| GPU | Intel UHD, NVIDIA RTX 3050 Laptop y driver virtual Oray |
| Tailscale | 1.102.3; IPv4 `100.105.88.14` |
| Python predeterminado | registro 3.13 roto; su ejecutable ya no existe |
| Python Hermes | 3.11.15 dentro del venv privado de Hermes; queda fuera de alcance |
| Python `uv` | registro de CPython 3.11.15; falta validar el ejecutable directo |
| Glances / 61208 | no instalado globalmente; puerto libre |
| Agente previo | sin directorio, tarea ni firewall con los nombres reservados |

La GPU NVIDIA no se habilita todavía: que aparezca en WMI no demuestra que Glances
pueda obtener telemetría fiable. La instalación debe usar un entorno propio y no reparar,
actualizar ni reutilizar el venv de Hermes.

### Puerta 5B-Python

Antes de crear archivos operativos se comprobará directamente la Python gestionada por
`uv`. Si existe y ejecuta 3.11.15, se usará solo como base para un venv independiente. El
instalador deberá elevarse para crear una regla de firewall limitada a Mac mini y una
tarea programada, sin alterar el Python global.

Estado: **aprobada**. El ejecutable CPython 3.11.15 de `uv` existe y arrancó. El pequeño
`-c` de comprobación sufrió únicamente el tratamiento de comillas de PowerShell 5.1; no
fue un fallo del intérprete. `uv.exe` está dentro del árbol de Hermes y no se utilizará.

## Paquete operativo preparado

Ruta: `clients/windows/homepage-metrics-agent/`.

- `Install-HomepageMetricsAgent.ps1`: eleva mediante UAC, crea un venv separado, fija
  Glances 4.5.6, genera credencial, configura firewall/tarea, arranca y llama a tests.
- `Start-HomepageMetricsAgent.ps1`: espera Tailscale y ejecuta únicamente la API en
  `100.105.88.14:61208`, sin WebUI, procesos, autodiscovery ni ejecución desde config.
- `Test-HomepageMetricsAgent.ps1`: valida listener, firewall, autenticación, versión,
  CPU, RAM, disco, uptime y ausencia de datos de procesos.
- `Copy-HomepageMetricsSecret.ps1`: lleva temporalmente el secreto DPAPI al portapapeles
  sin imprimirlo; se usará después para configurar Homepage fuera de Git.
- `Uninstall-HomepageMetricsAgent.ps1`: retira tarea/firewall y mueve archivos a backups
  fechados en vez de borrarlos.
- `Write-GlancesPassword.py`: recibe el secreto por stdin y almacena solo el hash Glances.

El instalador es deliberadamente de primera instalación: si encuentra cualquier objeto
reservado o 61208 ocupado, se detiene sin sobrescribir. Si falla después de activarse,
retira su tarea/firewall y conserva los archivos fallidos con fecha.

## Validación previa en el Mac mini

```text
Helper de password contra Glances 4.5.6: OK
Agente Windows de métricas: validación estática OK
Pruebas estáticas de Homepage: OK
Pruebas de Compose: OK
```

La siguiente puerta requiere ejecutar el instalador actualizado en Nilton PC y revisar
su test local antes de transferir el secreto o modificar Homepage.

## Primer intento de instalación

El venv independiente se creó correctamente, Glances 4.5.6 y sus dependencias se
instalaron, `pip check` no encontró inconsistencias y la API v4 pudo arrancar. El test
alcanzó la comprobación de credenciales después de validar tarea, listener, firewall,
versión y rechazo sin autenticación.

Se detuvo al importar `secret.dpapi`: `Get-Content -Raw` conservó el salto de línea final
escrito por `Set-Content`, y PowerShell 5.1 lo rechazó como formato DPAPI. La corrección
aplica `.Trim()` únicamente a la representación cifrada antes de descifrar; no cambia ni
expone el secreto. El exportador recibió la misma corrección.

El rollback automático retiró el endpoint remoto: una prueba posterior desde el
contenedor Homepage devolvió `NO_ENDPOINT`. Antes del segundo intento se comprobará
también en Windows que tarea, firewall, listener y ruta activa no existen. Los restos se
conservan en rutas `failed-*` para diagnóstico y no se borran.

La comprobación local posterior confirmó exactamente: tarea `False`, firewall `False`,
listeners 61208 `0` y directorio activo `False`. El equipo está limpio para repetir la
instalación; cualquier ruta `failed-*` continúa siendo solo evidencia recuperable.

## Segundo intento de instalación

La corrección DPAPI funcionó: el test superó lectura de secreto, autenticación, tarea,
listener, firewall y versión. Se detuvo después al convertir una respuesta métrica que
PowerShell 5.1 entregó como `System.Object[]` directamente a `System.Double`.

El validador ahora exige explícitamente un solo objeto para CPU, RAM y uptime, un solo
valor para cada campo numérico y usa `Convert.ToDouble` con cultura invariante. Si la API
real devolviera más de un valor, la prueba indicará el campo y la cardinalidad en vez de
elegir uno silenciosamente. El rollback volvió a retirar la ruta activa y Homepage
confirmó `NO_ENDPOINT`.

## Tercer intento de instalación

CPU, RAM y uptime pasaron la nueva validación escalar. El test se detuvo con
`Filesystem.size devolvio 2 valores`. La implementación de Glances 4.5.6 confirma que
cada entrada filesystem tiene un único `size`; los dos valores procedían de que
PowerShell 5.1 conservó el array JSON raíz como un objeto anidado, comportamiento ya
observado con `ConvertFrom-Json` durante la Fase 4.

La corrección enumera explícitamente cada elemento de `fs` y `processlist`. Para el
disco no selecciona el primer prefijo: exige exactamente una entrada cuyo `mnt_point`
sea `C:\`. Cero entradas o duplicados siguen siendo un fallo bloqueante. El endpoint
remoto volvió a quedar retirado por el rollback.

## Cuarto intento de instalación — privacidad de procesos

Las métricas base y el filesystem ya pasaron, pero `/api/4/processlist` continuó
devolviendo datos. La inspección del código de Glances 4.5.6 mostró que
`--disable-process` afecta presentación y actualización normal, mientras el método API
de `processlist` lee directamente la lista compartida de procesos.

No se relaja la prueba. El agente pasa a una allowlist explícita con únicamente
`quicklook`, `system`, `cpu`, `mem`, `fs` y `uptime`. `processcount`, `processlist` y
`programlist` deben faltar de `pluginslist`, y cada endpoint debe responder HTTP 400 por
plugin desconocido. Esto reduce además el resto de plugins que Homepage no necesita en
5B. El rollback volvió a dejar `NO_ENDPOINT`.

La allowlist se validó además en runtime con una instancia efímera de la misma imagen
Glances 4.5.6: `pluginslist` contiene los seis plugins permitidos y los endpoints
`processcount`, `processlist` y `programlist` devuelven HTTP 400.

## Agente Windows aprobado

El usuario ejecutó de nuevo la batería instalada y obtuvo:

```text
Pruebas del agente: OK; CPU=9.5%; RAM=16840433664; disco=510513188864; uptime_delta=0s
```

Desde el contenedor Homepage, `/api/4/status` responde HTTP 200 y `/api/4/cpu` sin
credenciales responde HTTP 401. Quedan demostrados ruta, firewall y autenticación desde
el consumidor real.

Se creó `scripts/set-nilton-pc-metrics-secret.sh` para recibir el secreto solo por stdin,
validar sus 43 caracteres Base64URL y guardarlo en `services/homepage/.env` con modo 600.
`.env` está ignorado por Git y el script no muestra su contenido. La configuración
operativa previa está respaldada en
`services/homepage/backups/20260830-fase-5b-nilton-pc/`.

La transferencia, tarjeta, recreación exclusiva y regresión se completaron después de
la corrección descrita a continuación.

## Primer intento de transferencia

El comando basado en el pipeline de PowerShell mostró una ejecución aceptada y otra
rechazada por formato. La inspección posterior, tomada como fuente de verdad, confirmó
que `services/homepage/.env` **no existe**; por tanto, el secreto no quedó configurado y
Homepage no se modificó ni recreó.

Se sustituye ese método ambiguo por `Send-HomepageMetricsSecret.ps1`. El script descifra
la copia DPAPI local solo en memoria y escribe una única línea directamente en stdin de
una única instancia de `ssh.exe`. No usa argumentos ni salida para el secreto y vacía el
portapapeles únicamente tras recibir código cero. La integración queda detenida hasta
comprobar en el Mac mini existencia, permisos y nombres de variables sin leer valores.

## Transferencia efectiva e integración

El receptor confirmó la escritura, pero Windows PowerShell 5.1 rechazó después
`Set-Clipboard -Value ''` porque convierte la cadena vacía en `null`. La transferencia
sí había terminado: la inspección real encontró `.env`, modo 600, propietario `bedvil`,
exactamente dos variables esperadas y regla activa de exclusión en Git. No se leyó ni
mostró ningún valor. El emisor se corrigió para sobrescribir el portapapeles con un
espacio inocuo en futuras ejecuciones.

Se añadió `🖥 EQUIPOS / Nilton PC` con widget Glances v4 compacto, MagicDNS, credenciales
`HOMEPAGE_VAR_*`, vista sin gráfica y refresco cada cinco segundos. Homepage 2.1.2 muestra
CPU/RAM en `metric: info`; disco y uptime continúan validados por el test dedicado sin
crear tarjetas duplicadas ni habilitar más plugins.

Solo se recreó `homepage`. Resultado: running, healthy, cero reinicios. Desde el propio
contenedor se verificaron credenciales inyectadas, `status` público, rechazo 401 para
CPU anónima, seis endpoints autenticados, RAM/disco dentro de tolerancia, allowlist
exacta y HTTP 400 para procesos/programas. El proxy real del widget también respondió.

La batería completa pasó: estática, Compose, runtime, Docker proxy, métricas locales,
PROD, DEV, herramientas, Nilton PC, HTTPS/Tailscale y regresión de n8n/Kuma/OpenClaw.

El usuario confirmó además que la tarjeta se ve y funciona desde Homepage.

## Prueba de caída aislada y cierre G5B

Con autorización del usuario se detuvo solamente la tarea `HomepageMetricsAgent`. En
Windows quedó `Ready` y no hubo listener 61208. Desde el contenedor Homepage, la API de
Nilton PC devolvió `ECONNREFUSED`, mientras Homepage siguió `running`, `healthy` y con
cero reinicios. La prueba de runtime pasó durante la caída.

Al iniciar de nuevo la tarea, el test local devolvió OK (CPU, RAM, disco y uptime) y el
test desde Homepage confirmó de nuevo API autenticada, privacidad, proxy del widget y
regresión. El usuario confirmó también la tarjeta visualmente.

Estado: **Fase 5B completada; G5B cerrada**.
