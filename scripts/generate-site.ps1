$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Config = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "site.config.json") | ConvertFrom-Json
$BaseArticles = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "articles.json") | ConvertFrom-Json
$JapaneseArticleOverrides = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "articles.ja.json") | ConvertFrom-Json
$JapaneseStatic = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "static.ja.json") | ConvertFrom-Json
$ContentPolicy = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "content-policy.json") | ConvertFrom-Json
$Articles = $BaseArticles
$EnglishCulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
$JapaneseCulture = [System.Globalization.CultureInfo]::GetCultureInfo("ja-JP")
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Today = Get-Date
$Script:CurrentLang = "en"
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

function Is-Japanese {
  return $Script:CurrentLang -eq "ja"
}

function T([string]$Key) {
  if (-not (Is-Japanese)) {
    $English = @{
      skip = "Skip to content"; topBar = "Japan Travel & Culture Guide"; topExtra = " / Updated weekly / Free newsletter every Friday"
      latest = "Latest"; search = "Search TABI"; closeSearch = "Close search"; searchPlaceholder = "Search Kyoto, food, craft, hidden gems..."
      newsletter = "Free Newsletter"; explore = "Explore"; disclosure = "Disclosure"; contact = "Contact"; sitemap = "Sitemap"
      sourcePolicy = "Source Policy"; sourcePolicyShort = "Source Policy"; language = "Language"; readNext = "Read Next"
      filedUnder = "Filed Under"; related = "Related"; inThisGuide = "In This Guide"; sourceInfo = "Source & Verification"
      articleScore = "Article score"; quality = "Quality"; freshness = "Freshness"; seasonalFit = "Seasonal fit"
      affiliate = "Affiliate links may earn us a commission."; copyright = "All rights reserved."; home = "Home"
    }
    return $English[$Key]
  }
  $Japanese = @{
    skip = "本文へ移動"; topBar = "日本の旅と文化のガイド"; topExtra = " / 毎週更新 / 金曜にニュースレター"
    latest = "新着"; search = "TABIを検索"; closeSearch = "検索を閉じる"; searchPlaceholder = "京都、食、工芸、穴場を検索..."
    newsletter = "無料ニュースレター"; explore = "探す"; disclosure = "開示"; contact = "お問い合わせ"; sitemap = "サイトマップ"
    sourcePolicy = "情報出所ポリシー"; sourcePolicyShort = "出所ポリシー"; language = "言語"; readNext = "次に読む"
    filedUnder = "分類"; related = "関連記事"; inThisGuide = "このガイドの内容"; sourceInfo = "出所と検証"
    articleScore = "記事スコア"; quality = "品質"; freshness = "鮮度"; seasonalFit = "季節適合"
    affiliate = "一部リンクから収益を得る場合があります。"; copyright = "All rights reserved."; home = "ホーム"
  }
  return $Japanese[$Key]
}

function Get-LangPrefix([string]$Lang) {
  if ($Lang -eq "ja") { return "/ja" }
  return ""
}

function Get-BasePath([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { return "/" }
  if ($Path -eq "/ja" -or $Path -eq "/ja/") { return "/" }
  if ($Path.StartsWith("/ja/")) { return $Path.Substring(3) }
  return $Path
}

function LocalizePath([string]$Path, [string]$Lang) {
  if ([string]::IsNullOrWhiteSpace($Path)) { $Path = "/" }
  if ($Path.StartsWith("http") -or $Path.StartsWith("mailto:") -or $Path.StartsWith("#")) { return $Path }
  $BasePath = Get-BasePath $Path
  if (-not $BasePath.StartsWith("/")) { $BasePath = "/$BasePath" }
  if ($Lang -eq "ja") {
    if ($BasePath -eq "/") { return "/ja/" }
    return "/ja$BasePath"
  }
  return $BasePath
}

function Href([string]$Path) {
  return LocalizePath $Path $Script:CurrentLang
}

function SiteUrl([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { $Path = "/" }
  if (-not $Path.StartsWith("/")) { $Path = "/$Path" }
  return "$($Config.siteUrl.TrimEnd('/'))$Path"
}

function Format-Date([string]$DateValue) {
  $Date = [datetime]::ParseExact($DateValue, "yyyy-MM-dd", $EnglishCulture)
  if (Is-Japanese) {
    return $Date.ToString("yyyy年M月d日", $JapaneseCulture)
  }
  return $Date.ToString("MMMM d, yyyy", $EnglishCulture)
}

function Format-ReadingTime([int]$Minutes) {
  if (Is-Japanese) { return "$Minutes分で読める" }
  if ($Minutes -eq 1) { return "1 min read" }
  return "$Minutes min read"
}

function Get-CategoryLabel([string]$Slug) {
  if (Is-Japanese) {
    switch ($Slug) {
      "travel-guide" { return "旅行ガイド" }
      "culture" { return "文化と伝統" }
      "food" { return "食" }
      "things-to-buy" { return "買うべきもの" }
      "hidden-gems" { return "知られざる場所" }
    }
  }
  foreach ($Category in $Config.categories) {
    if ($Category.slug -eq $Slug) { return $Category.label }
  }
  return $Slug
}

function Get-ArticleUrl($Article) {
  return Href "/articles/$($Article.id).html"
}

function Get-CategoryUrl([string]$Slug) {
  return Href "/categories/$Slug.html"
}

function Get-TagUrl([string]$Tag) {
  return Href "/tags/$Tag.html"
}

function Get-AreaUrl([string]$Slug) {
  return Href "/areas/$Slug.html"
}

function Get-ItineraryUrl([string]$Slug) {
  return Href "/itineraries/$Slug.html"
}

function Get-PlanningUrl([string]$Slug) {
  return Href "/planning/$Slug.html"
}

function Get-TopicUrl([string]$Slug) {
  return Href "/topics/$Slug.html"
}

function Get-StaticTranslation([string]$Group, [string]$Key) {
  if (-not (Is-Japanese)) { return $null }
  $GroupProperty = $JapaneseStatic.PSObject.Properties[$Group]
  if ($null -eq $GroupProperty) { return $null }
  $KeyProperty = $GroupProperty.Value.PSObject.Properties[$Key]
  if ($null -eq $KeyProperty) { return $null }
  return $KeyProperty.Value
}

function Get-LocalizedStatic($Object, [string]$Group, [string]$Key) {
  $Translation = Get-StaticTranslation $Group $Key
  if ($null -eq $Translation) { return $Object }
  $Copy = [ordered]@{}
  foreach ($Property in $Object.PSObject.Properties) {
    $Copy[$Property.Name] = $Property.Value
  }
  foreach ($Property in $Translation.PSObject.Properties) {
    $Copy[$Property.Name] = $Property.Value
  }
  return [pscustomobject]$Copy
}

function Get-TopicDisplay($Topic) {
  return Get-LocalizedStatic $Topic "topics" $Topic.slug
}

function Get-AreaDisplay($Area) {
  return Get-LocalizedStatic $Area "areas" $Area.slug
}

function Get-ItineraryDisplay($Plan) {
  return Get-LocalizedStatic $Plan "itineraries" $Plan.slug
}

function Get-PlanningDisplay($Guide) {
  return Get-LocalizedStatic $Guide "planning" $Guide.slug
}

function Get-GlossaryDisplay($Term) {
  return Get-LocalizedStatic $Term "glossary" $Term.term
}

function Copy-ArticleForLanguage($Article, [string]$Lang) {
  if ($Lang -ne "ja") { return $Article }
  $Override = @($JapaneseArticleOverrides | Where-Object { $_.id -eq $Article.id } | Select-Object -First 1)
  if ($Override.Count -eq 0) { return $Article }
  $Copy = [ordered]@{}
  foreach ($Property in $Article.PSObject.Properties) {
    $Copy[$Property.Name] = $Property.Value
  }
  $Copy["title"] = $Override[0].title
  $Copy["summary"] = $Override[0].summary
  $Copy["sections"] = @($Override[0].sections)
  if ($Override[0].PSObject.Properties.Name -contains "imageAlt") {
    $Copy["imageAlt"] = $Override[0].imageAlt
  }
  return [pscustomobject]$Copy
}

function Set-RenderLanguage([string]$Lang) {
  $Script:CurrentLang = $Lang
  $Script:Articles = @($BaseArticles | ForEach-Object { Copy-ArticleForLanguage $_ $Lang })
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
  if ($DaysOld -le 30) {
    if (Is-Japanese) { return "新しい" }
    return "Fresh"
  }
  if ($DaysOld -le 120) {
    if (Is-Japanese) { return "確認予定" }
    return "Review soon"
  }
  if (Is-Japanese) { return "更新確認が必要" }
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
    '<li><a href="{0}"{1}>{2}</a></li>' -f (Get-CategoryUrl $NavItem.slug), $Current, (Html (Get-CategoryLabel $NavItem.slug))
  }
  return ($Items -join "`n")
}

function New-SearchJson {
  $Payload = foreach ($Article in $Articles) {
    $Topic = Get-ArticleTopic $Article
    $TopicDisplay = if ($null -ne $Topic) { Get-TopicDisplay $Topic } else { $null }
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
      topic = if ($null -ne $TopicDisplay) { $TopicDisplay.title } else { "" }
    }
  }
  return ($Payload | ConvertTo-Json -Depth 6 -Compress)
}

