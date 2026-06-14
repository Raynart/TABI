# generate-pages.ps1 — TABI
# Generates: index.html, articles/*.html, categories/*.html, tags/*.html, 404.html

$ErrorActionPreference = 'Stop'
$root     = Split-Path $PSScriptRoot -Parent
$config   = Get-Content "$root\site.config.json"  -Raw -Encoding UTF8 | ConvertFrom-Json
$articles = Get-Content "$root\articles.json" -Raw -Encoding UTF8 | ConvertFrom-Json

$siteUrl  = $config.siteUrl
$siteName = $config.siteName
$tagline  = $config.tagline

# Ensure output directories exist
@('articles','categories','tags') | ForEach-Object {
    $d = "$root\$_"
    if (-not (Test-Path $d)) { New-Item -ItemType Directory $d | Out-Null }
}

# ===== HELPERS =====

function Escape-Json {
    param($str)
    if (-not $str) { return '' }
    return ($str -replace '\\', '\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '' -replace "`t", '\t')
}

function Get-FontLink {
    return '<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Noto+Serif+JP:wght@300;400;700&amp;family=Noto+Serif:ital,wght@0,300;0,400;0,700;1,300;1,400&amp;family=Noto+Sans:wght@300;400;500;600&amp;display=swap" rel="stylesheet">'
}

function Get-Head {
    param($title, $desc, $og, $canonical, $ogType = 'website', $jsonLd = '')
    $font = Get-FontLink

    # GA4 — only emitted when googleAnalyticsId is set
    $gaScript = ''
    if ($config.googleAnalyticsId) {
        $gaId = $config.googleAnalyticsId
        $gaScript = "  <script async src=""https://www.googletagmanager.com/gtag/js?id=$gaId""></script>`n  <script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag('js',new Date());gtag('config','$gaId');</script>"
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
  <meta property="og:image" content="$og">
  <meta property="og:url" content="$canonical">
  <meta property="og:type" content="$ogType">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="$title">
  <meta name="twitter:description" content="$desc">
  <meta name="twitter:image" content="$og">
  <link rel="canonical" href="$canonical">
  <link rel="icon" type="image/svg+xml" href="favicon.svg">
  <link rel="stylesheet" href="styles.css">
  <link rel="alternate" type="application/rss+xml" title="$siteName RSS" href="rss.xml">
  $font
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
<header class="site-header">
  <div class="header-inner">
    <ul class="header-nav" role="navigation" aria-label="Main navigation">
      $navItems
    </ul>
    <a href="index.html" class="site-logo" aria-label="$siteName home">
      <span class="logo-en">$siteName<span class="dot">.</span></span>
      <span class="logo-jp">&#26053; &#8212; $tagline</span>
    </a>
    <div class="header-right">
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
<script src="script.js"></script>
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

# ===== ARTICLE CARDS (used in index + category pages) =====
function Get-ArticleCard {
    param($article, $size = 'sub')  # 'main' or 'sub'
    $cat   = Get-CategoryLabel $article.category
    $date  = Format-Date $article.publishedAt
    $title = [System.Net.WebUtility]::HtmlEncode($article.title)
    $img   = if ($article.heroImage) { $article.heroImage } else { '' }
    $strip = if ($size -eq 'main') { '<div class="ed-main-strip">&#29305;&#38598;</div>' } else { '' }
    $imgTag = if ($img) {
        "<img data-src=""$img"" alt=""$([System.Net.WebUtility]::HtmlEncode($article.heroImageAlt))"" class=""ed-img"" loading=""lazy"">"
    } else {
        '<div class="ed-img" style="width:100%;height:100%;background:linear-gradient(160deg,#100808 0%,#2e1010 40%,#5a1a1a 100%);"></div>'
    }
    return @"
<a href="articles/$($article.id).html" class="ed-card ed-$size">
  $imgTag
  <div class="ed-overlay"></div>
  $strip
  <div class="ed-content">
    <p class="ed-cat">$cat</p>
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
$cultureArticles = $articles | Where-Object { $_.category -eq 'culture' } | Sort-Object { $_.publishedAt } -Descending | Select-Object -First 3
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
    $img   = if ($a.heroImage) { "<img data-src=""$($a.heroImage)"" alt=""$([System.Net.WebUtility]::HtmlEncode($a.heroImageAlt))"" loading=""lazy"" style=""width:100%;height:100%;object-fit:cover;"">" } else { "<div style=""width:100%;height:100%;background:var(--ink-soft);""></div>" }
    $numStr = $ci.ToString().PadLeft(2, '0')
    $cultureHtml += @"
<a href="articles/$($a.id).html" class="culture-card">
  <p class="culture-num">$numStr</p>
  <div class="culture-card-img">$img</div>
  <p class="culture-card-cat">$cat</p>
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
$indexLines.Add('<div class="progress-bar" role="progressbar" aria-hidden="true"></div>')
$indexLines.Add($topBarHtml)
$indexLines.Add($headerHtml)
$indexLines.Add($tickerHtml)

# Hero
$indexLines.Add('<section class="hero" aria-label="Featured article">')
$indexLines.Add('  <div class="hero-bg"></div>')
$indexLines.Add('  <div class="hero-pattern"></div>')
$indexLines.Add("  <div class=""hero-kanji"" aria-hidden=""true"">$heroKanji</div>")
$indexLines.Add('  <div class="hero-line"></div>')
if ($heroImg) {
    $indexLines.Add("  <img src=""$heroImg"" alt=""$heroTitle"" style=""position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:0.35;"" loading=""eager"">")
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
$indexLines.Add("      <a href=""categories/travel-guide.html"" class=""hero-btn-ghost"">Browse all guides</a>")
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
    $indexLines.Add('  <a href="categories/travel-guide.html" class="section-label-link">All articles <span class="arrow">&rarr;</span></a>')
    $indexLines.Add('</div>')
    $indexLines.Add('<div class="editorial-grid">')
    $indexLines.Add($gridHtml)
    $indexLines.Add('</div>')
}

# Culture section
if ($cultureHtml) {
    $indexLines.Add('<div class="section-label">')
    $indexLines.Add('  <span class="section-label-jp" aria-hidden="true">&#25991;&#21270;</span>')
    $indexLines.Add('  <h2 class="section-label-en">Culture &amp; Tradition</h2>')
    $indexLines.Add('  <div class="section-label-line"></div>')
    $indexLines.Add('  <a href="categories/culture.html" class="section-label-link">All articles <span class="arrow">&rarr;</span></a>')
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

$indexLines.Add($footerHtml)
[System.IO.File]::WriteAllText("$root\index.html", ($indexLines -join "`n"), [System.Text.Encoding]::UTF8)
Write-Host "Generated index.html"

# ===== ARTICLE PAGES =====
Write-Host "Generating $($articles.Count) article pages..."
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

    # Body paragraphs
    $bodyHtml = ''
    if ($a.body -and $a.body.Count -gt 0) {
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

    # Affiliate links
    $affiliateHtml = ''
    if ($a.affiliate -and $a.affiliateLinks -and $a.affiliateLinks.Count -gt 0) {
        $affiliateHtml = '<div class="affiliate-block"><p class="affiliate-block-label">Where to Buy</p>'
        foreach ($link in $a.affiliateLinks) {
            $label = [System.Net.WebUtility]::HtmlEncode($link.label)
            $price = if ($link.price) { "<span class=""affiliate-price"">$([System.Net.WebUtility]::HtmlEncode($link.price))</span>" } else { '' }
            $affiliateHtml += "<a href=""$($link.url)"" class=""affiliate-link"" target=""_blank"" rel=""noopener noreferrer nofollow"">$label $price</a>"
        }
        $affiliateHtml += '</div>'
    }

    # Hero image
    $heroHtml = ''
    if ($a.heroImage) {
        $credit = if ($a.heroImageCredit) { "<span class=""img-credit"">Image: $([System.Net.WebUtility]::HtmlEncode($a.heroImageCredit))</span>" } else { '' }
        $heroHtml = @"
<div class="article-hero">
  <img src="$($a.heroImage)" alt="$([System.Net.WebUtility]::HtmlEncode($a.heroImageAlt))" loading="eager">
  <div class="article-hero-overlay"></div>
  $credit
</div>
"@
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($headHtml)
    $lines.Add('<body>')
    $lines.Add('<div class="progress-bar" role="progressbar" aria-hidden="true"></div>')
    $lines.Add((Get-TopBar))
    $lines.Add($headerHtml)
    $lines.Add($heroHtml)
    $lines.Add('<main class="article-wrap">')
    $lines.Add("  <div class=""article-eyebrow"">")
    $lines.Add("    <span class=""article-cat"">$cat</span>")
    $lines.Add('    <span class="article-dot"></span>')
    $lines.Add("    <span class=""article-date"">$date</span>")
    $lines.Add('    <span class="article-dot"></span>')
    $lines.Add("    <span class=""article-reading"">$($a.readingTime) min read</span>")
    $lines.Add("  </div>")
    $lines.Add("  <h1 class=""article-title"">$title</h1>")
    $lines.Add("  <p class=""article-excerpt"">$excerpt</p>")
    $lines.Add('  <div class="article-body">')
    $lines.Add($bodyHtml)
    $lines.Add($affiliateHtml)
    $lines.Add('  </div>')
    if ($tagsHtml) {
        $lines.Add("  <div class=""article-tags"">$tagsHtml</div>")
    }
    $lines.Add('</main>')
    $lines.Add((Get-Footer))

    [System.IO.File]::WriteAllText("$root\articles\$($a.id).html", ($lines -join "`n"), [System.Text.Encoding]::UTF8)
}
Write-Host "Generated $($articles.Count) article pages"

# ===== CATEGORY PAGES =====
Write-Host "Generating category pages..."
foreach ($cat in $config.categories) {
    $catArticles = $articles | Where-Object { $_.category -eq $cat.slug } | Sort-Object { $_.publishedAt } -Descending
    $canonical = "$siteUrl/categories/$($cat.slug).html"
    $catBreadcrumb = "{""@context"":""https://schema.org"",""@type"":""BreadcrumbList"",""itemListElement"":[{""@type"":""ListItem"",""position"":1,""name"":""Home"",""item"":""$siteUrl/""},{""@type"":""ListItem"",""position"":2,""name"":""$(Escape-Json $cat.label)"",""item"":""$canonical""}]}"
    $headHtml  = Get-Head "$($cat.label) &mdash; $siteName" "Browse all $($cat.label) articles on $siteName." '' $canonical 'website' $catBreadcrumb
    $headerHtml = Get-Header $cat.slug

    $cardsHtml = ''
    $isFirst = $true
    foreach ($a in $catArticles) {
        $size = if ($isFirst) { 'main'; $isFirst = $false } else { 'sub' }
        $cardsHtml += Get-ArticleCard $a $size
    }
    if (-not $cardsHtml) {
        $cardsHtml = '<p style="padding:48px 32px;color:var(--mist);">No articles yet. Check back soon.</p>'
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($headHtml)
    $lines.Add('<body>')
    $lines.Add('<div class="progress-bar" role="progressbar" aria-hidden="true"></div>')
    $lines.Add((Get-TopBar))
    $lines.Add($headerHtml)
    $lines.Add('<div class="section-label">')
    $lines.Add("  <h1 class=""section-label-en"">$($cat.label)</h1>")
    $lines.Add('  <div class="section-label-line"></div>')
    $lines.Add("  <span style=""font-size:0.78rem;color:var(--mist);"">$($catArticles.Count) articles</span>")
    $lines.Add('</div>')
    $lines.Add('<div class="editorial-grid">')
    $lines.Add($cardsHtml)
    $lines.Add('</div>')
    $lines.Add((Get-Footer))

    [System.IO.File]::WriteAllText("$root\categories\$($cat.slug).html", ($lines -join "`n"), [System.Text.Encoding]::UTF8)
    Write-Host "  Generated categories/$($cat.slug).html ($($catArticles.Count) articles)"
}

# ===== TAG PAGES =====
Write-Host "Generating tag pages..."
# Only generate pages for the 15 canonical tags defined in site.config.json
$allTags = $config.tags
foreach ($tag in $allTags) {
    $tagArticles = $articles | Where-Object { $_.tags -and $_.tags -contains $tag } | Sort-Object { $_.publishedAt } -Descending
    $canonical = "$siteUrl/tags/$tag.html"
    $tagBreadcrumb = "{""@context"":""https://schema.org"",""@type"":""BreadcrumbList"",""itemListElement"":[{""@type"":""ListItem"",""position"":1,""name"":""Home"",""item"":""$siteUrl/""},{""@type"":""ListItem"",""position"":2,""name"":""#$tag"",""item"":""$canonical""}]}"
    $headHtml  = Get-Head "#$tag &mdash; $siteName" "Articles tagged $tag on $siteName." '' $canonical 'website' $tagBreadcrumb
    $headerHtml = Get-Header

    $cardsHtml = ''
    $isFirst = $true
    foreach ($a in $tagArticles) {
        $size = if ($isFirst) { 'main'; $isFirst = $false } else { 'sub' }
        $cardsHtml += Get-ArticleCard $a $size
    }
    if (-not $cardsHtml) {
        $cardsHtml = '<p style="padding:48px 32px;color:var(--mist);">No articles yet.</p>'
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($headHtml)
    $lines.Add('<body>')
    $lines.Add('<div class="progress-bar" role="progressbar" aria-hidden="true"></div>')
    $lines.Add((Get-TopBar))
    $lines.Add($headerHtml)
    $lines.Add('<div class="section-label">')
    $lines.Add("  <h1 class=""section-label-en"">#$tag</h1>")
    $lines.Add('  <div class="section-label-line"></div>')
    $lines.Add("  <span style=""font-size:0.78rem;color:var(--mist);"">$($tagArticles.Count) articles</span>")
    $lines.Add('</div>')
    $lines.Add('<div class="editorial-grid">')
    $lines.Add($cardsHtml)
    $lines.Add('</div>')
    $lines.Add((Get-Footer))

    [System.IO.File]::WriteAllText("$root\tags\$tag.html", ($lines -join "`n"), [System.Text.Encoding]::UTF8)
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
$lines.Add('<div style="max-width:640px;margin:120px auto;padding:0 32px;text-align:center;">')
$lines.Add('  <p style="font-family:var(--serif);font-size:6rem;color:var(--border);line-height:1;">404</p>')
$lines.Add('  <h1 style="font-family:var(--serif);font-size:1.8rem;margin:16px 0 12px;">Page not found</h1>')
$lines.Add('  <p style="color:var(--mist);margin-bottom:32px;">The page you&#8217;re looking for doesn&#8217;t exist or has moved.</p>')
$lines.Add('  <a href="index.html" style="display:inline-block;background:var(--accent);color:#fff;padding:12px 28px;font-size:0.82rem;font-weight:600;letter-spacing:0.1em;text-transform:uppercase;">&larr; Back to Home</a>')
$lines.Add('</div>')
$lines.Add((Get-Footer))
[System.IO.File]::WriteAllText("$root\404.html", ($lines -join "`n"), [System.Text.Encoding]::UTF8)
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
            '<p>We may set cookies for analytics and functionality. You can disable cookies in your browser settings at any time.</p>',
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
            '<p>We only recommend products and services we genuinely believe in. Affiliate relationships do not influence our editorial content or opinions.</p>',
            '<p>Affiliate links are marked with <strong>rel="nofollow sponsored"</strong> in our HTML and may be indicated in the article text.</p>',
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
    $lines.Add('<div class="progress-bar" role="progressbar" aria-hidden="true"></div>')
    $lines.Add((Get-TopBar))
    $lines.Add($headerHtml)
    $lines.Add('<main style="max-width:720px;margin:80px auto 120px;padding:0 32px;">')
    $lines.Add("  <h1 style=""font-family:var(--serif);font-size:2rem;font-weight:300;margin-bottom:28px;letter-spacing:-0.01em;"">$($page.heading)</h1>")
    foreach ($line in $page.body) {
        $lines.Add("  $line")
    }
    $lines.Add('</main>')
    $lines.Add((Get-Footer))

    [System.IO.File]::WriteAllText("$root\$($page.file)", ($lines -join "`n"), [System.Text.Encoding]::UTF8)
    Write-Host "  Generated $($page.file)"
}
