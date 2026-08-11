# generate-site.ps1 — TABI entry point
# Runs all generation scripts in order.

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

Write-Host "=== TABI Site Generator ===" -ForegroundColor Cyan
Write-Host "Root: $root"

# 1. Pages
Write-Host "`n[1/3] Generating pages..." -ForegroundColor Yellow
& "$PSScriptRoot\generate-pages.ps1"

# 2. Feeds
Write-Host "`n[2/3] Generating feeds..." -ForegroundColor Yellow
& "$PSScriptRoot\generate-feeds.ps1"

# 3. Fact freshness. Reports only -- it never fails the build, because content
#    ageing is the passage of time rather than a mistake in this run.
Write-Host "`n[3/3] Checking fact freshness..." -ForegroundColor Yellow
& "$PSScriptRoot\check-freshness.ps1"

Write-Host "`n=== Done ===" -ForegroundColor Green
