# OpenLiteSpeed + LSPHP 8.5 for WordPress.
FROM litespeedtech/openlitespeed:latest

COPY uploads.ini /tmp/uploads.ini
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        lsphp85 \
        lsphp85-common \
        lsphp85-mysql \
        lsphp85-curl \
        lsphp85-imagick \
        lsphp85-intl \
        lsphp85-redis \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/local/lsws/lsphp85/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp8 \
    && ln -sf /usr/local/lsws/fcgi-bin/lsphp8 /usr/local/lsws/fcgi-bin/lsphp \
    && mkdir -p /usr/local/lsws/lsphp85/etc/php/8.5/litespeed/conf.d \
    && cat /tmp/uploads.ini >> /usr/local/lsws/lsphp85/etc/php/8.5/litespeed/php.ini \
    && cp /tmp/uploads.ini /usr/local/lsws/lsphp85/etc/php/8.5/litespeed/conf.d/99-wordpress.ini \
    && rm /tmp/uploads.ini

# Fix permissions for bind-mounted wordpress source.
COPY ols-entrypoint.sh /ols-entrypoint.sh
RUN chmod +x /ols-entrypoint.sh
ENTRYPOINT ["/ols-entrypoint.sh"]
