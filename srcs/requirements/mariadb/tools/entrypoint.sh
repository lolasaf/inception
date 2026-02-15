#!/bin/sh
set -eu

# Create socket dir and ensure permissions
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# If MariaDB hasn't been initialized yet (fresh volume)
if [ ! -d "/var/lib/mysql/mysql" ]; then
  # Create system tables
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql

  # Start MariaDB locally (no TCP) to run initialization SQL
  mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid="$!"

  # Wait until it responds to commands
  for i in $(seq 1 30); do
    mariadb-admin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1 && break
    sleep 1
  done

  # Read secrets (mounted by compose)
  ROOT_PASS="$(cat /run/secrets/db_root_password)"
  DB_PASS="$(cat /run/secrets/db_password)"

  # Use env vars from .env (MYSQL_DATABASE, MYSQL_USER)
  mariadb --socket=/run/mysqld/mysqld.sock <<-SQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
SQL

  # Stop the temporary server
  mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"${ROOT_PASS}" shutdown
  wait "$pid"
fi

# Start MariaDB for real (TCP enabled for other containers)
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0