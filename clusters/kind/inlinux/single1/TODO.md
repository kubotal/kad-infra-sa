
```

apt-get update
apt-get upgrade
```

```
apt-get install docker.io
usermod -a -G docker sa
```

```
cd /tmp
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

sudo snap install kubectl --classic
```


```
export MY_PUBLIC_IP=192.168.56.101


cat >/tmp/single1-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: single1
networking:
  apiServerAddress: "${MY_PUBLIC_IP}"
  apiServerPort: 6443
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
    listenAddress: "0.0.0.0"
  - containerPort: 443
    hostPort: 443
    protocol: TCP
    listenAddress: "0.0.0.0"
EOF

kind create cluster --config /tmp/single1-config.yaml

```



6  kind
7  kind create cluster
8  kubectl cluster-info --context kind-kind
9  snap install kubectl
10  sudo snap install kubectl
11  sudo snap install kubectl --clessic
13  kubectl get pods -A
14  docker ps
15  history
