# Fase 5F — Integración y diseño final

Estado: **pendiente de confirmación visual final**.

## Primera limpieza visual aplicada

El usuario identificó redundancias en la vista real de Homepage. Se aplicó el siguiente
ajuste sin tocar agentes, servidores, contenedores ni Tailscale:

- `🖥 EQUIPOS` permanece como la única vista de recursos para Nilton PC, DEV y PROD.
- `🚨 PRODUCCIÓN` conserva únicamente `Tickets PROD`; se retiró el indicador simple
  `Servidor Ubuntu PROD`, redundante con la tarjeta de métricas completa.
- Se retiró el grupo `🧪 DESARROLLO / DEV` y sus enlaces `Tickets DEV` y `API DEV`.
  La VM y su agente Glances continúan operativos: `Servidor DEV` sigue en `EQUIPOS`.
- Se retiró `Tailscale Admin` de `🛠 ADMINISTRACIÓN`; `Tailscale` se conserva una sola
  vez en `🏠 HOME SERVER`.

La configuración pasa de diez a nueve grupos. Los tests verifican que las tarjetas
retiradas no reaparezcan, que Tickets PROD continúe disponible, que Tailscale aparezca
una sola vez y que las métricas de los tres equipos sigan privadas y funcionales.

## Validación técnica

Antes del cambio se creó el backup recuperable
`services/homepage/backups/20260830-fase-5f-layout-cleanup/`. Se recreó exclusivamente
el contenedor Homepage; quedó `running`, `healthy` y sin reinicios. El smoke test completo
pasó para Docker proxy, métricas locales, PROD, ausencia de accesos DEV, herramientas,
Nilton PC, DEV, PROD, Tailscale, n8n, Kuma y OpenClaw.

## Segunda iteración visual

Se fusionaron `HOME SERVER`, `EQUIPOS`, `PRODUCCIÓN` y `ADMINISTRACIÓN` bajo el único
grupo `🏠 HOME SERVER`. Para evitar otra duplicidad, Uptime Kuma se conserva una sola vez
y GitHub se trasladó a ese grupo. Las métricas de Nilton PC, DEV y PROD continúan ahí,
junto a Tickets PROD.

Los seis grupos visibles usan ocho columnas uniformes, reduciendo a la mitad el ancho
anterior de las tarjetas de cuatro columnas. Todas las descripciones se simplificaron a
una palabra. `Azure Dashboard` se añadió a `🧪 PLATAFORMAS IA` mediante el portal oficial
`https://portal.azure.com/`.

Se creó el backup `services/homepage/backups/20260830-fase-5f-unified-layout/`, se
recreó únicamente Homepage y el smoke test completo volvió a pasar. Pendiente: revisión
visual del usuario y los siguientes refinamientos que decida.

## Tercera iteración — cuadrícula uniforme

Se guardó una copia recuperable previa en
`services/homepage/backups/20260830-fase-5f-equal-grid/`. Homepage usa ahora las
opciones soportadas `fullWidth: true` y `useEqualHeights: true`, manteniendo ocho
columnas por grupo: cuatro tarjetas por cada mitad lógica de la pantalla. Las tarjetas
de cada fila adoptan la altura de la mayor, sin CSS personalizado frágil.

Solo se recreó Homepage. Volvió a `running`, `healthy` y sin reinicios; la batería
completa de smoke tests pasó. Pendiente: revisión visual del usuario.

## Cuarta iteración — dos columnas

La vista usa ahora dos grupos superiores sin encabezado (`IZQUIERDA` y `DERECHA`) con
subgrupos nativos. Izquierda contiene HOME SERVER e IDE; derecha contiene accesos rápidos,
LLM, agentes, terminales y plataformas. Cada sección usa cuatro tarjetas por fila (dos
en los accesos rápidos). El separador central se aplica mediante CSS mínimo.

Se retiraron los `ping` redundantes de las tres tarjetas Glances para eliminar el
solapamiento de puntos verdes con nombres de host. El backup previo está en
`services/homepage/backups/20260830-fase-5f-two-columns/`. Runtime y métricas de Nilton,
DEV y PROD pasaron; pendiente de confirmación visual.

## Quinta iteración — tormenta AB y prioridad de equipos

El usuario eligió como fondo una tormenta marina oscura, con un rayo vertical como
separador natural de las columnas. El activo versionado
`assets/storm-ab-background.png` integra el logotipo oficial AB: una versión metálica
con brillo púrpura/cian en la esquina superior derecha y otra grande, azul y tenue,
como marca de agua de fondo. Se monta en Homepage como recurso estático de solo lectura.

`HOME SERVER` prioriza ahora la información operativa: Nilton PC, DEV, PROD y Tickets
PROD ocupan la primera fila; n8n, Uptime Kuma, OpenClaw y Tailscale la segunda. GitHub y
GitHub Copilot dejan de estar aislados a la derecha y pasan a HOME SERVER. Cada uno ocupa
dos columnas mediante identificadores CSS estables, con el mismo ancho destacado que
tenían juntos anteriormente.

