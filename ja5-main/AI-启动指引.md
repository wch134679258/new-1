# AI 快速启动指引（ja4 项目）

> **本文件写给 AI 助手看**（人类也可参考）。这台电脑每次重置后 `node_modules`、`target` 文件夹会被删除，请依赖本文件避免重复探索，直接执行标准流程。
> 最后更新：2026-10-16（新增：文章详情/收藏/搜索建议 + 《凡人修仙传》小说内容 + 前端多页面；详见「八、2026-10-16 功能升级」）

**测试账号**：昵称 `verify用户`，密码 `abc12345`（2026-10-16 重新入库，可直接登录验证；注意数据库当天被重置过，`段先生` 账号的密码未知）
**版本管理**：项目根目录已是 git 仓库（分支 main）。改动代码后请提交；开机后如怀疑文件被动过，可用 `git status` / `git diff` 对比。

## 一、项目结构（都在 C:\Users\Administrator\Desktop\ja3-main\）

```
Desktop\ja4\
├─ 启动项目.bat / 启动前端.bat / 启动后端.bat / 停止项目.bat   ← GBK 编码一键脚本
├─ AI-启动指引.md    ← 本文件
├─ _archive\        冗余副本归档区（2026-10-19 从 ja3-main 移入，可随时删）
└─ ja3-main\
   ├─ aurora-vue-2\     前端：Vue3 + Vite，端口 5173（Aurora 登录/注册页）
   ├─ springBootTest\   后端：Spring Boot 3.4.5 + MyBatis-Plus，端口 8081（自带 mvnw）
   └─ *.rar             原始压缩包，勿删
```

## 二、环境（已确认可用，无需重新检查）

- **Node**：系统 PATH 有 node（D:\Program Files\nodejs，v20.11）；AI 沙盒内优先用托管版：
  `C:\Users\Administrator\.workbuddy\binaries\node\versions\22.22.2-2\node.exe`
- **Java**：Zulu 21（PATH 有 java），满足项目要求（JDK 17+）
- **Maven**：无全局 mvn，用 `springBootTest\mvnw.cmd`（阿里云镜像已配置，~/.m2 已缓存约 800MB）
- **MySQL 8.0**：已安装，服务自启（3306 端口），账号 root / 123456
- **数据库**：`springboot_test` 库已建好（user 表：id/name/password，name 唯一索引，**无 email 列**）。若库被重置，重跑 `springBootTest\init-db.sql`（mysql 客户端在 C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe）
- **npm 缓存**：C:\Users\Administrator\AppData\Local\npm-cache（若缓存保留，安装很快）

## 三、开机后的标准流程（AI 直接照做，不要重新分析）

1. **推荐：一键启动**（AI 请用 PowerShell 工具后台调用，用户可直接双击）：
   ```
   & "C:\Users\Administrator\Desktop\ja3-main\启动后端.bat"    ← 后台运行
   & "C:\Users\Administrator\Desktop\ja3-main\启动前端.bat"    ← 后台运行
   ```
   脚本会自动 npm install / mvnw 编译，**不依赖已删除的 node_modules、target**
2. **验证就绪**（轮询即可）：
   - `curl http://localhost:5173` → 200
   - `curl http://localhost:8081/api/auth/captcha` → JSON
3. **打开页面**：http://localhost:5173 （昵称 + 密码注册/登录，带图形验证码）
4. **停止项目**：运行 `停止项目.bat`（kill 5173、8081 端口进程）

**实测耗时参考**：前端冷启动约 30 秒（依赖重装），热启动约 5 秒；后端冷编译约 60-70 秒，热启动约 20 秒。

## 四、关键事实（避免不必要的思考）

- **登录方式**：昵称 + 密码。**邮箱功能已全部移除**（表单、后端 DTO/Service/实体、数据库列、verify_code 表均已删）
- 接口签名：
  - `POST /api/auth/register { name, password, captchaId, captcha }` → `{ token, userId }`
  - `POST /api/auth/login { name, password, remember }` → `{ token, userId }`
  - `GET /api/auth/me`（Bearer token）→ `{ id, name }`
- `vite.config.js` 已配置 `/api → http://localhost:8081` 代理，前端**无需 .env**；后端 CorsConfig 也放行 5173（双保险）
- JWT 密钥与数据库密码均为演示值（root/123456），生产需替换
- 图形验证码存后端内存 Map，重启后端即失效（正常现象）；4 位字母数字不区分大小写
- 每次开机 node_modules、target 必被清空 → **这是设计如此，不是故障**，脚本已适配

## 五、AI 沙盒环境的坑（脚本已内置规避，若手动执行需注意）

- 沙盒会注入 `SERVER__PORT`（双下划线）环境变量，Spring 宽松绑定会把它当成 `server.port`，导致后端绑到错误端口 → 手动跑后端前先清掉
- 沙盒注入的 HTTP_PROXY/HTTPS_PROXY 指向会失效的本地代理 → 手动 npm 前先清掉
- bash 里 `cmd //c 中文.bat` 传参会乱码 → 用 PowerShell 工具 `& "路径.bat"` 代替
- PowerShell 工具前台运行拿不到 stdout → 用 run_in_background 后台运行再用 TaskOutput 读输出
- cmd 黑名单：sc.exe、wmic.exe、reg.exe、从 bash 调 powershell 均被禁

## 六、首页搜索（2026-10-14 完成）

