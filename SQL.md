# 数据看板查询SQL参考样例

## 数据看板

### 我的收入情况

来源：工资、奖金、补贴、分红、副业、利息、红包...

- 税后总收入

```sql
SELECT
  amount
FROM
  dashboard.salary
WHERE
  dtm BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  dtm ASC
```

- 稳定收入

作为普通打工人，主要是工资收入；其次，可能还有些副业收入。

```sql
SELECT
  dtm,
  amount AS '工资'
FROM
  dashboard.salary
WHERE
  category = '工资'
  AND dtm BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  dtm ASC
```

- 非稳定收入

年终奖/裁员赔偿/补贴/奖金/其他/

```sql
SELECT
  dtm,
  amount AS '年终奖'
FROM
  dashboard.salary
WHERE
  category = '年终奖'
  AND dtm BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  dtm ASC
```

### 我的支出情况

如果是以电子支付为主的年轻人，基本上关注支付宝、微信支付即可。

如果还存在现金等其他支出方式，请尽量以银行卡支出项为准。

- 总支出

即**某段时间内**支出总和

```sql
SELECT
  amount
FROM
  dashboard.transaction
WHERE
  income_or_expenditure = '支出'
  AND timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  timestamp ASC
```

- 月度支出

即**逐月**统计支出总额

```sql
SELECT
  DATE_FORMAT(timestamp, '%Y-%m') AS month,
  SUM(amount) AS '总支出'
FROM
  dashboard.transaction
WHERE
  income_or_expenditure = '支出'
  AND timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
GROUP BY
  DATE_FORMAT(timestamp, '%Y-%m')
ORDER BY
  month ASC
```

- 分层支出

即**某段时间内**落入各数值区间的订单数

```sql
SELECT
    CASE
        WHEN amount BETWEEN 0 AND 9.99 THEN '0-9'
        WHEN amount BETWEEN 10 AND 49.99 THEN '10-49'
        WHEN amount BETWEEN 50 AND 99.99 THEN '50-99'
        WHEN amount BETWEEN 100 AND 199.99 THEN '100-199'
        WHEN amount BETWEEN 200 AND 499.99 THEN '200-499'
        WHEN amount BETWEEN 500 AND 999.99 THEN '500-999'
        WHEN amount BETWEEN 1000 AND 2999.99 THEN '1000-2999'
        ELSE '3000+'
    END AS amount_range,
    COUNT(*) AS '总笔数'
FROM
    dashboard.transaction
WHERE
  income_or_expenditure = '支出'
  AND timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
GROUP BY
    amount_range
ORDER BY
    MIN(amount)
```

- 大额支出

即**某段时间内**支出金额大于 x 元的订单

```sql
SELECT
  timestamp AS '交易时间',
  category AS '订单分类',
  counterparty AS '商户名称',
  amount AS '实付金额'
FROM
  dashboard.transaction
WHERE
  income_or_expenditure = '支出'
  AND amount > 499.99
  AND timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  timestamp DESC
```

- 信用借还

即**某段时间内**信用卡还款情况

```sql
SELECT
  timestamp,
  counterparty AS '卡商',
  goods AS '还款类目',
  amount AS '实还本息'
FROM
  dashboard.transaction
WHERE
  category = '信用借还'
  AND counterparty = '广发银行'
  AND income_or_expenditure = '不计收支'
  AND timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  timestamp ASC
```

- 支出趋势

刨除收入、不记收支的情况，展示一条随时间变化的支出金额曲线

```sql
SELECT
  timestamp,
  amount AS '支出金额'
FROM
  dashboard.transaction
WHERE
  income_or_expenditure = '支出'
  AND timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  timestamp ASC
```

### 我的消费习惯

以下科目一定不适合所有人，建议优先选取自己高频的支出项分析。

#### 命苦吃快餐

- 总共吃了多少顿快餐

```sql
SELECT
  DATE_FORMAT(timestamp, '%Y-%m') AS month,
  COUNT(t.counterparty) AS '订单数'
FROM 
    dashboard.transaction t
JOIN 
    dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE 
    tt.tag LIKE '%快餐%'
    AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
GROUP BY
  DATE_FORMAT(t.timestamp, '%Y-%m')
ORDER BY
  month ASC
```

- 都在哪家吃 & 花了多少钱

```sql
SELECT
  t.timestamp AS '交易时间',
  t.category AS '订单分类',
  t.counterparty AS '商户名称',
  t.amount AS '消费金额'
FROM
  dashboard.transaction t
  JOIN dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE
  tt.tag LIKE '%快餐%'
  AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  t.timestamp DESC
```

- 快餐价位趋势（早/中/晚）

> 早餐: 5~10; 中餐: 11~15; 晚餐: 16~20; 夜宵: 21~23 + 0~4

```sql
SELECT
  t.timestamp AS '交易时间',
  t.category AS '订单分类',
  t.counterparty AS '商户名称',
  t.amount AS '早餐'
FROM
  dashboard.transaction t
  JOIN dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE
  tt.tag LIKE '%快餐%'
  AND HOUR(t.timestamp) BETWEEN 5 AND 10
  AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  t.timestamp DESC
```

