# ReadMe

## 1.安装K3s

### **1.1 使用国内镜像源安装 K3s**

```bash
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn |sh -
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | sh -

```
### **1.2 安装完成 **
```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config

kubectl version
Client Version: v1.33.5+k3s1
Kustomize Version: v5.6.0
Server Version: v1.33.5+k3s1

$ kubectl get pod -A
NAMESPACE     NAME                                      READY   STATUS      RESTARTS   AGE
kube-system   coredns-64fd4b4794-8f25l                  1/1     Running     0          19m
kube-system   helm-install-traefik-bcpqg                0/1     Completed   2          19m
kube-system   helm-install-traefik-crd-x477b            0/1     Completed   0          19m
kube-system   local-path-provisioner-774c6665dc-772c2   1/1     Running     0          19m
kube-system   metrics-server-7bfffcd44-n59r9            1/1     Running     0          19m
kube-system   svclb-traefik-e55e4718-2nblp              2/2     Running     0          18m
kube-system   traefik-c98fdf6fb-r24q4                   1/1     Running     0          18m

两个Completed Job 是用于安装traefik和crd用的：
$ sudo ls /var/lib/rancher/k3s/server/manifests/
ccm.yaml  coredns.yaml	local-storage.yaml  metrics-server  rolebindings.yaml  runtimes.yaml  traefik.yaml

默认安装了一个LoadBalancer：
$ kubectl get svc -n kube-system 
NAME             TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
kube-dns         ClusterIP      10.43.0.10      <none>        53/UDP,53/TCP,9153/TCP       25m
metrics-server   ClusterIP      10.43.177.113   <none>        443/TCP                      25m
traefik          LoadBalancer   10.43.254.230   10.178.0.4    80:30999/TCP,443:32356/TCP   25m

kubectl get ingress --all-namespaces
如果输出为空，说明还没有任何业务绑定到 Traefik。

```

## 2.K3s 容器引擎 containerd

### 2.1 镜像管理工具

sudo crictl ps

也可以使用 nerdctl，风格几乎与docker一样：
wget https://github.com/containerd/nerdctl/releases/download/v1.7.6/nerdctl-full-1.7.6-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local nerdctl-full-1.7.6-linux-amd64.tar.gz

### 2.2 镜像加速

sudo tee /etc/systemd/system/k3s.service.env <<EOF
K3S_REGISTRY_CONFIG='{
  "mirrors": {
    "docker.io": {
      "endpoint": ["https://l8hcmqn7.mirror.aliyuncs.com", "https://registry-1.docker.io"]
    }
  }
}'
EOF

### 2.3 重启k3s
sudo systemctl restart k3s 

```bash
sudo tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/k3s/containerd/containerd.sock
image-endpoint: unix:///run/k3s/containerd/containerd.sock
timeout: 10
debug: false
EOF
```

## 3. 多节点K3s 集群
(略)

## 4. 安装Home Assistant
### 4.1 下载Home Assistant helm chart

**安装 Helm 3（以 Linux x86_64 为例）**
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
**下载helm仓库到本地）**
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo update
helm repo ls 
helm search repo k8s-at-home/home-assistant
helm pull k8s-at-home/home-assistant
tar -zxvf home-assistant-13.4.2.tgz
cd home-assistant
cat values.yaml
cat Chart.yaml
helm show values k8s-at-home/home-assistant > values.yaml

### 4.2 **安装 Home Assistant**
```bash
## 复制 K3s 配置到当前用户的 .kube 目录
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config  # 关键：设置正确权限，否则可能被拒绝访问

## 简易安装
sudo kubectl create namespace home-assistant
helm install  home-assistant ./home-assistant-13.4.2/ --namespace home-assistant  --create-namespace -f ./home-assistant-13.4.2/ values.yaml
helm ls -n home-assistant

## PVC绑定安装
helm install home-assistant k8s-at-home/home-assistant \
  --set persistence.config.enabled=true \
  --set persistence.config.size=10Gi \
  --set persistence.config.accessMode=ReadWriteOnce \
  --set persistence.config.storageClass=local-path \
  --set volumeMounts.config.mountPath=/config \
  --namespace home-assistant --create-namespace

## 查看PVC
$ kubectl get pvc -A
NAMESPACE        NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
home-assistant   home-assistant-config   Bound    pvc-aa2d8143-17f3-420e-923b-1eb73f2f54d3   10Gi       RWO            local-path     <unset>                 31m

sudo ls /var/lib/rancher/k3s/storage/
pvc-aa2d8143-17f3-420e-923b-1eb73f2f54d3_home-assistant_home-assistant-config

$ sudo ls /var/lib/rancher/k3s/storage/pvc-aa2d8143-17f3-420e-923b-1eb73f2f54d3_home-assistant_home-assistant-config/
automations.yaml  configuration.yaml  home-assistant.log    home-assistant.log.fault  home-assistant_v2.db-shm	scenes.yaml   secrets.yaml
blueprints	  deps		      home-assistant.log.1  home-assistant_v2.db      home-assistant_v2.db-wal	scripts.yaml  tts
```
### 4.3 **404 错误解决**
```bash
curl http://home.local
400: Bad Request
curl -H "Host: home.local" http://home.local

PODID=$(kubectl get pod -n home-assistant -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $PODID -n home-assistant -- sh
cp /config/configuration.yaml /config/configuration.yaml.bak

cat /config/configuration.yaml

**使用 cat + EOF 覆盖写入新内容**
cat > /config/configuration.yaml << 'EOF'
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.42.0.0/16
    - 10.178.0.0/24
    - 127.0.0.1

# Loads default set of integrations. Do not remove.
default_config:

# Text to speech
tts:
  - platform: google_translate

automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml
EOF

**不想覆盖，只想添加 http 块，可以使用 >> 追加：**
kubectl exec -n home-assistant home-assistant-5dcdfcdfbb-7vrlq -- sh -c "
cat >> /config/configuration.yaml << 'EOF'

http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.42.0.0/16
    - 10.178.0.0/24
    - 127.0.0.1
EOF
"
**重启pod**
kubectl rollout restart deployment/home-assistant -n home-assistant
```

### 4.4 **备份配置文件**
kubectl cp $PODID:/config ./backup -n home-assistant

```

export CONTAINERD_ADDRESS="/run/k3s/containerd/containerd.sock"
