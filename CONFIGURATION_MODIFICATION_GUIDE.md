# Service 1: Nginx: Change to Port 8443 from 443

**1. Edit `srcs/docker-compose.yml`**
```yaml
ports:
  - "8443:8443"
```

**2. Edit `srcs/requirements/nginx/conf/default`**
```nginx
listen 8443 ssl default_server;
listen [::]:8443 ssl default_server;
```

**3. Edit `srcs/.env`**
```dotenv
WP_URL=https://wel-safa.42.fr:8443
```

**4. Run**
```bash
make fclean && make up
```

**5. Test**
```bash
curl -Ik https://wel-safa.42.fr:8443
# HTTP/1.1 200 OK
# or on browser https://wel-safa.42.fr:8443
```

---

## Service 2: WordPress PHP-FPM (Port 9000 → 9001)

**1. Edit `srcs/requirements/wordpress/Dockerfile`**
```dockerfile
RUN sed -i 's|^listen = .*|listen = 9001|' /etc/php/8.2/fpm/pool.d/www.conf
EXPOSE 9001
```

**2. Edit `srcs/requirements/nginx/conf/default`**
```nginx
fastcgi_pass wordpress:9001;
```

**3. Run**
```bash
make fclean && make up
```

**4. Test**
```bash
docker exec wordpress netstat -tuln | grep 9001
curl -Ik https://wel-safa.42.fr
# HTTP/1.1 200 OK
```

---

## Service 3: MariaDB (Port 3306 → Custom Port)

**1. Edit `srcs/requirements/mariadb/Dockerfile`**
```dockerfile
EXPOSE 3307
```

**2. Edit `srcs/requirements/mariadb/tools/entrypoint.sh`** (change the mysqld startup line)
```bash
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0 --port=3307
```

**3. Edit `srcs/requirements/wordpress/tools/entrypoint.sh`** (update DB port)
```bash
mariadb -h mariadb -P 3307 -u "$MYSQL_USER" -p"$DB_PASS" -e "SELECT 1" "$MYSQL_DATABASE" >/dev/null 2>&1
```

```bash
wp config create \
  --dbhost="mariadb:3307"
```

**4. Run**
```bash
make fclean && make up
```

**5. Test**
```bash
docker exec mariadb netstat -tuln | grep 3307
curl -Ik https://wel-safa.42.fr
# HTTP/1.1 200 OK
```

---

## Important Notes for Evaluation

### Understanding Bind Mounts vs Docker Volumes

Your project uses **bind mounts** (not Docker volumes):
```yaml
mariadb_data:
  driver_opts:
    type: none
    device: /home/wel-safa/data/mariadb  # ← Host directory
```

**This is important:** When you run `docker compose down --volumes`, it does **NOT** delete the host directories. It only removes Docker metadata. The actual `/home/wel-safa/data/` directories remain on your host.

**For port changes:** You must delete the actual host directories, not just use `docker compose down --volumes`. This is why `make fclean` has been updated to explicitly delete `/home/wel-safa/data/mariadb` and `/home/wel-safa/data/wordpress`.
- **NGINX** (port 443): Published to host - accessible from outside
- **WordPress PHP-FPM** (port 9000): Internal only - only NGINX can access it
- **MariaDB** (port 3306): Internal only - only WordPress can access it

**Never expose MariaDB or PHP-FPM ports to the host machine in docker-compose!** They should remain internal to the docker network.

### Configuration Checklist

When modifying any service port:

- [ ] Update docker-compose.yml (if host port is published)
- [ ] Update the service's Dockerfile(s)
- [ ] Update dependent service configurations (e.g., NGINX must know WordPress's new port)
- [ ] Run `make down && make up`
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
make up
```

---

## Quick Reference: Full Modification Workflow

```bash
# 1. Modify configuration files as described above
# 2. Stop current services
make down

# 3. Rebuild and start everything
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
make up                     # Rebuild with new configs and start services
# Verify functionality