1. Создание секрета regcred

В Kubernetes секрет для авторизации в Docker Registry хранится в формате kubernetes.io/dockerconfigjson.
Создаём его один раз локально:

```sh
kubectl create secret docker-registry regcred \
  --docker-server=reg.chiz.work.gd \
  --docker-username=achi \
  --docker-password=123 \
  --namespace=default \
  --dry-run=client -o yaml > cluster/base/secrets/registry-secret.yaml
```
👉 Файл появится в cluster/base/secrets/registry-secret.yaml.



2. Привязка секрета к ServiceAccount

Чтобы поды автоматически использовали regcred, нужно обновить ServiceAccount по умолчанию:
```sh
kubectl patch serviceaccount default \
  -p '{"imagePullSecrets": [{"name": "regcred"}]}' \
  -n default \
  --dry-run=client -o yaml > cluster/base/secrets/default-serviceaccount.yaml
```

3. Описание kustomization.yaml

Создай cluster/base/secrets/kustomization.yaml:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - registry-secret.yaml
  - default-serviceaccount.yaml
```

4. Подключение в prod

В cluster/environments/prod/kustomization.yaml добавь ссылку:
```yaml
resources:
  - ../../base/secrets
  - ../../base/ingress-controller
  - ../../base/services/chiz-gateway
```

5. Применение

```sh
kubectl apply -k cluster/environments/prod
```

6. Проверка

Проверить, что секрет есть:
```sh
kubectl get secret regcred -n default
``` 

Проверить ServiceAccount:`
```sh
kubectl get sa default -o yaml -n default | grep imagePullSecrets -A2
```
Должно быть:
```sh
>>>
imagePullSecrets:
- name: regcred
```