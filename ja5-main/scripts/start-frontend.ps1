# ============================================================
#  前端启动（aurora-vue-2，5173）
#  Vite 在后台独立运行；关闭本窗口不会停止前端。
# ============================================================

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.Encoding]::UTF8

$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'aurora-vue-2'
$port = 5173
$logDir = Join-Path $root 'logs'
$runDir = Join-Path $root 'run'
foreach ($dir in @($logDir, $runDir)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}
$log = Join-Path $logDir ('frontend-{0}.log' -f (Get-Date -Format 'yyyyMMdd'))

function Say {
    param([string]$msg, [string]$color = 'Gray')
    Write-Host $msg -ForegroundColor $color
    try { Add-Content -Path $log -Value ('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $msg) -Encoding UTF8 } catch {}
}
function Fail {
    param([string]$msg)
    Say ''
    Say "  [错误] $msg" 'Red'
    exit 1
}
function Test-Frontend {
    try {
        $r = Invoke-WebRequest -Uri 'http://127.0.0.1:5173/' -UseBasicParsing -TimeoutSec 2
        return ($r.StatusCode -eq 200)
    } catch { return $false }
}

Say '================================================' 'Cyan'
Say '  启动前端 aurora-vue-2（后台运行）' 'Cyan'
Say '================================================' 'Cyan'
if (-not (Test-Path $app)) { Fail "找不到前端目录：$app" }
foreach ($v in 'HTTP_PROXY','HTTPS_PROXY','http_proxy','https_proxy','NO_PROXY','no_proxy') {
    Remove-Item "Env:$v" -ErrorAction SilentlyContinue
}

if (Test-Frontend) {
    Say '  前端已经在运行：http://localhost:5173/' 'Green'
    return
}

$node = $null
$g = Get-Command node.exe -ErrorAction SilentlyContinue
if ($g) { $node = $g.Source }
if (-not $node) {
    foreach ($c in @('C:\Program Files\nodejs\node.exe','D:\Program Files\nodejs\node.exe','E:\node\node.exe')) {
        if (Test-Path $c) { $node = $c; break }
    }
}
if (-not $node) { Fail '找不到 Node.js 18+，请安装后加入 PATH' }
Say "[1/3] Node：$node"

try {
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop
    foreach ($c in $conns) {
        Say "[2/3] 清理占用 5173 的旧进程 PID=$($c.OwningProcess)" 'Yellow'
        Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Milliseconds 600
} catch {
    Say '[2/3] 端口 5173 空闲'
}

Set-Location $app
$viteJs = Join-Path $app 'node_modules\vite\bin\vite.js'
if (-not (Test-Path $viteJs)) {
    Say '[3/3] 依赖缺失，正在 npm install...'
    $g = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if (-not $g) { Fail '找不到 npm.cmd，请检查 Node.js 安装' }
    & $g.Source install --prefer-offline --registry=https://registry.npmmirror.com --no-audit --no-fund --loglevel=error 2>&1 |
        ForEach-Object { Write-Host "      $_" }
    if (-not (Test-Path $viteJs)) { Fail 'npm install 失败，node_modules 中没有 Vite' }
} else {
    Say '[3/3] 前端依赖已就绪'
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stdout = Join-Path $logDir "frontend-runtime-$stamp.log"
$stderr = Join-Path $logDir "frontend-error-$stamp.log"
try {
    $process = Start-Process -FilePath $node -ArgumentList @(('"' + $viteJs + '"')) -WorkingDirectory $app `
        -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
} catch {
    Fail "Vite 启动失败：$($_.Exception.Message)"
}
Set-Content -Path (Join-Path $runDir 'frontend.pid') -Value $process.Id -Encoding Ascii
Say "      PID=$($process.Id)"
Say "      运行日志：$stdout"

$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 2
    $process.Refresh()
    if ($process.HasExited) { break }
    if (Test-Frontend) { $ready = $true; break }
}
if (-not $ready) {
    if (Test-Path $stderr) { Get-Content $stderr -Tail 25 | ForEach-Object { Say "      $_" 'Yellow' } }
    if (Test-Path $stdout) { Get-Content $stdout -Tail 15 | ForEach-Object { Say "      $_" 'Yellow' } }
    if ($process.HasExited) { Fail "前端进程已退出，退出码=$($process.ExitCode)" }
    Fail '前端进程仍在，但 60 秒内页面未就绪'
}

Say ''
Say '  [成功] 前端地址：http://localhost:5173/' 'Green'
Say '  接口代理：/api -> http://127.0.0.1:8081' 'Green'
Say '  关闭本窗口不会停止前端；停止请双击 停止项目.bat' 'Green'
