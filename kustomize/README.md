# hack to deploy cf-for-k8s with kustomize/kubectl instead of kapp
## Deploy
1. generate rendered yaml with ytt as normal (cf-for-k8s-rendered.yml)
1. Move cf-for-k8s-rendered.yml to this directory, then use kubectl apply
```
cd $HOME/workspace/cf-for-k8s/kustomize
mv /tmp/cf-for-k8s-rendered.yml .
kubectl apply -k .
```
1. It works!
1. How does ordering work without kapp annotations?
  1. Ordering works with kustomize because it applies namespaces first, then CRDs, then validating/mutating webhook configurations, then serviceaccounts.
  It applies the deployments last.
  1. Webhooks are still able to inject sidecars into every pod because k8s waits for the webhook server to come up before it creates pods for each deployment

## Delete
1. cd kustomize
1. kapp delete -k .
```
cd $HOME/workspace/cf-for-k8s/kustomize
kubectl delete -k .
```
1. There are a bunch of errors but all the resources do seem to get deleted
```
Error from server (NotFound): error when deleting ".": networkpolicies.networking.k8s.io "pilot-network-policy" not found
Error from server (NotFound): error when deleting ".": networkpolicies.networking.k8s.io "sidecar-injector-network-policy" not found
Error from server (NotFound): error when deleting ".": persistentvolumeclaims "cf-blobstore-minio" not found
```
1. It seems possible that these errors would go away once this PR (already merged) is released since it fixes ordering upon deletion
https://github.com/kubernetes-sigs/cli-utils/pull/207

## TODO: what were removed kapp resources doing other than ordering?
## Upgrade/ rotate secrets - ?? todo
