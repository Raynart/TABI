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

$AreaClusters = @(
  [pscustomobject]@{
    slug = "tokyo"
    title = "Tokyo"
    description = "Neighborhood food, shopping, nightlife, and low-friction first-trip decisions."
    image = "/assets/images/osaka-food-alley.png"
    tags = @("tokyo", "izakaya", "nightlife", "yukata", "shopping")
    categories = @("food", "things-to-buy", "travel-guide")
    neighborhoods = @(
      [pscustomobject]@{ name = "Yanaka"; note = "Slow streets, small shops, and first-day wandering." },
      [pscustomobject]@{ name = "Shibuya"; note = "Big-city energy that works best when paired with a quieter pocket." },
      [pscustomobject]@{ name = "Asakusa"; note = "Useful for craft, tradition, and easy transit links." }
    )
  },
  [pscustomobject]@{
    slug = "kyoto"
    title = "Kyoto"
    description = "Shrines, ryokan, craft, tea, and routes that reward early starts."
    image = "/assets/images/kyoto-shrine-hero.png"
    tags = @("kyoto", "shrines", "ryokan", "craft", "matcha", "kintsugi", "wabi-sabi")
    categories = @("travel-guide", "culture", "things-to-buy")
    neighborhoods = @(
      [pscustomobject]@{ name = "Northern Kyoto"; note = "Quieter temples, hills, and slower transit days." },
      [pscustomobject]@{ name = "Demachiyanagi"; note = "A good edge for cafes, riverside time, and local rhythm." },
      [pscustomobject]@{ name = "Higashiyama"; note = "Best early or late, with careful pacing." }
    )
  },
  [pscustomobject]@{
    slug = "osaka"
    title = "Osaka"
    description = "Food-first planning, markets, alleys, and neighborhoods beyond the obvious photo stop."
    image = "/assets/images/osaka-food-alley.png"
    tags = @("osaka", "street-food", "nightlife", "food", "itinerary")
    categories = @("food", "travel-guide")
    neighborhoods = @(
      [pscustomobject]@{ name = "Namba"; note = "A practical base for first nights and late food." },
      [pscustomobject]@{ name = "Nakazakicho"; note = "Cafes, small shops, and a slower counterpoint to Dotonbori." },
      [pscustomobject]@{ name = "Tenma"; note = "Compact food energy that rewards small rounds." }
    )
  },
  [pscustomobject]@{
    slug = "yakushima"
    title = "Yakushima"
    description = "Ancient forest, rain, coastal villages, and slower island planning."
    image = "/assets/images/yakushima-forest.png"
    tags = @("yakushima", "forest", "hiking", "islands", "slow-travel")
    categories = @("hidden-gems")
    neighborhoods = @(
      [pscustomobject]@{ name = "Forest trails"; note = "Choose one major route and leave room for weather." },
      [pscustomobject]@{ name = "Coastal villages"; note = "Useful for scale, meals, and recovery time." },
      [pscustomobject]@{ name = "Short walks"; note = "Good backup plans when rain changes the day." }
    )
  },
  [pscustomobject]@{
    slug = "setouchi"
    title = "Setouchi"
    description = "Island art, ferries, sea air, and slow travel between small ports."
    image = "/assets/images/yakushima-forest.png"
    tags = @("setouchi", "islands", "art", "slow-travel")
    categories = @("hidden-gems", "culture")
    neighborhoods = @(
      [pscustomobject]@{ name = "Museum islands"; note = "Plan around ferry rhythm, not a crowded checklist." },
      [pscustomobject]@{ name = "Harbor towns"; note = "Good for ordinary time between art stops." },
      [pscustomobject]@{ name = "Sunset routes"; note = "Worth protecting when the timetable allows." }
    )
  }
)