**数据模型（两级分类）**：
- `category` 一级分类（前端/后端/设计/数据库/工程）
- `tag` 二级标签，`category_id` 归属一级分类
- `article_tag` 文章↔标签多对多；`article.category_id` 冗余一级分类便于过滤
- **建表脚本**：`springBootTest/init-db.sql`（全量，幂等）；已有库增量升级用 `springBootTest/migrate-category.sql`（幂等，自动回填关联）

**接口**（均公开无需登录）：
- `GET /api/search?q=&categoryId=&tagId=&sort=hot|new&page=&size=` —— 关键词命中 标题/摘要/正文/作者/标签串，有关键词时按「标题命中>标签命中>热度」相关度排序；分类与标签可叠加（分级分类交叉检索）
- `GET /api/search/categories` —— 分类树（一级分类+其下标签+文章数）
- `GET /api/search/hot-tags` —— 热门标签（按关联文章数倒序）

**前端**：`HomePage.vue` 已接入（分类导航、二级标签联动、热度/最新排序、筛选面包屑、分页）；API 封装在 `src/api/search.js`。

**AI 沙盒跑后端的坑（新增）**：沙盒的 `SERVER__PORT` 会让后端绑错端口（实测跑到 8080）。正确姿势：
```bash
env -u SERVER_PORT -u SERVER__PORT -u SERVER_ADDRESS -u SERVER__ADDRESS -u SERVER_HOST -u SERVER__HOST -u MAVEN_OPTS \
  HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= \
  java -classpath "$MVN_HOME/boot/plexus-classworlds-2.8.0.jar" -Dclassworlds.conf="$MVN_HOME/bin/m2.conf" \
  -Dmaven.home="$MVN_HOME" -Dmaven.multiModuleProjectDirectory="$PWD" \
  org.codehaus.plexus.classworlds.launcher.Launcher -o -DskipTests spring-boot:run -Dspring-boot.run.jvmArguments="-Dserver.port=8081"
```
（`mvn`/`mvnw` shell 脚本在沙盒内因 classworlds 加载问题不可用，直接用 java 调 Launcher 可行）

## 七、已知缺失 / 可改进（截至 2026-10-14）

