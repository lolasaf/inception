# NAME=inception
# COMPOSE=docker compose -f srcs/docker-compose.yml --env-file srcs/.env

# all: up

# up:
# 	mkdir -p /home/$(USER)/data/mariadb /home/$(USER)/data/wordpress
# 	$(COMPOSE) up -d --build

# down:
# 	$(COMPOSE) down

# re: down up

# clean:
# 	$(COMPOSE) down --volumes

# fclean: clean
# 	docker system prune -af

# .PHONY: all up down re clean fclean