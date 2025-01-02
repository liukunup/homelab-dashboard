-- --------------------------------------------------------

--
-- 数据库 `dashboard` 存储待Grafana展示的数据
--

CREATE DATABASE IF NOT EXISTS `dashboard`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

ALTER DATABASE `dashboard`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- 表 `transaction` 存储电子对账单(支付宝/微信支付)
--

CREATE TABLE `transaction` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
  `timestamp` datetime NOT NULL COMMENT '交易时间',
  `category` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '交易类型',
  `counterparty` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '交易对方',
  `account` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '对方账号',
  `goods` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '商品',
  `income_or_expenditure` enum('收入','支出','不计收支','/') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '收/支',
  `amount` double NOT NULL COMMENT '金额',
  `channel` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '收/付款方式',
  `status` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '交易状态',
  `po_transaction` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '交易订单号',
  `po_seller` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '商家订单号',
  `comments` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '备注',
  `source` tinyint(3) UNSIGNED NOT NULL DEFAULT '000' COMMENT '记录来源(0-手工,1-支付宝,2-微信)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='电子对账单';

ALTER TABLE `transaction` ADD UNIQUE(`po_transaction`);

-- --------------------------------------------------------

--
-- 表 `transaction_tag` 存储交易标签
--

CREATE TABLE `transaction_tag` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
  `field` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '字段名',
  `value` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '字段值',
  `counts` int(11) unsigned NOT NULL COMMENT '出现频次',
  `tag` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '暂未标记' COMMENT '字段值',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标签表';

ALTER TABLE `transaction_tag` ADD UNIQUE(`field`, `value`);

-- --------------------------------------------------------

--
-- 表 `salary` 存储薪酬福利
--

CREATE TABLE `salary` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
  `dtm` date NOT NULL COMMENT '年月日',
  `company` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '公司',
  `amount` double NOT NULL COMMENT '金额',
  `category` enum('工资','年终奖','裁员赔偿','补贴','奖金','其他') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '类别',
  `comments` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '备注',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='薪酬福利';

ALTER TABLE `salary` ADD UNIQUE(`dtm`, `company`, `amount`);

-- --------------------------------------------------------

--
-- 表 `loan` 存储房贷还款
--

CREATE TABLE `loan` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
  `period` int NOT NULL COMMENT '第N期',
  `organization` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '服务机构名称',
  `current_interest_rate` double NOT NULL COMMENT '当前年利率(%)',
  `lpr_spread` double NOT NULL COMMENT '加点幅度(%)',
  `actual_principal_interest` double NOT NULL COMMENT '实还本息',
  `due_principal_interest` double NOT NULL COMMENT '应还本息',
  `actual_principal` double NOT NULL COMMENT '实还本金',
  `actual_interest` double NOT NULL COMMENT '实还利息',
  `repayment_date` date NOT NULL COMMENT '还款日期',
  `actual_interest_payment_date` date NOT NULL COMMENT '实际还息日期',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='薪酬福利';

ALTER TABLE `loan` ADD UNIQUE(`period`, `organization`);

-- --------------------------------------------------------
