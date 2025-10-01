
### installation:

```sh
helm install argocd ./cluster/base/argo-cd \
  --namespace argocd \
  -f ./cluster/base/argo-cd/values.yaml

kubectl apply -f base-apps.yaml -n argocd  
```