# Grafana + MySQL + phpMyAdmin

[Grafana](https://grafana.com/docs/grafana/latest/)

[MySQL](https://artifacthub.io/packages/helm/bitnami/mysql)

[phpMyAdmin](https://artifacthub.io/packages/helm/bitnami/phpmyadmin)

## 部署步骤

1. 创建命名空间

```shell
# 创建命名空间
kubectl create namespace homelab-dashboard
# 导出环境变量
export K8S_NS=homelab-dashboard
```

2. 安装

```shell
# MySQL password
kubectl apply -f mysql/password.yaml -n $K8S_NS
# MySQL
helm install -f mysql/values.yaml mysql bitnami/mysql -n $K8S_NS

# phpMyAdmin
helm install -f phpmyadmin/values.yaml phpmyadmin bitnami/phpmyadmin -n $K8S_NS

# Grafana
kubectl apply -f grafana/grafana.yaml -n $K8S_NS
```

3. 卸载

```shell
# Grafana
kubectl delete -f grafana/grafana.yaml -n $K8S_NS

# phpMyAdmin
helm uninstall phpmyadmin -n $K8S_NS

# MySQL
helm uninstall mysql -n $K8S_NS
# MySQL password
kubectl delete -f mysql/password.yaml -n $K8S_NS
```

4. 查看`Pod`状态

```shell
kubectl get all -n $K8S_NS
```

## 体验试用

- 配置`域名`到`IP`的解析映射(内容如下所示，注意换成自己的IP)
  - 配置到本地`hosts`文件
  - 安装`SwitchHosts!`软件进行配置和管理
  - 配置到路由`hosts`文件

```text
192.168.100.x phpmyadmin.homelab.com
192.168.100.x dashboard.homelab.com
```

敬请体验

- [phpmyadmin.homelab.com](http://phpmyadmin.homelab.com/)
- [dashboard.homelab.com](http://dashboard.homelab.com/)
