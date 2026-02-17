*This project has been created as part of the 42 curriculum by wel-safa.*

# Inception

## Description

Inception is a system administration project that focuses on Docker containerization. The goal is to build a small-scale web infrastructure using Docker Compose, consisting of:
- **Nginx** - Web server with SSL/TLS support
- **WordPress** - Content Management System with PHP-FPM
- **MariaDB** - Database server

Each service runs in its own container. The stack is isolated on a Docker network and stores data persistently via Docker volumes.

## Instructions

### Prerequisites
- Docker and Docker Compose installed
- Hostname `wel-safa.42.fr` pointing to your local IP in `/etc/hosts`

### Setup
```bash
# Clone the repository
git clone <repo-url> inception
cd inception

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
- Website: `https://wel-safa.42.fr`
- WordPress Admin: `https://wel-safa.42.fr/wp-admin`
  - Username: `siteowner`
  - Password: stored in `secrets/wp_admin_password.txt`

## Project Structure

The project uses Docker Compose to orchestrate three services:

```
inception-repo/
├── Makefile
├── secrets/                    # Sensitive creds (not in git)
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
├── srcs/
│   ├── .env                    # Environment variables
│   ├── docker-compose.yml      # Service orchestration
│   └── requirements/
│       ├── mariadb/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── tools/
│       │   │   └── entrypoint.sh
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   └── conf/
│       │       └── default
│       └── wordpress/
│           ├── Dockerfile
│           ├── .dockerignore
│           └── tools/
│               └── entrypoint.sh
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── .gitignore
```

## Project Description and Design Choices

### Virtual Machines vs Docker
- **Virtual Machines**: full OS per service, heavier and slower
- **Docker**: lightweight, shared kernel, faster startup, easier service isolation

### Secrets vs Environment Variables
- **Environment Variables**: non-sensitive config in `.env`
- **Docker Secrets**: passwords stored in `secrets/` and mounted at `/run/secrets/`

### Docker Network vs Host Network
- **Docker Network** (bridge): isolated container communication by service name
- **Host Network**: shared host network stack (not used)

### Docker Volumes vs Bind Mounts
- **Docker Volumes**: managed by Docker, portable, good for persistence
- **Bind Mounts**: direct host path mapping

This project uses Docker named volumes with `driver_opts` to store data under `/home/wel-safa/data/` as required.

## Resources

### Docker Beginner tutorials
- [The Coding Sloth: The Only Docker Tutorial You Need To Get Started](https://www.youtube.com/watch?v=DQdB7wFEygo)
- [Cyberflow: Docker in 4 minutes (No BS, No Fluff)](https://www.youtube.com/watch?v=YEyl9CS5oNY)
- [Web Concepts: Docker Explained](https://www.youtube.com/watch?v=WoZobj2Ruj0)

### Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://wordpress.org/documentation/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [WP-CLI Documentation](https://wp-cli.org/)

### AI Usage
AI tools were used to:
- Add concise code comments
- Review Docker and Nginx configuration patterns
- Troubleshoot build/runtime issues
- Draft and simplify documentation

All AI-generated content was reviewed and validated.
