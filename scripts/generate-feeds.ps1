# generate-feeds.ps1 — TABI
# Generates sitemap.xml, rss.xml, robots.txt

$ErrorActionPreference = 'Stop'
$root    = Split-Path $PSScriptRoot -Parent
$config  = Get-Content "$root\site.config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$articles = Get-Content "$root\articles.json" -Raw -Encoding UTF8 | ConvertFrom-Json

$siteUrl  = $config.siteUrl
$today    = (Get-Date).ToString('yyyy-MM-dd')

# ===== sitemap.xml =====
$sm = [System.Collections.Generic.List[string]]::new()
$sm.Add('<?xml version="1.0" encoding="UTF-8"?>')
$sm.Add('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')

# Top page
$sm.Add("  <url><loc>$siteUrl/</loc><changefreq>daily</changefreq><priority>1.0</priority></url>")

# Category pages
foreach ($cat in $config.categories) {
    $sm.Add("  <url><loc>$siteUrl/categories/$($cat.slug).html</loc><changefreq>weekly</changefreq><priority>0.8</priority></url>")
}

# Article pages
foreach ($a in $articles) {
    $lastmod = if ($a.updatedAt) { $a.updatedAt } else { $a.publishedAt }
    $sm.Add("  <url><loc>$siteUrl/articles/$($a.id).html</loc><lastmod>$lastmod</lastmod><changefreq>monthly</changefreq><priority>0.7</priority></url>")
}

$sm.Add('</urlset>')
[System.IO.File]::WriteAllText("$root\sitemap.xml", ($sm -join "`n"), [System.Text.Encoding]::UTF8)
Write-Host "Generated sitemap.xml ($($articles.Count) articles)"

# ===== rss.xml =====
$recent = $articles | Sort-Object { $_.publishedAt } -Descending | Select-Object -First 20
$rss = [System.Collections.Generic.List[string]]::new()
$rss.Add('<?xml version="1.0" encoding="UTF-8"?>')
$rss.Add('<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">')
$rss.Add('<channel>')
$rss.Add("  <title>$($config.siteName) — $($config.tagline)</title>")
$rss.Add("  <link>$siteUrl</link>")
$rss.Add("  <description>$($config.description)</description>")
$rss.Add("  <language>$($config.language)</language>")
$rss.Add("  <lastBuildDate>$(Get-Date -Format 'ddd, dd MMM yyyy HH:mm:ss') +0000</lastBuildDate>")
$rss.Add("  <atom:link href=""$siteUrl/rss.xml"" rel=""self"" type=""application/rss+xml"" />")

foreach ($a in $recent) {
    $pubDate = [datetime]::ParseExact($a.publishedAt, 'yyyy-MM-dd', $null).ToString('ddd, dd MMM yyyy') + ' 00:00:00 +0000'
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
[System.IO.File]::WriteAllText("$root\rss.xml", ($rss -join "`n"), [System.Text.Encoding]::UTF8)
Write-Host "Generated rss.xml ($($recent.Count) items)"

# ===== robots.txt =====
$robots = @"
User-agent: *
Allow: /

Sitemap: $siteUrl/sitemap.xml
"@
[System.IO.File]::WriteAllText("$root\robots.txt", $robots, [System.Text.Encoding]::UTF8)
Write-Host "Generated robots.txt"
