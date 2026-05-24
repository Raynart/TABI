$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Config = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "site.config.json") | ConvertFrom-Json
$Articles = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "articles.json") | ConvertFrom-Json
$EnglishCulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Today = Get-Date
$TopicClusters = @(
  [pscustomobject]@{
    slug = "kyoto-travel"
    title = "Kyoto Travel"
    description = "Quiet shrines, ryokan, craft, and routes for seeing Kyoto with more care."
    tags = @("kyoto", "shrines", "ryokan", "craft", "wabi-sabi", "kintsugi")
    categories = @("travel-guide", "culture")
  },
  [pscustomobject]@{
    slug = "first-time-japan"
    title = "First-Time Japan"
    description = "Practical routes, food confidence, and gentle planning for a first trip to Japan."
    tags = @("first-time", "itinerary", "tokyo", "kyoto", "osaka", "language", "travel-tips")
    categories = @("travel-guide", "food")
  },
  [pscustomobject]@{
    slug = "japanese-food"
    title = "Japanese Food"
    description = "Menus, alleys, counters, convenience-store saves, and the meals that shape a trip."
    tags = @("food", "osaka", "tokyo", "izakaya", "menus", "konbini", "street-food")
    categories = @("food")
  },
  [pscustomobject]@{
    slug = "shopping-in-japan"
    title = "Shopping in Japan"
    description = "Useful, packable, and culturally thoughtful things worth bringing home."
    tags = @("shopping", "souvenirs", "kitchen-knives", "matcha", "drugstore", "yukata", "skincare")
    categories = @("things-to-buy")
  },
  [pscustomobject]@{
    slug = "slow-travel"
    title = "Slow Travel"
    description = "Forests, islands, walking routes, and quieter places where Japan has room to breathe."
    tags = @("slow-travel", "hidden-gems", "yakushima", "setouchi", "walking", "forest", "islands")
    categories = @("hidden-gems")
  }
)

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

function Get-ArticleTags($Article) {
  return @($Article.tags)
}

function Get-DaysOld($Article) {
  $Published = [datetime]::ParseExact($Article.publishedAt, "yyyy-MM-dd", $EnglishCulture)
  return [Math]::Max(0, [int]($Today.Date - $Published.Date).TotalDays)
}

function Get-FreshnessScore($Article) {
  $DaysOld = Get-DaysOld $Article
  $VolatileCategories = @("travel-guide", "things-to-buy")
  $Base = if ($DaysOld -le 14) { 25 } elseif ($DaysOld -le 45) { 21 } elseif ($DaysOld -le 90) { 16 } elseif ($DaysOld -le 180) { 10 } else { 5 }
  if ($VolatileCategories -contains $Article.category -and $DaysOld -gt 90) { $Base -= 4 }
  return [Math]::Max(0, $Base)
}

function Get-FreshnessLabel($Article) {
  $DaysOld = Get-DaysOld $Article
  if ($DaysOld -le 30) { return "Fresh" }
  if ($DaysOld -le 120) { return "Review soon" }
  return "Needs update"
}

function Get-SeasonalityScore($Article) {
  $Month = [int]$Today.Month
  $Tags = Get-ArticleTags $Article
  $Score = 0

  if (($Tags -contains "hanami" -or $Tags -contains "cherry-blossoms" -or $Tags -contains "spring") -and ($Month -in @(2, 3, 4))) { $Score += 16 }
  if (($Tags -contains "mount-fuji" -or $Tags -contains "hiking" -or $Tags -contains "summer") -and ($Month -in @(5, 6, 7, 8))) { $Score += 16 }
  if (($Tags -contains "yakushima" -or $Tags -contains "forest" -or $Tags -contains "islands") -and ($Month -in @(4, 5, 6, 9, 10))) { $Score += 10 }
  if (($Tags -contains "shopping" -or $Tags -contains "souvenirs" -or $Article.category -eq "things-to-buy") -and ($Month -in @(11, 12, 1))) { $Score += 8 }
  if ($Article.category -eq "food") { $Score += 4 }
  if ($Article.category -eq "hidden-gems") { $Score += 3 }

  return [Math]::Min(18, $Score)
}

