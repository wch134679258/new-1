@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
title 恢复数据库 springboot_test
cd /d "%~dp0"

echo ================================================
echo   数据库恢复脚本（机器重置 / 数据被清空时用）
echo   库: springboot_test    账号: root / 123456
echo   全部脚本幂等，可重复执行
echo ================================================
echo.

rem ---------- 定位 mysql 客户端 ----------
rem 不写死版本号：MySQL 8.0 / 8.4 / 9.x 都能找到（本机已升到 8.4）
set "MYSQL="
for /d %%D in ("C:\Program Files\MySQL\MySQL Server *") do if exist "%%~fD\bin\mysql.exe" set "MYSQL=%%~fD\bin\mysql.exe"
if not defined MYSQL for /d %%D in ("D:\Program Files\MySQL\MySQL Server *") do if exist "%%~fD\bin\mysql.exe" set "MYSQL=%%~fD\bin\mysql.exe"
if not defined MYSQL (
  where mysql >nul 2>nul && set "MYSQL=mysql"
)
if not defined MYSQL (
  echo [错误] 未找到 mysql 客户端，请确认 MySQL 已安装
  echo        预期路径: C:\Program Files\MySQL\MySQL Server <版本>\bin\mysql.exe
  pause
  exit /b 1
)

set "FAILED=0"

echo [1/4] 建库建表 + 内容迁移...for %%f in (
  init-db.sql
  migrate-category.sql
  migrate-novel.sql
  migrate-novel-more.sql
  migrate-favorite.sql
  migrate-game-score.sql
  migrate-history-like.sql
  migrate-article-content.sql
) do (
  echo   - %%f
  if "%%f"=="init-db.sql" (
    rem init-db.sql 自带 CREATE DATABASE，不能传库名
    "!MYSQL!" -uroot -p123456 --default-character-set=utf8mb4 < "springBootTest\%%f" >nul 2>nul
  ) else (
    "!MYSQL!" -uroot -p123456 --default-character-set=utf8mb4 springboot_test < "springBootTest\%%f" >nul 2>nul
  )
  if errorlevel 1 (
    echo     [失败] 上面这一步出错，可能是 MySQL 未启动
    set "FAILED=1"
  )
)

echo [2/4] 重建测试账号 verify用户 / abc12345 ...
"!MYSQL!" -uroot -p123456 --default-character-set=utf8mb4 springboot_test -e "INSERT INTO user (id, name, password) VALUES (2, 'verify用户', '$2a$10$5jB/x.hdAEwoToMk.Kj3ceSxrApIi/tzm8zMaWxf7YhB04gqhj7lW') ON DUPLICATE KEY UPDATE password = VALUES(password);" >nul 2>nul
if errorlevel 1 set "FAILED=1"

echo [3/4] 升级角色列并授予管理员（migrate-admin.sql）...
rem  依赖上一步的账号已存在，否则没人可提权
"!MYSQL!" -uroot -p123456 --default-character-set=utf8mb4 < "springBootTest\migrate-admin.sql" >nul 2>nul
if errorlevel 1 set "FAILED=1"

echo [4/4] 校验数据量...
"!MYSQL!" -uroot -p123456 --default-character-set=utf8mb4 springboot_test -e "SELECT (SELECT COUNT(*) FROM user) AS 用户数, (SELECT COUNT(*) FROM user WHERE role=1) AS 管理员数, (SELECT COUNT(*) FROM article) AS 文章数, (SELECT COUNT(*) FROM category) AS 分类数, (SELECT COUNT(*) FROM tag) AS 标签数;"

echo.
if "!FAILED!"=="1" (
  echo [警告] 有步骤失败，常见原因：MySQL 服务没启动
  echo        启动服务后重跑本脚本即可（脚本幂等）
  pause
  exit /b 1
)
echo 恢复完成。基准值：文章 19 / 分类 6 / 标签 37 / 用户 1 / 管理员 1
pause
exit /b 0
