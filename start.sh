#!/bin/sh

DOMAIN="1e6ba5c88830f78f.sn.mynetname.net"
CERT_PATH="/home/data/certs/live/${DOMAIN}/fullchain.pem"
KEY_PATH="/home/data/certs/live/${DOMAIN}/privkey.pem"
CERT_DIR="/home/data/certs"
EMAIL="abbasuddin1989@aol.com"

echo "[start.sh] Checking certificate..."

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    echo "[start.sh] Certificate found at $CERT_PATH — skipping certbot."
else
    echo "[start.sh] Certificate NOT found — running certbot..."

    # Ensure webroot exists
    mkdir -p /var/www/html/.well-known/acme-challenge

    # Start nginx temporarily for HTTP-01 challenge
    nginx

    # Run certbot
    certbot certonly --webroot \
        -w /var/www/html \
        -d "$DOMAIN" \
        --config-dir "$CERT_DIR" \
        --work-dir "$CERT_DIR/work" \
        --logs-dir "$CERT_DIR/logs" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive

    if [ $? -eq 0 ]; then
        echo "[start.sh] Certificate issued successfully."
        # Stop temporary nginx before supervisord takes over
        nginx -s stop
    else
        echo "[start.sh] Certbot FAILED — starting HTTP only."
        nginx -s stop
    fi
fi

echo "[start.sh] Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
