# 🛠️ Cómo lo monté (paso a paso)

Registro de los comandos clave, con datos personales sustituidos por marcadores.

## 1. Sistema base

```bash
sudo apt update && sudo apt upgrade -y

# Swap de 2 GB: la Pi tiene solo 1 GB de RAM y Nextcloud + MariaDB la agotan
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
```

## 2. Disco USB para los datos de Nextcloud y Navidrome

```bash
sudo mkdir -p /mnt/TU_DISCO_USB
blkid                                    # localiza el UUID del disco
echo 'UUID=TU_UUID /mnt/TU_DISCO_USB ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
sudo mount -a
sudo chown -R 33:33 /mnt/TU_DISCO_USB    # 33 = usuario www-data dentro del contenedor de Nextcloud
```

`nofail` evita que la Pi se quede sin arrancar si el disco no está conectado.

## 3. Docker, red compartida y Portainer

```bash
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker TU_USUARIO       # cierra sesión y vuelve a entrar

docker network create proxy_net
mkdir -p ~/docker/portainer ~/docker/npm ~/docker/pihole ~/docker/mariadb ~/docker/navidrome ~/docker/homarr

docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/docker/portainer:/data \
  portainer/portainer-ce:latest
```

Resto de servicios: se despliegan como *stacks* desde Portainer con los compose de la carpeta `docker/`.

## 4. WireGuard con PiVPN

Probé primero WireGuard en contenedores (`wg-easy` y `linuxserver/wireguard`) y tuve problemas de compatibilidad con la arquitectura de la Pi y con la autenticación del panel. Acabé usando **PiVPN**, que instala WireGuard en el sistema y gestiona los clientes:

```bash
curl -L https://install.pivpn.io | bash
pivpn add          # crea un cliente (un dispositivo = un cliente)
pivpn -qr          # muestra el QR para importarlo en el móvil
pivpn -l           # lista clientes
pivpn add -n portatil     # un cliente por dispositivo
pivpn -c                  # clientes conectados y último handshake
pivpn -r portatil         # revoca un cliente (si pierdes el dispositivo)
```

En el router: redirigir **UDP 51820** a la IP local de la Pi.

## 5. Mantenimiento y diagnóstico

```bash
docker logs --tail 20 duckdns            # ¿responde OK el actualizador?
sudo wg show                             # estado de la VPN: ¿hay handshake reciente?
sudo tcpdump -ni any udp port 51820      # ¿llegan paquetes de WireGuard?
pihole restartdns
```

Utilidades de recuperación que me hicieron falta:

```bash
# Restablecer la contraseña de Portainer
docker stop portainer
docker run --rm -v ~/docker/portainer:/data portainer/helper-reset-password
docker start portainer

# Contraseña de Pi-hole
docker exec -it pihole pihole setpassword

# Dominios de confianza de Nextcloud
docker exec --user www-data nextcloud php occ config:system:set trusted_domains 1 --value=TU_DOMINIO
```

## 💡 Lecciones aprendidas

- Revisar siempre `ls` y `df -h` **antes** de ejecutar un `rm -rf` sobre un disco de datos.
- Montar discos por **UUID** y con `nofail`.
- Un contenedor y su volumen pueden tener propietarios distintos (`chown 33:33` para Nextcloud).
- Las contraseñas no deben ir en la línea de comandos: quedan en `~/.bash_history`.
