# generate-feeds.ps1 — TABI
# Generates sitemap.xml, rss.xml, robots.txt

$ErrorActionPreference = 'Stop'
$root    = Split-Path $PSScriptRoot -Parent
$config  = Get-Content "$root\site.config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$articles = Get-Content "$root\articles.json" -Raw -Encoding UTF8 | ConvertFrom-Json

# See generate-pages.ps1: TABI_SITE_URL overrides the site URL for local preview builds.
$siteUrl  = if ($env:TABI_SITE_URL) { $env:TABI_SITE_URL.TrimEnd('/') } else { $config.siteUrl }
$today    = (Get-Date).ToString('yyyy-MM-dd')

# RFC-822 dates in RSS must use English day and month names. Without an explicit
# culture these follow the machine locale, which produced dates like "水, 17 6 2026".
$invariant = [System.Globalization.CultureInfo]::InvariantCulture

# ===== sitemap.xml =====
$sm = [System.Collections.Generic.List[string]]::new()
$sm.Add('<?xml version="1.0" encoding="UTF-8"?>')
$sm.Add('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')

# Listings paginate at 12 per page and pages 2+ have their own URLs, which are
# linked from the pagination control -- but only page 1 was ever declared here.
# Fourteen real, crawlable pages were missing from the sitemap.
$perPage = 12
function Get-PageCount { param($n) return [Math]::Max(1, [Math]::Ceiling($n / [double]$perPage)) }

# Top page
$sm.Add("  <url><loc>$siteUrl/</loc><changefreq>daily</changefreq><priority>1.0</priority></url>")

# All-articles archive, including its later pages
$archivePages = Get-PageCount $articles.Count
for ($i = 1; $i -le $archivePages; $i++) {
    $f = if ($i -eq 1) { 'articles.html' } else { "articles-$i.html" }
    $pri = if ($i -eq 1) { '0.9' } else { '0.4' }
    $sm.Add("  <url><loc>$siteUrl/$f</loc><changefreq>daily</changefreq><priority>$pri</priority></url>")
}

# Category pages
foreach ($cat in $config.categories) {
    $n = @($articles | Where-Object { $_.category -eq $cat.slug }).Count
    $pages = Get-PageCount $n
    for ($i = 1; $i -le $pages; $i++) {
        $f = if ($i -eq 1) { "categories/$($cat.slug).html" } else { "categories/$($cat.slug)-$i.html" }
        $pri = if ($i -eq 1) { '0.8' } else { '0.4' }
        $sm.Add("  <url><loc>$siteUrl/$f</loc><changefreq>weekly</changefreq><priority>$pri</priority></url>")
    }
}

# Article pages
foreach ($a in $articles) {
    $lastmod = if ($a.updatedAt) { $a.updatedAt } else { $a.publishedAt }
    $sm.Add("  <url><loc>$siteUrl/articles/$($a.id).html</loc><lastmod>$lastmod</lastmod><changefreq>monthly</changefreq><priority>0.7</priority></url>")
}

# Tag pages. Thin ones are generated with noindex (see generate-pages.ps1), so
# listing them here would ask the crawler to fetch a page and then be told to
# forget it.
$thinTagThreshold = if ($config.thinTagThreshold) { [int]$config.thinTagThreshold } else { 3 }
$tagList = @($config.tags + @($articles | ForEach-Object { $_.tags }) | Where-Object { $_ } | Sort-Object -Unique)
$tagsIndexed = 0
foreach ($tag in $tagList) {
    $n = @($articles | Where-Object { $_.tags -and $_.tags -contains $tag }).Count
    if ($n -lt $thinTagThreshold) { continue }
    $tagsIndexed++
    $pages = Get-PageCount $n
    for ($i = 1; $i -le $pages; $i++) {
        $f = if ($i -eq 1) { "tags/$tag.html" } else { "tags/$tag-$i.html" }
        $pri = if ($i -eq 1) { '0.5' } else { '0.3' }
        $sm.Add("  <url><loc>$siteUrl/$f</loc><changefreq>weekly</changefreq><priority>$pri</priority></url>")
    }
}

# Region pages and the region hub
$minRegionFeed = if ($config.minRegionArticles) { [int]$config.minRegionArticles } else { 1 }
$sm.Add("  <url><loc>$siteUrl/regions.html</loc><changefreq>weekly</changefreq><priority>0.7</priority></url>")
foreach ($r in $config.regions) {
    $n = @($articles | Where-Object { $_.region -eq $r.slug }).Count
    if ($n -ge $minRegionFeed) {
        $sm.Add("  <url><loc>$siteUrl/regions/$($r.slug).html</loc><changefreq>weekly</changefreq><priority>0.6</priority></url>")
    }
}

# Static pages
foreach ($p in @('about.html','contact.html','newsletter.html','affiliate.html','privacy.html','terms.html')) {
    $sm.Add("  <url><loc>$siteUrl/$p</loc><changefreq>yearly</changefreq><priority>0.3</priority></url>")
}