$Script:SearchJson = New-SearchJson

function New-Head([string]$Title, [string]$Description, [string]$Path, [string]$Image) {
  $Canonical = SiteUrl $Path
  $BasePath = Get-BasePath $Path
  $EnglishPath = LocalizePath $BasePath "en"
  $JapanesePath = LocalizePath $BasePath "ja"
  $ImageUrl = if ([string]::IsNullOrWhiteSpace($Image)) { SiteUrl "/assets/images/kyoto-shrine-hero.png" } else { SiteUrl $Image }
  $OgType = if ($BasePath -like "/articles/*") { "article" } else { "website" }
  $PreloadImage = if ([string]::IsNullOrWhiteSpace($Image)) { "/assets/images/kyoto-shrine-hero-1536.webp" } else { "$(Get-ImageBase $Image)-1536.webp" }
  $FeedXml = Href "/feed.xml"
  $FeedJson = Href "/feed.json"
  return @"
<head>
  <meta charset="UTF-8">
  <meta http-equiv="content-language" content="$Script:CurrentLang">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$(Html $Title)</title>
  <meta name="description" content="$(Html $Description)">
  <link rel="canonical" href="$(Html $Canonical)">
  <link rel="alternate" hreflang="en" href="$(Html (SiteUrl $EnglishPath))">
  <link rel="alternate" hreflang="ja" href="$(Html (SiteUrl $JapanesePath))">
  <link rel="alternate" hreflang="x-default" href="$(Html (SiteUrl $EnglishPath))">
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
  <link rel="alternate" type="application/rss+xml" title="TABI RSS" href="$FeedXml">
  <link rel="alternate" type="application/feed+json" title="TABI JSON Feed" href="$FeedJson">
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
  <div class="ticker-label">$(Html (T "latest"))</div>
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
    '<a href="{0}"{1}>{2}</a>' -f (Get-CategoryUrl $NavItem.slug), $Current, (Html (Get-CategoryLabel $NavItem.slug))
  }
  $ItineraryLabel = if (Is-Japanese) { "旅程" } else { "Itineraries" }
  $AreaLabel = if (Is-Japanese) { "地域" } else { "Areas" }
  $PlanningLabel = if (Is-Japanese) { "準備" } else { "Planning" }
  $Items += '<a href="{0}">{1}</a>' -f (Href "/itineraries/index.html"), $ItineraryLabel
  $Items += '<a href="{0}">{1}</a>' -f (Href "/areas/index.html"), $AreaLabel
  $Items += '<a href="{0}">{1}</a>' -f (Href "/planning/index.html"), $PlanningLabel
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
  $NewsletterHref = if ((Get-BasePath $Path) -eq "/404.html") { "$(Href "/")#newsletter" } else { "#newsletter" }
  $HomeHref = Href "/"
  $LangBase = Get-BasePath $Path
  $EnglishHref = LocalizePath $LangBase "en"
  $JapaneseHref = LocalizePath $LangBase "ja"
  $CurrentLangLabel = if (Is-Japanese) { "日本語" } else { "English" }
  $SearchJson = New-SearchJson
  $FirstTimeTopic = Get-TopicDisplay ($TopicClusters | Where-Object { $_.slug -eq "first-time-japan" } | Select-Object -First 1)
  $SlowTravelTopic = Get-TopicDisplay ($TopicClusters | Where-Object { $_.slug -eq "slow-travel" } | Select-Object -First 1)
  $StructuredData = ""
  if (-not [string]::IsNullOrWhiteSpace($JsonLd)) {
    $StructuredData = "<script type=""application/ld+json"">$JsonLd</script>"
  }
  return @"
<!DOCTYPE html>
<html lang="$Script:CurrentLang">
$Head
<body>
<a class="skip-link" href="#main">$(Html (T "skip"))</a>
<div class="top-bar"><span>$(Html (T "topBar"))</span><span class="top-extra">$(Html (T "topExtra"))</span></div>
<header class="site-header">
  <div class="header-inner">
    <ul class="header-nav">
      $Nav
    </ul>
    <a class="site-logo" href="$HomeHref" aria-label="TABI home">
      <span class="logo-en">TABI<span class="dot">.</span></span>
      <span class="logo-jp">&#26053; - $(if (Is-Japanese) { "日本を深く見る" } else { "Discover Japan" })</span>
    </a>
    <div class="header-actions">
      <nav class="language-switch" aria-label="$(Html (T "language"))">
        <a href="$EnglishHref"$(if (-not (Is-Japanese)) { ' aria-current="true"' } else { '' })>EN</a>
        <a href="$JapaneseHref"$(if (Is-Japanese) { ' aria-current="true"' } else { '' })>JP</a>
      </nav>
      <button class="header-search" type="button" aria-label="$(Html (T "search"))" title="$(Html (T "search"))" data-search-toggle>&#8981;</button>
      <a class="header-cta" href="$NewsletterHref">$(Html (T "newsletter"))</a>
    </div>
  </div>
