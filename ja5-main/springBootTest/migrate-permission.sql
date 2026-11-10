-- ============================================================
--  用户权限字段迁移（可重复执行）
--  数据库：springboot_test
--  规则：permission = 1 默认用户；permission = 0 管理员
--  密码：继续使用 BCrypt 哈希，禁止写入明文
-- ============================================================

CREATE DATABASE IF NOT EXISTS `springboot_test`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE `springboot_test`;

-- 1. 新增 permission 字段（已存在则跳过）
SET @has_permission := (
  SELECT COUNT(*)
    FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'user'
     AND COLUMN_NAME  = 'permission'
);
SET @ddl := IF(
  @has_permission = 0,
  'ALTER TABLE `user` ADD COLUMN `permission` TINYINT NOT NULL DEFAULT 1 COMMENT ''权限：1=默认用户，0=管理员'' AFTER `password`',
  'SELECT ''permission 字段已存在，跳过'' AS info'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 新增权限索引（查询管理员/普通用户时更快，已存在则跳过）
SET @has_index := (
  SELECT COUNT(*)
    FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'user'
     AND INDEX_NAME   = 'idx_user_permission'
);
SET @ddl := IF(
  @has_index = 0,
  'ALTER TABLE `user` ADD KEY `idx_user_permission` (`permission`)',
  'SELECT ''idx_user_permission 已存在，跳过'' AS info'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. 所有账号先归为默认权限，再把最早创建的用户设为管理员
--    当前项目里 id=1 是 verify用户；如需指定其他管理员，请修改下方条件。
UPDATE `user` SET `permission` = 1;
UPDATE `user`
   SET `permission` = 0
 WHERE `id` = (SELECT `id` FROM (SELECT MIN(`id`) AS `id` FROM `user`) AS first_user);

-- 4. 查看结果（password 不查询、不输出明文）
SELECT `id`, `name`, `permission`,
       CASE WHEN `permission` = 0 THEN '管理员' ELSE '默认用户' END AS `permission_label`
  FROM `user`
 ORDER BY `permission`, `id`;
