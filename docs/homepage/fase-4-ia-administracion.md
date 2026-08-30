# Fase 4 — IA y Administración

Fecha: 30 de agosto de 2026.

Estado: **completada; G4 cerrada tras validación funcional y visual del usuario**.

## Subfase 4A — Descubrimiento y selección de enlaces

Se verificaron los destinos sin iniciar sesión ni almacenar credenciales:

| Herramienta | URL elegida | Resultado automático |
|---|---|---|
| ChatGPT | `https://chatgpt.com/` | TLS válido; protección HTTP 403 para cliente automatizado |
| Codex | `https://chatgpt.com/codex` | TLS válido; protección HTTP 403 para cliente automatizado |
| Antigravity | `https://antigravity.google.com/` | HTTP 200 y URL canónica declarada |
| GitHub Copilot | `https://github.com/copilot` | HTTP 200 |
| Google AI Studio | `https://aistudio.google.com/` | HTTP 200; redirige a `/welcome` |
| Gemini | `https://gemini.google.com/` | HTTP 200 |
| NVIDIA Build | `https://build.nvidia.com/` | HTTP 200 |

Para Administración se conservaron los destinos ya verificados de Tailscale Admin y
Uptime Kuma, y se añadió `https://github.com/`. No se usaron perfiles personales ni URLs
supuestas.

## Subfase 4B — Primera versión de INTELIGENCIA ARTIFICIAL

Se creó `🤖 INTELIGENCIA ARTIFICIAL` con siete tarjetas y cuatro columnas. Todas son
enlaces simples: no contienen API keys, tokens, widgets, llamadas de modelo ni
integraciones con cuentas.

Esta fue la primera versión aprobada para continuar. Después se amplió y reclasificó en
4E a petición del usuario; no representa ya la configuración activa.

## Subfase 4C — ADMINISTRACIÓN

Se creó `🛠 ADMINISTRACIÓN` con tres tarjetas:

1. Tailscale Admin.
2. Uptime Kuma Admin.
3. GitHub.

Tailscale y Kuma también permanecen en HOME SERVER para no alterar la base ya aprobada.
Las tarjetas administrativas son accesos directos y no duplican monitorización ni
permisos Docker.

## Subfase 4D — Pruebas y regresiones

- Configuración estática y Compose correctos.
- `/api/services`: exactamente cinco grupos, siete enlaces IA y tres administrativos.
- URLs HTTPS: certificado válido y respuestas aceptables; 401/403 solo se admite para
  portales que protegen el acceso automatizado.
- Uptime Kuma Admin continúa respondiendo.
- Ninguna tarjeta nueva contiene widgets, Docker, ping, siteMonitor o patrones secretos.
- HOME, PROD y DEV conservan exactamente sus destinos y tests.
- Tailscale Serve conserva 443, 8443 y 10000.
- Homepage continúa `healthy`, sin reinicios ni errores bloqueantes nuevos.

La primera ejecución detectó dos supuestos incorrectos en los propios tests: Homepage
añade `widgets: []` al runtime de enlaces simples y el validador DEV no admitía grupos de
fases posteriores. Se corrigieron manteniendo bloqueados los widgets no vacíos y todos
los destinos DEV. Una muestra térmica quedó 7 °C desfasada; la repetición inmediata y la
batería final coincidieron a 53 °C dentro de tolerancia. No se amplió la tolerancia.

## Backup y rollback

Backup previo, ignorado por Git:

```text
services/homepage/backups/20260830-fase-4/
```

Para volver a G3, restaurar `services.yaml`, `settings.yaml`, `static.sh` y
`smoke-test.sh` desde el backup; retirar `phase4.sh` y `phase4_validate.py`, y restaurar
el validador DEV previo. No tocar Compose, contenedores, Tailscale ni servicios externos.
No ejecutar sin petición explícita.

## Subfase 4E — Clasificación ampliada

El inventario solicitado se filtró para conservar herramientas con modalidad gratuita
real o aquellas para las que el usuario ya dispone de cuenta. La configuración activa
separa ahora:

| Grupo | Contenido |
|---|---|
| `🧠 LLM Y CHAT IA` | ChatGPT, Gemini, Claude, Perplexity, Grok, Microsoft Copilot y Mistral Vibe |
| `🧑‍💻 IDE Y EDITORES` | VS Code, Cursor, Antigravity, Zed, Visual Studio Community y JetBrains IDEs |
| `🤖 AGENTES Y CLI` | Hermes Desktop/Agent, Codex CLI, OpenCode, Aider y GitHub Copilot |
| `⌨️ TERMINALES Y SHELLS` | Warp, PowerShell y WSL |
| `🧪 PLATAFORMAS IA` | Google AI Studio y NVIDIA Build |

Gemini permanece como chat web, pero Gemini CLI se omitió porque Google retiró su uso
para cuentas individuales en favor de Antigravity CLI. Claude web permanece por su plan
gratuito; Claude Code se omitió porque requiere un plan de pago. Mistral Le Chat aparece
con su nombre actual, Mistral Vibe.

## Subfase 4F — Homepage Launcher para Windows

El inventario real entregado por el usuario confirmó estos AppID:

- `Microsoft.VisualStudioCode`.
- `Anysphere.Cursor`.
- `com.google.antigravity`.
- `com.nousresearch.hermes`.
- `dev.warp.Warp`.
- Windows PowerShell del sistema.

Se creó `clients/windows/homepage-launcher` con:

- catálogo JSON de 13 destinos tras retirar Windows Terminal por duplicar PowerShell;
- manejador `homeserver-launch://`;
- instalación y desinstalación por usuario en HKCU, sin administrador;
- test PowerShell que resuelve todos los destinos sin abrirlos;
- validador Linux para catálogo, AppID y protecciones del manejador.

El manejador solo acepta `homeserver-launch://<id>` sin ruta, puerto, query, fragmento,
usuario ni argumentos. Busca primero AppID o un ejecutable conocido; si no existe abre
el fallback HTTPS fijo del catálogo. No usa `Invoke-Expression`, `cmd /c` ni comandos
recibidos desde Homepage.

OpenCode usa una Tab Config moderna de Warp en lugar de ejecutarse como proceso suelto.
La configuración fija `bash` y `opencode.cmd` y se abre con
`warp://tab_config/homepage_opencode`. Windows Terminal se retiró posteriormente por
duplicar PowerShell; el catálogo final previsto contiene 13 destinos.

## Backup y rollback de la ampliación

Backup previo, ignorado por Git:

```text
services/homepage/backups/20260830-fase-4-launcher/
```

El rollback del servidor restaura desde ese backup los YAML y tests anteriores. El
rollback de Windows ejecuta `Uninstall-HomepageLauncher.ps1`, que retira únicamente la
clave HKCU y `%LOCALAPPDATA%\HomepageLauncher`. No ejecutar ninguno sin petición.

## Puerta G4 — cerrada

La parte servidor pasó configuración estática, runtime, enlaces externos, HOME, PROD,
DEV, métricas, proxy Docker, Tailscale y regresiones. El instalador Windows pasó su
batería de 13 destinos y las pruebas negativas de seguridad. El usuario confirmó:

1. apertura local de VS Code, Cursor, Antigravity, Hermes, Warp y PowerShell;
2. fallbacks web para herramientas ausentes;
3. retirada de Windows Terminal por redundancia;
4. OpenCode 1.18.25 funcionando dentro de Warp/Git Bash;
5. iconos y distribución visual correctos.

G4 queda cerrada. La Fase 5 puede iniciarse únicamente cuando el usuario la solicite.
