# ==============================================================================
# MARIADB DOCKERFILE
# ==============================================================================
# Builds a MariaDB database server container from minimal Debian base
# MariaDB is initialized and configured by the entrypoint script
# ==============================================================================

# Use minimal Debian 12 (Bookworm) - penultimate version
FROM debian:bookworm-slim

# Install MariaDB server and clean up to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
        mariadb-server \
        mariadb-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*

# Copy entrypoint script that initializes the database
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose MySQL/MariaDB port (internal network only, not published to host)
EXPOSE 3306

# The entrypoint handles:
# - Database initialization (first run)
# - Creating WordPress database and user
# - Starting MariaDB server
ENTRYPOINT ["/entrypoint.sh"]