</header>
$Ticker
$MobileNav
<div class="search-panel" data-search-panel hidden>
  <div class="search-panel-inner" role="dialog" aria-modal="true" aria-label="$(Html (T "search"))">
    <div class="search-panel-head">
      <p class="search-panel-title">$(Html (T "search"))</p>
      <button class="icon-button" type="button" aria-label="$(Html (T "closeSearch"))" data-search-close>&#10005;</button>
    </div>
    <input class="search-input" type="search" placeholder="$(Html (T "searchPlaceholder"))" data-search-input>
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
      <p class="footer-tagline">$(if (Is-Japanese) { "日本の旅、文化、食、知られざる場所、持ち帰る価値のあるものを静かに案内します。" } else { "Your guide to the real Japan: travel, culture, food, hidden places, and the things worth bringing home." })</p>
    </div>
    <div>
      <p class="footer-col-title">$(Html (T "explore"))</p>
      <ul class="footer-links">
        <li><a href="$(Get-CategoryUrl "travel-guide")">$(Html (Get-CategoryLabel "travel-guide"))</a></li>
        <li><a href="$(Get-CategoryUrl "culture")">$(Html (Get-CategoryLabel "culture"))</a></li>
        <li><a href="$(Get-CategoryUrl "food")">$(Html (Get-CategoryLabel "food"))</a></li>
        <li><a href="$(Get-CategoryUrl "hidden-gems")">$(Html (Get-CategoryLabel "hidden-gems"))</a></li>
        <li><a href="$(Get-CategoryUrl "things-to-buy")">$(Html (Get-CategoryLabel "things-to-buy"))</a></li>
        <li><a href="$(Href "/areas/index.html")">$(if (Is-Japanese) { "地域ガイド" } else { "Area Guides" })</a></li>
      </ul>
    </div>
    <div>
      <p class="footer-col-title">TABI</p>
      <ul class="footer-links">
        <li><a href="$(Href "/")#newsletter">Newsletter</a></li>
        <li><a href="$(Href "/itineraries/index.html")">$(if (Is-Japanese) { "旅程" } else { "Itineraries" })</a></li>
        <li><a href="$(Href "/planning/index.html")">$(if (Is-Japanese) { "旅の準備" } else { "Planning Tools" })</a></li>
        <li><a href="$(Href "/glossary.html")">$(if (Is-Japanese) { "用語集" } else { "Glossary" })</a></li>
        <li><a href="$(Href "/articles/hidden-shrines-kyoto-locals-keep-secret.html")">$(if (Is-Japanese) { "ここから読む" } else { "Start Here" })</a></li>
        <li><a href="$(Get-TopicUrl "first-time-japan")">$(Html $FirstTimeTopic.title)</a></li>
        <li><a href="$(Get-TopicUrl "slow-travel")">$(Html $SlowTravelTopic.title)</a></li>
      </ul>
    </div>
    <div>
      <p class="footer-col-title">$(Html (T "disclosure"))</p>
      <ul class="footer-links">
        <li><a href="$(Get-CategoryUrl "things-to-buy")">$(if (Is-Japanese) { "買い物ガイド" } else { "Shopping Guides" })</a></li>
        <li><a href="$(Href "/source-policy.html")">$(Html (T "sourcePolicyShort"))</a></li>
        <li><a href="/sitemap.xml">$(Html (T "sitemap"))</a></li>
        <li><a href="mailto:$($Config.contactEmail)">$(Html (T "contact"))</a></li>
      </ul>
    </div>
  </div>
  <div class="footer-bottom">
    <div class="footer-bottom-inner">
      <span>&copy; 2026 TABI. $(Html (T "copyright"))</span>
      <span>$(Html (T "affiliate"))</span>
    </div>
  </div>
</footer>
<script>window.TABI_ARTICLES = $SearchJson;</script>
<script src="/script.js"></script>
$StructuredData
</body>
</html>
"@
}

