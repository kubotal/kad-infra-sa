
# kubo1 cluster

## Network setting

```
cat >$(brew --prefix)/etc/dnsmasq.d/kubo1 <<EOF
address=/first.pool.kubo1.mbp/172.18.103.1 
address=/.ingress.kubo1.mbp/172.18.103.1 
address=/ldap.kubo1.mbp/172.18.103.2 
address=/last.pool.kubo1.mbp/172.18.103.4 
EOF


sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping ldap.kubo1.mbp
```


## Cluster creation

WARNING: See use local registry if applicable

```
cat >/tmp/kubo1-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo1
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5447
EOF
```

```
kind create cluster --config /tmp/kubo1-config.yaml
```

```
export GITHUB_USER=SergeAlexandre
export GITHUB_REPO=kad-infra-sa
export GIT_BRANCH=main
export GITHUB_TOKEN=

flux bootstrap github \
--owner=${GITHUB_USER} \
--repository=${GITHUB_REPO} \
--branch=${GIT_BRANCH} \
--interval 15s \
--owner kubotal \
--read-write-key \
--path=clusters/kind/m48/kubo1/flux

```

And git pull on kad-infra-sa 

# Decrease reaction time on dependencies

In flux-system/kustomization, add patches:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- gotk-components.yaml
- gotk-sync.yaml
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --requeue-dependency=5s
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller)"
```

# Deployment kubocd

```
cd ..../kad-infra-sa/clusters/kind/m48/kubo1
kubectl create ns kubocd

helm upgrade -i -n kubocd kubocd oci://quay.io/kubocd/charts/kubocd:v0.1.1-snapshot --values ./values1.yaml
```

# Using local registry

Manage to have:

```
$ tree /Users/sa/dev/certs/
/Users/sa/dev/certs/
|-- ca-odp.crt
|-- host.docker.internal.crt
|-- host.docker.internal.key
|-- localhost.crt
`-- localhost.key
```

And create folder `/Users/sa/dev/registry`


Create registry in docker:

```
docker run -d -p 5001:5000 --restart=always --name registry \
    -v /Users/sa/dev/registry:/var/lib/registry \
    -v /Users/sa/dev/certs:/certs \
     -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/host.docker.internal.crt \
     -e REGISTRY_HTTP_TLS_KEY=/certs/host.docker.internal.key \
     -e REGISTRY_STORAGE_DELETE_ENABLED=true \
    registry:2
```


And create the cluster the following way:

```
cat >/tmp/kubo1-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo1
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5447
EOF
```


```
kind create cluster --config /tmp/kubo1-config.yaml

docker exec -it kubo1-control-plane bash -c "update-ca-certificates"
```

Check `1 added`:

```
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```
