-- ============================================================
--  ja3-main · 全量建库建表脚本（幂等，可重复执行）
--  数据库：springboot_test   字符集：utf8mb4
--  登录方式：昵称 + 密码（无邮箱）
--
--  内容分级分类模型（两级）：
--    一级分类 category   (id, name, slug, sort)        例：前端 / 后端 / 设计 / 数据库 / 工程
--    二级标签 tag        (id, name, slug, category_id)  例：Vue、Vite 归属「前端」
--    关联表   article_tag (article_id, tag_id)          文章 ↔ 标签 多对多
--    article.category_id 同时冗余一份一级分类，便于直接按一级分类过滤与统计
--
--  注意：若只需增量升级已有库，请执行 migrate-category.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS springboot_test
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE springboot_test;

-- ============================================================
-- 用户表
-- ============================================================
CREATE TABLE IF NOT EXISTS `user` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name`       VARCHAR(64)  NOT NULL COMMENT '昵称（唯一登录名）',
  `password`   VARCHAR(100) NOT NULL COMMENT 'BCrypt 加密后的密码（禁止明文）',
  `permission` TINYINT      NOT NULL DEFAULT 1 COMMENT '权限：1=默认用户，0=管理员',
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- ============================================================
-- 一级分类表
-- ============================================================
CREATE TABLE IF NOT EXISTS `category` (
  `id`         BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name`       VARCHAR(64) NOT NULL COMMENT '分类名（展示用）',
  `slug`       VARCHAR(64) NOT NULL COMMENT '分类英文名 / URL 别名',
  `sort`       INT         NOT NULL DEFAULT 0 COMMENT '排序权重，越小越靠前',
  `created_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_category_name` (`name`),
  UNIQUE KEY `uk_category_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='一级分类表';

-- ============================================================
-- 二级标签表（tag 归属某个一级分类）
--   category_id 允许为 NULL：表示不属于任何一级分类的通用标签
-- ============================================================
CREATE TABLE IF NOT EXISTS `tag` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name`        VARCHAR(64) NOT NULL COMMENT '标签名（展示用）',
  `slug`        VARCHAR(64) NOT NULL COMMENT '标签英文名 / URL 别名',
  `category_id` BIGINT      NULL COMMENT '所属一级分类 id',
  `sort`        INT         NOT NULL DEFAULT 0 COMMENT '排序权重，越小越靠前',
  `created_at`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tag_name` (`name`),
  KEY `idx_tag_category` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='二级标签表';

-- ============================================================
-- 文章表（首页搜索 / 展示的数据源）
--   category      冗余一级分类名，列表页免 JOIN
--   category_id   一级分类 id，支持按分类精确过滤
--   tags          冗余逗号分隔标签串，用于关键词模糊命中（权威数据在 article_tag）
--   views         浏览量，作为默认「热度」排序依据
-- ============================================================
CREATE TABLE IF NOT EXISTS `article` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `title`       VARCHAR(200) NOT NULL COMMENT '标题',
  `summary`     VARCHAR(500) NOT NULL DEFAULT '' COMMENT '摘要',
  `content`     TEXT         NULL COMMENT '正文',
  `author`      VARCHAR(64)  NOT NULL DEFAULT '' COMMENT '作者',
  `category_id` BIGINT       NULL COMMENT '一级分类 id',
  `category`    VARCHAR(64)  NOT NULL DEFAULT '' COMMENT '一级分类名（冗余，便于展示）',
  `tags`        VARCHAR(255) NOT NULL DEFAULT '' COMMENT '标签名逗号分隔（冗余，用于模糊命中）',
  `views`       INT          NOT NULL DEFAULT 0 COMMENT '浏览量（热度）',
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_article_title` (`title`),
  KEY `idx_article_category` (`category`),
  KEY `idx_article_category_id` (`category_id`),
  KEY `idx_article_created` (`created_at`),
  KEY `idx_article_views` (`views`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文章表（首页搜索数据源）';

-- ============================================================
-- 文章 ↔ 标签 关联表（多对多）
-- ============================================================
CREATE TABLE IF NOT EXISTS `article_tag` (
  `article_id` BIGINT NOT NULL COMMENT '文章 id',
  `tag_id`     BIGINT NOT NULL COMMENT '标签 id',
  PRIMARY KEY (`article_id`, `tag_id`),
  KEY `idx_at_tag` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文章-标签关联表';

-- ============================================================
--  演示数据（幂等：先补齐分类 / 标签，再仅在 article 为空时插入文章）
-- ============================================================

-- 一级分类
INSERT INTO `category` (`name`, `slug`, `sort`) VALUES
  ('前端',   'frontend', 10),
  ('后端',   'backend',  20),
  ('设计',   'design',   30),
  ('数据库', 'database', 40),
  ('工程',   'devops',   50)
ON DUPLICATE KEY UPDATE `sort` = VALUES(`sort`);

-- 二级标签（按分类归属）
INSERT INTO `tag` (`name`, `slug`, `category_id`, `sort`)
SELECT t.n, t.s, c.id, t.o
FROM (
            SELECT 'Vue'          AS n, 'vue'            AS s, '前端'   AS cn, 10 AS o
  UNION ALL SELECT 'Vite',            'vite',             '前端',   20
  UNION ALL SELECT '组合式API',       'composition-api',  '前端',   30
  UNION ALL SELECT '构建工具',        'bundler',          '前端',   40
  UNION ALL SELECT 'Spring Boot',     'spring-boot',      '后端',   10
  UNION ALL SELECT 'MyBatis-Plus',    'mybatis-plus',     '后端',   20
  UNION ALL SELECT 'JWT',             'jwt',              '后端',   30
  UNION ALL SELECT '认证',            'auth',             '后端',   40
  UNION ALL SELECT '安全',            'security',         '后端',   50
  UNION ALL SELECT '设计灵感',        'design-inspire',   '设计',   10
  UNION ALL SELECT '玻璃拟态',        'glassmorphism',    '设计',   20
  UNION ALL SELECT '配色',            'color',            '设计',   30
  UNION ALL SELECT '深色主题',        'dark-mode',        '设计',   40
  UNION ALL SELECT 'UI',              'ui',               '设计',   50
  UNION ALL SELECT '极光',            'aurora',           '设计',   60
  UNION ALL SELECT '星海',            'starfield',        '设计',   70
  UNION ALL SELECT 'MySQL',           'mysql',            '数据库', 10
  UNION ALL SELECT '索引',            'index',            '数据库', 20
  UNION ALL SELECT '性能优化',        'performance',      '数据库', 30
  UNION ALL SELECT '工程化',          'engineering',      '工程',   10
  UNION ALL SELECT '前后端分离',      'frontend-backend', '工程',   20
) AS t
JOIN `category` c ON c.name = t.cn
ON DUPLICATE KEY UPDATE `slug`        = VALUES(`slug`),
                        `category_id` = VALUES(`category_id`),
                        `sort`        = VALUES(`sort`);

-- 文章（仅在表为空时插入，保证可重复执行不产生重复数据）
INSERT INTO `article` (`title`, `summary`, `content`, `author`, `category_id`, `category`, `tags`, `views`, `created_at`)
SELECT tmp.t, tmp.s, tmp.c, tmp.a, cat.id, tmp.cat, tmp.tg, tmp.v, tmp.d
FROM (
            SELECT '极光下的星海：Vue 3 组合式 API 实战' AS t,
                   '从 setup 语法糖到自定义 composable，一步步拆解 Aurora 登录页的实现思路。' AS s,
                   '组合式 API 让逻辑复用变得自然。本文以 Aurora 项目为例，梳理 ref、computed、watch 的协作方式，并给出登录表单校验 composable 的完整抽离过程。' AS c,
                   '段先生' AS a, '前端' AS cat, 'Vue,组合式API,前端' AS tg, 1286 AS v, '2026-10-01 09:20:00' AS d
  UNION ALL SELECT 'Spring Boot 3 整合 MyBatis-Plus 的正确姿势',
                   '依赖选型、分页插件、驼峰映射，把踩过的坑一次性讲清楚。',
                   'Spring Boot 3 需要 mybatis-plus-spring-boot3-starter，版本 3.5.9 起对 Jakarta 命名空间支持完整；分页插件需从 mybatis-plus-jsqlparser 单独引入。',
                   '段先生', '后端', 'Spring Boot,MyBatis-Plus,后端', 974, '2026-10-03 14:05:00'
  UNION ALL SELECT 'JWT 登录态设计：从签发到校验的完整链路',
                   '令牌结构、过期策略、前后端协作方式，以及为什么不要在前端存用户敏感信息。',
                   'JWT 由 header、payload、signature 三段组成。服务端只做验签，不保存会话，天然适合前后端分离；但必须配短过期时间与刷新机制。',
                   '风林', '后端', 'JWT,认证,安全', 1533, '2026-10-05 10:12:00'
  UNION ALL SELECT '玻璃拟态设计指南：让界面轻起来',
                   '毛玻璃、噪点、渐变边框的组合公式，以及如何避免糊成一片。',
                   '玻璃拟态的核心是背景模糊加半透明叠加。关键是控制对比度，让前景文字始终清晰可读，深色背景下尤其要注意描边亮度。',
                   '林深', '设计', '设计灵感,玻璃拟态,UI', 2107, '2026-10-06 16:40:00'
  UNION ALL SELECT '星海配色：深色主题下的极光渐变',
                   '紫、青、粉三色如何配比，才能既有科技感又不刺眼。',
                   '深色主题中，高饱和色只做点缀。把大面积留给深背景，渐变只出现在标题和按钮上，并用模糊光斑营造星海氛围。',
                   '林深', '设计', '配色,设计灵感,深色主题,极光,星海', 1822, '2026-10-07 11:30:00'
  UNION ALL SELECT 'MySQL 索引优化入门：从慢查询到执行计划',
                   '看懂 EXPLAIN 的 type、key、rows 三列，找出该加的索引。',
                   '索引的本质是把随机 IO 变成顺序 IO。联合索引要遵守最左前缀原则，范围查询会中断后续列的索引使用。',
                   '风林', '数据库', 'MySQL,索引,性能优化', 1341, '2026-10-08 08:55:00'
  UNION ALL SELECT 'Vite 为什么这么快：ESM 与依赖预构建',
                   '对比 Webpack 的打包方式，理解 Vite 冷启动快在哪一环。',
                   'Vite 开发环境不做打包，直接用浏览器原生 ESM 加载模块，配合 esbuild 预构建依赖，冷启动只需毫秒级。',
                   '段先生', '前端', 'Vite,构建工具,前端', 1655, '2026-10-09 13:18:00'
  UNION ALL SELECT '从零搭建一套前后端分离的个人项目',
                   '目录结构、启动脚本、环境变量，把重复劳动交给脚本。',
                   '前后端分离项目的关键约定是接口契约稳定。前端只管发请求，后端只管返回结构化数据，启动脚本负责把环境差异抹平。',
                   '风林', '工程', '工程化,前后端分离,Vue', 889, '2026-10-10 15:02:00'
) AS tmp
JOIN `category` cat ON cat.name = tmp.cat
WHERE NOT EXISTS (SELECT 1 FROM `article` LIMIT 1);

-- 文章 ↔ 标签 关联（按标题 + 标签名反查；INSERT IGNORE 保证幂等）
INSERT IGNORE INTO `article_tag` (`article_id`, `tag_id`)
SELECT a.id, t.id
FROM `article` a
JOIN (
            SELECT '极光下的星海：Vue 3 组合式 API 实战' AS title, 'Vue' AS tn
  UNION ALL SELECT '极光下的星海：Vue 3 组合式 API 实战', '组合式API'
  UNION ALL SELECT 'Spring Boot 3 整合 MyBatis-Plus 的正确姿势', 'Spring Boot'
  UNION ALL SELECT 'Spring Boot 3 整合 MyBatis-Plus 的正确姿势', 'MyBatis-Plus'
  UNION ALL SELECT 'JWT 登录态设计：从签发到校验的完整链路', 'JWT'
  UNION ALL SELECT 'JWT 登录态设计：从签发到校验的完整链路', '认证'
  UNION ALL SELECT 'JWT 登录态设计：从签发到校验的完整链路', '安全'
  UNION ALL SELECT '玻璃拟态设计指南：让界面轻起来', '设计灵感'
  UNION ALL SELECT '玻璃拟态设计指南：让界面轻起来', '玻璃拟态'
  UNION ALL SELECT '玻璃拟态设计指南：让界面轻起来', 'UI'
  UNION ALL SELECT '星海配色：深色主题下的极光渐变', '配色'
  UNION ALL SELECT '星海配色：深色主题下的极光渐变', '深色主题'
  UNION ALL SELECT '星海配色：深色主题下的极光渐变', '设计灵感'
  UNION ALL SELECT '星海配色：深色主题下的极光渐变', '极光'
  UNION ALL SELECT '星海配色：深色主题下的极光渐变', '星海'
  UNION ALL SELECT 'MySQL 索引优化入门：从慢查询到执行计划', 'MySQL'
  UNION ALL SELECT 'MySQL 索引优化入门：从慢查询到执行计划', '索引'
  UNION ALL SELECT 'MySQL 索引优化入门：从慢查询到执行计划', '性能优化'
  UNION ALL SELECT 'Vite 为什么这么快：ESM 与依赖预构建', 'Vite'
  UNION ALL SELECT 'Vite 为什么这么快：ESM 与依赖预构建', '构建工具'
  UNION ALL SELECT '从零搭建一套前后端分离的个人项目', '工程化'
  UNION ALL SELECT '从零搭建一套前后端分离的个人项目', '前后端分离'
  UNION ALL SELECT '从零搭建一套前后端分离的个人项目', 'Vue'
) AS m ON m.title = a.title
JOIN `tag` t ON t.name = m.tn;

SELECT 'init ok' AS result;