#### 线上逛超市

- 总共花了多少钱

```sql
SELECT
  DATE_FORMAT(t.timestamp, '%Y-%m') AS month,
  SUM(t.amount) AS '总金额'
FROM
  dashboard.transaction t
  JOIN dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE
  tt.tag = '朴朴'
  AND tt.field = 'counterparty'
  AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
GROUP BY
  DATE_FORMAT(t.timestamp, '%Y-%m')
ORDER BY
  month ASC
```

- 都在哪家买 & 花了多少钱

```sql
SELECT
  t.timestamp AS '交易时间',
  t.category AS '订单分类',
  t.counterparty AS '商户名称',
  t.amount AS '消费金额'
FROM
  dashboard.transaction t
  JOIN dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE
  tt.tag = '朴朴'
  AND tt.field = 'counterparty'
  AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  t.timestamp DESC
```

#### 咖啡大师

- 买了多少杯咖啡(订单数)

```sql
SELECT
    COUNT(t.counterparty) AS '订单数'
FROM 
    dashboard.transaction t
JOIN 
    dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE 
    tt.tag LIKE '%咖啡%'
    AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
```

- 买了多少钱的咖啡

```sql
SELECT 
    SUM(t.amount) AS '总消费金额'
FROM 
    dashboard.transaction t
JOIN 
    dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE 
    tt.tag LIKE '%咖啡%'
    AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
```

- 贡献了多少钱给瑞幸

```sql
SELECT 
    SUM(t.amount) AS '总消费金额'
FROM 
    dashboard.transaction t
JOIN 
    dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE 
    tt.tag = '瑞幸咖啡'
    AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
```

#### 生活缴费

- 水费（月支出）

```sql
SELECT
    DATE_FORMAT(t.timestamp, '%Y-%m') AS '年-月',
    SUM(t.amount) AS '月支出'
FROM
    dashboard.transaction t
JOIN
    dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE
    tt.tag = '水费'
    AND tt.field = 'counterparty'
    AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
GROUP BY
    DATE_FORMAT(t.timestamp, '%Y-%m')
ORDER BY
    DATE_FORMAT(t.timestamp, '%Y-%m')
```

- 水费（缴费记录）

```sql
SELECT
    t.timestamp AS '缴费时间',
    t.counterparty AS '缴费机构',
    t.amount AS '金额'
FROM
    dashboard.transaction t
JOIN
    dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE
    tt.tag = '水费'
    AND tt.field = 'counterparty'
    AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  t.timestamp DESC
```

#### 租房费用

```sql
SELECT
  t.timestamp AS '交易时间',
  t.category AS '订单分类',
  t.counterparty AS '机构名称',
  t.amount AS '支付金额'
FROM
  dashboard.transaction t
  JOIN dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE
  tt.tag = '租房'
  AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  t.timestamp DESC
```

#### 请客吃饭

#### 形象管理

- 买衣服鞋子

#### 学习充电

- 折腾花钱

#### 红包

- 红包的收发
- 不记收支（都是些什么情况）

#### 新房装修

```sql
SELECT
  t.timestamp AS '交易时间',
  t.category AS '订单分类',
  t.counterparty AS '商户名称',
  t.amount AS '支付金额'
FROM
  dashboard.transaction t
  JOIN dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE
  tt.tag = '装修'
  AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  t.timestamp DESC
```

#### 房贷还款

每月还款的本金、利息等情况

- 已还本息总额

```sql
SELECT
  SUM(actual_principal_interest) AS '已还本息总额'
FROM
  dashboard.loan
```

- 提前还款记录

```sql
SELECT
  actual_interest_payment_date AS '实际还款时间',
  actual_principal AS '实还本金',
  actual_interest AS '实还利息'
FROM
  dashboard.loan
WHERE
  period > 1000
ORDER BY
  actual_interest_payment_date DESC
```

- 实还本金&利息

```sql
SELECT
  actual_interest_payment_date AS '实际还款时间',
  actual_principal AS '实还本金',
  actual_interest AS '实还利息'
FROM
  dashboard.loan
WHERE
  actual_principal_interest < 20000
ORDER BY
  actual_interest_payment_date ASC
```

#### 医疗健康

```sql
SELECT
  timestamp AS '发生时间',
  counterparty AS '机构名称',
  amount AS '支出费用'
FROM
  dashboard.transaction
WHERE
  category = '医疗健康'
  AND timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
ORDER BY
  timestamp DESC
```

## 辅助能力

- 联表查询最近一年的交易记录中未被标记的情况

```sql
SELECT
  t.counterparty,
  COUNT(t.counterparty) AS counts
FROM
  dashboard.transaction t
  JOIN dashboard.transaction_tag tt ON t.counterparty = tt.value
WHERE
  tt.field = 'counterparty'
  AND tt.tag = '暂未标记'
  AND t.timestamp BETWEEN FROM_UNIXTIME($__unixEpochFrom()) AND FROM_UNIXTIME($__unixEpochTo())
GROUP BY
  t.counterparty
ORDER BY
  counts, t.timestamp DESC
```
