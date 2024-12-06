# KUBO4

## Versions:

Flux: 2.4.0
Kad: 0.3.0-snapshot
kind: 0.24.0

## Network setting

Create a 'kind' network to allow fixed IP
> This is not required for our single node cluster. But will be compatible with multi-nodes

```
docker network rm kind # If kind was already used.
docker network create -d=bridge -o com.docker.network.bridge.enable_ip_masquerade=true -o com.docker.network.driver.mtu=65535  --subnet 172.18.0.0/16 kind

docker network inspect kind
```


## kubo4 cluster


```
cat >$(brew --prefix)/etc/dnsmasq.d/kubo4 <<EOF
address=/first.pool.kubo4.mbp/172.18.130.1 
address=/.ingress.kubo4.mbp/172.18.130.1 
address=/padl.kubo4.mbp/172.18.130.2 
address=/ldap.kubo4.mbp/172.18.130.3 
address=/last.pool.kubo4.mbp/172.18.130.4 
EOF


sudo brew services restart dnsmasq

sudo killall -HUP mDNSResponder

ping ldap.kubo4.mbp
ping padl.kubo4.mbp
```


```
cat >/tmp/kubo4-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kubo4
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 5445
EOF

kind create cluster --config /tmp/kubo4-config.yaml

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
--path=clusters/kind/mbp64/kubo4/flux

flux bootstrap github \
--owner=${GITHUB_USER} \
--repository=${GITHUB_REPO} \
--branch=${GIT_BRANCH} \
--interval 15s \
--owner kubotal \
--token-auth \
--path=clusters/kind/mbp64/kubo4/flux

```


cleanup

```
docker stop $(docker ps -a -q)
docker container prune --force
docker volume prune --all --force
docker network prune --force
docker image prune --all --force



```
