# Seguridad y red

## Acceso remoto

La vía principal es Tailscale. Datos históricos pendientes de reconfirmar cuando una tarea
dependa de ellos:

- LAN: `192.168.1.43`.
- Tailscale: `100.72.206.57`.
- El Mac mini actúa como Exit Node.

SSH funciona con el usuario `bedvil`. En Windows se usa este alias:

```sshconfig
Host macmini
    HostName 100.72.206.57
    User bedvil
```

Existe autenticación ED25519 y la clave pública está instalada en
`/home/bedvil/.ssh/authorized_keys`. No copiar claves privadas al repositorio.

## Regla SSH

No desactivar aún `PasswordAuthentication`. Cualquier endurecimiento debe:

1. conservar una sesión existente;
2. validar sintaxis de SSH;
3. probar una segunda conexión por clave;
4. disponer de recuperación local antes de recargar el servicio.

## HTTPS privado de n8n

n8n usa actualmente:

- URL: `https://macmini-server.tailf553c4.ts.net:8443/`.
- TLS terminado por Tailscale Serve.
- Upstream local: `http://127.0.0.1:5678`.
- `N8N_SECURE_COOKIE=true`.
- `N8N_PROXY_HOPS=1`.
- Puerto Docker ligado solo al loopback; ya no existe acceso HTTP directo por la LAN.

El puerto 443 ya pertenece a otro servicio del servidor, por lo que n8n utiliza 8443. Se
usó Tailscale Serve, no Funnel: el servicio debe permanecer accesible únicamente para los
dispositivos autorizados de la tailnet.

La comprobación del servidor confirmó certificado válido y `/healthz` con HTTP 200. Falta
la comprobación funcional desde otro dispositivo: inicio de sesión, editor y ejecución de
un workflow con webhook.

## HTTPS privado de Homepage

Homepage usa `https://macmini-server.tailf553c4.ts.net:10000/`, terminado por Tailscale
Serve y disponible solo dentro de la tailnet. Su upstream es
`http://127.0.0.1:3000`; Docker no publica 3000 en la LAN. La validación confirmó TLS
correcto, HTTP 200, rechazo de `192.168.1.43:3000` y conservación exacta de las reglas
443 y 8443. No se habilitó Funnel.

## Acceso al entorno DEV

La VM `tickets-server-dev` permanece detrás del NAT de VirtualBox y no requiere puertos
del router. Tailscale se ejecuta dentro del invitado y proporciona MagicDNS e IP privada.
El frontend 5173 y el backend Docker 18000 usan HTTP de aplicación, pero solo se enlazan
mediante la tailnet; no están publicados como servicios de Internet. CORS admite el
origen MagicDNS exacto del frontend. SSH usa `nilton` por el puerto 22 de Tailscale. No
almacenar su contraseña o claves privadas en este repositorio.

## Secretos y datos sensibles

Las tarjetas de IA y Administración son enlaces simples. No contienen API keys, tokens,
cookies, usuarios ni widgets de proveedor. Cada servicio externo conserva su propia
autenticación. Uptime Kuma Admin sigue usando su acceso Tailscale actual; Homepage no
recibe sus credenciales.

- No versionar `TOOLS.md`, tokens de Telegram, claves de API, `.env`, claves SSH ni
  credenciales de n8n.
- No versionar bases de datos ni volúmenes persistentes.
- No imprimir configuraciones completas si podrían contener valores secretos; seleccionar
  solo campos no sensibles.
- Vaultwarden, AdGuard Home y cualquier servicio que afecte credenciales o DNS requieren
  un diseño de seguridad específico antes de instalarse.
