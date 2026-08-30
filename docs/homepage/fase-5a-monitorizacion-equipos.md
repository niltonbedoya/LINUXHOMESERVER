# Fase 5A — Monitorización de equipos

Estado: **descubrimiento y SDD completados; no se ha instalado ni desplegado nada**.

Fecha de verificación: 30 de agosto de 2026, zona `Europe/Madrid`.

## 1. Objetivo y límites

Homepage mostrará una vista compacta de recursos reales de cuatro equipos remotos:

- Nilton PC (Windows).
- servidor Ubuntu DEV.
- Raspberry Pi actual.
- servidor Ubuntu PROD.

El teléfono queda fuera del inventario y de todas las fases: no se instalarán agentes,
sensores ni tareas periódicas en Android. El futuro NAS y sus discos también quedan fuera;
la Raspberry Pi de esta fase solo aportará métricas de su sistema actual.

Homepage será un resumen visual. Uptime Kuma conserva alertas e histórico y no se
duplicará esa responsabilidad.

## 2. Estado real descubierto

| Equipo | MagicDNS canónico | IP observada | Estado Tailscale | API Glances 61208 |
|---|---|---:|---|---|
| Mac mini | `macmini-server.tailf553c4.ts.net` | `100.72.206.57` | online | interna a Compose |
| Nilton PC | `nilton-pc.tailf553c4.ts.net` | `100.105.88.14` | online/activo | no disponible |
| DEV | `tickets-server-dev.tailf553c4.ts.net` | `100.80.93.74` | online/activo | no disponible |
| Raspberry Pi | `raspberrypi.tailf553c4.ts.net` | `100.65.215.4` | online | no disponible |
| PROD | `servicio-tickets-definitivo.tailf553c4.ts.net` | `100.113.199.93` | online/activo | no disponible |

Las IP son evidencia puntual, no configuración. Los consumidores usarán MagicDNS. Una
prueba desde el contenedor `homepage` no encontró `/api/4/status` en ninguno de los
cuatro destinos remotos; esto es el estado esperado antes de instalar agentes, no un
fallo de los equipos.

Homepage, `homepage-dockerproxy` y `homepage-glances` estaban activos; Homepage estaba
`healthy` y continuaba publicado solo en `127.0.0.1:3000`.

## 3. Diseño elegido

Cada equipo ejecutará su propia instancia fijada de Glances en modo web. Homepage la
consultará por MagicDNS a través de Tailscale:

```text
Homepage (Mac mini)
    ├── Tailscale → Glances Nilton PC
    ├── Tailscale → Glances DEV
    ├── Tailscale → Glances Raspberry Pi
    └── Tailscale → Glances PROD
```

No se abrirán puertos en el router ni se usará Funnel. Cada agente debe:

- escuchar solo en su dirección Tailscale, nunca en `0.0.0.0`, LAN o Internet;
- exigir autenticación y usar una contraseña distinta por equipo;
- desactivar autodetección y publicación externa;
- arrancar automáticamente sin depender de una sesión interactiva;
- ejecutarse sin `sudo` dentro del proceso y con permisos mínimos;
- evitar Docker socket y acceso innecesario a datos de aplicaciones.

Las credenciales no se escribirán en YAML ni en Git. Antes de 5B se demostrará la
inyección mediante variables `HOMEPAGE_VAR_*` desde un `.env` local ignorado. Si esa
ruta no pasa una prueba controlada, la puerta se detendrá antes de exponer una API.

En Windows se decidirá el mecanismo exacto después de inspeccionar Python, Glances y el
Programador de tareas. En Linux se prefiere un entorno Python aislado y un servicio
systemd dedicado. No se añadirá el agente a los Compose de Tickets ni se reiniciarán sus
aplicaciones.

## 4. Métricas previstas

| Equipo | Métricas base | Métricas condicionadas |
|---|---|---|
| Nilton PC | CPU, RAM, filesystem, uptime | red y GPU si la API real las valida |
| DEV | CPU, RAM, disco, uptime | red; sin temperatura si la VM no expone sensor |
| Raspberry Pi | CPU, RAM, raíz, uptime | red y temperatura CPU si coincide con el host |
| PROD | CPU, RAM, disco, uptime | red y temperatura solo si son fiables |

