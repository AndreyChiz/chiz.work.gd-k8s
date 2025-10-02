
### installation:

```sh
helm install argocd cluster/base/argo-cd/ -n argocd --create-namespace

kubectl apply -f base-apps.yaml -n argocd  
```
