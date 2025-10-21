# Readme

## 1. 安装容器工具
### 1.1 安装Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

### 1.2 安装nerdctl
wget https://github.com/containerd/nerdctl/releases/download/v1.7.4/nerdctl-full-1.7.4-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local nerdctl-full-1.7.4-linux-amd64.tar.gz