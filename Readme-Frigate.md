# Readme

## 1. 安装MQTT

### 1.1 **下载mqtt仓库**

helm repo add k8s-at-home https://k8s-at-home.com/charts
helm repo update
helm search repo k8s-at-home/mosquitto --versions

* **默认值安装**
helm install mqtt k8s-at-home/mosquitto \
  --version 4.8.2 \
  --namespace mqtt \
  --create-namespace \
  -f values.yaml

* **修改values.yaml**
helm upgrade mqtt k8s-at-home/mosquitto \
  --version 4.8.2 \
  --namespace mqtt \
  -f values.yaml \
  --set auth.username=mqttuser \
  --set auth.password=mqtt123 

* **mosquitto-values.yaml覆盖values.yaml**
helm upgrade mqtt ./mosquitto-4.8.2 \
  --install \
  --namespace mqtt \
  --create-namespace \
  -f ./mosquitto-4.8.2/mosquitto-values.yaml

### 1.2 **添加MQTT集成**

home-assistant 添加集成：MQTT

### 1.3 **测试**

* **方法一**
  sudo apt install -y mosquitto-clients
  kubectl port-forward -n mqtt svc/mqtt-mosquitto 1883:1883
  mosquitto_pub -h 127.0.0.1 -p 1883 -u mqttuser -P mqtt123 -t "homeassistant/sensor/frigate/camera_0/state" -m "on"
* **方法二**
  在Home Assistant中添加一个MQTT订阅器，订阅主题为：homeassistant/sensor/frigate/camera_0/state

## 2. 安装Frigate

### 2.1 **查找仓库**

helm search repo k8s-at-home/frigate --versions
NAME               	CHART VERSION	APP VERSION 	DESCRIPTION
k8s-at-home/frigate	8.2.2        	0.10.0-amd64	NVR With Realtime Object Detection for IP Cameras
k8s-at-home/frigate	8.2.1        	0.10.0-amd64	NVR With Realtime Object Detection for IP Cameras
k8s-at-home/frigate	8.2.0        	0.10.0-amd64	NVR With Realtime Object Detection for IP Cameras

### 2.2 **下载helm仓库**

helm pull  k8s-at-home/frigate --version 8.2.2  --destination . --untar


* **默认值安装**
helm install frigate frigate-8.2.2 \
  --version 8.2.2 \
  --namespace home-assistant \
  --create-namespace \
  -f frigate-8.2.2/values.yaml

* **覆盖values.yaml**
helm upgrade --install frigate-8.2.2 \
  --namespace home-assistant \
  --create-namespace \
  -f frigate-8.2.2/frigate-values.yaml

helm install frigate frigate-8.2.2 \
  --namespace home-assistant \
  --create-namespace \
  -f frigate-8.2.2/frigate-values.yaml

* **卸载frigate**
helm ls -A
helm uninstall frigate-8.2.2 -n home-assistant

* **改用manifest安装**
因为helm安装frigate时，PVC不能按配置设置创建，所以改用manifest安装
cd mainifest
kubectl apply -f frigate-complete.yaml

### 2.3 **PVC**
kubectl get storageclass local-path -o jsonpath='{.reclaimPolicy}'
# 输出：Delete
❌ 一旦你删除 PVC，底层数据将被立即删除！

### 2.4 **K3s NodePort**
K3s 默认使用 flannel + service-node-port-range=30000-32767，但默认禁用了 kube-proxy，改用内置的 servicelb 和 traefik 来处理服务暴露。

改成ClusterIP，并使用 Traefik 暴露服务：

kubectl port-forward -n frigate service/frigate 5000:5000