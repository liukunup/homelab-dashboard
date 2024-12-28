-- --------------------------------------------------------

--
-- 数据库 `dashboard`
--

CREATE DATABASE IF NOT EXISTS `dashboard`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

ALTER DATABASE `dashboard`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- 表的结构 `transaction`
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
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='电子对账单';

-- --------------------------------------------------------

--
-- 表的结构 `transaction_tag`
--

CREATE TABLE `transaction_tag` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
  `field` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '字段名',
  `value` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '字段值',
  `counts` int(11) unsigned NOT NULL COMMENT '出现频次',
  `tag` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '暂未标记' COMMENT '字段值',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='标签表';

-- --------------------------------------------------------

--
-- 交易订单号 确保记录唯一
--

ALTER TABLE `transaction` ADD UNIQUE(`po_transaction`);
ALTER TABLE `transaction_tag` ADD UNIQUE(`field`, `value`);
