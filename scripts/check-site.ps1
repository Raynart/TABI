$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host "Generating TABI static site..."
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "generate-site.ps1")

Write-Host "Generating editorial dashboard..."
& node (Join-Path $PSScriptRoot "editorial-dashboard.mjs")

Write-Host "Validating links, feeds, hreflang, JSON-LD, and policy requirements..."
& node (Join-Path $PSScriptRoot "validate-site.mjs")

Write-Host "Validating structured content data..."
& node (Join-Path $PSScriptRoot "validate-data.mjs")

Write-Host "Running maintenance health checks..."
& node (Join-Path $PSScriptRoot "site-health.mjs")

Write-Host "Writing maintenance report..."
& node (Join-Path $PSScriptRoot "health-report.mjs")

Write-Host "TABI check complete."
