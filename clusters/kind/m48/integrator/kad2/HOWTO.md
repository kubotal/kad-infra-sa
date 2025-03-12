# kad2

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


## kad2 cluster

```
cat >$(brew --prefix)/etc/dnsmasq.d/kad2 <<EOF
address=/first.pool.kad2.mbp/172.18.102.1 
address=/.ingress.kad2.mbp/172.18.102.1 
address=/padl.kad2.mbp/172.18.102.2 
address=/ldap.kad2.mbp/172.18.102.3 
address=/last.pool.kad2.mbp/172.18.102.4 
EOF


sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping ldap.kad2.mbp
ping padl.kad2.mbp
```


```
cat >/tmp/kad2-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kad2
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5447
EOF

kind create cluster --config /tmp/kad2-config.yaml
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
--path=clusters/kind/m48/integrator/kad2/flux


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
