# Homepage Metrics Agent para Windows

Estado: **agente instalado y validado; integración con Homepage en curso**.

Este directorio contendrá el agente Glances de Nilton PC, su instalación reproducible,
pruebas y desinstalación. El objetivo es exponer métricas únicamente al Mac mini por
Tailscale, con autenticación y sin publicar datos en la LAN.

La primera comprobación remota confirmó que Nilton PC está online en Tailscale, pero no
tiene SSH escuchando en el puerto 22. No se instalará SSH para esta tarea.

## Inventario de solo lectura

Desde PowerShell, copiar el directorio desde el Mac mini y ejecutar:

```powershell
$stage = Join-Path $env:TEMP ("homepage-metrics-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
scp -r macmini:/home/bedvil/server/clients/windows/homepage-metrics-agent $stage
Set-ExecutionPolicy -Scope Process RemoteSigned
& "$stage\Get-HomepageMetricsInventory.ps1"
```

El inventario no instala paquetes, no crea tareas y no cambia el firewall. Su salida se
usa para fijar el método de instalación antes de crear la parte operativa de 5B.

## Diseño resultante del inventario

- Base: CPython 3.11.15 gestionada por `uv`, comprobada directamente.
- Aislamiento: venv nuevo en `C:\ProgramData\HomepageMetricsAgent`.
- Hermes: no se usa su Python, su venv ni su `uv.exe`.
- Glances: versión fijada 4.5.6 con extras web.
- API: solo `100.105.88.14:61208`, autenticación Basic y WebUI deshabilitada.
- Privacidad: allowlist limitada a `quicklook`, `system`, `cpu`, `mem`, `fs` y `uptime`;
  procesos, autodiscovery, información pública y ejecución desde config deshabilitados.
- Firewall: acepta únicamente al Mac mini `100.72.206.57` por Tailscale.
- Inicio: tarea `HomepageMetricsAgent` como SYSTEM al arrancar; espera la interfaz
  Tailscale antes de iniciar.
- Secreto: hash de Glances bajo ACL administrativa y copia clara solo como DPAPI del
  usuario. Nunca se imprime ni se versiona.

## Instalación

El script solicita elevación UAC, instala en un directorio nuevo, registra firewall y
tarea, arranca el agente y ejecuta la batería local completa:

```powershell
& "$stage\Install-HomepageMetricsAgent.ps1"
```

No cerrar la ventana elevada mientras instala dependencias. Al finalizar copia el
secreto al portapapeles sin mostrarlo. No pegarlo en el chat.

## Transferencia del secreto a Homepage

El método preferido no usa el portapapeles: descifra la copia DPAPI únicamente en
memoria y escribe el valor en la entrada estándar de una sola instancia de SSH. El
secreto no forma parte del comando ni se muestra en la salida:

```powershell
scp macmini:/home/bedvil/server/clients/windows/homepage-metrics-agent/Send-HomepageMetricsSecret.ps1 "$env:TEMP\Send-HomepageMetricsSecret.ps1"
& "$env:TEMP\Send-HomepageMetricsSecret.ps1"
```

El receptor del Mac mini valida el formato antes de escribir y guarda `.env` con modo
600. El script sobrescribe además el portapapeles con contenido inocuo solo después de
una transferencia exitosa; usa un espacio por compatibilidad con PowerShell 5.1.

## Pruebas repetibles

```powershell
& "$env:ProgramData\HomepageMetricsAgent\Test-HomepageMetricsAgent.ps1"
```

Comprueba tarea, listener, firewall, versión, rechazo sin autenticación, CPU, RAM, disco,
uptime, allowlist y rechazo HTTP de los tres plugins de procesos.

## Rollback

```powershell
& "$env:ProgramData\HomepageMetricsAgent\Uninstall-HomepageMetricsAgent.ps1"
```

Solicita elevación, retira únicamente tarea y firewall propios, y mueve archivos/secreto
a rutas fechadas recuperables en vez de borrarlos.
