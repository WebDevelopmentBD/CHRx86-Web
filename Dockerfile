FROM alpine:3.19

# Enable community repository (required for certbot)
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories

# Install nginx, PHP 8.3, Python3, supervisord
RUN apk add --no-cache \
    nginx \
    php83 \
    php83-fpm \
    php83-opcache \
    php83-json \
    php83-curl \
    php83-mbstring \
    php83-session \
    php83-gd \
    php83-exif \
    php83-fileinfo \
    certbot \
    certbot-nginx \
    python3 \
    py3-pip \
    supervisor \
    wget \
    tzdata \
    && mkdir -p /run/nginx \
    && mkdir -p /var/www/html \
    && mkdir -p /run/php

# Download and install curl CA bundle at system level
RUN wget -q https://curl.se/ca/cacert.pem -O /etc/ssl/certs/cacert.pem \
    && update-ca-certificates

# Point PHP and Python3 to the CA bundle
ENV SSL_CERT_FILE=/etc/ssl/certs/cacert.pem
ENV CURL_CA_BUNDLE=/etc/ssl/certs/cacert.pem
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/cacert.pem
ENV TZ=Asia/Dhaka

# Verify Python3 installation
RUN which python3 && python3 --version

# Ensure shell_exec and exec are not disabled in PHP
# Also enable dl() for dynamic extension loading at runtime
RUN sed -i 's/^disable_functions\s*=.*/disable_functions =/' /etc/php83/php.ini \
    && sed -i 's|^;curl.cainfo\s*=.*|curl.cainfo=/etc/ssl/certs/cacert.pem|' /etc/php83/php.ini \
    && sed -i 's|^;date.timezone\s*=.*|date.timezone=Asia/Dhaka|' /etc/php83/php.ini \
    && sed -i 's|^;openssl.cafile\s*=.*|openssl.cafile=/etc/ssl/certs/cacert.pem|' /etc/php83/php.ini \
    && sed -i 's/^;enable_dl\s*=.*/enable_dl = On/' /etc/php83/php.ini \
    && sed -i 's|^;extension_dir\s*=.*|extension_dir=/usr/lib/php83/modules|' /etc/php83/php.ini

# Copy nginx configs
# default.conf = HTTP only (always loaded)
# ssl.conf = HTTPS (copied into place by start.sh after cert exists)
COPY nginx/default.conf /etc/nginx/http.d/default.conf
COPY nginx/ssl.conf /etc/nginx/ssl.conf.disabled

# Copy supervisord config
COPY supervisord.conf /etc/supervisord.conf

# Default index files
COPY index.php /var/www/html/index.php
COPY favicon.ico /var/www/html/favicon.ico
RUN echo "print('Python3 OK')" > /var/www/html/test.py

# Add certbot renewal script
RUN echo '#!/bin/sh' > /usr/local/bin/certbot-renew.sh \
    && echo 'certbot renew --quiet --deploy-hook "nginx -s reload"' >> /usr/local/bin/certbot-renew.sh \
    && chmod +x /usr/local/bin/certbot-renew.sh

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 80 443

CMD ["/usr/local/bin/start.sh"]