function New-ArticleCard($Article, [bool]$Featured) {
  $Class = if ($Featured) { "article-card featured" } else { "article-card" }
  $Read = Format-ReadingTime $Article.readingTime
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
  $ScoreLabel = if (Is-Japanese) { "スコア" } else { "Score" }
  $Image = New-ResponsiveImage $Article.image $Article.imageAlt "lazy" "(max-width: 720px) 100vw, 33vw" ""
  return @"
<a class="listing-card" href="$(Get-ArticleUrl $Article)" data-search-card>
  $Image
  <p class="card-cat">$(Html (Get-CategoryLabel $Article.category))</p>
  <h2>$(Html $Article.title)</h2>
  <p>$(Html $Article.summary)</p>
  <p class="listing-meta">$(Html $ScoreLabel) $Score / $(Html $Freshness)</p>
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
    $Label = if ($Item.label -eq "Home") { T "home" } else { $Item.label }
    if ([string]::IsNullOrWhiteSpace($Item.url)) {
      '<span aria-current="page">{0}</span>' -f (Html $Label)
    } else {
      '<a href="{0}">{1}</a>' -f (Href $Item.url), (Html $Label)
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
  <div><span>$(Html (T "articleScore"))</span><strong>$Score</strong></div>
  <div><span>$(Html (T "quality"))</span><strong>$Quality</strong></div>
  <div><span>$(Html (T "freshness"))</span><strong>$(Html $Freshness)</strong></div>
  <div><span>$(Html (T "seasonalFit"))</span><strong>$Seasonality</strong></div>
</div>
"@
}

function Get-ArticleSourceMeta($Article) {
  $Default = $ContentPolicy.defaultArticleMeta
  return [pscustomobject]@{
    sourcePolicy = if ($Article.PSObject.Properties.Name -contains "sourcePolicy") { $Article.sourcePolicy } else { $Default.sourcePolicy }
    verificationLevel = if ($Article.PSObject.Properties.Name -contains "verificationLevel") { $Article.verificationLevel } else { $Default.verificationLevel }
    lastChecked = if ($Article.PSObject.Properties.Name -contains "lastChecked") { $Article.lastChecked } else { $Default.lastChecked }
    sourceNote = if ($Article.PSObject.Properties.Name -contains "sourceNote") { $Article.sourceNote } else { $Default.sourceNote }
  }
}

function New-ArticleSourcePanel($Article) {
  $Meta = Get-ArticleSourceMeta $Article
  $PolicyText = if (Is-Japanese) { "AIスクレイピング禁止、引用不可、転載不可、権利不明、倫理的に問題のある情報源は使わない方針です。" } else { "TABI avoids sources that prohibit AI scraping, quotation, republication, reuse, or create ethical risk." }
  $ConfirmText = if (Is-Japanese) { "営業時間、価格、閉店、交通ルールなど変わりやすい情報は、旅行前に公式情報で確認してください。" } else { "Confirm volatile details such as hours, prices, closures, and transport rules with official sources before travel." }
  $PolicyLabel = if (Is-Japanese) { "方針" } else { "Policy" }
  $VerificationLabel = if (Is-Japanese) { "検証" } else { "Verification" }
  $CheckedLabel = if (Is-Japanese) { "最終確認" } else { "Last checked" }
  $PanelText = if (Is-Japanese) { "$PolicyText$ConfirmText" } else { "$PolicyText $ConfirmText" }
  return @"
<div class="source-panel">
  <p class="footer-col-title">$(Html (T "sourceInfo"))</p>
  <dl>
    <div><dt>$(Html $PolicyLabel)</dt><dd>$(Html $Meta.sourcePolicy)</dd></div>
    <div><dt>$(Html $VerificationLabel)</dt><dd>$(Html $Meta.verificationLevel)</dd></div>
    <div><dt>$(Html $CheckedLabel)</dt><dd>$(Html $Meta.lastChecked)</dd></div>
  </dl>
  <p>$(Html $PanelText)</p>
  <a class="tag-pill topic-pill" href="$(Href "/source-policy.html")">$(Html (T "sourcePolicy"))</a>
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
  <p class="footer-col-title">$(Html (T "inThisGuide"))</p>
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
  $Href = Href $Url
  return @"
<a class="utility-card" href="$Href">
  <span>$(Html $Label)</span>
  <strong>$(Html $Title)</strong>
  <p>$(Html $Description)</p>
</a>
"@
}

function New-Newsletter {
  $Alt = if (Is-Japanese) { "夕暮れの静かな京都の神社参道" } else { "A quiet Kyoto shrine path with lanterns at blue hour" }
  $Kicker = if (Is-Japanese) { "無料ニュースレター" } else { "Free Newsletter" }
  $Title = if (Is-Japanese) { "日本の旅を、静かに深く。" } else { "Japan, delivered to your inbox." }
  $Description = if (Is-Japanese) { "毎週金曜日、ひとつの目的地、ひとつの文化的な視点、持ち帰る価値のあるものをお届けします。" } else { "Every Friday: one destination, one cultural insight, and one thing worth bringing home. No noise. Just the Japan worth knowing." }
  $Button = if (Is-Japanese) { "登録" } else { "Subscribe" }
  $Image = New-ResponsiveImage "/assets/images/kyoto-shrine-hero.png" $Alt "lazy" "(max-width: 720px) 100vw, 40vw" ""
  return @"
<section class="newsletter-wrap" id="newsletter" aria-labelledby="newsletter-title">
  <div class="newsletter">
    <div class="newsletter-visual">
      $Image
    </div>
    <div class="newsletter-content">
      <p class="page-kicker">$(Html $Kicker)</p>
      <h2 id="newsletter-title">$(Html $Title)</h2>
      <p>$(Html $Description)</p>
      <form class="nl-form" data-newsletter-form>
        <input class="nl-input" type="email" name="email" placeholder="your@email.com" aria-label="Email address" required>
        <button class="nl-btn" type="submit">$(Html $Button)</button>
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
  $PlanningCards = if (Is-Japanese) {
    @(
      New-UtilityCard "旅程" "日数から旅を選ぶ" "3日、7日、10日、14日の静的ルートをTABI内の記事グラフから組み立てます。" "/itineraries/index.html"
      New-UtilityCard "地域" "場所から探す" "東京、京都、大阪、屋久島、瀬戸内をタグとカテゴリの適合度から整理します。" "/areas/index.html"
      New-UtilityCard "チェックリスト" "出発前に整える" "お金、移動、通信、荷物、初日のつまずきを減らす実用チェックリストです。" "/planning/japan-travel-checklist.html"
      New-UtilityCard "用語集" "旅の言葉を知る" "食、宿、買い物、交通に出てくる言葉を短く説明します。" "/glossary.html"
    )
  } else {
    @(
      New-UtilityCard "Itineraries" "Choose a Trip Length" "Static 3, 7, 10, and 14 day routes assembled from TABI's local article graph." "/itineraries/index.html"
      New-UtilityCard "Areas" "Browse by Place" "Tokyo, Kyoto, Osaka, Yakushima, and Setouchi hubs built from tags and category fit." "/areas/index.html"
      New-UtilityCard "Checklist" "Before You Fly" "A practical pre-trip checklist for money, transit, connectivity, luggage, and first-day friction." "/planning/japan-travel-checklist.html"
      New-UtilityCard "Glossary" "Decode Japan Travel Terms" "Plain-English explanations for terms that appear across food, stays, shopping, and transport." "/glossary.html"
    )
  }
  $TopicCards = foreach ($Topic in $TopicClusters) {
    $TopicDisplay = Get-TopicDisplay $Topic
    $Count = @(Select-TopicArticles $Topic 50).Count
    $TopicLabel = if (Is-Japanese) { "テーマ" } else { "Topic Cluster" }
    $CountLabel = if (Is-Japanese) { "$Count 本のガイド" } else { "$Count guides" }
    @"
<a class="topic-card" href="$(Get-TopicUrl $Topic.slug)">
  <span>$(Html $TopicLabel)</span>
  <strong>$(Html $TopicDisplay.title)</strong>
  <p>$(Html $TopicDisplay.description)</p>
  <small>$(Html $CountLabel)</small>
</a>
"@
  }
  $HeroRead = Format-ReadingTime $Hero.readingTime

  $EditorialCards = for ($i = 0; $i -lt $Editorial.Count; $i++) {
    New-ArticleCard $Editorial[$i] ($i -eq 0)
  }
  $CultureCards = foreach ($Article in $Culture) { New-CultureCard $Article }
  $BuyCards = foreach ($Article in $Buy) { New-BuyCard $Article }
  $Newsletter = New-Newsletter
  $SiteTitle = if (Is-Japanese) { "$($Config.siteName) - 日本を深く見る" } else { "$($Config.siteName) - $($Config.tagline)" }
  $SiteDescription = if (Is-Japanese) { "日本の旅、文化、食、知られざる場所、持ち帰る価値のあるものを静かに案内するTABIの日本語版です。" } else { $Config.description }

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
      <a class="hero-btn" href="$(Get-ArticleUrl $Hero)">$(if (Is-Japanese) { "ガイドを読む" } else { "Read the Guide" })</a>
      <a class="hero-link" href="$(Get-CategoryUrl "travel-guide")">$(if (Is-Japanese) { "すべてのガイドを見る" } else { "Browse all guides" })</a>
    </div>
  </div>
</section>
<section aria-labelledby="travel-heading">
  <div class="section-label">
    <span class="section-label-jp">&#26053;</span>
    <h2 class="section-label-en" id="travel-heading">$(if (Is-Japanese) { "編集部のおすすめ" } else { "Editor's Picks" })</h2>
    <div class="section-label-line"></div>
    <a class="section-label-link" href="$(Get-CategoryUrl "travel-guide")">$(if (Is-Japanese) { "すべての記事" } else { "All articles" })</a>
  </div>
  $(New-AlgorithmNote $(if (Is-Japanese) { "TABI内の記事スコア、鮮度、季節性、品質、編集上の重み、カテゴリの多様性で並べています。" } else { "Ranked by TABI's local article score: freshness, seasonality, quality, editorial weight, and category diversity." }))
  <div class="editorial-grid">
    $($EditorialCards -join "`n")
  </div>
</section>
<section aria-labelledby="topics-heading">
  <div class="section-label">
    <span class="section-label-jp">&#36947;</span>
    <h2 class="section-label-en" id="topics-heading">$(if (Is-Japanese) { "テーマ別に探す" } else { "Topic Paths" })</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="topic-grid">
    $($TopicCards -join "`n")
  </div>
</section>
<section aria-labelledby="planning-heading">
  <div class="section-label">
    <span class="section-label-jp">&#35336;</span>
    <h2 class="section-label-en" id="planning-heading">$(if (Is-Japanese) { "旅の準備" } else { "Plan Your Trip" })</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="utility-grid">
    $($PlanningCards -join "`n")
  </div>
</section>
<section aria-labelledby="culture-heading">
  <div class="section-label">
    <span class="section-label-jp">&#25991;&#21270;</span>
    <h2 class="section-label-en" id="culture-heading">$(if (Is-Japanese) { "文化と伝統" } else { "Culture &amp; Tradition" })</h2>
    <div class="section-label-line"></div>
    <a class="section-label-link" href="$(Get-CategoryUrl "culture")">$(if (Is-Japanese) { "文化の記事" } else { "All culture" })</a>
  </div>
  <div class="culture-grid">
    $($CultureCards -join "`n")
  </div>
</section>
<section class="interlude" aria-label="The TABI philosophy">
  <div class="interlude-kanji">&#26053;&#25991;&#21270;</div>
  <div class="interlude-inner">
    <p class="interlude-label">$(if (Is-Japanese) { "TABIの視点" } else { "The TABI Philosophy" })</p>
    <p class="interlude-quote">$(if (Is-Japanese) { "日本は目的地である前に、<br><strong>ものの見方でもあります。</strong>" } else { "Japan is not a destination.<br><strong>It is a way of seeing.</strong>" })</p>
    <p class="interlude-sub">$(if (Is-Japanese) { "古い森の道から深夜のカウンターまで、知る価値のある日本を静かに集めます。" } else { "From ancient forest temples to 4am ramen counters, we find the Japan worth knowing." })</p>
  </div>
</section>
<section aria-labelledby="buy-heading">
  <div class="section-label">
    <span class="section-label-jp">&#36023;&#29289;</span>
    <h2 class="section-label-en" id="buy-heading">$(if (Is-Japanese) { "持ち帰りたいもの" } else { "Things to Buy" })</h2>
    <div class="section-label-line"></div>
    <a class="section-label-link" href="$(Get-CategoryUrl "things-to-buy")">$(if (Is-Japanese) { "買い物ガイド" } else { "All guides" })</a>
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
    description = $SiteDescription
    inLanguage = $Script:CurrentLang
  } | ConvertTo-Json -Depth 5 -Compress

  return New-Layout $SiteTitle $SiteDescription "/" $Main "" $Hero.image $JsonLd
}

