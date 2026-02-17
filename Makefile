# ==============================================================================
# INCEPTION - Docker Infrastructure Makefile
# ==============================================================================
# This Makefile manages a multi-container Docker setup for WordPress
# Includes: nginx (web server), WordPress (CMS), MariaDB (database)
# ==============================================================================

# Project name for identification
NAME = inception

# Docker Compose command with configuration file and environment variables
COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env

# ==============================================================================
# TARGETS
# ==============================================================================

# Default target: start all services
all: up

# Start services: create data directories and launch containers
up:
	@echo "Creating data directories..."
	mkdir -p /home/$(USER)/data/mariadb /home/$(USER)/data/wordpress
	@echo "Starting Docker containers..."
	$(COMPOSE) up -d --build

# Stop all running containers
down:
	@echo "Stopping containers..."
	$(COMPOSE) down

# Restart: stop then start services
re: down up

# Clean: stop containers and remove volumes (WARNING: deletes database data)
clean:
	@echo "Stopping containers and removing volumes..."
	$(COMPOSE) down --volumes

# Full clean: remove all Docker resources (images, containers, networks)
fclean: clean
	@echo "Removing all Docker resources..."
	docker system prune -af

# Declare phony targets (not actual files)
.PHONY: all up down re clean fclean