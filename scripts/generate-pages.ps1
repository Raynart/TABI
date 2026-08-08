# generate-pages.ps1 — TABI
# Generates: index.html, articles/*.html, categories/*.html, tags/*.html, 404.html

$ErrorActionPreference = 'Stop'
$root     = Split-Path $PSScriptRoot -Parent
$config   = Get-Content "$root\site.config.json"  -Raw -Encoding UTF8 | ConvertFrom-Json
$articles = Get-Content "$root\articles.json" -Raw -Encoding UTF8 | ConvertFrom-Json

# Every page carries <base href="$siteUrl/">, so a build made with the production
# URL cannot be previewed locally -- the browser would fetch styles.css, script.js
# and every link from the live site. Set TABI_SITE_URL (e.g. http://localhost:8080)
# to produce a build that runs against a local server. Unset for real builds.
$siteUrl  = if ($env:TABI_SITE_URL) { $env:TABI_SITE_URL.TrimEnd('/') } else { $config.siteUrl }
$siteName = $config.siteName
$tagline  = $config.tagline
$defaultOgImage = (($articles | Where-Object { $_.heroImage } | Sort-Object { $_.publishedAt } -Descending | Select-Object -First 1).heroImage)

$script:ImageSizeCache = @{}

# Ad slots and contextual affiliate blocks. Both stay dormant until
# site.config.json -> monetization is filled in; see that file for the details.
. "$PSScriptRoot\monetization.ps1"

# Appended to image URLs so a change forces browsers past a stale cached copy.
# Bump this when image files are replaced in place.
$imageVersion = '20260806-list-images'

# Ensure output directories exist
@('articles','categories','tags') | ForEach-Object {
    $d = "$root\$_"
    if (-not (Test-Path $d)) { New-Item -ItemType Directory $d | Out-Null }
}

# ===== VALIDATE ARTICLE DATA =====
# Ad-hoc tags and categories used to slip in silently and produce thin one-article
# tag pages, or pages nothing linked to. Fail the build instead.
$validCategories = @($config.categories | ForEach-Object { $_.slug })
$validTags       = @($config.tags)
$dataErrors      = [System.Collections.Generic.List[string]]::new()

foreach ($a in $articles) {
    if ($validCategories -notcontains $a.category) {
        $dataErrors.Add("$($a.id): unknown category '$($a.category)'")
    }
    foreach ($t in @($a.tags)) {
        if ($validTags -notcontains $t) {
            $dataErrors.Add("$($a.id): unknown tag '$t'")
        }
    }
    if (-not $a.excerpt)  { $dataErrors.Add("$($a.id): empty excerpt") }
    if (-not $a.sections) { $dataErrors.Add("$($a.id): no body sections") }
}

if (-not ($validCategories -contains $config.homepageFeature.category)) {
    $dataErrors.Add("site.config.json: homepageFeature.category '$($config.homepageFeature.category)' is not a configured category")
}

if ($dataErrors.Count -gt 0) {
    $dataErrors | ForEach-Object { Write-Host "  DATA ERROR: $_" -ForegroundColor Red }
    throw "articles.json failed validation ($($dataErrors.Count) problem(s)). Fix articles.json or site.config.json and re-run."
}

# ===== HELPERS =====

