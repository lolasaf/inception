# ==============================================================================
# WORDPRESS DOCKERFILE
# ==============================================================================
# Builds a WordPress container with PHP-FPM (FastCGI Process Manager)
# Includes WP-CLI for WordPress installation and management
# ==============================================================================

# Use minimal Debian 12 (Bookworm) as base image
FROM debian:bookworm-slim

# Install PHP-FPM, MySQL client, and required tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.2-fpm \
    php8.2-mysql \
    mariadb-client \
    curl \
    ca-certificates \
    net-tools \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# Configure PHP-FPM to listen on port 9000 for FastCGI connections from nginx
RUN mkdir -p /run/php \
 && sed -i 's|^listen = .*|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

# Copy entrypoint script that downloads and configures WordPress
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose FastCGI port for communication with nginx
EXPOSE 9000

# The entrypoint handles:
# - Installing WP-CLI
# - Downloading WordPress core
# - Creating wp-config.php
# - Installing WordPress and creating users
ENTRYPOINT ["/entrypoint.sh"]