- `后端\`、`后端文件\` 冗余副本文件夹，建议归档避免混淆
- 后端无单元测试
- 密码找回功能随邮箱一并移除（如需找回，可后续加管理员重置或手机号方案）
- `user` 表中 `段先生` 的旧密码 hash 与任何已知口令不匹配（历史遗留数据），已新增 `verify用户`/`abc12345` 作为可用测试账号

## 八、2026-10-16 功能升级（文章详情 / 收藏 / 搜索建议 / 小说内容）

### 8.1 数据库变更（幂等迁移脚本，按序执行）

```
springBootTest/migrate-novel.sql     新增「小说」分类 + 7 个标签 + 《凡人修仙传》5 篇文章（含正文）
springBootTest/migrate-novel-more.sql 小说第二辑：《龙族》《蛊真人》《诡秘之主》作品级标签 + 6 篇文章（含正文）
springBootTest/migrate-favorite.sql  新增 favorite 收藏表（user_id + article_id 联合唯一）
```

> 2026-10-16 当天库被重置过（只剩 `段先生`），上述两个脚本已执行；测试账号 `verify用户`/`abc12345`
> 已用 BCrypt 重新入库（id=2）。若库再被重置，重跑 init-db.sql + 这两个迁移脚本即可。

### 8.2 新增后端接口

```
GET  /api/article/{id}              文章详情（浏览量 +1；带 Bearer token 时返回 favorited）
GET  /api/article/{id}/related      相关文章（共享标签优先，同分类兜底，最多 4 条）
GET  /api/search/suggest?q=         搜索建议（标题 5 条 + 标签 5 条）
POST /api/favorites/{articleId}     收藏（需登录）   -> { message }
DELETE /api/favorites/{articleId}   取消收藏（需登录）
GET  /api/favorites?page=&size=     我的收藏列表（分页，需登录）
GET  /api/favorites/ids             已收藏的文章 id 列表（需登录，列表页标记收藏态）
```

关键类：`ArticleService` / `FavoriteService` / `ArticleController` / `FavoriteController` /
`FavoriteMapper(.xml)`；`ArticleItem.from()` 为搜索/收藏/相关文章共用的实体转 DTO 工厂；
`JwtUtil.tryGetUserId()` 用于「可选登录」接口（详情页：未登录也能看，登录了多返回收藏态）。

### 8.3 前端结构（视图状态机，无 vue-router）

App.vue 管理 view：`auth / home / article / favorites / discover / about`，body 加 `view-home` 类开启滚动。

```
src/api/http.js        统一请求层（token 注入 / 401 清token / {message} 错误提取），auth|search|article|favorites 四个 api 共用
src/api/article.js     详情 / 相关文章
src/api/favorites.js   收藏列表 / ids / 收藏 / 取消
src/components/SiteNav.vue       全站导航（首页/发现/收藏/关于全部可用）
src/components/ArticleCard.vue   文章卡片（整卡可点击、分类/标签可点、星星收藏）
src/components/ArticleDetail.vue 阅读页（正文分段、收藏、相关文章、返回）
src/components/FavoritesPage.vue 我的收藏（未登录引导登录、可直接取消收藏）
src/components/DiscoverPage.vue  发现页（最新/热门/分类入口）
src/components/AboutPage.vue     关于页（项目介绍 + 技术栈 + 测试账号）
src/components/SearchBar.vue     升级：建议下拉（防抖 250ms）+ 搜索历史（localStorage）+ 键盘导航 + 关键词高亮
src/components/HomePage.vue      升级：卡片进详情、卡片收藏、数字分页、支持跨页面初始筛选 initialFilter
```

修复：首页结果卡片 `.rcard` 原本只有媒体查询里的 padding、无基础样式（裸奔），现已由 ArticleCard 提供完整样式。

### 8.4 验证记录（2026-10-16 全部通过）

- 搜索「凡人修仙传」→ 5 条结果，标题命中优先（id 16/18/19/20 + 韩立人物志）
- 搜索建议 `q=凡人` → 3 条标题 + 2 条标签
- 详情/相关文章/收藏增删查/重复收藏 400/未登录 401/收藏不存在文章 400 均符合预期
- 前端 `vite build` 通过，8 个新组件经 dev server 逐一编译 200

### 8.5 环境备注

- `mvnw package` 离线会因缺 surefire 插件依赖失败；重启后端用文档「六」节末尾的 java Launcher 方式跑 `spring-boot:run`（compile 离线可用）
- Windows curl 传中文 JSON body：先 `printf` 写入**Windows 绝对路径**文件，再 `--data-binary @绝对路径`（MSYS 的 /tmp 路径 curl.exe 不认）

---

## 九、2026-10-19 后端加固（稳定性 / 安全 / 日志）

### 9.1 目录结构变化

- `ja3-main/后端/`、`ja3-main/后端文件/` → 归档到 **`_archive/`**（`git mv`，历史可追溯）
- `springBootTest/` 内新增：`config/AuthSupport.java`、`resources/logback-spring.xml`
- `springBootTest/` 内重命名：`application-prob.properties` → **`application-prod.properties`**（原名拼写错误）
- `UserController.java`（遗留 demo，密码硬编码 123、`/user/test` 打印配置）**经用户确认保留原样**，未删除，仅在此记录风险

### 9.2 配置与日志

| 项 | 改动 |
|---|---|
| `application.properties` | 中文注释原先全是 `?`（文件编码已损坏）→ 重写为 UTF-8；修正 `com.fengling`→`com.fenglin` 拼写（原配置从未生效）；新增优雅停机、错误不回传堆栈 |
| SQL 日志 | `StdOutImpl`（直接刷 stdout、绕过日志级别、无法归档）→ `Slf4jImpl`，由 `logging.level.com.fenglin.springboottest.mapper=debug` 控制 |
| 日志文件 | `log/xx.log` 单文件不轮转 → `log/springboot-test.log`，**10MB/天滚动 + gz + 保留 14 天 + 总量 200MB 封顶** |
| 多环境 | 新增 `application-prod.properties`（HikariCP 调参、敏感项走环境变量、SQL 日志关闭） |
| logback 坑 | `logback-spring.xml` 里 **不要 include** `org/springframework/boot/logging/logback/console.xml`——`spring-boot:run` 下解析不到，控制台日志会整段消失；改为自己定义 CONSOLE appender |

### 9.3 安全加固

- **JwtUtil**：`secret.getBytes()` 平台默认编码 → `StandardCharsets.UTF_8`（消除跨平台签名不互认的隐患）；补 HS384 密钥 ≥48 字节前置校验；`JwtParser` 缓存复用（线程安全）
- **AuthService**：`BCryptPasswordEncoder` 提升为单例 bean；注册补长度上限 + `DuplicateKeyException` 竞态转换（不再 500）；**登录失败 5 次锁定 60 秒**（内存计数，重启清零）
- **CaptchaService**：`new Random()` → `ThreadLocalRandom`；内存 Map 加上限 2000，防刷接口撑爆内存
- **AuthSupport**（新）：三处 Controller 各自复制的 Bearer 解析逻辑收敛为 `requireUserId` / `optionalUserId`

### 9.4 接口响应约定（新增）

`GlobalExceptionHandler` 现在兜底所有异常，**永远返回 `{message}` JSON，不再回 HTML 错误页**：

| 场景 | 状态码 | message |
|---|---|---|
| 业务异常 | 400 | 原文案 |
| 未登录 / 令牌无效 | 401 | 请先登录 / 登录已过期，请重新登录 |
| JSON 格式错误 | 400 | 请求体格式不正确，请检查后重试 |
| `@Valid` 校验失败 | 400 | `name 请输入昵称`（字段名 + 原因） |
| 参数类型错误 | 400 | 参数格式不正确：categoryId |
| 方法不支持 | 405 | 不支持的请求方法：POST |
| 路径不存在 | 404 | 接口不存在 |
| 唯一索引冲突 | 409 | 数据冲突，记录可能已存在 |
| 未预期异常 | 500 | 服务器内部错误，请稍后再试（堆栈只进日志） |

### 9.5 验证记录（2026-10-19 全部通过）

- `mvnw compile`：**BUILD SUCCESS**，34 个源文件零警告
- 冒烟：captcha / search / categories / hot-tags / suggest / article 详情 / related / favorites 增删查 / 重复收藏 400 / 未登录 401 / 假 token 401
- 新异常分支逐一验证：坏 JSON 400、空昵称 400、非数字 categoryId 400、POST /api/search 405、不存在路径 404
- 登录限流：连续 5 次失败后第 6 次返回「尝试次数过多，请 60 秒后再试」

### 9.6 本次踩坑记录（供后续参考）

- **数据库被重置过**：本机 MySQL 里 `springboot_test` 库曾不存在（`Unknown database`）→ 重跑 `init-db.sql` + `migrate-novel.sql` + `migrate-favorite.sql`
- `verify用户` 的旧 BCrypt hash 与 `abc12345` 不匹配 → 已用后端同款 `BCryptPasswordEncoder` 重新生成 hash 更新，测试账号恢复可用
- bash 直接 `cmd //c` 会被 MSYS 路径转换坑到；`./mvnw.cmd` 直接可执行
- 用 curl 发中文 JSON body 必须 `--data-binary @Windows绝对路径`（见 8.5）