function Escape-Json {
    param($str)
    if (-not $str) { return '' }
    return ($str -replace '\\', '\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '' -replace "`t", '\t')
}

function Get-ImageSize {
    # Reads a WebP file's intrinsic size so <img> can carry width/height and the
    # browser can reserve space before the bytes arrive (no layout shift).
    # heroImage holds an absolute site URL; map it back to the file on disk.
    param($url)
    if (-not $url) { return $null }
    # heroImage values are written with the production URL, which stays put even in
    # a local preview build, so match against both.
    $prefix = @("$($config.siteUrl)/", "$siteUrl/") | Where-Object { $url.StartsWith($_) } | Select-Object -First 1
    if (-not $prefix) { return $null }   # external image, size unknown
    $path = Join-Path $root ($url.Substring($prefix.Length) -replace '/', '\')
    if ($script:ImageSizeCache.ContainsKey($path)) { return $script:ImageSizeCache[$path] }

    $size = $null
    if (Test-Path $path) {
        $b = New-Object byte[] 32
        $fs = [System.IO.File]::OpenRead($path)
        try { $read = $fs.Read($b, 0, 32) } finally { $fs.Dispose() }
        if ($read -ge 30 -and [System.Text.Encoding]::ASCII.GetString($b, 0, 4) -eq 'RIFF') {
            switch ([System.Text.Encoding]::ASCII.GetString($b, 12, 4)) {
                'VP8 ' { $size = @{ w = ([BitConverter]::ToUInt16($b, 26) -band 0x3FFF)
                                    h = ([BitConverter]::ToUInt16($b, 28) -band 0x3FFF) } }
                'VP8L' { $n = [BitConverter]::ToUInt32($b, 21)
                         $size = @{ w = (($n -band 0x3FFF) + 1)
                                    h = ((($n -shr 14) -band 0x3FFF) + 1) } }
                'VP8X' { $size = @{ w = ($b[24] + $b[25] * 256 + $b[26] * 65536 + 1)
                                    h = ($b[27] + $b[28] * 256 + $b[29] * 65536 + 1) } }
            }
        }
    }
    $script:ImageSizeCache[$path] = $size
    return $size
}

function Get-ImageSrc {
    # Adds the cache-busting query to locally hosted images.
    param($url)
    if (-not $url) { return '' }
    if ($url -like "$($config.siteUrl)/assets/images/*" -or $url -like "$siteUrl/assets/images/*" -or $url -like 'assets/images/*') {
        $sep = if ($url.Contains('?')) { '&' } else { '?' }
        return "$url${sep}v=$imageVersion"
    }
    return $url
}

function Get-ImageDimAttr {
    param($url)
    $d = Get-ImageSize $url
    if ($d) { return " width=""$($d.w)"" height=""$($d.h)""" }
    return ''
}

function Get-ImageSrcset {
    # Cards display at roughly 400-850 CSS px but the source images are ~1670px wide.
    # An 800w variant sits beside each original (see scripts/make-image-variants.py),
    # so let the browser pick. Falls back to no srcset if the variant is missing.
    param($url, $sizes)
    if (-not $url -or -not $url.EndsWith('.webp')) { return '' }
    $small = $url.Substring(0, $url.Length - 5) + '-800.webp'
    $dim   = Get-ImageSize $small
    if (-not $dim) { return '' }
    $full  = Get-ImageSize $url
    if (-not $full) { return '' }
    return " srcset=""$(Get-ImageSrc $small) $($dim.w)w, $(Get-ImageSrc $url) $($full.w)w"" sizes=""$sizes"""
}

function Write-ListingPages {
    # Writes a card listing across as many real pages as it needs, instead of
    # emitting every card and hiding the overflow with JavaScript. Page 2 onward
    # get their own URL, so they are linkable and crawlable, and the listing still
    # works with scripting turned off.
    param(
        $items,           # articles, already sorted
        $slugBase,        # e.g. 'categories/eat-drink' or 'articles'
        $heading,
        $description,
        $kanji = '',
        $activeCat = '',
        $perPage = 12
    )
    $total     = @($items).Count
    $pageCount = [Math]::Max(1, [Math]::Ceiling($total / [double]$perPage))

    for ($pageNo = 1; $pageNo -le $pageCount; $pageNo++) {
        $file      = if ($pageNo -eq 1) { "$slugBase.html" } else { "$slugBase-$pageNo.html" }
        $canonical = "$siteUrl/$file"
        $pageItems = @($items) | Select-Object -Skip (($pageNo - 1) * $perPage) -First $perPage

        # rel=prev/next tell crawlers these pages are one sequence.
        $extra = ''
        if ($pageNo -gt 1) {
            $prevFile = if ($pageNo -eq 2) { "$slugBase.html" } else { "$slugBase-$($pageNo - 1).html" }
            $extra += "  <link rel=""prev"" href=""$siteUrl/$prevFile"">`n"
        }
        if ($pageNo -lt $pageCount) {
            $extra += "  <link rel=""next"" href=""$siteUrl/$slugBase-$($pageNo + 1).html"">`n"
        }

        $suffix    = if ($pageNo -gt 1) { " &mdash; Page $pageNo" } else { '' }
        $pageDesc  = if ($pageNo -gt 1) { "$description Page $pageNo of $pageCount." } else { $description }
        $ogImage   = ((@($pageItems) | Where-Object { $_.heroImage } | Select-Object -First 1).heroImage)

        $itemList = ''
        $pos = 1
        foreach ($a in $pageItems) {
            if ($itemList) { $itemList += ',' }
            $itemList += "{""@type"":""ListItem"",""position"":$pos,""url"":""$siteUrl/articles/$($a.id).html"",""name"":""$(Escape-Json $a.title)""}"
            $pos++
        }
        $schema = "{""@context"":""https://schema.org"",""@type"":""CollectionPage"",""name"":""$(Escape-Json $heading)"",""url"":""$canonical"",""mainEntity"":{""@type"":""ItemList"",""itemListElement"":[$itemList]}}"
        $crumb  = "{""@context"":""https://schema.org"",""@type"":""BreadcrumbList"",""itemListElement"":[{""@type"":""ListItem"",""position"":1,""name"":""Home"",""item"":""$siteUrl/""},{""@type"":""ListItem"",""position"":2,""name"":""$(Escape-Json $heading)"",""item"":""$canonical""}]}"

        $headHtml = Get-Head "$heading$suffix &mdash; $siteName" $pageDesc $ogImage $canonical 'website' "$schema`n$crumb" $extra

        # One in-feed unit per listing page, dropped in after the sixth card so it
        # sits below the fold and the grid still opens on editorial content.
        $feedAd = Get-InFeedAd
        $cardsHtml = ''
        $isFirst = ($pageNo -eq 1)
        $cardNo  = 0
        foreach ($a in $pageItems) {
            $size = if ($isFirst) { 'main'; $isFirst = $false } else { 'sub' }
            $cardsHtml += Get-ArticleCard $a $size
            $cardNo++
            if ($feedAd -and $cardNo -eq 6) { $cardsHtml += $feedAd }
        }
        if (-not $cardsHtml) {
            $cardsHtml = '<p style="padding:48px 32px;color:var(--mist);">No articles yet. Check back soon.</p>'
        }

        $kanjiHtml = if ($kanji) { "  <span class=""section-label-jp"" aria-hidden=""true"">$kanji</span>`n" } else { '' }

        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add($headHtml)
        $lines.Add('<body>')
        $lines.Add('<div class="progress-bar" aria-hidden="true"></div>')
        $lines.Add((Get-TopBar))
        $lines.Add((Get-Header $activeCat))
        $lines.Add('<main id="main">')
        $lines.Add("<nav class=""breadcrumb"" aria-label=""Breadcrumb"" style=""padding:0 var(--pad-x);max-width:var(--max-w);margin:1.5rem auto 0;""><a href=""index.html"">Home</a><span class=""breadcrumb-sep"" aria-hidden=""true"">&#8250;</span><span class=""breadcrumb-current"">$heading</span></nav>")
        $lines.Add('<div class="section-label">')
        $lines.Add($kanjiHtml.TrimEnd())
        $lines.Add("  <h1 class=""section-label-en"">$heading</h1>")
        $lines.Add('  <div class="section-label-line"></div>')
        $lines.Add("  <span style=""font-size:0.78rem;color:var(--mist);"">$total articles</span>")
        $lines.Add('</div>')
        $lines.Add('<div class="editorial-grid">')
        $lines.Add($cardsHtml)
        $lines.Add('</div>')

        if ($pageCount -gt 1) {
            $pg = [System.Collections.Generic.List[string]]::new()
            $pg.Add('<nav class="pagination" aria-label="Pagination">')
            for ($i = 1; $i -le $pageCount; $i++) {
                $href = if ($i -eq 1) { "$slugBase.html" } else { "$slugBase-$i.html" }
                if ($i -eq $pageNo) {
                    $pg.Add("  <a class=""pg-btn active"" href=""$href"" aria-current=""page"" aria-label=""Page $i"">$i</a>")
                } else {
                    $pg.Add("  <a class=""pg-btn"" href=""$href"" aria-label=""Page $i"">$i</a>")
                }
            }
            $pg.Add('</nav>')
            $lines.Add(($pg -join "`n"))
        }

        $lines.Add('</main>')
        $lines.Add((Get-Footer))

        $outPath = Join-Path $root ($file -replace '/', '\')
        [System.IO.File]::WriteAllText($outPath, ($lines -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
    }
    return $pageCount
}

function Get-FontLink {
    # Noto Sans 700 is requested because styles.css uses font-weight:700 on var(--sans);
    # without it the browser synthesises a bold, which renders noticeably worse.
    $href = 'https://fonts.googleapis.com/css2?family=Noto+Serif+JP:wght@300;400;700&amp;family=Noto+Serif:ital,wght@0,300;0,400;0,700;1,300;1,400&amp;family=Noto+Sans:wght@300;400;500;600;700&amp;display=swap'
    # Loaded with media="print" and switched to "all" on load, so the font CSS does
    # not block the first render. display=swap already means text paints in the
    # fallback face first, so this costs nothing visually and removes a round trip.
    return @"
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link rel="stylesheet" href="$href" media="print" onload="this.media='all';this.onload=null"><noscript><link rel="stylesheet" href="$href"></noscript>
"@
}

function Get-Head {
    param($title, $desc, $og, $canonical, $ogType = 'website', $jsonLd = '', $extraHead = '')
    $font = Get-FontLink
    $ogImage = if ($og) { $og } else { $defaultOgImage }

    # GA4 is only configured here; script.js loads it after the visitor consents.
    # Loading the tag directly in <head> would run analytics before the cookie
    # banner was answered, which is exactly what the banner is supposed to prevent.
    # The AdSense library is handled the same way -- the client ID is declared here,
    # script.js fetches adsbygoogle.js only after consent. Personalised ads set
    # cookies, so loading the library up front would beat the banner to it.
    $gaScript = ''
    $globals = @()
    if ($config.googleAnalyticsId) { $globals += "window.TABI_GA_ID='$($config.googleAnalyticsId)';" }
    $adsClient = Get-AdsenseClient
    if ($adsClient) { $globals += "window.TABI_ADS_CLIENT='$adsClient';" }
    if ($globals.Count -gt 0) {
        $gaScript = "  <script>$($globals -join '')</script>"
    }

    return @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="theme-color" content="#111111">
  <base href="$siteUrl/">
  <title>$title</title>
  <meta name="description" content="$desc">
  <meta property="og:title" content="$title">
  <meta property="og:description" content="$desc">
  <meta property="og:image" content="$ogImage">
  <meta property="og:url" content="$canonical">
  <meta property="og:type" content="$ogType">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="$title">
  <meta name="twitter:description" content="$desc">
  <meta name="twitter:image" content="$ogImage">
  <link rel="canonical" href="$canonical">
  <link rel="icon" type="image/svg+xml" href="favicon.svg">
  <link rel="manifest" href="manifest.json">
  <link rel="stylesheet" href="styles.css">
  <link rel="alternate" type="application/rss+xml" title="$siteName RSS" href="rss.xml">
$extraHead  $font
$gaScript
$(if ($jsonLd) { ($jsonLd -split "`n" | Where-Object { $_.Trim() } | ForEach-Object { "  <script type=""application/ld+json"">$($_.Trim())</script>" }) -join "`n" })
</head>
"@
}

function Get-TopBar {
    return '<div class="top-bar">Japan Travel &amp; Culture Guide &nbsp;<span>&middot;</span>&nbsp; Updated weekly &nbsp;<span>&middot;</span>&nbsp; <a href="newsletter.html" style="color:inherit;text-decoration:underline;text-underline-offset:3px;">Free newsletter every Friday</a></div>'
}

function Get-Header {
    param($activeCat = '')
    $navItems = ''
    foreach ($cat in $config.categories) {
        $active = if ($cat.slug -eq $activeCat) { ' class="active"' } else { '' }
        $navItems += "<li><a href=""categories/$($cat.slug).html""$active>$($cat.nav)</a></li>"
    }
    return @"
<a class="skip-link" href="#main">Skip to content</a>
<header class="site-header">
  <div class="header-inner">
    <nav class="header-nav-wrap" aria-label="Main navigation">
      <ul class="header-nav">
        $navItems
      </ul>
    </nav>
    <a href="index.html" class="site-logo" aria-label="$siteName home">
      <span class="logo-en">$siteName<span class="dot">.</span></span>
      <span class="logo-jp">&#26053; &#8212; $tagline</span>
    </a>
    <div class="header-right">
      <button class="header-search-btn" id="search-open" aria-label="Search" aria-expanded="false"><svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" width="18" height="18" aria-hidden="true"><circle cx="8.5" cy="8.5" r="5.5"/><path d="M15 15l-3-3"/></svg></button>
      <button class="header-menu-btn" aria-label="Open menu" aria-expanded="false">&#9776;</button>
      <a href="#newsletter" class="header-cta">Free Newsletter</a>
    </div>
  </div>
</header>
"@
}

function Get-Ticker {
    param($articles)
    $items = ''
    $recent = $articles | Sort-Object { $_.publishedAt } -Descending | Select-Object -First 8
    foreach ($a in $recent) {
        $label = ($config.categories | Where-Object { $_.slug -eq $a.category } | Select-Object -First 1).nav
        if (-not $label) { $label = $a.category }
        $items += "<span class=""ticker-item""><strong>$label</strong> &mdash; $([System.Net.WebUtility]::HtmlEncode($a.title))</span>"
    }
    # Duplicate for infinite scroll
    return @"
<div class="ticker" aria-hidden="true">
  <div class="ticker-label">Latest</div>
  <div class="ticker-track" id="ticker-track">$items$items</div>
</div>
"@
}

function Get-Footer {
    $year = (Get-Date).Year
    $catLinks = ''
    foreach ($cat in $config.categories) {
        $catLinks += "<li><a href=""categories/$($cat.slug).html"">$($cat.label)</a></li>"
    }

    # Only ask for cookie consent when there is actually something to consent to.
    # With no analytics ID configured the site sets no cookies at all, so the
    # banner was asking permission for something that never happened.
    # Ads are the same deal: AdSense sets cookies, so enabling it also turns the
    # banner on even with analytics off.
    $gdprBanner = ''
    if ($config.googleAnalyticsId -or (Test-AdsEnabled)) {
        $gdprText = if (Test-AdsEnabled) {
            'We use cookies to analyze site traffic and to serve ads. <a href="privacy.html">Privacy Policy</a>.'
        } else {
            'We use cookies to analyze site traffic. <a href="privacy.html">Privacy Policy</a>.'
        }
        $gdprBanner = @"
<div class="gdpr-banner" id="gdpr-banner">
  <p class="gdpr-text">$gdprText</p>
  <div class="gdpr-actions">
    <button class="gdpr-btn gdpr-decline" id="gdpr-decline">Decline</button>
    <button class="gdpr-btn gdpr-accept" id="gdpr-accept">Accept</button>
  </div>
</div>
"@
    }
    return @"
<footer class="site-footer">
  <div class="footer-top">
    <div>
      <div class="footer-brand-logo">$siteName<span class="dot">.</span></div>
      <div class="footer-brand-jp">&#26053; &mdash; &#12383;&#12403; &mdash; Journey</div>
      <p class="footer-tagline">$($config.description)</p>
      <div class="footer-social">
        <a href="#" title="Instagram" aria-label="Instagram">&#9670;</a>
        <a href="#" title="X / Twitter" aria-label="X">&#9632;</a>
        <a href="#" title="Pinterest" aria-label="Pinterest">&#9675;</a>
      </div>
    </div>
    <div>
      <p class="footer-col-title">Explore</p>
      <ul class="footer-links">$catLinks</ul>
    </div>
    <div>
      <p class="footer-col-title">About</p>
      <ul class="footer-links">
        <li><a href="about.html">About TABI</a></li>
        <li><a href="newsletter.html">Newsletter</a></li>
        <li><a href="contact.html">Contact</a></li>
      </ul>
    </div>
    <div>
      <p class="footer-col-title">Legal</p>
      <ul class="footer-links">
        <li><a href="privacy.html">Privacy Policy</a></li>
        <li><a href="terms.html">Terms of Use</a></li>
        <li><a href="affiliate.html">Affiliate Disclosure</a></li>
      </ul>
    </div>
  </div>
  <div class="footer-bottom">
    <div class="footer-bottom-inner">
      <p class="footer-copy">&copy; $year $siteName. All rights reserved. Affiliate links may earn us a commission.</p>
      <p class="footer-jp-strip">&#26053; &nbsp;&middot;&nbsp; &#12383;&#12403; &nbsp;&middot;&nbsp; &#25991;&#21270; &nbsp;&middot;&nbsp; &#36023;&#29289;</p>
    </div>
  </div>
</footer>
<button class="back-top" aria-label="Back to top">&#8593;</button>
<div class="search-overlay" id="search-overlay" aria-hidden="true" inert>
  <div class="search-modal" role="dialog" aria-modal="true" aria-labelledby="search-title">
    <h2 class="visually-hidden" id="search-title">Search</h2>
    <button class="search-close" id="search-close" aria-label="Close search">&times;</button>
    <input class="search-input" id="search-input" type="search" placeholder="Search Japan guides&#8230;" autocomplete="off" aria-label="Search">
    <p class="search-hint">Try &#8220;kyoto&#8221;, &#8220;budget&#8221;, &#8220;food&#8221;</p>
    <div class="search-results" id="search-results" role="region" aria-live="polite" aria-label="Search results"></div>
  </div>
</div>
$gdprBanner
<script src="script.js" defer></script>
</body></html>
"@
}

$EnUs = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
function Format-Date {
    param($dateStr)
    try {
        return [datetime]::ParseExact($dateStr, 'yyyy-MM-dd', $EnUs).ToString('MMMM d, yyyy', $EnUs)
    } catch {
        return $dateStr
    }
}

function Get-CategoryLabel {
    param($slug)
    $cat = $config.categories | Where-Object { $_.slug -eq $slug } | Select-Object -First 1
    if ($cat) { return $cat.label } else { return $slug }
}

# ===== CATEGORY FALLBACK GRADIENTS + ICONS =====
function Get-CardFallback {
    param($category)
    switch ($category) {
        'travel-guide'  { return @{ grad = 'linear-gradient(160deg,#081f0d 0%,#1a4a2e 55%,#0d3320 100%)'; icon = '&#9992;' } }
        'food'          { return @{ grad = 'linear-gradient(160deg,#200a02 0%,#5c2008 55%,#3a1205 100%)'; icon = '&#127837;' } }
        'culture'       { return @{ grad = 'linear-gradient(160deg,#12082a 0%,#371a66 55%,#200d45 100%)'; icon = '&#26319;' } }
        'things-to-buy' { return @{ grad = 'linear-gradient(160deg,#1a1400 0%,#4a3800 55%,#2e2400 100%)'; icon = '&#127850;' } }
        'hidden-gems'   { return @{ grad = 'linear-gradient(160deg,#04141f 0%,#0d3a55 55%,#072840 100%)'; icon = '&#128142;' } }
        default         { return @{ grad = 'linear-gradient(160deg,#100808 0%,#2e1010 55%,#5a1a1a 100%)'; icon = '&#127758;' } }
    }
}

# ===== ARTICLE CARDS (used in index + category pages) =====
function Get-ArticleCard {
    param($article, $size = 'sub')  # 'main' or 'sub'
    $cat   = Get-CategoryLabel $article.category
    $date  = Format-Date $article.publishedAt
    $title = [System.Net.WebUtility]::HtmlEncode($article.title)
    $img   = if ($article.heroImage) { $article.heroImage } else { '' }
    $strip = if ($size -eq 'main') { '<div class="ed-main-strip">&#29305;&#38598;</div>' } else { '' }
    $fb    = Get-CardFallback $article.category
    $imgTag = if ($img) {
        "<img src=""$(Get-ImageSrc $img)"" alt=""$([System.Net.WebUtility]::HtmlEncode($article.heroImageAlt))"" class=""ed-img"" loading=""lazy"" decoding=""async""$(Get-ImageSrcset $img '(max-width: 768px) 100vw, (max-width: 1280px) 50vw, 640px')$(Get-ImageDimAttr $img)>"
    } else {
        "<div class=""ed-img ed-img-fallback"" style=""background:$($fb.grad);""><span class=""fallback-icon"">$($fb.icon)</span></div>"
    }
    return @"
<a href="articles/$($article.id).html" class="ed-card ed-$size">
  $imgTag
  <div class="ed-overlay"></div>
  $strip
  <div class="ed-content">
    <p class="ed-cat cat--$($article.category)">$cat</p>
    <h3 class="ed-title">$title</h3>
    <div class="ed-meta">
      <span>$date</span>
      <span class="ed-meta-dot"></span>
      <span>$($article.readingTime) min read</span>
    </div>
  </div>
</a>
"@
}

# ===== INDEX.HTML =====
Write-Host "Generating index.html..."

$heroArticle = $articles | Sort-Object { $_.publishedAt } -Descending | Select-Object -First 1
$gridArticles = $articles | Sort-Object { $_.publishedAt } -Descending | Select-Object -Skip 1 -First 4
# Homepage feature section. This used to filter on a hardcoded category 'culture'
# that no articles have had since the taxonomy was reworked, so the section never
# rendered at all. Driven from site.config.json now, and validated at startup.
$featureCat = $config.categories | Where-Object { $_.slug -eq $config.homepageFeature.category } | Select-Object -First 1
$cultureArticles = $articles | Where-Object { $_.category -eq $featureCat.slug } | Sort-Object { $_.publishedAt } -Descending | Select-Object -First 3
$buyArticles = $articles | Where-Object { $_.category -eq 'things-to-buy' } | Sort-Object { $_.publishedAt } -Descending | Select-Object -First 4

$heroImg = if ($heroArticle -and $heroArticle.heroImage) { $heroArticle.heroImage } else { '' }
$heroTitle = if ($heroArticle) { [System.Net.WebUtility]::HtmlEncode($heroArticle.title) } else { 'Welcome to TABI' }
$heroDesc  = if ($heroArticle -and $heroArticle.excerpt) { [System.Net.WebUtility]::HtmlEncode($heroArticle.excerpt) } elseif ($heroArticle -and $heroArticle.summary) { [System.Net.WebUtility]::HtmlEncode($heroArticle.summary) } else { 'Your guide to the real Japan.' }
$heroCat   = if ($heroArticle) { Get-CategoryLabel $heroArticle.category } else { 'Travel Guide' }
$heroKanji = '&#26053;'

$gridHtml = ''
if ($gridArticles.Count -gt 0) {
    $gridHtml += Get-ArticleCard $gridArticles[0] 'main'
    for ($i = 1; $i -lt $gridArticles.Count; $i++) {
        $gridHtml += Get-ArticleCard $gridArticles[$i] 'sub'
    }
}

$cultureHtml = ''
$ci = 1
foreach ($a in $cultureArticles) {
    $cat  = Get-CategoryLabel $a.category
    $title = [System.Net.WebUtility]::HtmlEncode($a.title)
    $desc  = if ($a.excerpt) { [System.Net.WebUtility]::HtmlEncode($a.excerpt) } elseif ($a.summary) { [System.Net.WebUtility]::HtmlEncode($a.summary) } else { '' }
    $fb2   = Get-CardFallback $a.category
    $img   = if ($a.heroImage) { "<img src=""$(Get-ImageSrc $a.heroImage)"" alt=""$([System.Net.WebUtility]::HtmlEncode($a.heroImageAlt))"" loading=""lazy"" decoding=""async""$(Get-ImageSrcset $a.heroImage '(max-width: 768px) 100vw, 400px')$(Get-ImageDimAttr $a.heroImage) style=""width:100%;height:100%;object-fit:cover;"">" } else { "<div style=""width:100%;height:100%;$($fb2.grad);display:flex;align-items:center;justify-content:center;""><span style=""font-size:2rem;opacity:.25;"">$($fb2.icon)</span></div>" }
    $numStr = $ci.ToString().PadLeft(2, '0')
    $cultureHtml += @"
<a href="articles/$($a.id).html" class="culture-card">
  <p class="culture-num">$numStr</p>
  <div class="culture-card-img">$img</div>
  <p class="culture-card-cat cat--$($a.category)">$cat</p>
  <h3 class="culture-card-title">$title</h3>
  <p class="culture-card-desc">$desc</p>
</a>
"@
    $ci++
}

$buyHtml = ''
foreach ($a in $buyArticles) {
    $title = [System.Net.WebUtility]::HtmlEncode($a.title)
    $price = if ($a.affiliateLinks -and $a.affiliateLinks.Count -gt 0) { [System.Net.WebUtility]::HtmlEncode($a.affiliateLinks[0].price) } else { '' }
    $priceHtml = if ($price) { "<p class=""buy-price"">From $price</p>" } else { '' }
    $tagLabel = if ($a.tags -and $a.tags.Count -gt 0) { $a.tags[0] } else { 'Shopping' }
    $buyHtml += @"
<a href="articles/$($a.id).html" class="buy-card">
  <p class="buy-tag">$tagLabel</p>
  <h3 class="buy-title">$title</h3>
  $priceHtml
  <span class="buy-arrow">&#8599;</span>
</a>
"@
}

$tickerHtml = Get-Ticker $articles
$headerHtml = Get-Header
$footerHtml = Get-Footer
$websiteSchema = @"
{"@context":"https://schema.org","@type":"WebSite","name":"$(Escape-Json $siteName)","url":"$siteUrl/","description":"$(Escape-Json $config.description)"}
"@
$headHtml   = Get-Head "$siteName &mdash; $tagline" $config.description $heroImg "$siteUrl/" 'website' $websiteSchema.Trim()
$topBarHtml = Get-TopBar

$indexLines = [System.Collections.Generic.List[string]]::new()
$indexLines.Add($headHtml)
$indexLines.Add('<body>')
$indexLines.Add('<div class="progress-bar" aria-hidden="true"></div>')
$indexLines.Add($topBarHtml)
$indexLines.Add($headerHtml)
$indexLines.Add('<main id="main">')
$indexLines.Add($tickerHtml)

# Hero
$indexLines.Add('<section class="hero" aria-label="Featured article">')
$indexLines.Add('  <div class="hero-bg"></div>')
$indexLines.Add('  <div class="hero-pattern"></div>')
$indexLines.Add("  <div class=""hero-kanji"" aria-hidden=""true"">$heroKanji</div>")
$indexLines.Add('  <div class="hero-line"></div>')
if ($heroImg) {
    $indexLines.Add("  <img src=""$(Get-ImageSrc $heroImg)"" alt="""" style=""position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:0.35;"" loading=""eager"" fetchpriority=""high"" decoding=""async""$(Get-ImageSrcset $heroImg '100vw')$(Get-ImageDimAttr $heroImg)>")
}
$indexLines.Add('  <div class="hero-content">')
$indexLines.Add('    <div class="hero-eyebrow">')
$indexLines.Add("      <span class=""hero-tag"">$heroCat</span>")
$indexLines.Add('    </div>')
$indexLines.Add("    <h1 class=""hero-title"">$heroTitle</h1>")
$indexLines.Add("    <p class=""hero-desc"">$heroDesc</p>")
$indexLines.Add('    <div class="hero-actions">')
if ($heroArticle) {
    $indexLines.Add("      <a href=""articles/$($heroArticle.id).html"" class=""hero-btn"">Read the Guide &nbsp;&rarr;</a>")
}
$indexLines.Add("      <a href=""articles.html"" class=""hero-btn-ghost"">Browse all guides</a>")
$indexLines.Add('    </div>')
$indexLines.Add('  </div>')
$indexLines.Add('  <div class="scroll-hint" aria-hidden="true"><span>Scroll</span><div class="scroll-hint-line"></div></div>')
$indexLines.Add('</section>')

# Travel section
if ($gridHtml) {
    $indexLines.Add('<div class="section-label">')
    $indexLines.Add('  <span class="section-label-jp" aria-hidden="true">&#26053;</span>')
    $indexLines.Add('  <h2 class="section-label-en">Travel Guide</h2>')
    $indexLines.Add('  <div class="section-label-line"></div>')
    $indexLines.Add('  <a href="articles.html" class="section-label-link">All articles <span class="arrow">&rarr;</span></a>')
    $indexLines.Add('</div>')
    $indexLines.Add('<div class="editorial-grid">')
    $indexLines.Add($gridHtml)
    $indexLines.Add('</div>')
}

# Culture section
if ($cultureHtml) {
    $indexLines.Add('<div class="section-label">')
    $indexLines.Add("  <span class=""section-label-jp"" aria-hidden=""true"">$($config.homepageFeature.kanji)</span>")
    $indexLines.Add("  <h2 class=""section-label-en"">$([System.Net.WebUtility]::HtmlEncode($featureCat.label))</h2>")
    $indexLines.Add('  <div class="section-label-line"></div>')
    $indexLines.Add("  <a href=""categories/$($featureCat.slug).html"" class=""section-label-link"">All articles <span class=""arrow"">&rarr;</span></a>")
    $indexLines.Add('</div>')
    $indexLines.Add('<div class="culture-grid">')
    $indexLines.Add($cultureHtml)
    $indexLines.Add('</div>')
}

# Interlude
$indexLines.Add('<div class="interlude" aria-hidden="true">')
$indexLines.Add('  <div class="interlude-kanji">&#26053;&#25991;&#21270;</div>')
$indexLines.Add('  <div class="interlude-inner">')
$indexLines.Add('    <div class="interlude-lines"><div class="iline"></div><span class="isymbol">&#9961;</span><div class="iline"></div></div>')
$indexLines.Add('    <p class="interlude-label">The TABI Philosophy</p>')
$indexLines.Add('    <p class="interlude-quote">Japan is not a destination.<br><strong>It is a way of seeing.</strong></p>')
$indexLines.Add('    <p class="interlude-sub">From ancient forest temples to 4am ramen counters &mdash; we find the Japan worth knowing.</p>')
$indexLines.Add('  </div>')
$indexLines.Add('</div>')

# Things to Buy section
if ($buyHtml) {
    $indexLines.Add('<div class="section-label">')
    $indexLines.Add('  <span class="section-label-jp" aria-hidden="true">&#36023;&#29289;</span>')
    $indexLines.Add('  <h2 class="section-label-en">Things to Buy</h2>')
    $indexLines.Add('  <div class="section-label-line"></div>')
    $indexLines.Add('  <a href="categories/things-to-buy.html" class="section-label-link">All guides <span class="arrow">&rarr;</span></a>')
    $indexLines.Add('</div>')
    $indexLines.Add('<div class="buy-grid">')
    $indexLines.Add($buyHtml)
    $indexLines.Add('</div>')
}

# Newsletter
$nlAction = if ($config.beehiivUrl) { $config.beehiivUrl } else { '#' }
$nlMethod  = if ($config.beehiivUrl) { 'get' } else { 'post' }
$nlTarget  = if ($config.beehiivUrl) { ' target="_blank" rel="noopener"' } else { '' }
$indexLines.Add('<div class="newsletter-wrap" id="newsletter">')
$indexLines.Add('  <div class="newsletter">')
$indexLines.Add('    <div class="nl-visual" aria-hidden="true">')
$indexLines.Add('      <div class="nl-visual-kanji">&#26053;</div>')
$indexLines.Add('      <div class="nl-visual-badge"><span class="nl-badge-en">Weekly</span><span class="nl-badge-main">TABI</span><div class="nl-badge-accent"></div></div>')
$indexLines.Add('    </div>')
$indexLines.Add('    <div class="nl-content">')
$indexLines.Add('      <p class="nl-label">Free Newsletter</p>')
$indexLines.Add('      <h2 class="nl-title">Japan, delivered<br>to your inbox.</h2>')
$indexLines.Add('      <p class="nl-desc">Every Friday: one destination, one cultural insight, one thing worth buying. No noise. Just the Japan worth knowing.</p>')
$indexLines.Add("      <form class=""nl-form"" action=""$nlAction"" method=""$nlMethod""$nlTarget>")
$indexLines.Add('        <input class="nl-input" type="email" name="email" placeholder="your@email.com" required aria-label="Email address">')
$indexLines.Add('        <button class="nl-btn" type="submit">Subscribe</button>')
$indexLines.Add('      </form>')
$indexLines.Add('      <p class="nl-note">No spam. Unsubscribe anytime.</p>')
$indexLines.Add('    </div>')
$indexLines.Add('  </div>')
$indexLines.Add('</div>')

$indexLines.Add('</main>')
$indexLines.Add($footerHtml)
[System.IO.File]::WriteAllText("$root\index.html", ($indexLines -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Generated index.html"

# ===== ARTICLE PAGES =====
Write-Host "Generating $($articles.Count) article pages..."

# Pre-build per-category sorted lists for prev/next navigation
$catPeersMap = @{}
foreach ($c in $config.categories) {
    $catPeersMap[$c.slug] = @($articles | Where-Object { $_.category -eq $c.slug } | Sort-Object { $_.publishedAt } -Descending)
}

foreach ($a in $articles) {
    $title    = [System.Net.WebUtility]::HtmlEncode($a.title)
    $excerpt  = if ($a.excerpt) { [System.Net.WebUtility]::HtmlEncode($a.excerpt) } elseif ($a.summary) { [System.Net.WebUtility]::HtmlEncode($a.summary) } else { '' }
    $cat      = Get-CategoryLabel $a.category
    $date     = Format-Date $a.publishedAt
    $canonical = "$siteUrl/articles/$($a.id).html"
    $ogImg    = if ($a.heroImage) { $a.heroImage } else { '' }

    $catLabel  = Get-CategoryLabel $a.category
    $imgForSchema = if ($a.heroImage) { """$(Escape-Json $a.heroImage)""" } else { 'null' }
    $updatedAt = if ($a.updatedAt) { $a.updatedAt } else { $a.publishedAt }
    $articleSchema = "{""@context"":""https://schema.org"",""@type"":""Article"",""headline"":""$(Escape-Json $a.title)"",""description"":""$(Escape-Json ($a.excerpt))"",""image"":$imgForSchema,""datePublished"":""$($a.publishedAt)"",""dateModified"":""$updatedAt"",""author"":{""@type"":""Organization"",""name"":""$(Escape-Json $siteName)""},""publisher"":{""@type"":""Organization"",""name"":""$(Escape-Json $siteName)"",""logo"":{""@type"":""ImageObject"",""url"":""$siteUrl/favicon.svg""}},""mainEntityOfPage"":{""@type"":""WebPage"",""@id"":""$canonical""}}"
    $breadcrumbSchema = "{""@context"":""https://schema.org"",""@type"":""BreadcrumbList"",""itemListElement"":[{""@type"":""ListItem"",""position"":1,""name"":""Home"",""item"":""$siteUrl/""},{""@type"":""ListItem"",""position"":2,""name"":""$(Escape-Json $catLabel)"",""item"":""$siteUrl/categories/$($a.category).html""},{""@type"":""ListItem"",""position"":3,""name"":""$(Escape-Json $a.title)"",""item"":""$canonical""}]}"
    $jsonLd = "$articleSchema`n$breadcrumbSchema"

    $headHtml = Get-Head "$title &mdash; $siteName" $excerpt $ogImg $canonical 'article' $jsonLd
    $headerHtml = Get-Header $a.category

    # Article body — sections (with ToC) or legacy flat body
    $bodyHtml = ''
    $tocHtml  = ''
    if ($a.sections -and $a.sections.Count -gt 0) {
        $tocItems = ''
        for ($si = 0; $si -lt $a.sections.Count; $si++) {
            $hText    = [System.Net.WebUtility]::HtmlEncode($a.sections[$si].heading)
            $tocItems += "<li><a href=""#s$si"">$hText</a></li>"
        }
        $tocHtml = "<nav class=""toc"" aria-label=""Article contents""><p class=""toc-title"">In this article</p><ol class=""toc-list"">$tocItems</ol></nav>"
        # The mid-article unit goes after a whole section rather than between
        # paragraphs, so it never splits an argument in half. Suppressed on short
        # articles, where it would land on top of the conclusion.
        $adAfter = Get-AdAfterSection
        if ($a.sections.Count -lt ($adAfter + 2)) { $adAfter = 0 }
        for ($si = 0; $si -lt $a.sections.Count; $si++) {
            $sec   = $a.sections[$si]
            $hText = [System.Net.WebUtility]::HtmlEncode($sec.heading)
            $bodyHtml += "<section class=""article-section""><h2 id=""s$si"">$hText</h2>"
            if ($sec.paragraphs) {
                foreach ($p in $sec.paragraphs) {
                    $bodyHtml += "<p>$([System.Net.WebUtility]::HtmlEncode($p))</p>"
                }
            }
            $bodyHtml += "</section>`n"
            if ($adAfter -gt 0 -and $si -eq ($adAfter - 1)) {
                $bodyHtml += (Get-InArticleAd)
            }
        }
    } elseif ($a.body -and $a.body.Count -gt 0) {
        foreach ($p in $a.body) {
            $bodyHtml += "<p>$([System.Net.WebUtility]::HtmlEncode($p))</p>`n"
        }
    }

    # Tags
    $tagsHtml = ''
    if ($a.tags) {
        foreach ($tag in $a.tags) {
            $tagsHtml += "<a href=""tags/$tag.html"" class=""article-tag"">$tag</a>"
        }
    }

    # Share bar
    $tweetUrl  = [System.Uri]::EscapeDataString($canonical)
    $tweetText = [System.Uri]::EscapeDataString($a.title)
    $shareHtml = "<div class=""share-bar""><span class=""share-label"">Share</span><a href=""https://twitter.com/intent/tweet?url=$tweetUrl&amp;text=$tweetText"" class=""share-btn share-x"" target=""_blank"" rel=""noopener noreferrer"" aria-label=""Share on X"">X / Twitter</a><button class=""share-btn share-copy"" data-url=""$canonical"" aria-label=""Copy link"">Copy link</button></div>"

    # Related articles
    $relatedHtml = ''
    if ($a.relatedIds -and $a.relatedIds.Count -gt 0) {
        $relatedArticles = @($articles | Where-Object { $a.relatedIds -contains $_.id })
        if ($relatedArticles.Count -gt 0) {
            $relatedCards = ($relatedArticles | ForEach-Object { Get-ArticleCard $_ 'sub' }) -join ''
            $relatedHtml = "<section class=""related-articles""><h2 class=""related-title"">Related Articles</h2><div class=""related-grid"">$relatedCards</div></section>"
        }
    }

    # Affiliate links -- per-article, hand-written in articles.json.
    # rel carries "sponsored" as well as nofollow; Google reads a paid link without
    # it as an undisclosed link scheme.
    $affiliateHtml = ''
    if ($a.affiliate -and $a.affiliateLinks -and $a.affiliateLinks.Count -gt 0) {
        $affiliateHtml = '<div class="affiliate-block"><p class="affiliate-block-label">Where to Buy</p>'
        foreach ($link in $a.affiliateLinks) {
            $label = [System.Net.WebUtility]::HtmlEncode($link.label)
            $price = if ($link.price) { "<span class=""affiliate-price"">$([System.Net.WebUtility]::HtmlEncode($link.price))</span>" } else { '' }
            $affiliateHtml += "<a href=""$($link.url)"" class=""affiliate-link"" target=""_blank"" rel=""nofollow sponsored noopener noreferrer"">$label $price</a>"
        }
        $affiliateHtml += '</div>'
    }

    # Contextual partner block, chosen from site.config.json by category and tags.
    $partnerHtml    = Get-PartnerBox $a
    $disclosureHtml = Get-AffiliateDisclosure $a

    # Breadcrumb
    $breadcrumbHtml = "<nav class=""breadcrumb"" aria-label=""Breadcrumb""><a href=""index.html"">Home</a><span class=""breadcrumb-sep"" aria-hidden=""true"">&#8250;</span><a href=""categories/$($a.category).html"">$cat</a><span class=""breadcrumb-sep"" aria-hidden=""true"">&#8250;</span><span class=""breadcrumb-current"">$title</span></nav>"

    # Prev / Next navigation (same category, sorted newest-first)
    $prevNextHtml = ''
    $peers = if ($catPeersMap.ContainsKey($a.category)) { $catPeersMap[$a.category] } else { @() }
    $peerIdx = -1
    for ($pi = 0; $pi -lt $peers.Count; $pi++) {
        if ($peers[$pi].id -eq $a.id) { $peerIdx = $pi; break }
    }
    if ($peers.Count -gt 1) {
        $prevA = if ($peerIdx -lt $peers.Count - 1) { $peers[$peerIdx + 1] } else { $null }  # older
        $nextA = if ($peerIdx -gt 0)                { $peers[$peerIdx - 1] } else { $null }  # newer
        $prevHtml = if ($prevA) {
            "<a href=""articles/$($prevA.id).html"" class=""prev-next-link prev-next-prev""><span class=""prev-next-label"">&larr; Previous</span><span class=""prev-next-title"">$([System.Net.WebUtility]::HtmlEncode($prevA.title))</span></a>"
        } else {
            "<span class=""prev-next-link prev-next-prev"" aria-hidden=""true""></span>"
        }
        $nextHtml = if ($nextA) {
            "<a href=""articles/$($nextA.id).html"" class=""prev-next-link prev-next-next""><span class=""prev-next-label"">Next &rarr;</span><span class=""prev-next-title"">$([System.Net.WebUtility]::HtmlEncode($nextA.title))</span></a>"
        } else {
            "<span class=""prev-next-link prev-next-next"" aria-hidden=""true""></span>"
        }
        $prevNextHtml = "<nav class=""prev-next"" aria-label=""More in $cat"">$prevHtml$nextHtml</nav>"
    }

    # Hero image
    $heroHtml = ''
    if ($a.heroImage) {
        $credit = if ($a.heroImageCredit) { "<span class=""img-credit"">Image: $([System.Net.WebUtility]::HtmlEncode($a.heroImageCredit))</span>" } else { '' }
        $heroHtml = @"
<div class="article-hero">
  <img src="$(Get-ImageSrc $a.heroImage)" alt="$([System.Net.WebUtility]::HtmlEncode($a.heroImageAlt))" loading="eager" fetchpriority="high" decoding="async"$(Get-ImageSrcset $a.heroImage '100vw')$(Get-ImageDimAttr $a.heroImage)>
  <div class="article-hero-overlay"></div>
  $credit
</div>
"@
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($headHtml)
    $lines.Add('<body>')
    $lines.Add('<div class="progress-bar" aria-hidden="true"></div>')
    $lines.Add((Get-TopBar))
    $lines.Add($headerHtml)
    $lines.Add('<main id="main">')
    $lines.Add($heroHtml)
    $lines.Add('<div class="article-wrap">')
    $lines.Add($breadcrumbHtml)
    $lines.Add("  <div class=""article-eyebrow"">")
    $lines.Add("    <span class=""article-cat cat--$($a.category)"">$cat</span>")
    $lines.Add('    <span class="article-dot"></span>')
    $lines.Add("    <span class=""article-date"">$date</span>")
    $lines.Add('    <span class="article-dot"></span>')
    $lines.Add("    <span class=""article-reading"">$($a.readingTime) min read</span>")
    $lines.Add("  </div>")
    $lines.Add("  <h1 class=""article-title"">$title</h1>")
    $lines.Add("  <p class=""article-excerpt"">$excerpt</p>")
    # Above the fold and above the first paid link, which is where the FTC expects
    # the disclosure -- not in the footer.
    if ($disclosureHtml) { $lines.Add($disclosureHtml) }
    $lines.Add($tocHtml)
    $lines.Add('  <div class="article-body">')
    $lines.Add($bodyHtml)
    $lines.Add($affiliateHtml)
    if ($partnerHtml) { $lines.Add($partnerHtml) }
    $lines.Add('  </div>')
    if ($tagsHtml) {
        $lines.Add("  <div class=""article-tags"">$tagsHtml</div>")
    }
    $lines.Add($shareHtml)
    $endAd = Get-EndOfArticleAd
    if ($endAd) { $lines.Add($endAd) }
    $lines.Add($prevNextHtml)
    $lines.Add('</div>')
    if ($relatedHtml) { $lines.Add($relatedHtml) }
    $lines.Add('</main>')
    $lines.Add((Get-Footer))

    [System.IO.File]::WriteAllText("$root\articles\$($a.id).html", ($lines -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
}
Write-Host "Generated $($articles.Count) article pages"

# ===== CATEGORY PAGES =====
Write-Host "Generating category pages..."
# Stale files, including page-2+ files from a run when a category was larger.
$validCategoryFiles = @()
foreach ($cat in $config.categories) {
    $n = @($articles | Where-Object { $_.category -eq $cat.slug }).Count
    $pages = [Math]::Max(1, [Math]::Ceiling($n / 12.0))
    for ($i = 1; $i -le $pages; $i++) {
        $validCategoryFiles += if ($i -eq 1) { "$($cat.slug).html" } else { "$($cat.slug)-$i.html" }
    }
}
Get-ChildItem "$root\categories" -Filter *.html | Where-Object { $validCategoryFiles -notcontains $_.Name } | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName
}

foreach ($cat in $config.categories) {
    $catArticles = $articles | Where-Object { $_.category -eq $cat.slug } | Sort-Object { $_.publishedAt } -Descending
    $n = Write-ListingPages $catArticles "categories/$($cat.slug)" $cat.label `
        "Browse all $($cat.label) articles on $siteName." '' $cat.slug
    Write-Host "  Generated categories/$($cat.slug).html ($(@($catArticles).Count) articles, $n page(s))"
}

# ===== ALL ARTICLES ARCHIVE =====
# The homepage grid shows the 4 most recent articles regardless of category, so its
# "All articles" link needs a real archive to point at. That link and the hero button
# both used to point at a category page that does not exist.
Write-Host "Generating articles.html..."
$archiveArticles = $articles | Sort-Object { $_.publishedAt } -Descending
Get-ChildItem $root -Filter 'articles-*.html' | ForEach-Object { Remove-Item -LiteralPath $_.FullName }
$n = Write-ListingPages $archiveArticles 'articles' 'All Articles' `
    "Every guide on $siteName - travelling, eating and living well in Japan." '&#26053;'
Write-Host "  Generated articles.html ($(@($archiveArticles).Count) articles, $n page(s))"

# ===== TAG PAGES =====
Write-Host "Generating tag pages..."
# Generate pages for configured tags and every tag currently used by articles.
$articleTags = @($articles | ForEach-Object { if ($_.tags) { $_.tags } })
$allTags = @($config.tags + $articleTags | Where-Object { $_ } | Sort-Object -Unique)

$validTagFiles = @()
foreach ($tag in $allTags) {
    $n = @($articles | Where-Object { $_.tags -and $_.tags -contains $tag }).Count
    $pages = [Math]::Max(1, [Math]::Ceiling($n / 12.0))
    for ($i = 1; $i -le $pages; $i++) {
        $validTagFiles += if ($i -eq 1) { "$tag.html" } else { "$tag-$i.html" }
    }
}
Get-ChildItem "$root\tags" -Filter *.html | Where-Object { $validTagFiles -notcontains $_.Name } | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName
}

foreach ($tag in $allTags) {
    $tagArticles = $articles | Where-Object { $_.tags -and $_.tags -contains $tag } | Sort-Object { $_.publishedAt } -Descending
    Write-ListingPages $tagArticles "tags/$tag" "#$tag" "Articles tagged $tag on $siteName." | Out-Null
}
Write-Host "Generated $($allTags.Count) tag pages"

# ===== 404.html =====
$headHtml = Get-Head "Page Not Found &mdash; $siteName" "The page you are looking for could not be found." '' "$siteUrl/404.html"
$headerHtml = Get-Header
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add($headHtml)
$lines.Add('<body>')
$lines.Add((Get-TopBar))
$lines.Add($headerHtml)
$lines.Add('<main id="main">')
$lines.Add('<div style="max-width:640px;margin:120px auto;padding:0 32px;text-align:center;">')
$lines.Add('  <p style="font-family:var(--serif);font-size:6rem;color:var(--border);line-height:1;">404</p>')
$lines.Add('  <h1 style="font-family:var(--serif);font-size:1.8rem;margin:16px 0 12px;">Page not found</h1>')
$lines.Add('  <p style="color:var(--mist);margin-bottom:32px;">The page you&#8217;re looking for doesn&#8217;t exist or has moved.</p>')
$lines.Add('  <a href="index.html" style="display:inline-block;background:var(--accent);color:#fff;padding:12px 28px;font-size:0.82rem;font-weight:600;letter-spacing:0.1em;text-transform:uppercase;">&larr; Back to Home</a>')
$lines.Add('</div>')
$lines.Add('</main>')
$lines.Add((Get-Footer))
[System.IO.File]::WriteAllText("$root\404.html", ($lines -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Generated 404.html"

Write-Host "`nAll pages generated successfully."

# ===== STATIC STUB PAGES =====
Write-Host "Generating static pages..."

$staticPages = @(
    @{
        file    = 'about.html'
        title   = "About TABI &mdash; $siteName"
        heading = 'About TABI'
        body    = @(
            '<p>TABI is an independent guide to Japan for international travellers.</p>',
            '<p>We cover travel, culture, food, and the things worth bringing home &mdash; written by people who actually live here.</p>',
            '<p>Questions or pitches? <a href="contact.html">Get in touch.</a></p>'
        )
    },
    @{
        file    = 'newsletter.html'
        title   = "Newsletter &mdash; $siteName"
        heading = 'The TABI Newsletter'
        body    = @(
            '<p>Every Friday: one destination, one cultural insight, one thing worth buying. No noise. Just the Japan worth knowing.</p>',
            $(if ($config.beehiivUrl) {
                "<form class=""nl-form"" action=""$($config.beehiivUrl)"" method=""get"" target=""_blank"" rel=""noopener"" style=""margin-top:24px;"">"
            } else {
                '<form class="nl-form" action="#" method="post" style="margin-top:24px;">'
            }),
            '  <input class="nl-input" type="email" name="email" placeholder="your@email.com" required aria-label="Email address">',
            '  <button class="nl-btn" type="submit">Subscribe</button>',
            '</form>',
            '<p class="nl-note" style="margin-top:12px;">No spam. Unsubscribe anytime.</p>'
        )
    },
    @{
        file    = 'contact.html'
        title   = "Contact &mdash; $siteName"
        heading = 'Contact'
        body    = @(
            '<p>For editorial enquiries, article pitches, or partnership proposals:</p>',
            "<p><a href=""mailto:$($config.contactEmail)"">$($config.contactEmail)</a></p>",
            '<p style="margin-top:24px;color:var(--mist);font-size:0.85rem;">We read every email and aim to reply within 3 business days.</p>'
        )
    },
    @{
        file    = 'privacy.html'
        title   = "Privacy Policy &mdash; $siteName"
        heading = 'Privacy Policy'
        body    = @(
            '<p style="color:var(--mist);font-size:0.82rem;">Last updated: June 2026</p>',
            '<p>TABI collects minimal data to operate the site. We may use analytics tools (such as Google Analytics) to understand how visitors use our content. No personal data is sold to third parties.</p>',
            '<h2 style="font-size:1.05rem;margin:28px 0 10px;">Cookies</h2>',
            '<p>We may set cookies for analytics and functionality. Nothing that sets a cookie loads until you accept the banner, and you can disable cookies in your browser settings at any time.</p>',
            $(if (Test-AdsEnabled) {
                '<h2 style="font-size:1.05rem;margin:28px 0 10px;">Advertising</h2>' +
                '<p>TABI displays ads served by Google AdSense. Google and its partners may use cookies to serve ads based on your prior visits to this or other websites, and may process your data as described in <a href="https://policies.google.com/technologies/partner-sites" target="_blank" rel="noopener noreferrer">how Google uses information from sites that use its services</a>. Ad scripts are only loaded after you accept cookies; if you decline, no ad request is made. You can also opt out of personalised advertising at <a href="https://www.google.com/settings/ads" target="_blank" rel="noopener noreferrer">Google Ads Settings</a>.</p>'
            } else { '' }),
            '<h2 style="font-size:1.05rem;margin:28px 0 10px;">Affiliate Links</h2>',
            '<p>Some links on this site are affiliate links. Clicking them and making a purchase may earn TABI a small commission at no extra cost to you. See our <a href="affiliate.html">Affiliate Disclosure</a> for details.</p>',
            "<h2 style=""font-size:1.05rem;margin:28px 0 10px;"">Contact</h2>",
            "<p>Questions about privacy? Email us at <a href=""mailto:$($config.contactEmail)"">$($config.contactEmail)</a>.</p>"
        )
    },
    @{
        file    = 'terms.html'
        title   = "Terms of Use &mdash; $siteName"
        heading = 'Terms of Use'
        body    = @(
            '<p style="color:var(--mist);font-size:0.82rem;">Last updated: June 2026</p>',
            '<p>By using TABI you agree to these terms. All content on this site is for informational purposes only. We make no guarantees about the accuracy or completeness of travel information, which can change without notice.</p>',
            '<h2 style="font-size:1.05rem;margin:28px 0 10px;">Intellectual Property</h2>',
            '<p>All text, images, and design on TABI are &copy; TABI unless otherwise noted. Do not reproduce content without written permission.</p>',
            '<h2 style="font-size:1.05rem;margin:28px 0 10px;">External Links</h2>',
            '<p>TABI links to third-party sites for convenience. We are not responsible for their content or practices.</p>'
        )
    },
    @{
        file    = 'affiliate.html'
        title   = "Affiliate Disclosure &mdash; $siteName"
        heading = 'Affiliate Disclosure'
        body    = @(
            '<p>TABI participates in affiliate programmes. This means that some links to products or services may be affiliate links &mdash; if you click through and make a purchase, we may earn a small commission at no additional cost to you.</p>',
            '<p>We only recommend products and services we genuinely believe in. Affiliate relationships do not influence our editorial content or opinions. Nothing is ranked, added or removed because of what it pays.</p>',
            '<p>Affiliate links are marked with <strong>rel="nofollow sponsored"</strong> in our HTML, sit inside a labelled block rather than the article text, and every article carrying one shows a disclosure above the fold.</p>',
            # Listing the programmes is the part readers can actually check, so it is
            # generated from the live config rather than written by hand and left stale.
            $(
                $mon    = Get-Mon
                $active = if ($mon -and $mon.partners) { @($mon.partners | Where-Object { $_.url }) } else { @() }
                if ($active.Count -gt 0) {
                    '<h2 style="font-size:1.05rem;margin:28px 0 10px;">Programmes We Use</h2><ul style="margin:0 0 8px 18px;line-height:2;">' +
                    (($active | ForEach-Object { "<li>$([System.Net.WebUtility]::HtmlEncode($_.name))</li>" }) -join '') + '</ul>'
                } else { '' }
            ),
            "<p style=""margin-top:24px;"">Questions? <a href=""contact.html"">Contact us.</a></p>"
        )
    }
)

foreach ($page in $staticPages) {
    $canonical = "$siteUrl/$($page.file)"
    $headHtml  = Get-Head $page.title $config.description '' $canonical
    $headerHtml = Get-Header

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($headHtml)
    $lines.Add('<body>')
    $lines.Add('<div class="progress-bar" aria-hidden="true"></div>')
    $lines.Add((Get-TopBar))
    $lines.Add($headerHtml)
    $lines.Add('<main id="main" style="max-width:720px;margin:80px auto 120px;padding:0 32px;">')
    $lines.Add("  <h1 style=""font-family:var(--serif);font-size:2rem;font-weight:300;margin-bottom:28px;letter-spacing:-0.01em;"">$($page.heading)</h1>")
    foreach ($line in $page.body) {
        # Sections that depend on config (ads, affiliate programmes) render as an
        # empty string when unconfigured; skip them rather than leaving a blank line.
        if ($line) { $lines.Add("  $line") }
    }
    $lines.Add('</main>')
    $lines.Add((Get-Footer))

    [System.IO.File]::WriteAllText("$root\$($page.file)", ($lines -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  Generated $($page.file)"
}
