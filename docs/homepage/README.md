# Proyecto Homepage

Estado: **Fases 1–4 cerradas; Fase 5A documentada sin cambios operativos**.

Este directorio contiene la especificación, las puertas de control y las evidencias del
despliegue de Homepage. No se modificaron n8n, Uptime Kuma, OpenClaw ni SSH; en Tailscale
se añadió únicamente la regla dedicada de Homepage en 10000.

Orden de lectura:

1. [00-descubrimiento.md](00-descubrimiento.md): estado real y diferencias encontradas.
2. [SDD.md](SDD.md): diseño técnico propuesto.
3. [fases.md](fases.md): ejecución incremental y puntos de parada.
4. [pruebas.md](pruebas.md): criterios verificables y pruebas críticas.
5. [evidencias.md](evidencias.md): resultados registrados por cada puerta.
6. [fase-2-produccion.md](fase-2-produccion.md): descubrimiento, diseño y rollback PROD.
7. [fase-3-desarrollo.md](fase-3-desarrollo.md): VM, endpoints, separación y rollback DEV.
8. [fase-4-ia-administracion.md](fase-4-ia-administracion.md): herramientas, lanzador,
   pruebas y rollback.
9. [fase-5a-monitorizacion-equipos.md](fase-5a-monitorizacion-equipos.md): inventario,
   diseño seguro, métricas, fases y pruebas para PC y servidores.
10. [fase-5b-nilton-pc.md](fase-5b-nilton-pc.md): descubrimiento, despliegue y evidencia
    del primer agente Windows.

El teléfono está excluido de la monitorización por decisión del usuario. La integración
remota comenzará por Nilton PC en 5B y dejará PROD para el final.
