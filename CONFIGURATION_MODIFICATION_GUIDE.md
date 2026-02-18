# Configuration Modification Guide for Inception Evaluation

This guide explains how to modify service configurations during the evaluation, specifically for port changes. Each service has different configuration points that must be updated together to ensure functionality.

---

## Overview of Services & Their Ports

- **NGINX**
    - Default Port: 443 (HTTPS)
    - Type: Published (Host ↔ Container)
    - Configuration Files: `docker-compose.yml` + `nginx/conf/default`

- **WordPress PHP-FPM**
    - Default Port: 9000
    - Type: Internal Only
    - Configuration Files: `wordpress/Dockerfile` + `nginx/conf/default`

- **MariaDB**
    - Default Port: 3306
    - Type: Internal Only
    - Configuration Files: `mariadb/Dockerfile` (never published)

---

## Service 1: NGINX (Port 443 → Custom Port)

**Example: Change from port 443 to port 8443**

### Step 1: Update docker-compose.yml

**File:** `srcs/docker-compose.yml`

**Current configuration:**
```yaml
nginx:
  container_name: nginx
  # ... other config ...
  ports:
    - "443:443"
```

**Modified configuration:**
```yaml
nginx:
  container_name: nginx
  # ... other config ...
  ports:
    - "8443:443"
```

**What this does:**
- Left side (8443) = Port on your host machine
- Right side (443) = Port inside the container (unchanged)
- Now access via `https://wel-safa.42.fr:8443` instead of `https://wel-safa.42.fr`

### Step 2: Update NGINX Configuration

**File:** `srcs/requirements/nginx/conf/default`

**Current configuration:**
```nginx
server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    # ... rest of config ...
}
```

**Modified configuration (port 8443 example):**
```nginx
server {
    listen 8443 ssl default_server;
    listen [::]:8443 ssl default_server;
    # ... rest of config ...
}
```

**Note:** This line is NOT needed since we already mapped the port in docker-compose. However, it's good practice to document the actual listening port.

### Step 3: Rebuild and Restart

```bash
# From the project root directory
make down        # Stop containers
make build       # Rebuild images with new configurations
make up          # Start containers

# Or using docker-compose directly:
cd srcs
docker-compose down
docker-compose build
docker-compose up -d
```

### Verification

```bash
# Check if NGINX is accessible on the new port
curl -k https://wel-safa.42.fr:8443

# Or in browser: https://wel-safa.42.fr:8443
```

---

## Service 2: WordPress PHP-FPM (Port 9000 → Custom Port)

**Example: Change from port 9000 to port 9001**

### Step 1: Update WordPress Dockerfile

**File:** `srcs/requirements/wordpress/Dockerfile`

**Current configuration:**
```dockerfile
RUN mkdir -p /run/php \
 && sed -i 's|^listen = .*|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

# ... other config ...

EXPOSE 9000
```

**Modified configuration (port 9001 example):**
```dockerfile
RUN mkdir -p /run/php \
 && sed -i 's|^listen = .*|listen = 9001|' /etc/php/8.2/fpm/pool.d/www.conf

# ... other config ...

EXPOSE 9001
```

**What this does:**
- Changes the PHP-FPM listening port inside the container
- EXPOSE is just documentation; the actual port mapping happens in docker-compose

### Step 2: Update NGINX Configuration

**File:** `srcs/requirements/nginx/conf/default`

**Current configuration:**
```nginx
location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    
    # Forward PHP requests to WordPress container on port 9000
    fastcgi_pass wordpress:9000;
    
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
}
```

**Modified configuration (port 9001 example):**
```nginx
location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    
    # Forward PHP requests to WordPress container on port 9001
    fastcgi_pass wordpress:9001;
    
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
}
```

**Important:** Both places must match! NGINX must know which port WordPress is listening on.

### Step 3: Rebuild and Restart

```bash
make down        # Stop containers
make build       # Rebuild images (WordPress Dockerfile will be rebuilt)
make up          # Start containers
```

### Verification

```bash
# Check if wordpress container is listening on the new port
docker exec wordpress netstat -tuln | grep 9001

# Check NGINX logs for any connection errors
docker logs nginx

# Test if WordPress is still accessible via HTTPS (verify in browser)
# The change should be transparent to the end user
```

---

## Service 3: MariaDB (Port 3306 → Custom Port)

**Example: Change from port 3306 to port 3307**

### Step 1: Update MariaDB Dockerfile

