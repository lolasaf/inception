# Developer Documentation - Inception Project

## Project Architecture

### Overview
Inception is a containerized web application infrastructure following a three-tier architecture pattern:

```
┌─────────────────────────────────────────────────┐
│              Client Browser                      │
└────────────────────┬────────────────────────────┘
                     │ HTTP/HTTPS (Port 80/443)
                     ▼
┌─────────────────────────────────────────────────┐
│  Docker Host (wel-safa.42.fr)                   │
│  ┌───────────────────────────────────────────┐  │
│  │  Docker Network: inception (bridge)       │  │
│  │                                           │  │
│  │  ┌──────────┐    ┌──────────┐    ┌─────┐│  │
│  │  │  nginx   │───▶│wordpress │───▶│maria││  │
│  │  │  :80/443 │    │  :9000   │    │ db  ││  │
│  │  └──────────┘    └──────────┘    │:3306││  │
│  │       │               │           └─────┘│  │
│  │       │               │              │    │  │
│  │       ▼               ▼              ▼    │  │
│  │  (static files) (wp files)    (database) │  │
│  └───────────────────────────────────────────┘  │
│              │           │              │       │
│              ▼           ▼              ▼       │
│   /home/wel-safa/data/wordpress  mariadb       │
└─────────────────────────────────────────────────┘
```

### Technology Stack
- **Base OS**: Debian 12 (Bookworm) Slim
- **Web Server**: Nginx (latest from Debian repos)
- **Application**: WordPress (latest via WP-CLI)
- **Language**: PHP 8.2 with FPM
- **Database**: MariaDB 10.11+
- **Orchestration**: Docker Compose
- **Automation**: GNU Make + Shell scripts

## Setting Up the Development Environment

### Prerequisites
```bash
# Check Docker installation
docker --version          # Should be 24.0+
docker compose version    # Should be 2.0+

# Check available disk space
df -h /home/wel-safa     # Need at least 2GB free
```

### Initial Setup from Scratch

1. **Clone the repository**
   ```bash
   git clone <your-repo-url> inception-repo
   cd inception-repo
   ```

2. **Understand the project structure**
   ```
   inception-repo/
   ├── Makefile                          # Build automation
   ├── README.md                         # Project overview
   ├── USER_DOC.md                       # User documentation
   ├── DEV_DOC.md                        # This file
   ├── inception_subject.md              # Project requirements
   ├── secrets/                          # Credentials (not in git)
   │   ├── db_root_password.txt          # MariaDB root password
   │   ├── db_password.txt               # WordPress DB user password
   │   ├── wp_admin_password.txt         # WP admin password
   │   └── wp_user_password.txt          # WP additional user password
   └── srcs/                             # Docker configuration
       ├── .env                          # Environment variables
       ├── docker-compose.yml            # Service orchestration
       └── requirements/                 # Service definitions
           ├── mariadb/
           │   ├── Dockerfile            # MariaDB image definition
           │   ├── conf/                 # (empty, for custom config)
           │   └── tools/
           │       └── entrypoint.sh     # DB initialization script
           ├── nginx/
           │   ├── Dockerfile            # Nginx image definition
           │   ├── default               # Nginx site configuration
           │   ├── conf/                 # (empty, for SSL certs)
           │   └── tools/                # (empty, for scripts)
           └── wordpress/
               ├── Dockerfile            # WordPress image definition
               ├── conf/                 # (empty, for PHP config)
               └── tools/
                   └── entrypoint.sh     # WP installation script
   ```

3. **Configure secrets** (already done, but for reference)
   ```bash
   # Generate secure random passwords
   openssl rand -base64 24 > secrets/db_root_password.txt
   openssl rand -base64 24 > secrets/db_password.txt
   openssl rand -base64 24 > secrets/wp_admin_password.txt
   openssl rand -base64 24 > secrets/wp_user_password.txt
   
   # Set proper permissions
   chmod 600 secrets/*.txt
   ```

4. **Configure environment variables**
   - Edit `srcs/.env` to customize settings
   - Key variables:
     - `LOGIN`: Your 42 username
     - `DOMAIN_NAME`: Your domain (login.42.fr)
     - `MYSQL_DATABASE`: Database name
     - `WP_ADMIN_USER`: WordPress admin username

5. **Configure domain resolution**
   ```bash
   # Add to /etc/hosts
   echo "127.0.0.1 wel-safa.42.fr" | sudo tee -a /etc/hosts
   ```