$sm.Add('</urlset>')
[System.IO.File]::WriteAllText("$root\sitemap.xml", ($sm -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Generated sitemap.xml ($(($sm.Count - 3)) URLs; $($articles.Count) articles, $tagsIndexed of $($tagList.Count) tags)"

# ===== rss.xml =====
$recent = $articles | Sort-Object { $_.publishedAt } -Descending | Select-Object -First 20
$rss = [System.Collections.Generic.List[string]]::new()
$rss.Add('<?xml version="1.0" encoding="UTF-8"?>')
$rss.Add('<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">')
$rss.Add('<channel>')
# NOTE: this file has no BOM, so PowerShell 5.1 reads it as ANSI. A literal em dash
# here would be written to the feed as mojibake -- use a numeric reference instead.
$rss.Add("  <title>$([System.Security.SecurityElement]::Escape($config.siteName)) &#8212; $([System.Security.SecurityElement]::Escape($config.tagline))</title>")
$rss.Add("  <link>$siteUrl</link>")
$rss.Add("  <description>$([System.Security.SecurityElement]::Escape($config.description))</description>")
$rss.Add("  <language>$($config.language)</language>")
$rss.Add("  <lastBuildDate>$((Get-Date).ToUniversalTime().ToString('ddd, dd MMM yyyy HH:mm:ss', $invariant)) +0000</lastBuildDate>")
$rss.Add("  <atom:link href=""$siteUrl/rss.xml"" rel=""self"" type=""application/rss+xml"" />")

foreach ($a in $recent) {
    $pubDate = [datetime]::ParseExact($a.publishedAt, 'yyyy-MM-dd', $invariant).ToString('ddd, dd MMM yyyy', $invariant) + ' 00:00:00 +0000'
    $excerpt = if ($a.excerpt) { [System.Security.SecurityElement]::Escape($a.excerpt) } else { '' }
    $rss.Add("  <item>")
    $rss.Add("    <title>$([System.Security.SecurityElement]::Escape($a.title))</title>")
    $rss.Add("    <link>$siteUrl/articles/$($a.id).html</link>")
    $rss.Add("    <description>$excerpt</description>")
    $rss.Add("    <pubDate>$pubDate</pubDate>")
    $rss.Add("    <guid isPermaLink=""true"">$siteUrl/articles/$($a.id).html</guid>")
    $rss.Add("  </item>")
}

$rss.Add('</channel>')
$rss.Add('</rss>')
[System.IO.File]::WriteAllText("$root\rss.xml", ($rss -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Generated rss.xml ($($recent.Count) items)"

# ===== robots.txt =====
$robots = @"
User-agent: *
Allow: /

Sitemap: $siteUrl/sitemap.xml
"@
[System.IO.File]::WriteAllText("$root\robots.txt", $robots, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Generated robots.txt"

# ===== manifest.json =====
# Was hand-written with start_url and scope of "/", but the site is served from
# "/TABI/" on GitHub Pages. Installing it opened the root of raynart.github.io --
# someone else's page -- and the scope covered the whole origin. Generated from
# siteUrl now so it follows the domain when tabi.guide is switched on.
$uri = [Uri]$siteUrl
$scope = $uri.AbsolutePath
if (-not $scope.EndsWith('/')) { $scope += '/' }
$emDash = [char]0x2014   # never write this literally: the script is read as ANSI
$manifest = [ordered]@{
    name             = "$($config.siteName) $emDash $($config.tagline)"
    short_name       = $config.siteName
    description      = $config.description
    start_url        = $scope
    scope            = $scope
    display          = 'standalone'
    background_color = '#f7f4ef'
    theme_color      = '#111111'
    lang             = $config.language
    icons            = @(
        [ordered]@{ src = 'favicon.svg'; sizes = 'any'; type = 'image/svg+xml'; purpose = 'any maskable' }
    )
}
# ConvertTo-Json escapes non-ASCII to \uXXXX. That is valid JSON and browsers
# decode it, so the em dashes survive the round trip.
$manifestJson = $manifest | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText("$root\manifest.json", $manifestJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Generated manifest.json (scope $scope)"

# ===== ads.txt =====
# AdSense will not serve on a domain without this file once the account has any
# ads.txt at all, and flags "earnings at risk" in the dashboard until it resolves.
# Written only when a client ID is configured; removed again if it is cleared, so
# a stale file cannot outlive the account it authorises.
$adsClientId = ''
if ($config.PSObject.Properties.Name -contains 'monetization' -and
    $config.monetization.adsense -and $config.monetization.adsense.clientId) {
    $adsClientId = $config.monetization.adsense.clientId
}
$adsTxtPath = "$root\ads.txt"
if ($adsClientId) {
    # ca-pub-0000000000000000 -> pub-0000000000000000, the publisher ID ads.txt wants.
    $pubId = $adsClientId -replace '^ca-', ''
    $adsTxt = "google.com, $pubId, DIRECT, f08c47fec0942fa0`n"
    [System.IO.File]::WriteAllText($adsTxtPath, $adsTxt, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Generated ads.txt ($pubId)"
} elseif (Test-Path $adsTxtPath) {
    Remove-Item -LiteralPath $adsTxtPath
    Write-Host "Removed ads.txt (no AdSense client configured)"
}

# ===== articles-slim.json (for client-side search) =====
$slim = $articles | ForEach-Object {
    [PSCustomObject]@{
        id          = $_.id
        title       = $_.title
        excerpt     = if ($_.excerpt) { $_.excerpt } else { '' }
        category    = $_.category
        tags        = if ($_.tags) { $_.tags } else { @() }
        publishedAt = $_.publishedAt
    }
}
$slimJson = $slim | ConvertTo-Json -Depth 3 -Compress
[System.IO.File]::WriteAllText("$root\articles-slim.json", $slimJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Generated articles-slim.json ($($slim.Count) items)"
