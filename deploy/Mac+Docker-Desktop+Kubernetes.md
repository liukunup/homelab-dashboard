# 下载&安装 Docker Desktop

[Download Docker Desktop | Docker](https://www.docker.com/products/docker-desktop/)

## 启动 Kubernetes

备注：国内网络环境，可能拉取镜像时会被拦截，考虑使用替代来源的镜像。

![截屏2023-07-25 18.02.34.png](https://cdn.nlark.com/yuque/0/2023/png/2576395/1690279437473-4a0caaff-cf18-4a2e-8d2f-8f8ae781891b.png#averageHue=%23eceff5&clientId=u8c6d8f20-2d78-4&from=ui&id=u1bbb9b5f&originHeight=1580&originWidth=2778&originalType=binary&ratio=1&rotation=0&showTitle=false&size=317818&status=done&style=none&taskId=u64c5c400-f9c1-47bc-925c-3c0cac49b14&title=)

## 部署 Ingress

```shell
# 更新 Repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# 安装 Ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# 更新 Ingress (设置为默认的Ingress控制器)
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
  --set controller.ingressClassResource.default=true

# 这样更快～
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# 卸载 Ingress
helm uninstall ingress-nginx
```
