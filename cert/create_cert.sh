
#!/bin/bash
# 生成测试证书
# openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
#    -subj "/CN=*.misumi.com.cn/O=misumi" \
#    -keyout misumi.key -out misumi.crt

openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=*.home.local/O=home" \
  -addext "subjectAltName=DNS:*.home.local,DNS:home.local,IP:10.178.0.4,IP:10.178.0.6" \
  -addext "keyUsage=digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth"

# 创建 Kubernetes Secret
kubectl create -n home-assistant secret tls home-tls-secret \
  --key=tls.key \
  --cert=tls.crt

