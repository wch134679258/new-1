-- =============================================================
--  [已废弃] 请勿使用本脚本的 role 权限模型
--  当前项目统一使用 `permission`：1=默认用户，0=管理员。
--  请改为执行：migrate-permission.sql
--  本文件仅保留历史记录，role 列不再参与登录/后台权限判断。
--
--  管理端（文章 CRUD）· 角色列迁移（历史文件）
--  用法：mysql -uroot -p123456 --default-character-set=utf8mb4 springboot_test < 本文件
--
--  背景：
--    user 表原本只有 id / name / password，没有角色概念，
--    管理接口（/api/admin/**）无法区分普通用户与管理员。
--    这里加一列 role：0 = 普通用户（默认），1 = 管理员。
--
--  幂等说明：
--    MySQL 8 不支持 "ADD COLUMN IF NOT EXISTS"（那是 MariaDB 语法），
--    因此用 information_schema 先查是否存在，再用 PREPARE 动态决定是否 ALTER。
-- =============================================================

USE springboot_test;

-- ---------- 1. 添加 role 列（已存在则跳过） ----------
SET @schema = DATABASE();
SET @col_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @schema
    AND TABLE_NAME   = 'user'
    AND COLUMN_NAME  = 'role'
);

SET @ddl = IF(@col_exists = 0,
  "ALTER TABLE `user` ADD COLUMN `role` TINYINT NOT NULL DEFAULT 0 COMMENT '0=普通用户 1=管理员' AFTER `password`",
  "SELECT 'role 列已存在，跳过' AS info"
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------- 2. 补索引：便于按角色筛选 ----------
SET @idx_exists = (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = @schema
    AND TABLE_NAME   = 'user'
    AND INDEX_NAME   = 'idx_user_role'
);
SET @idx = IF(@idx_exists = 0,
  "ALTER TABLE `user` ADD KEY `idx_user_role` (`role`)",
  "SELECT 'idx_user_role 已存在，跳过' AS info"
);
PREPARE stmt2 FROM @idx;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- ---------- 3. 把测试账号提升为管理员 ----------
-- 说明：verify用户 是本机长期使用的测试账号，默认给它管理员权限，
--       方便直接进管理页。正式环境请改为显式授权。
UPDATE `user` SET `role` = 1 WHERE `name` = 'verify用户';

-- ---------- 4. 结果自查 ----------
SELECT
  (SELECT COUNT(*) FROM `user` WHERE `role` = 1) AS admin_count,
  (SELECT COUNT(*) FROM `user`)                  AS user_count,
  (SELECT COUNT(*) FROM article)                 AS article_count,
  (SELECT COUNT(*) FROM category)                AS category_count,
  (SELECT COUNT(*) FROM tag)                     AS tag_count;

SELECT 'migrate admin ok' AS result;