## 十、2026-10-19 星空贪吃蛇小游戏（前后端联动）

### 10.1 功能概览

- 前端新页面 `aurora-vue-2/src/components/SpaceSnake.vue`（Canvas 实现，无新增依赖），入口：登录后导航栏「游戏」
- 玩法：光蛇吞噬小星球变长；普通星球 +10 分，金色星球 +50 分（约 12% 概率）；每吃一颗航速加快，撞边界 / 撞自己结束
- 交互：方向键 / WASD / 触屏滑动 / 虚拟方向键；空格暂停；切窗口自动暂停；**全屏按钮**（Fullscreen API，Esc 退出）
- 视觉：星空视差背景 + 极光星云（呼应 AuroraBackground）、发光蛇身（青→紫渐变）、带环行星、粒子与浮字特效、死亡震屏
- 本地最高分存 `localStorage`（`aurora_snake_best`）；联网成绩走 `/api/game` 接口

### 10.2 数据库变更

执行 `springBootTest/migrate-game-score.sql`（幂等）：

- 新表 `game_score`（id, user_id, nickname 快照, score, length, duration, created_at）
- 排名口径：分数 DESC → duration ASC → id ASC；`idx_game_score_rank` 联合索引

### 10.3 新增后端接口

| 方法 | 路径 | 登录 | 说明 |
|---|---|---|---|
| POST | `/api/game/scores` | 是 | 提交成绩 `{score, length, duration}` → `{message, score, best, isNewBest, rank, playCount, leaderboard}` |
| GET | `/api/game/leaderboard?limit=10` | 否 | 排行榜 Top N（1~50）→ `{list: [ScoreItem]}` |
| GET | `/api/game/my-best` | 是 | 我的最好成绩 → `{best, rank, playCount}` |

- 新增文件：`entity/GameScore.java`、`mapper/GameScoreMapper.java`、`service/GameScoreService.java`、`controller/GameController.java`、`dto/ScoreRequest.java`、`dto/ScoreItem.java`（record）
- 昵称由服务端按 userId 反查（`userMapper.selectById`），客户端伪造不了；分数/长度/时长均有 `@Valid` 上限校验

### 10.4 前端文件

- 新增：`src/components/SpaceSnake.vue`、`src/api/game.js`
- 改动：`App.vue`（视图状态机新增 `game` 分支）、`SiteNav.vue`（菜单新增「游戏」）、`AboutPage.vue`（特性卡片 + 简介）
- `style.css`：**修复「不能滑动」**——`body` 原写死 `overflow:hidden`，窗口矮于登录卡时内容被裁剪且无法滚动；改为 `overflow-y:auto` + `place-items:safe center`（内容超高时从顶部排列，避免居中裁剪）

### 10.5 验证记录（2026-10-19 全部通过）

- `mvnw compile` BUILD SUCCESS；`npm run build` 44 modules 零错误
- 接口冒烟：未登录提交 401、`limit=0` 回落默认 10、越界 score 400（`@Valid`）、正常提交返回 rank + 最新榜单、`my-best` 无成绩时 best=0
- 前端：游戏页渲染 / 开始 / 暂停 / 重开 / 结算遮罩 / 提交按钮状态机均按预期（构建 + 逻辑走查）



---

## 十一、2026-10-23 交互与站点结构补全（后端接口 + 前端页面）

### 11.1 后端

**新增表（幂等脚本 `springBootTest/migrate-history-like.sql`）**：`read_history`（浏览历史）、`article_like`（点赞），均为 user_id + article_id 联合唯一。

**新增接口**

| 方法 | 路径 | 登录 | 说明 |
|---|---|---|---|
| POST | `/api/history/{articleId}` | 是 | 记录浏览（重复浏览只刷新时间） |
| GET | `/api/history?page=&size=` | 是 | 浏览历史（按浏览时间倒序，带 viewedAt） |
| DELETE | `/api/history/{articleId}` | 是 | 删除一条 |
| DELETE | `/api/history` | 是 | 清空，返回 removed |
| POST | `/api/likes/{articleId}` | 是 | 点赞 → `{ liked, likes }` |
| DELETE | `/api/likes/{articleId}` | 是 | 取消点赞 → `{ liked, likes }` |
| GET | `/api/likes/ids` | 是 | 我点赞过的 id |
| GET | `/api/likes/{articleId}/count` | 否 | 某文章点赞数 |
| GET | `/api/user/profile` | 是 | 个人中心汇总 `{ user, stats:{favorites,history,likes}, game }` |

关键类：`HistoryService` / `LikeService` / `ProfileService` + 三个 Controller；
`dto/HistoryItem`（`@JsonIgnore` 掉 tagsRaw，对外只给拆好的 tags 数组）；
`ArticleService.detail` 新增 `liked` / `likes` 两个字段。

**数据**：`migrate-article-content.sql`（幂等）把 8 篇技术文章的正文从 ~150 字补全到 ~1300 字 / 6 段（详情页按空行分段渲染）。

**启动脚本**：`启动后端.bat` / `启动前端.bat` 内置 `:killport`，启动前先结束占用 8081 / 5173 的残留进程 —— 解决「二次启动直接崩在端口被占用」。

### 11.2 前端

