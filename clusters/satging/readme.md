install native kubernates trubles

---

postmarketOS ARM64, systemd
Docker установлен и работает (docker ps)
Swap (zram) активен и не отключается
root-доступ

```sh
sudo apk add --no-cache \
    containerd \
    runc \
    iptables \
    ebtables \
    ethtool \
    socat \
    conntrack-tools \
    util-linux \
    bash \
    curl

```

undo

```sh
sudo apk del containerd runc iptables ebtables ethtool socat conntrack-tools util-linux bash curl
```

---

```sh
sudo tee /etc/systemd/system/containerd.service <<'EOF'
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStart=/usr/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStart=/usr/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
> sudo systemctl daemon-reload
sudo systemctl enable --now containerd
systemctl status containerd
```

```sh
sudo  nano  /etc/containerd/config.toml
```

```sh
[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.runc.options]
SystemdCgroup = true
```

```sh
sudo systemctl restart containerd
systemctl status containerd
```

undo

```sh
sudo systemctl disable --now containerd
sudo mv /etc/containerd/config.toml /etc/containerd/config.backup
```

## Установка kubeadm, kubelet, kubectl

```sh
sudo apk add --no-cache kubeadm kubelet kubectl
```

undo

```sh
sudo apk del kubeadm kubelet kubectl
```

## Настройка kubelet с активным swap (zram)

```sh
sudo mkdir -p /etc/systemd/system/kubelet.service.d
sudo tee /etc/systemd/system/kubelet.service.d/10-ignore-swap.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"
EOF

sudo systemctl daemon-reexec
sudo systemctl restart kubelet
```

undo

```sh
sudo rm -f /etc/systemd/system/kubelet.service.d/10-ignore-swap.conf
sudo systemctl daemon-reexec
sudo systemctl restart kubelet
```

```sh
sudo systemctl enable --now kubelet
```

## Скачивание образа

напрямую не доступен так что качать через зеркало

```sh
sudo kubeadm config images pull \
    --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```

или на постоянку

```sh
export KUBEADM_IMAGE_REPOSITORY=registry.cn-hangzhou.aliyuncs.com/google_containers
```

## Инициализация кластера

-   если ранее запускался kubeadmin, то перед запуском нужно удалить старый конфиг

```sh
sudo kubeadm reset -f                                                                                                                                   with achi@chiz at 20:17:28
sudo systemctl restart kubelet

sudo rm /etc/kubernetes/admin.conf
sudo rm /etc/kubernetes/kubelet.conf
sudo rm /etc/kubernetes/super-admin.conf
sudo rm /etc/kubernetes/controller-manager.conf
sudo rm /etc/kubernetes/scheduler.conf
sudo rm  /etc/kubernetes/manifests/kube-apiserver.yaml
sudo rm /etc/kubernetes/manifests/kube-controller-manager.yaml
sudo rm /etc/kubernetes/manifests/kube-scheduler.yaml
sudo rm /etc/kubernetes/manifests/etcd.yaml
```

sudo apk add containerd-ctr

```sh
sudo ctr image pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.10
```

```sh
sudo mkdir -p /etc/cni/net.d

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

```

```sh
wget https://github.com/containernetworking/plugins/releases/download/v1.8.0/cni-plugins-linux-arm64-v1.8.0.tgz -P /tmp
sudo mkdir -p /usr/libexec/cni
sudo tar -xzvf /tmp/cni-plugins-linux-arm64-v1.8.0.tgz -C /usr/libexec/cni
sudo systemctl restart kubelet
```

```sh
sudo systemctl restart containerd
sudo systemctl restart kubelet
sudo journalctl -u kubelet -f
```

```sh
sudo nano /etc/crictl.yaml
```

```sh
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
```

```sh
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=Swap --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers

#или для пеерносновго

 sudo kubeadm init \
  --apiserver-advertise-address=0.0.0.0 \
  --apiserver-cert-extra-sans=127.0.0.1,localhost \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --ignore-preflight-errors=Swap \
  --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \
  --control-plane-endpoint=127.0.0.1
```

```sh

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.195.215.51:6443 --token hnjblz.flfx7lxarkamu9bm \
	--discovery-token-ca-cert-hash sha256:edde0e30633bd0a5b71036f8179d3c1e51e78b3c58d11ed1bfdaf1fe9dda529e
```

```sh
sudo mkdir -p /usr/libexec/cni
sudo ln -s /opt/cni/bin/* /usr/libexec/cni/

sudo systemctl restart kubelet
kubectl delete pod -n kube-system -l k8s-app=kube-dns
kubectl get pods -n kube-system -w



# 1. Создаём директорию и файл с фиксированными DNS-серверами
sudo mkdir -p /etc/kubernetes
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | sudo tee /etc/kubernetes/resolv.conf

# 2. Создаём или редактируем файл настроек kubelet для systemd
sudo mkdir -p /etc/default
echo 'KUBELET_EXTRA_ARGS="--resolv-conf=/etc/kubernetes/resolv.conf"' | sudo tee /etc/default/kubelet

# 3. Перезагружаем systemd и kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 4. Проверяем, что kubelet запущен
systemctl status kubelet

```

