# Developer Documentation - Inception

## Architecture

### System Overview

The Inception infrastructure consists of three isolated Docker containers communicating through a private Docker bridge network:

```
┌────────────────────────────────────────┐
│  NGINX Container (Port 443)            │
│  - HTTPS/TLS termination               │
│  - Reverse proxy to PHP-FPM            │
│  - Serves static files                 │
└────────────────────────────────────────┘
         ↓ TCP port 9000
┌────────────────────────────────────────┐
│  WordPress Container (PHP-FPM)         │
│  - Executes WordPress PHP code         │
│  - Manages WordPress business logic    │
│  - Processes requests from NGINX       │
└────────────────────────────────────────┘
         ↓ TCP connection (port 3306)
┌────────────────────────────────────────┐
│  MariaDB Container                     │
│  - Stores WordPress data               │
│  - Handles all database queries        │
└────────────────────────────────────────┘
```

### Request Flow

**Example: User visits `https://wel-safa.42.fr/`**

```
1. Browser → NGINX (HTTPS port 443)
   ├─ TLS handshake (verified certificate)
   └─ HTTP request decrypted

2. NGINX receives request
   ├─ Is it a static file? (.css, .js, .jpg)
   │  └─ Serve directly from /var/www/html
   └─ Is it a .php file?
      └─ Forward to PHP-FPM via TCP port 9000

3. PHP-FPM processes request
   ├─ Load WordPress files (wp-load.php)
   ├─ Connect to MariaDB
   ├─ Query database for page content
   └─ Generate HTML response

4. MariaDB executes query
   ├─ Retrieve pages, posts, users, etc.
   └─ Return data to PHP-FPM

5. PHP-FPM → NGINX
   └─ HTML response

6. NGINX → Browser
   ├─ Encrypt with TLS
   └─ Send over HTTPS port 443
```

### Container Communication

| Path | Protocol | Purpose |
|------|----------|---------|
| NGINX ↔ PHP-FPM | TCP (port 9000) | FastCGI request processing |
| PHP-FPM ↔ MariaDB | TCP (port 3306) | Database queries |
| Browser ↔ NGINX | HTTPS (port 443) | Public web traffic |
| All containers | Docker bridge network `inception` | Service discovery (hostname resolution) |

### Services

**NGINX**
- Web server and reverse proxy
- Terminates TLS/SSL connections
- Routes PHP requests to PHP-FPM
- Serves static content directly
- Only exposed port: 443 (HTTPS)

**WordPress (PHP-FPM)**
- FastCGI Process Manager for PHP 8.2
- Executes WordPress application code
- Manages user authentication, posts, pages, plugins
- Communicates with MariaDB for data
- Listens on TCP port 9000 (internal only)

**MariaDB**
- Relational database server
- Stores all WordPress data (posts, users, settings, etc.)
- Listens on port 3306 (internal only)
- Data persists in Docker volumes

### Volumes & Data Persistence

| Volume | Host Path | Container Path | Purpose |
|--------|-----------|-----------------|---------|
| `mariadb_data` | `/home/wel-safa/data/mariadb` | `/var/lib/mysql` | Database files (persists across restarts) |
| `wordpress_data` | `/home/wel-safa/data/wordpress` | `/var/www/html` | WordPress files, uploads, themes (persists across restarts) |

### Networking

- **Network Type**: Docker bridge (custom `inception` network)
- **Isolation**: Containers cannot reach the host network or external services directly
- **Service Discovery**: Containers resolve service names via Docker DNS
  - `mariadb` → Container IP
  - `wordpress` → Container IP
  - `nginx` → Container IP

### Why This Architecture?

**Separation of Concerns**
- Each service has one responsibility
- Easy to update, scale, or replace individual components

**Security**
- Only NGINX exposed to the public (port 443)
- Database and PHP-FPM only accessible within the network
- TLS/SSL encryption for all client communication

**Performance**
- NGINX is lightweight and fast
- PHP-FPM scales with multiple worker processes
- TCP port 9000 allows flexibility in container communication

**Scalability**
- Each container can be independently restarted or updated
- Volumes decouple data from containers
- Docker Compose orchestrates startup order and dependencies

---

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