function Get-QualityScore($Article) {
  $Score = 0
  $SectionCount = @($Article.sections).Count
  $TagCount = @(Get-ArticleTags $Article).Count
  $SummaryLength = ([string]$Article.summary).Length

  if ($SummaryLength -ge 120 -and $SummaryLength -le 340) { $Score += 18 } elseif ($SummaryLength -gt 0) { $Score += 10 }
  if ($SectionCount -ge 3) { $Score += 22 } elseif ($SectionCount -gt 0) { $Score += 12 }
  if ($TagCount -ge 3 -and $TagCount -le 5) { $Score += 18 } elseif ($TagCount -gt 0) { $Score += 10 }
  if (-not [string]::IsNullOrWhiteSpace($Article.image)) { $Score += 14 }
  if (-not [string]::IsNullOrWhiteSpace($Article.imageAlt)) { $Score += 10 }
  if ($Article.readingTime -ge 5) { $Score += 10 } elseif ($Article.readingTime -gt 0) { $Score += 5 }
  if ($Article.affiliate -eq $true -and $Article.category -eq "things-to-buy") { $Score += 8 }

  return [Math]::Min(100, $Score)
}

function Get-CategoryPriority([string]$Category, [string]$ContextCategory) {
  if ($Category -eq $ContextCategory) { return 16 }
  switch ($Category) {
    "travel-guide" { return 10 }
    "hidden-gems" { return 9 }
    "food" { return 8 }
    "culture" { return 7 }
    "things-to-buy" { return 6 }
    default { return 5 }
  }
}

function Get-ArticleScore($Article, [string]$ContextCategory) {
  $Score = 0
  $Score += Get-FreshnessScore $Article
  $Score += Get-SeasonalityScore $Article
  $Score += [Math]::Round((Get-QualityScore $Article) / 4)
  $Score += Get-CategoryPriority $Article.category $ContextCategory
  if ($Article.featured -eq $true) { $Score += 12 }
  if ($ContextCategory -eq "things-to-buy" -and $Article.affiliate -eq $true) { $Score += 8 }
  return [int]$Score
}

function Select-ScoredArticles([object[]]$Candidates, [int]$Limit, [string]$ContextCategory) {
  return @($Candidates |
    Sort-Object @{ Expression = { Get-ArticleScore $_ $ContextCategory }; Descending = $true }, @{ Expression = { $_.publishedAt }; Descending = $true } |
    Select-Object -First $Limit)
}

function Select-DiverseArticles([object[]]$Candidates, [int]$Limit, [string]$ContextCategory) {
  $Selected = @()
  $SeenCategories = @{}
  $Sorted = Select-ScoredArticles $Candidates ($Candidates.Count) $ContextCategory

  foreach ($Candidate in $Sorted) {
    if ($Selected.Count -ge $Limit) { break }
    if (-not $SeenCategories.ContainsKey($Candidate.category) -or $SeenCategories[$Candidate.category] -lt 2) {
      $Selected += $Candidate
      if (-not $SeenCategories.ContainsKey($Candidate.category)) { $SeenCategories[$Candidate.category] = 0 }
      $SeenCategories[$Candidate.category] += 1
    }
  }

  foreach ($Candidate in $Sorted) {
    if ($Selected.Count -ge $Limit) { break }
    if (@($Selected | Where-Object { $_.id -eq $Candidate.id }).Count -eq 0) {
      $Selected += $Candidate
    }
  }

  return @($Selected)
}

function Get-RelatedScore($BaseArticle, $Candidate) {
  $BaseTags = Get-ArticleTags $BaseArticle
  $CandidateTags = Get-ArticleTags $Candidate
  $SharedTags = @($CandidateTags | Where-Object { $BaseTags -contains $_ }).Count
  $Score = 0
  $Score += $SharedTags * 18
  if ($Candidate.category -eq $BaseArticle.category) { $Score += 16 }
  if ($Candidate.affiliate -eq $true -and $BaseArticle.category -eq "things-to-buy") { $Score += 8 }
  $Score += Get-SeasonalityScore $Candidate
  $Score += [Math]::Round((Get-QualityScore $Candidate) / 10)
  $Score += [Math]::Round((Get-FreshnessScore $Candidate) / 2)
  return [int]$Score
}