function New-ArticlePage($Article) {
  $Read = Format-ReadingTime $Article.readingTime
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
    $TopicDisplay = Get-TopicDisplay $Topic
    $TopicHtml = '<a class="tag-pill topic-pill" href="{0}">{1}</a>' -f (Get-TopicUrl $Topic.slug), (Html $TopicDisplay.title)
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
    <p class="footer-col-title">$(Html (T "filedUnder"))</p>
    <a class="tag-pill" href="$(Get-CategoryUrl $Article.category)">$(Html (Get-CategoryLabel $Article.category))</a>
    $TopicHtml
    <div class="tag-list">
      $(New-LinkedTagList $Article.tags)
    </div>
    <p class="footer-col-title sidebar-section-title">$(Html (T "related"))</p>
    <p class="sidebar-note">$(if (Is-Japanese) { "共有タグ、カテゴリ適合、鮮度、季節性、品質スコアから選んでいます。" } else { "Chosen by shared tags, category fit, freshness, seasonality, and quality score." })</p>
    <ul class="footer-links">
      $($RelatedHtml -join "`n")
    </ul>
    $(New-ArticleSourcePanel $Article)
  </aside>
</article>
<section aria-labelledby="next-heading" class="next-read">
  <div class="section-label">
    <span class="section-label-jp">&#27425;</span>
    <h2 class="section-label-en" id="next-heading">$(Html (T "readNext"))</h2>
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
    inLanguage = $Script:CurrentLang
    author = @{ "@type" = "Organization"; name = $Config.siteName }
    publisher = @{ "@type" = "Organization"; name = $Config.siteName }
    mainEntityOfPage = SiteUrl (Get-ArticleUrl $Article)
  }
  $BreadcrumbJsonLd = @{
    "@type" = "BreadcrumbList"
    itemListElement = @(
      @{ "@type" = "ListItem"; position = 1; name = T "home"; item = SiteUrl (Href "/") },
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
  $CategoryLabel = Get-CategoryLabel $Category.slug
  $Description = if (Is-Japanese) { "日本の$(Html $CategoryLabel)に関するTABIのガイドをまとめています。" } else { "Curated TABI guides for $($Category.label.ToLowerInvariant()) in Japan." }
  $Kicker = if (Is-Japanese) { "カテゴリ" } else { "Category" }
  $Algorithm = if (Is-Japanese) { "カテゴリ適合、鮮度、季節性、編集上の重み、記事品質で並べています。" } else { "Sorted by category relevance, freshness, seasonality, editorial weight, and article quality." }
  $Items = Select-ScoredArticles @($Articles | Where-Object { $_.category -eq $Category.slug }) 100 $Category.slug
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = $CategoryLabel; url = "" }
  )
  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">$(Html $Kicker)</p>
  <h1 class="page-title">$(Html $CategoryLabel)</h1>
  <p class="page-desc">$Description</p>
</section>
$(New-AlgorithmNote $Algorithm)
<section class="listing-grid" aria-label="$(Html $CategoryLabel) articles">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = $CategoryLabel
    description = $Description
    url = SiteUrl (Get-CategoryUrl $Category.slug)
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$CategoryLabel - TABI" $Description (Get-CategoryUrl $Category.slug) $Main $Category.slug "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-TagPage([string]$Tag) {
  $Kicker = if (Is-Japanese) { "タグ" } else { "Tag" }
  $Description = if (Is-Japanese) { "#$Tag に関連するTABI内の記事をまとめています。" } else { "Articles connected to $Tag, gathered from across TABI." }
  $Algorithm = if (Is-Japanese) { "記事スコアが高く、鮮度と季節性のあるガイドから表示しています。" } else { "Sorted by article score so stronger, fresher, and more seasonally useful guides appear first." }
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
  <p class="page-kicker">$(Html $Kicker)</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Description)</p>
</section>
$(New-AlgorithmNote $Algorithm)
<section class="listing-grid" aria-label="$(Html $Tag) articles">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = $Title
    description = $Description
    url = SiteUrl (Get-TagUrl $Tag)
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$Title - TABI" $Description (Get-TagUrl $Tag) $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-TopicPage($Topic) {
  $TopicDisplay = Get-TopicDisplay $Topic
  $Kicker = if (Is-Japanese) { "テーマ" } else { "Topic Path" }
  $TopicsLabel = if (Is-Japanese) { "テーマ" } else { "Topics" }
  $Algorithm = if (Is-Japanese) { "タグの重なり、カテゴリ適合、記事スコアから作る静的な内部リンクハブです。" } else { "This topic path is generated from tag overlap, category fit, and article score. It acts as a static internal-link hub." }
  $Items = Select-TopicArticles $Topic 100
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = $TopicsLabel; url = "" },
    [pscustomobject]@{ label = $TopicDisplay.title; url = "" }
  )
  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">$(Html $Kicker)</p>
  <h1 class="page-title">$(Html $TopicDisplay.title)</h1>
  <p class="page-desc">$(Html $TopicDisplay.description)</p>
