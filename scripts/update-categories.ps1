# update-categories.ps1 — Remap categories and prepend new articles
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

$articlesPath = Join-Path $root 'articles.json'
$newPath      = Join-Path $root 'new-articles.json'

# ── category remap ──────────────────────────────────────────────────────────
$remap = @{
    'ryokan-first-time-guide'         = 'before-you-go'
    'japan-winter-travel-guide'       = 'before-you-go'
    'kissaten-tokyo-coffee-culture'   = 'eat-drink'
    'kanazawa-japan-guide'            = 'hidden-japan'
    'tsukiji-outer-market-guide'      = 'eat-drink'
    'izakaya-guide-first-timers'      = 'eat-drink'
    'ic-card-japan-guide'             = 'getting-around'
    'naoshima-art-island-guide'       = 'hidden-japan'
    'shinkansen-guide'                = 'getting-around'
    'tokyo-neighborhoods-guide'       = 'before-you-go'
    'ramen-regional-guide'            = 'eat-drink'
    'sumo-tournament-guide'           = 'before-you-go'
    'japanese-onsen-etiquette'        = 'rules-etiquette'
    'hiroshima-guide'                 = 'hidden-japan'
    'autumn-foliage-japan'            = 'before-you-go'
    'beppu-onsen-guide'               = 'hidden-japan'
    'sushi-counter-guide'             = 'eat-drink'
    'nara-day-trip'                   = 'hidden-japan'
    'golden-week-avoid'               = 'before-you-go'
    'hokkaido-summer-guide'           = 'hidden-japan'
    'koenji-shimokitazawa'            = 'hidden-japan'
    'wagyu-guide'                     = 'eat-drink'
    'japanese-vending-machines'       = 'before-you-go'
    'tokyo-day-trips'                 = 'getting-around'
    'hidden-shrines-kyoto'            = 'hidden-japan'
    '10-days-japan-no-tourist-traps'  = 'before-you-go'
    'mt-fuji-route-guide'             = 'hidden-japan'
    'osaka-3-days-itinerary'          = 'getting-around'
    'yakushima-ancient-forest'        = 'hidden-japan'
    'japanese-menu-guide'             = 'eat-drink'
    'wabi-sabi-explained'             = 'rules-etiquette'
    'kintsugi-art-of-gold'            = 'rules-etiquette'
    'hanami-2026-guide'               = 'before-you-go'
    'japan-convenience-store-guide'   = 'eat-drink'
}

# ── load & remap existing articles ──────────────────────────────────────────
$existing = Get-Content $articlesPath -Raw | ConvertFrom-Json
foreach ($a in $existing) {
    if ($remap.ContainsKey($a.id)) {
        $a.category = $remap[$a.id]
    }
}

# ── load new articles ────────────────────────────────────────────────────────
$newArticles = Get-Content $newPath -Raw | ConvertFrom-Json

# ── merge: new articles first (newest dates) ─────────────────────────────────
$all = @($newArticles) + @($existing)

Write-Host "Total articles: $($all.Count)"

# ── save ─────────────────────────────────────────────────────────────────────
$json = $all | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($articlesPath, $json, [System.Text.UTF8Encoding]::new($false))

Write-Host "articles.json updated." -ForegroundColor Green
