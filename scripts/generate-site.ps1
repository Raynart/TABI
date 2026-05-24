$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Config = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "site.config.json") | ConvertFrom-Json
$Articles = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "articles.json") | ConvertFrom-Json
$EnglishCulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Html([object]$Value) {
  if ($null -eq $Value) { return "" }
  return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function SiteUrl([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { $Path = "/" }
  if (-not $Path.StartsWith("/")) { $Path = "/$Path" }
  return "$($Config.siteUrl.TrimEnd('/'))$Path"
}

function Format-Date([string]$DateValue) {
  $Date = [datetime]::ParseExact($DateValue, "yyyy-MM-dd", $EnglishCulture)
  return $Date.ToString("MMMM d, yyyy", $EnglishCulture)
}

function Get-CategoryLabel([string]$Slug) {
  foreach ($Category in $Config.categories) {
    if ($Category.slug -eq $Slug) { return $Category.label }
  }
  return $Slug
}

function Get-ArticleUrl($Article) {
  return "/articles/$($Article.id).html"
}

function Get-CategoryUrl([string]$Slug) {
  return "/categories/$Slug.html"
}

function Get-TagUrl([string]$Tag) {
  return "/tags/$Tag.html"
}

function Get-BuyIcon($Article) {
  if ($Article.id -like "*knife*") { return "&#128298;" }
  if ($Article.id -like "*matcha*") { return "&#127861;" }
  if ($Article.id -like "*drugstore*") { return "&#129524;" }
  if ($Article.id -like "*yukata*") { return "&#128088;" }
  return "&#10022;"
}

function Write-Page([string]$RelativePath, [string]$Html) {
  $Target = Join-Path $Root $RelativePath
  $Directory = Split-Path $Target -Parent
  if (-not (Test-Path $Directory)) {
    New-Item -ItemType Directory -Force -Path $Directory | Out-Null
  }
  [System.IO.File]::WriteAllText($Target, $Html, $Utf8NoBom)
}

function New-Nav([string]$CurrentCategory) {
  $Items = foreach ($NavItem in $Config.nav) {
    $Current = ""
    if ($NavItem.slug -eq $CurrentCategory) { $Current = ' aria-current="page"' }
    '<li><a href="{0}"{1}>{2}</a></li>' -f (Get-CategoryUrl $NavItem.slug), $Current, (Html $NavItem.label)
  }
  return ($Items -join "`n")
}

function New-SearchJson {
  $Payload = foreach ($Article in $Articles) {
    [pscustomobject]@{
      title = $Article.title
      summary = $Article.summary
      category = $Article.category
      categoryLabel = Get-CategoryLabel $Article.category
      tags = @($Article.tags)
      url = Get-ArticleUrl $Article
    }
  }
  return ($Payload | ConvertTo-Json -Depth 6 -Compress)
}

$Script:SearchJson = New-SearchJson

function New-Head([string]$Title, [string]$Description, [string]$Path, [string]$Image) {
  $Canonical = SiteUrl $Path
  $ImageUrl = if ([string]::IsNullOrWhiteSpace($Image)) { SiteUrl "/assets/images/kyoto-shrine-hero.png" } else { SiteUrl $Image }
  $OgType = if ($Path -like "/articles/*") { "article" } else { "website" }
  return @"
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$(Html $Title)</title>
  <meta name="description" content="$(Html $Description)">
  <link rel="canonical" href="$(Html $Canonical)">
  <meta property="og:type" content="$OgType">
  <meta property="og:site_name" content="$(Html $Config.siteName)">
  <meta property="og:title" content="$(Html $Title)">
  <meta property="og:description" content="$(Html $Description)">
  <meta property="og:url" content="$(Html $Canonical)">
  <meta property="og:image" content="$(Html $ImageUrl)">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="$(Html $Title)">
  <meta name="twitter:description" content="$(Html $Description)">
  <meta name="twitter:image" content="$(Html $ImageUrl)">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Serif+JP:wght@300;400;700&family=Noto+Serif:ital,wght@0,400;0,700;1,400&family=Noto+Sans:wght@400;500;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/styles.css">
</head>
"@
}

function New-Ticker {
  $Latest = @($Articles | Sort-Object publishedAt -Descending | Select-Object -First 6)
  $Items = foreach ($Article in ($Latest + $Latest)) {
    '<span class="ticker-item"><strong>{0}</strong> - {1}</span>' -f (Html (Get-CategoryLabel $Article.category)), (Html $Article.title)
  }
  return @"
<div class="ticker" aria-label="Latest articles">
  <div class="ticker-label">Latest</div>
  <div class="ticker-track">
    $($Items -join "`n")
  </div>
</div>
"@
}

function New-Layout([string]$Title, [string]$Description, [string]$Path, [string]$Main, [string]$CurrentCategory, [string]$Image, [string]$JsonLd) {
  $Head = New-Head $Title $Description $Path $Image
  $Nav = New-Nav $CurrentCategory
  $Ticker = New-Ticker
  $StructuredData = ""
  if (-not [string]::IsNullOrWhiteSpace($JsonLd)) {
    $StructuredData = "<script type=""application/ld+json"">$JsonLd</script>"
  }
  return @"
<!DOCTYPE html>
<html lang="en">
$Head
<body>
<a class="skip-link" href="#main">Skip to content</a>
<div class="top-bar"><span>Japan Travel &amp; Culture Guide</span><span class="top-extra"> / Updated weekly / Free newsletter every Friday</span></div>
<header class="site-header">
  <div class="header-inner">
    <ul class="header-nav">
      $Nav
    </ul>
    <a class="site-logo" href="/" aria-label="TABI home">
      <span class="logo-en">TABI<span class="dot">.</span></span>
      <span class="logo-jp">&#26053; - Discover Japan</span>
    </a>
    <div class="header-actions">
      <button class="header-search" type="button" aria-label="Search articles" title="Search articles" data-search-toggle>&#8981;</button>
      <a class="header-cta" href="#newsletter">Free Newsletter</a>
    </div>
  </div>
</header>
$Ticker
<div class="search-panel" data-search-panel hidden>
  <div class="search-panel-inner" role="dialog" aria-modal="true" aria-label="Search articles">
    <div class="search-panel-head">
      <p class="search-panel-title">Search TABI</p>
      <button class="icon-button" type="button" aria-label="Close search" data-search-close>&#10005;</button>
    </div>
    <input class="search-input" type="search" placeholder="Search Kyoto, food, craft, hidden gems..." data-search-input>
    <div class="search-results" data-search-results></div>
  </div>
</div>
<main id="main">
$Main
</main>
<footer class="site-footer">
  <div class="footer-top">
    <div>
      <div class="footer-logo">TABI<span class="dot">.</span></div>
      <p class="footer-tagline">Your guide to the real Japan: travel, culture, food, hidden places, and the things worth bringing home.</p>
    </div>
    <div>
      <p class="footer-col-title">Explore</p>
      <ul class="footer-links">
        <li><a href="/categories/travel-guide.html">Travel Guide</a></li>
        <li><a href="/categories/culture.html">Culture &amp; Tradition</a></li>
        <li><a href="/categories/food.html">Food &amp; Drink</a></li>
        <li><a href="/categories/hidden-gems.html">Hidden Gems</a></li>
        <li><a href="/categories/things-to-buy.html">Things to Buy</a></li>
      </ul>
    </div>
    <div>
      <p class="footer-col-title">TABI</p>
      <ul class="footer-links">
        <li><a href="/#newsletter">Newsletter</a></li>
        <li><a href="/articles/hidden-shrines-kyoto-locals-keep-secret.html">Start Here</a></li>
        <li><a href="/categories/hidden-gems.html">Hidden Gems</a></li>
      </ul>
    </div>
    <div>
      <p class="footer-col-title">Disclosure</p>
      <ul class="footer-links">
        <li><a href="/categories/things-to-buy.html">Shopping Guides</a></li>
        <li><a href="/sitemap.xml">Sitemap</a></li>
        <li><a href="mailto:$($Config.contactEmail)">Contact</a></li>
      </ul>
    </div>
  </div>
  <div class="footer-bottom">
    <div class="footer-bottom-inner">
      <span>&copy; 2026 TABI. All rights reserved.</span>
      <span>Affiliate links may earn us a commission.</span>
    </div>
  </div>
</footer>
<script>window.TABI_ARTICLES = $Script:SearchJson;</script>
<script src="/script.js"></script>
$StructuredData
</body>
</html>
"@
}

function New-ArticleCard($Article, [bool]$Featured) {
  $Class = if ($Featured) { "article-card featured" } else { "article-card" }
  $Read = if ($Article.readingTime -eq 1) { "1 min read" } else { "$($Article.readingTime) min read" }
  return @"
<a class="$Class" href="$(Get-ArticleUrl $Article)" data-search-card>
  <img src="$(Html $Article.image)" alt="$(Html $Article.imageAlt)" loading="lazy">
  <div class="card-content">
    <p class="card-cat">$(Html (Get-CategoryLabel $Article.category))</p>
    <h3 class="card-title">$(Html $Article.title)</h3>
    <p class="card-meta">$(Format-Date $Article.publishedAt) / $Read</p>
  </div>
</a>
"@
}

function New-CultureCard($Article) {
  return @"
<a class="culture-card" href="$(Get-ArticleUrl $Article)" data-search-card>
  <img src="$(Html $Article.image)" alt="$(Html $Article.imageAlt)" loading="lazy">
  <p class="card-cat">$(Html (Get-CategoryLabel $Article.category))</p>
  <h3>$(Html $Article.title)</h3>
  <p>$(Html $Article.summary)</p>
</a>
"@
}

function New-BuyCard($Article) {
  $Price = if ($Article.PSObject.Properties.Name -contains "price") { $Article.price } else { "Guide" }
  return @"
<a class="buy-card" href="$(Get-ArticleUrl $Article)" data-search-card>
  <span class="buy-icon" aria-hidden="true">$(Get-BuyIcon $Article)</span>
  <p class="buy-tag">$(Html (($Article.tags | Select-Object -First 1)))</p>
  <h3 class="buy-title">$(Html $Article.title)</h3>
  <p class="buy-price">$(Html $Price)</p>
</a>
"@
}

function New-ListingCard($Article) {
  return @"
<a class="listing-card" href="$(Get-ArticleUrl $Article)" data-search-card>
  <img src="$(Html $Article.image)" alt="$(Html $Article.imageAlt)" loading="lazy">
  <p class="card-cat">$(Html (Get-CategoryLabel $Article.category))</p>
  <h2>$(Html $Article.title)</h2>
  <p>$(Html $Article.summary)</p>
  <div class="tag-list">
    $(New-TagList $Article.tags)
  </div>
</a>
"@
}

function New-TagList($Tags) {
  $Items = foreach ($Tag in $Tags) {
    '<span class="tag-pill">#{0}</span>' -f (Html $Tag)
  }
  return ($Items -join "`n")
}

function New-Newsletter {
  return @"
<section class="newsletter-wrap" id="newsletter" aria-labelledby="newsletter-title">
  <div class="newsletter">
    <div class="newsletter-visual">
      <img src="/assets/images/kyoto-shrine-hero.png" alt="A quiet Kyoto shrine path with lanterns at blue hour" loading="lazy">
    </div>
    <div class="newsletter-content">
      <p class="page-kicker">Free Newsletter</p>
      <h2 id="newsletter-title">Japan, delivered to your inbox.</h2>
      <p>Every Friday: one destination, one cultural insight, and one thing worth bringing home. No noise. Just the Japan worth knowing.</p>
      <form class="nl-form" data-newsletter-form>
        <input class="nl-input" type="email" name="email" placeholder="your@email.com" aria-label="Email address" required>
        <button class="nl-btn" type="submit">Subscribe</button>
      </form>
      <p class="nl-status" data-newsletter-status></p>
    </div>
  </div>
</section>
"@
}

function New-HomePage {
  $Sorted = @($Articles | Sort-Object publishedAt -Descending)
  $Hero = $Sorted | Where-Object { $_.id -eq "hidden-shrines-kyoto-locals-keep-secret" } | Select-Object -First 1
  if ($null -eq $Hero) { $Hero = $Sorted[0] }
  $EditorialIds = @(
    "hidden-shrines-kyoto-locals-keep-secret",
    "perfect-route-up-mount-fuji",
    "osaka-three-day-eating-itinerary",
    "yakushima-ancient-forest-few-tourists-find",
    "kintsugi-art-of-repairing-broken-things"
  )
  $Editorial = foreach ($Id in $EditorialIds) {
    $Sorted | Where-Object { $_.id -eq $Id } | Select-Object -First 1
  }
  $Editorial = @($Editorial | Where-Object { $null -ne $_ })
  $Culture = @($Sorted | Where-Object { $_.category -eq "culture" } | Select-Object -First 3)
  $Buy = @($Sorted | Where-Object { $_.category -eq "things-to-buy" } | Select-Object -First 4)
  $HeroRead = if ($Hero.readingTime -eq 1) { "1 min read" } else { "$($Hero.readingTime) min read" }

  $EditorialCards = for ($i = 0; $i -lt $Editorial.Count; $i++) {
    New-ArticleCard $Editorial[$i] ($i -eq 0)
  }
  $CultureCards = foreach ($Article in $Culture) { New-CultureCard $Article }
  $BuyCards = foreach ($Article in $Buy) { New-BuyCard $Article }
  $Newsletter = New-Newsletter

  $Main = @"
<section class="hero">
  <div class="hero-media">
    <img src="$(Html $Hero.image)" alt="$(Html $Hero.imageAlt)">
  </div>
  <div class="hero-kanji">&#26053;</div>
  <div class="hero-content">
    <div class="eyebrow"><span class="eyebrow-mark">$(Html (Get-CategoryLabel $Hero.category))</span><span>$(Format-Date $Hero.publishedAt) / $HeroRead</span></div>
    <h1 class="hero-title">$(Html $Hero.title)</h1>
    <p class="hero-desc">$(Html $Hero.summary)</p>
    <div class="hero-actions">
      <a class="hero-btn" href="$(Get-ArticleUrl $Hero)">Read the Guide</a>
      <a class="hero-link" href="/categories/travel-guide.html">Browse all guides</a>
    </div>
  </div>
</section>
<section aria-labelledby="travel-heading">
  <div class="section-label">
    <span class="section-label-jp">&#26053;</span>
    <h2 class="section-label-en" id="travel-heading">Editor's Picks</h2>
    <div class="section-label-line"></div>
    <a class="section-label-link" href="/categories/travel-guide.html">All articles</a>
  </div>
  <div class="editorial-grid">
    $($EditorialCards -join "`n")
  </div>
</section>
<section aria-labelledby="culture-heading">
  <div class="section-label">
    <span class="section-label-jp">&#25991;&#21270;</span>
    <h2 class="section-label-en" id="culture-heading">Culture &amp; Tradition</h2>
    <div class="section-label-line"></div>
    <a class="section-label-link" href="/categories/culture.html">All culture</a>
  </div>
  <div class="culture-grid">
    $($CultureCards -join "`n")
  </div>
</section>
<section class="interlude" aria-label="The TABI philosophy">
  <div class="interlude-kanji">&#26053;&#25991;&#21270;</div>
  <div class="interlude-inner">
    <p class="interlude-label">The TABI Philosophy</p>
    <p class="interlude-quote">Japan is not a destination.<br><strong>It is a way of seeing.</strong></p>
    <p class="interlude-sub">From ancient forest temples to 4am ramen counters, we find the Japan worth knowing.</p>
  </div>
</section>
<section aria-labelledby="buy-heading">
  <div class="section-label">
    <span class="section-label-jp">&#36023;&#29289;</span>
    <h2 class="section-label-en" id="buy-heading">Things to Buy</h2>
    <div class="section-label-line"></div>
    <a class="section-label-link" href="/categories/things-to-buy.html">All guides</a>
  </div>
  <div class="buy-grid">
    $($BuyCards -join "`n")
  </div>
</section>
$Newsletter
"@

  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "WebSite"
    name = $Config.siteName
    url = $Config.siteUrl
    description = $Config.description
    inLanguage = $Config.language
  } | ConvertTo-Json -Depth 5 -Compress

  return New-Layout "$($Config.siteName) - $($Config.tagline)" $Config.description "/" $Main "" $Hero.image $JsonLd
}

function New-ArticlePage($Article) {
  $Read = if ($Article.readingTime -eq 1) { "1 min read" } else { "$($Article.readingTime) min read" }
  $SectionHtml = foreach ($Section in $Article.sections) {
    @"
<section>
  <h2>$(Html $Section.heading)</h2>
  <p>$(Html $Section.body)</p>
</section>
"@
  }
  $Related = @($Articles | Where-Object { $_.category -eq $Article.category -and $_.id -ne $Article.id } | Sort-Object publishedAt -Descending | Select-Object -First 3)
  $RelatedHtml = foreach ($Item in $Related) {
    '<li><a href="{0}">{1}</a></li>' -f (Get-ArticleUrl $Item), (Html $Item.title)
  }

  $Main = @"
<section class="page-hero">
  <p class="page-kicker">$(Html (Get-CategoryLabel $Article.category))</p>
  <h1 class="page-title">$(Html $Article.title)</h1>
  <p class="page-desc">$(Html $Article.summary)</p>
  <p class="article-meta">$(Format-Date $Article.publishedAt) / $Read</p>
</section>
<article class="article-layout">
  <div class="article-cover">
    <img src="$(Html $Article.image)" alt="$(Html $Article.imageAlt)">
  </div>
  <div class="article-body">
    $($SectionHtml -join "`n")
  </div>
  <aside class="article-sidebar" aria-label="Article details">
    <p class="footer-col-title">Filed Under</p>
    <a class="tag-pill" href="$(Get-CategoryUrl $Article.category)">$(Html (Get-CategoryLabel $Article.category))</a>
    <div class="tag-list">
      $(foreach ($Tag in $Article.tags) { '<a class="tag-pill" href="{0}">#{1}</a>' -f (Get-TagUrl $Tag), (Html $Tag) })
    </div>
    <p class="footer-col-title sidebar-section-title">Related</p>
    <ul class="footer-links">
      $($RelatedHtml -join "`n")
    </ul>
  </aside>
</article>
$(New-Newsletter)
"@

  $ImageUrl = SiteUrl $Article.image
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "Article"
    headline = $Article.title
    description = $Article.summary
    image = $ImageUrl
    datePublished = $Article.publishedAt
    dateModified = $Article.publishedAt
    inLanguage = $Config.language
    author = @{ "@type" = "Organization"; name = $Config.siteName }
    publisher = @{ "@type" = "Organization"; name = $Config.siteName }
    mainEntityOfPage = SiteUrl (Get-ArticleUrl $Article)
  } | ConvertTo-Json -Depth 8 -Compress

  return New-Layout "$($Article.title) - TABI" $Article.summary (Get-ArticleUrl $Article) $Main $Article.category $Article.image $JsonLd
}

