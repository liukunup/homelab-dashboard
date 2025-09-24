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
    `account_name` VARCHAR(64) NOT NULL COMMENT '科目名称',
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
    `brief` TEXT NOT NULL COMMENT '摘要',
    `reference` VARCHAR(256) DEFAULT NULL COMMENT '订单号/凭证号/参考号',
    `status` ENUM('draft', 'posted', 'reviewed') NOT NULL DEFAULT 'draft' COMMENT '状态',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    INDEX idx_transaction_date (`transaction_date`),
    INDEX idx_reference (`reference`),
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
    `template` VARCHAR(256) DEFAULT '{counterpart} - {goods}' COMMENT '描述模板',
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
    `transaction_at` DATETIME NOT NULL COMMENT '交易时间',
    `transaction_type` VARCHAR(256) NOT NULL COMMENT '交易类型',
    `counterparty` VARCHAR(256) DEFAULT NULL COMMENT '交易对方',
    `account` VARCHAR(256) DEFAULT NULL COMMENT '对方账号',
    `goods` VARCHAR(256) NOT NULL COMMENT '商品',
    `income_or_expenditure` ENUM('收入','支出','不计收支','/') NOT NULL COMMENT '收/支',
    `amount` DECIMAL(15,2) NOT NULL COMMENT '金额',
    `channel` VARCHAR(256) DEFAULT NULL COMMENT '收/付款方式',
    `status` VARCHAR(256) NOT NULL COMMENT '交易状态',
    `trade_no` VARCHAR(256) NOT NULL COMMENT '交易订单号',
    `out_trade_no` VARCHAR(256) NOT NULL COMMENT '商家订单号',
    `comments` VARCHAR(1024) DEFAULT NULL COMMENT '备注',
    `source` ENUM('manual', 'alipay', 'wechatpay', 'bank') NOT NULL DEFAULT 'manual' COMMENT '来源',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    INDEX idx_transaction_at (`transaction_at`),
    INDEX idx_source (`source`),
    INDEX idx_trade_no (`trade_no`),
    INDEX idx_counterparty (`counterparty`),
    INDEX idx_income_or_expenditure (`income_or_expenditure`),
    INDEX idx_transaction_type (`transaction_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='原始交易记录表';

-- --------------------------------------------------------

--
-- 原始交易统计表
--

CREATE TABLE `deb_online_transaction_statistics` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `key` VARCHAR(256) NOT NULL COMMENT '键',
    `value` VARCHAR(256) NOT NULL COMMENT '值',
    `value_count` BIGINT UNSIGNED NOT NULL COMMENT '值的出现次数',
    `tag` VARCHAR(256) NOT NULL DEFAULT '暂未标记' COMMENT '值的类别/标记',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY uq_key_value (`key`, `value`),
    INDEX idx_key (`key`),
    INDEX idx_value (`value`),
    INDEX idx_tag (`tag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='原始交易统计表';

-- --------------------------------------------------------

--
-- 工资薪金表
--

CREATE TABLE `deb_salary` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `dtm` DATE NOT NULL COMMENT '年/月/日',
    `company` VARCHAR(256) NOT NULL COMMENT '公司',
    `amount` DECIMAL(15,2) NOT NULL CHECK (amount > 0) COMMENT '金额',
    `category` ENUM('工资','年终奖','裁员赔偿','补贴','奖金','其他') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '类别',
    `comments` VARCHAR(1024) DEFAULT NULL COMMENT '备注',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY uq_dtm_company_amount (`dtm`, `company`, `amount`),
    INDEX idx_dtm (`dtm`),
    INDEX idx_company (`company`),
    INDEX idx_category (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工资薪金表';

-- --------------------------------------------------------

--
-- 房贷还款表
--

CREATE TABLE `deb_loan` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
    `period` INT NOT NULL COMMENT '第N期',
    `organization` VARCHAR(256) NOT NULL COMMENT '服务机构名称',
    `current_interest_rate` DECIMAL(15,2) NOT NULL CHECK (current_interest_rate > 0) COMMENT '当前年利率(%)',
    `lpr_spread` DECIMAL(15,2) NOT NULL CHECK (lpr_spread > 0) COMMENT '加点幅度(%)',
    `actual_principal_interest` DECIMAL(15,2) NOT NULL CHECK (actual_principal_interest > 0) COMMENT '实还本息',
    `due_principal_interest` DECIMAL(15,2) NOT NULL CHECK (due_principal_interest > 0) COMMENT '应还本息',
    `actual_principal` DECIMAL(15,2) NOT NULL CHECK (actual_principal > 0) COMMENT '实还本金',
    `actual_interest` DECIMAL(15,2) NOT NULL CHECK (actual_interest > 0) COMMENT '实还利息',
    `repayment_date` DATE NOT NULL COMMENT '还款日期',
    `actual_interest_payment_date` DATE NOT NULL COMMENT '实际还息日期',
    `create_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `delete_at` DATETIME DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY uq_period_organization (`period`, `organization`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='房贷还款表';

-- --------------------------------------------------------

--
-- 预置数据
--

INSERT INTO `deb_account` (`account_code`, `account_name`, `account_type`) VALUES
-- 资产类 (1xxx)
('1001', '现金', '资产'),
('1002', '银行存款', '资产'),
('1003', '支付宝余额', '资产'),
('1004', '微信零钱', '资产'),
('1005', '信用卡', '资产'),
('1010', '应收账款', '资产'),
('1020', '预付费用', '资产'),
-- 负债类 (2xxx)
('2001', '房贷', '负债'),
('2002', '车贷', '负债'),
('2010', '应付账款', '负债'),
('2011', '应付工资', '负债'),
('2012', '预收收入', '负债'),
-- 权益类 (3xxx)
('3001', '实收资本', '权益'),
('3002', '未分配利润', '权益'),
-- 收入类 (4xxx)
('4001', '工资收入', '收入'),
('4002', '奖金收入', '收入'),
('4003', '兼职收入', '收入'),
('4004', '理财收入', '收入'),
('4005', '投资收益', '收入'),
-- 费用类 (5xxx)
('5001', '餐饮美食', '费用'),
('5002', '交通出行', '费用'),
('5003', '购物消费', '费用'),
('5004', '住房水电', '费用'),
('5005', '通讯网络', '费用'),
('5006', '娱乐休闲', '费用'),
('5007', '医疗保健', '费用'),
('5008', '学习培训', '费用'),
('5009', '人情往来', '费用'),
('5010', '服饰美容', '费用'),
('5011', '宠物花销', '费用'),
('5012', '汽车费用', '费用'),
('5013', '保险费用', '费用'),
('5014', '税费支出', '费用');
