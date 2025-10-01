```sh
stern --all-namespaces .
```

Синхронизация
```sh
kubectl apply -k .   
```

Откат
```sh
kubectl delete -k .
```

лог кластера:
```sh
kubectl get events -n traefik --sort-by='.lastTimestamp'
```