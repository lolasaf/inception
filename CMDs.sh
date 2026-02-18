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

# build all
make

# Check running containers and ports used
cd srcs
docker compose ps

# Check SSL certificate
curl -v https://wel-safa.42.fr
openssl s_client -connect wel-safa.42.fr:443

# Check http / https conncetion
curl -Ik http://wel-safa.42.fr
curl -Ik https://wel-safa.42.fr

# Clean everything
make fclean

# Start fresh
make

# Check logs
docker compose logs mariadb

# Check volumes
docker volume ls
docker volume inspect <volume_name>

# Login to the database (in srcs directory):
# from host:
docker exec -it mariadb mariadb -uwpuser -p wordpress
# from root:
docker exec -it mariadb mariadb -uroot -p"$(cat ../secrets/db_root_password.txt | tr -d '\n')" wordpress

# once logged in, run SQL commands to check tables and users:
SHOW TABLES;
SELECT user_login FROM wp_users;
SELECT * FROM <table_name> LIMIT 1;
exit;