</section>
$(New-AlgorithmNote $Algorithm)
<section class="listing-grid" aria-label="$(Html $TopicDisplay.title) articles">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = $TopicDisplay.title
    description = $TopicDisplay.description
    url = SiteUrl (Get-TopicUrl $Topic.slug)
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$($TopicDisplay.title) - TABI" $TopicDisplay.description (Get-TopicUrl $Topic.slug) $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-AreaIndexPage {
  $Cards = foreach ($Area in $AreaClusters) {
    $AreaDisplay = Get-AreaDisplay $Area
    New-UtilityCard $(if (Is-Japanese) { "地域ガイド" } else { "Area Guide" }) $AreaDisplay.title $AreaDisplay.description (Get-AreaUrl $Area.slug)
  }
  $Title = if (Is-Japanese) { "場所から旅を組み立てる。" } else { "Plan by place, not only by category." }
  $Description = if (Is-Japanese) { "TABIのタグ、カテゴリ、記事スコアから作る静的な地域ハブです。地図連携なしで運用できます。" } else { "Static regional hubs generated from TABI tags, categories, and article scores. No map integration required." }
  $Algorithm = if (Is-Japanese) { "地域ページは、ローカルのタグ重なり、カテゴリ適合、記事スコアから組み立てます。" } else { "Area pages are assembled from local tag overlap, category fit, and article score." }
  $PageName = if (Is-Japanese) { "地域ガイド" } else { "Area Guides" }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = $PageName; url = "" }))
  <p class="page-kicker">$(Html $PageName)</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Description)</p>
</section>
$(New-AlgorithmNote $Algorithm)
<section class="utility-grid" aria-label="Area guide links">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = "TABI $PageName"
    description = $Description
    url = SiteUrl "/areas/index.html"
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$PageName - TABI" $Description "/areas/index.html" $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-AreaPage($Area) {
  $AreaDisplay = Get-AreaDisplay $Area
  $Items = Select-ClusterArticles $AreaDisplay 100
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $NeighborhoodCards = foreach ($Place in $AreaDisplay.neighborhoods) {
    $PlaceLabel = if (Is-Japanese) { "場所の手がかり" } else { "Place Cue" }
    @"
<div class="detail-card">
  <span>$(Html $PlaceLabel)</span>
  <strong>$(Html $Place.name)</strong>
  <p>$(Html $Place.note)</p>
</div>
"@
  }
  $AreasLabel = if (Is-Japanese) { "地域" } else { "Areas" }
  $Kicker = if (Is-Japanese) { "地域ガイド" } else { "Area Guide" }
  $CueKicker = if (Is-Japanese) { "現地計画の手がかり" } else { "Local Planning Cues" }
  $CueTitle = if (Is-Japanese) { "この地域をどう捉えるか" } else { "Where this area starts to make sense" }
  $CueDescription = if (Is-Japanese) { "これはライブの店舗リストではなく、1日の形を決めるための編集上の手がかりです。現在情報は出発前に確認してください。" } else { "These are editorial planning cues, not live listings. Use them to choose the shape of a day before confirming current details." }
  $Algorithm = if (Is-Japanese) { "下のガイドは、この地域のタグ、カテゴリ、鮮度、季節性、品質スコアとの重なりで並べています。" } else { "Guides below are ranked by overlap with this area's tags, matching categories, freshness, seasonality, and quality score." }
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = $AreasLabel; url = "/areas/index.html" },
    [pscustomobject]@{ label = $AreaDisplay.title; url = "" }
  )
  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">$(Html $Kicker)</p>
  <h1 class="page-title">$(Html $AreaDisplay.title)</h1>
  <p class="page-desc">$(Html $AreaDisplay.description)</p>
</section>
<section class="split-feature" aria-labelledby="area-cues">
  <div>
    <p class="page-kicker">$(Html $CueKicker)</p>
    <h2 id="area-cues">$(Html $CueTitle)</h2>
    <p>$(Html $CueDescription)</p>
  </div>
  <div class="detail-grid">
    $($NeighborhoodCards -join "`n")
  </div>
</section>
$(New-AlgorithmNote $Algorithm)
<section class="listing-grid" aria-label="$(Html $AreaDisplay.title) guides">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = "$($AreaDisplay.title) Travel Guide"
    description = $AreaDisplay.description
    url = SiteUrl (Get-AreaUrl $Area.slug)
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$($AreaDisplay.title) - TABI" $AreaDisplay.description (Get-AreaUrl $Area.slug) $Main "" $Area.image $JsonLd
}

function New-ItineraryHubPage {
  $Cards = foreach ($Plan in $ItineraryPlans) {
    $PlanDisplay = Get-ItineraryDisplay $Plan
    New-UtilityCard $PlanDisplay.duration $PlanDisplay.title $PlanDisplay.description (Get-ItineraryUrl $Plan.slug)
  }
  $PageName = if (Is-Japanese) { "旅程" } else { "Itineraries" }
  $Kicker = if (Is-Japanese) { "静的旅程" } else { "Static Itineraries" }
  $Title = if (Is-Japanese) { "日数から日本のルートを選ぶ。" } else { "Choose a Japan route by trip length." }
  $Description = if (Is-Japanese) { "予約データではなく、TABI内の記事グラフ、日数、旅の速度、関心、記事品質から組み立てたルートです。" } else { "These routes are generated from TABI's local article graph, using duration, pace, interests, and article quality rather than live booking data." }
  $Algorithm = if (Is-Japanese) { "各旅程ページでは、タグとカテゴリの重なりから関連ガイドを選び、TABIの記事スコアで並べています。" } else { "Each itinerary page pulls supporting guides by tag and category overlap, then sorts by local article score." }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = $PageName; url = "" }))
  <p class="page-kicker">$(Html $Kicker)</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Description)</p>
</section>
$(New-AlgorithmNote $Algorithm)
<section class="utility-grid" aria-label="Itinerary links">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = "Japan $PageName"
    description = $Description
    url = SiteUrl "/itineraries/index.html"
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$PageName - TABI" $Description "/itineraries/index.html" $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-ItineraryPage($Plan) {
  $PlanDisplay = Get-ItineraryDisplay $Plan
  $Items = Select-ClusterArticles $PlanDisplay 8
  $Cards = foreach ($Article in $Items) { New-CompactArticleCard $Article }
  $StepCards = foreach ($Step in $PlanDisplay.steps) {
    @"
<div class="route-step">
  <span>$(Html $Step.label)</span>
  <strong>$(Html $Step.title)</strong>
  <p>$(Html $Step.body)</p>
</div>
"@
  }
  $ItinerariesLabel = if (Is-Japanese) { "旅程" } else { "Itineraries" }
  $RouteHeading = if (Is-Japanese) { "ルートの形" } else { "Route Shape" }
  $SupportingHeading = if (Is-Japanese) { "関連ガイド" } else { "Supporting Guides" }
  $Algorithm = if (Is-Japanese) { "この旅程の関心、カテゴリ、TABIの記事スコアから選んでいます。" } else { "Selected by this itinerary's interests, categories, and TABI article score." }
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = $ItinerariesLabel; url = "/itineraries/index.html" },
    [pscustomobject]@{ label = $PlanDisplay.title; url = "" }
  )
  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">$(Html $PlanDisplay.duration) / $(Html $PlanDisplay.pace)</p>
  <h1 class="page-title">$(Html $PlanDisplay.title)</h1>
  <p class="page-desc">$(Html $PlanDisplay.description)</p>
</section>
<section class="route-panel" aria-labelledby="route-heading">
  <div class="section-label compact-label">
    <span class="section-label-jp">&#36947;</span>
    <h2 class="section-label-en" id="route-heading">$(Html $RouteHeading)</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="route-grid">
    $($StepCards -join "`n")
  </div>
