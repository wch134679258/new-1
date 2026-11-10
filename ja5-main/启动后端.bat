@echo off
chcp 936 >nul
setlocal
title springBootTest 8081
rem ============================================================
rem  This .bat is only a launcher (pure ASCII, no encoding traps).
rem  All logic lives in scripts\start-backend.ps1
rem ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -NoLogo -File "%~dp0scripts\start-backend.ps1"
set "RC=%errorlevel%"
echo.
if not "%RC%"=="0" echo [exit code %RC%] - see logs under ja5-main\logs\ for details
echo Press any key to close this window...
pause >nul
endlocal
