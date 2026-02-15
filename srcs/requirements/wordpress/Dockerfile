FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.2-fpm php8.2-mysql mariadb-client curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/php \
 && sed -i 's|^listen = .*|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000
ENTRYPOINT ["/entrypoint.sh"]