</section>
<section aria-labelledby="supporting-guides" class="next-read">
  <div class="section-label">
    <span class="section-label-jp">&#26412;</span>
    <h2 class="section-label-en" id="supporting-guides">$(Html $SupportingHeading)</h2>
    <div class="section-label-line"></div>
  </div>
  $(New-AlgorithmNote $Algorithm)
  <div class="compact-grid">
    $($Cards -join "`n")
  </div>
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "TouristTrip"
    name = $PlanDisplay.title
    description = $PlanDisplay.description
    url = SiteUrl (Get-ItineraryUrl $Plan.slug)
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$($PlanDisplay.title) - TABI" $PlanDisplay.description (Get-ItineraryUrl $Plan.slug) $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-PlanningIndexPage {
  $Cards = foreach ($Guide in $PlanningGuides) {
    $GuideDisplay = Get-PlanningDisplay $Guide
    New-UtilityCard $GuideDisplay.kicker $GuideDisplay.title $GuideDisplay.description (Get-PlanningUrl $Guide.slug)
  }
  $Cards += New-UtilityCard $(if (Is-Japanese) { "用語集" } else { "Glossary" }) $(if (Is-Japanese) { "日本旅行の用語" } else { "Japan Travel Terms" }) $(if (Is-Japanese) { "食、宿、買い物、交通に出てくる言葉を短く説明します。" } else { "Plain-English explanations for recurring food, stay, shopping, and transport terms." }) "/glossary.html"
  $Cards += New-UtilityCard $(if (Is-Japanese) { "旅程" } else { "Itineraries" }) $(if (Is-Japanese) { "日数別ルート" } else { "Trip Length Routes" }) $(if (Is-Japanese) { "予約前に、日本旅行の大きな形を静的ルートで決められます。" } else { "Use static route pages to choose the shape of a Japan trip before booking details." }) "/itineraries/index.html"
  $PageName = if (Is-Japanese) { "旅の準備" } else { "Planning Tools" }
  $Title = if (Is-Japanese) { "外部連携に頼らない、日本旅行の準備。" } else { "Practical Japan planning without live integrations." }
  $Description = if (Is-Japanese) { "TABIのコードベース内で管理できる、チェックリスト、基本情報、用語集、ルートページです。" } else { "Evergreen checklists, trip basics, terminology, and route pages that can be maintained locally in the TABI codebase." }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = $PageName; url = "" }))
  <p class="page-kicker">$(Html $PageName)</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Description)</p>
</section>
<section class="utility-grid" aria-label="Planning tools">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "CollectionPage"
    name = "TABI $PageName"
    description = $Description
    url = SiteUrl "/planning/index.html"
  } | ConvertTo-Json -Depth 5 -Compress
  return New-Layout "$PageName - TABI" $Description "/planning/index.html" $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function New-PlanningGuidePage($Guide) {
  $GuideDisplay = Get-PlanningDisplay $Guide
  $Blocks = foreach ($Block in $GuideDisplay.blocks) {
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
      $ItemDisplay = Get-PlanningDisplay $Item
      New-UtilityCard $ItemDisplay.kicker $ItemDisplay.title $ItemDisplay.description (Get-PlanningUrl $Item.slug)
    }
  }
  $SiblingCards += New-UtilityCard $(if (Is-Japanese) { "用語集" } else { "Glossary" }) $(if (Is-Japanese) { "旅の言葉" } else { "Travel Terms" }) $(if (Is-Japanese) { "日本旅行でよく出てくる言葉を短く説明します。" } else { "Quick explanations for common Japan travel words." }) "/glossary.html"
  $PlanningLabel = if (Is-Japanese) { "旅の準備" } else { "Planning" }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = $PlanningLabel; url = "/planning/index.html" }, [pscustomobject]@{ label = $GuideDisplay.title; url = "" }))
  <p class="page-kicker">$(Html $GuideDisplay.kicker)</p>
  <h1 class="page-title">$(Html $GuideDisplay.title)</h1>
  <p class="page-desc">$(Html $GuideDisplay.description)</p>
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
    name = $GuideDisplay.title
    description = $GuideDisplay.description
    url = SiteUrl (Get-PlanningUrl $Guide.slug)
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$($GuideDisplay.title) - TABI" $GuideDisplay.description (Get-PlanningUrl $Guide.slug) $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function New-GlossaryPage {
  $DisplayTerms = @($GlossaryTerms | ForEach-Object { Get-GlossaryDisplay $_ } | Sort-Object term)
  $Terms = for ($i = 0; $i -lt $DisplayTerms.Count; $i++) {
    $Term = $DisplayTerms[$i]
    @"
<article class="glossary-card" id="$(Get-SectionId $Term.term ($i + 1))">
  <span>$(Html $Term.category)</span>
  <h2>$(Html $Term.term)</h2>
  <p>$(Html $Term.definition)</p>
</article>
"@
  }
  $PageName = if (Is-Japanese) { "用語集" } else { "Glossary" }
  $Title = if (Is-Japanese) { "日本旅行の言葉を、短くわかりやすく。" } else { "Japan travel terms, decoded." }
  $Description = if (Is-Japanese) { "TABIの食、宿、買い物、交通ガイドに出てくる言葉を確認できる静的リファレンスです。" } else { "A static reference for recurring words across TABI's food, stay, shopping, and transport guides." }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = $PageName; url = "" }))
  <p class="page-kicker">$(Html $PageName)</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Description)</p>
</section>
<section class="glossary-grid" aria-label="Japan travel glossary">
  $($Terms -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "DefinedTermSet"
    name = "TABI $PageName"
    description = $Description
    url = SiteUrl "/glossary.html"
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$PageName - TABI" $Description "/glossary.html" $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function New-SourcePolicyPage {
  $AllowedItems = @($ContentPolicy.allowedSourceTypes)
  $DisallowedItems = @($ContentPolicy.disallowedSourceTypes)
  $RuleItems = @($ContentPolicy.reuseRules)
  if (Is-Japanese) {
    $AllowedItems = @(
      "通常の参照が許される公式観光、交通、施設、行政、観光組織のページ。",
      "紹介対象である場所、組織、作り手、運営者が公開する一次情報。",
      "条件を守れるオープンライセンスまたはパブリックドメインの資料。",
      "TABI自身の編集メモ、独自分析、ローカルに管理する構造化データ。"
    )
    $DisallowedItems = @(
      "AIスクレイピング、 automated collection、引用、転載、再利用を禁止しているページや媒体。",
      "有料、会員限定、非公開、流出、アクセス制限のある資料。",
      "無断転載、スクレイピングミラー、盗用サイト、低品質アフィリエイト量産サイト、権利不明のコンテンツ。",
      "明示的な許可や文脈がない個人SNS、個人証言、コミュニティ投稿。",
      "嫌がらせ、プライバシー侵害、差別、扇情、搾取など倫理的なリスクがある情報源。"
    )
    $RuleItems = @(
      "第三者媒体の表現、ランキング、表、独自の編集構成をコピーしない。",
      "事実確認が必要な場合は公式情報と一次情報を優先し、TABI独自の文章で要約する。",
      "利用条件が曖昧な情報源は使わない。",
      "営業時間、価格、閉店、交通ルールなど変わりやすい情報は、現在情報として断定しない。"
    )
  }
  $Allowed = foreach ($Item in $AllowedItems) {
    '<li>{0}</li>' -f (Html $Item)
  }
  $Disallowed = foreach ($Item in $DisallowedItems) {
    '<li>{0}</li>' -f (Html $Item)
  }
  $Rules = foreach ($Item in $RuleItems) {
    '<li>{0}</li>' -f (Html $Item)
  }
  $Title = if (Is-Japanese) { "TABIの情報出所ポリシー" } else { "TABI Source Policy" }
  $Desc = if (Is-Japanese) { "TABIが使う情報源、使わない情報源、引用や再利用に関する編集ルールです。" } else { "How TABI chooses sources, avoids prohibited collection, and handles attribution, quotation, and volatile travel details." }
  $Intro = if (Is-Japanese) {
    "TABIは、AIスクレイピング禁止、引用禁止、転載禁止、権利不明、倫理的に問題のある媒体から情報を収集しません。外部情報を使う場合も、公式情報や一次情報を優先し、本文はTABIの編集判断で書きます。"
  } else {
    "TABI does not collect from media that prohibit AI scraping, quotation, republication, or reuse, and does not rely on sources with unclear rights or ethical risk. When outside information is needed, official and primary sources are preferred and TABI writes original editorial summaries."
  }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = $Title; url = "" }))
  <p class="page-kicker">$(Html (T "sourcePolicy"))</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Desc)</p>