6. **Build and launch**
   ```bash
   make
   ```

## Build System

### Makefile Targets

```bash
make        # Default: creates directories and starts services
make up     # Same as default
make down   # Stop all containers
make re     # Restart (down + up)
make clean  # Stop and remove volumes (DELETES DATA)
make fclean # Full cleanup including images
```

### Manual Docker Commands

```bash
# Build images manually
docker compose -f srcs/docker-compose.yml build

# Start services in foreground (see logs)
docker compose -f srcs/docker-compose.yml up

# Start services in background
docker compose -f srcs/docker-compose.yml up -d

# Stop services
docker compose -f srcs/docker-compose.yml down

# Remove volumes (DELETES DATA)
docker compose -f srcs/docker-compose.yml down --volumes

# View logs
docker compose -f srcs/docker-compose.yml logs -f

# Rebuild specific service
docker compose -f srcs/docker-compose.yml build --no-cache mariadb
```

## Container Management

### Accessing Containers

```bash
# Open shell in running container
docker exec -it mariadb /bin/bash
docker exec -it wordpress /bin/bash
docker exec -it nginx /bin/bash

# Run one-off commands
docker exec mariadb mysqladmin ping
docker exec wordpress wp --info --allow-root
docker exec nginx nginx -v
```

### Inspecting Containers

```bash
# View container details
docker inspect mariadb

# View container stats (CPU, Memory)
docker stats

# View container processes
docker top mariadb

# View container networks
docker network inspect inception
```

### Debugging Containers

```bash
# View logs for specific service
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx

# Follow logs in real-time
docker compose -f srcs/docker-compose.yml logs -f wordpress

# View last 50 lines
docker compose -f srcs/docker-compose.yml logs --tail=50 mariadb

# View logs with timestamps
docker compose -f srcs/docker-compose.yml logs -t
```

## Volume Management

### Understanding Volumes

The project uses Docker volumes with bind mount configuration to store data at specific host paths:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none          # Bind mount type
      o: bind             # Options
      device: /home/wel-safa/data/mariadb   # Host path
```

This approach combines:
- Docker volume management (lifecycle, backups)
- Bind mount specificity (known host location)

### Volume Commands

```bash
# List all volumes
docker volume ls

# Inspect volume
docker volume inspect inception_mariadb_data

# View volume data on host
ls -la /home/wel-safa/data/mariadb
ls -la /home/wel-safa/data/wordpress

# Manually backup volume
sudo tar -czf mariadb_backup.tar.gz /home/wel-safa/data/mariadb

# Remove volumes (DELETES DATA)
docker compose -f srcs/docker-compose.yml down --volumes
```

## Service-Specific Development

### MariaDB Container

**Dockerfile**: `srcs/requirements/mariadb/Dockerfile`
**Entrypoint**: `srcs/requirements/mariadb/tools/entrypoint.sh`

Key features:
- Installs MariaDB server from Debian repos
- Custom entrypoint handles initialization
- First run: creates database and users
- Subsequent runs: starts existing database

Development tips:
```bash
# Connect to database from host
docker exec -it mariadb mariadb -uroot -p$(cat secrets/db_root_password.txt)

# Connect as WordPress user
docker exec -it mariadb mariadb -uwpuser -p$(cat secrets/db_password.txt) wordpress

# View WordPress tables
docker exec -it mariadb mariadb -uwpuser -p$(cat secrets/db_password.txt) -e "SHOW TABLES;" wordpress

# Dump database
docker exec mariadb mysqldump -uroot -p$(cat secrets/db_root_password.txt) wordpress > backup.sql

# Import database
docker exec -i mariadb mariadb -uroot -p$(cat secrets/db_root_password.txt) wordpress < backup.sql
```

### WordPress Container

**Dockerfile**: `srcs/requirements/wordpress/Dockerfile`
**Entrypoint**: `srcs/requirements/wordpress/tools/entrypoint.sh`

Key features:
- Installs PHP 8.2 with FPM and MySQL extension
- Downloads WordPress via WP-CLI
- Auto-configures database connection
- Creates admin and additional user

Development tips:
```bash
# Use WP-CLI commands
docker exec wordpress wp --info --allow-root
docker exec wordpress wp plugin list --allow-root
docker exec wordpress wp theme list --allow-root
docker exec wordpress wp user list --allow-root

