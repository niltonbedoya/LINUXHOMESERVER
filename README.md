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
