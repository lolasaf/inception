FROM debian:bookworm-slim

RUN apt update && apt upgrade && apt install -y \
    nginx

COPY default /etc/nginx/sites-available/default
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]