function New-CategoryPage($Category) {
  $Items = @($Articles | Where-Object { $_.category -eq $Category.slug } | Sort-Object publishedAt -Descending)
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $Main = @"
<section class="page-hero">
  <p class="page-kicker">Category</p>
  <h1 class="page-title">$(Html $Category.label)</h1>
  <p class="page-desc">Curated TABI guides for $(Html $Category.label.ToLowerInvariant()) in Japan.</p>
</section>
<section class="listing-grid" aria-label="$(Html $Category.label) articles">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = $Category.label
    description = "Curated TABI guides for $($Category.label) in Japan."
    url = SiteUrl (Get-CategoryUrl $Category.slug)
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$($Category.label) - TABI" "Curated TABI guides for $($Category.label) in Japan." (Get-CategoryUrl $Category.slug) $Main $Category.slug "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-TagPage([string]$Tag) {
  $Items = @($Articles | Where-Object { @($_.tags) -contains $Tag } | Sort-Object publishedAt -Descending)
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $Title = "#$Tag"
  $Main = @"
<section class="page-hero">
  <p class="page-kicker">Tag</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">Articles connected to $(Html $Tag), gathered from across TABI.</p>
</section>
<section class="listing-grid" aria-label="$(Html $Tag) articles">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = $Title
    description = "Articles connected to $Tag, gathered from across TABI."
    url = SiteUrl (Get-TagUrl $Tag)
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$Title - TABI" "Articles connected to $Tag, gathered from across TABI." (Get-TagUrl $Tag) $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-Sitemap {
  $Urls = @("/")
  $Urls += foreach ($Category in $Config.categories) { Get-CategoryUrl $Category.slug }
  $Tags = @($Articles | ForEach-Object { $_.tags } | Sort-Object -Unique)
  $Urls += foreach ($Tag in $Tags) { Get-TagUrl $Tag }
  $Urls += foreach ($Article in $Articles) { Get-ArticleUrl $Article }
  $Items = foreach ($Url in $Urls) {
    "  <url><loc>$(Html (SiteUrl $Url))</loc></url>"
  }
  return @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
$($Items -join "`n")
</urlset>
"@
}

Write-Page "index.html" (New-HomePage)

foreach ($Article in $Articles) {
  Write-Page "articles/$($Article.id).html" (New-ArticlePage $Article)
}

foreach ($Category in $Config.categories) {
  Write-Page "categories/$($Category.slug).html" (New-CategoryPage $Category)
}

$AllTags = @($Articles | ForEach-Object { $_.tags } | Sort-Object -Unique)
foreach ($Tag in $AllTags) {
  Write-Page "tags/$Tag.html" (New-TagPage $Tag)
}

Write-Page "sitemap.xml" (New-Sitemap)
Write-Page "robots.txt" "User-agent: *`nAllow: /`nSitemap: $(SiteUrl '/sitemap.xml')`n"

Write-Host "Generated $($Articles.Count) articles, $($Config.categories.Count) categories, and $($AllTags.Count) tag pages."