function Select-RelatedArticles($BaseArticle, [int]$Limit) {
  return @($Articles |
    Where-Object { $_.id -ne $BaseArticle.id } |
    Sort-Object @{ Expression = { Get-RelatedScore $BaseArticle $_ }; Descending = $true }, @{ Expression = { $_.publishedAt }; Descending = $true } |
    Select-Object -First $Limit)
}

function Get-TopicUrl([string]$Slug) {
  return "/topics/$Slug.html"
}

function Get-ArticleTopic($Article) {
  $BestTopic = $null
  $BestScore = -1
  $Tags = Get-ArticleTags $Article
  foreach ($Topic in $TopicClusters) {
    $Score = 0
    foreach ($Tag in $Tags) {
      if (@($Topic.tags) -contains $Tag) { $Score += 3 }
    }
    if (@($Topic.categories) -contains $Article.category) { $Score += 2 }
    if ($Score -gt $BestScore) {
      $BestScore = $Score
      $BestTopic = $Topic
    }
  }
  return $BestTopic
}

function Select-TopicArticles($Topic, [int]$Limit) {
  $Items = @($Articles | Where-Object {
    $Article = $_
    $Tags = Get-ArticleTags $Article
    (@($Topic.categories) -contains $Article.category) -or (@($Tags | Where-Object { @($Topic.tags) -contains $_ }).Count -gt 0)
  })
  return Select-ScoredArticles $Items $Limit ""
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
    $Topic = Get-ArticleTopic $Article
    [pscustomobject]@{
      title = $Article.title
      summary = $Article.summary
      category = $Article.category
      categoryLabel = Get-CategoryLabel $Article.category
      tags = @($Article.tags)
      url = Get-ArticleUrl $Article
      score = Get-ArticleScore $Article ""
      qualityScore = Get-QualityScore $Article
      freshness = Get-FreshnessLabel $Article
      topic = if ($null -ne $Topic) { $Topic.title } else { "" }
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
        <li><a href="/topics/first-time-japan.html">First-Time Japan</a></li>
        <li><a href="/topics/slow-travel.html">Slow Travel</a></li>
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
  $Score = Get-ArticleScore $Article $Article.category
  $Freshness = Get-FreshnessLabel $Article
  return @"
<a class="listing-card" href="$(Get-ArticleUrl $Article)" data-search-card>
  <img src="$(Html $Article.image)" alt="$(Html $Article.imageAlt)" loading="lazy">
  <p class="card-cat">$(Html (Get-CategoryLabel $Article.category))</p>
  <h2>$(Html $Article.title)</h2>
  <p>$(Html $Article.summary)</p>
  <p class="listing-meta">Score $Score / $(Html $Freshness)</p>
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

function New-LinkedTagList($Tags) {
  $Items = foreach ($Tag in $Tags) {
    '<a class="tag-pill" href="{0}">#{1}</a>' -f (Get-TagUrl $Tag), (Html $Tag)
  }
  return ($Items -join "`n")
}

function New-Breadcrumbs($Items) {
  $Parts = foreach ($Item in $Items) {
    if ([string]::IsNullOrWhiteSpace($Item.url)) {
      '<span aria-current="page">{0}</span>' -f (Html $Item.label)
    } else {
      '<a href="{0}">{1}</a>' -f $Item.url, (Html $Item.label)
    }
  }
  return @"
<nav class="breadcrumbs" aria-label="Breadcrumb">
  $($Parts -join '<span aria-hidden="true">/</span>')
</nav>
"@
}

function New-ArticleSignals($Article) {
  $Quality = Get-QualityScore $Article
  $Freshness = Get-FreshnessLabel $Article
  $Score = Get-ArticleScore $Article ""
  $Seasonality = Get-SeasonalityScore $Article
  return @"
<div class="signal-grid" aria-label="Editorial signals">
  <div><span>Article score</span><strong>$Score</strong></div>
  <div><span>Quality</span><strong>$Quality</strong></div>
  <div><span>Freshness</span><strong>$(Html $Freshness)</strong></div>
  <div><span>Seasonal fit</span><strong>$Seasonality</strong></div>
</div>
"@
}

function New-CompactArticleCard($Article) {
  return @"
<a class="compact-card" href="$(Get-ArticleUrl $Article)">
  <img src="$(Html $Article.image)" alt="$(Html $Article.imageAlt)" loading="lazy">
  <span>$(Html (Get-CategoryLabel $Article.category))</span>
  <strong>$(Html $Article.title)</strong>
</a>
"@
}

function New-AlgorithmNote([string]$Text) {
  return @"
<p class="algorithm-note">$(Html $Text)</p>
"@
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
  $Hero = (Select-ScoredArticles $Sorted 1 "")[0]
  $Editorial = Select-DiverseArticles $Sorted 5 ""
  $Culture = Select-ScoredArticles @($Sorted | Where-Object { $_.category -eq "culture" }) 3 "culture"
  $Buy = Select-ScoredArticles @($Sorted | Where-Object { $_.category -eq "things-to-buy" }) 4 "things-to-buy"
  $TopicCards = foreach ($Topic in $TopicClusters) {
    $Count = @(Select-TopicArticles $Topic 50).Count
    @"
<a class="topic-card" href="$(Get-TopicUrl $Topic.slug)">
  <span>Topic Cluster</span>
  <strong>$(Html $Topic.title)</strong>
  <p>$(Html $Topic.description)</p>
  <small>$Count guides</small>
</a>
"@
  }
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
  $(New-AlgorithmNote "Ranked by TABI's local article score: freshness, seasonality, quality, editorial weight, and category diversity.")
  <div class="editorial-grid">
    $($EditorialCards -join "`n")
  </div>
</section>
<section aria-labelledby="topics-heading">
  <div class="section-label">
    <span class="section-label-jp">&#36947;</span>
    <h2 class="section-label-en" id="topics-heading">Topic Paths</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="topic-grid">
    $($TopicCards -join "`n")
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
  $Topic = Get-ArticleTopic $Article
  $TopicHtml = ""
  if ($null -ne $Topic) {
    $TopicHtml = '<a class="tag-pill topic-pill" href="{0}">{1}</a>' -f (Get-TopicUrl $Topic.slug), (Html $Topic.title)
  }
  $Related = Select-RelatedArticles $Article 4
  $RelatedHtml = foreach ($Item in $Related) {
    '<li><a href="{0}">{1}</a></li>' -f (Get-ArticleUrl $Item), (Html $Item.title)
  }
  $RelatedCards = foreach ($Item in ($Related | Select-Object -First 3)) {
    New-CompactArticleCard $Item
  }
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = Get-CategoryLabel $Article.category; url = Get-CategoryUrl $Article.category },
    [pscustomobject]@{ label = $Article.title; url = "" }
  )

  $Main = @"
<section class="page-hero">
  $Breadcrumbs
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
    $(New-ArticleSignals $Article)
    <p class="footer-col-title">Filed Under</p>
    <a class="tag-pill" href="$(Get-CategoryUrl $Article.category)">$(Html (Get-CategoryLabel $Article.category))</a>
    $TopicHtml
    <div class="tag-list">
      $(New-LinkedTagList $Article.tags)
    </div>
    <p class="footer-col-title sidebar-section-title">Related</p>
    <p class="sidebar-note">Chosen by shared tags, category fit, freshness, seasonality, and quality score.</p>
    <ul class="footer-links">
      $($RelatedHtml -join "`n")
    </ul>
  </aside>
</article>
<section aria-labelledby="next-heading" class="next-read">
  <div class="section-label">
    <span class="section-label-jp">&#27425;</span>
    <h2 class="section-label-en" id="next-heading">Read Next</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="compact-grid">
    $($RelatedCards -join "`n")
  </div>
</section>
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
  $Items = Select-ScoredArticles @($Articles | Where-Object { $_.category -eq $Category.slug }) 100 $Category.slug
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = $Category.label; url = "" }
  )
  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">Category</p>
  <h1 class="page-title">$(Html $Category.label)</h1>
  <p class="page-desc">Curated TABI guides for $(Html $Category.label.ToLowerInvariant()) in Japan.</p>