新增：`api/{history,likes,profile}.js`、`composables/useToast.js`、`components/{ToastHost,StateBlocks,SiteFooter,ProfilePage}.vue`。
改动：`App.vue`（新增 profile 视图 + 全局 ToastHost + 全站页脚）、`SiteNav.vue`（菜单加「我的」，头像可点）、
`ArticleDetail.vue`（点赞按钮 + 浏览历史上报 + 阅读时长 + 点赞数）、
`HomePage/DiscoverPage/FavoritesPage`（操作结果改走 Toast）、`AboutPage.vue`（功能一览 + 项目结构）。

- **Toast**：`toast.success/error/info()`，模块级单例，最多 3 条、悬停暂停、点击关闭
- **StateBlocks**：`variant="skeleton|empty|error"`，骨架屏带微光动画，空/错误态带行动按钮
- **页脚**：登录页与全屏游戏页不显示（App 里按 view 判断）

### 11.3 验证记录

- `mvnw -o compile` BUILD SUCCESS；`npm run build` 59 modules 零错误
- 接口冒烟：profile / history 增删改查 / likes 增删 / ids / count / 详情 liked+likes 全通过
- 文章详情返回 6 段正文、likes=1、liked=true

### 11.4 踩坑

- **Vue SFC 报「Element is missing end tag」**：文件末尾漏了 `</style>`，报错位置会指向 `<style>` 那一行而不是文件末尾，容易误判
- **改 GBK 中文 .bat 禁用 `sed -i`**：会丢掉 CR，cmd 解析崩坏（本次用 `iconv` 转 GBK + `tr/sed` 重建 CRLF）

---

## 十二、2026-10-26 机器重置后的恢复流程（重要：重置会连数据库一起清空）

### 12.1 重置实际会丢什么（比原先记录的更严重）

原先文档只记了 `node_modules` / `target` 被删。实测本次重置后**数据库 `springboot_test` 也被清了**，不只是编译产物：

| 项目 | 重置后的状态 |
|---|---|
| `aurora-vue-2/node_modules` | 消失 → `npm install`（约 30 秒，31 个包） |
| `springBootTest/target` | 消失 → `mvnw.cmd compile` |
| `~/.m2/repository` 中**本项目专用依赖** | 消失（mybatis-plus **3.5.9** spring-boot3-starter、mybatis-plus-jsqlparser 3.5.9、jjwt **0.12.6**） |
| 数据库 `user` 表 | **0 行**，测试账号没了 |
| 数据库 `favorite` / `game_score` / `read_history` / `article_like` | **整表不存在** |
| 《凡人修仙传》5 篇小说文章 | 丢失，article 从 13 篇掉回 8 篇 |

### 12.2 一键恢复（推荐）

双击 **`ja5-main\恢复数据.bat`**（GBK + CRLF），按序跑 8 个幂等脚本并重建测试账号：

```
init-db.sql → migrate-category.sql → migrate-novel.sql → migrate-novel-more.sql
→ migrate-favorite.sql → migrate-game-score.sql → migrate-history-like.sql → migrate-article-content.sql
```

恢复后基准值：**文章 19 / 分类 6 / 标签 37 / 用户 1**（`verify用户` / `abc12345`，id=2）。

### 12.3 手动恢复命令

```bash
# 前端依赖
cd ja5-main/aurora-vue-2 && npm install --no-audit --no-fund

# 后端依赖（注意：不要加 -o，见 12.4）
cd ja5-main/springBootTest && ./mvnw.cmd -B compile
```

测试账号密码哈希用后端同款 BCrypt 生成（**不要**用 `BCryptPasswordEncoder`，它在单文件模式缺 commons-logging 依赖）：

```bash
java -cp "C:/Users/Administrator/.m2/repository/org/springframework/security/spring-security-crypto/6.4.5/spring-security-crypto-6.4.5.jar" Hash2.java abc12345
# Hash2.java: System.out.println(BCrypt.hashpw(a[0], BCrypt.gensalt(10)));
```

### 12.4 关键修正：`mvnw -o`（离线）在本机已不可用

11.3 写的「`mvnw -o compile` BUILD SUCCESS」**已失效**——`~/.m2` 里只剩别的项目的旧版本（mybatis-plus 3.5.1、jjwt 0.9.1），本项目要的 3.5.9 / 0.12.6 不在缓存里，离线模式必然报 `Cannot access aliyunmaven in offline mode`。

> 结论：重置后首次编译**必须联网**（阿里云镜像可用，实测约 28 秒拉完）。联网拉一次后本地才重新有缓存。
> 另：`java -cp` 在 bash 里必须传 **Windows 盘符路径**（`C:/...`），MSYS 的 `/c/...` 路径 JVM 认不到。

### 12.5 验证记录（2026-10-26 全部通过）

- `npm install` 31 包 / `npm run build` 59 modules 零错误
- `mvnw -B compile` BUILD SUCCESS；`spring-boot:run` 正常起在 8081
- 接口冒烟：captcha ✓ / login（verify用户 + abc12345，返回 token）✓ / 搜索「凡人」5 条 ✓
- profile `{user,stats,game}` ✓ / history ✓ / likes/ids ✓ / game/leaderboard ✓

### 12.6 启动脚本路径 bug（已修，双击仍起不来的元凶）

`启动前端.bat` / `启动后端.bat` 是项目还在**仓库根目录**时写的，里面是：

```
cd /d "%~dp0ja5-main\aurora-vue-2"     ← 错
cd /d "%~dp0ja5-main\springBootTest"   ← 错
```

