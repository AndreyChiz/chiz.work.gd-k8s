## Установка
заменить на vps /etc/gninx  на /nginx из этой директории


## Примечания

### Обновление сертификатов

```sh
sudo certbot --nginx -d reg.chiz.work.gd
```

### Пеерзагрузка nginx

```sh
sudo nginx -t
sudo systemctl reload nginx
```