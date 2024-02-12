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
-- 表的结构 `salary`
--

CREATE TABLE `salary` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '记录编号',
  `dtm` date NOT NULL COMMENT '发薪时间',
  `company` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '发薪公司',
  `amount` double NOT NULL COMMENT '薪金值',
  `category` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '收入类型',
  `comments` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '收入备注',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='个人薪资单';

-- --------------------------------------------------------

--
-- 发薪时间+发薪公司 确保记录唯一
--

ALTER TABLE `salary` ADD UNIQUE(`dtm`, `company`);
