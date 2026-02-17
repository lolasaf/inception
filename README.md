# Inception

*This project has been created as part of the 42 curriculum by wel-safa.*

## Description

Inception is a system administration project that focuses on Docker containerization. The goal is to build a small-scale web infrastructure using Docker Compose, consisting of:
- **Nginx** - Web server with SSL/TLS support
- **WordPress** - Content Management System with PHP-FPM
- **MariaDB** - Database server

Each service runs in its own container, following Docker best practices and security guidelines. The entire infrastructure is orchestrated using Docker Compose, with persistent data storage via Docker volumes.

## Instructions

### Prerequisites
- Docker and Docker Compose installed
- Virtual Machine (recommended)
- The hostname `wel-safa.42.fr` pointing to `127.0.0.1` in your `/etc/hosts` file

### Setup
```bash
# Clone the repository
git clone <your-repo-url>
cd inception-repo

# Add domain to /etc/hosts
echo "127.0.0.1 wel-safa.42.fr" | sudo tee -a /etc/hosts

# Build and start all services
make
```

### Usage
```bash
make        # Build and start all services
make down   # Stop all services
make re     # Restart all services
make clean  # Stop services and remove volumes (WARNING: deletes data)
make fclean # Full cleanup including Docker images
```

### Access
- Website: `http://wel-safa.42.fr` (or `https://wel-safa.42.fr` after SSL setup)
- WordPress Admin: `http://wel-safa.42.fr/wp-admin`
  - Username: `siteowner`
  - Password: Located in `secrets/wp_admin_password.txt`

## Project Structure

The project uses Docker Compose to orchestrate three services:

```
inception-repo/
├── Makefile              # Project build automation
├── secrets/              # Sensitive credentials (not in git)
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env              # Environment variables
    ├── docker-compose.yml # Service orchestration
    └── requirements/
        ├── mariadb/      # Database container
        ├── nginx/        # Web server container
        └── wordpress/    # Application container
```

### Design Choices

#### Virtual Machines vs Docker
- **Virtual Machines**: Full OS isolation, higher resource overhead, slower startup
- **Docker** (used in this project): Lightweight, shared kernel, fast startup, efficient resource usage, perfect for microservices architecture

#### Secrets vs Environment Variables
- **Environment Variables**: Suitable for non-sensitive configuration (domain names, usernames)
- **Docker Secrets** (used for passwords): Mounted as files at `/run/secrets/`, more secure, not visible in `docker inspect`, recommended for production

#### Docker Network vs Host Network
- **Docker Network** (bridge, used here): Isolated network for inter-container communication, better security, port mapping control
- **Host Network**: Container shares host's network stack, less isolation, used for performance-critical applications

#### Docker Volumes vs Bind Mounts
- **Docker Volumes** (used here): Managed by Docker, better performance, easier backups, platform-independent
- **Bind Mounts**: Direct host filesystem mapping, useful for development, but less portable

The project uses Docker volumes with bind mount driver options to satisfy the requirement of storing data in `/home/wel-safa/data/`.

## Resources

### Documentation and Tutorials
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [WordPress Codex](https://wordpress.org/documentation/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [WP-CLI Documentation](https://wp-cli.org/)

### AI Usage
AI tools were used for:
- **Code Comments**: Generating comprehensive inline documentation for better code understanding
- **Configuration Best Practices**: Researching Docker, Nginx, and PHP-FPM configuration patterns
- **Troubleshooting**: Debugging container networking and service communication issues
- **Documentation**: Structuring and formatting README files

All AI-generated content was reviewed, tested, and modified to ensure correctness and compliance with project requirements.

## Status

### ✅ Completed
- [x] Docker Compose configuration
- [x] MariaDB container with custom Dockerfile
- [x] WordPress container with PHP-FPM
- [x] Nginx container configuration
- [x] Docker volumes for persistent storage
- [x] Docker network for inter-container communication
- [x] Environment variables and secrets management
- [x] Automated database initialization
- [x] Automated WordPress installation with WP-CLI
- [x] Two WordPress users (admin + author)
- [x] Makefile for project management
- [x] Comprehensive code comments and documentation

### ⚠️  In Progress / To Do
- [ ] **SSL/TLS Configuration** - CRITICAL: Project requires HTTPS with TLSv1.2/1.3
- [ ] **README.md** - Create comprehensive project documentation
- [ ] **USER_DOC.md** - Write user documentation
- [ ] **DEV_DOC.md** - Write developer documentation
- [ ] Volume type verification - Ensure using proper Docker named volumes (not bind mounts)
- [ ] Testing and validation

### Optional (Bonus)
- [ ] Redis cache for WordPress
- [ ] FTP server container
- [ ] Static website (non-PHP)
- [ ] Adminer database management tool
- [ ] Additional service of choice

## Next Steps

See [DEV_DOC.md](DEV_DOC.md) for detailed development instructions.
