# Proyecto Homepage

Estado: **Fases 1, 2 y 3 cerradas; Fase 4 implementada y pendiente de validación visual**.

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
8. [fase-4-ia-administracion.md](fase-4-ia-administracion.md): enlaces, pruebas y rollback.

PROD, DEV e IA quedan fuera de la primera entrega y requieren confirmación explícita.
