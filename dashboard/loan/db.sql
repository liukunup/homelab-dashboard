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
-- 表的结构 `loan`
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

-- --------------------------------------------------------

--
-- 确保记录唯一
--

ALTER TABLE `loan` ADD UNIQUE(`period`, `organization`);