$ItineraryPlans = @(
  [pscustomobject]@{
    slug = "three-days"
    title = "3 Days in Japan"
    duration = "3 days"
    pace = "Focused"
    description = "A tight route for travelers adding Japan to a larger trip or using Tokyo as a short gateway."
    tags = @("tokyo", "food", "first-time", "shopping")
    categories = @("travel-guide", "food", "things-to-buy")
    steps = @(
      [pscustomobject]@{ label = "Day 1"; title = "Arrive gently"; body = "Stay in one Tokyo neighborhood, solve cash, transit, and first meal decisions, then stop early." },
      [pscustomobject]@{ label = "Day 2"; title = "Food and texture"; body = "Pair a market or old street with one planned dinner and a low-pressure shopping stop." },
      [pscustomobject]@{ label = "Day 3"; title = "One final loop"; body = "Use the last morning for a compact route near your departure station or airport line." }
    )
  },
  [pscustomobject]@{
    slug = "seven-days"
    title = "7 Days in Japan"
    duration = "7 days"
    pace = "Balanced"
    description = "A first-timer plan that keeps Tokyo and Kyoto readable without turning every day into transit."
    tags = @("tokyo", "kyoto", "first-time", "itinerary", "shrines", "food")
    categories = @("travel-guide", "culture", "food")
    steps = @(
      [pscustomobject]@{ label = "Days 1-3"; title = "Tokyo base"; body = "Use Tokyo for food confidence, practical setup, and one quiet neighborhood day." },
      [pscustomobject]@{ label = "Days 4-6"; title = "Kyoto slower"; body = "Move early, build around shrines and craft, and avoid overloading temple days." },
      [pscustomobject]@{ label = "Day 7"; title = "Return cleanly"; body = "Keep the final day close to your departure route and finish shopping before luggage becomes a problem." }
    )
  },
  [pscustomobject]@{
    slug = "ten-days"
    title = "10 Days in Japan"
    duration = "10 days"
    pace = "Classic"
    description = "The classic Tokyo, Kyoto, and Osaka route with more space for neighborhoods and food."
    tags = @("itinerary", "tokyo", "kyoto", "osaka", "food", "shopping")
    categories = @("travel-guide", "food", "things-to-buy")
    steps = @(
      [pscustomobject]@{ label = "Days 1-3"; title = "Tokyo"; body = "Start with food, transit confidence, and one older neighborhood before the trip speeds up." },
      [pscustomobject]@{ label = "Days 4-6"; title = "Kyoto"; body = "Anchor mornings with quiet places and afternoons with craft, tea, or riverside time." },
      [pscustomobject]@{ label = "Days 7-9"; title = "Osaka"; body = "Make food the structure and let neighborhoods fill the gaps." },
      [pscustomobject]@{ label = "Day 10"; title = "Departure buffer"; body = "Protect time for packing, gifts, and one simple final meal." }
    )
  },
  [pscustomobject]@{
    slug = "fourteen-days"
    title = "14 Days in Japan"
    duration = "14 days"
    pace = "Slow extension"
    description = "A longer plan that adds forest, islands, or walking routes after the classic first-trip core."
    tags = @("slow-travel", "yakushima", "setouchi", "walking", "islands", "kyoto")
    categories = @("hidden-gems", "travel-guide", "culture")
    steps = @(
      [pscustomobject]@{ label = "Days 1-6"; title = "First-trip core"; body = "Use Tokyo and Kyoto for orientation, food, shrines, and practical shopping." },
      [pscustomobject]@{ label = "Days 7-10"; title = "Choose one extension"; body = "Pick Yakushima, Setouchi, Fuji, or Kiso Valley instead of collecting all of them." },
      [pscustomobject]@{ label = "Days 11-13"; title = "Recover the rhythm"; body = "Return through Osaka or Tokyo with space for laundry, food, and lower-pressure wandering." },
      [pscustomobject]@{ label = "Day 14"; title = "Leave deliberately"; body = "Use the final day for calm logistics rather than a new major sight." }
    )
  }
)

$PlanningGuides = @(
  [pscustomobject]@{
    slug = "japan-travel-checklist"
    title = "Japan Travel Checklist"
    description = "A practical pre-trip checklist for first-time Japan travelers, designed to avoid last-minute friction."
    kicker = "Before You Fly"
    blocks = @(
      [pscustomobject]@{ heading = "Two weeks before"; items = @("Confirm passport validity and entry requirements from official sources.", "Reserve any must-have stays or restaurants.", "Choose a communication plan and save offline maps.") },
      [pscustomobject]@{ heading = "One week before"; items = @("Add transit cards, key addresses, and hotel names to your phone.", "Check luggage forwarding needs and pack a small day bag.", "Prepare written allergy or medication notes if relevant.") },
      [pscustomobject]@{ heading = "First day in Japan"; items = @("Withdraw or prepare cash for small shops.", "Confirm the airport-to-hotel route before leaving arrivals.", "Eat simply and sleep early enough to protect the next day.") }
    )
  },
  [pscustomobject]@{
    slug = "budget-transport-connectivity"
    title = "Budget, Transport, and Connectivity"
    description = "A local-first planning page for money, trains, luggage, and phone access without relying on live external feeds."
    kicker = "Trip Basics"
    blocks = @(
      [pscustomobject]@{ heading = "Money"; items = @("Carry a mix of cards and cash because small restaurants and rural stops can still be cash-friendly.", "Use price ranges as planning cues, then confirm current fares and fees before travel.", "Keep tax-free shopping sealed only when it fits your actual travel plan.") },
      [pscustomobject]@{ heading = "Transport"; items = @("Build days around one or two anchors instead of maximum transfers.", "Use station-area stays when the route has several city changes.", "Treat luggage forwarding as a comfort tool on multi-city routes.") },
      [pscustomobject]@{ heading = "Connectivity"; items = @("Choose eSIM, SIM, or pocket Wi-Fi based on device compatibility and group size.", "Save hotel addresses, train routes, and emergency notes offline.", "Keep a battery plan for long food, shrine, and walking days.") }
    )
  }
)

