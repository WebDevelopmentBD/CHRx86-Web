FROM alpine:3.19

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
    python3 \
    py3-pip \
    supervisor \
    wget \
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

# Verify Python3 installation
RUN which python3 && python3 --version

# Ensure shell_exec and exec are not disabled in PHP
# Also enable dl() for dynamic extension loading at runtime
RUN sed -i 's/^disable_functions\s*=.*/disable_functions =/' /etc/php83/php.ini \
    && sed -i 's|^;curl.cainfo\s*=.*|curl.cainfo=/etc/ssl/certs/cacert.pem|' /etc/php83/php.ini \
    && sed -i 's|^;openssl.cafile\s*=.*|openssl.cafile=/etc/ssl/certs/cacert.pem|' /etc/php83/php.ini \
    && sed -i 's/^;enable_dl\s*=.*/enable_dl = On/' /etc/php83/php.ini \
    && sed -i 's|^;extension_dir\s*=.*|extension_dir=/usr/lib/php83/modules|' /etc/php83/php.ini

# Copy nginx config
COPY nginx/default.conf /etc/nginx/http.d/default.conf

# Copy supervisord config
COPY supervisord.conf /etc/supervisord.conf

# Default index files
RUN echo "<?php phpinfo(); ?>" > /var/www/html/index.php \
    && echo "print('Python3 OK')" > /var/www/html/test.py

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
