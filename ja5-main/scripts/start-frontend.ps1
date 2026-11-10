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
    # 5173 可能仍是另一份 jage 的 Vite。不能只凭 HTTP 200 就复用，
    # 否则从 D:\new-1 启动也会继续看到桌面旧项目。
    Say '  检测到 5173 已有前端，正在重启为当前目录版本...' 'Yellow'
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
$runtimeCore = Join-Path $app 'node_modules\@vue\runtime-core\dist\runtime-core.esm-bundler.js'
$compilerDom = Join-Path $app 'node_modules\@vue\compiler-dom\index.js'
$rollupNative = Join-Path $app 'node_modules\@rollup\rollup-win32-x64-msvc\rollup.win32-x64-msvc.node'

function Test-FrontendDeps {
    return (Test-Path $viteJs) -and (Test-Path $runtimeCore) -and (Test-Path $compilerDom) -and (Test-Path $rollupNative)
}

if (-not (Test-FrontendDeps)) {
    Say '[3/3] 前端依赖缺失或不完整，正在重新安装...'
    $npm = Join-Path (Split-Path -Parent $node) 'npm.cmd'
    if (-not (Test-Path $npm)) {
        $g = Get-Command npm.cmd -ErrorAction SilentlyContinue
        if ($g) { $npm = $g.Source }
    }
    if (-not $npm) { Fail '找不到 npm.cmd，请检查 Node.js 安装' }

    # npm 默认缓存目录在部分机器上没有写权限，会导致包只解压出一半。
    # 固定使用项目内缓存，并把完整输出写进日志，失败时能直接看到原因。
    $npmCache = Join-Path $app '.npm-cache'
    if (-not (Test-Path $npmCache)) { New-Item -ItemType Directory -Path $npmCache | Out-Null }
    $npmLog = Join-Path $logDir ('npm-install-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

    Say "      npm $npm"
    Say "      缓存 $npmCache"
    & $npm install --prefer-offline --cache $npmCache --registry=https://registry.npmmirror.com `
        --no-audit --no-fund --loglevel=error 2>&1 |
        Tee-Object -FilePath $npmLog | ForEach-Object { Write-Host "      $_" }

    if (-not (Test-FrontendDeps)) {
        Say '      首次安装不完整，正在联网强制补齐...' 'Yellow'
        & $npm install --force --cache $npmCache --registry=https://registry.npmmirror.com `
            --no-audit --no-fund --loglevel=error 2>&1 |
            Tee-Object -FilePath $npmLog -Append | ForEach-Object { Write-Host "      $_" }
    }

    if (-not (Test-FrontendDeps)) {
        Fail "前端依赖安装失败。请查看 $npmLog（通常是 npm 缓存损坏或网络问题）"
    }
    Say '      前端依赖安装完成'
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