$GlossaryTerms = @(
  [pscustomobject]@{ term = "Otoshi"; category = "Food"; definition = "A small starter served at many izakaya as part of a seating charge." },
  [pscustomobject]@{ term = "Shotengai"; category = "City"; definition = "A local shopping arcade or street, often useful for everyday food and small shops." },
  [pscustomobject]@{ term = "Ryokan"; category = "Stay"; definition = "A Japanese-style inn, usually shaped by tatami rooms, baths, meal timing, and house rules." },
  [pscustomobject]@{ term = "Onsen"; category = "Stay"; definition = "A hot spring bath with etiquette around washing, towels, tattoos, and quiet behavior." },
  [pscustomobject]@{ term = "Tax-free"; category = "Shopping"; definition = "A visitor shopping process that may require sealed bags and passport handling." },
  [pscustomobject]@{ term = "Konbini"; category = "Food"; definition = "A convenience store, useful for breakfasts, tickets, ATMs, and small travel fixes." },
  [pscustomobject]@{ term = "IC card"; category = "Transport"; definition = "A stored-value transit card or mobile wallet setup used for many trains, buses, and small purchases." },
  [pscustomobject]@{ term = "Takkyubin"; category = "Logistics"; definition = "Luggage delivery service that can make multi-city routes easier." },
  [pscustomobject]@{ term = "Kaiseki"; category = "Food"; definition = "A seasonal multi-course meal often associated with ryokan and refined restaurants." },
  [pscustomobject]@{ term = "Shukubo"; category = "Stay"; definition = "Temple lodging, usually simple and rule-driven, with a focus on quiet and routine." }
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

function Get-AreaUrl([string]$Slug) {
  return "/areas/$Slug.html"
}

function Get-ItineraryUrl([string]$Slug) {
  return "/itineraries/$Slug.html"
}

function Get-PlanningUrl([string]$Slug) {
  return "/planning/$Slug.html"
}

function Get-SectionId([string]$Heading, [int]$Index) {
  $Slug = ([string]$Heading).ToLowerInvariant() -replace "[^a-z0-9]+", "-"
  $Slug = $Slug.Trim("-")
  if ([string]::IsNullOrWhiteSpace($Slug)) { $Slug = "section-$Index" }
  return $Slug
}

function Get-BuyIcon($Article) {
  if ($Article.id -like "*knife*") { return "&#128298;" }
  if ($Article.id -like "*matcha*") { return "&#127861;" }
  if ($Article.id -like "*drugstore*") { return "&#129524;" }
  if ($Article.id -like "*yukata*") { return "&#128088;" }
  return "&#10022;"
}

function Get-ImageBase([string]$ImagePath) {
  if ([string]::IsNullOrWhiteSpace($ImagePath)) { return "" }
  $DotIndex = $ImagePath.LastIndexOf(".")
  if ($DotIndex -lt 0) { return $ImagePath }
  return $ImagePath.Substring(0, $DotIndex)
}

function New-ResponsiveImage([string]$ImagePath, [string]$Alt, [string]$Loading, [string]$Sizes, [string]$Priority) {
  $Base = Get-ImageBase $ImagePath
  $LoadingAttr = if ([string]::IsNullOrWhiteSpace($Loading)) { "lazy" } else { $Loading }
  $PriorityAttr = ""
  if (-not [string]::IsNullOrWhiteSpace($Priority)) {
    $PriorityAttr = " fetchpriority=""$Priority"""
  }
  return @"
<picture>
  <source type="image/webp" srcset="$(Html "$Base-640.webp") 640w, $(Html "$Base-1024.webp") 1024w, $(Html "$Base-1536.webp") 1536w" sizes="$(Html $Sizes)">
  <img src="$(Html $ImagePath)" alt="$(Html $Alt)" width="1536" height="1024" loading="$LoadingAttr" decoding="async"$PriorityAttr>
</picture>
"@
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
  if (($Article.PSObject.Properties.Name -contains "shoppingGuide") -and @($Article.shoppingGuide).Count -ge 3) { $Score += 8 }

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

function Get-ClusterScore($Article, $Cluster) {
  $Tags = Get-ArticleTags $Article
  $SharedTags = @($Tags | Where-Object { @($Cluster.tags) -contains $_ }).Count
  $Score = $SharedTags * 18
  if (@($Cluster.categories) -contains $Article.category) { $Score += 12 }
  $Score += [Math]::Round((Get-ArticleScore $Article "") / 4)
  return [int]$Score
}

function Select-ClusterArticles($Cluster, [int]$Limit) {
  return @($Articles |
    Where-Object {
      $Article = $_
      $Tags = Get-ArticleTags $Article
      (@($Cluster.categories) -contains $Article.category) -or (@($Tags | Where-Object { @($Cluster.tags) -contains $_ }).Count -gt 0)
    } |
    Sort-Object @{ Expression = { Get-ClusterScore $_ $Cluster }; Descending = $true }, @{ Expression = { $_.publishedAt }; Descending = $true } |
    Select-Object -First $Limit)
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
  $PreloadImage = if ([string]::IsNullOrWhiteSpace($Image)) { "/assets/images/kyoto-shrine-hero-1536.webp" } else { "$(Get-ImageBase $Image)-1536.webp" }
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
  <meta name="theme-color" content="#111111">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="$(Html $Title)">
  <meta name="twitter:description" content="$(Html $Description)">
  <meta name="twitter:image" content="$(Html $ImageUrl)">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="preload" as="image" href="$(Html $PreloadImage)" type="image/webp">
  <link rel="alternate" type="application/rss+xml" title="TABI RSS" href="/feed.xml">
  <link rel="alternate" type="application/feed+json" title="TABI JSON Feed" href="/feed.json">
  <link rel="manifest" href="/site.webmanifest">
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

function New-MobileNav([string]$CurrentCategory) {
  $Items = foreach ($NavItem in $Config.nav) {
    $Current = ""
    if ($NavItem.slug -eq $CurrentCategory) { $Current = ' aria-current="page"' }
    '<a href="{0}"{1}>{2}</a>' -f (Get-CategoryUrl $NavItem.slug), $Current, (Html $NavItem.label)
  }
  $Items += '<a href="/itineraries/index.html">Itineraries</a>'
  $Items += '<a href="/areas/index.html">Areas</a>'
  $Items += '<a href="/planning/index.html">Planning</a>'
  return @"
<nav class="mobile-nav" aria-label="Primary mobile navigation">
  $($Items -join "`n")
</nav>
"@
}

function New-Layout([string]$Title, [string]$Description, [string]$Path, [string]$Main, [string]$CurrentCategory, [string]$Image, [string]$JsonLd) {
  $Head = New-Head $Title $Description $Path $Image
  $Nav = New-Nav $CurrentCategory
  $Ticker = New-Ticker
  $MobileNav = New-MobileNav $CurrentCategory
  $NewsletterHref = if ($Path -eq "/404.html") { "/#newsletter" } else { "#newsletter" }
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
      <a class="header-cta" href="$NewsletterHref">Free Newsletter</a>
    </div>
  </div>
</header>
$Ticker
$MobileNav
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
        <li><a href="/areas/index.html">Area Guides</a></li>
      </ul>
    </div>
    <div>
      <p class="footer-col-title">TABI</p>
      <ul class="footer-links">
        <li><a href="/#newsletter">Newsletter</a></li>
        <li><a href="/itineraries/index.html">Itineraries</a></li>
        <li><a href="/planning/index.html">Planning Tools</a></li>
        <li><a href="/glossary.html">Glossary</a></li>
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
  $Image = New-ResponsiveImage $Article.image $Article.imageAlt "lazy" "(max-width: 720px) 100vw, 33vw" ""
  return @"
<a class="$Class" href="$(Get-ArticleUrl $Article)" data-search-card>
  $Image
  <div class="card-content">
    <p class="card-cat">$(Html (Get-CategoryLabel $Article.category))</p>
    <h3 class="card-title">$(Html $Article.title)</h3>
    <p class="card-meta">$(Format-Date $Article.publishedAt) / $Read</p>
  </div>
</a>
"@
}

function New-CultureCard($Article) {
  $Image = New-ResponsiveImage $Article.image $Article.imageAlt "lazy" "(max-width: 720px) 100vw, 33vw" ""
  return @"
<a class="culture-card" href="$(Get-ArticleUrl $Article)" data-search-card>
  $Image
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
  $Image = New-ResponsiveImage $Article.image $Article.imageAlt "lazy" "(max-width: 720px) 100vw, 33vw" ""
  return @"
<a class="listing-card" href="$(Get-ArticleUrl $Article)" data-search-card>
  $Image
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

function New-ArticleToc($Article) {
  $Sections = @($Article.sections)
  if ($Sections.Count -lt 2) { return "" }
  $Links = for ($i = 0; $i -lt $Sections.Count; $i++) {
    $Section = $Sections[$i]
    '<li><a href="#{0}">{1}</a></li>' -f (Get-SectionId $Section.heading ($i + 1)), (Html $Section.heading)
  }
  return @"
<div class="article-toc" aria-label="Article sections">
  <p class="footer-col-title">In This Guide</p>
  <ol>
    $($Links -join "`n")
  </ol>
</div>
"@
}

function New-ShoppingGuidePanel($Article) {
  if ($Article.category -ne "things-to-buy") { return "" }
  if (-not ($Article.PSObject.Properties.Name -contains "shoppingGuide")) { return "" }
  $Items = @($Article.shoppingGuide)
  if ($Items.Count -eq 0) { return "" }

  $Rows = foreach ($Item in $Items) {
    @"
<div>
  <span>$(Html $Item.label)</span>
  <strong>$(Html $Item.value)</strong>
</div>
"@
  }
  $ComparisonHtml = ""
  if ($Article.PSObject.Properties.Name -contains "comparison") {
    $CompareRows = foreach ($Option in @($Article.comparison)) {
      @"
<tr>
  <th scope="row">$(Html $Option.option)</th>
  <td>$(Html $Option.bestFor)</td>
  <td>$(Html $Option.watchFor)</td>
</tr>
"@
    }
    if (@($CompareRows).Count -gt 0) {
      $ComparisonHtml = @"
<div class="comparison-wrap">
  <table class="comparison-table">
    <thead>
      <tr>
        <th scope="col">Option</th>
        <th scope="col">Best for</th>
        <th scope="col">Watch for</th>
      </tr>
    </thead>
    <tbody>
      $($CompareRows -join "`n")
    </tbody>
  </table>
</div>
"@
    }
  }
  $Disclosure = ""
  if ($Article.affiliate -eq $true) {
    $Disclosure = '<p class="shopping-disclosure">Affiliate disclosure: TABI may earn a commission from qualifying purchases, but the buying notes above are written as editorial guidance first.</p>'
  }

  return @"
<section class="shopping-guide" aria-labelledby="shopping-guide-title">
  <p class="page-kicker">Buyer's Notes</p>
  <h2 id="shopping-guide-title">What to check before you buy</h2>
  <div class="shopping-grid">
    $($Rows -join "`n")
  </div>
  $ComparisonHtml
  $Disclosure
</section>
"@
}

function New-FeedbackBlock($Article) {
  $Subject = [uri]::EscapeDataString("TABI feedback: $($Article.title)")
  return @"
<section class="feedback-block" aria-labelledby="feedback-title">
  <div>
    <p class="page-kicker">Keep This Guide Useful</p>
    <h2 id="feedback-title">Was this guide helpful?</h2>
    <p>Tell us what felt unclear, missing, or worth updating. This is a simple editorial inbox link, not a tracking widget.</p>
  </div>
  <a class="button secondary" href="mailto:$($Config.contactEmail)?subject=$Subject">Send Feedback</a>
</section>
"@
}

function New-CompactArticleCard($Article) {
  $Image = New-ResponsiveImage $Article.image $Article.imageAlt "lazy" "120px" ""
  return @"
<a class="compact-card" href="$(Get-ArticleUrl $Article)">
  $Image
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

function New-UtilityCard([string]$Label, [string]$Title, [string]$Description, [string]$Url) {
  return @"
<a class="utility-card" href="$Url">
  <span>$(Html $Label)</span>
  <strong>$(Html $Title)</strong>
  <p>$(Html $Description)</p>
</a>
"@
}

function New-Newsletter {
  $Image = New-ResponsiveImage "/assets/images/kyoto-shrine-hero.png" "A quiet Kyoto shrine path with lanterns at blue hour" "lazy" "(max-width: 720px) 100vw, 40vw" ""
  return @"
<section class="newsletter-wrap" id="newsletter" aria-labelledby="newsletter-title">
  <div class="newsletter">
    <div class="newsletter-visual">
      $Image
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
  $PlanningCards = @(
    New-UtilityCard "Itineraries" "Choose a Trip Length" "Static 3, 7, 10, and 14 day routes assembled from TABI's local article graph." "/itineraries/index.html"
    New-UtilityCard "Areas" "Browse by Place" "Tokyo, Kyoto, Osaka, Yakushima, and Setouchi hubs built from tags and category fit." "/areas/index.html"
    New-UtilityCard "Checklist" "Before You Fly" "A practical pre-trip checklist for money, transit, connectivity, luggage, and first-day friction." "/planning/japan-travel-checklist.html"
    New-UtilityCard "Glossary" "Decode Japan Travel Terms" "Plain-English explanations for terms that appear across food, stays, shopping, and transport." "/glossary.html"
  )
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
    $(New-ResponsiveImage $Hero.image $Hero.imageAlt "eager" "100vw" "high")
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
<section aria-labelledby="planning-heading">
  <div class="section-label">
    <span class="section-label-jp">&#35336;</span>
    <h2 class="section-label-en" id="planning-heading">Plan Your Trip</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="utility-grid">
    $($PlanningCards -join "`n")
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
  $Sections = @($Article.sections)
  $SectionHtml = for ($i = 0; $i -lt $Sections.Count; $i++) {
    $Section = $Sections[$i]
    $SectionId = Get-SectionId $Section.heading ($i + 1)
    @"
<section id="$SectionId">
  <h2>$(Html $Section.heading)</h2>
  <p>$(Html $Section.body)</p>
</section>
"@
  }
  $ShoppingGuide = New-ShoppingGuidePanel $Article
  $ArticleToc = New-ArticleToc $Article
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
    $(New-ResponsiveImage $Article.image $Article.imageAlt "eager" "(max-width: 900px) 100vw, 1180px" "high")
  </div>
  <div class="article-body">
$($SectionHtml -join "`n")
$ShoppingGuide
  </div>
  <aside class="article-sidebar" aria-label="Article details">
    $ArticleToc
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
$(New-FeedbackBlock $Article)
$(New-Newsletter)
"@

  $ImageUrl = SiteUrl $Article.image
  $ArticleJsonLd = @{
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
  }
  $BreadcrumbJsonLd = @{
    "@type" = "BreadcrumbList"
    itemListElement = @(
      @{ "@type" = "ListItem"; position = 1; name = "Home"; item = SiteUrl "/" },
      @{ "@type" = "ListItem"; position = 2; name = Get-CategoryLabel $Article.category; item = SiteUrl (Get-CategoryUrl $Article.category) },
      @{ "@type" = "ListItem"; position = 3; name = $Article.title; item = SiteUrl (Get-ArticleUrl $Article) }
    )
  }
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@graph" = @($ArticleJsonLd, $BreadcrumbJsonLd)
  } | ConvertTo-Json -Depth 10 -Compress

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

function New-AreaIndexPage {
  $Cards = foreach ($Area in $AreaClusters) {
    New-UtilityCard "Area Guide" $Area.title $Area.description (Get-AreaUrl $Area.slug)
  }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = "Areas"; url = "" }))
  <p class="page-kicker">Area Guides</p>
  <h1 class="page-title">Plan by place, not only by category.</h1>
  <p class="page-desc">Static regional hubs generated from TABI tags, categories, and article scores. No map integration required.</p>
</section>
$(New-AlgorithmNote "Area pages are assembled from local tag overlap, category fit, and article score.")
<section class="utility-grid" aria-label="Area guide links">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = "TABI Area Guides"
    description = "Regional planning hubs for Japan travel."
    url = SiteUrl "/areas/index.html"
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "Area Guides - TABI" "Regional planning hubs for Japan travel." "/areas/index.html" $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-AreaPage($Area) {
  $Items = Select-ClusterArticles $Area 100
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $NeighborhoodCards = foreach ($Place in $Area.neighborhoods) {
    @"
<div class="detail-card">
  <span>Place Cue</span>
  <strong>$(Html $Place.name)</strong>
  <p>$(Html $Place.note)</p>
</div>
"@
  }
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = "Areas"; url = "/areas/index.html" },
    [pscustomobject]@{ label = $Area.title; url = "" }
  )
  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">Area Guide</p>
  <h1 class="page-title">$(Html $Area.title)</h1>
  <p class="page-desc">$(Html $Area.description)</p>
</section>
<section class="split-feature" aria-labelledby="area-cues">
  <div>
    <p class="page-kicker">Local Planning Cues</p>
    <h2 id="area-cues">Where this area starts to make sense</h2>
    <p>These are editorial planning cues, not live listings. Use them to choose the shape of a day before confirming current details.</p>
  </div>
  <div class="detail-grid">
    $($NeighborhoodCards -join "`n")
  </div>
</section>
$(New-AlgorithmNote "Guides below are ranked by overlap with this area's tags, matching categories, freshness, seasonality, and quality score.")
<section class="listing-grid" aria-label="$(Html $Area.title) guides">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = "$($Area.title) Travel Guide"
    description = $Area.description
    url = SiteUrl (Get-AreaUrl $Area.slug)
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$($Area.title) - TABI" $Area.description (Get-AreaUrl $Area.slug) $Main "" $Area.image $JsonLd
}

function New-ItineraryHubPage {
  $Cards = foreach ($Plan in $ItineraryPlans) {
    New-UtilityCard $Plan.duration $Plan.title $Plan.description (Get-ItineraryUrl $Plan.slug)
  }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = "Itineraries"; url = "" }))
  <p class="page-kicker">Static Itineraries</p>
  <h1 class="page-title">Choose a Japan route by trip length.</h1>
  <p class="page-desc">These routes are generated from TABI's local article graph, using duration, pace, interests, and article quality rather than live booking data.</p>
