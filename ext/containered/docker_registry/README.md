# Содержание
- [Установка и запуска](#установка-и-запуска)
- [Удаление образов](#удаление-образов)




## Установка и запуска

1. Создать каталоги рядом с docker-compose.yml:

```sh
mkdir auth registry_data
```

2. Создать htpasswd для Registry:

```sh
docker run --rm --entrypoint htpasswd httpd:2 -Bbn achi 123y > auth/htpasswd
```

```sh
# альтернатива
sudo apt-get install apache2-utils -y
mkdir -p ./auth

htpasswd -Bbn achi 123 > ./auth/htpasswd
```

3. Настройка на хорсте откуда пушить

```ssh
docker login <IP_или_HOST>:5000

# <IP_или_HOST> — адрес сервера с твоим Registry.
# Username / Password — те, что ты указал в htpasswd (admin / Harbor123).
# После успешного логина Docker сохранит учётку в ~/.docker/config.json.

```

4. Тегирование образа

```sh
docker tag my-app:latest <IP_или_HOST>:5000/my-app:latest
```

5. Push

```sh
docker push <IP_или_HOST>:5000/my-app:latest
```

🔹 Дополнительно

Если Registry защищён TLS, используем его URL (https://...).

Если Registry insecure (без TLS), на хосте нужно разрешить небезопасный Registry:

```sh
# В /etc/docker/daemon.json
{
  "insecure-registries" : ["<IP_или_HOST>:5000"]
}
```

```sh
sudo systemctl restart docker
```

6. Pull
   Если новый хост, пердлварительно выполнить шаг 3.

```shdocker pull <IP_или_HOST>:5000/my-app:latest

```

7. Push

```sh
cat > Dockerfile <<EOF
FROM alpine:3.18
LABEL maintainer="achi"
RUN echo "Hello Docker Registry куфе!" > /hello.txt
EOF
```

```sh
sudo docker build -t chiz-work-test:777 .
```

```sh
sudo docker tag chiz-work-test:777 chiz.work.gd/chiz-work-test:777
sudo docker push chiz.work.gd/chiz-work-test:777
```


## Удаление образов 
### Установка cli утилиты

```sh
curl -LO https://github.com/genuinetools/reg/releases/download/v0.14.0/reg-linux-arm64       
chmod +x reg-linux-arm64
sudo mv reg-linux-arm64 /usr/local/bin/reg
```

```sh 
reg -u achi -p 123  ls reg.chiz.work.gd

Repositories for reg.chiz.work.gd
REPO                TAGS
chiz-api-gateway    0.0.1a, 0.0.2a, 0.0.3a
chiz-work-test      777
gateway             latest
```

```sh
reg -u achi -p 123 rm reg.chiz.work.gd/chiz-api-gateway:0.0.1a
reg -u achi -p 123 rm reg.chiz.work.gd/chiz-api-gateway:0.0.2a


#После удаления запускаем garbage
docker stop chiz-docker-registry
docker run --rm \
  -v /home/www/src/chiz.work.gd-k8s/ext_env/containered/docker_registry/registry_data/:/var/lib/registry \
  registry:2 garbage-collect /etc/docker/registry/config.yml
docker start chiz-docker-registry

```

```sh
 docker exec -it chiz-docker-registry registry garbage-collect /etc/docker/registry/config.yml  
 ```