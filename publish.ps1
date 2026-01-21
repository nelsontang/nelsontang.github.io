# hugo new posts/my-new-post.md
# .\publish.ps1 "publish: add xxx"


param(
    [string]$Message = "publish blog",
    [switch]$FailOnDraft
)

$ErrorActionPreference = "Stop"

function Run {
    param(
        [Parameter(Mandatory=$true)][string]$exe,
        [Parameter(Mandatory=$true)][string[]]$args
    )
    Write-Host "   $exe $($args -join ' ')" -ForegroundColor DarkGray
    & $exe @args
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $exe $($args -join ' ')"
    }
}


Write-Host "==> Ensure on main branch" -ForegroundColor Cyan
Run -exe git -args @("checkout", "main")

# 1) 检查 draft
Write-Host "==> Check draft posts" -ForegroundColor Cyan
$draftFiles = Get-ChildItem content -Recurse -File -Include *.md,*.markdown -ErrorAction SilentlyContinue |
    Where-Object {
        (Get-Content $_.FullName -Raw) -match "(?im)^\s*draft\s*:\s*true\s*$"
    }

if ($draftFiles.Count -gt 0) {
    Write-Warning "Found $($draftFiles.Count) draft post(s)."
    $draftFiles | Select-Object -First 10 | ForEach-Object {
        Write-Host "   draft: $($_.FullName)"
    }
    if ($FailOnDraft) {
        throw "FailOnDraft enabled and draft posts were found."
    }
} else {
    Write-Host "   No drafts found." -ForegroundColor Green
}

# 2) 自动提交 main 变更
Write-Host "==> Commit and push changes on main (if any)" -ForegroundColor Cyan
$status = git status --porcelain
if ($status) {
    Run -exe git -args @("add", "-A")
    Run -exe git -args @("commit", "-m", $Message)
    Run -exe git -args @("push")
} else {
    Write-Host "   Working tree clean, nothing to commit." -ForegroundColor Green
}

# 3) 构建 Hugo
Write-Host "==> Build Hugo site" -ForegroundColor Cyan
Run -exe hugo -args @("--minify","--cleanDestinationDir")

if (!(Test-Path "public/index.html")) {
    throw "public/index.html not found. Hugo build output invalid."
}

# 4) 发布到 gh-pages
Write-Host "==> Publish public/ to gh-pages" -ForegroundColor Cyan
if (git branch --list gh-pages) {
    Run -exe git -args @("branch", "-D", "gh-pages")
}

Run -exe git -args @("subtree", "split", "--prefix", "public", "-b", "gh-pages")
Run -exe git -args @("push", "-f", "origin", "gh-pages:gh-pages")

# 5) 回到 main
Run -exe git -args @("checkout", "main")

Write-Host "==> Done! Site published successfully." -ForegroundColor Green
