## Обновление сертификатов

```sh
sudo certbot --nginx -d reg.chiz.work.gd
```

## Пеерзагрузка nginx

```sh
sudo nginx -t
sudo systemctl reload nginx
```