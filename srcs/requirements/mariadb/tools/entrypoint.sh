#!/bin/sh
# ==============================================================================
# MARIADB ENTRYPOINT SCRIPT
# ==============================================================================
# This script initializes MariaDB on first run and starts the database server
# - Creates system tables if database is uninitialized
# - Sets root password and creates WordPress database/user
# - Starts MariaDB server listening on all interfaces
# ==============================================================================

# Exit on error, exit on undefined variable
set -eu

# ------------------------------------------------------------------------------
# SETUP: Create socket directory and set permissions
# ------------------------------------------------------------------------------
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# ------------------------------------------------------------------------------
# INITIALIZATION: Only runs on first container start (empty volume)
# ------------------------------------------------------------------------------
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "[MariaDB] First run detected - initializing database..."
  
  # Create system tables (mysql, performance_schema, etc.)
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql

  # Start MariaDB temporarily (local socket only, no network access)
  # This allows us to run SQL commands to set up users and databases
  mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid="$!"

  # Wait until MariaDB responds to commands (up to 30 seconds)
  echo "[MariaDB] Waiting for temporary server to start..."
  for i in $(seq 1 30); do
    mariadb-admin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1 && break
    sleep 1
  done

  # Read passwords from Docker secrets (secure way to inject credentials)
  ROOT_PASS="$(cat /run/secrets/db_root_password)"
  DB_PASS="$(cat /run/secrets/db_password)"

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

  # Stop the temporary server gracefully
  echo "[MariaDB] Shutting down temporary server..."
  mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"${ROOT_PASS}" shutdown
  wait "$pid"
  
  echo "[MariaDB] Initialization complete!"
fi

# ------------------------------------------------------------------------------
# START: Launch MariaDB server with network access
# ------------------------------------------------------------------------------
# bind-address=0.0.0.0 allows connections from other Docker containers
echo "[MariaDB] Starting MariaDB server..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0