但这两个 bat 现在位于 `ja5-main\` 内，`%~dp0` 已经是 `...\ja5-main\`，再拼一层就变成
不存在的 `ja5-main\ja5-main\aurora-vue-2` → 脚本一运行立即失败。

**正确写法**（`%~dp0` 直接拼子目录）：

```
cd /d "%~dp0aurora-vue-2"
cd /d "%~dp0springBootTest"
```

> 修改 GBK 中文 .bat 后**必须重建 CRLF**：用 `iconv` 转码或 `sed` 处理会吃掉 CR，
> cmd 解析会崩坏（表现是脚本一闪而过、中文变乱码）。改完用 `xxd` 确认行尾是 `0d 0a`。
> 本目录所有 .bat 均为 **GBK + CRLF**，新增脚本请用
> `iconv -f UTF-8 -t GBK xx.bat | sed 's/$/\r/' > tmp && mv tmp xx.bat` 转换。

### 12.7 沙盒内起的服务不持久

`npm run dev` / `spring-boot:run` 在 AI 沙盒后台跑，进程会被回收（实测后端启动成功
2 秒、运行约 26 秒后即被终止，日志无应用级错误）。**只能用于冒烟验证**。
要长期运行请让用户双击 `启动项目.bat`，在用户自己的会话里不会被回收。

---

## 十三、2026-11-04 启动链路重写（快 2~3 倍 + 一键就绪）

### 13.1 项目路径已变

**当前路径：`D:\workSpace\ja5\ja5-main`**（本文档前面章节写的 `C:\Users\Administrator\Desktop\ja3-main`
是历史路径，已失效；脚本内部统一用 `%~dp0` 相对定位，换目录不用改脚本）。

### 13.2 实测数据（同一台机器，热启动）

| 环节 | 旧做法 | 新做法 | 结果 |
|---|---|---|---|
| 后端就绪 | `mvnw spring-boot:run` **11.2 s** | 增量编译 + `java -cp` 直启 **≈7 s**（无改动编译 3.9 s + JVM 3.5 s） | ↓ 约 40% |
| 后端依赖解析 | 每次 Maven 全量启动 | `classpath.txt` 缓存，仅 pom 变更时重算 | 省 4 s |
| 前端就绪 | `npm run dev` **3.4 s** | `node node_modules/vite/bin/vite.js` **1.4 s** | ↓ 约 60% |
| 冷启动 | 两个窗口各跑各的，人工判断好了没 | 并行 + 健康检查 + 自动开浏览器 | 少等一轮 |
| 一键启动 | 无就绪反馈 | 主控轮询 `/api/auth/captcha` 与 `/`，3~8 s 后自动打开页面 | 可感知 |

### 13.3 新脚本分工

```
启动项目.bat   主控：环境检查 → 清端口 → 数据库自检(可选自动恢复) → 并行拉起两端 → 健康检查 → 开浏览器
启动后端.bat   单启后端：依赖 classpath 缓存 → mvnw -o 增量编译 → java 直启（前台，Ctrl+C 停）
启动前端.bat   单启前端：依赖缺了才装 → node 直启 vite
停止项目.bat   按端口结束进程（不再按进程名批量杀 java/node，避免误杀别的项目）
恢复数据.bat   7 个幂等迁移 + 测试账号 + migrate-admin 提权（新增，之前漏了）
```

要点：
- **后端不再走 `spring-boot:run`**：该插件在离线模式下会因 `spring-boot-loader-tools` 等
  插件依赖缺失**直接报错退出**（本次实测 `mvnw -o spring-boot:run` 必失败）。改为
  `dependency:build-classpath` 生成 `target/classpath.txt` + `java -cp` 直启，**离线可用**。
- 编译仍走 Maven（`-o` 优先，失败自动切联网），保证增量编译正确性。
- JVM 参数 `-XX:TieredStopAtLevel=1 -Xss512k -Dspring.jmx.enabled=false`：开发环境只做
  C1 编译换启动速度；devtools 热重启依然生效（日志里 `restartedMain` 可见）。

### 13.4 本次踩的三个坑（改脚本必看）

1. **`set /p` 只能读 1024 字符**：classpath.txt 有 7.3 KB，`set /p DEPCP=<target\classpath.txt`
   会静默截断，表现为 `NoClassDefFoundError: BCryptPasswordEncoder`（前 1KB 里没有这个 jar）。
   必须用 `for /f "usebackq delims=" %%L in ("target\classpath.txt") do set "DEPCP=%%L"`。
2. **`!VAR!` 需要 `setlocal enabledelayedexpansion`**，否则原样传到命令行；
   反之 `%VAR%` 在 `( )` 块内会在解析时就展开。两种写法别混用。
3. **`call :sub && set X=1` 的坑**：`if 条件 call :sub && set ...` 里条件为假时 `if` 本身
   返回 0，`&&` 后的语句**仍会执行**。要写成 `( call :sub \n if errorlevel 1 set ... )`。

### 13.5 数据库自检

主控会查 `springboot_test.article` 是否有数据；缺失时用 `choice` 询问（15 秒默认 Y），
同意后调用 `恢复数据.bat`（幂等）。这样「开机后库被清空」不再需要人工先跑恢复脚本。

### 13.6 沙盒里跑不起来/被回收时的替代验证法

沙盒内 `agent-browser` 守护进程会卡住，可用已下载的 Chrome 直接截图验证 UI：

```bash
"/c/Users/Administrator/.agent-browser/browsers/chrome-157.0.8103.38/chrome.exe" \
  --headless=new --disable-gpu --no-sandbox --hide-scrollbars \
  --window-size=1440,3000 --virtual-time-budget=15000 \
  --screenshot="C:/tmp/home.png" "http://localhost:5173/"