La temperatura de Windows se omite inicialmente porque los sensores de Glances están
documentados para Linux. Ninguna GPU se mostrará por inferencia: solo se habilitará si el
hardware, el controlador y la API devuelven una lectura comprobable.

## 5. Presentación en Homepage

Se añadirá un grupo propio `🖥 EQUIPOS` con una tarjeta compacta por dispositivo. No se
llenará la cabecera con cuatro widgets expandidos. El ajuste visual definitivo se hará
cuando existan datos reales de todos los nodos, para decidir columnas, altura y orden
con evidencia y no con marcadores ficticios.

Un equipo apagado debe degradar únicamente su tarjeta. La página, las tarjetas actuales
y las métricas locales del Mac mini deben continuar funcionando.

## 6. Fases y puertas

1. **5A — Descubrimiento y SDD:** este documento; sin cambios operativos.
2. **5B — Nilton PC:** primer despliegue y validación del patrón Windows.
3. **5C — DEV:** patrón Linux en la VM, sin modificar la aplicación de Tickets.
4. **5D — Raspberry Pi:** patrón Linux ARM y sensor térmico si es fiable.
5. **5E — PROD:** último despliegue, tras reutilizar el patrón ya probado.
6. **5F — Integración y diseño:** tarjetas, pruebas de fallo aislado y refinamiento visual.

Cada fase necesita inventario previo, backup recuperable de su configuración, pruebas y
rollback independiente. Un fallo grave de seguridad, acceso o regresión bloquea las
fases siguientes.

## 7. Pruebas obligatorias por equipo

- Registrar SO, arquitectura, versión de Tailscale y método de arranque real.
- Fijar y comprobar versión de Glances; no usar una dependencia flotante.
- Confirmar el listener exclusivamente en la IP Tailscale y el puerto acordado.
- Rechazar una consulta sin credenciales y aceptar la misma consulta autenticada.
- Validar `/api/4/status`, CPU, memoria, filesystem y uptime.
- Comparar RAM, disco y uptime con comandos nativos; CPU solo debe estar entre 0–100 %.
- Validar sensores, red o GPU únicamente cuando vayan a mostrarse.
- Consultar la API desde el contenedor Homepage, no solo desde el propio equipo.
- Confirmar que apagar o bloquear el agente no rompe Homepage.
- Verificar que no existen secretos versionados ni exposición por LAN/Internet.
- Repetir la regresión completa de Homepage, Tailscale, n8n, Kuma y OpenClaw.

Tolerancias iniciales: RAM 5 %, disco 2 %, uptime 60 segundos y temperatura Linux 5 °C.
Una discrepancia sostenida obliga a omitir la métrica, no a ampliar silenciosamente el
margen.

## 8. Rollback general

Cada equipo tendrá un rollback propio: detener y deshabilitar solo su agente, retirar su
listener y restaurar su archivo respaldado. En el Mac mini se retirará únicamente la
tarjeta correspondiente y sus variables locales. No se usará `tailscale serve reset`,
no se tocarán las reglas 443/8443/10000 y no se reiniciarán aplicaciones ajenas.

## 9. Referencias técnicas

- [Widget informativo Glances de Homepage](https://gethomepage.dev/widgets/info/glances/)
- [Widget de servicio Glances de Homepage](https://gethomepage.dev/widgets/services/glances/)
- [Variables de entorno de Homepage](https://gethomepage.dev/configs/settings/#environment-variables)
- [Documentación de Glances](https://glances.readthedocs.io/en/latest/)
- [CLI y opciones web de Glances](https://glances.readthedocs.io/en/latest/glances.html)
- [API REST y seguridad de Glances](https://glances.readthedocs.io/en/develop/api/restful.html)
- [Conexión entre dispositivos Tailscale](https://tailscale.com/kb/1452/connect-to-devices)