</section>
$(New-AlgorithmNote "Each itinerary page pulls supporting guides by tag and category overlap, then sorts by local article score.")
<section class="utility-grid" aria-label="Itinerary links">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = "Japan Itineraries"
    description = "Static Japan trip routes by duration and travel style."
    url = SiteUrl "/itineraries/index.html"
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "Japan Itineraries - TABI" "Static Japan trip routes by duration and travel style." "/itineraries/index.html" $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-ItineraryPage($Plan) {
  $Items = Select-ClusterArticles $Plan 8
  $Cards = foreach ($Article in $Items) { New-CompactArticleCard $Article }
  $StepCards = foreach ($Step in $Plan.steps) {
    @"
<div class="route-step">
  <span>$(Html $Step.label)</span>
  <strong>$(Html $Step.title)</strong>
  <p>$(Html $Step.body)</p>
</div>
"@
  }
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = "Itineraries"; url = "/itineraries/index.html" },
    [pscustomobject]@{ label = $Plan.title; url = "" }
  )
  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">$(Html $Plan.duration) / $(Html $Plan.pace)</p>
  <h1 class="page-title">$(Html $Plan.title)</h1>
  <p class="page-desc">$(Html $Plan.description)</p>
</section>
<section class="route-panel" aria-labelledby="route-heading">
  <div class="section-label compact-label">
    <span class="section-label-jp">&#36947;</span>
    <h2 class="section-label-en" id="route-heading">Route Shape</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="route-grid">
    $($StepCards -join "`n")
  </div>
