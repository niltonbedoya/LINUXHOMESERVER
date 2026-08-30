# Fase 4 — IA y Administración

Fecha: 30 de agosto de 2026.

Estado: **implementación y pruebas automáticas completadas; validación visual pendiente**.

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

## Subfase 4B — INTELIGENCIA ARTIFICIAL

Se creó `🤖 INTELIGENCIA ARTIFICIAL` con siete tarjetas y cuatro columnas. Todas son
enlaces simples: no contienen API keys, tokens, widgets, llamadas de modelo ni
integraciones con cuentas.

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

## Puerta G4

Pendiente de comprobación visual: verificar iconos, distribución y apertura de los diez
enlaces nuevos. La Fase 5 no debe iniciarse hasta que el usuario confirme G4.
