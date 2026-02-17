# User Documentation - Inception Project

## Overview

This document explains how to use and manage the Inception WordPress infrastructure. The system consists of three interconnected services:
- **Nginx** - Web server that handles all incoming requests
- **WordPress** - Website and content management system
- **MariaDB** - Database that stores all website data

## Starting the Project

### Prerequisites
Before starting, ensure your system has:
- Docker and Docker Compose installed
- At least 2GB of free disk space
- Port 443 available

### Initial Setup

1. **Configure the domain name**
   ```bash
   # Add the domain to your hosts file
   echo "127.0.0.1 wel-safa.42.fr" | sudo tee -a /etc/hosts
   ```

2. **Start all services**
   ```bash
   # Navigate to the project directory
   cd /path/to/inception-repo
   
   # Build and start all containers
   make
   ```

   This command will:
   - Create data directories at `/home/wel-safa/data/`
   - Build Docker images for all three services
   - Start all containers in the background
   - Initialize the database (first run only)
   - Download and install WordPress (first run only)

3. **Wait for services to start**
   - The first startup takes 2-3 minutes
   - WordPress logs show "[WordPress] Starting PHP-FPM..." when ready

## Accessing the Website

### Main Website
- URL: `http://wel-safa.42.fr`
- Once SSL is configured: `https://wel-safa.42.fr`

### WordPress Administration Panel
- URL: `http://wel-safa.42.fr/wp-admin`
- Login with the admin credentials (see Credentials section below)

## Managing Credentials

All sensitive passwords are stored in the `secrets/` directory:

### Database Credentials
- **Root Password**: `secrets/db_root_password.txt`
  - Used for: MariaDB root user administration
  - User: `root`
  
- **WordPress Database Password**: `secrets/db_password.txt`
  - Used for: WordPress connection to database
  - User: `wpuser`
  - Database: `wordpress`

### WordPress Credentials
- **Admin User**: `secrets/wp_admin_password.txt`
  - Username: `siteowner`
  - Email: `siteowner@42.fr`
  - Role: Administrator (full access)
  
- **Additional User**: `secrets/wp_user_password.txt`
  - Username: `editor`
  - Email: `editor@42.fr`
  - Role: Author (can create and publish posts)

### Viewing Passwords
```bash
# View any password
cat secrets/db_password.txt

# View all credentials at once
for file in secrets/*.txt; do
  echo "$(basename $file): $(cat $file)"
done
```

⚠️ **Security Note**: Never commit password files to Git. These are in `.gitignore`.

## Stopping the Project

### Stop Services (Preserve Data)
```bash
make down
```
This stops all containers but keeps your data safe in the volumes.

### Restart Services
```bash
make re
```
Equivalent to `make down` followed by `make up`.

### Complete Cleanup (⚠️ DELETES DATA)
```bash
# Remove containers and volumes (deletes database and WordPress files)
make clean

# Also remove Docker images
make fclean
```

## Checking Service Status

### View Running Containers
```bash
docker ps
```
You should see three containers:
- `nginx`
- `wordpress`
- `mariadb`

### View Container Logs
```bash
# View all logs
docker compose -f srcs/docker-compose.yml logs

# Follow logs in real-time
docker compose -f srcs/docker-compose.yml logs -f

# View logs for specific service
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx
```

### Check Service Health

1. **Database Health**
   ```bash
   docker exec mariadb mysqladmin ping
   # Should output: mysqld is alive
   ```

2. **WordPress Health**
   ```bash
   docker exec wordpress wp core is-installed --allow-root
   # Should exit with code 0 (no output means success)
   ```

3. **Nginx Health**
   ```bash
   docker exec nginx nginx -t
   # Should output: syntax is ok, test is successful
   ```

## Troubleshooting

### Website Not Loading

1. Check if containers are running:
   ```bash
   docker ps
   ```

2. Check if domain is configured:
   ```bash
   ping wel-safa.42.fr
   # Should respond from 127.0.0.1
   ```

3. View error logs:
   ```bash
   docker compose -f srcs/docker-compose.yml logs nginx
   ```

### WordPress Shows Database Connection Error

1. Check MariaDB is running:
   ```bash
   docker ps | grep mariadb
   ```

2. Verify database credentials in `.env` match those in secrets:
   ```bash
   cat srcs/.env
   cat secrets/db_password.txt
   ```

3. Restart services:
   ```bash
   make re
   ```

### Cannot Access /wp-admin

1. Verify WordPress is fully installed:
   ```bash
   docker exec wordpress wp core is-installed --allow-root && echo "Installed" || echo "Not installed"
   ```

2. Check WordPress logs:
   ```bash
   docker compose -f srcs/docker-compose.yml logs wordpress
   ```

### Ports Already in Use

If port 443 is already in use:
```bash
# Find what's using the port
sudo lsof -i :443

# Stop the conflicting service
sudo systemctl stop apache2  # or nginx, etc.
```

### Data Directory Issues

1. Check directory permissions:
   ```bash
   ls -la /home/wel-safa/data/
   ```

2. Create directories manually if needed:
   ```bash
   mkdir -p /home/wel-safa/data/mariadb
   mkdir -p /home/wel-safa/data/wordpress
   ```

## Data Management

### Backup Your Data

```bash
# Stop services first
make down

# Create backup
sudo tar -czf inception-backup-$(date +%Y%m%d).tar.gz /home/wel-safa/data/

# Restart services
make
```

### Restore from Backup

```bash
# Stop services
make down

# Remove current data
sudo rm -rf /home/wel-safa/data/*

# Extract backup
sudo tar -xzf inception-backup-YYYYMMDD.tar.gz -C /

# Restart services
make
```

## Service Details

### What Each Service Does

**Nginx (Web Server)**
- Listens on port 443 (HTTPS)
- Serves static files (images, CSS, JavaScript)
- Forwards PHP requests to WordPress container
- Acts as the only entry point to your infrastructure

**WordPress (Application)**
- Runs PHP-FPM on port 9000 (internal only)
- Handles dynamic content generation
- Manages posts, pages, users, and media
- Stores files in `/var/www/html`

**MariaDB (Database)**
- Runs on port 3306 (internal network only)
- Stores all WordPress content and settings
- Not accessible from outside the Docker network

### Port Mapping

| Service   | External Port | Internal Port | Protocol |
|-----------|---------------|---------------|----------|
| Nginx     | 443           | 443           | HTTPS*   |
| WordPress | -             | 9000          | FastCGI  |
| MariaDB   | -             | 3306          | MySQL    |

*HTTPS configuration pending (SSL certificates needed)

## Getting Help

If you encounter issues:
1. Check the logs (see "Checking Service Status" section)
2. Review the [README.md](README.md) for project overview
3. Consult the [DEV_DOC.md](DEV_DOC.md) for technical details
4. Check the official documentation for each service
