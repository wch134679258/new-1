# ============================================================
#  一键启动：后台启动前后端，并通过前端地址验证真实登录链路。
#  成功后可关闭本窗口；前后端继续运行。
# ============================================================

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.Encoding]::UTF8

$root = Split-Path -Parent $PSScriptRoot
$beScript = Join-Path $PSScriptRoot 'start-backend.ps1'
$feScript = Join-Path $PSScriptRoot 'start-frontend.ps1'
$logDir = Join-Path $root 'logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$log = Join-Path $logDir ('start-all-{0}.log' -f (Get-Date -Format 'yyyyMMdd'))

function Say {
    param([string]$msg, [string]$color = 'Gray')
    Write-Host $msg -ForegroundColor $color
    try { Add-Content -Path $log -Value ('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $msg) -Encoding UTF8 } catch {}
}
function Test-PortListen {
    param([int]$p)
    try { return [bool](Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction Stop) } catch { return $false }
}
function Find-MySql {
    $dirs = Get-ChildItem 'C:\Program Files\MySQL' -Directory -ErrorAction SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName 'bin\mysql.exe') } | Sort-Object Name -Descending
    foreach ($d in $dirs) { return (Join-Path $d.FullName 'bin\mysql.exe') }
    $g = Get-Command mysql.exe -ErrorAction SilentlyContinue
    if ($g) { return $g.Source }
    return $null
}
function Test-LoginChain {
    # 必须走 5173，而不是只测 8081：这正是浏览器登录/注册使用的路径。
    try {
        $r = Invoke-WebRequest -Uri 'http://127.0.0.1:5173/api/auth/captcha' -UseBasicParsing -TimeoutSec 3
        return ($r.StatusCode -eq 200 -and $r.Content -match 'captchaId')
    } catch { return $false }
}

Say '================================================' 'Cyan'
Say '  ja5-main 一键启动（后台运行版）' 'Cyan'
Say '  前端 http://localhost:5173/' 'Cyan'
Say '  后端 http://localhost:8081' 'Cyan'
Say '================================================' 'Cyan'
foreach ($v in 'HTTP_PROXY','HTTPS_PROXY','http_proxy','https_proxy','NO_PROXY','no_proxy') {
    Remove-Item "Env:$v" -ErrorAction SilentlyContinue
}

Say '[1/4] 检查 MySQL...'
if (-not (Test-PortListen 3306)) {
    Say '  [错误] MySQL 3306 未监听，请先启动 MySQL 服务' 'Red'
    exit 1
}
$mysql = Find-MySql
$articleCount = ''
if ($mysql) {
    $oldEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & $mysql -uroot -p123456 -N -B -e 'SELECT COUNT(*) FROM springboot_test.article' 2>$null
        if ($out) { $articleCount = ($out | Select-Object -First 1).ToString().Trim() }
    } catch {} finally { $ErrorActionPreference = $oldEap }
}
if ($articleCount -and $articleCount -ne '0') {
    Say "      MySQL 正常，文章 $articleCount 篇" 'Green'
} else {
    Say '      MySQL 已启动；文章数据自检未通过（不阻塞登录测试）' 'Yellow'
}

Say '[2/4] 启动后端...'
& $beScript
Say '[3/4] 启动前端...'
& $feScript

Say '[4/4] 通过前端地址检查验证码/登录链路...'
$ready = $false
for ($i = 0; $i -lt 15; $i++) {
    if (Test-LoginChain) { $ready = $true; break }
    Start-Sleep -Seconds 2
}

if (-not $ready) {
    Say '  [错误] 前端页面可能已打开，但 /api/auth/captcha 仍未通过' 'Red'
    Say '         请查看 logs 目录最新的 backend-runtime / frontend-runtime 日志' 'Yellow'
    exit 1
}

Say ''
Say '  [成功] 登录、注册所需接口已经通过真实链路检查' 'Green'
Say '  请使用：http://localhost:5173/' 'Green'
Say '  现在可以关闭本窗口，前后端不会停止' 'Green'
Say '  停止项目：双击 停止项目.bat' 'Green'
Start-Process 'http://localhost:5173/' | Out-Null
