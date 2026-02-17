# User Documentation - Inception

## Overview (Services Provided)

This stack provides a complete WordPress website with HTTPS:
- **Nginx**: public web server and TLS termination. Handles all incoming requests and secures connections with SSL/TLS certificates.
- **WordPress**: PHP application (site and admin panel). The content management system where you create posts, pages, and manage your website.
- **MariaDB**: database for WordPress content. Stores all your website data including posts, users, and settings.

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
