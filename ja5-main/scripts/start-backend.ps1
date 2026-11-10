# ============================================================
#  后端启动（springBootTest，8081）
#  Java 在后台独立运行；关闭本窗口不会停止后端。
#  运行日志：logs\backend-runtime-*.log / backend-error-*.log
# ============================================================

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.Encoding]::UTF8

$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'springBootTest'
$port = 8081
$logDir = Join-Path $root 'logs'
$runDir = Join-Path $root 'run'
foreach ($dir in @($logDir, $runDir)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}
$log = Join-Path $logDir ('backend-{0}.log' -f (Get-Date -Format 'yyyyMMdd'))

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
function Test-Backend {
    try {
        $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8081/api/auth/captcha' -UseBasicParsing -TimeoutSec 2
        return ($r.StatusCode -eq 200)
    } catch { return $false }
}

Say '================================================' 'Cyan'
Say '  启动后端 springBootTest（后台运行）' 'Cyan'
Say '================================================' 'Cyan'
if (-not (Test-Path $app)) { Fail "找不到后端目录：$app" }

foreach ($v in 'HTTP_PROXY','HTTPS_PROXY','http_proxy','https_proxy','NO_PROXY','no_proxy',
               'SERVER_PORT','SERVER__PORT','SERVER_ADDRESS','SERVER__ADDRESS','SERVER_HOST','SERVER__HOST','MAVEN_OPTS') {
    Remove-Item "Env:$v" -ErrorAction SilentlyContinue
}

if (Test-Backend) {
    Say '  后端已经在运行，接口检查通过：http://localhost:8081/api/auth/captcha' 'Green'
    return
}

# 优先使用真实 JDK，跳过 Oracle javapath 转发桩。
$javaCandidates = @()
if ($env:JAVA_HOME) {
    $cand = Join-Path $env:JAVA_HOME 'bin\java.exe'
    if (Test-Path $cand) { $javaCandidates += $cand }
}
$javaRoots = @(
    'C:\Program Files\Java', 'D:\Program Files\Java', 'E:\Program Files\Java',
    'C:\Program Files\Zulu', 'C:\Program Files\Eclipse Adoptium', 'C:\Program Files\Microsoft\jdk'
)
foreach ($r in $javaRoots) {
    if (-not (Test-Path $r)) { continue }
    Get-ChildItem $r -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $cand = Join-Path $_.FullName 'bin\java.exe'
        if (Test-Path $cand) { $javaCandidates += $cand }
    }
}
$javaCandidates = $javaCandidates | Where-Object { $_ -notmatch 'jre' } |
    Sort-Object -Property @{ Expression = { if ($_ -match '(\d+)') { [int]$matches[1] } else { 0 } }; Descending = $true }
$java = $javaCandidates | Select-Object -First 1
if (-not $java) {
    $g = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($g -and $g.Source -notmatch 'Oracle\\Java\\javapath') { $java = $g.Source }
}
if (-not $java) { Fail '找不到可用的 JDK 17+。请设置 JAVA_HOME，或把真实 JDK 的 bin 目录加入 PATH' }
Say "[1/4] Java：$java"

