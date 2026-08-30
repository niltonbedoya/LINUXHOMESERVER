# LINUXHOMESERVER

Servidor doméstico Linux que centraliza y autoaloja múltiples servicios de productividad, automatización, inteligencia artificial y red privada virtual.

---

## 🖥️ ¿Qué es este proyecto?

**LINUXHOMESERVER** es una infraestructura de servidor en casa (homelab) basada en Linux. El objetivo es tener control total sobre los datos y los servicios, evitando depender de plataformas en la nube de terceros. Todos los servicios se despliegan de forma local (o en una VPS propia) y se gestionan desde este repositorio.

---

## 🛠️ Servicios alojados

| Servicio | Descripción |
|---|---|
| **VPN** | Red Privada Virtual para acceder de forma segura al servidor desde cualquier lugar. Permite conectarse a los servicios como si estuvieras en la red local. |
| **N8N** | Plataforma de automatización de flujos de trabajo de código abierto (similar a Zapier). Permite crear integraciones entre aplicaciones y automatizar tareas repetitivas. |
| **OpenClaw** | Servicio/herramienta alojada en el servidor (pendiente de descripción detallada al agregar configuración). |

> **Nota:** Esta tabla se actualizará automáticamente a medida que se agreguen nuevos servicios al repositorio.

---

## 📁 Estructura del repositorio

```
LINUXHOMESERVER/
├── README.md          # Este archivo — descripción general del proyecto
└── (configuraciones de servicios por agregar)
```

---

## 🚀 Objetivo

- Autoalojar servicios que normalmente estarían en la nube.
- Mantener privacidad y control total sobre los datos.
- Automatizar tareas del hogar y del trabajo con N8N.
- Conectarse de forma segura desde cualquier dispositivo mediante VPN.
- Escalar con nuevos servicios según las necesidades.

---

## 📝 Notas

- El repositorio está en desarrollo activo.
- Las configuraciones específicas de cada servicio (docker-compose, scripts, etc.) se irán agregando en las próximas actualizaciones.
# Mac mini Home Server

Repositorio central de documentación y coordinación del servidor doméstico Mac mini
2014. El servidor usa Linux Mint, Docker, Tailscale, OpenClaw, n8n, Uptime Kuma y
Telegram.

## Principios

- Servidor ligero, sencillo y encendido permanentemente.
- Tailscale y SSH con clave como acceso remoto principal.
- Servicios persistentes en Docker cuando resulte adecuado.
- Sin exposición pública innecesaria, Kubernetes, VM pesadas ni LLM locales grandes.
- Una responsabilidad clara por herramienta:
  - Uptime Kuma: monitorización.
  - OpenClaw: agentes, automatización e interacción.
  - n8n: workflows e integraciones.
  - Telegram: interfaz móvil y notificaciones.

## Estructura

```text
/home/bedvil/server/
├── AGENTS.md                    reglas permanentes para asistentes
├── README.md                    entrada al proyecto
├── services/
│   └── homepage/                configuración versionada del dashboard
├── docs/
│   ├── arquitectura.md          componentes, rutas y relaciones
│   ├── decisiones.md            decisiones técnicas vigentes
│   ├── estado-actual.md         inventario verificado e histórico
│   ├── homepage/                SDD, fases, pruebas y evidencias del dashboard
│   ├── openclaw-telegram.md     contexto y runbook del bot
│   ├── operaciones.md           comprobaciones seguras y backups
│   ├── pendientes.md            trabajo priorizado
│   └── seguridad-y-red.md       acceso remoto y riesgos conocidos
├── docker -> /home/bedvil/docker
└── openclaw -> /home/bedvil/.openclaw/workspace
```

Los enlaces `docker` y `openclaw` apuntan fuera de este directorio. El repositorio
central versiona la documentación y los enlaces, no copia automáticamente el contenido
de los destinos. OpenClaw no se modifica desde aquí salvo petición explícita.

El entorno habitual es VS Code en Windows conectado mediante Remote SSH al alias
`macmini`. Las herramientas registradas son Antigravity, Codex con cuenta de empresa y
GitHub Copilot Pro; Antigravity sustituyó el uso directo anterior de Gemini.

## Estado resumido

Comprobado el 30 de agosto de 2026:

- Linux Mint 22.3 y kernel 6.14.0-37-generic.
- Docker 29.1.3 y Compose 2.40.3.
- `n8n` y `uptime-kuma` están activos.
- Homepage está healthy, con estado Docker restringido y métricas reales, y disponible
  por HTTPS privado en `https://macmini-server.tailf553c4.ts.net:10000/`; separa HOME,
  EQUIPOS, PROD, DEV, LLM, IDE, agentes/CLI, terminales, plataformas IA y Administración.
- El lanzador Windows seguro de Fase 4 está instalado y validado con 13 destinos; G4
  quedó cerrada tras confirmar aplicaciones, fallbacks, OpenCode en Warp y diseño.
- Tailscale está activo.
- El bot de Telegram se inicia al arrancar mediante `telegram_bot_loop.sh`.
- El acceso real a Docker funciona para `bedvil`; el sandbox de Codex puede bloquearlo.
- La Fase 5B de Homepage ya obtiene métricas privadas de Nilton PC mediante Glances
  autenticado sobre Tailscale. DEV, Raspberry Pi y PROD siguen pendientes; el teléfono
  está excluido.

Consulta [docs/estado-actual.md](docs/estado-actual.md) antes de operar y
[docs/pendientes.md](docs/pendientes.md) antes de iniciar trabajo nuevo.
