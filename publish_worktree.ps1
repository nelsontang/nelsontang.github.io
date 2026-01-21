# publish_worktree.ps1
# 临时方案：本地 build（不含草稿）→ 写入 gh-pages worktree → push
$ErrorActionPreference = "Stop"

function Require-Cmd($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Command not found: $name. Please install it and ensure it's in PATH."
  }
}

Require-Cmd "git"
Require-Cmd "hugo"

# 1) 确保在 main
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne "main") { throw "Run this on main branch. Current: $branch" }

# 2) 干净构建（不带 -D，draft:true 不会上线）
if (Test-Path "public") { Remove-Item -Recurse -Force "public" }
hugo --minify --cleanDestinationDir
if (-not (Test-Path "public/index.html")) { throw "Build failed: public/index.html missing" }

# 3) 准备 worktree 目录
$wt = ".ghpages"
if (-not (Test-Path $wt)) {
  git worktree add $wt gh-pages
}

# 4) 清空 worktree（保留 .git）
Get-ChildItem -Force $wt | Where-Object { $_.Name -notin @('.git') } | Remove-Item -Recurse -Force

# 5) 拷贝 public 到 worktree 根目录
Copy-Item -Recurse -Force "public\*" $wt

# 6) 提交并推送 gh-pages
Push-Location $wt
git add -A
git commit -m "publish $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 2>$null
git push origin gh-pages
Pop-Location

Write-Host "Published to gh-pages via worktree successfully."
