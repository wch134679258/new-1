@echo off
chcp 936 >nul
setlocal
title aurora-vue-2 5173
rem ============================================================
rem  This .bat is only a launcher (pure ASCII, no encoding traps).
rem  All logic lives in scripts\start-frontend.ps1
rem ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -NoLogo -File "%~dp0scripts\start-frontend.ps1"
set "RC=%errorlevel%"
echo.
if not "%RC%"=="0" echo [exit code %RC%] - see logs under ja5-main\logs\ for details
echo Press any key to close this window...
pause >nul
endlocal