</section>
$(New-AlgorithmNote "Sorted by category relevance, freshness, seasonality, editorial weight, and article quality.")
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
  $Items = Select-ScoredArticles @($Articles | Where-Object { @($_.tags) -contains $Tag }) 100 ""
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $Title = "#$Tag"
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = $Title; url = "" }
  )
  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">Tag</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">Articles connected to $(Html $Tag), gathered from across TABI.</p>
</section>
$(New-AlgorithmNote "Sorted by article score so stronger, fresher, and more seasonally useful guides appear first.")
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

function New-TopicPage($Topic) {
  $Items = Select-TopicArticles $Topic 100
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = "Topics"; url = "" },
    [pscustomobject]@{ label = $Topic.title; url = "" }
  )
  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">Topic Path</p>
  <h1 class="page-title">$(Html $Topic.title)</h1>
  <p class="page-desc">$(Html $Topic.description)</p>
</section>
$(New-AlgorithmNote "This topic path is generated from tag overlap, category fit, and article score. It acts as a static internal-link hub.")
<section class="listing-grid" aria-label="$(Html $Topic.title) articles">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = $Topic.title
    description = $Topic.description
    url = SiteUrl (Get-TopicUrl $Topic.slug)
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$($Topic.title) - TABI" $Topic.description (Get-TopicUrl $Topic.slug) $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-NotFoundPage {
  $Picks = Select-DiverseArticles $Articles 6 ""
  $PickCards = foreach ($Article in $Picks) { New-CompactArticleCard $Article }
  $TopicCards = foreach ($Topic in $TopicClusters) {
    '<a class="tag-pill topic-pill" href="{0}">{1}</a>' -f (Get-TopicUrl $Topic.slug), (Html $Topic.title)
  }
  $Main = @"
