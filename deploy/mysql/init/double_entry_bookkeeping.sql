-- --------------------------------------------------------

--
-- 数据库 `dashboard` 存储用于 Grafana 展示的数据
--

CREATE DATABASE IF NOT EXISTS `dashboard`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

ALTER DATABASE `dashboard`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- 会计科目表（复式记账法）
--

CREATE TABLE `dek_account` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `account_code` VARCHAR(32) NOT NULL COMMENT '科目编码',
    `account_name` VARCHAR(256) NOT NULL COMMENT '科目名称',
    `account_type` ENUM('资产', '负债', '权益', '收入', '费用') NOT NULL COMMENT '科目类型',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY uq_account_code (`account_code`),
    UNIQUE KEY uq_account_name (`account_name`),
    INDEX idx_account_type (`account_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会计科目表';

-- --------------------------------------------------------

--
-- 交易主表
--

CREATE TABLE `dek_transaction` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `transaction_at` DATETIME NOT NULL COMMENT '交易时间',
    `description` TEXT NOT NULL COMMENT '交易描述',
    `source` ENUM('支付宝', '微信', '手工') NOT NULL COMMENT '交易来源',
    `status` ENUM('草稿', '已记账', '已审核') NOT NULL DEFAULT '草稿' COMMENT '交易状态',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    INDEX idx_status (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易主表';

-- --------------------------------------------------------

--
-- 交易分录表
--

CREATE TABLE `dek_transaction_entry` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `transaction_id` BIGINT UNSIGNED NOT NULL COMMENT '所属交易ID',
    `account_id` BIGINT UNSIGNED NOT NULL COMMENT '关联科目ID',
    `amount` DECIMAL(15,2) NOT NULL CHECK (amount > 0) COMMENT '金额（正数）',
    `flag` ENUM('Debit', 'Credit') NOT NULL COMMENT '借贷标志',
    `desc` VARCHAR(255) COMMENT '分录描述',
    `source_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '来源原始记录ID',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    FOREIGN KEY (`transaction_id`) REFERENCES `dek_transaction`(`id`) ON DELETE CASCADE,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易分录表';

-- --------------------------------------------------------

--
-- 映射规则表
--

CREATE TABLE `dek_mapping_rule` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `platform` ENUM('支付宝', '微信支付', '手工录入', '不限') NOT NULL COMMENT '适用平台',
    `pattern` VARCHAR(255) NOT NULL COMMENT '匹配模式（支持%通配符）',
    `debit_account_id` BIGINT UNSIGNED NOT NULL COMMENT '借方科目ID',
    `credit_account_id` BIGINT UNSIGNED NOT NULL COMMENT '贷方科目ID',
    `template` VARCHAR(255) DEFAULT '{goods} - {counterpart}' COMMENT '描述模板',
    `priority` INT NOT NULL DEFAULT 0 COMMENT '优先级（数值越大优先级越高）',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='映射规则表';

-- --------------------------------------------------------

--
-- 原始交易记录（包括支付宝、微信支付等）
--

CREATE TABLE `dek_online_transaction` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
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
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='原始交易记录表';

-- --------------------------------------------------------

--
-- 原始交易统计表
--

CREATE TABLE `dek_online_transaction_statistics` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `key` VARCHAR(256) NOT NULL COMMENT '键',
    `value` VARCHAR(256) NOT NULL COMMENT '值',
    `value_count` BIGINT UNSIGNED NOT NULL COMMENT '值的次数',
    `category` VARCHAR(256) NOT NULL DEFAULT '暂未标记' COMMENT '值的类别',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY uq_key_value (`key`, `value`),
    INDEX idx_key (`key`),
    INDEX idx_value (`value`),
    INDEX idx_category (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='原始交易统计表';

-- --------------------------------------------------------

--
-- 预置数据
--

INSERT INTO `dek_account` (`account_code`, `account_name`, `account_type`) VALUES
('1001', '现金', '资产'),
('1002', '存款', '资产'),
('2001', '房贷', '负债'),
('2002', '车贷', '负债'),
('4001', '工资', '收入'),
('5001', '餐饮', '费用'),
('5002', '交通', '费用'),
('5003', '购物', '费用');
