## Развертывание

### Базовая установка

```sh
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

sudo modprobe overlay
sudo modprobe br_netfilter

echo -e "net.bridge.bridge-nf-call-iptables = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl --system

sudo sysctl -p /etc/sysctl.d/k8s.conf

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubeadm"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubelet"

chmod +x kubeadm kubectl kubelet
sudo mv kubeadm kubectl kubelet /usr/local/bin/

kubeadm version
kubectl version --client
kubelet --version



sudo systemctl start containerd
sudo systemctl enable containerd

kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=Swap --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers

 mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  sudo nano /etc/crictl.yaml
  ----------------------------------------------------------------------------
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false

-----------------------------------------------------------------------------

sudo tee /etc/cni/net.d/10-bridge.conf > /dev/null <<EOF
{
  "cniVersion": "0.4.0",
  "name": "bridge",
  "type": "bridge",
  "bridge": "cni0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.244.0.0/16",
    "routes": [
      { "dst": "0.0.0.0/0" }
    ]
  }
}
EOF


wget https://github.com/containernetworking/plugins/releases/download/v1.8.0/cni-plugins-linux-arm64-v1.8.0.tgz -P /tmp
sudo mkdir -p /usr/libexec/cni
sudo tar -xzvf /tmp/cni-plugins-linux-arm64-v1.8.0.tgz -C /usr/libexec/cni
sudo systemctl restart kubelet

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-
```
#### Установка плагинов

- Flanel

```sh
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

- Docker Registry
```sh
# /etc/containerd/config.toml на каждой ноде
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."reg.chiz.work.gd:5000"]
  endpoint = ["http://reg.chiz.work.gd:5000"]
[plugins."io.containerd.grpc.v1.cri".registry.configs."reg.chiz.work.gd:5000".auth]
  username = "achi"
  password = "123"
```

```sh
sudo systemctl restart containerd
```


### Тестирование

#### Тест состояния кластера
```sh
 kubectl get pods -n kube-system
```

>>>
```sh
NAME                                   READY   STATUS    RESTARTS   AGE
coredns-7ddb67b59b-7jzdf               1/1     Running   0          6m59s
coredns-7ddb67b59b-ft49g               1/1     Running   0          6m59s
etcd-chiz.work.gd                      1/1     Running   0          7m2s
kube-apiserver-chiz.work.gd            1/1     Running   0          7m2s
kube-controller-manager-chiz.work.gd   1/1     Running   0          7m6s
kube-proxy-l68v9                       1/1     Running   0          7m
kube-scheduler-chiz.work.gd            1/1     Running   0          7m5s
```

#### Тест сети

Создание тестового контейнера
```sh
kubectl run test-ping -it --image=busybox:1.36 --restart=Never -- /bin/sh
```
Внутри контейнера
```sh
ping 8.8.8.8
ping 10.244.0.3
```