</section>
<section aria-labelledby="supporting-guides" class="next-read">
  <div class="section-label">
    <span class="section-label-jp">&#26412;</span>
    <h2 class="section-label-en" id="supporting-guides">Supporting Guides</h2>
    <div class="section-label-line"></div>
  </div>
  $(New-AlgorithmNote "Selected by this itinerary's interests, categories, and TABI article score.")
  <div class="compact-grid">
    $($Cards -join "`n")
  </div>
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "TouristTrip"
    name = $Plan.title
    description = $Plan.description
    url = SiteUrl (Get-ItineraryUrl $Plan.slug)
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$($Plan.title) - TABI" $Plan.description (Get-ItineraryUrl $Plan.slug) $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-PlanningIndexPage {
  $Cards = foreach ($Guide in $PlanningGuides) {
    New-UtilityCard $Guide.kicker $Guide.title $Guide.description (Get-PlanningUrl $Guide.slug)
  }
  $Cards += New-UtilityCard "Glossary" "Japan Travel Terms" "Plain-English explanations for recurring food, stay, shopping, and transport terms." "/glossary.html"
  $Cards += New-UtilityCard "Itineraries" "Trip Length Routes" "Use static route pages to choose the shape of a Japan trip before booking details." "/itineraries/index.html"
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = "Planning"; url = "" }))
  <p class="page-kicker">Planning Tools</p>
  <h1 class="page-title">Practical Japan planning without live integrations.</h1>
  <p class="page-desc">Evergreen checklists, trip basics, terminology, and route pages that can be maintained locally in the TABI codebase.</p>
