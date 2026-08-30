# Homepage Launcher para Windows

Lanzador local del protocolo `homeserver-launch://`. Solo admite los identificadores
incluidos en `tools.json`: no ejecuta comandos, rutas ni argumentos recibidos desde la
web. Busca primero una aplicación registrada o un comando conocido y, si no existe,
abre exclusivamente la URL HTTPS oficial configurada como fallback. OpenCode es la única
excepción de ejecución: abre una Tab Config fija de Warp que usa Bash y ejecuta
`opencode.cmd`, sin aceptar argumentos desde Homepage.

## Instalación

Desde PowerShell en Windows, copiar esta carpeta desde el servidor y ejecutar:

```powershell
scp -r macmini:/home/bedvil/server/clients/windows/homepage-launcher "$env:TEMP\homepage-launcher"
Set-ExecutionPolicy -Scope Process RemoteSigned
& "$env:TEMP\homepage-launcher\Install-HomepageLauncher.ps1"
```

No requiere administrador. Instala los archivos del manejador en
`%LOCALAPPDATA%\HomepageLauncher` y registra el protocolo únicamente para el usuario
actual en `HKCU\Software\Classes\homeserver-launch`. También instala
`homepage_opencode.toml` en el directorio de Tab Configs de Warp; si ya existe con otro
contenido crea un backup fechado antes de sustituirlo.

## Pruebas

El instalador ejecuta automáticamente toda la batería. Para repetirla:

```powershell
& "$env:LOCALAPPDATA\HomepageLauncher\Test-HomepageLauncher.ps1" `
    -InstalledPath "$env:LOCALAPPDATA\HomepageLauncher"
```

La prueba resuelve todos los destinos sin abrir aplicaciones, confirma los programas
declarados como instalados y rechaza rutas, parámetros e identificadores no permitidos.

## Desinstalación

Elimina únicamente el registro y la copia local creados por este componente:

```powershell
& "$env:LOCALAPPDATA\HomepageLauncher\Uninstall-HomepageLauncher.ps1"
```
