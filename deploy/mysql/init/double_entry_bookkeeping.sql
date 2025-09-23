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

CREATE TABLE `deb_account` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `account_code` VARCHAR(4) NOT NULL COMMENT '科目编码',
    `account_name` VARCHAR(256) NOT NULL COMMENT '科目名称',
    `account_type` ENUM('资产', '负债', '权益', '收入', '费用') NOT NULL COMMENT '科目类型',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否启用',
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

CREATE TABLE `deb_transaction` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `transaction_date` DATE NOT NULL COMMENT '交易日期',
    `description` TEXT NOT NULL COMMENT '摘要',
    `reference` VARCHAR(256) DEFAULT NULL COMMENT '订单号/凭证号/参考号',
    `status` ENUM('draft', 'posted', 'reviewed') NOT NULL DEFAULT 'draft' COMMENT '状态',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    INDEX idx_transaction_date (`transaction_date`),
    INDEX idx_status (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易主表';

-- --------------------------------------------------------

--
-- 交易分录表
--

CREATE TABLE `deb_transaction_entry` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `transaction_id` BIGINT UNSIGNED NOT NULL COMMENT '所属交易ID',
    `account_id` BIGINT UNSIGNED NOT NULL COMMENT '关联科目ID',
    `amount` DECIMAL(15,2) NOT NULL CHECK (amount > 0) COMMENT '金额（正数）',
    `flag` ENUM('debit', 'credit') NOT NULL COMMENT '借贷标志',
    `description` VARCHAR(256) COMMENT '分录描述',
    `source` ENUM('manual', 'alipay', 'wechatpay', 'bank') NOT NULL DEFAULT 'manual' COMMENT '来源',
    `source_id` VARCHAR(256) DEFAULT NULL COMMENT '原始交易ID',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    INDEX idx_transaction_id (`transaction_id`),
    INDEX idx_account_id (`account_id`),
    INDEX idx_source_id (`source_id`),
    FOREIGN KEY (`transaction_id`) REFERENCES `deb_transaction`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`account_id`) REFERENCES `deb_account`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易分录表';

-- --------------------------------------------------------

--
-- 映射规则表
--

CREATE TABLE `deb_mapping_rule` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `platform` ENUM('manual', 'alipay', 'wechatpay', 'bank', 'all') NOT NULL COMMENT '适用平台',
    `pattern` VARCHAR(256) NOT NULL COMMENT '匹配模式',
    `debit_account_id` BIGINT UNSIGNED NOT NULL COMMENT '借方科目ID',
    `credit_account_id` BIGINT UNSIGNED NOT NULL COMMENT '贷方科目ID',
    `template` VARCHAR(256) DEFAULT '{goods} - {counterpart}' COMMENT '描述模板',
    `priority` INT NOT NULL DEFAULT 0 COMMENT '优先级（数值越大优先级越高）',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    INDEX idx_platform (`platform`),
    INDEX idx_priority (`priority`),
    FOREIGN KEY (`debit_account_id`) REFERENCES `deb_account`(`id`) ON DELETE RESTRICT,
    FOREIGN KEY (`credit_account_id`) REFERENCES `deb_account`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='映射规则表';

-- --------------------------------------------------------

--
-- 原始交易记录（包括支付宝、微信支付等）
--

CREATE TABLE `deb_online_transaction` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `timestamp` DATETIME NOT NULL COMMENT '交易时间',
    `category` VARCHAR(256) NOT NULL COMMENT '交易类型',
    `counterparty` VARCHAR(256) DEFAULT NULL COMMENT '交易对方',
    `account` VARCHAR(256) DEFAULT NULL COMMENT '对方账号',
    `goods` VARCHAR(256) NOT NULL COMMENT '商品',
    `income_or_expenditure` ENUM('收入','支出','不计收支','/') NOT NULL COMMENT '收/支',
    `amount` double NOT NULL COMMENT '金额',
    `channel` VARCHAR(256) DEFAULT NULL COMMENT '收/付款方式',
    `status` VARCHAR(256) NOT NULL COMMENT '交易状态',
    `po_transaction` VARCHAR(256) NOT NULL COMMENT '交易订单号',
    `po_seller` VARCHAR(256) NOT NULL COMMENT '商家订单号',
    `comments` VARCHAR(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '备注',
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

CREATE TABLE `deb_online_transaction_statistics` (
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
