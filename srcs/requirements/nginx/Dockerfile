# ==============================================================================
# NGINX DOCKERFILE
# ==============================================================================
# Builds an Nginx web server container that serves as reverse proxy
# Forwards PHP requests to WordPress container and serves static files
# ==============================================================================

# Use minimal Debian 12 (Bookworm) as base image
FROM debian:bookworm-slim

# Build argument for domain name (passed from docker-compose)
ARG DOMAIN_NAME=wel-safa.42.fr

# Install Nginx web server and OpenSSL for SSL certificates
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directory for SSL certificates
RUN mkdir -p /etc/nginx/ssl

# Copy SSL certificates
# COPY conf/certificate.crt /etc/nginx/ssl/certificate.crt
# COPY conf/private.key /etc/nginx/ssl/private.key

# Generate self-signed SSL certificate during build
# This ensures certificates exist on any machine that builds the image
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/private.key \
    -out /etc/nginx/ssl/certificate.crt \
    -subj "/C=DE/ST=Berlin/L=Berlin/O=42Network/OU=Inception/CN=${DOMAIN_NAME}"


# Set proper permissions for private key
RUN chmod 600 /etc/nginx/ssl/private.key && \
    chmod 644 /etc/nginx/ssl/certificate.crt

# Copy custom Nginx configuration
COPY conf/default /etc/nginx/sites-available/default

# Enable the site configuration
# Remove the default symbolic link (if it exists)
RUN rm -f /etc/nginx/sites-enabled/default
# Create a symbolic link from sites-available to sites-enabled
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Expose HTTPS port
EXPOSE 443

# Start Nginx in foreground mode (required for Docker containers)
CMD ["nginx", "-g", "daemon off;"]