# HomeLab Dashboard

My HomeLab/Dashboard

## 架构图

数据库 MySQL

数据看板 Grafana

## 数据看板

## 命令行

命令样例

```shell
python ./scripts/xxx.py --host localhost --port 3306 --username <username> --password <password> --database dashboard --type xxx
```

- 导入工具

```shell
python ./scripts/synchronizer.py --path data --type Alipay
python ./scripts/synchronizer.py --path data --type WeChatPay
python ./scripts/synchronizer.py --path data --type Salary
python ./scripts/synchronizer.py --path data --type HousingLoan
```

- 分析工具

```shell
python ./scripts/analyzer.py --type Frequency
python ./scripts/analyzer.py --type PreMark
```
