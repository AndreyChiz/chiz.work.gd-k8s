install native kubernates trubles

----

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
----

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


* если ранее запускался kubeadmin, то перед запуском нужно удалить старый конфиг
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
sudo kubeadm init \
  --apiserver-advertise-address=0.0.0.0 \
  --apiserver-cert-extra-sans=127.0.0.1,localhost \
  --pod-network-cidr=10.244.0.0/16 \
  --ignore-preflight-errors=Swap \
  --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers

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