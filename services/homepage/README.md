# Homepage — configuración operativa

Estado: Fase 4 completada y G4 cerrada; la implantación 5B de Nilton PC está operativa
y pendiente de confirmación visual/prueba de caída. Servidor, lanzador Windows, clics y
presentación previa están validados.
Homepage funciona localmente en
`127.0.0.1:3000` con estado Docker restringido y métricas reales del host, y está
publicado de forma privada en:

```text
https://macmini-server.tailf553c4.ts.net:10000/
```

Grupos actuales: HOME SERVER, EQUIPOS, PRODUCCIÓN, DESARROLLO/DEV, LLM Y CHAT IA, IDE Y
EDITORES, AGENTES Y CLI, TERMINALES Y SHELLS, PLATAFORMAS IA y ADMINISTRACIÓN.

Nilton PC ya aporta métricas privadas autenticadas. DEV, Raspberry Pi y PROD permanecen
pendientes. El teléfono queda excluido.

La credencial de Nilton PC se recibe exclusivamente por stdin mediante
`scripts/set-nilton-pc-metrics-secret.sh`. Se guarda en `.env` con modo 600, archivo
ignorado por Git. Nunca pasar el secreto como argumento ni pegarlo en documentación.

Los enlaces `homeserver-launch://` requieren instalar el cliente documentado en
`/home/bedvil/server/clients/windows/homepage-launcher`. El servidor no puede detectar
aplicaciones instaladas en Windows.

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
