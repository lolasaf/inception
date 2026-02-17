#!/bin/sh
# ==============================================================================
# WORDPRESS ENTRYPOINT SCRIPT
# ==============================================================================
# This script sets up WordPress on first run and starts PHP-FPM
# - Waits for MariaDB to be ready
# - Downloads WordPress core using WP-CLI
# - Creates wp-config.php with database credentials
# - Installs WordPress and creates admin + additional user
# - Starts PHP-FPM server
# ==============================================================================

# Exit on error, exit on undefined variable
set -eu

echo "[WordPress] Starting entrypoint..."

# ------------------------------------------------------------------------------
# VALIDATION: Ensure all required secrets exist
# ------------------------------------------------------------------------------
for f in db_password wp_admin_password wp_user_password; do
  if [ ! -f "/run/secrets/$f" ]; then
    echo "[WordPress] ERROR: Missing secret file: /run/secrets/$f"
    exit 1
  fi
done

# Read passwords from Docker secrets
DB_PASS="$(cat /run/secrets/db_password)"
ADMIN_PASS="$(cat /run/secrets/wp_admin_password)"
USER_PASS="$(cat /run/secrets/wp_user_password)"

# ------------------------------------------------------------------------------
# WAIT FOR DATABASE: Ensure MariaDB is ready before proceeding
# ------------------------------------------------------------------------------
echo "[WordPress] Waiting for MariaDB to be ready..."
for i in $(seq 1 120); do
  mariadb -h mariadb -u "$MYSQL_USER" -p"$DB_PASS" -e "SELECT 1" "$MYSQL_DATABASE" >/dev/null 2>&1 && break
  sleep 1
done

# Final check - exit with error if database is still not reachable
mariadb -h mariadb -u "$MYSQL_USER" -p"$DB_PASS" -e "SELECT 1" "$MYSQL_DATABASE" >/dev/null 2>&1 || {
  echo "[WordPress] ERROR: MariaDB not reachable with provided credentials"
  exit 1
}

echo "[WordPress] Database connection successful!"

# Change to WordPress directory
cd /var/www/html

# ------------------------------------------------------------------------------
# INSTALL WP-CLI: Command-line tool for WordPress management
# ------------------------------------------------------------------------------
if [ ! -x /usr/local/bin/wp ]; then
  echo "[WordPress] Installing WP-CLI..."
  curl -sSLo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp
fi

# ------------------------------------------------------------------------------
# DOWNLOAD WORDPRESS: Get WordPress core files if not present
# ------------------------------------------------------------------------------
if [ ! -d wp-admin ]; then
  echo "[WordPress] Downloading WordPress core..."
  wp core download --allow-root
fi

# ------------------------------------------------------------------------------
# CREATE CONFIG: Generate wp-config.php with database credentials
# ------------------------------------------------------------------------------
if [ ! -f wp-config.php ]; then
  echo "[WordPress] Creating wp-config.php..."
  wp config create \
    --dbname="$MYSQL_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$DB_PASS" \
    --dbhost="mariadb" \
    --allow-root
fi

# ------------------------------------------------------------------------------
# INSTALL WORDPRESS: Set up site with admin user (only on first run)
# ------------------------------------------------------------------------------
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "[WordPress] Installing WordPress..."
  wp core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$ADMIN_PASS" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --allow-root

  # Create second user as required by project
  echo "[WordPress] Creating additional user..."
  wp user create "$WP_USER" "$WP_USER_EMAIL" \
    --user_pass="$USER_PASS" \
    --role=author \
    --allow-root
fi

# ------------------------------------------------------------------------------
# PERMISSIONS: Ensure WordPress files are owned by web server user
# ------------------------------------------------------------------------------
chown -R www-data:www-data /var/www/html

# ------------------------------------------------------------------------------
# START PHP-FPM: Launch FastCGI Process Manager
# ------------------------------------------------------------------------------
echo "[WordPress] Starting PHP-FPM..."
exec php-fpm8.2 -F
