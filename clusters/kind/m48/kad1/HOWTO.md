# Kad1

Test KAD deployment

## Versions:

Flux: 2.5.0
Kad: 0.6.0-snapshot
kind: 0.27.0

## Network setting

To create the kind network

```
kind create cluster
kind delete cluster

docker network inspect kind
```

Ensure kind network is `172.18.0.0/16`

If not, adjust all following IP. or create explicitly the 'kind' network to allow fixed IP

```
docker network rm kind # If kind was already used.
docker network create -d=bridge -o com.docker.network.bridge.enable_ip_masquerade=true -o com.docker.network.driver.mtu=65535  --subnet 172.18.0.0/16 kind
```

> This is not required for our single node cluster. But will be compatible with multi-nodes


## kad1 cluster

```
cat >$(brew --prefix)/etc/dnsmasq.d/kad1 <<EOF
address=/first.pool.kad1.mbp/172.18.101.1 
address=/.ingress.kad1.mbp/172.18.101.1 
address=/padl.kad1.mbp/172.18.101.2 
address=/ldap.kad1.mbp/172.18.101.3 
address=/last.pool.kad1.mbp/172.18.101.4 
EOF


sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping ldap.kad1.mbp
ping padl.kad1.mbp
```


```
cat >/tmp/kad1-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kad1
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5446
EOF
```

```
kind create cluster --config /tmp/kad1-config.yaml
```

```
export GITHUB_USER=SergeAlexandre
export GITHUB_REPO=kad-infra-sa
export GIT_BRANCH=v0.6.0
export GITHUB_TOKEN=

flux bootstrap github \
--owner=${GITHUB_USER} \
--repository=${GITHUB_REPO} \
--branch=${GIT_BRANCH} \
--interval 15s \
--owner kubotal \
--read-write-key \
--path=clusters/kind/m48/kad1/flux


```

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

# cleanup

```
docker stop $(docker ps -a -q)
docker container prune --force
docker volume prune --all --force
docker network prune --force
docker image prune --all --force



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

And crete folder `/Users/sa/dev/registry`


Create registry in docker:

```
docker run -d -p 5001:5000 --restart=always --name registry \
    -v /Users/sa/dev/registry:/var/lib/registry \
    -v /Users/sa/dev/certs:/certs \
     -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/host.docker.internal.crt \
     -e REGISTRY_HTTP_TLS_KEY=/certs/host.docker.internal.key \
    registry:2
```


And create the cluster the following way:

```
cat >/tmp/kad1-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kad1
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /Users/sa/dev/certs/ca-odp.crt
        containerPath: /usr/local/share/ca-certificates/ca-odp.crt
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5446
EOF
```


```
kind create cluster --config /tmp/kad1-config.yaml

docker exec -it kad1-control-plane bash -c "update-ca-certificates"
```

Check `1 added`:

```
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```

Then you can deploy fluxcd as described above
