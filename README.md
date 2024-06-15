# Практика с Docker #
1. Установить Docker на хост машину: https://docs.docker.com/engine/install/ubuntu/<br/>
  и Docker Compose - как плагин или как отдельное приложение;<br/>
2. Создать кастомный образ NGINX на базе дистрибутива Alpine. После запуска, NGINX<br/>
  должен отдавать кастомную страницу (достаточно изменить дефолтную страницу);<br/>
3. Определить разницу между контейнером и образом. Вывод описать в домашнем задании.
4. Подготовить ответ на вопрос о возможности сборки ядра в контейнере;<br/>
### Исходные данные  ###
&ensp;&ensp;ПК на Linux c 8 ГБ ОЗУ или виртуальная машина (ВМ) с включенной Nested Virtualization.<br/>
&ensp;&ensp;Предварительно установленное и настроенное ПО:<br/>
&ensp;&ensp;&ensp;Hashicorp Vagrant (https://www.vagrantup.com/downloads);<br/>
&ensp;&ensp;&ensp;Oracle VirtualBox (https://www.virtualbox.org/wiki/Linux_Downloads).<br/>
&ensp;&ensp;&ensp;Все действия проводились с использованием Vagrant 2.4.0, VirtualBox 7.0.14 и образа<br/> 
&ensp;&ensp;ubuntu/jammy64 версии 20240301.0.0.<br/> 
### Ход решения ###
&ensp;&ensp;Конфигурирование хостовой машины осуществлялось с использованием bash-скрипта config.sh.<br/>
Ниже представлены фрагменты скрипта согласно пунктов домашнего задания.
1. ##### Установка Docker и других необходимых компонентов:<br/>
```shell
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
```
2. ##### Подготовка инфраструктуры для создания кастомного образа NGINX, его сборка и запуск контейнера:<br/>
```shell
mkdir /home/vagrant/docker && cd /home/vagrant/docker

#Подготовка конфигурационных файлов NGINX и файла Dockerfile
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
```
&ensp;&ensp;- Проверка работы Docker и контейнера NGINX на виртуальной машине:
```shell
vagrant@docker~/docker$ sudo docker images
REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
nginx-custom   v1        eb309f34a6f4   10 minutes ago   17.9MB

vagrant@docker~/docker$ sudo docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED         STATUS         PORTS                                   NAMES
03e98f8aa27e   nginx-custom:v1   "/usr/sbin/nginx -g …"   10 minutes ago  Up 10 minutes  0.0.0.0:8080->80/tcp, :::8080->80/tcp   competent_bohr

vagrant@docker:~/docker$ ps afx | grep docker
   1886 pts/0    S+     0:00              \_ grep --color=auto docker
    675 ?        Ssl    0:00 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
   1764 ?        Sl     0:00  \_ /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 8080 -container-ip 172.17.0.2 -container-port 80
   1771 ?        Sl     0:00  \_ /usr/bin/docker-proxy -proto tcp -host-ip :: -host-port 8080 -container-ip 172.17.0.2 -container-port 80

vagrant@docker~/docker$ curl http://localhost:8080
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
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
&ensp;&ensp;- Проверка работы контейнера NGINX из хостовой машины:<br/>
![изображение](https://github.com/DemBeshtau/13_1_DZ/assets/149678567/b11c25d0-9be8-456b-b5c6-2c363783c506)

3. ##### Определение разницы между контейнером и образом.<br/>
&ensp;&ensp;Образом в Docker называется исполняемый пакет, содержащий в себе всё необходимое для запуска приложения: непосредственно приложение, среда исполнения,
библиотеки, переменные окружения, файлы конфигурации. Является шаблоном для создания контейнеров.<br/>
&ensp;&ensp;Контейнером в Docker называется называется запущенный изолированный образ с возможностью временного хранения данных, которые уничтожаются после удаления
контейнера.<br/>
&ensp;&ensp;Говоря языком объектно-ориентированного программирования, образ - это класс, а контейнер - экземпляр этого класса (объект).<br/>

4. ##### Ответ на вопрос о возможности сборки ядра в контейнере.<br/>
&ensp;&ensp;Исходя из предназначения и логики работы контейнеров Docker, можно говорить, что при наличии в подготовленном образе компилятора с необходимой рабочей средой и исходных кодов ядра, компиляция ядра, в запущенном из этого образа контейнере, возможна. 



