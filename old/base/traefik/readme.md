dashboard
0.0.0.0:30002 
http://192.168.1.11:30002/

При необходимости - проброс порта
```sh
kubectl -n traefik port-forward deploy/traefik 30002:8080
```


logs
```sh
kubectl -n traefik logs -f deploy/traefik
```