```

登录态怎么造：`POST /api/auth/login` 拿 token → 在 `aurora-vue-2/public/` 放一个临时
`__seed.html`（写 `localStorage.setItem('aurora_token', token)` 后 `location.replace('/')`），
截完图记得删掉，别提交。


补充：Chrome 的 `--window-size` 有最小窗口宽度，窄屏（如 390）会被裁切而不是重新布局。
要看真实移动端，用 CDP 覆盖视口：

```js
await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 2, mobile: true })
await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true })
```

（`chrome --headless --remote-debugging-port=9333` 起进程，再用 Node 内置 WebSocket 走 CDP，
Node 18+ 无需装 puppeteer。）

---

## 十四、2026-11-04 首页改版（结构重排）

### 14.1 问题定位

对照截图（1440×900）确认，问题不在配色而在结构：首屏上方约 40% 是空白、13 篇文章同一规格平铺、
除第一张卡外全无封面、数据条 4 张玻璃卡纯占位、分类两行 chips 噪音、侧栏「今日星语」是随机文案、
HomePage 自带 footer 与 SiteFooter 重复渲染。

### 14.2 改动

| 位置 | 改动 |
|---|---|
| `components/HomePage.vue` | 模板与样式重写；脚本逻辑（检索/分页/无限滚动/收藏/跨页筛选）**原样保留** |
| `components/PickCard.vue` | 新增：带封面的精选卡，`lead` 变体用作首屏头条 |
| `components/ArticleRow.vue` | 新增：紧凑列表行（小封面 + 标题 + 元信息 + 浏览数） |
| `utils/cover.js` | 新增：按文章 id 轮转 `public/covers/*.jpg`，三个卡片组件共用 |
| `ArticleCard.vue` | **未改动**（发现页 / 收藏页继续用它，零回归风险） |

新结构：Hero 左文案右头条 → 内联指标条 → 单行分类 tab（选中后展开二级标签）→ 精选三列 + 列表行 →
侧栏（热门榜单 / 分类分布 / 继续探索 + 随便逛逛）。删掉「今日星语」与页面自带 footer。

### 14.3 几个判断规则（改的时候别踩）

- `showPicks = !hasFilter && list.length > 3`：搜索/筛选结果里每条命中项地位相同，**不要**硬挑三条当精选。
- 精选取 `list.slice(0,3)`，列表行取 `slice(3)`；无限滚动追加的分页只进列表行。
- 头条取 `pool[0] || list[0]`：`pool` 是全站最热 50 条，比当前列表更稳。
- **类名别用 `.tabs` / `.tab`**：`style.css` 里给登录页 tabs 写过 `.tabs{background/padding}` 和 `.tab{flex:1}`，
  冲突会让首页分类按钮被均分撑满整行。本次改用 `.cat-tabs` / `.cat-tab`。

### 14.4 验证记录

- `npm run build` 65 modules 通过（改版前 59）
- CDP 实测三种状态：默认态（精选 3 + 列表 7 + 共 13 条）、点「前端」（精选隐藏、2 条、二级标签展开）、
  搜索「凡」+ 前端筛选（0 条、面包屑同时显示关键词与分类）
- 1440 / 1024 / 390 三个宽度：`document.scrollWidth == clientWidth == 390`，无横向溢出

### 14.5 已知未做

- `SiteNav` 在 ≤900px 直接 `display:none` 掉菜单，**移动端没有导航入口**（首页改版前就存在，本次未动）
- 首页「更新节奏」热力图没做：缺按日期的发布/浏览量数据，需要后端补统计接口

---

## 十五、2026-11-10 启动体系重写（.bat 只做壳，逻辑全在 PowerShell）

### 15.1 为什么要重写

「双击 启动后端.bat 没反应 / 一闪就退，登录页注册登录进不去首页」的排查结论：
**前端 5173 在跑，后端 8081 压根没启动**（`log/springboot-test.log` 无当日记录），
Vite 代理连不上 8081 返回 `500 + text/plain`，前端只能显示「请求失败，请稍后再试」，
看起来像地址写错，其实是后端没起来。

旧 .bat 的问题在于：所有逻辑（编码、CRLF、`%~dp0` 尾反斜杠、`!VAR!` 延迟展开、
`set /p` 截断、`start /d "%~dp0"` 引号转义）都写在批处理里，一旦出错窗口一闪就没了，
且没有任何日志可查。

### 15.2 新结构

```
ja5-main\
├─ 启动后端.bat / 启动前端.bat / 启动项目.bat / 停止项目.bat   ← 纯 ASCII 三行壳，只负责调用 ps1
├─ scripts\
│   ├─ start-backend.ps1    后端：定位 java → 清端口 → 依赖 classpath → 按需增量编译 → java -cp 直启
│   ├─ start-frontend.ps1   前端：定位 node → 清端口 → 缺依赖才 npm install → node vite.js
│   ├─ start-all.ps1        一键：环境检查 → 清端口 → 库自检 → 各开一个窗口 → 健康检查 → 开浏览器
│   └─ stop-all.ps1         按端口停 5173 / 8081（不按进程名杀，避免误杀）
└─ logs\                     每次启动一份 backend-*.log / frontend-*.log / start-all-*.log
```

- `.bat` 内容固定为：`powershell -NoProfile -ExecutionPolicy Bypass -NoLogo -File "%~dp0scripts\xxx.ps1"`
  **纯 ASCII + CRLF**，不写一个中文，从根上消灭编码坑
- `.ps1` 统一 **UTF-8 带 BOM + CRLF**（PS 5.1 读无 BOM 的 UTF-8 中文会乱码，必须带 BOM）
- 失败时窗口不关，会打出 `[错误] xxx`，并把全过程写进 `logs\`

### 15.3 本机环境的新事实（2026-11-10 实测）

| 项 | 值 |
|---|---|
| 项目路径 | `C:\Users\duan\Desktop\jage\ja5-main`（13.1 写的 `D:\workSpace\ja5` 已过期） |
| JDK | **25.0.2**，真实路径 `D:\Program Files\Java\jdk-25.0.2`；另有 `C:\Program Files\Java\jdk-17` |
| `JAVA_HOME` | **未设置** |
| MySQL | **8.4**（`C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe`），root/123456 正常 |
| Node | `E:\node\node.exe`（v22.23.4，系统 PATH） |

**头号坑：PATH 里的 `java` 是 Oracle javapath 转发桩**
`C:\Program Files\Common Files\Oracle\Java\javapath\java.exe` —— cmd 里能正常跑，
但 **PowerShell 会把它当「文档」拒绝执行**，报 `CannotActivateDocumentInPipeline`。
所以 `start-backend.ps1` 里显式跳过 javapath，改为扫 `C:\/D:\Program Files\Java` 下的
真实 JDK 目录并按主版本号取最新（优先 JAVA_HOME）。

### 15.4 其它修正

- `恢复数据.bat` 里写死的 `MySQL Server 8.0` 路径 → 改成 `for /d` 通配匹配 `MySQL Server *`，
  8.0/8.4/9.x 都能找到（这是「启动项目.bat 一进来就报库未就绪」的原因之一）
- `启动项目.bat` 原来用 `start ... /d "%~dp0"`，`%~dp0` 结尾的反斜杠会和闭合引号粘连，
  可能直接「系统找不到指定的路径」→ 新方案改为在 ps1 里 `Start-Process -WorkingDirectory`，无此问题

### 15.5 AI 沙盒的限制（重要，别再试了）

- **cmd.exe 被完全拦截**：Bash 调 `cmd.exe` 直接报「Invoking cmd.exe from Bash bypasses all command validation」；
  PowerShell 工具调 `cmd /c` 报「cmd.exe cannot be used from the PowerShell tool」。所以 **.bat 无法在沙盒里验证**
- **PowerShell 工具无法执行任何原生程序**：`& 'C:\Windows\System32\whoami.exe'` 静默零输出、
  `$LASTEXITCODE` 为空（`java.exe`、`node.exe` 同理）。ps1 里的「启动进程」这一步只能由用户实测
- 能在沙盒里做的：`[System.Management.Automation.Language.Parser]::ParseFile()` 语法校验（推荐每次都跑）
- curl 打本地端口前必须去掉注入的代理：
  `env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy curl ...`（否则得到假 502）
- bash 里 `java ... &` 起的后端能活 1~5 分钟，之后被回收 → 只能用于冒烟，不能当常驻服务

### 15.6 冒烟记录（2026-11-10）

- 后端手工 `java -cp target/classes;target/classpath.txt` 起在 8081：登录 `verify用户/abc12345` 直连与经 5173 代理均 200
- 用真实验证码走 `/api/auth/register`：新建 userId=3 → 立即登录成功（测试账号已从库中删除）
- `mvnw.cmd -B -q -o -DskipTests compile`：BUILD SUCCESS（仅 JDK25 的 jansi/Unsafe 警告）
- `npm run build`：71 modules 通过（本次改了 `src/api/http.js`）
- 4 个 ps1：ParseFile 全部 OK，BOM 齐全；`.bat` 壳为纯 ASCII + CRLF

### 15.7 前端错误提示改进

`src/api/http.js` 新增 `OFFLINE_MSG`：fetch 直接 reject（后端没起）或拿到**非 JSON 的 5xx**
（后端有 GlobalExceptionHandler，正常出错必回 JSON，所以非 JSON 5xx 必是代理连不上）时，
提示「连不上后端服务，请确认后端已在 8081 端口启动（双击 启动项目.bat）」，
不再让用户去猜「是不是地址错了」。

### 15.8 二次修正：后台运行版（2026-11-10 18:06，以本节为准）

- 前后端改为 `Start-Process` **后台独立运行**，不再依赖两个黑窗口保持打开；启动成功后关闭窗口不会停止服务
- Java 禁用 devtools 自动重启（`-Dspring.devtools.restart.enabled=false`），避免开发期热重启造成状态误判
- 运行输出分别写入 `logs/backend-runtime-*`、`logs/frontend-runtime-*`；PID 写入 `run/*.pid`（已 gitignore）
- `启动项目.bat` 最后必须验证 **`http://127.0.0.1:5173/api/auth/captcha`**，即浏览器登录/注册真正走的链路，
  而不是只检查 8081 端口；通过后才打开浏览器
- Vite 代理目标固定为 **`http://127.0.0.1:8081`**，避免 Windows/Node 将 localhost 解析到 ::1 的兼容问题
- 实测：`localhost` / `127.0.0.1` / `192.168.1.5` 的 5173 页面与验证码接口均 200；
  `verify用户 / abc12345` 登录成功；真实验证码注册临时账号并立即登录成功（临时账号已删除）
- 前端默认勾选「记住我」，`App.vue` 在挂载时若发现 `localStorage.aurora_token`，会调用 `/auth/me`
  并直接进入首页。这是自动恢复登录，不是跳过认证；点导航栏「退出登录」或用无痕窗口即可看到登录/注册页。
- 后台运行版只明确打印一个推荐地址 **`http://localhost:5173/`**，这是有意为之；本机使用不需要 Network 地址。