</section>
<section class="utility-grid" aria-label="Planning tools">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = "TABI Planning Tools"
    description = "Evergreen Japan planning tools maintained locally."
    url = SiteUrl "/planning/index.html"
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "Planning Tools - TABI" "Evergreen Japan planning tools maintained locally." "/planning/index.html" $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function New-PlanningGuidePage($Guide) {
  $Blocks = foreach ($Block in $Guide.blocks) {
    $Items = foreach ($Item in $Block.items) {
      '<li>{0}</li>' -f (Html $Item)
    }
    @"
<section class="checklist-block">
  <h2>$(Html $Block.heading)</h2>
  <ul>
    $($Items -join "`n")
  </ul>
</section>
"@
  }
  $SiblingCards = foreach ($Item in $PlanningGuides) {
    if ($Item.slug -ne $Guide.slug) {
      New-UtilityCard $Item.kicker $Item.title $Item.description (Get-PlanningUrl $Item.slug)
    }
  }
  $SiblingCards += New-UtilityCard "Glossary" "Travel Terms" "Quick explanations for common Japan travel words." "/glossary.html"
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = "Planning"; url = "/planning/index.html" }, [pscustomobject]@{ label = $Guide.title; url = "" }))
  <p class="page-kicker">$(Html $Guide.kicker)</p>
  <h1 class="page-title">$(Html $Guide.title)</h1>
  <p class="page-desc">$(Html $Guide.description)</p>
