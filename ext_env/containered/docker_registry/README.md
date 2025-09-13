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