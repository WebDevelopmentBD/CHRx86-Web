FROM alpine:3.19

# Install nginx, PHP 8.3, Python3, supervisord
RUN apk add --no-cache \
    nginx \
    php83 \
    php83-fpm \
    php83-opcache \
    php83-mysqli \
    php83-json \
    php83-curl \
    php83-mbstring \
    php83-session \
    php83-sqlite3 \
    python3 \
    py3-pip \
    supervisor \
    && mkdir -p /run/nginx \
    && mkdir -p /var/www/html \
    && mkdir -p /run/php

# Copy nginx config
COPY nginx/default.conf /etc/nginx/http.d/default.conf

# Copy supervisord config
COPY supervisord.conf /etc/supervisord.conf

# Default index files
RUN echo "<?php phpinfo(); ?>" > /var/www/html/index.php \
    && echo "print('Python3 OK')" > /var/www/html/test.py

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