# Install new plugin
docker exec wordpress wp plugin install contact-form-7 --activate --allow-root

# Update WordPress
docker exec wordpress wp core update --allow-root

# Check PHP configuration
docker exec wordpress php -i | grep -i memory
docker exec wordpress php-fpm8.2 -v

# View PHP-FPM logs
docker exec wordpress tail -f /var/log/php8.2-fpm.log
```

### Nginx Container

**Dockerfile**: `srcs/requirements/nginx/Dockerfile`
**Config**: `srcs/requirements/nginx/default`

Key features:
- Installs Nginx from Debian repos
- Custom site configuration for WordPress
- Forwards PHP requests to WordPress container
- Serves static files directly

Development tips:
```bash
# Test Nginx configuration
docker exec nginx nginx -t

# Reload Nginx (after config changes)
docker exec nginx nginx -s reload

# View Nginx access logs
docker exec nginx tail -f /var/log/nginx/access.log

# View Nginx error logs
docker exec nginx tail -f /var/log/nginx/error.log

# Check which files Nginx is serving
docker exec nginx ls -la /var/www/html
```

## Network Configuration

### Docker Network
- **Name**: `inception`
- **Type**: Bridge
- **Isolation**: Containers can talk to each other, but not directly to host

### Container Hostnames
Within the Docker network, containers can reach each other by service name:
- `mariadb` - Database server
- `wordpress` - PHP-FPM server
- `nginx` - Web server

Example: WordPress connects to database at `mariadb:3306`

### Network Commands
```bash
# Inspect network
docker network inspect inception

# List containers on network
docker network inspect inception -f '{{range .Containers}}{{.Name}} {{end}}'

# Test connectivity between containers
docker exec wordpress ping -c 3 mariadb
docker exec nginx ping -c 3 wordpress
```

## Data Persistence

### Storage Locations

**Host Machine:**
- MariaDB data: `/home/wel-safa/data/mariadb/`
- WordPress files: `/home/wel-safa/data/wordpress/`

**Inside Containers:**
- MariaDB data: `/var/lib/mysql/`
- WordPress files: `/var/www/html/`

### Data Lifecycle

1. **First Run**:
   - Directories created by Makefile
   - MariaDB initializes empty database
   - WordPress downloads and installs

2. **Normal Operation**:
   - Changes written to volumes
   - Data persists across container restarts

3. **Clean Shutdown** (`make down`):
   - Containers stop
   - Data remains in volumes

4. **Volume Removal** (`make clean`):
   - Containers stop and removed
   - **Data deleted permanently**

## Environment Variables

### Configuration File
All non-sensitive configuration is in `srcs/.env`:

```bash
# General
LOGIN=wel-safa                    # Your 42 login
DOMAIN_NAME=wel-safa.42.fr        # Your domain

# Database
MYSQL_DATABASE=wordpress          # Database name
MYSQL_USER=wpuser                 # Non-root user for WordPress

# WordPress
WP_TITLE=Inception                # Site title
WP_URL=https://wel-safa.42.fr     # Full site URL
WP_ADMIN_USER=siteowner           # Admin username
WP_ADMIN_EMAIL=siteowner@42.fr    # Admin email
WP_USER=editor                    # Additional user
WP_USER_EMAIL=editor@42.fr        # Additional user email
```

### Secrets Management
Sensitive data (passwords) are stored in separate files and mounted as Docker secrets at `/run/secrets/` inside containers.

Advantages:
- Not visible in `docker inspect`
- Not in environment variables
- Can't be accidentally logged
- More secure than environment variables

## Testing and Validation

### Health Checks

```bash
# Check all services are running
docker ps --filter "status=running" | grep -E "nginx|wordpress|mariadb"

# Test database connectivity
docker exec wordpress mariadb -h mariadb -u wpuser -p$(cat secrets/db_password.txt) -e "SELECT 1;" wordpress

# Test WordPress installation
docker exec wordpress wp core is-installed --allow-root && echo "✓ WordPress installed"

# Test Nginx configuration
docker exec nginx nginx -t && echo "✓ Nginx config valid"

# Test website accessibility
curl -I http://wel-safa.42.fr
```

### Manual Testing Checklist

- [ ] All three containers are running
- [ ] Website loads at `http://wel-safa.42.fr`
- [ ] WordPress admin panel accessible
- [ ] Can login with admin credentials
- [ ] Can login with second user credentials
- [ ] Database has two users (verify in phpMyAdmin or CLI)
- [ ] WordPress files persist after `make re`
- [ ] Database persists after `make re`