</section>
<article class="guide-body">
  $($Blocks -join "`n")
</article>
<section class="utility-grid" aria-label="More planning tools">
  $($SiblingCards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "HowTo"
    name = $Guide.title
    description = $Guide.description
    url = SiteUrl (Get-PlanningUrl $Guide.slug)
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$($Guide.title) - TABI" $Guide.description (Get-PlanningUrl $Guide.slug) $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function New-GlossaryPage {
  $Terms = foreach ($Term in ($GlossaryTerms | Sort-Object term)) {
    @"
<article class="glossary-card" id="$(Get-SectionId $Term.term 1)">
  <span>$(Html $Term.category)</span>
  <h2>$(Html $Term.term)</h2>
  <p>$(Html $Term.definition)</p>
</article>
"@
  }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = "Glossary"; url = "" }))
  <p class="page-kicker">Glossary</p>
  <h1 class="page-title">Japan travel terms, decoded.</h1>
  <p class="page-desc">A static reference for recurring words across TABI's food, stay, shopping, and transport guides.</p>
</section>
<section class="glossary-grid" aria-label="Japan travel glossary">
  $($Terms -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "DefinedTermSet"
    name = "TABI Japan Travel Glossary"
    description = "Plain-English definitions for recurring Japan travel terms."
    url = SiteUrl "/glossary.html"
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "Japan Travel Glossary - TABI" "Plain-English definitions for recurring Japan travel terms." "/glossary.html" $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function ConvertTo-Rfc3339([string]$DateValue) {
  $Date = [datetime]::ParseExact($DateValue, "yyyy-MM-dd", $EnglishCulture)
  return $Date.ToString("yyyy-MM-ddT00:00:00+09:00", $EnglishCulture)
}

function New-RssFeed {
  $Latest = @($Articles | Sort-Object publishedAt -Descending | Select-Object -First 20)
  $Items = foreach ($Article in $Latest) {
    @"
  <item>
    <title>$(Html $Article.title)</title>
    <link>$(Html (SiteUrl (Get-ArticleUrl $Article)))</link>
    <guid>$(Html (SiteUrl (Get-ArticleUrl $Article)))</guid>
    <pubDate>$([datetime]::ParseExact($Article.publishedAt, "yyyy-MM-dd", $EnglishCulture).ToUniversalTime().ToString("r", $EnglishCulture))</pubDate>
    <description>$(Html $Article.summary)</description>
    <category>$(Html (Get-CategoryLabel $Article.category))</category>
  </item>
"@
  }
  return @"
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
  <title>$(Html $Config.siteName) - $(Html $Config.tagline)</title>
  <link>$(Html $Config.siteUrl)</link>
  <description>$(Html $Config.description)</description>
  <language>en</language>
  <lastBuildDate>$((Get-Date).ToUniversalTime().ToString("r", $EnglishCulture))</lastBuildDate>
$($Items -join "`n")
</channel>
</rss>
"@
}

function New-JsonFeed {
  $Latest = @($Articles | Sort-Object publishedAt -Descending | Select-Object -First 20)
  $Items = foreach ($Article in $Latest) {
    [pscustomobject]@{
      id = SiteUrl (Get-ArticleUrl $Article)
      url = SiteUrl (Get-ArticleUrl $Article)
      title = $Article.title
      summary = $Article.summary
      content_text = $Article.summary
      image = SiteUrl $Article.image
      date_published = ConvertTo-Rfc3339 $Article.publishedAt
      tags = @($Article.tags)
    }
  }
  $Feed = [pscustomobject]@{
    version = "https://jsonfeed.org/version/1.1"
    title = "$($Config.siteName) - $($Config.tagline)"
    home_page_url = $Config.siteUrl
    feed_url = SiteUrl "/feed.json"
    description = $Config.description
    language = "en"
    items = $Items
  }
  return ($Feed | ConvertTo-Json -Depth 8)
}

function New-WebManifest {
  $Manifest = [pscustomobject]@{
    name = "$($Config.siteName) - $($Config.tagline)"
    short_name = $Config.siteName
    description = $Config.description
    start_url = "/"
    display = "standalone"
    background_color = "#f7f4ef"
    theme_color = "#111111"
    lang = "en"
  }
  return ($Manifest | ConvertTo-Json -Depth 5)
}

function New-LlmsText {
  $TopArticles = Select-DiverseArticles $Articles 8 ""
  $ArticleLines = foreach ($Article in $TopArticles) {
    "- [$($Article.title)]($(SiteUrl (Get-ArticleUrl $Article))): $($Article.summary)"
  }
  $TopicLines = foreach ($Topic in $TopicClusters) {
    "- [$($Topic.title)]($(SiteUrl (Get-TopicUrl $Topic.slug))): $($Topic.description)"
  }
  $AreaLines = foreach ($Area in $AreaClusters) {
    "- [$($Area.title)]($(SiteUrl (Get-AreaUrl $Area.slug))): $($Area.description)"
  }
  $ItineraryLines = foreach ($Plan in $ItineraryPlans) {
    "- [$($Plan.title)]($(SiteUrl (Get-ItineraryUrl $Plan.slug))): $($Plan.description)"
  }
  return @"
# TABI

TABI is an English-language curation site introducing Japan through travel, culture, food, hidden places, and practical things worth bringing home.

## Core Topics

$($TopicLines -join "`n")

## Area Guides

$($AreaLines -join "`n")

## Itineraries

$($ItineraryLines -join "`n")

## Recommended Guides

$($ArticleLines -join "`n")

## Site Data

- Sitemap: $(SiteUrl "/sitemap.xml")
- RSS: $(SiteUrl "/feed.xml")
- JSON Feed: $(SiteUrl "/feed.json")
"@
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
  $Urls = @([pscustomobject]@{ loc = "/"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) })
  $Urls += foreach ($Category in $Config.categories) { [pscustomobject]@{ loc = Get-CategoryUrl $Category.slug; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
  $Urls += foreach ($Topic in $TopicClusters) { [pscustomobject]@{ loc = Get-TopicUrl $Topic.slug; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
  $Urls += [pscustomobject]@{ loc = "/areas/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
  $Urls += foreach ($Area in $AreaClusters) { [pscustomobject]@{ loc = Get-AreaUrl $Area.slug; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
  $Urls += [pscustomobject]@{ loc = "/itineraries/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
  $Urls += foreach ($Plan in $ItineraryPlans) { [pscustomobject]@{ loc = Get-ItineraryUrl $Plan.slug; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
  $Urls += [pscustomobject]@{ loc = "/planning/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
  $Urls += foreach ($Guide in $PlanningGuides) { [pscustomobject]@{ loc = Get-PlanningUrl $Guide.slug; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
  $Urls += [pscustomobject]@{ loc = "/glossary.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
  $Tags = @($Articles | ForEach-Object { $_.tags } | Sort-Object -Unique)
  $Urls += foreach ($Tag in $Tags) { [pscustomobject]@{ loc = Get-TagUrl $Tag; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
  $Urls += foreach ($Article in $Articles) { [pscustomobject]@{ loc = Get-ArticleUrl $Article; lastmod = $Article.publishedAt } }
  $Items = foreach ($Url in $Urls) {
    "  <url><loc>$(Html (SiteUrl $Url.loc))</loc><lastmod>$($Url.lastmod)</lastmod></url>"
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

Write-Page "areas/index.html" (New-AreaIndexPage)
foreach ($Area in $AreaClusters) {
  Write-Page "areas/$($Area.slug).html" (New-AreaPage $Area)
}

Write-Page "itineraries/index.html" (New-ItineraryHubPage)
foreach ($Plan in $ItineraryPlans) {
  Write-Page "itineraries/$($Plan.slug).html" (New-ItineraryPage $Plan)
}

Write-Page "planning/index.html" (New-PlanningIndexPage)
foreach ($Guide in $PlanningGuides) {
  Write-Page "planning/$($Guide.slug).html" (New-PlanningGuidePage $Guide)
}

Write-Page "glossary.html" (New-GlossaryPage)

$AllTags = @($Articles | ForEach-Object { $_.tags } | Sort-Object -Unique)
foreach ($Tag in $AllTags) {
  Write-Page "tags/$Tag.html" (New-TagPage $Tag)
}

Write-Page "404.html" (New-NotFoundPage)
Write-Page "sitemap.xml" (New-Sitemap)
Write-Page "robots.txt" "User-agent: *`nAllow: /`nSitemap: $(SiteUrl '/sitemap.xml')`n"
Write-Page "feed.xml" (New-RssFeed)
Write-Page "feed.json" (New-JsonFeed)
Write-Page "site.webmanifest" (New-WebManifest)
Write-Page "llms.txt" (New-LlmsText)

Write-Host "Generated $($Articles.Count) articles, $($Config.categories.Count) categories, $($TopicClusters.Count) topics, $($AreaClusters.Count) areas, $($ItineraryPlans.Count) itineraries, and $($AllTags.Count) tag pages."
