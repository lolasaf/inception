#!/bin/sh
# ==============================================================================
# MARIADB ENTRYPOINT SCRIPT
# ==============================================================================
# This script initializes MariaDB on first run and starts the database server
# - Creates system tables if database is uninitialized
# - Sets root password and creates WordPress database/user
# - Starts MariaDB server listening on all interfaces
# ==============================================================================

# Exit on error
set -e

# ------------------------------------------------------------------------------
# CREATE RUNTIME DIRECTORY and SET OWNERSHIP
# ------------------------------------------------------------------------------
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# ------------------------------------------------------------------------------
# INITIALIZE DATABASE IF NEEDED: only runs on empty data directory
# ------------------------------------------------------------------------------
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "[MariaDB] Initializing database..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql

  # Start MariaDB temporarily (local socket only, no network access)
  # This allows us to run SQL commands to set up users and databases
  echo "[MariaDB] Starting temporary server..."
  mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid="$!"

  # Wait until MariaDB responds to commands (up to 30 seconds)
  echo "[MariaDB] Waiting for temporary server to start..."
  for i in $(seq 1 30); do
    mariadb-admin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1 && break
    sleep 1
  done

  # Read passwords from Docker secrets (remove trailing newlines)
  ROOT_PASS="$(cat /run/secrets/db_root_password | tr -d '\n')"
  DB_PASS="$(cat /run/secrets/db_password | tr -d '\n')"

  # Execute SQL commands to set up database and users
  # Uses environment variables from .env file: MYSQL_DATABASE, MYSQL_USER
  echo "[MariaDB] Creating database and user..."
  mariadb --socket=/run/mysqld/mysqld.sock <<-SQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
SQL

  # Verify the WordPress user was created successfully
  echo "[MariaDB] Verifying WordPress user was created..."
  if ! mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"${ROOT_PASS}" -e "SELECT User FROM mysql.user WHERE User='${MYSQL_USER}' AND Host='%';" 2>/dev/null | grep -q "${MYSQL_USER}"; then
    echo "[MariaDB] ERROR: Initialization failed - WordPress user not created"
    echo "[MariaDB] Cleaning up failed initialization..."
    mariadb-admin --socket=/run/mysqld/mysqld.sock shutdown 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    rm -rf /var/lib/mysql/mysql
    exit 1
  fi

  # Stop the temporary server gracefully
  echo "[MariaDB] Shutting down temporary server..."
  mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"${ROOT_PASS}" shutdown
  wait "$pid"
  
  echo "[MariaDB] Initialization complete!"
else
  echo "[MariaDB] Database already exists - reusing existing database"
fi

# ------------------------------------------------------------------------------
# START: Launch MariaDB server with network access
# ------------------------------------------------------------------------------
# bind-address=0.0.0.0 allows connections from other Docker containers
echo "[MariaDB] Starting MariaDB server..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0 --port=3306