## Common Development Tasks

### Modifying MariaDB Configuration

1. Edit `srcs/requirements/mariadb/tools/entrypoint.sh`
2. Rebuild: `docker compose -f srcs/docker-compose.yml build mariadb`
3. Restart: `make re`

### Modifying WordPress Configuration

1. Edit `srcs/requirements/wordpress/tools/entrypoint.sh`
2. Rebuild: `docker compose -f srcs/docker-compose.yml build wordpress`
3. Restart: `make re`

### Modifying Nginx Configuration

1. Edit `srcs/requirements/nginx/default`
2. Rebuild: `docker compose -f srcs/docker-compose.yml build nginx`
3. Restart: `make re`

### Adding SSL/TLS (REQUIRED)

This is a **critical missing feature**. The project requires HTTPS with TLSv1.2/1.3:

1. Generate SSL certificate:
   ```bash
   # Self-signed certificate for development
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout srcs/requirements/nginx/conf/private.key \
     -out srcs/requirements/nginx/conf/certificate.crt \
     -subj "/CN=wel-safa.42.fr"
   ```

2. Update `srcs/requirements/nginx/Dockerfile`:
   ```dockerfile
   # Copy SSL certificates
   COPY conf/certificate.crt /etc/nginx/ssl/certificate.crt
   COPY conf/private.key /etc/nginx/ssl/private.key
   RUN chmod 600 /etc/nginx/ssl/private.key
   
   # Expose HTTPS port
   EXPOSE 443
   ```

3. Update `srcs/requirements/nginx/default`:
   ```nginx
   server {
       listen 443 ssl default_server;
       listen [::]:443 ssl default_server;
       
       ssl_certificate /etc/nginx/ssl/certificate.crt;
       ssl_certificate_key /etc/nginx/ssl/private.key;
       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_ciphers HIGH:!aNULL:!MD5;
       
       # ... rest of configuration
   }
   ```

4. Rebuild and test:
   ```bash
   make re
   curl -Ik https://wel-safa.42.fr
   ```

## Troubleshooting

### Build Failures

```bash
# Clean build cache
docker builder prune

# Rebuild without cache
docker compose -f srcs/docker-compose.yml build --no-cache

# Check Dockerfile syntax
docker compose -f srcs/docker-compose.yml config
```

### Container Crashes

```bash
# View container exit code
docker ps -a | grep mariadb

# View container logs
docker logs mariadb

# Restart specific container
docker compose -f srcs/docker-compose.yml restart mariadb
```

### Network Issues

```bash
# Recreate network
docker compose -f srcs/docker-compose.yml down
docker network rm inception
docker compose -f srcs/docker-compose.yml up -d

# Test DNS resolution
docker exec wordpress nslookup mariadb
```

## Best Practices

### Development Workflow
1. Make changes to configuration files
2. Rebuild specific service
3. Test changes in isolated environment
4. Review logs for errors
5. Commit changes with descriptive messages

### Security Considerations
- Never commit secrets to Git
- Use strong passwords (20+ characters)
- Keep Debian packages updated
- Limit container privileges
- Use read-only volumes where possible

### Performance Optimization
- Use `.dockerignore` to exclude unnecessary files
- Minimize layers in Dockerfiles
- Clean up package caches after installation
- Use multi-stage builds for smaller images

## Next Steps for Project Completion

### Critical (Must Complete)
1. **SSL/TLS Configuration** - Required by project, see "Adding SSL/TLS" section
2. **Volume Type Fix** - Verify using proper named volumes (check subject requirements)
3. **Testing** - Complete all validation checks

### Documentation (Required)
- ✅ README.md - Completed
- ✅ USER_DOC.md - Completed
- ✅ DEV_DOC.md - Completed

### Optional Enhancements (Bonus)
- Redis cache for WordPress performance
- FTP server for file management
- Static website showcase
- Adminer for database management
- Additional service of choice

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [MariaDB Docker Documentation](https://mariadb.com/kb/en/installing-and-using-mariadb-via-docker/)
- [WordPress Docker Documentation](https://developer.wordpress.org/advanced-administration/before-install/howto-install/)
- [Nginx Configuration Guide](https://nginx.org/en/docs/beginners_guide.html)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)
