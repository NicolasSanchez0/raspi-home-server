# 🏠 Raspberry Pi Home Server

Servidor doméstico en una **Raspberry Pi 4 (1 GB)** pensado para **privacidad y acceso remoto**: bloqueo de anuncios a nivel de red, nube y música propias, un panel de control y una VPN para acceder a todo desde fuera de casa.

> Proyecto personal de aprendizaje en administración de sistemas Linux, redes y ciberseguridad.

## 🧰 Tecnologías

| Servicio | Función | Puerto |
|---|---|---|
| **Linux (Raspberry Pi OS)** | Sistema base | - |
| **Docker + Portainer** | Contenedores y gestión de stacks (Compose) por web | - |
| **WireGuard (PiVPN)** | VPN para acceso remoto seguro | UDP 51820 |
| **Pi-hole** | DNS propio con bloqueo de anuncios y rastreadores | 53, 8080 |
| **Nginx Proxy Manager** | Proxy inverso: un nombre local (`*.home`) por servicio | 80, 81, 443 |
| **Nextcloud + MariaDB** | Nube personal, datos en disco USB externo | 8082 |
| **Navidrome** | Servidor de música en streaming | 4533 |
| **Homarr** | Panel de inicio con acceso a todos los servicios | 7575 |
| **DuckDNS** | DNS dinámico (la IP pública de casa cambia) | - |

## 🗺️ Arquitectura

```
                    Internet
                       │
       tu-dominio.duckdns.org  ◄── contenedor DuckDNS (cada 5 min)
                       │
                 Router (NAT)
                       │
                  UDP 51820
                       │
               WireGuard (PiVPN)
                       │
   Clientes VPN (móvil, portátil) ──► DNS por Pi-hole (nombres *.home)
                       │
              Nginx Proxy Manager       red Docker "proxy_net"
        ┌──────────┬───┴──────┬──────────┐
    Nextcloud   Navidrome   Homarr   Pi-hole / Portainer
```

## 📁 Estructura del repositorio

```
.
├── docker/
│   ├── pi-hole/
│   ├── nginx-proxy-manager/
│   ├── nextcloud/
│   ├── navidrome/
│   ├── homarr/
│   └── duckdns/             # actualizador en contenedor
├── docs/
│   └── instalacion.md       # comandos y pasos de la instalación
├── wireguard/
│   └── wg0.conf.example     # plantilla sin claves
├── .env.example
└── .gitignore
```

> 📖 Los comandos de instalación están en [`docs/instalacion.md`](docs/instalacion.md).

## 🚀 Puesta en marcha

```bash
git clone https://github.com/NicolasSanchez0/raspi-home-server.git
cd raspi-home-server
cp .env.example .env && nano .env      # rellena tus datos (no se sube a Git)

# Red compartida por varios servicios (una sola vez)
docker network create proxy_net

# Levantar un servicio (ejemplo: Pi-hole)
cd docker/pi-hole
docker compose --env-file ../../.env up -d
```

Antes de arrancar, sustituye en los compose `TU_USUARIO` (tu usuario de Linux) y `TU_DISCO_USB` (punto de montaje de tu disco).

En **Portainer**, cada carpeta `docker/<servicio>` se despliega como un *stack*: pega el compose y rellena las variables `${...}` en la sección *Environment variables*.

## 📸 Capturas

### Panel de inicio (Homarr)
Acceso centralizado a todos los servicios del servidor.
<img width="2463" height="824" alt="image" src="https://github.com/user-attachments/assets/3bfac378-a629-458f-ac96-3fcd8b60226c" />

### Gestión de contenedores (Portainer)
Stacks de Docker Compose desplegados y en ejecución.
<img width="2473" height="713" alt="image" src="https://github.com/user-attachments/assets/eeb75007-0924-41a1-a12a-3a951b34a7c4" />

### Proxy inverso (Nginx Proxy Manager)
Un nombre local por servicio, resuelto por Pi-hole.
<img width="1331" height="650" alt="image" src="https://github.com/user-attachments/assets/8e88fce8-a4a6-48cc-b7fc-530d311601d1" />

### DNS con bloqueo de anuncios (Pi-hole)
Panel con las consultas DNS y los dominios bloqueados.
<img width="1318" height="1054" alt="image" src="https://github.com/user-attachments/assets/37b45846-bedb-4d5d-ae8d-35f61fe036f1" />

### Servidor en funcionamiento
8 contenedores en una Raspberry Pi 4 con 1 GB de RAM y swap.
<img width="2474" height="385" alt="image" src="https://github.com/user-attachments/assets/dcb63f90-7ba2-4041-9c1e-15f62304108f" />

## 🧗 Retos superados

- **Arquitectura 32 vs 64 bits:** compatibilidad de imágenes y paquetes con el sistema de la Pi; los contenedores fijan `platform: linux/arm64` donde hizo falta (y `seccomp:unconfined` para que arranquen).
- **Copias de seguridad físicas:** imágenes `.img` completas de la tarjeta SD para recuperar el sistema entero.
- **IP pública dinámica:** automatizada con DuckDNS; el dominio se corrige solo tras un cambio de IP (por ejemplo, al reiniciar el router).
- **Script de actualización que fallaba en silencio:** diagnostiqué respuestas `KO` (token mal formado en la URL) y añadí `curl --max-time` para que un corte de red no deje el bucle colgado.
- **Almacenamiento externo:** datos de Nextcloud y música de Navidrome en un disco USB para no desgastar la tarjeta SD.
- **Red Docker compartida (`proxy_net`):** permite que Nginx Proxy Manager llegue a los demás contenedores por nombre.
- **Conflicto de puertos:** Pi-hole y Nginx Proxy Manager querían el puerto 80; el panel de Pi-hole va por el 8080.
- **WireGuard: de Docker a PiVPN:** probé `wg-easy` y `linuxserver/wireguard` en contenedor (problemas de arquitectura y de autenticación del panel) y acabé con PiVPN, que gestiona claves y clientes de forma fiable.
- **Recuperación de servicios:** restablecí la contraseña de Portainer con su imagen auxiliar y reconstruí la configuración de Nextcloud sin perder los datos del disco USB.
- **Memoria limitada:** swap de 2 GB para que Nextcloud y MariaDB no agoten la RAM de 1 GB.
- **VPN multi-dispositivo:** cada cliente de WireGuard tiene sus propias claves e IP (compartirlas provoca que se echen del túnel).
- **Diagnóstico de la VPN:** `wg show` y `tcpdump` para distinguir entre fallo de red, redirección de puertos y reenvío/NAT.
- **Recursos limitados:** ajustar los servicios a 1 GB de RAM (Nextcloud es el más exigente).
- **Contenedor "unhealthy" con la app funcionando:** diagnostiqué con `docker inspect` que el healthcheck de Homarr probaba `localhost` y la app solo escuchaba en la IP del contenedor; lo corregí con un healthcheck propio.

## 🔒 Seguridad

- Ningún secreto en el repositorio: variables en `.env` (ignorado por Git) y plantillas con marcadores.
- Paneles de administración (Nginx Proxy Manager 81, Portainer, Homarr) **no expuestos a Internet**; acceso remoto solo a través de la VPN.
- Homarr monta `docker.sock`: quien acceda a él controla Docker, por eso va solo en red local/VPN.
- Solo se abre en el router lo imprescindible (WireGuard y, si hace falta, 80/443).

## 📚 Qué aprendí

Linux, redes (NAT, DNS, redirección de puertos, CGNAT), contenedores, VPN, automatización con shell y contenedores, y resolución de problemas leyendo logs.

## 📝 Licencia

MIT
