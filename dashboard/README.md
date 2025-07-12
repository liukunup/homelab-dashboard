# 使用说明

## 命令行

命令样例

```shell
python ./scripts/xxx.py --host localhost --port 3306 --username <username> --password <password> --database dashboard --type xxx
```

- 导入工具

```shell
python ./scripts/synchronizer.py --database dashboard --path data --type Alipay
python ./scripts/synchronizer.py --database dashboard --path data --type WeChatPay
python ./scripts/synchronizer.py --database dashboard --path data --type Salary
python ./scripts/synchronizer.py --database dashboard --path data --type HousingLoan
```

- 分析工具

```shell
python ./scripts/analyzer.py --database dashboard --type Frequency
python ./scripts/analyzer.py --database dashboard --type PreMark
```
