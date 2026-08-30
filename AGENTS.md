# Instrucciones permanentes del repositorio

Este repositorio documenta y coordina el servidor doméstico Mac mini de `bedvil`.
Trabaja en español salvo que se pida otro idioma.

## Fuente de verdad

1. Los archivos y el estado real del servidor prevalecen sobre la documentación histórica.
2. Antes de cambiar algo, inspecciona el archivo completo y el servicio afectado.
3. Distingue siempre entre datos verificados ahora y datos heredados del contexto.
4. Después de un cambio confirmado, actualiza `docs/estado-actual.md` y, si procede,
   `docs/pendientes.md` o `docs/decisiones.md`.

## Límites estrictos

- `openclaw` es un enlace a `/home/bedvil/.openclaw/workspace` y lo administra el
  usuario desde la aplicación OpenClaw. No crear, editar, mover ni borrar nada dentro
  de `openclaw/` salvo petición explícita del usuario para ese archivo o tarea.
- `docker` es un enlace a `/home/bedvil/docker`. No modificar Compose, volúmenes ni
  datos persistentes salvo petición explícita.
- Nunca versionar ni mostrar tokens, claves, credenciales, archivos `.env`, bases de
  datos o contenido privado de los volúmenes.
- No usar `sudo` dentro de scripts de aplicación.
- No reiniciar servicios arbitrariamente. Primero identificar cómo se ejecutan,
  validar la configuración y reiniciar solo el componente necesario.
- No cambiar SSH ni desactivar `PasswordAuthentication` hasta comprobar en otra sesión
  que el acceso con clave sigue funcionando.
- Antes de editar configuración operativa, crear una copia de seguridad recuperable.

## Forma de trabajo

- Mantener soluciones simples y ligeras; evitar Kubernetes, máquinas virtuales pesadas
  y LLM locales grandes.
- Preferir Docker para servicios permanentes cuando tenga sentido.
- Usar Tailscale como acceso remoto principal y evitar exposición pública innecesaria.
- Separar responsabilidades: Uptime Kuma monitoriza, OpenClaw automatiza e interactúa,
  n8n orquesta workflows y Telegram sirve de interfaz/notificaciones.
- Hacer comprobaciones de solo lectura primero. Tener en cuenta que el sandbox de Codex
  puede bloquear Docker, systemd, red o crontab aunque funcionen en el host; confirmar
  fuera del aislamiento antes de diagnosticar un fallo real.
- Validar cada cambio con la herramienta apropiada antes de aplicarlo o reiniciar.

## Lectura inicial recomendada

1. `README.md`
2. `docs/estado-actual.md`
3. `docs/arquitectura.md`
4. El runbook o documento específico de la tarea
5. `docs/pendientes.md`

