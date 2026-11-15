param([switch]$NoPause)
# Sibian 一键上传：把本地改动提交并推送到 GitHub，Pages 会自动重新部署
$ErrorActionPreference = 'Continue'
Set-Location -LiteralPath $PSScriptRoot

function Finish([int]$code, [string]$msg, [string]$color) {
  Write-Host ""
  if ($msg) { Write-Host $msg -ForegroundColor $color }
  if (-not $NoPause) { Write-Host ""; Read-Host "按回车键关闭窗口" | Out-Null }
  exit $code
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sibian 一键上传" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "目录: $PSScriptRoot"
Write-Host ""

# 1. 找 git
$git = "C:\Program Files\Git\cmd\git.exe"
if (-not (Test-Path $git)) {
  $cmd = Get-Command git -ErrorAction SilentlyContinue
  if ($cmd) { $git = $cmd.Source } else { Finish 1 "[X] 找不到 git，请先安装 Git for Windows" "Red" }
}

# 2. 确认当前位置对
if (-not (Test-Path (Join-Path $PSScriptRoot "index.html"))) {
  Finish 1 "[X] 这个目录里没有 index.html，脚本要放在项目根目录" "Red"
}

# 3. 有没有东西要传
$changes = @(& $git status --porcelain)
if ($changes.Count -eq 0) {
  Finish 0 "[OK] 没有检测到任何改动，不需要上传。" "Green"
}
Write-Host "检测到 $($changes.Count) 项改动：" -ForegroundColor Yellow
$changes | ForEach-Object { Write-Host "   $_" }

# 4. 安全检查：本地数据/调试产物绝不能进公开仓库
$bad = @('_board','_board_new','_out/','_run\d','_peek','_scanTabs','_retest','\.bak_v','\.json$','\.png$','\.jpg$','\.pdf$','node_modules')
$danger = $changes | Where-Object { $line = $_; ($bad | Where-Object { $line -match $_ }) }
if ($danger) {
  Write-Host ""
  Write-Host "[!] 发现疑似本地数据文件，已中止上传：" -ForegroundColor Red
  $danger | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
  Write-Host ""
  Write-Host "    这些可能是班级备份、板书图片或调试文件，不应出现在公开仓库。" -ForegroundColor Red
  Write-Host "    如果确认要传，请先手动 git add 指定文件。" -ForegroundColor Red
  Finish 1 "" "Red"
}
Write-Host ""
Write-Host "[OK] 安全检查通过（没有数据文件混入）" -ForegroundColor Green

# 5. 提交
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$msg = "update: $stamp 界面更新"
& $git add -A | Out-Null
$staged = @(& $git diff --cached --name-only)
if ($staged.Count -eq 0) { Finish 0 "[OK] 暂存区为空，无需提交。" "Green" }
Write-Host "将要提交 $($staged.Count) 个文件：" -ForegroundColor Yellow
$staged | ForEach-Object { Write-Host "   $_" }

& $git commit -m $msg --quiet
if ($LASTEXITCODE -ne 0) { Finish 1 "[X] 提交失败，请看上面的报错" "Red" }
Write-Host "[OK] 已提交：$msg" -ForegroundColor Green

# 6. 推送
Write-Host ""
Write-Host "正在推送到 GitHub..." -ForegroundColor Cyan
& $git push origin main
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "[X] 推送失败。" -ForegroundColor Red
  Write-Host "    常见原因：网络断了 / 凭据过期（会弹登录窗口，重新授权即可）" -ForegroundColor Red
  Write-Host "    重新运行本脚本即可续传，已提交的内容不会丢。" -ForegroundColor Red
  Finish 1 "" "Red"
}

# 7. 完成
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  上传完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "网址:  https://rossg5708373.github.io/sibian/" -ForegroundColor Cyan
Write-Host ""
Write-Host "请等 1-2 分钟让 GitHub 重新部署，然后打开网址按 Ctrl+F5 强刷。" -ForegroundColor Yellow
Write-Host "（普通刷新会看到旧版本，必须强刷）" -ForegroundColor Yellow
Finish 0 "" "Green"