**File:** `srcs/requirements/mariadb/Dockerfile`

**Current configuration:**
```dockerfile
EXPOSE 3306
```

**Modified configuration (port 3307 example):**
```dockerfile
EXPOSE 3307
```

### Step 2: Update MariaDB Configuration

**File:** `srcs/requirements/mariadb/tools/entrypoint.sh`

Add or modify the MariaDB server configuration to listen on the new port. This is typically done in the my.cnf configuration file:

**Option A: Modify during container startup (recommended)**

Add this to your entrypoint script before starting MariaDB:

```bash
# Set the port for MariaDB
sed -i 's|^port = .*|port = 3307|' /etc/mysql/mariadb.conf.d/50-server.cnf

# Or if using a custom config:
echo "[mysqld]\nport=3307" >> /etc/mysql/mariadb.conf.d/custom.cnf
```

### Step 3: Update WordPress Entrypoint Script

**File:** `srcs/requirements/wordpress/tools/entrypoint.sh`

**Current configuration (look for the MySQL connection):**
```bash
# MySQL connection typically uses:
mysql -h mariadb -u root -p"$ROOT_PASS" ...
```

**No changes needed!** WordPress connects to MariaDB using DNS resolution (service name "mariadb"), not the port directly in docker-compose. The port change is the container's internal concern.

**However**, if there are explicit port references, update them:
```bash
# If you see: mysql -h mariadb -P 3306 ...
# Change to: mysql -h mariadb -P 3307 ...
```

### Step 4: Rebuild and Restart

```bash
make down        # Stop containers
make build       # Rebuild images
make up          # Start containers
```

### Verification

```bash
# Check if MariaDB is listening on the new port inside the container
docker exec mariadb netstat -tuln | grep 3307

# Test connection from WordPress container
docker exec wordpress mysql -h mariadb -P 3307 -u root -p"$(cat /run/secrets/db_root_password)" -e "SELECT 1;"

# Verify WordPress still works
curl -k https://wel-safa.42.fr
```

---

## Important Notes for Evaluation

### Network Isolation Reminder
- **NGINX** (port 443): Published to host - accessible from outside
- **WordPress PHP-FPM** (port 9000): Internal only - only NGINX can access it
- **MariaDB** (port 3306): Internal only - only WordPress can access it

**Never expose MariaDB or PHP-FPM ports to the host machine in docker-compose!** They should remain internal to the docker network.

### Configuration Checklist

When modifying any service port:

- [ ] Update docker-compose.yml (if host port is published)
- [ ] Update the service's Dockerfile(s)
- [ ] Update dependent service configurations (e.g., NGINX must know WordPress's new port)
- [ ] Run `make down && make build && make up`
- [ ] Verify service is accessible or functioning correctly
- [ ] Check logs for connection errors: `docker logs <service_name>`
- [ ] Test full stack (e.g., access WordPress and verify database queries work)

### Rollback Procedure

If something breaks during modification:

```bash
# Stop everything
make down

# Revert your changes to the configuration files
git checkout srcs/

# Rebuild and restart
make build
make up
```

---

## Quick Reference: Full Modification Workflow

```bash
# 1. Modify configuration files as described above
# 2. Stop current services
make down

# 3. Rebuild with new configurations
make build

# 4. Start everything
make up

# 5. Verify services are running
docker-compose -f srcs/docker-compose.yml ps

# 6. Test functionality
curl -k https://wel-safa.42.fr
```

---

## Troubleshooting Common Issues

### Issue: NGINX can't connect to WordPress
**Cause:** Port mismatch between WordPress listening port and NGINX fastcgi_pass
**Solution:** Ensure both Dockerfile and nginx/conf/default use the same port

### Issue: WordPress can't connect to database
**Cause:** Port mismatch between MariaDB listening port and WordPress connection string
**Solution:** Check entrypoint.sh for explicit port references; update if present

### Issue: Services don't start
**Cause:** Maybe the new port is already in use on the host
**Solution:** Check with `netstat -tuln | grep <port>` or choose a different port

### Issue: Website loads but shows errors
**Cause:** May be a cache issue or incomplete startup
**Solution:** Clear containers and volumes, then rebuild with `make down` and `make up`

## FOR EACH MODIFICATION
git checkout srcs/          # (if needed to revert)
# Edit configuration files
make down                   # Stop containers
make build                  # Rebuild with new configs
make up                     # Start services
# Verify functionality