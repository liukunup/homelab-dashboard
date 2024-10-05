# 个人消费数据分析

## 账单分析维度

- 宏观

  - 收入
  - 支出
  - 其他(投资、借贷等)

- 微观

  - 支出分类
    - 衣
    - 食
    - 住
    - 行
  - 支出排行
  - 支出对比

## 效果截图

## 使用说明

```mysql-sql
SELECT
    TRIM(`goods`) AS word,
    COUNT(*) AS cnt
FROM `transaction`
GROUP BY word
ORDER BY cnt DESC
```

### 导出微信账单

### 导出支付宝账单

