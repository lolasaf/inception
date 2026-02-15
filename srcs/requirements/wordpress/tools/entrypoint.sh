#!/bin/sh
set -eu

echo "[wp] starting entrypoint"

# Ensure secrets exist (fail with clear message)
for f in db_password wp_admin_password wp_user_password; do
  if [ ! -f "/run/secrets/$f" ]; then
    echo "[wp] missing secret: /run/secrets/$f"
    exit 1
  fi
done

DB_PASS="$(cat /run/secrets/db_password)"
ADMIN_PASS="$(cat /run/secrets/wp_admin_password)"
USER_PASS="$(cat /run/secrets/wp_user_password)"

echo "[wp] waiting for mariadb..."
for i in $(seq 1 120); do
  mariadb -h mariadb -u "$MYSQL_USER" -p"$DB_PASS" -e "SELECT 1" "$MYSQL_DATABASE" >/dev/null 2>&1 && break
  sleep 1
done

# Hard fail if DB still not reachable
mariadb -h mariadb -u "$MYSQL_USER" -p"$DB_PASS" -e "SELECT 1" "$MYSQL_DATABASE" >/dev/null 2>&1 || {
  echo "[wp] mariadb not reachable with provided credentials"
  exit 1
}

cd /var/www/html

# Install wp-cli (deterministic path)
if [ ! -x /usr/local/bin/wp ]; then
  echo "[wp] installing wp-cli"
  curl -sSLo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp
fi

# Download WP if needed
if [ ! -d wp-admin ]; then
  echo "[wp] downloading wordpress core"
  wp core download --allow-root
fi

# Create config if needed
if [ ! -f wp-config.php ]; then
  echo "[wp] creating wp-config.php"
  wp config create \
    --dbname="$MYSQL_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$DB_PASS" \
    --dbhost="mariadb" \
    --allow-root
fi

# Install WP if needed
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "[wp] installing wordpress"
  wp core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$ADMIN_PASS" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --allow-root

  echo "[wp] creating second user"
  wp user create "$WP_USER" "$WP_USER_EMAIL" \
    --user_pass="$USER_PASS" \
    --role=author \
    --allow-root
fi

chown -R www-data:www-data /var/www/html

echo "[wp] starting php-fpm"
exec php-fpm8.2 -F
