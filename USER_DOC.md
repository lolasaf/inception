# User Documentation - Inception

## Overview (Services Provided)

This stack provides a complete WordPress website with HTTPS:
- **Nginx**: public web server and TLS termination. Handles all incoming requests and secures connections with SSL/TLS certificates.
- **WordPress**: PHP application (site and admin panel). The content management system where you create posts, pages, and manage your website.
- **MariaDB**: database for WordPress content. Stores all your website data including posts, users, and settings.

## Initial Setup (Required Before First Run)

### Generate Secrets

Create strong random passwords for all services:

```bash
mkdir -p secrets
openssl rand -base64 24 > secrets/db_root_password.txt
openssl rand -base64 24 > secrets/db_password.txt
openssl rand -base64 24 > secrets/wp_admin_password.txt
openssl rand -base64 24 > secrets/wp_user_password.txt
chmod 600 secrets/*.txt
```

These files are:
- Automatically gitignored (never committed to version control)
- Read-only (chmod 600) for security
- Only accessible to Docker at runtime

### Create Configuration File

Create the environment configuration file with your domain and usernames:

```bash
cat > srcs/.env << 'EOF'
LOGIN=wel-safa
DOMAIN_NAME=wel-safa.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_TITLE=Inception
WP_URL=https://wel-safa.42.fr
WP_ADMIN_USER=siteowner
WP_ADMIN_EMAIL=siteowner@42.fr
WP_USER=editor
WP_USER_EMAIL=editor@42.fr
EOF
```

**Replace `wel-safa` with your actual login** in all places where it appears.

This file is:
- Automatically gitignored (never committed to version control)
- Contains non-sensitive configuration only (no passwords)

### Add Hostname to /etc/hosts

For HTTPS to work properly, add your domain to your system's hosts file:

```bash
echo "127.0.0.1 wel-safa.42.fr" | sudo tee -a /etc/hosts
```

**Replace `wel-safa.42.fr` with your actual domain** if you changed it in `.env`.

---

## Start and Stop

### Start
```bash
cd /path/to/inception-repo
make
```

### Stop (keep data)
```bash
make down
```

### Restart
```bash
make re
```

### Full cleanup (deletes data)
```bash
make clean
make fclean
```

## Access the Website and Admin Panel

Make sure the hostname points to your local IP:
```bash
echo "127.0.0.1 wel-safa.42.fr" | sudo tee -a /etc/hosts
```

- Website: `https://wel-safa.42.fr`
- Admin panel: `https://wel-safa.42.fr/wp-admin`

## Credentials (Location and Management)

All passwords are stored in the `secrets/` directory:
- Database root password: `secrets/db_root_password.txt`
- WordPress database password: `secrets/db_password.txt`
- WordPress admin password: `secrets/wp_admin_password.txt`
- WordPress user password: `secrets/wp_user_password.txt`

View a password:
```bash
cat secrets/wp_admin_password.txt
```

## Check Services Are Running

### Containers running
```bash
docker ps
```
Expected containers: `nginx`, `wordpress`, `mariadb`.

### Logs
```bash
docker compose -f srcs/docker-compose.yml logs
```

### Quick health checks
```bash
docker exec mariadb mysqladmin ping
docker exec wordpress wp core is-installed --allow-root
docker exec nginx nginx -t
```

## Getting Help

If you encounter issues:
1. Check the logs (see "Checking Services Are Running" section)
2. Review the [README.md](README.md) for project overview
3. Consult the [DEV_DOC.md](DEV_DOC.md) for technical details
4. Check the official documentation for each service