La copia recuperable previa se conserva en
`services/homepage/backups/20260830-fase-5f-storm-ab-background/`.

La validación estática, Compose y los tests runtime de Homepage, herramientas, interfaz
sin accesos DEV, producción, Nilton PC, DEV y PROD pasaron. El contenedor Homepage quedó
`running/healthy`, sin reinicios, y el recurso visual respondió desde
`/images/storm-ab-background.png`.

## Sexta iteración — corrección de altura y fondo efectivo

La revisión visual detectó dos defectos: `useEqualHeights` solo igualaba tarjetas dentro
de cada fila, por lo que los equipos seguían siendo menos altos que los servicios, y el
CSS aplicado al elemento `body` quedaba oculto por la capa de fondo propia de Homepage.

Se corrigió la altura mediante un mínimo de `10rem` para las tarjetas de HOME SERVER en
pantallas de escritorio. El fondo pasó a la opción oficial `background.image`, con
opacidad `35`, que Homepage coloca en su capa visual efectiva. La regeneración interna
`/api/revalidate` confirmó que el HTML activo contiene esa configuración. La copia previa
está en `services/homepage/backups/20260830-fase-5f-background-height-fix/`; Homepage,
el recurso visual y las métricas privadas de los tres equipos volvieron a pasar.

## Séptima iteración — capas y compactación final

La siguiente revisión visual afinó cuatro detalles: GitHub y GitHub Copilot tienen ahora
una altura fija de `5rem` (la mitad de las filas prioritarias); se retiró el borde blanco
central porque el rayo ya separa las columnas; las tarjetas reciben un fondo oscuro con
90 % de opacidad para que el logo AB permanezca detrás de ellas; y se oculta únicamente
el indicador de swap de Glances, que se solapaba con nombre y descripción de Nilton,
DEV y PROD. CPU y memoria siguen visibles en esas tres tarjetas.

La opacidad nativa del fondo se ajustó a `20` para recuperar el color púrpura/cian del
logo superior. La regeneración interna confirmó esa configuración activa. El backup
previo es `services/homepage/backups/20260830-fase-5f-polish-card-layers/`; validación
estática, runtime, herramientas y métricas de Nilton, DEV y PROD pasaron.

## Octava iteración — cristal y fondo vivo

La capa oscura de la séptima iteración reducía demasiado el efecto del fondo. Una primera
lectura interpretó al revés la semántica de `background.opacity`: Homepage usa
`1 - opacity / 100` como velo oscuro, por lo que `10` oscurecía un 90 %. Se corrigió al
valor `75` (velo oscuro del 25 %) y las tarjetas usan un 35 % de fondo oscuro, recuperando
la transparencia y el color sin perder legibilidad. La copia previa de esta corrección
está en `services/homepage/backups/20260830-fase-5f-opacity-semantics-fix/`.

Homepage fue regenerado y quedó healthy; las validaciones estática y runtime pasaron.

## Novena iteración — contraste de tarjetas

Tras la revisión visual, se mantuvo el fondo vivo y se elevó exclusivamente la capa de
las tarjetas del 35 % al 48 % para recuperar su presencia. `custom.css` se comprobó desde
la API de Homepage sin reiniciar el contenedor, que continuó healthy. La copia previa está
en `services/homepage/backups/20260830-fase-5f-card-opacity-48/`.

## Décima iteración — contraste 62 %

El usuario ajustó el contraste final de las tarjetas al 62 %, manteniendo el fondo y el
resto del diseño sin cambios. La copia previa está en
`services/homepage/backups/20260830-fase-5f-card-opacity-62/`; la validación estática y
la entrega dinámica de `custom.css` pasaron con Homepage healthy.

## Aceptación visual y ajuste posterior

El usuario aprobó expresamente la apariencia final el 30 de agosto de 2026. La Fase 5F
quedó cerrada de forma provisional. Posteriormente solicitó restaurar los indicadores
verdes de conectividad de Nilton PC, DEV y PROD; por ello queda pendiente una última
confirmación visual. Se conservan los backups de cada iteración para una reversión futura
controlada.

## Undécima iteración — indicadores de conectividad

Se restauró el `ping` privado por MagicDNS para Nilton PC, Servidor DEV y Servidor PROD,
que devuelve el punto verde en la esquina superior derecha de cada tarjeta. Los tres nodos
respondieron ICMP desde el contenedor Homepage y continúan accesibles mediante sus widgets
Glances. La copia previa está en
`services/homepage/backups/20260830-fase-5f-restore-equipment-status-dots/`; las
validaciones estáticas y de métricas pasaron con Homepage healthy. Falta solo confirmar
que visualmente los tres puntos no se solapan con el texto.
