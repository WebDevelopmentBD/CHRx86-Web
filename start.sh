#!/bin/sh

# Fix DNS resolution inside container
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

DOMAIN="1e6ba5c88830f78f.sn.mynetname.net"
CERT_PATH="/home/data/certs/live/${DOMAIN}/fullchain.pem"
KEY_PATH="/home/data/certs/live/${DOMAIN}/privkey.pem"
CERT_DIR="/home/data/certs"
EMAIL="your@email.com"
SSL_CONF_SRC="/etc/nginx/ssl.conf.disabled"
SSL_CONF_DST="/etc/nginx/http.d/ssl.conf"

echo "[start.sh] Checking certificate..."

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    echo "[start.sh] Certificate found. Enabling HTTPS config."
    cp "$SSL_CONF_SRC" "$SSL_CONF_DST"
else
    echo "[start.sh] Certificate not found. Running certbot..."

    # Ensure webroot exists
    mkdir -p /var/www/html/.well-known/acme-challenge

    # Re-apply DNS right before certbot (in case it was overwritten)
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf

    # Verify DNS before running certbot
    nslookup acme-v02.api.letsencrypt.org && echo "[start.sh] DNS OK." || echo "[start.sh] DNS still failing."

    # Start nginx temporarily on HTTP only for challenge
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
        echo "[start.sh] Certificate issued. Enabling HTTPS config."
        cp "$SSL_CONF_SRC" "$SSL_CONF_DST"
        nginx -s stop
    else
        echo "[start.sh] Certbot failed. Starting HTTP only."
        nginx -s stop
    fi
fi

echo "[start.sh] Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