</section>
<article class="guide-body source-policy-body">
  <section class="checklist-block">
    <h2>$(if (Is-Japanese) { "編集方針" } else { "Editorial stance" })</h2>
    <p>$(Html $Intro)</p>
  </section>
  <section class="checklist-block">
    <h2>$(if (Is-Japanese) { "利用できる情報源" } else { "Allowed source types" })</h2>
    <ul>$($Allowed -join "`n")</ul>
  </section>
  <section class="checklist-block warning-block">
    <h2>$(if (Is-Japanese) { "利用しない情報源" } else { "Disallowed source types" })</h2>
    <ul>$($Disallowed -join "`n")</ul>
  </section>
  <section class="checklist-block">
    <h2>$(if (Is-Japanese) { "引用と再利用のルール" } else { "Reuse rules" })</h2>
    <ul>$($Rules -join "`n")</ul>
  </section>
</article>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "WebPage"
    name = $Title
    description = $Desc
    url = SiteUrl (Href "/source-policy.html")
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$Title - TABI" $Desc (Href "/source-policy.html") $Main "" "/assets/images/japanese-goods.png" $JsonLd
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
  <language>$Script:CurrentLang</language>
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
    feed_url = SiteUrl (Href "/feed.json")
    description = $Config.description
    language = $Script:CurrentLang
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
    <a class="button" href="$(Href "/")">$(if (Is-Japanese) { "ホームへ戻る" } else { "Back to Home" })</a>
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
  $OriginalLang = $Script:CurrentLang
  $Urls = @()
  foreach ($Lang in @("en", "ja")) {
    Set-RenderLanguage $Lang
    $Urls += [pscustomobject]@{ loc = Href "/"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += foreach ($Category in $Config.categories) { [pscustomobject]@{ loc = Get-CategoryUrl $Category.slug; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += foreach ($Topic in $TopicClusters) { [pscustomobject]@{ loc = Get-TopicUrl $Topic.slug; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += [pscustomobject]@{ loc = Href "/areas/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += foreach ($Area in $AreaClusters) { [pscustomobject]@{ loc = Get-AreaUrl $Area.slug; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += [pscustomobject]@{ loc = Href "/itineraries/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += foreach ($Plan in $ItineraryPlans) { [pscustomobject]@{ loc = Get-ItineraryUrl $Plan.slug; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += [pscustomobject]@{ loc = Href "/planning/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += foreach ($Guide in $PlanningGuides) { [pscustomobject]@{ loc = Get-PlanningUrl $Guide.slug; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += [pscustomobject]@{ loc = Href "/glossary.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += [pscustomobject]@{ loc = Href "/source-policy.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Tags = @($Articles | ForEach-Object { $_.tags } | Sort-Object -Unique)
    $Urls += foreach ($Tag in $Tags) { [pscustomobject]@{ loc = Get-TagUrl $Tag; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += foreach ($Article in $Articles) { [pscustomobject]@{ loc = Get-ArticleUrl $Article; lastmod = $Article.publishedAt } }
  }
  Set-RenderLanguage $OriginalLang
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

function Get-OutputPath([string]$RelativePath) {
  if ($Script:CurrentLang -eq "ja") { return "ja/$RelativePath" }
  return $RelativePath
}

function Write-LanguagePages([string]$Lang) {
  Set-RenderLanguage $Lang
  Write-Page (Get-OutputPath "index.html") (New-HomePage)
  foreach ($Article in $Articles) {
    Write-Page (Get-OutputPath "articles/$($Article.id).html") (New-ArticlePage $Article)
  }
  foreach ($Category in $Config.categories) {
    Write-Page (Get-OutputPath "categories/$($Category.slug).html") (New-CategoryPage $Category)
  }
  foreach ($Topic in $TopicClusters) {
    Write-Page (Get-OutputPath "topics/$($Topic.slug).html") (New-TopicPage $Topic)
  }
  Write-Page (Get-OutputPath "areas/index.html") (New-AreaIndexPage)
  foreach ($Area in $AreaClusters) {
    Write-Page (Get-OutputPath "areas/$($Area.slug).html") (New-AreaPage $Area)
  }
  Write-Page (Get-OutputPath "itineraries/index.html") (New-ItineraryHubPage)
  foreach ($Plan in $ItineraryPlans) {
    Write-Page (Get-OutputPath "itineraries/$($Plan.slug).html") (New-ItineraryPage $Plan)
  }
  Write-Page (Get-OutputPath "planning/index.html") (New-PlanningIndexPage)
  foreach ($Guide in $PlanningGuides) {
    Write-Page (Get-OutputPath "planning/$($Guide.slug).html") (New-PlanningGuidePage $Guide)
  }
  Write-Page (Get-OutputPath "glossary.html") (New-GlossaryPage)
  Write-Page (Get-OutputPath "source-policy.html") (New-SourcePolicyPage)
  $AllTags = @($Articles | ForEach-Object { $_.tags } | Sort-Object -Unique)
  foreach ($Tag in $AllTags) {
    Write-Page (Get-OutputPath "tags/$Tag.html") (New-TagPage $Tag)
  }
  Write-Page (Get-OutputPath "404.html") (New-NotFoundPage)
  Write-Page (Get-OutputPath "feed.xml") (New-RssFeed)
  Write-Page (Get-OutputPath "feed.json") (New-JsonFeed)
}

Write-LanguagePages "en"
Write-LanguagePages "ja"
Set-RenderLanguage "en"
Write-Page "sitemap.xml" (New-Sitemap)
Write-Page "robots.txt" "User-agent: *`nAllow: /`nSitemap: $(SiteUrl '/sitemap.xml')`n"
Write-Page "site.webmanifest" (New-WebManifest)
Write-Page "llms.txt" (New-LlmsText)

Write-Host "Generated localized TABI site in English and Japanese: $($BaseArticles.Count) articles, $($Config.categories.Count) categories, $($TopicClusters.Count) topics, $($AreaClusters.Count) areas, and $($ItineraryPlans.Count) itineraries per language."
