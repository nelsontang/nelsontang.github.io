$ErrorActionPreference = "Stop"

function Require-Cmd($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Missing command: $name. Please install it first."
    }
}

Write-Host "==> Check tools" -ForegroundColor Cyan
Require-Cmd git
Require-Cmd hugo
git --version | Out-Host
hugo version | Out-Host

Write-Host "==> Init submodules" -ForegroundColor Cyan
git submodule update --init --recursive | Out-Host

Write-Host "==> Verify theme exists" -ForegroundColor Cyan
if (!(Test-Path "themes/PaperMod")) {
    throw "themes/PaperMod not found. Submodule init failed."
}

Write-Host "==> Test build" -ForegroundColor Cyan
hugo --minify | Out-Host

if (!(Test-Path "public/index.html")) {
    throw "public/index.html not found after build."
}

Write-Host "==> OK. Next:" -ForegroundColor Green
Write-Host "   Preview: hugo server"
Write-Host "   Publish: .\publish.ps1 `"publish: ...`""
