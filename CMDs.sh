# Generate Secrets
mkdir -p secrets
openssl rand -base64 24 > secrets/db_root_password.txt
openssl rand -base64 24 > secrets/db_password.txt
openssl rand -base64 24 > secrets/wp_admin_password.txt
openssl rand -base64 24 > secrets/wp_user_password.txt
chmod 600 secrets/*.txt

# Create .env file
cat > srcs/.env << 'EOF'
LOGIN=wel-safa
DOMAIN_NAME=wel-safa.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_TITLE=Inception
WP_URL=https://wel-safa.42.fr
WP_ADMIN_USER=siteowner
WP_ADMIN_EMAIL=siteowner@42.fr
WP_USER=editor
WP_USER_EMAIL=editor@42.fr
EOF

# Check running containers and ports
cd srcs
docker compose ps

sudo rm -rf /home/wel-safa/data/mariadb/* && sudo rm -rf /home/wel-safa/data/wordpress/* && sleep 2

# Clean everything
make fclean
rm -rf ~/data/*

# Start fresh
make

# Check logs
docker compose logs mariadb