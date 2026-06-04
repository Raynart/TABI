# generate-site.ps1 — TABI entry point
# Runs all generation scripts in order.

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

Write-Host "=== TABI Site Generator ===" -ForegroundColor Cyan
Write-Host "Root: $root"

# 1. Pages
Write-Host "`n[1/2] Generating pages..." -ForegroundColor Yellow
& "$PSScriptRoot\generate-pages.ps1"

# 2. Feeds
Write-Host "`n[2/2] Generating feeds..." -ForegroundColor Yellow
& "$PSScriptRoot\generate-feeds.ps1"

Write-Host "`n=== Done ===" -ForegroundColor Green
