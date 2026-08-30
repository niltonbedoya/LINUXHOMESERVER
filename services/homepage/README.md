# Homepage — configuración operativa

Estado: Fase 4 completada en el servidor y pendiente de validación visual. Homepage funciona localmente en
`127.0.0.1:3000` con estado Docker restringido y métricas reales del host, y está
publicado de forma privada en:

```text
https://macmini-server.tailf553c4.ts.net:10000/
```

Grupos actuales: `🏠 HOME SERVER`, `🚨 PRODUCCIÓN`, `🧪 DESARROLLO / DEV`,
`🤖 INTELIGENCIA ARTIFICIAL` y `🛠 ADMINISTRACIÓN`.

Ruta versionada:

```text
/home/bedvil/server/services/homepage
```

Ruta operativa prevista:

```text
/home/bedvil/docker/homepage
```

La ruta operativa es un enlace a este directorio para mantener los archivos dentro del
repositorio principal.

Validación completa:

```bash
./scripts/validate.sh
./scripts/smoke-test.sh
```

Para reaplicar de forma idempotente la regla HTTPS y ejecutar las pruebas:

```bash
./scripts/publish-tailscale.sh
```

El rollback de red debe retirar solo 10000 con `tailscale serve --https=10000 off`;
nunca usar `tailscale serve reset`.
