# ==============================================================================
# NGINX DOCKERFILE
# ==============================================================================
# Builds an Nginx web server container that serves as reverse proxy
# Forwards PHP requests to WordPress container and serves static files
# ==============================================================================

# Use minimal Debian 12 (Bookworm) as base image
FROM debian:bookworm-slim

# Install Nginx web server
# TODO: Add -y flag and --no-install-recommends for cleaner installation
RUN apt update && apt upgrade && apt install -y \
    nginx

# Copy custom Nginx configuration for WordPress
COPY default /etc/nginx/sites-available/default

# Enable the site configuration
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Expose HTTP port
# TODO: Add port 443 and SSL certificate configuration for HTTPS
EXPOSE 80

# Start Nginx in foreground mode (required for Docker containers)
CMD ["nginx", "-g", "daemon off;"]