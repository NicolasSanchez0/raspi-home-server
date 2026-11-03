#!/bin/sh
# Actualiza la IP pública en Duck DNS. Pensado para ejecutarse desde cron.
# Con "ip=" vacío, Duck DNS usa la IP desde la que llega la petición.
set -u

ENV_FILE="$(dirname "$0")/../.env"
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

: "${DUCKDNS_DOMAIN:?Falta DUCKDNS_DOMAIN en .env}"
: "${DUCKDNS_TOKEN:?Falta DUCKDNS_TOKEN en .env}"

# --max-time evita que curl se quede colgado si se corta la red (p. ej. al reiniciar el router)
RESP=$(curl -s --max-time 20 "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=")

echo "$(date '+%F %T') duckdns: ${RESP:-sin respuesta}"
[ "$RESP" = "OK" ] || exit 1
