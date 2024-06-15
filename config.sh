#!/bin/bash

#Установка Docker и его компонентов
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
#sudo usermod -aG docker $USER 


#Подготовка инфраструктуры для создания кастомного образа NGINX
mkdir /home/vagrant/docker && cd /home/vagrant/docker

#Подготовка конфигурационных файлов NGINX
#default.conf
echo -e "
server {
    listen       80;
    listen       [::]:80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
" > default.conf\

#nginx.conf
echo -e "
user  nginx;
worker_processes  auto;
         
error_log /var/log/nginx/error.log notice;
pid       /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {         
    include      /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    access_log  /var/log/nginx/access.log;
    
    sendfile    on;
    keepalive_timeout  65;
         
    include /etc/nginx/conf.d/*.conf;
}" > nginx.conf

#index.html
echo -e '
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to CUSTOM NGINX!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.
         
<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>' > index.html

#Dockerfile
echo -e '
FROM alpine:latest
RUN apk update && apk upgrade
RUN apk add nginx
RUN mkdir /etc/nginx/conf.d
COPY default.conf /etc/nginx/conf.d/
COPY nginx.conf /etc/nginx/nginx.conf
RUN mkdir /usr/share/nginx/html
COPY index.html  /usr/share/nginx/html/
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]' > Dockerfile

#Подготовка кастомного образа nginx
sudo docker build -t nginx-custom:v1 .

#Запуск контейнера nginx из образа nginx-custom:v1
sudo docker run -d -p 8080:80 nginx-custom:v1