```sh
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo ip6tables-save | sudo tee /etc/iptables/rules.v6
```

/etc/systemd/system/iptables-kuber.service

```sh
[Unit]
Description=Restore iptables rules
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/iptables-restore /etc/iptables/rules.v4
ExecStartPost=/usr/sbin/ip6tables-restore /etc/iptables/rules.v6
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

```sh
# запрет изменения resolvconf
sudo chattr +i /etc/resolv.conf
```

чтобы запустились dns нужно копировать бинарники cni плагинов
cp: '/opt/cni/bin/LICENSE' and '/usr/libexec/cni/LICENSE' are the same file
cp: '/opt/cni/bin/README.md' and '/usr/libexec/cni/README.md' are the same file
cp: '/opt/cni/bin/bandwidth' and '/usr/libexec/cni/bandwidth' are the same file
cp: '/opt/cni/bin/bridge' and '/usr/libexec/cni/bridge' are the same file
cp: '/opt/cni/bin/calico' and '/usr/libexec/cni/calico' are the same file
cp: '/opt/cni/bin/calico-ipam' and '/usr/libexec/cni/calico-ipam' are the same file
cp: '/opt/cni/bin/dhcp' and '/usr/libexec/cni/dhcp' are the same file
cp: '/opt/cni/bin/dummy' and '/usr/libexec/cni/dummy' are the same file
cp: '/opt/cni/bin/firewall' and '/usr/libexec/cni/firewall' are the same file
cp: '/opt/cni/bin/flannel' and '/usr/libexec/cni/flannel' are the same file
cp: '/opt/cni/bin/host-device' and '/usr/libexec/cni/host-device' are the same file
cp: '/opt/cni/bin/host-local' and '/usr/libexec/cni/host-local' are the same file
cp: '/opt/cni/bin/install' and '/usr/libexec/cni/install' are the same file
cp: '/opt/cni/bin/ipvlan' and '/usr/libexec/cni/ipvlan' are the same file
cp: '/opt/cni/bin/loopback' and '/usr/libexec/cni/loopback' are the same file
cp: '/opt/cni/bin/macvlan' and '/usr/libexec/cni/macvlan' are the same file
cp: '/opt/cni/bin/portmap' and '/usr/libexec/cni/portmap' are the same file
cp: '/opt/cni/bin/ptp' and '/usr/libexec/cni/ptp' are the same file
cp: '/opt/cni/bin/sbr' and '/usr/libexec/cni/sbr' are the same file
cp: '/opt/cni/bin/static' and '/usr/libexec/cni/static' are the same file
cp: '/opt/cni/bin/tap' and '/usr/libexec/cni/tap' are the same file
cp: '/opt/cni/bin/tuning' and '/usr/libexec/cni/tuning' are the same file
cp: '/opt/cni/bin/vlan' and '/usr/libexec/cni/vlan' are the same file
cp: '/opt/cni/bin/vrf' and '/usr/libexec/cni/vrf' are the same file

> sudo chmod 644 /etc/cni/net.d/\*.conf

# Новая установка

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

#------------------------------

 kubectl get pods -n kube-system

NAME                                   READY   STATUS    RESTARTS   AGE
coredns-7ddb67b59b-7jzdf               1/1     Running   0          6m59s
coredns-7ddb67b59b-ft49g               1/1     Running   0          6m59s
etcd-chiz.work.gd                      1/1     Running   0          7m2s
kube-apiserver-chiz.work.gd            1/1     Running   0          7m2s
kube-controller-manager-chiz.work.gd   1/1     Running   0          7m6s
kube-proxy-l68v9                       1/1     Running   0          7m
kube-scheduler-chiz.work.gd            1/1     Running   0          7m5s

kubectl run test-ping -it --image=busybox:1.36 --restart=Never -- /bin/sh
ping 8.8.8.8
ping 10.244.0.3
```

#------------------------------------------------

```sh
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

```sh
# Настройка приватного Docker Registry для всех нод
# Файл: /etc/containerd/config.toml на каждой ноде
# Добавляем туда:
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."reg.chiz.work.gd:5000"]
  endpoint = ["http://reg.chiz.work.gd:5000"]
[plugins."io.containerd.grpc.v1.cri".registry.configs."reg.chiz.work.gd:5000".auth]
  username = "achi"
  password = "123"
```

```sh
sudo systemctl restart containerd
```
можно тянуть образы чрез->> image: reg.chiz.work.gd/myapp:latest
