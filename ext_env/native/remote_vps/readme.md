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

## Healthcheck

```sh
# privat docker_registry
curl -u achi:123 -k https://reg.chiz.work.gd/v2/_catalog 

# kubernates
kubectl get nodes
```