<section class="page-hero not-found-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = "404"; url = "" }))
  <p class="page-kicker">404</p>
  <h1 class="page-title">This path has wandered off the map.</h1>
  <p class="page-desc">Try a topic path, search TABI, or start with one of the strongest guides selected by the local article score.</p>
  <div class="hero-actions light-actions">
    <a class="button" href="/">Back to Home</a>
    <button class="button secondary" type="button" data-search-toggle>Search TABI</button>
  </div>
  <div class="tag-list">
    $($TopicCards -join "`n")
  </div>
</section>
<section class="next-read" aria-labelledby="not-found-picks">
  <div class="section-label">
    <span class="section-label-jp">&#22320;</span>
    <h2 class="section-label-en" id="not-found-picks">Recommended Guides</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="compact-grid">
    $($PickCards -join "`n")
  </div>
</section>
"@
  return New-Layout "Page Not Found - TABI" "Find your way back into TABI with recommended Japan travel, culture, food, and shopping guides." "/404.html" $Main "" "/assets/images/kyoto-shrine-hero.png" ""
}

function New-Sitemap {
  $Urls = @("/")
  $Urls += foreach ($Category in $Config.categories) { Get-CategoryUrl $Category.slug }
  $Urls += foreach ($Topic in $TopicClusters) { Get-TopicUrl $Topic.slug }
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

foreach ($Topic in $TopicClusters) {
  Write-Page "topics/$($Topic.slug).html" (New-TopicPage $Topic)
}

$AllTags = @($Articles | ForEach-Object { $_.tags } | Sort-Object -Unique)
foreach ($Tag in $AllTags) {
  Write-Page "tags/$Tag.html" (New-TagPage $Tag)
}

Write-Page "404.html" (New-NotFoundPage)
Write-Page "sitemap.xml" (New-Sitemap)
Write-Page "robots.txt" "User-agent: *`nAllow: /`nSitemap: $(SiteUrl '/sitemap.xml')`n"

Write-Host "Generated $($Articles.Count) articles, $($Config.categories.Count) categories, $($TopicClusters.Count) topics, and $($AllTags.Count) tag pages."
