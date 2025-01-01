# 使用说明

## 命令行

```shell
python ./scripts/synchronizer.py --host localhost --port 3306 --username <username> --password <password> --database dashboard --path data --type Alipay
python ./scripts/synchronizer.py --host localhost --port 3306 --username <username> --password <password> --database dashboard --path data --type WeChatPay
python ./scripts/synchronizer.py --host localhost --port 3306 --username <username> --password <password> --database dashboard --path data --type Salary
python ./scripts/synchronizer.py --host localhost --port 3306 --username <username> --password <password> --database dashboard --path data --type HousingLoan
```

```shell
python ./scripts/analyzer.py --host localhost --port 3306 --username <username> --password <password> --database dashboard --type Frequency
```