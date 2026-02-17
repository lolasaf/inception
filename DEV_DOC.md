# Developer Documentation - Inception

## 1) Environment Setup (from scratch)

### Prerequisites
- Docker and Docker Compose installed
- Port 443 available
- Enough disk space for data volumes

### Repository and configuration files
```bash
git clone <repo-url>
cd inception-repo
```

### Configuration
Create or update the configuration file:
- `srcs/.env` – Set your domain name, database credentials, and WordPress admin details:
   ```
   DOMAIN_NAME=your_domain.com
   DB_NAME=wordpress
   DB_USER=wordpress
   DB_ROOT_PASSWORD=<from secrets/db_root_password.txt>
   DB_PASSWORD=<from secrets/db_password.txt>
   WP_ADMIN_USER=admin
   WP_ADMIN_PASSWORD=<from secrets/wp_admin_password.txt>
   WP_USER=user
   WP_USER_PASSWORD=<from secrets/wp_user_password.txt>
   ```
- `secrets/*.txt` – Create individual files for each password (one per line, no extra whitespace)

### Secrets
Create or update the secret files (one password per file):
- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

Lock permissions:
```bash
chmod 600 secrets/*.txt
```

## 2) Build and Launch

### Using Makefile (recommended)
```bash
make        # build and start
make down   # stop
make re     # restart
make clean  # remove volumes (deletes data)
make fclean # remove images and volumes
```

### Using Docker Compose directly
```bash
# Build Docker images for all services
docker compose -f srcs/docker-compose.yml build
# Start services in background (detached mode)
docker compose -f srcs/docker-compose.yml up -d
# Stop and remove all containers
docker compose -f srcs/docker-compose.yml down
```

## 3) Manage Containers and Volumes

### Containers
```bash
# List running containers
docker ps
# Follow logs for all services
docker compose -f srcs/docker-compose.yml logs -f
# Open a shell inside the WordPress container
docker exec -it wordpress /bin/bash
```

### Volumes
```bash
# List Docker volumes
docker volume ls
# Inspect the MariaDB volume
docker volume inspect inception_mariadb_data
# Inspect the WordPress volume
docker volume inspect inception_wordpress_data
# Stop services and remove volumes (deletes data)
docker compose -f srcs/docker-compose.yml down --volumes
```

## 4) Data Location and Persistence

Data is stored on the host under `/home/wel-safa/data/` and persists across restarts:
- MariaDB data: `/home/wel-safa/data/mariadb`
- WordPress files: `/home/wel-safa/data/wordpress`

Data is only deleted when volumes are removed (`make clean`, `make fclean`, or `docker compose ... down --volumes`).