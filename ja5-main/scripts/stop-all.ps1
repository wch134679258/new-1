# ============================================================
#  停止项目：结束后台前后端，不按进程名误杀其他 Java/Node 项目。
# ============================================================

$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path -Parent $PSScriptRoot
$runDir = Join-Path $root 'run'
$logDir = Join-Path $root 'logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$log = Join-Path $logDir ('stop-{0}.log' -f (Get-Date -Format 'yyyyMMdd'))

function Say {
    param([string]$msg, [string]$color = 'Gray')
    Write-Host $msg -ForegroundColor $color
    try { Add-Content -Path $log -Value ('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $msg) -Encoding UTF8 } catch {}
}

Say '================================================' 'Cyan'
Say '  停止 ja5-main（5173 / 8081）' 'Cyan'
Say '================================================' 'Cyan'

foreach ($item in @(@('backend.pid','后端'), @('frontend.pid','前端'))) {
    $file = Join-Path $runDir $item[0]
    if (-not (Test-Path $file)) { continue }
    $savedPid = (Get-Content $file -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($savedPid -match '^\d+$') {
        $p = Get-Process -Id ([int]$savedPid) -ErrorAction SilentlyContinue
        if ($p) {
            Say "  $($item[1]) PID=$savedPid 正在结束..." 'Yellow'
            Stop-Process -Id ([int]$savedPid) -Force -ErrorAction SilentlyContinue
        }
    }
    Remove-Item $file -Force -ErrorAction SilentlyContinue
}

Start-Sleep -Milliseconds 500
foreach ($item in @(@(5173,'前端'), @(8081,'后端'))) {
    $port = $item[0]; $name = $item[1]
    try {
        $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop
        foreach ($c in $conns) {
            Say "  $name ($port) 仍有 PID=$($c.OwningProcess)，正在结束..." 'Yellow'
            Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Say "  $name ($port) 已停止" 'DarkGray'
    }
}

Start-Sleep -Milliseconds 500
$still = @()
foreach ($p in 5173, 8081) {
    try { if (Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction Stop) { $still += $p } } catch {}
}
Say ''
if ($still.Count -eq 0) { Say '  已全部停止' 'Green' }
else { Say "  [警告] 端口 $($still -join ', ') 仍被占用" 'Yellow' }
