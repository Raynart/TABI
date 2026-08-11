# check-freshness.ps1 -- TABI
# Reports which articles need their facts re-checked.
#
# Every factual error found in the August 2026 audit had the same shape: a fact
# with a scheduled change date, written as though it were permanent. Tokyo taxi
# fares had already changed; the JR Pass and the tax-free system were both weeks
# away from changing. Nothing in the repo knew that, so nothing could warn.
#
# Two signals:
#   factsExpire     a date this article is known to go stale on, with a note
#   factsCheckedAt  when its numbers were last verified
#
# Run on its own, or let generate-pages.ps1 print the summary on every build:
#     powershell -ExecutionPolicy Bypass -File .\scripts\check-freshness.ps1

$ErrorActionPreference = 'Stop'
$root     = Split-Path $PSScriptRoot -Parent
$config   = Get-Content "$root\site.config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$articles = Get-Content "$root\articles.json"    -Raw -Encoding UTF8 | ConvertFrom-Json

$today  = Get-Date
$months = if ($config.factsReviewMonths) { [int]$config.factsReviewMonths } else { 6 }
$cutoff = $today.AddMonths(-$months)

$expired  = @()   # a known change date has passed: the text is now wrong
$dueSoon  = @()   # a known change date is within 60 days
$stale    = @()   # not re-checked within the review window
$unchecked = @()  # never checked

foreach ($a in $articles) {
    foreach ($e in @($a.factsExpire)) {
        if (-not $e.on) { continue }
        $on = [datetime]::ParseExact($e.on, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
        if ($on -le $today) {
            $expired += [pscustomobject]@{ id = $a.id; on = $e.on; what = $e.what }
        } elseif ($on -le $today.AddDays(60)) {
            $dueSoon += [pscustomobject]@{ id = $a.id; on = $e.on; what = $e.what }
        }
    }
    if (-not $a.factsCheckedAt) {
        $unchecked += $a.id
    } else {
        $checked = [datetime]::ParseExact($a.factsCheckedAt, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
        if ($checked -lt $cutoff) { $stale += [pscustomobject]@{ id = $a.id; on = $a.factsCheckedAt } }
    }
}

Write-Host ""
Write-Host "=== Fact freshness ===" -ForegroundColor Cyan
Write-Host ("Today {0}; review window {1} months" -f $today.ToString('yyyy-MM-dd'), $months)

if ($expired.Count -gt 0) {
    Write-Host ""
    Write-Host "OUT OF DATE -- a scheduled change has already happened:" -ForegroundColor Red
    $expired | Sort-Object on | ForEach-Object { Write-Host ("  {0}  {1}`n      {2}" -f $_.on, $_.id, $_.what) }
}
if ($dueSoon.Count -gt 0) {
    Write-Host ""
    Write-Host "CHANGING SOON -- within 60 days:" -ForegroundColor Yellow
    $dueSoon | Sort-Object on | ForEach-Object { Write-Host ("  {0}  {1}`n      {2}" -f $_.on, $_.id, $_.what) }
}
if ($stale.Count -gt 0) {
    Write-Host ""
    Write-Host ("NOT CHECKED SINCE {0}:" -f $cutoff.ToString('yyyy-MM-dd')) -ForegroundColor Yellow
    $stale | Sort-Object on | ForEach-Object { Write-Host ("  {0}  {1}" -f $_.on, $_.id) }
}
if ($unchecked.Count -gt 0) {
    Write-Host ""
    Write-Host ("NEVER CHECKED ({0}) -- these make no dated or numeric claim, so there was nothing to verify:" -f $unchecked.Count)
    Write-Host ("  " + ($unchecked -join ', '))
}

$needsWork = $expired.Count + $dueSoon.Count + $stale.Count
Write-Host ""
if ($needsWork -eq 0) {
    Write-Host "Nothing needs re-checking." -ForegroundColor Green
} else {
    Write-Host ("{0} article(s) need attention." -f $needsWork) -ForegroundColor Yellow
}
Write-Host ""

# Deliberately exits 0. Content going stale is the passage of time, not a broken
# build, and failing here would eventually block every deploy for no good reason.
exit 0