# 端口被占用但没有健康接口时，清理旧进程。
try {
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop
    foreach ($c in $conns) {
        Say "[2/4] 清理占用 8081 的旧进程 PID=$($c.OwningProcess)" 'Yellow'
        Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Milliseconds 600
} catch {
    Say '[2/4] 端口 8081 空闲'
}

Set-Location $app
$cpFile = Join-Path $app 'target\classpath.txt'
$mvnw = Join-Path $app 'mvnw.cmd'
function Invoke-Maven {
    param([string[]]$mvnArgs, [string]$desc)
    Say "      $desc"
    if (-not (Test-Path $mvnw)) { return 1 }
    & $mvnw @mvnArgs 2>&1 | ForEach-Object {
        Write-Host "      $_"
        try { Add-Content -Path $log -Value "      $_" -Encoding UTF8 } catch {}
    }
    return $LASTEXITCODE
}

if (-not (Test-Path $cpFile)) {
    Say '[3/4] 首次运行，解析依赖 classpath...'
    $code = Invoke-Maven @('-B','-q','-o','org.apache.maven.plugins:maven-dependency-plugin:3.6.1:build-classpath',"-Dmdep.outputFile=$cpFile",'-DincludeScope=runtime') '离线解析依赖'
    if ($code -ne 0 -or -not (Test-Path $cpFile)) {
        $code = Invoke-Maven @('-B','-q','org.apache.maven.plugins:maven-dependency-plugin:3.6.1:build-classpath',"-Dmdep.outputFile=$cpFile",'-DincludeScope=runtime') '联网解析依赖'
    }
    if (-not (Test-Path $cpFile)) { Fail '依赖解析失败，target\classpath.txt 未生成' }
} else {
    Say '[3/4] 依赖 classpath 已就绪'
}

$mainClass = 'com.fenglin.springboottest.SpringBootTestApplication'
$clsFile = Join-Path $app 'target\classes\com\fenglin\springboottest\SpringBootTestApplication.class'
$needCompile = -not (Test-Path $clsFile)
if (-not $needCompile) {
    $clsTime = (Get-Item $clsFile).LastWriteTime
    $newestSrc = Get-ChildItem -Path (Join-Path $app 'src\main\java') -Recurse -Filter *.java -ErrorAction SilentlyContinue |
                 Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($newestSrc -and $newestSrc.LastWriteTime -gt $clsTime) { $needCompile = $true }
    $pomFile = Join-Path $app 'pom.xml'
    if ((Test-Path $pomFile) -and ((Get-Item $pomFile).LastWriteTime -gt (Get-Item $cpFile).LastWriteTime)) {
        Invoke-Maven @('-B','-q','-o','org.apache.maven.plugins:maven-dependency-plugin:3.6.1:build-classpath',"-Dmdep.outputFile=$cpFile",'-DincludeScope=runtime') 'pom.xml 已更新，刷新依赖' | Out-Null
    }
}
if ($needCompile) {
    Say '[4/4] 编译后端源码...'
    $code = Invoke-Maven @('-B','-q','-o','-DskipTests','compile') '离线编译'
    if ($code -ne 0) { $code = Invoke-Maven @('-B','-q','-DskipTests','compile') '联网编译' }
    if (-not (Test-Path $clsFile)) { Fail '编译失败，请查看上方 Maven 报错' }
} else {
    Say '[4/4] 编译产物已是最新'
}

$depcp = (Get-Content $cpFile -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($depcp)) { Fail 'target\classpath.txt 是空的，请删除后重试' }
$fullCp = (Join-Path $app 'target\classes') + ';' + $depcp
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stdout = Join-Path $logDir "backend-runtime-$stamp.log"
$stderr = Join-Path $logDir "backend-error-$stamp.log"
$javaArgs = @(
    '-XX:TieredStopAtLevel=1', '-Xss512k', '-Dspring.jmx.enabled=false',
    '-Dspring.devtools.restart.enabled=false', "-Dserver.port=$port",
    '-cp', ('"' + $fullCp + '"'), $mainClass
)

Say '  正在启动后台 Java 进程...'
try {
    $process = Start-Process -FilePath $java -ArgumentList $javaArgs -WorkingDirectory $app `
        -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
} catch {
    Fail "Java 启动失败：$($_.Exception.Message)"
}
Set-Content -Path (Join-Path $runDir 'backend.pid') -Value $process.Id -Encoding Ascii
Say "      PID=$($process.Id)"
Say "      运行日志：$stdout"

$ready = $false
for ($i = 0; $i -lt 45; $i++) {
    Start-Sleep -Seconds 2
    $process.Refresh()
    if ($process.HasExited) { break }
    if (Test-Backend) { $ready = $true; break }
}
if (-not $ready) {
    Say '  ---------- 后端错误日志末尾 ----------' 'Yellow'
    if (Test-Path $stderr) { Get-Content $stderr -Tail 25 | ForEach-Object { Say "      $_" 'Yellow' } }
    if (Test-Path $stdout) { Get-Content $stdout -Tail 15 | ForEach-Object { Say "      $_" 'Yellow' } }
    if ($process.HasExited) { Fail "后端进程已退出，退出码=$($process.ExitCode)。完整日志见 $stderr" }
    Fail 'Java 进程仍在，但 90 秒内验证码接口未就绪。请查看运行日志'
}

Say ''
Say '  [成功] 后端已就绪：http://localhost:8081' 'Green'
Say '  关闭本窗口不会停止后端；停止请双击 停止项目.bat' 'Green'
