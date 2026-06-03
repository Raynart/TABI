$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Config = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "site.config.json") | ConvertFrom-Json

function Read-JsonArray([string]$FilePath) {
  $Data = Get-Content -Raw -Encoding UTF8 $FilePath | ConvertFrom-Json
  return @($Data)
}

function Read-SplitJsonArray([string]$FolderPath, [string]$FallbackFilePath) {
  if (Test-Path $FolderPath) {
    $Files = @(Get-ChildItem -Path $FolderPath -Filter "*.json" | Sort-Object Name)
    if ($Files.Count -gt 0) {
      $Items = @()
      foreach ($File in $Files) {
        $Items += Read-JsonArray $File.FullName
      }
      return @($Items)
    }
  }
  return Read-JsonArray $FallbackFilePath
}

$BaseArticles = Read-SplitJsonArray (Join-Path $Root "content/articles") (Join-Path $Root "articles.json")
$JapaneseArticleOverrides = Read-SplitJsonArray (Join-Path $Root "content/articles.ja") (Join-Path $Root "articles.ja.json")
$JapaneseStatic = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "static.ja.json") | ConvertFrom-Json
$ContentPolicy = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "content-policy.json") | ConvertFrom-Json
$Articles = $BaseArticles
$EnglishCulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
$JapaneseCulture = [System.Globalization.CultureInfo]::GetCultureInfo("ja-JP")
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Today = Get-Date
$Script:CurrentLang = "en"
$UiLabels = @{
  en = @{
    skip = "Skip to content"; topBar = "Japan Travel & Culture Guide"; topExtra = " / Updated weekly / Free newsletter every Friday"
    latest = "Latest"; search = "Search TABI"; closeSearch = "Close search"; searchPlaceholder = "Search Kyoto, food, craft, hidden gems..."
    newsletter = "Free Newsletter"; explore = "Explore"; disclosure = "Disclosure"; contact = "Contact"; sitemap = "Sitemap"
    sourcePolicy = "Source Policy"; sourcePolicyShort = "Source Policy"; language = "Language"; readNext = "Read Next"
    filedUnder = "Filed Under"; related = "Related"; inThisGuide = "In This Guide"; sourceInfo = "Source & Verification"
    articleScore = "Article score"; quality = "Quality"; freshness = "Freshness"; seasonalFit = "Seasonal fit"
    affiliate = "Affiliate links may earn us a commission."; copyright = "All rights reserved."; home = "Home"
    linkPath = "Continue Your Route"; whyRelated = "Why these links"; topicPath = "Topic path"; areaPath = "Area guide"; itineraryPath = "Itinerary"; glossaryPath = "Glossary"
    latestAria = "Latest articles"; mobileNavAria = "Primary mobile navigation"; siteLogoAria = "TABI home"
    articleSectionsAria = "Article sections"; articleDetailsAria = "Article details"; emailAria = "Email address"; newsletterLink = "Newsletter"
    buyerNotes = "Buyer's Notes"; buyCheckTitle = "What to check before you buy"; option = "Option"; bestFor = "Best for"; watchFor = "Watch for"
    affiliateDisclosure = "Affiliate disclosure: TABI may earn a commission from qualifying purchases, but the buying notes above are written as editorial guidance first."
    feedbackKicker = "Keep This Guide Useful"; feedbackTitle = "Was this guide helpful?"; feedbackBody = "Tell us what felt unclear, missing, or worth updating. This is a simple editorial inbox link, not a tracking widget."; feedbackButton = "Send Feedback"
    homeKicker = "Japan Travel Intelligence"; homeTitle = "Find the Japan worth slowing down for."; homeDescription = "TABI is a bilingual editorial guide to Japanese travel, food, culture, craft, hidden places, and things worth bringing home."; featuredGuide = "Featured Guide"
    readInOtherLanguage = "Read in Japanese"; audience = "Best for"; searchPopular = "Popular searches"; searchLanguage = "Language"; noMatchesHelp = "Try Kyoto, food, itinerary, matcha, ryokan, or quiet travel."
    categoryHub = "Guide hub"; tagHub = "Tag hub"; hubIntro = "Start with the strongest guides, then move by topic, place, or related tags."
    collections = "Collections"; quickRead = "Quick Read"; keyTakeaways = "3 takeaways"; beforeYouGo = "Before you go"; avoid = "Avoid"; season = "Season"; budget = "Budget"; timeNeeded = "Time needed"
    currentLanguage = "Current language"; alsoAvailable = "Also available"; languageNote = "This page has a Japanese edition with localized editorial wording."; languageSwitchAria = "Choose site language"; breadcrumbAria = "Breadcrumb"; english = "English"; japanese = "Japanese"
    quickRoutes = "Quick routes"; startHere = "Start here"; browseCollections = "Browse collections"; planTrip = "Plan a trip"; openSearch = "Open search"; recentTitle = "Recently viewed"; recentKicker = "Pick up where you left off"; previousGuide = "Previous guide"; nextGuide = "Next guide"; moreInCategory = "More in this category"
    trustKicker = "Trust & Updates"; sourceNote = "Source note"; corrections = "Corrections"; sendCorrection = "Send a correction"; trustSummary = "Trust summary"; editorialPrinciples = "Editorial principles"; correctionPolicy = "Correction policy"
    legal = "Legal"; privacy = "Privacy Policy"; disclaimer = "Disclaimer"; aiDisclosure = "AI Disclosure"; affiliateDisclosureShort = "Affiliate Disclosure"
  }
  ja = @{
    skip = "本文へ移動"; topBar = "日本の旅と文化のガイド"; topExtra = " / 毎週更新 / 金曜にニュースレター"
    latest = "新着"; search = "TABIを検索"; closeSearch = "検索を閉じる"; searchPlaceholder = "京都、食、工芸、穴場を検索..."
    newsletter = "無料ニュースレター"; explore = "探す"; disclosure = "開示"; contact = "お問い合わせ"; sitemap = "サイトマップ"
    sourcePolicy = "情報出所ポリシー"; sourcePolicyShort = "出所ポリシー"; language = "言語"; readNext = "次に読む"
    filedUnder = "分類"; related = "関連記事"; inThisGuide = "このガイドの内容"; sourceInfo = "出所と検証"
    articleScore = "記事スコア"; quality = "品質"; freshness = "鮮度"; seasonalFit = "季節適合"
    affiliate = "一部リンクから収益を得る場合があります。"; copyright = "All rights reserved."; home = "ホーム"
    linkPath = "次に進む"; whyRelated = "表示理由"; topicPath = "テーマ"; areaPath = "地域ガイド"; itineraryPath = "旅程"; glossaryPath = "用語集"
    latestAria = "新着記事"; mobileNavAria = "主要ナビゲーション"; siteLogoAria = "TABIホーム"
    articleSectionsAria = "記事の目次"; articleDetailsAria = "記事の詳細"; emailAria = "メールアドレス"; newsletterLink = "ニュースレター"
    buyerNotes = "買う前のメモ"; buyCheckTitle = "購入前に見るポイント"; option = "選択肢"; bestFor = "向いている人"; watchFor = "確認したい点"
    affiliateDisclosure = "開示: 一部の商品リンクから収益を得る場合がありますが、上記の購入メモは編集上の判断を優先して作成しています。"
    feedbackKicker = "このガイドを育てる"; feedbackTitle = "このガイドは役に立ちましたか"; feedbackBody = "分かりにくかった点、足りない情報、更新したほうがよい箇所があればお知らせください。トラッキング用の仕組みではなく、編集用のメール窓口です。"; feedbackButton = "フィードバックを送る"
    homeKicker = "日本を深く見る旅ガイド"; homeTitle = "知らなかった日本に、静かに出会う。"; homeDescription = "TABIは、有名な観光地だけでは見えにくい日本の旅、文化、食、工芸、地域の文脈を日英で案内する編集ガイドです。"; featuredGuide = "注目ガイド"
    readInOtherLanguage = "英語で読む"; audience = "向いている人"; searchPopular = "よく探されるテーマ"; searchLanguage = "言語"; noMatchesHelp = "京都、食、旅程、抹茶、旅館、静かな旅などで探してみてください。"
    categoryHub = "カテゴリハブ"; tagHub = "タグハブ"; hubIntro = "まず強いガイドを読み、テーマ、地域、関連タグへ進めるよう整理しています。"
    collections = "目的別ガイド"; quickRead = "早わかり"; keyTakeaways = "3行まとめ"; beforeYouGo = "読む前に知ること"; avoid = "避けたい失敗"; season = "季節"; budget = "予算"; timeNeeded = "所要時間"
    currentLanguage = "現在の言語"; alsoAvailable = "対応版"; languageNote = "このページは英語でも読めます。英語版では訪日旅行者向けの文脈に合わせています。"; languageSwitchAria = "サイト言語を選ぶ"; breadcrumbAria = "パンくずリスト"; english = "English"; japanese = "日本語"
    quickRoutes = "すぐ行ける導線"; startHere = "ここから読む"; browseCollections = "目的別に探す"; planTrip = "旅を組み立てる"; openSearch = "検索を開く"; recentTitle = "最近見たページ"; recentKicker = "前回の続きから"; previousGuide = "前のガイド"; nextGuide = "次のガイド"; moreInCategory = "同じカテゴリを読む"
    trustKicker = "信頼性と更新"; sourceNote = "出所メモ"; corrections = "訂正"; sendCorrection = "訂正を送る"; trustSummary = "信頼性の要約"; editorialPrinciples = "編集原則"; correctionPolicy = "訂正方針"
    legal = "法務・ポリシー"; privacy = "プライバシーポリシー"; disclaimer = "免責事項"; aiDisclosure = "AI利用開示"; affiliateDisclosureShort = "アフィリエイト開示"
  }
}
$CategoryLabelsJa = @{
  "travel-guide" = "旅行ガイド"
  "culture" = "文化と伝統"
  "food" = "食"
  "things-to-buy" = "買い物"
  "hidden-gems" = "知られざる場所"
  "nature-outdoors" = "自然とアウトドア"
  "stays" = "宿と滞在"
}
$TagLabelsEn = @{
  "aesthetics" = "Aesthetics"; "art" = "Art"; "breakfast" = "Breakfast"; "budget" = "Budget"; "ceramics" = "Ceramics"; "cherry-blossoms" = "Cherry Blossoms"; "craft" = "Craft"; "design" = "Design"; "drugstore" = "Drugstore"; "fashion" = "Fashion"; "first-time" = "First-Time Japan"; "food" = "Food"; "forest" = "Forest"; "hanami" = "Hanami"; "heritage" = "Heritage"; "hiking" = "Hiking"; "islands" = "Islands"; "itinerary" = "Itinerary"; "izakaya" = "Izakaya"; "kintsugi" = "Kintsugi"; "kiso-valley" = "Kiso Valley"; "kitchen-knives" = "Kitchen Knives"; "konbini" = "Konbini"; "kyoto" = "Kyoto"; "language" = "Language"; "local-customs" = "Local Customs"; "local-food" = "Local Food"; "matcha" = "Matcha"; "menus" = "Menus"; "mount-fuji" = "Mount Fuji"; "nakasendo" = "Nakasendo"; "nightlife" = "Nightlife"; "osaka" = "Osaka"; "philosophy" = "Philosophy"; "planning" = "Planning"; "quiet-travel" = "Quiet Travel"; "ryokan" = "Ryokan"; "setouchi" = "Setouchi"; "shopping" = "Shopping"; "shrines" = "Shrines"; "skincare" = "Skincare"; "slow-travel" = "Slow Travel"; "souvenirs" = "Souvenirs"; "spring" = "Spring"; "street-food" = "Street Food"; "summer" = "Summer"; "tea" = "Tea"; "tokyo" = "Tokyo"; "travel-tips" = "Travel Tips"; "wabi-sabi" = "Wabi-Sabi"; "walking" = "Walking"; "where-to-stay" = "Where to Stay"; "yakushima" = "Yakushima"; "yukata" = "Yukata"
}
$SiteData = Get-Content -Raw -Encoding UTF8 (Join-Path $Root "site-data.json") | ConvertFrom-Json
$TopicClusters = @($SiteData.topics)
$SubcategoryDefinitions = @($SiteData.subcategories)
$AreaClusters = @($SiteData.areas)
$ItineraryPlans = @($SiteData.itineraries)
$PlanningGuides = @($SiteData.planning)
$GlossaryTerms = @($SiteData.glossary)
$CollectionDefinitions = @(
  [pscustomobject]@{
    slug = "unknown-japan"; tags = @("hidden-gems", "quiet-travel", "slow-travel", "yakushima", "setouchi", "kiso-valley"); categories = @("hidden-gems", "culture")
    en = [pscustomobject]@{ title = "Unknown Japan"; description = "Quieter places, slower routes, and cultural context for travelers who want Japan beyond the obvious."; kicker = "Editorial Collection" }
    ja = [pscustomobject]@{ title = "日本人も知らない日本"; description = "有名さではなく、静けさ、地域の文脈、歩いた後に残る感覚から日本を探すためのガイドです。"; kicker = "目的別ガイド" }
  }
  [pscustomobject]@{
    slug = "rainy-day-japan"; tags = @("forest", "craft", "tea", "kintsugi", "wabi-sabi", "konbini", "ryokan"); categories = @("culture", "food", "things-to-buy")
    en = [pscustomobject]@{ title = "Rainy Day Japan"; description = "Guides that still work when weather changes the plan: craft, food, forests, tea, and slower indoor decisions."; kicker = "Weather-Smart Travel" }
    ja = [pscustomobject]@{ title = "雨の日の日本旅行"; description = "雨で予定が変わる日にも楽しみやすい、工芸、食、森、茶、宿、買い物のガイドです。"; kicker = "天気に強い旅" }
  }
  [pscustomobject]@{
    slug = "solo-slow-travel"; tags = @("slow-travel", "walking", "quiet-travel", "menus", "konbini", "tokyo", "kyoto"); categories = @("travel-guide", "food", "hidden-gems")
    en = [pscustomobject]@{ title = "Solo and Slow Travel"; description = "Food confidence, quiet routes, smaller days, and places that suit travelers moving at their own pace."; kicker = "Travel Style" }
    ja = [pscustomobject]@{ title = "ひとりでゆっくり旅する"; description = "食事、街歩き、静かな場所、予定を詰めすぎない日を、自分の速度で組み立てるためのガイドです。"; kicker = "旅のスタイル" }
  }
  [pscustomobject]@{
    slug = "food-led-japan"; tags = @("food", "local-food", "izakaya", "menus", "konbini", "osaka", "street-food"); categories = @("food", "travel-guide")
    en = [pscustomobject]@{ title = "Food-Led Japan"; description = "Plan days around counters, markets, convenience-store saves, ordering confidence, and the neighborhoods food reveals."; kicker = "Food Route" }
    ja = [pscustomobject]@{ title = "食から選ぶ日本"; description = "居酒屋、メニュー、コンビニ朝食、大阪の食べ歩きなど、食を軸に旅を組み立てるガイドです。"; kicker = "食の旅" }
  }
  [pscustomobject]@{
    slug = "bring-home-japan"; tags = @("shopping", "souvenirs", "kitchen-knives", "matcha", "drugstore", "yukata", "skincare"); categories = @("things-to-buy")
    en = [pscustomobject]@{ title = "Bring-Home Japan"; description = "Useful, packable, culturally grounded things to buy in Japan, with care, luggage, and tax-free context."; kicker = "Shopping Collection" }
    ja = [pscustomobject]@{ title = "持ち帰りたい日本"; description = "包丁、抹茶、浴衣、ドラッグストア商品など、帰国後も使いやすい買い物を選ぶためのガイドです。"; kicker = "買い物ガイド" }
  }
  [pscustomobject]@{
    slug = "first-trip-with-breathing-room"; tags = @("first-time", "itinerary", "tokyo", "kyoto", "osaka", "travel-tips", "language"); categories = @("travel-guide", "food")
    en = [pscustomobject]@{ title = "First Trip, With Breathing Room"; description = "A calmer first Japan path through routes, meals, language confidence, and days that do not collapse under logistics."; kicker = "First-Time Japan" }
    ja = [pscustomobject]@{ title = "余白のある、はじめての日本"; description = "東京、京都、大阪、食事、言葉、移動を、詰め込みすぎず組み立てるための初回向けガイドです。"; kicker = "はじめての日本" }
  }
)
function Html([object]$Value) {
  if ($null -eq $Value) { return "" }
  return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Is-Japanese {
  return $Script:CurrentLang -eq "ja"
}

function Lang-Code {
  if (Is-Japanese) { return "ja" }
  return "en"
}

function T([string]$Key) {
  $Labels = $UiLabels[(Lang-Code)]
  if ($Labels.ContainsKey($Key)) { return $Labels[$Key] }
  return $Key
}

function Get-LocalizedScalar([string]$Group, [string]$Key, [string]$Default) {
  if (-not (Is-Japanese)) { return $Default }
  $GroupProperty = $JapaneseStatic.PSObject.Properties[$Group]
  if ($null -eq $GroupProperty) { return $Default }
  $KeyProperty = $GroupProperty.Value.PSObject.Properties[$Key]
  if ($null -eq $KeyProperty) { return $Default }
  return [string]$KeyProperty.Value
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

function Get-SiteDescription {
  return Get-LocalizedScalar "site" "description" $Config.description
}

function Get-SiteTitle {
  $Default = "$($Config.siteName) - $($Config.tagline)"
  return Get-LocalizedScalar "site" "title" $Default
}

function Get-LogoSubtitle {
  return Get-LocalizedScalar "site" "logoSubtitle" "Discover Japan"
}

function Get-FooterTagline {
  return Get-LocalizedScalar "site" "footerTagline" $Config.description
}

function Get-HomeTitle {
  return Get-LocalizedScalar "site" "homeTitle" (T "homeTitle")
}

function Get-HomeDescription {
  return Get-LocalizedScalar "site" "homeDescription" (T "homeDescription")
}

function Get-ArticleSeoTitle($Article) {
  if ($Article.PSObject.Properties.Name -contains "seoTitle") { return $Article.seoTitle }
  return "$($Article.title) - TABI"
}

function Get-ArticleSeoDescription($Article) {
  if ($Article.PSObject.Properties.Name -contains "seoDescription") { return $Article.seoDescription }
  return $Article.summary
}

function Get-ArticleAudience($Article) {
  if ($Article.PSObject.Properties.Name -contains "audience") { return $Article.audience }
  if (Is-Japanese) { return "このテーマを深く知りたい人。" }
  return "Readers who want more context before planning."
}

function Get-CollectionDisplay($Collection) {
  if (Is-Japanese) { return $Collection.ja }
  return $Collection.en
}

function New-LanguageAlternates([string]$Path) {
  $BasePath = Get-BasePath $Path
  return @(
    [pscustomobject]@{ "@type" = "WebPage"; inLanguage = "en"; url = SiteUrl (LocalizePath $BasePath "en") },
    [pscustomobject]@{ "@type" = "WebPage"; inLanguage = "ja"; url = SiteUrl (LocalizePath $BasePath "ja") }
  )
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
  if ((Is-Japanese) -and $CategoryLabelsJa.ContainsKey($Slug)) {
    return $CategoryLabelsJa[$Slug]
  }
  foreach ($Category in $Config.categories) {
    if ($Category.slug -eq $Slug) { return $Category.label }
  }
  return $Slug
}

function Get-TagLabel([string]$Tag) {
  if (Is-Japanese) {
    $Tags = $JapaneseStatic.PSObject.Properties["tags"]
    if ($null -ne $Tags) {
      $Label = $Tags.Value.PSObject.Properties[$Tag]
      if ($null -ne $Label) { return $Label.Value }
    }
  } else {
    if ($TagLabelsEn.ContainsKey($Tag)) { return $TagLabelsEn[$Tag] }
  }
  return $Tag
}

function Get-LanguageDisplayName([string]$Lang) {
  if ($Lang -eq "ja") { return T "japanese" }
  return T "english"
}

function Get-LanguageNativeName([string]$Lang) {
  if ($Lang -eq "ja") { return "日本語" }
  return "English"
}

function Get-OtherLanguageCode {
  if (Is-Japanese) { return "en" }
  return "ja"
}

function Get-ArticleUrl($Article) {
  return Href "/articles/$($Article.id).html"
}

function Get-CategoryUrl([string]$Slug) {
  return Href "/categories/$Slug.html"
}

function Get-GenreUrl([string]$Slug) {
  return Href "/genres/$Slug.html"
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

function Get-CollectionUrl([string]$Slug) {
  return Href "/collections/$Slug.html"
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

function Get-SubcategoryDisplay($Subcategory) {
  return Get-LocalizedStatic $Subcategory "subcategories" $Subcategory.slug
}

function Get-ArticleSubcategorySlug($Article) {
  if ($Article.PSObject.Properties.Name -contains "subcategory") { return [string]$Article.subcategory }
  return ""
}

function Get-SubcategoryBySlug([string]$Slug) {
  foreach ($Subcategory in $SubcategoryDefinitions) {
    if ($Subcategory.slug -eq $Slug) { return $Subcategory }
  }
  return $null
}

function Get-ArticleSubcategoryDisplay($Article) {
  $Slug = Get-ArticleSubcategorySlug $Article
  if ([string]::IsNullOrWhiteSpace($Slug)) { return $null }
  $Subcategory = Get-SubcategoryBySlug $Slug
  if ($null -eq $Subcategory) { return $null }
  return Get-SubcategoryDisplay $Subcategory
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
  } else {
    $Copy["imageAlt"] = "$($Override[0].title)をイメージしたTABIのメインビジュアル"
  }
  foreach ($PropertyName in @("shoppingGuide", "comparison")) {
    if ($Override[0].PSObject.Properties.Name -contains $PropertyName) {
      $Copy[$PropertyName] = @($Override[0].$PropertyName)
    }
  }
  foreach ($PropertyName in @("seoTitle", "seoDescription", "audience", "searchAliases")) {
    if ($Override[0].PSObject.Properties.Name -contains $PropertyName) {
      $Copy[$PropertyName] = $Override[0].$PropertyName
    }
  }
  if (-not ($Override[0].PSObject.Properties.Name -contains "seoTitle")) {
    $Copy["seoTitle"] = "$($Override[0].title) | TABI"
  }
  if (-not ($Override[0].PSObject.Properties.Name -contains "seoDescription")) {
    $Copy["seoDescription"] = $Override[0].summary
  }
  if (-not ($Override[0].PSObject.Properties.Name -contains "audience")) {
    $Copy["audience"] = "日本の旅を、事実情報に基づいて無理なく計画したい人。"
  }
  if (-not ($Override[0].PSObject.Properties.Name -contains "searchAliases")) {
    $Copy["searchAliases"] = @($Override[0].title, "日本 旅行", "TABI")
  }
  if ($Override[0].PSObject.Properties.Name -contains "tripBrief") {
    $Copy["tripBrief"] = $Override[0].tripBrief
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
  if ((Get-ArticleSubcategorySlug $Candidate) -eq (Get-ArticleSubcategorySlug $BaseArticle)) { $Score += 14 }
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

function Select-GenreArticles($Genre, [int]$Limit) {
  $Items = @($Articles | Where-Object { (Get-ArticleSubcategorySlug $_) -eq $Genre.slug })
  return Select-ScoredArticles $Items $Limit $Genre.category
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

function Select-CollectionArticles($Collection, [int]$Limit) {
  return @($Articles |
    Where-Object {
      $Article = $_
      $Tags = Get-ArticleTags $Article
      (@($Collection.categories) -contains $Article.category) -or (@($Tags | Where-Object { @($Collection.tags) -contains $_ }).Count -gt 0)
    } |
    Sort-Object @{ Expression = { Get-ClusterScore $_ $Collection }; Descending = $true }, @{ Expression = { $_.publishedAt }; Descending = $true } |
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

function Get-GenreIndexLabel {
  if (Is-Japanese) { return "ジャンル" }
  return "Genres"
}

function New-Nav([string]$CurrentCategory) {
  $Items = foreach ($NavItem in $Config.nav) {
    $Current = ""
    if ($NavItem.slug -eq $CurrentCategory) { $Current = ' aria-current="page"' }
    '<li><a href="{0}"{1}>{2}</a></li>' -f (Get-CategoryUrl $NavItem.slug), $Current, (Html (Get-CategoryLabel $NavItem.slug))
  }
  $GenreCurrent = if ($CurrentCategory -eq "__genres") { ' aria-current="page"' } else { "" }
  $Items += '<li><a href="{0}"{1}>{2}</a></li>' -f (Href "/genres/index.html"), $GenreCurrent, (Html (Get-GenreIndexLabel))
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
      subcategory = Get-ArticleSubcategorySlug $Article
      subcategoryLabel = if ($null -ne (Get-ArticleSubcategoryDisplay $Article)) { (Get-ArticleSubcategoryDisplay $Article).title } else { "" }
      tags = @($Article.tags)
      tagLabels = @($Article.tags | ForEach-Object { Get-TagLabel $_ })
      aliases = if ($Article.PSObject.Properties.Name -contains "searchAliases") { @($Article.searchAliases) } else { @() }
      audience = Get-ArticleAudience $Article
      language = $Script:CurrentLang
      languageLabel = Get-LanguageDisplayName $Script:CurrentLang
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
  $BasePath = Get-BasePath $Path
  $CurrentPath = LocalizePath $BasePath $Script:CurrentLang
  $Canonical = SiteUrl $CurrentPath
  $EnglishPath = LocalizePath $BasePath "en"
  $JapanesePath = LocalizePath $BasePath "ja"
  $ImageUrl = if ([string]::IsNullOrWhiteSpace($Image)) { SiteUrl "/assets/images/kyoto-shrine-hero.png" } else { SiteUrl $Image }
  $OgType = if ($BasePath -like "/articles/*") { "article" } else { "website" }
  $PreloadImage = if ([string]::IsNullOrWhiteSpace($Image)) { "/assets/images/kyoto-shrine-hero-1536.webp" } else { "$(Get-ImageBase $Image)-1536.webp" }
  $FeedXml = Href "/feed.xml"
  $FeedJson = Href "/feed.json"
  $OgLocale = if (Is-Japanese) { "ja_JP" } else { "en_US" }
  $OgAlternate = if (Is-Japanese) { "en_US" } else { "ja_JP" }
  return @"
<head>
  <meta charset="UTF-8">
  <meta http-equiv="content-language" content="$Script:CurrentLang">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$(Html $Title)</title>
  <meta name="description" content="$(Html $Description)">
  <meta name="robots" content="index, follow, max-image-preview:large">
  <meta name="googlebot" content="index, follow, max-snippet:-1, max-image-preview:large, max-video-preview:-1">
  <link rel="canonical" href="$(Html $Canonical)">
  <link rel="alternate" hreflang="en" href="$(Html (SiteUrl $EnglishPath))">
  <link rel="alternate" hreflang="ja" href="$(Html (SiteUrl $JapanesePath))">
  <link rel="alternate" hreflang="x-default" href="$(Html (SiteUrl $EnglishPath))">
  <meta property="og:type" content="$OgType">
  <meta property="og:site_name" content="$(Html $Config.siteName)">
  <meta property="og:locale" content="$OgLocale">
  <meta property="og:locale:alternate" content="$OgAlternate">
  <meta property="og:title" content="$(Html $Title)">
  <meta property="og:description" content="$(Html $Description)">
  <meta property="og:url" content="$(Html $Canonical)">
  <meta property="og:image" content="$(Html $ImageUrl)">
  <meta property="og:image:alt" content="$(Html $Title)">
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
<div class="ticker" aria-label="$(Html (T "latestAria"))">
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
  $GenreCurrent = if ($CurrentCategory -eq "__genres") { ' aria-current="page"' } else { "" }
  $Items += '<a href="{0}"{1}>{2}</a>' -f (Href "/genres/index.html"), $GenreCurrent, (Html (Get-GenreIndexLabel))
  $ItineraryLabel = if (Is-Japanese) { "旅程" } else { "Itineraries" }
  $AreaLabel = if (Is-Japanese) { "地域" } else { "Areas" }
  $PlanningLabel = if (Is-Japanese) { "準備" } else { "Planning" }
  $Items += '<a href="{0}">{1}</a>' -f (Href "/itineraries/index.html"), $ItineraryLabel
  $Items += '<a href="{0}">{1}</a>' -f (Href "/areas/index.html"), $AreaLabel
  $Items += '<a href="{0}">{1}</a>' -f (Href "/planning/index.html"), $PlanningLabel
  return @"
<nav class="mobile-nav" aria-label="$(Html (T "mobileNavAria"))">
  $($Items -join "`n")
</nav>
"@
}

function Get-JsonLdTypes($Node) {
  $TypeProperty = $Node.PSObject.Properties["@type"]
  if ($null -eq $TypeProperty) { return @() }
  return @($TypeProperty.Value)
}

function Test-JsonLdHasType([object[]]$Nodes, [string]$TypeName) {
  foreach ($Node in $Nodes) {
    if ((Get-JsonLdTypes $Node) -contains $TypeName) { return $true }
  }
  return $false
}

function New-OrganizationJsonLd {
  return [ordered]@{
    "@type" = "Organization"
    "@id" = "$(SiteUrl "/")#organization"
    name = $Config.siteName
    url = $Config.siteUrl
    logo = SiteUrl "/assets/images/kyoto-shrine-hero.png"
    contactPoint = @{
      "@type" = "ContactPoint"
      email = $Config.contactEmail
      contactType = "editorial"
      availableLanguage = @("English", "Japanese")
    }
  }
}

function New-WebSiteJsonLd {
  return [ordered]@{
    "@type" = "WebSite"
    "@id" = "$(SiteUrl "/")#website"
    name = $Config.siteName
    alternateName = @("TABI Japan", "TABI 日本")
    url = $Config.siteUrl
    description = Get-SiteDescription
    inLanguage = $Script:CurrentLang
    publisher = @{ "@id" = "$(SiteUrl "/")#organization" }
    potentialAction = @{
      "@type" = "SearchAction"
      target = "$(SiteUrl (Href "/"))?q={search_term_string}"
      "query-input" = "required name=search_term_string"
    }
  }
}

function New-WebPageJsonLd([string]$Title, [string]$Description, [string]$Path, [string]$Image) {
  $ImageUrl = if ([string]::IsNullOrWhiteSpace($Image)) { SiteUrl "/assets/images/kyoto-shrine-hero.png" } else { SiteUrl $Image }
  return [ordered]@{
    "@type" = "WebPage"
    "@id" = "$(SiteUrl $Path)#webpage"
    url = SiteUrl $Path
    name = $Title
    description = $Description
    inLanguage = $Script:CurrentLang
    isPartOf = @{ "@id" = "$(SiteUrl "/")#website" }
    publisher = @{ "@id" = "$(SiteUrl "/")#organization" }
    primaryImageOfPage = @{
      "@type" = "ImageObject"
      url = $ImageUrl
    }
    workTranslation = New-LanguageAlternates $Path
  }
}

function New-ItemListJsonLd([object[]]$Items, [string]$Name) {
  $Elements = for ($i = 0; $i -lt $Items.Count; $i++) {
    $Item = $Items[$i]
    $ItemName = if ($Item.PSObject.Properties.Name -contains "title") { $Item.title } elseif ($Item.PSObject.Properties.Name -contains "name") { $Item.name } else { "Item $($i + 1)" }
    $ItemUrl = if ($Item.PSObject.Properties.Name -contains "url") { $Item.url } else { Get-ArticleUrl $Item }
    [ordered]@{
      "@type" = "ListItem"
      position = $i + 1
      name = $ItemName
      url = SiteUrl $ItemUrl
    }
  }
  return [ordered]@{
    "@type" = "ItemList"
    name = $Name
    numberOfItems = $Items.Count
    itemListElement = @($Elements)
  }
}

function New-StructuredDataJson([string]$Title, [string]$Description, [string]$Path, [string]$Image, [string]$JsonLd) {
  $Nodes = @()
  if (-not [string]::IsNullOrWhiteSpace($JsonLd)) {
    $Parsed = $JsonLd | ConvertFrom-Json
    $GraphProperty = $Parsed.PSObject.Properties["@graph"]
    if ($null -ne $GraphProperty) {
      $Nodes += @($GraphProperty.Value)
    } else {
      $Nodes += $Parsed
    }
  }
  if (-not (Test-JsonLdHasType $Nodes "Organization")) { $Nodes = @((New-OrganizationJsonLd)) + $Nodes }
  if (-not (Test-JsonLdHasType $Nodes "WebSite")) { $Nodes = @((New-WebSiteJsonLd)) + $Nodes }
  if (-not (Test-JsonLdHasType $Nodes "WebPage")) { $Nodes = @((New-WebPageJsonLd $Title $Description $Path $Image)) + $Nodes }
  return ([ordered]@{
    "@context" = "https://schema.org"
    "@graph" = @($Nodes)
  } | ConvertTo-Json -Depth 20 -Compress)
}

function New-CollectionStructuredData([string]$TypeName, [string]$Name, [string]$Description, [string]$Url, [object[]]$Items) {
  $CollectionNode = [ordered]@{
    "@type" = $TypeName
    name = $Name
    description = $Description
    inLanguage = $Script:CurrentLang
    isPartOf = @{ "@id" = "$(SiteUrl "/")#website" }
    publisher = @{ "@id" = "$(SiteUrl "/")#organization" }
    workTranslation = New-LanguageAlternates $Url
    url = SiteUrl $Url
  }
  $Graph = @($CollectionNode)
  if ($Items.Count -gt 0) {
    $Graph += New-ItemListJsonLd $Items $Name
  }
  return ([ordered]@{
    "@context" = "https://schema.org"
    "@graph" = $Graph
  } | ConvertTo-Json -Depth 12 -Compress)
}

function New-Layout([string]$Title, [string]$Description, [string]$Path, [string]$Main, [string]$CurrentCategory, [string]$Image, [string]$JsonLd) {
  $Head = New-Head $Title $Description $Path $Image
  $BasePathForNav = Get-BasePath $Path
  $CurrentNav = if ($BasePathForNav -like "/genres/*") { "__genres" } else { $CurrentCategory }
  $Nav = New-Nav $CurrentNav
  $Ticker = New-Ticker
  $MobileNav = New-MobileNav $CurrentNav
  $NewsletterHref = if ((Get-BasePath $Path) -eq "/404.html") { "$(Href "/")#newsletter" } else { "#newsletter" }
  $HomeHref = Href "/"
  $LangBase = Get-BasePath $Path
  $EnglishHref = LocalizePath $LangBase "en"
  $JapaneseHref = LocalizePath $LangBase "ja"
  $LanguageNotice = New-LanguageNotice $Path
  $QuickRoutes = New-QuickRoutes
  $RecentlyViewed = New-RecentlyViewedShell
  $SearchJson = New-SearchJson
  $FirstTimeTopic = Get-TopicDisplay ($TopicClusters | Where-Object { $_.slug -eq "first-time-japan" } | Select-Object -First 1)
  $SlowTravelTopic = Get-TopicDisplay ($TopicClusters | Where-Object { $_.slug -eq "slow-travel" } | Select-Object -First 1)
  $StructuredJson = New-StructuredDataJson $Title $Description $Path $Image $JsonLd
  $StructuredData = "<script type=""application/ld+json"">$StructuredJson</script>"
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
    <a class="site-logo" href="$HomeHref" aria-label="$(Html (T "siteLogoAria"))">
      <span class="logo-en">TABI<span class="dot">.</span></span>
      <span class="logo-jp">&#26053; - $(Html (Get-LogoSubtitle))</span>
    </a>
    <div class="header-actions">
      <nav class="language-switch" aria-label="$(Html (T "languageSwitchAria"))">
        <a href="$EnglishHref" lang="en" hreflang="en"$(if (-not (Is-Japanese)) { ' aria-current="true"' } else { '' })><span>EN</span><small>English</small></a>
        <a href="$JapaneseHref" lang="ja" hreflang="ja"$(if (Is-Japanese) { ' aria-current="true"' } else { '' })><span>JP</span><small>日本語</small></a>
      </nav>
      <button class="header-search" type="button" aria-label="$(Html (T "search"))" title="$(Html (T "search"))" aria-expanded="false" aria-controls="site-search-panel" data-search-toggle>&#8981;</button>
      <a class="header-cta" href="$NewsletterHref">$(Html (T "newsletter"))</a>
    </div>
  </div>
</header>
$Ticker
$MobileNav
$LanguageNotice
$QuickRoutes
<div class="search-panel" id="site-search-panel" data-search-panel hidden>
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
$RecentlyViewed
<footer class="site-footer">
  <div class="footer-top">
    <div>
      <div class="footer-logo">TABI<span class="dot">.</span></div>
      <p class="footer-tagline">$(Html (Get-FooterTagline))</p>
    </div>
    <div>
      <p class="footer-col-title">$(Html (T "explore"))</p>
      <ul class="footer-links">
        <li><a href="$(Get-CategoryUrl "travel-guide")">$(Html (Get-CategoryLabel "travel-guide"))</a></li>
        <li><a href="$(Get-CategoryUrl "culture")">$(Html (Get-CategoryLabel "culture"))</a></li>
        <li><a href="$(Get-CategoryUrl "food")">$(Html (Get-CategoryLabel "food"))</a></li>
        <li><a href="$(Get-CategoryUrl "hidden-gems")">$(Html (Get-CategoryLabel "hidden-gems"))</a></li>
        <li><a href="$(Get-CategoryUrl "things-to-buy")">$(Html (Get-CategoryLabel "things-to-buy"))</a></li>
        <li><a href="$(Href "/genres/index.html")">$(Html (Get-GenreIndexLabel))</a></li>
        <li><a href="$(Href "/areas/index.html")">$(if (Is-Japanese) { "地域ガイド" } else { "Area Guides" })</a></li>
      </ul>
    </div>
    <div>
      <p class="footer-col-title">TABI</p>
      <ul class="footer-links">
        <li><a href="$(Href "/")#newsletter">$(Html (T "newsletterLink"))</a></li>
        <li><a href="$(Href "/itineraries/index.html")">$(if (Is-Japanese) { "旅程" } else { "Itineraries" })</a></li>
        <li><a href="$(Href "/collections/index.html")">$(Html (T "collections"))</a></li>
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
        <li><a href="$(Href "/legal.html")">$(Html (T "legal"))</a></li>
        <li><a href="$(Href "/privacy.html")">$(Html (T "privacy"))</a></li>
        <li><a href="$(Href "/disclaimer.html")">$(Html (T "disclaimer"))</a></li>
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
    '<span class="tag-pill" data-tag="{0}">#{1}</span>' -f (Html $Tag), (Html (Get-TagLabel $Tag))
  }
  return ($Items -join "`n")
}

function New-LinkedTagList($Tags) {
  $Items = foreach ($Tag in $Tags) {
    '<a class="tag-pill" href="{0}" data-tag="{1}">#{2}</a>' -f (Get-TagUrl $Tag), (Html $Tag), (Html (Get-TagLabel $Tag))
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
<nav class="breadcrumbs" aria-label="$(Html (T "breadcrumbAria"))">
  $($Parts -join '<span aria-hidden="true">/</span>')
</nav>
"@
}

function New-LanguageNotice([string]$Path) {
  $BasePath = Get-BasePath $Path
  $OtherLang = Get-OtherLanguageCode
  $OtherHref = LocalizePath $BasePath $OtherLang
  $CurrentLabel = Get-LanguageDisplayName $Script:CurrentLang
  $OtherLabel = Get-LanguageNativeName $OtherLang
  return @"
<aside class="language-notice" aria-label="$(Html (T "language"))">
  <div>
    <span>$(Html (T "currentLanguage"))</span>
    <strong>$(Html $CurrentLabel)</strong>
  </div>
  <p>$(Html (T "languageNote"))</p>
  <a href="$OtherHref">$(Html (T "alsoAvailable")): $(Html $OtherLabel)</a>
</aside>
"@
}

function New-QuickRoutes {
  $StartArticle = Select-DiverseArticles $Articles 1 ""
  $StartHref = if ($StartArticle.Count -gt 0) { Get-ArticleUrl $StartArticle[0] } else { Href "/" }
  return @"
<nav class="quick-routes" aria-label="$(Html (T "quickRoutes"))">
  <span>$(Html (T "quickRoutes"))</span>
  <a href="$StartHref">$(Html (T "startHere"))</a>
  <a href="$(Href "/collections/index.html")">$(Html (T "browseCollections"))</a>
  <a href="$(Href "/planning/index.html")">$(Html (T "planTrip"))</a>
  <button type="button" data-search-toggle aria-expanded="false" aria-controls="site-search-panel">$(Html (T "openSearch"))</button>
</nav>
"@
}

function New-RecentlyViewedShell {
  return @"
<aside class="recently-viewed" data-recently-viewed hidden>
  <div>
    <span>$(Html (T "recentKicker"))</span>
    <h2>$(Html (T "recentTitle"))</h2>
  </div>
  <div class="recently-viewed-list" data-recently-viewed-list></div>
</aside>
"@
}

function New-ArticlePager($Article) {
  $CategoryItems = @(Select-ScoredArticles @($Articles | Where-Object { $_.category -eq $Article.category }) 100 $Article.category)
  if ($CategoryItems.Count -lt 2) { return "" }
  $Index = 0
  for ($i = 0; $i -lt $CategoryItems.Count; $i++) {
    if ($CategoryItems[$i].id -eq $Article.id) { $Index = $i; break }
  }
  $Previous = $CategoryItems[($Index - 1 + $CategoryItems.Count) % $CategoryItems.Count]
  $Next = $CategoryItems[($Index + 1) % $CategoryItems.Count]
  return @"
<nav class="article-pager" aria-label="$(Html (T "moreInCategory"))">
  <a href="$(Get-ArticleUrl $Previous)">
    <span>$(Html (T "previousGuide"))</span>
    <strong>$(Html $Previous.title)</strong>
  </a>
  <a href="$(Get-ArticleUrl $Next)">
    <span>$(Html (T "nextGuide"))</span>
    <strong>$(Html $Next.title)</strong>
  </a>
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
  $DefaultJa = $ContentPolicy.defaultArticleMetaJa
  $SourceNote = if ($Article.PSObject.Properties.Name -contains "sourceNote") { $Article.sourceNote } else { $Default.sourceNote }
  if (Is-Japanese -and $SourceNote -eq $Default.sourceNote -and $null -ne $DefaultJa) {
    $SourceNote = $DefaultJa.sourceNote
  }
  return [pscustomobject]@{
    sourcePolicy = if ($Article.PSObject.Properties.Name -contains "sourcePolicy") { $Article.sourcePolicy } else { $Default.sourcePolicy }
    verificationLevel = if ($Article.PSObject.Properties.Name -contains "verificationLevel") { $Article.verificationLevel } else { $Default.verificationLevel }
    lastChecked = if ($Article.PSObject.Properties.Name -contains "lastChecked") { $Article.lastChecked } else { $Default.lastChecked }
    sourceNote = $SourceNote
  }
}

function Get-SourcePolicyDisplay([string]$Value) {
  switch ($Value) {
    "tabi-local-editorial" {
      if (Is-Japanese) { return "TABI独自編集" }
      return "TABI local editorial"
    }
    default { return $Value }
  }
}

function Get-VerificationDisplay([string]$Value) {
  switch ($Value) {
    "static-editorial" {
      if (Is-Japanese) { return "静的編集レビュー" }
      return "Static editorial review"
    }
    default { return $Value }
  }
}

function Get-PolicyItems([string]$EnglishKey, [string]$JapaneseKey) {
  if (Is-Japanese) { return @($ContentPolicy.$JapaneseKey) }
  return @($ContentPolicy.$EnglishKey)
}

function Get-TrustSummary {
  if (Is-Japanese) { return $ContentPolicy.trustSummary.ja }
  return $ContentPolicy.trustSummary.en
}

function New-ArticleSourcePanel($Article) {
  $Meta = Get-ArticleSourceMeta $Article
  $PolicyText = if (Is-Japanese) { "AIスクレイピング禁止、引用不可、転載不可、権利不明、倫理的に問題のある情報源は使わない方針です。" } else { "TABI avoids sources that prohibit AI scraping, quotation, republication, reuse, or create ethical risk." }
  $ConfirmText = if (Is-Japanese) { "営業時間、価格、閉店、交通ルールなど変わりやすい情報は、旅行前に公式情報で確認してください。" } else { "Confirm volatile details such as hours, prices, closures, and transport rules with official sources before travel." }
  $PolicyLabel = if (Is-Japanese) { "方針" } else { "Policy" }
  $VerificationLabel = if (Is-Japanese) { "検証" } else { "Verification" }
  $CheckedLabel = if (Is-Japanese) { "最終確認" } else { "Last checked" }
  $PanelText = if (Is-Japanese) { "$PolicyText$ConfirmText" } else { "$PolicyText $ConfirmText" }
  $CorrectionSubject = [uri]::EscapeDataString("TABI correction: $($Article.title)")
  return @"
<div class="source-panel">
  <p class="footer-col-title">$(Html (T "sourceInfo"))</p>
  <p class="source-trust-kicker">$(Html (T "trustKicker"))</p>
  <dl>
    <div><dt>$(Html $PolicyLabel)</dt><dd>$(Html (Get-SourcePolicyDisplay $Meta.sourcePolicy))</dd></div>
    <div><dt>$(Html $VerificationLabel)</dt><dd>$(Html (Get-VerificationDisplay $Meta.verificationLevel))</dd></div>
    <div><dt>$(Html $CheckedLabel)</dt><dd>$(Html $Meta.lastChecked)</dd></div>
  </dl>
  <p>$(Html $PanelText)</p>
  <p><strong>$(Html (T "sourceNote")):</strong> $(Html $Meta.sourceNote)</p>
  <p><strong>$(Html (T "corrections")):</strong> $(if (Is-Japanese) { "誤りや更新点があれば編集窓口へ送れます。" } else { "Send errors or update requests to the editorial inbox." })</p>
  <a class="tag-pill topic-pill" href="$(Href "/source-policy.html")">$(Html (T "sourcePolicy"))</a>
  <a class="tag-pill" href="mailto:$($Config.contactEmail)?subject=$CorrectionSubject">$(Html (T "sendCorrection"))</a>
</div>
"@
}

function Get-ArticleArea($Article) {
  $Tags = Get-ArticleTags $Article
  $BestArea = $null
  $BestScore = 0
  foreach ($Area in $AreaClusters) {
    $Shared = @($Tags | Where-Object { @($Area.tags) -contains $_ }).Count
    if (@($Area.categories) -contains $Article.category) { $Shared += 1 }
    if ($Shared -gt $BestScore) {
      $BestScore = $Shared
      $BestArea = $Area
    }
  }
  return $BestArea
}

function Get-ArticleItinerary($Article) {
  $Tags = Get-ArticleTags $Article
  $BestPlan = $null
  $BestScore = 0
  foreach ($Plan in $ItineraryPlans) {
    $Shared = @($Tags | Where-Object { @($Plan.tags) -contains $_ }).Count
    if (@($Plan.categories) -contains $Article.category) { $Shared += 1 }
    if ($Shared -gt $BestScore) {
      $BestScore = $Shared
      $BestPlan = $Plan
    }
  }
  return $BestPlan
}

function Get-ArticleGlossaryTerm($Article) {
  $Tags = Get-ArticleTags $Article
  $Mapping = @{
    ryokan = "Ryokan"; onsen = "Onsen"; konbini = "Konbini"; izakaya = "Otoshi"; food = "Otoshi"; shopping = "Tax-free"
    matcha = "Kaiseki"; "kiso-valley" = "Shukubo"; "where-to-stay" = "Ryokan"; "travel-tips" = "IC card"; planning = "IC card"
  }
  foreach ($Tag in $Tags) {
    if ($Mapping.ContainsKey($Tag)) {
      $Term = $GlossaryTerms | Where-Object { $_.term -eq $Mapping[$Tag] } | Select-Object -First 1
      if ($null -ne $Term) { return Get-GlossaryDisplay $Term }
    }
  }
  return Get-GlossaryDisplay ($GlossaryTerms | Select-Object -First 1)
}

function New-ArticlePathways($Article) {
  $Topic = Get-ArticleTopic $Article
  $Area = Get-ArticleArea $Article
  $Plan = Get-ArticleItinerary $Article
  $Term = Get-ArticleGlossaryTerm $Article
  $Cards = @()
  if ($null -ne $Topic) {
    $Display = Get-TopicDisplay $Topic
    $Cards += New-UtilityCard (T "topicPath") $Display.title $Display.description (Get-TopicUrl $Topic.slug)
  }
  if ($null -ne $Area) {
    $Display = Get-AreaDisplay $Area
    $Cards += New-UtilityCard (T "areaPath") $Display.title $Display.description (Get-AreaUrl $Area.slug)
  }
  if ($null -ne $Plan) {
    $Display = Get-ItineraryDisplay $Plan
    $Cards += New-UtilityCard (T "itineraryPath") $Display.title $Display.description (Get-ItineraryUrl $Plan.slug)
  }
  if ($null -ne $Term) {
    $Description = if (Is-Japanese) { "$($Term.term)など、旅で出てくる言葉を確認できます。" } else { "Decode terms like $($Term.term) that appear across TABI guides." }
    $Cards += New-UtilityCard (T "glossaryPath") $Term.term $Description "/glossary.html"
  }
  if ($Cards.Count -eq 0) { return "" }
  return @"
<section class="pathway-section" aria-labelledby="pathway-heading">
  <div class="section-label compact-label">
    <span class="section-label-jp">&#36947;</span>
    <h2 class="section-label-en" id="pathway-heading">$(Html (T "linkPath"))</h2>
    <div class="section-label-line"></div>
  </div>
  <p class="algorithm-note">$(if (Is-Japanese) { "この記事のタグ、カテゴリ、地域性から次に読む導線を自動で選んでいます。" } else { "Selected from this article's tags, category, area fit, and itinerary fit." })</p>
  <div class="utility-grid">
    $($Cards -join "`n")
  </div>
</section>
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
<div class="article-toc" aria-label="$(Html (T "articleSectionsAria"))">
  <p class="footer-col-title">$(Html (T "inThisGuide"))</p>
  <ol>
    $($Links -join "`n")
  </ol>
</div>
"@
}

function New-ArticleTripBrief($Article) {
  if (-not ($Article.PSObject.Properties.Name -contains "tripBrief")) { return "" }
  $Brief = $Article.tripBrief
  $Takeaways = foreach ($Item in @($Brief.takeaways)) { "<li>$(Html $Item)</li>" }
  $Before = foreach ($Item in @($Brief.beforeYouGo)) { "<li>$(Html $Item)</li>" }
  $Avoid = foreach ($Item in @($Brief.avoid)) { "<li>$(Html $Item)</li>" }
  return @"
<section class="trip-brief" aria-labelledby="trip-brief-title">
  <p class="page-kicker">$(Html (T "quickRead"))</p>
  <h2 id="trip-brief-title">$(Html (T "keyTakeaways"))</h2>
  <div class="brief-grid">
    <div class="brief-card">
      <span>$(Html (T "keyTakeaways"))</span>
      <ul>$($Takeaways -join "`n")</ul>
    </div>
    <div class="brief-card">
      <span>$(Html (T "beforeYouGo"))</span>
      <ul>$($Before -join "`n")</ul>
    </div>
    <div class="brief-card">
      <span>$(Html (T "avoid"))</span>
      <ul>$($Avoid -join "`n")</ul>
    </div>
  </div>
  <dl class="brief-facts">
    <div><dt>$(Html (T "season"))</dt><dd>$(Html $Brief.season)</dd></div>
    <div><dt>$(Html (T "budget"))</dt><dd>$(Html $Brief.budget)</dd></div>
    <div><dt>$(Html (T "timeNeeded"))</dt><dd>$(Html $Brief.timeNeeded)</dd></div>
  </dl>
</section>
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
        <th scope="col">$(Html (T "option"))</th>
        <th scope="col">$(Html (T "bestFor"))</th>
        <th scope="col">$(Html (T "watchFor"))</th>
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
    $Disclosure = '<p class="shopping-disclosure">{0}</p>' -f (Html (T "affiliateDisclosure"))
  }

  return @"
<section class="shopping-guide" aria-labelledby="shopping-guide-title">
  <p class="page-kicker">$(Html (T "buyerNotes"))</p>
  <h2 id="shopping-guide-title">$(Html (T "buyCheckTitle"))</h2>
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
    <p class="page-kicker">$(Html (T "feedbackKicker"))</p>
    <h2 id="feedback-title">$(Html (T "feedbackTitle"))</h2>
    <p>$(Html (T "feedbackBody"))</p>
  </div>
  <a class="button secondary" href="mailto:$($Config.contactEmail)?subject=$Subject">$(Html (T "feedbackButton"))</a>
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

function New-HubIntro([string]$Label, [string]$Text) {
  return @"
<section class="hub-intro" aria-label="$(Html $Label)">
  <span>$(Html $Label)</span>
  <p>$(Html $Text)</p>
</section>
"@
}

function Get-CategoryDescription([string]$Slug, [string]$Label) {
  if (Is-Japanese) {
    switch ($Slug) {
      "travel-guide" { return "日本旅行のルート、宿、移動、街歩きを、予定表ではなく旅の質から考えるガイドです。" }
      "culture" { return "わびさび、金継ぎ、花見、神社の作法など、日本文化を旅の中で誤解なく見るための読み物です。" }
      "food" { return "居酒屋、メニュー、コンビニ朝食、大阪の食べ歩きまで、旅の記憶を作る食の入口です。" }
      "things-to-buy" { return "包丁、抹茶、浴衣、ドラッグストア商品など、持ち帰ってからも使える買い物を選びます。" }
      "hidden-gems" { return "有名さよりも、静けさ、地域の文脈、歩いた後に残る感覚を重視した場所のガイドです。" }
    }
  }
  switch ($Slug) {
    "travel-guide" { return "Japan travel guides for routes, stays, transport, and slower decisions that improve the shape of a trip." }
    "culture" { return "Cultural guides that explain aesthetics, craft, seasonal customs, and etiquette without flattening them into slogans." }
    "food" { return "Food guides for counters, menus, convenience-store mornings, Osaka eating days, and the habits that make meals easier." }
    "things-to-buy" { return "Shopping guides for practical, culturally grounded things worth bringing home from Japan." }
    "hidden-gems" { return "Quieter Japan guides selected for context, restraint, and places that do not need to become crowded checklists." }
    "nature-outdoors" { return "Nature and outdoor guides for forests, coasts, mountains, islands, and rural landscapes with safer, slower planning." }
    "stays" { return "Stay guides for ryokan, minshuku, machiya, temple lodgings, farm stays, and nights that become part of the trip." }
  }
  if (Is-Japanese) { return "日本の$Labelに関するTABIのガイドをまとめています。" }
  return "Curated TABI guides for $($Label.ToLowerInvariant()) in Japan."
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
        <input class="nl-input" type="email" name="email" placeholder="your@email.com" aria-label="$(Html (T "emailAria"))" required>
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
      New-UtilityCard "目的別" "目的別ガイド" "雨の日、ひとり旅、食の旅、持ち帰りたいものなど、旅の意図から探せます。" "/collections/index.html"
      New-UtilityCard "旅程" "日数から旅を選ぶ" "3日、7日、10日、14日の静的ルートをTABI内の記事グラフから組み立てます。" "/itineraries/index.html"
      New-UtilityCard "地域" "場所から探す" "東京、京都、大阪、屋久島、瀬戸内をタグとカテゴリの適合度から整理します。" "/areas/index.html"
      New-UtilityCard "チェックリスト" "出発前に整える" "お金、移動、通信、荷物、初日のつまずきを減らす実用チェックリストです。" "/planning/japan-travel-checklist.html"
    )
  } else {
    @(
      New-UtilityCard "Collections" "Browse by Intent" "Rainy days, solo travel, food-led routes, and things worth bringing home." "/collections/index.html"
      New-UtilityCard "Itineraries" "Choose a Trip Length" "Static 3, 7, 10, and 14 day routes assembled from TABI's local article graph." "/itineraries/index.html"
      New-UtilityCard "Areas" "Browse by Place" "Tokyo, Kyoto, Osaka, Yakushima, and Setouchi hubs built from tags and category fit." "/areas/index.html"
      New-UtilityCard "Checklist" "Before You Fly" "A practical pre-trip checklist for money, transit, connectivity, luggage, and first-day friction." "/planning/japan-travel-checklist.html"
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
  $EditorialCards = for ($i = 0; $i -lt $Editorial.Count; $i++) {
    New-ArticleCard $Editorial[$i] ($i -eq 0)
  }
  $CultureCards = foreach ($Article in $Culture) { New-CultureCard $Article }
  $BuyCards = foreach ($Article in $Buy) { New-BuyCard $Article }
  $HomeTitle = Get-HomeTitle
  $HomeDescription = Get-HomeDescription
  $HeroRead = Format-ReadingTime $Hero.readingTime
  $HeroFeature = @"
<a class="hero-feature" href="$(Get-ArticleUrl $Hero)">
  <span>$(Html (T "featuredGuide")) / $(Html (Get-CategoryLabel $Hero.category)) / $HeroRead</span>
  <strong>$(Html $Hero.title)</strong>
</a>
"@
  $LocalDiscoverySection = ""
  if (Is-Japanese) {
    $Discovery = Select-DiverseArticles @($Sorted | Where-Object { $_.category -in @("hidden-gems", "culture", "travel-guide") }) 4 ""
    $DiscoveryCards = foreach ($Article in $Discovery) { New-CompactArticleCard $Article }
    $LocalDiscoverySection = @"
<section aria-labelledby="local-discovery-heading" class="next-read">
  <div class="section-label">
    <span class="section-label-jp">&#26085;</span>
    <h2 class="section-label-en" id="local-discovery-heading">日本人も知らない日本</h2>
    <div class="section-label-line"></div>
    <a class="section-label-link" href="$(Get-CategoryUrl "hidden-gems")">知られざる場所</a>
  </div>
  <p class="algorithm-note">有名さよりも、静けさ、文化的な文脈、旅の余白を残せるかを重視して選んでいます。</p>
  <div class="compact-grid">
    $($DiscoveryCards -join "`n")
  </div>
</section>
"@
  }
  $Newsletter = New-Newsletter
  $SiteTitle = Get-SiteTitle
  $SiteDescription = Get-SiteDescription

  $Main = @"
<section class="hero">
  <div class="hero-media">
    $(New-ResponsiveImage $Hero.image $Hero.imageAlt "eager" "100vw" "high")
  </div>
  <div class="hero-kanji">&#26053;</div>
  <div class="hero-content">
    <div class="eyebrow"><span class="eyebrow-mark">$(Html (T "homeKicker"))</span><span>EN / JP</span></div>
    <h1 class="hero-title">$(Html $HomeTitle)</h1>
    <p class="hero-desc">$(Html $HomeDescription)</p>
    $HeroFeature
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
$LocalDiscoverySection
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

  $HomeWebSiteJsonLd = New-WebSiteJsonLd
  $HomeWebSiteJsonLd["workTranslation"] = New-LanguageAlternates "/"
  $JsonLd = $HomeWebSiteJsonLd | ConvertTo-Json -Depth 7 -Compress

  return New-Layout $SiteTitle $SiteDescription "/" $Main "" $Hero.image $JsonLd
}

function New-ArticlePage($Article) {
  $Read = Format-ReadingTime $Article.readingTime
  $SeoTitle = Get-ArticleSeoTitle $Article
  $SeoDescription = Get-ArticleSeoDescription $Article
  $OtherLangHref = if (Is-Japanese) { LocalizePath (Get-ArticleUrl $Article) "en" } else { LocalizePath (Get-ArticleUrl $Article) "ja" }
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
  $Subcategory = Get-ArticleSubcategoryDisplay $Article
  $SubcategoryHtml = ""
  if ($null -ne $Subcategory) {
    $SubcategoryHtml = '<a class="tag-pill topic-pill" href="{0}">{1}</a>' -f (Get-GenreUrl $Subcategory.slug), (Html $Subcategory.title)
  }
  $Related = Select-RelatedArticles $Article 4
  $RelatedHtml = foreach ($Item in $Related) {
    '<li><a href="{0}">{1}</a></li>' -f (Get-ArticleUrl $Item), (Html $Item.title)
  }
  $RelatedCards = foreach ($Item in ($Related | Select-Object -First 3)) {
    New-CompactArticleCard $Item
  }
  $ArticlePager = New-ArticlePager $Article
  $Pathways = New-ArticlePathways $Article
  $TripBrief = New-ArticleTripBrief $Article
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = Get-CategoryLabel $Article.category; url = Get-CategoryUrl $Article.category },
    [pscustomobject]@{ label = if ($null -ne $Subcategory) { $Subcategory.title } else { Get-CategoryLabel $Article.category }; url = if ($null -ne $Subcategory) { Get-GenreUrl $Subcategory.slug } else { Get-CategoryUrl $Article.category } },
    [pscustomobject]@{ label = $Article.title; url = "" }
  )

  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">$(Html (Get-CategoryLabel $Article.category))</p>
  <h1 class="page-title">$(Html $Article.title)</h1>
  <p class="page-desc">$(Html $Article.summary)</p>
  <p class="article-meta">$(Format-Date $Article.publishedAt) / $Read</p>
  <div class="article-audience">
    <span>$(Html (T "audience"))</span>
    <strong>$(Html (Get-ArticleAudience $Article))</strong>
    <a href="$OtherLangHref">$(Html (T "readInOtherLanguage"))</a>
  </div>
</section>
<article class="article-layout">
  <div class="article-cover">
    $(New-ResponsiveImage $Article.image $Article.imageAlt "eager" "(max-width: 900px) 100vw, 1180px" "high")
  </div>
  <div class="article-body">
$TripBrief
$($SectionHtml -join "`n")
$ShoppingGuide
  </div>
  <aside class="article-sidebar" aria-label="$(Html (T "articleDetailsAria"))">
    $ArticleToc
    $(New-ArticleSignals $Article)
    <p class="footer-col-title">$(Html (T "filedUnder"))</p>
    <a class="tag-pill" href="$(Get-CategoryUrl $Article.category)">$(Html (Get-CategoryLabel $Article.category))</a>
    $SubcategoryHtml
    $TopicHtml
    <div class="tag-list">
      $(New-LinkedTagList $Article.tags)
    </div>
    <p class="footer-col-title sidebar-section-title">$(Html (T "related"))</p>
    <p class="sidebar-note"><strong>$(Html (T "whyRelated")):</strong> $(if (Is-Japanese) { "共有タグ、カテゴリ適合、鮮度、季節性、品質スコアから選んでいます。" } else { "Chosen by shared tags, category fit, freshness, seasonality, and quality score." })</p>
    <ul class="footer-links">
      $($RelatedHtml -join "`n")
    </ul>
    $(New-ArticleSourcePanel $Article)
  </aside>
</article>
$ArticlePager
$Pathways
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
  $ArticleSourceMeta = Get-ArticleSourceMeta $Article
  $ArticleJsonLd = @{
    "@type" = "Article"
    "@id" = "$(SiteUrl (Get-ArticleUrl $Article))#article"
    headline = $Article.title
    description = $SeoDescription
    alternativeHeadline = Get-ArticleAudience $Article
    articleSection = @((Get-CategoryLabel $Article.category), $(if ($null -ne $Subcategory) { $Subcategory.title } else { "" })) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    keywords = @($Article.tags | ForEach-Object { Get-TagLabel $_ }) + $(if ($null -ne $Subcategory) { @($Subcategory.title) } else { @() }) + $(if ($Article.PSObject.Properties.Name -contains "searchAliases") { @($Article.searchAliases) } else { @() })
    image = $ImageUrl
    thumbnailUrl = $ImageUrl
    datePublished = $Article.publishedAt
    dateModified = $ArticleSourceMeta.lastChecked
    inLanguage = $Script:CurrentLang
    isPartOf = @{ "@id" = "$(SiteUrl "/")#website" }
    about = @((Get-CategoryLabel $Article.category), @($Article.tags | ForEach-Object { Get-TagLabel $_ })) | ForEach-Object { $_ }
    workTranslation = New-LanguageAlternates (Get-ArticleUrl $Article)
    author = @{ "@id" = "$(SiteUrl "/")#organization" }
    publisher = @{ "@id" = "$(SiteUrl "/")#organization" }
    mainEntityOfPage = SiteUrl (Get-ArticleUrl $Article)
    timeRequired = "PT$($Article.readingTime)M"
  }
  $BreadcrumbJsonLd = @{
    "@type" = "BreadcrumbList"
    itemListElement = @(
      @{ "@type" = "ListItem"; position = 1; name = T "home"; item = SiteUrl (Href "/") },
      @{ "@type" = "ListItem"; position = 2; name = Get-CategoryLabel $Article.category; item = SiteUrl (Get-CategoryUrl $Article.category) },
      @{ "@type" = "ListItem"; position = 3; name = if ($null -ne $Subcategory) { $Subcategory.title } else { Get-CategoryLabel $Article.category }; item = if ($null -ne $Subcategory) { SiteUrl (Get-GenreUrl $Subcategory.slug) } else { SiteUrl (Get-CategoryUrl $Article.category) } },
      @{ "@type" = "ListItem"; position = 4; name = $Article.title; item = SiteUrl (Get-ArticleUrl $Article) }
    )
  }
  $FaqJsonLd = @{
    "@type" = "FAQPage"
    mainEntity = @($Sections | Select-Object -First 3 | ForEach-Object {
      @{
        "@type" = "Question"
        name = $_.heading
        acceptedAnswer = @{
          "@type" = "Answer"
          text = $_.body
        }
      }
    })
  }
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@graph" = @($ArticleJsonLd, $BreadcrumbJsonLd, $FaqJsonLd)
  } | ConvertTo-Json -Depth 10 -Compress

  return New-Layout $SeoTitle $SeoDescription (Get-ArticleUrl $Article) $Main $Article.category $Article.image $JsonLd
}

function New-CategoryPage($Category) {
  $CategoryLabel = Get-CategoryLabel $Category.slug
  $Description = Get-CategoryDescription $Category.slug $CategoryLabel
  $Kicker = if (Is-Japanese) { "カテゴリ" } else { "Category" }
  $Algorithm = if (Is-Japanese) { "カテゴリ適合、鮮度、季節性、編集上の重み、記事品質で並べています。" } else { "Sorted by category relevance, freshness, seasonality, editorial weight, and article quality." }
  $Items = Select-ScoredArticles @($Articles | Where-Object { $_.category -eq $Category.slug }) 100 $Category.slug
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $GenreCards = foreach ($Genre in @($SubcategoryDefinitions | Where-Object { ($_.category -eq $Category.slug) -or (@($_.categories) -contains $Category.slug) })) {
    $GenreDisplay = Get-SubcategoryDisplay $Genre
    $Count = @(Select-GenreArticles $Genre 500).Count
    $CountLabel = if (Is-Japanese) { "$Count 件" } else { "$Count guides" }
    New-UtilityCard $CountLabel $GenreDisplay.title $GenreDisplay.description (Get-GenreUrl $Genre.slug)
  }
  $GenreBlock = if (@($GenreCards).Count -gt 0) {
    $GenreTitle = if (Is-Japanese) { "細かいジャンル" } else { "Genres in this category" }
    @"
<section aria-labelledby="category-genres">
  <div class="section-label">
    <span class="section-label-jp">棚</span>
    <h2 class="section-label-en" id="category-genres">$(Html $GenreTitle)</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="utility-grid">
    $($GenreCards -join "`n")
  </div>
</section>
"@
  } else { "" }
  $HubIntro = New-HubIntro (T "categoryHub") (T "hubIntro")
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
$HubIntro
$GenreBlock
$(New-AlgorithmNote $Algorithm)
<section class="listing-grid" aria-label="$(Html $CategoryLabel) articles">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = New-CollectionStructuredData "CollectionPage" $CategoryLabel $Description (Get-CategoryUrl $Category.slug) $Items
  return New-Layout "$CategoryLabel - TABI" $Description (Get-CategoryUrl $Category.slug) $Main $Category.slug "/assets/images/kyoto-shrine-hero.png" $JsonLd
}


function New-GenreIndexPage {
  $Kicker = if (Is-Japanese) { "ジャンル" } else { "Genres" }
  $Title = if (Is-Japanese) { "1000件に向けた細かい棚。" } else { "Smaller shelves for a 1,000-guide library." }
  $Description = if (Is-Japanese) { "大カテゴリを保ちながら、食、旅程、工芸、買い物、穴場を細かいジャンルで探せるようにしています。" } else { "Keep the five main categories, then browse by focused genres built for a much larger TABI library." }
  $Cards = foreach ($Genre in $SubcategoryDefinitions) {
    $GenreDisplay = Get-SubcategoryDisplay $Genre
    $Count = @(Select-GenreArticles $Genre 500).Count
    $CountLabel = if (Is-Japanese) { "$(Get-CategoryLabel $Genre.category) / $Count 件" } else { "$(Get-CategoryLabel $Genre.category) / $Count guides" }
    New-UtilityCard $CountLabel $GenreDisplay.title $GenreDisplay.description (Get-GenreUrl $Genre.slug)
  }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = $Kicker; url = "" }))
  <p class="page-kicker">$(Html $Kicker)</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Description)</p>
</section>
<section class="utility-grid" aria-label="Genre links">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $Items = @($SubcategoryDefinitions | ForEach-Object { $Display = Get-SubcategoryDisplay $_; [pscustomobject]@{ title = $Display.title; url = Get-GenreUrl $_.slug } })
  $JsonLd = New-CollectionStructuredData "CollectionPage" "TABI Genres" $Description "/genres/index.html" $Items
  return New-Layout "$Kicker - TABI" $Description "/genres/index.html" $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-GenrePage($Genre) {
  $GenreDisplay = Get-SubcategoryDisplay $Genre
  $Kicker = if (Is-Japanese) { "ジャンル" } else { "Genre" }
  $GenreIndexLabel = if (Is-Japanese) { "ジャンル" } else { "Genres" }
  $Algorithm = if (Is-Japanese) { "このジャンルに明示的に分類された記事を、鮮度、季節性、記事品質で並べています。" } else { "This page lists guides explicitly assigned to this genre, sorted by freshness, seasonal fit, and article quality." }
  $Items = Select-GenreArticles $Genre 100
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $Breadcrumbs = New-Breadcrumbs @(
    [pscustomobject]@{ label = "Home"; url = "/" },
    [pscustomobject]@{ label = Get-CategoryLabel $Genre.category; url = Get-CategoryUrl $Genre.category },
    [pscustomobject]@{ label = $GenreIndexLabel; url = "/genres/index.html" },
    [pscustomobject]@{ label = $GenreDisplay.title; url = "" }
  )
  $Main = @"
<section class="page-hero">
  $Breadcrumbs
  <p class="page-kicker">$(Html $Kicker) / $(Html (Get-CategoryLabel $Genre.category))</p>
  <h1 class="page-title">$(Html $GenreDisplay.title)</h1>
  <p class="page-desc">$(Html $GenreDisplay.description)</p>
</section>
$(New-AlgorithmNote $Algorithm)
<section class="listing-grid" aria-label="$(Html $GenreDisplay.title) articles">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = New-CollectionStructuredData "CollectionPage" $GenreDisplay.title $GenreDisplay.description (Get-GenreUrl $Genre.slug) $Items
  return New-Layout "$($GenreDisplay.title) - TABI" $GenreDisplay.description (Get-GenreUrl $Genre.slug) $Main $Genre.category "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-TagPage([string]$Tag) {
  $Kicker = if (Is-Japanese) { "タグ" } else { "Tag" }
  $TagLabel = Get-TagLabel $Tag
  $Title = "#$TagLabel"
  $Description = if (Is-Japanese) { "#$TagLabel に関連するTABI内の記事をまとめています。" } else { "Articles connected to $Tag, gathered from across TABI." }
  $Algorithm = if (Is-Japanese) { "記事スコアが高く、鮮度と季節性のあるガイドから表示しています。" } else { "Sorted by article score so stronger, fresher, and more seasonally useful guides appear first." }
  $Items = Select-ScoredArticles @($Articles | Where-Object { @($_.tags) -contains $Tag }) 100 ""
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $RelatedTags = @($Items | ForEach-Object { $_.tags } | Where-Object { $_ -ne $Tag } | Group-Object | Sort-Object Count -Descending | Select-Object -First 8)
  $RelatedTagLinks = foreach ($Group in $RelatedTags) {
    '<a class="tag-pill" href="{0}">#{1}</a>' -f (Get-TagUrl $Group.Name), (Html (Get-TagLabel $Group.Name))
  }
  $RelatedTagLabel = if (Is-Japanese) { "関連タグ" } else { "Related tags" }
  $RelatedTagBlock = if (@($RelatedTagLinks).Count -gt 0) {
    @"
<section class="hub-intro" aria-label="Related tags">
  <span>$(Html $RelatedTagLabel)</span>
  <div class="tag-list">$($RelatedTagLinks -join "`n")</div>
</section>
"@
  } else { "" }
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
$(New-HubIntro (T "tagHub") (T "hubIntro"))
$RelatedTagBlock
$(New-AlgorithmNote $Algorithm)
<section class="listing-grid" aria-label="$(Html $Tag) articles">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = New-CollectionStructuredData "CollectionPage" $Title $Description (Get-TagUrl $Tag) $Items
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
  $JsonLd = New-CollectionStructuredData "CollectionPage" $TopicDisplay.title $TopicDisplay.description (Get-TopicUrl $Topic.slug) $Items
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
  $ListItems = @($AreaClusters | ForEach-Object {
    $AreaDisplay = Get-AreaDisplay $_
    [pscustomobject]@{ title = $AreaDisplay.title; url = Get-AreaUrl $_.slug }
  })
  $JsonLd = New-CollectionStructuredData "CollectionPage" "TABI $PageName" $Description "/areas/index.html" $ListItems
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
  $AreaPageJsonLd = New-CollectionStructuredData "CollectionPage" "$($AreaDisplay.title) Travel Guide" $AreaDisplay.description (Get-AreaUrl $Area.slug) $Items
  $AreaParsedJsonLd = $AreaPageJsonLd | ConvertFrom-Json
  $DestinationJsonLd = @{
    "@type" = "TouristDestination"
    name = $AreaDisplay.title
    description = $AreaDisplay.description
    url = SiteUrl (Get-AreaUrl $Area.slug)
    image = SiteUrl $Area.image
    touristType = @("Cultural travelers", "Independent travelers")
  }
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@graph" = @($AreaParsedJsonLd."@graph") + @($DestinationJsonLd)
  } | ConvertTo-Json -Depth 12 -Compress
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
  $ListItems = @($ItineraryPlans | ForEach-Object {
    $PlanDisplay = Get-ItineraryDisplay $_
    [pscustomobject]@{ title = $PlanDisplay.title; url = Get-ItineraryUrl $_.slug }
  })
  $JsonLd = New-CollectionStructuredData "CollectionPage" "Japan $PageName" $Description "/itineraries/index.html" $ListItems
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
  $TripNode = [ordered]@{
    "@type" = "TouristTrip"
    name = $PlanDisplay.title
    description = $PlanDisplay.description
    inLanguage = $Script:CurrentLang
    isPartOf = @{ "@id" = "$(SiteUrl "/")#website" }
    provider = @{ "@id" = "$(SiteUrl "/")#organization" }
    workTranslation = New-LanguageAlternates (Get-ItineraryUrl $Plan.slug)
    url = SiteUrl (Get-ItineraryUrl $Plan.slug)
    itinerary = @($PlanDisplay.steps | ForEach-Object { @{ "@type" = "ListItem"; name = $_.title; description = $_.body } })
  }
  $JsonLd = ([ordered]@{
    "@context" = "https://schema.org"
    "@graph" = @($TripNode, (New-ItemListJsonLd $Items $SupportingHeading))
  } | ConvertTo-Json -Depth 12 -Compress)
  return New-Layout "$($PlanDisplay.title) - TABI" $PlanDisplay.description (Get-ItineraryUrl $Plan.slug) $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-CollectionIndexPage {
  $Cards = foreach ($Collection in $CollectionDefinitions) {
    $Display = Get-CollectionDisplay $Collection
    $Count = @(Select-CollectionArticles $Collection 20).Count
    $CountLabel = if (Is-Japanese) { "$Count 本のガイド" } else { "$Count guides" }
    New-UtilityCard $Display.kicker $Display.title "$($Display.description) $CountLabel." (Get-CollectionUrl $Collection.slug)
  }
  $PageName = T "collections"
  $Title = if (Is-Japanese) { "目的から日本の旅を探す。" } else { "Browse Japan by intent." }
  $Description = if (Is-Japanese) { "雨の日、ひとり旅、食の旅、買い物、はじめての日本など、旅の意図からTABI内のガイドを組み替えた編集ハブです。" } else { "Editorial collections that reorganize TABI guides around intent: rainy days, solo travel, food, shopping, first trips, and quieter Japan." }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = $PageName; url = "" }))
  <p class="page-kicker">$(Html $PageName)</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Description)</p>
</section>
<section class="utility-grid" aria-label="$(Html $PageName)">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $ListItems = @($CollectionDefinitions | ForEach-Object {
    $Display = Get-CollectionDisplay $_
    [pscustomobject]@{ title = $Display.title; url = Get-CollectionUrl $_.slug }
  })
  $JsonLd = New-CollectionStructuredData "CollectionPage" "TABI $PageName" $Description (Href "/collections/index.html") $ListItems
  return New-Layout "$PageName - TABI" $Description "/collections/index.html" $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-CollectionPage($Collection) {
  $Display = Get-CollectionDisplay $Collection
  $Items = Select-CollectionArticles $Collection 100
  $Cards = foreach ($Article in $Items) { New-ListingCard $Article }
  $Featured = @($Items | Select-Object -First 3)
  $FeaturedCards = foreach ($Article in $Featured) { New-CompactArticleCard $Article }
  $Algorithm = if (Is-Japanese) { "この目的別ガイドは、タグ、カテゴリ、記事スコア、鮮度、季節性から静的に組み立てています。" } else { "This collection is assembled from tags, categories, article score, freshness, and seasonal fit." }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = (T "collections"); url = "/collections/index.html" }, [pscustomobject]@{ label = $Display.title; url = "" }))
  <p class="page-kicker">$(Html $Display.kicker)</p>
  <h1 class="page-title">$(Html $Display.title)</h1>
  <p class="page-desc">$(Html $Display.description)</p>
</section>
<section class="next-read" aria-labelledby="collection-start">
  <div class="section-label">
    <span class="section-label-jp">&#36984;</span>
    <h2 class="section-label-en" id="collection-start">$(if (Is-Japanese) { "まず読む3本" } else { "Start With These" })</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="compact-grid">
    $($FeaturedCards -join "`n")
  </div>
</section>
$(New-AlgorithmNote $Algorithm)
<section class="listing-grid" aria-label="$(Html $Display.title) articles">
  $($Cards -join "`n")
</section>
$(New-Newsletter)
"@
  $JsonLd = New-CollectionStructuredData "CollectionPage" $Display.title $Display.description (Get-CollectionUrl $Collection.slug) $Items
  return New-Layout "$($Display.title) - TABI" $Display.description (Get-CollectionUrl $Collection.slug) $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
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
  $ListItems = @($PlanningGuides | ForEach-Object {
    $GuideDisplay = Get-PlanningDisplay $_
    [pscustomobject]@{ title = $GuideDisplay.title; url = Get-PlanningUrl $_.slug }
  })
  $GlossaryTitle = if (Is-Japanese) { "日本旅行の用語" } else { "Japan Travel Terms" }
  $ItineraryTitle = if (Is-Japanese) { "日数別ルート" } else { "Trip Length Routes" }
  $ListItems += [pscustomobject]@{ title = $GlossaryTitle; url = Href "/glossary.html" }
  $ListItems += [pscustomobject]@{ title = $ItineraryTitle; url = Href "/itineraries/index.html" }
  $JsonLd = New-CollectionStructuredData "CollectionPage" "TABI $PageName" $Description "/planning/index.html" $ListItems
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
  $HowToSteps = @()
  $StepPosition = 1
  foreach ($Block in @($GuideDisplay.blocks)) {
    foreach ($Item in @($Block.items)) {
      $HowToSteps += @{
        "@type" = "HowToStep"
        position = $StepPosition
        name = $Block.heading
        text = $Item
      }
      $StepPosition += 1
    }
  }
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
    inLanguage = $Script:CurrentLang
    workTranslation = New-LanguageAlternates (Get-PlanningUrl $Guide.slug)
    url = SiteUrl (Get-PlanningUrl $Guide.slug)
    step = $HowToSteps
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
    inLanguage = $Script:CurrentLang
    workTranslation = New-LanguageAlternates "/glossary.html"
    url = SiteUrl "/glossary.html"
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$PageName - TABI" $Description "/glossary.html" $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function New-SourcePolicyPage {
  $AllowedItems = Get-PolicyItems "allowedSourceTypes" "allowedSourceTypesJa"
  $DisallowedItems = Get-PolicyItems "disallowedSourceTypes" "disallowedSourceTypesJa"
  $RuleItems = Get-PolicyItems "reuseRules" "reuseRulesJa"
  $PrincipleItems = Get-PolicyItems "editorialPrinciples" "editorialPrinciplesJa"
  $CorrectionItems = Get-PolicyItems "correctionPolicy" "correctionPolicyJa"
  $Allowed = foreach ($Item in $AllowedItems) {
    '<li>{0}</li>' -f (Html $Item)
  }
  $Disallowed = foreach ($Item in $DisallowedItems) {
    '<li>{0}</li>' -f (Html $Item)
  }
  $Rules = foreach ($Item in $RuleItems) {
    '<li>{0}</li>' -f (Html $Item)
  }
  $Principles = foreach ($Item in $PrincipleItems) {
    '<li>{0}</li>' -f (Html $Item)
  }
  $Corrections = foreach ($Item in $CorrectionItems) {
    '<li>{0}</li>' -f (Html $Item)
  }
  $Title = if (Is-Japanese) { "TABIの情報出所ポリシー" } else { "TABI Source Policy" }
  $Desc = if (Is-Japanese) { "TABIが使う情報源、使わない情報源、引用・再利用・訂正・更新に関する編集ルールです。" } else { "How TABI chooses sources, avoids prohibited collection, and handles attribution, quotation, corrections, and volatile travel details." }
  $Intro = if (Is-Japanese) {
    "TABIは、AIスクレイピング禁止、引用禁止、転載禁止、権利不明、倫理的に問題のある媒体から情報を収集しません。外部情報を使う場合も、公式情報や一次情報を優先し、本文はTABIの編集判断で書きます。"
  } else {
    "TABI does not collect from media that prohibit AI scraping, quotation, republication, or reuse, and does not rely on sources with unclear rights or ethical risk. When outside information is needed, official and primary sources are preferred and TABI writes original editorial summaries."
  }
  $CorrectionSubject = [uri]::EscapeDataString("TABI correction or policy question")
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = $Title; url = "" }))
  <p class="page-kicker">$(Html (T "sourcePolicy"))</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Desc)</p>
</section>
<article class="guide-body source-policy-body">
  <section class="trust-summary-block">
    <span>$(Html (T "trustSummary"))</span>
    <p>$(Html (Get-TrustSummary))</p>
    <a class="tag-pill topic-pill" href="mailto:$($Config.contactEmail)?subject=$CorrectionSubject">$(Html (T "sendCorrection"))</a>
  </section>
  <section class="checklist-block">
    <h2>$(if (Is-Japanese) { "編集方針" } else { "Editorial stance" })</h2>
    <p>$(Html $Intro)</p>
  </section>
  <section class="checklist-block">
    <h2>$(Html (T "editorialPrinciples"))</h2>
    <ul>$($Principles -join "`n")</ul>
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
  <section class="checklist-block">
    <h2>$(Html (T "correctionPolicy"))</h2>
    <ul>$($Corrections -join "`n")</ul>
  </section>
</article>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "WebPage"
    name = $Title
    description = $Desc
    inLanguage = $Script:CurrentLang
    workTranslation = New-LanguageAlternates (Href "/source-policy.html")
    url = SiteUrl (Href "/source-policy.html")
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$Title - TABI" $Desc (Href "/source-policy.html") $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function New-PolicySection([string]$Heading, [string[]]$Items) {
  $List = foreach ($Item in $Items) {
    '<li>{0}</li>' -f (Html $Item)
  }
  return @"
  <section class="checklist-block">
    <h2>$(Html $Heading)</h2>
    <ul>$($List -join "`n")</ul>
  </section>
"@
}

function New-LegalPage {
  $Title = if (Is-Japanese) { "TABIの法務・ポリシーセンター" } else { "TABI Legal and Policy Center" }
  $Desc = if (Is-Japanese) { "免責事項、プライバシー、アフィリエイト、AI利用、情報出所、訂正窓口をまとめたTABIのポリシー入口です。" } else { "A single entry point for TABI's disclaimer, privacy, affiliate, AI, source, and corrections policies." }
  $CoverageHeading = if (Is-Japanese) { "このページで確認できること" } else { "What this covers" }
  $LastUpdatedLabel = if (Is-Japanese) { "最終更新" } else { "Last updated" }
  $Cards = @(
    [pscustomobject]@{ title = T "disclaimer"; kicker = if (Is-Japanese) { "旅行情報の限界" } else { "Travel information limits" }; body = if (Is-Japanese) { "価格、営業時間、交通、天候、安全、制度は変わるため、旅行前に公式情報で確認してください。" } else { "Prices, hours, transport, weather, safety rules, and regulations can change; confirm volatile details with official sources before travel." }; url = "/disclaimer.html" },
    [pscustomobject]@{ title = T "privacy"; kicker = if (Is-Japanese) { "データの扱い" } else { "Data practices" }; body = if (Is-Japanese) { "問い合わせ、ニュースレター、端末内保存、アクセス解析の有無など、TABIが扱う情報を説明します。" } else { "Explains contact, newsletter, local device storage, analytics status, and how TABI handles information." }; url = "/privacy.html" },
    [pscustomobject]@{ title = T "sourcePolicy"; kicker = if (Is-Japanese) { "情報出所" } else { "Sources and reuse" }; body = if (Is-Japanese) { "AIスクレイピング禁止、引用禁止、転載禁止、倫理的に問題のある情報源は使わない方針です。" } else { "TABI avoids prohibited AI scraping, quotation, republication, unclear-rights, and ethically risky sources." }; url = "/source-policy.html" }
  )
  $CardHtml = foreach ($Card in $Cards) {
    @"
<a class="utility-card" href="$(Href $Card.url)">
  <span>$(Html $Card.kicker)</span>
  <h2>$(Html $Card.title)</h2>
  <p>$(Html $Card.body)</p>
</a>
"@
  }
  $Updated = $Today.ToString("yyyy-MM-dd", $EnglishCulture)
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = T "legal"; url = "" }))
  <p class="page-kicker">$(Html (T "legal"))</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Desc)</p>
</section>
<section class="utility-grid" aria-label="$(Html (T "legal"))">
  $($CardHtml -join "`n")
</section>
<article class="guide-body source-policy-body">
  $(New-PolicySection $CoverageHeading @(
    $(if (Is-Japanese) { "TABIの記事は一般的な旅行・文化・買い物情報であり、法律、医療、金融、安全、登山、交通、査証、税務の専門助言ではありません。" } else { "TABI articles are general travel, culture, food, and shopping information, not legal, medical, financial, safety, mountaineering, transport, visa, or tax advice." }),
    $(if (Is-Japanese) { "個人情報、端末内保存、問い合わせメール、将来のアクセス解析に関する考え方を説明します。" } else { "The privacy policy explains personal information, local device storage, contact emails, and any future analytics choices." }),
    $(if (Is-Japanese) { "アフィリエイトや広告がある場合でも、編集判断を優先する方針を明記します。" } else { "Affiliate or advertising relationships, when present, are disclosed without changing TABI's editorial-first stance." })
  ))
  <section class="trust-summary-block">
    <span>$(Html $LastUpdatedLabel)</span>
    <p>$(Html $Updated)</p>
    <a class="tag-pill topic-pill" href="mailto:$($Config.contactEmail)">$(Html (T "contact"))</a>
  </section>
</article>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "WebPage"
    name = $Title
    description = $Desc
    inLanguage = $Script:CurrentLang
    workTranslation = New-LanguageAlternates (Href "/legal.html")
    url = SiteUrl (Href "/legal.html")
    dateModified = $Updated
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$Title - TABI" $Desc (Href "/legal.html") $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function New-PrivacyPage {
  $Title = if (Is-Japanese) { "TABI プライバシーポリシー" } else { "TABI Privacy Policy" }
  $Desc = if (Is-Japanese) { "TABIが扱う情報、利用目的、端末内保存、第三者サービス、問い合わせ方法を説明します。" } else { "How TABI handles information, local device storage, third-party services, contact emails, and privacy requests." }
  $Updated = $Today.ToString("yyyy-MM-dd", $EnglishCulture)
  $InfoHeading = if (Is-Japanese) { "収集する可能性のある情報" } else { "Information TABI may handle" }
  $UseHeading = if (Is-Japanese) { "利用目的" } else { "How information is used" }
  $SharingHeading = if (Is-Japanese) { "共有・保存・問い合わせ" } else { "Sharing, retention, and requests" }
  $LastUpdatedLabel = if (Is-Japanese) { "最終更新" } else { "Last updated" }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = T "legal"; url = "/legal.html" }, [pscustomobject]@{ label = T "privacy"; url = "" }))
  <p class="page-kicker">$(Html (T "privacy"))</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Desc)</p>
</section>
<article class="guide-body source-policy-body">
  $(New-PolicySection $InfoHeading @(
    $(if (Is-Japanese) { "お問い合わせや訂正依頼で送信された氏名、メールアドレス、本文。" } else { "Name, email address, and message content sent through correction or contact emails." }),
    $(if (Is-Japanese) { "ニュースレターを導入した場合のメールアドレスと配信設定。現時点で外部配信サービスを使う場合は、そのサービス名を明記します。" } else { "Email address and subscription settings if a newsletter provider is enabled; TABI should name any provider before use." }),
    $(if (Is-Japanese) { "最近見たページなど、ブラウザのlocalStorageに保存される端末内データ。" } else { "Device-local data stored in browser localStorage, such as recently viewed pages." })
  ))
  $(New-PolicySection $UseHeading @(
    $(if (Is-Japanese) { "問い合わせへの返信、訂正対応、サイト改善、スパムや不正利用の防止。" } else { "Responding to messages, handling corrections, improving the site, and preventing spam or misuse." }),
    $(if (Is-Japanese) { "localStorageの情報は端末内での表示改善に使い、TABIのサーバーへ送信する前提ではありません。" } else { "localStorage data is intended for on-device experience improvements and is not designed to be sent to TABI servers." }),
    $(if (Is-Japanese) { "アクセス解析を導入する場合は、このページで目的、提供者、無効化方法を更新します。" } else { "If analytics are introduced, this page should be updated with the purpose, provider, and opt-out details." })
  ))
  $(New-PolicySection $SharingHeading @(
    $(if (Is-Japanese) { "法令上必要な場合、または問い合わせ対応に必要なサービス提供者を除き、個人情報を販売しません。" } else { "TABI does not sell personal information and only shares it when legally required or needed to operate a requested service." }),
    $(if (Is-Japanese) { "問い合わせメールは、対応に必要な期間保存し、その後整理します。" } else { "Contact emails are retained for as long as needed to respond and maintain editorial records, then reviewed for deletion." }),
    $(if (Is-Japanese) { "確認、訂正、削除に関する相談は hello@tabi.guide へ送れます。" } else { "Privacy access, correction, or deletion questions can be sent to hello@tabi.guide." })
  ))
  <section class="trust-summary-block">
    <span>$(Html $LastUpdatedLabel)</span>
    <p>$(Html $Updated)</p>
  </section>
</article>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "PrivacyPolicy"
    name = $Title
    description = $Desc
    inLanguage = $Script:CurrentLang
    url = SiteUrl (Href "/privacy.html")
    dateModified = $Updated
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$Title - TABI" $Desc (Href "/privacy.html") $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function New-DisclaimerPage {
  $Title = if (Is-Japanese) { "TABI 免責事項・開示" } else { "TABI Disclaimer and Disclosures" }
  $Desc = if (Is-Japanese) { "旅行情報の変動、専門助言ではないこと、アフィリエイト、AI利用、外部リンクに関するTABIの開示です。" } else { "TABI's disclosure on changing travel details, non-professional advice, affiliate links, AI assistance, and external links." }
  $Updated = $Today.ToString("yyyy-MM-dd", $EnglishCulture)
  $TravelHeading = if (Is-Japanese) { "旅行情報について" } else { "Travel information" }
  $AffiliateHeading = if (Is-Japanese) { "アフィリエイト・広告開示" } else { "Affiliate and advertising disclosure" }
  $AiHeading = if (Is-Japanese) { "AI利用と外部リンク" } else { "AI assistance and external links" }
  $LastUpdatedLabel = if (Is-Japanese) { "最終更新" } else { "Last updated" }
  $Main = @"
<section class="page-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = T "legal"; url = "/legal.html" }, [pscustomobject]@{ label = T "disclaimer"; url = "" }))
  <p class="page-kicker">$(Html (T "disclaimer"))</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Desc)</p>
</section>
<article class="guide-body source-policy-body">
  $(New-PolicySection $TravelHeading @(
    $(if (Is-Japanese) { "価格、営業時間、営業日、交通、予約条件、免税、入場ルール、天候、安全情報は予告なく変わることがあります。" } else { "Prices, opening hours, schedules, transport, booking rules, tax-free rules, entry rules, weather, and safety information may change without notice." }),
    $(if (Is-Japanese) { "TABIは一般的な編集ガイドであり、旅行前には公式サイト、事業者、自治体、交通機関など一次情報を確認してください。" } else { "TABI is a general editorial guide; confirm volatile details with official sites, operators, local authorities, or transport providers before travel." }),
    $(if (Is-Japanese) { "登山、食品アレルギー、薬、法律、査証、税務、保険、安全判断は専門家や公式機関に確認してください。" } else { "For hiking, allergies, medicine, legal, visa, tax, insurance, and safety decisions, consult official bodies or qualified professionals." })
  ))
  $(New-PolicySection $AffiliateHeading @(
    $(if (Is-Japanese) { "買い物関連ページでは、将来的にアフィリエイトリンクや広告リンクを含む場合があります。" } else { "Shopping-related pages may include affiliate or advertising links in the future." }),
    $(if (Is-Japanese) { "収益が発生する場合でも、掲載判断、買い物メモ、注意点は編集上の有用性を優先します。" } else { "Even where revenue is possible, recommendations, buying notes, and cautions should remain editorial-first." }),
    $(if (Is-Japanese) { "PR、提供、報酬関係がある場合は、記事内または近接箇所で分かるように表示します。" } else { "Sponsored, gifted, or compensated relationships should be disclosed in or near the relevant content." })
  ))
  $(New-PolicySection $AiHeading @(
    $(if (Is-Japanese) { "TABIは下書き、整理、翻訳、校正、検証補助にAIを使う場合がありますが、公開前に編集確認を行う前提です。" } else { "TABI may use AI for drafting support, organization, translation, proofreading, and verification support, with editorial review before publication." }),
    $(if (Is-Japanese) { "AIスクレイピング、引用、転載、再利用を禁じる情報源や、倫理的に問題のある情報源は利用しません。" } else { "TABI does not use sources that prohibit AI scraping, quotation, republication, or reuse, or sources with ethical concerns." }),
    $(if (Is-Japanese) { "外部リンク先の内容、販売、価格、在庫、プライバシー対応についてTABIは管理していません。" } else { "TABI does not control external sites' content, sales terms, prices, stock, or privacy practices." })
  ))
  <section class="trust-summary-block">
    <span>$(Html $LastUpdatedLabel)</span>
    <p>$(Html $Updated)</p>
    <a class="tag-pill topic-pill" href="$(Href "/source-policy.html")">$(Html (T "sourcePolicy"))</a>
  </section>
</article>
$(New-Newsletter)
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "WebPage"
    name = $Title
    description = $Desc
    inLanguage = $Script:CurrentLang
    workTranslation = New-LanguageAlternates (Href "/disclaimer.html")
    url = SiteUrl (Href "/disclaimer.html")
    dateModified = $Updated
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout "$Title - TABI" $Desc (Href "/disclaimer.html") $Main "" "/assets/images/japanese-goods.png" $JsonLd
}

function ConvertTo-Rfc3339([string]$DateValue) {
  $Date = [datetime]::ParseExact($DateValue, "yyyy-MM-dd", $EnglishCulture)
  return $Date.ToString("yyyy-MM-ddT00:00:00+09:00", $EnglishCulture)
}

function ConvertTo-RssDate([string]$DateValue) {
  $Date = [datetime]::ParseExact($DateValue, "yyyy-MM-dd", $EnglishCulture)
  return $Date.ToUniversalTime().ToString("r", $EnglishCulture)
}

function New-RssFeed {
  $Latest = @($Articles | Sort-Object publishedAt -Descending | Select-Object -First 20)
  $LatestPublishedAt = ($Latest | Select-Object -First 1).publishedAt
  $Items = foreach ($Article in $Latest) {
    @"
  <item>
    <title>$(Html $Article.title)</title>
    <link>$(Html (SiteUrl (Get-ArticleUrl $Article)))</link>
    <guid>$(Html (SiteUrl (Get-ArticleUrl $Article)))</guid>
    <pubDate>$(ConvertTo-RssDate $Article.publishedAt)</pubDate>
    <description>$(Html $Article.summary)</description>
    <category>$(Html (Get-CategoryLabel $Article.category))</category>
  </item>
"@
  }
  return @"
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
  <title>$(Html (Get-SiteTitle))</title>
  <link>$(Html (SiteUrl (Href "/")))</link>
  <description>$(Html (Get-SiteDescription))</description>
  <language>$Script:CurrentLang</language>
  <lastBuildDate>$(ConvertTo-RssDate $LatestPublishedAt)</lastBuildDate>
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
    title = Get-SiteTitle
    home_page_url = SiteUrl (Href "/")
    feed_url = SiteUrl (Href "/feed.json")
    description = Get-SiteDescription
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
    icons = @(
      [pscustomobject]@{ src = "/assets/images/kyoto-shrine-hero-640.webp"; sizes = "640x640"; type = "image/webp"; purpose = "any" },
      [pscustomobject]@{ src = "/assets/images/kyoto-shrine-hero-1024.webp"; sizes = "1024x1024"; type = "image/webp"; purpose = "any" }
    )
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
    $TopicDisplay = Get-TopicDisplay $Topic
    '<a class="tag-pill topic-pill" href="{0}">{1}</a>' -f (Get-TopicUrl $Topic.slug), (Html $TopicDisplay.title)
  }
  $Title = if (Is-Japanese) { "この道は地図から外れてしまいました。" } else { "This path has wandered off the map." }
  $Description = if (Is-Japanese) { "テーマ、検索、またはTABIの記事スコアで選ばれたおすすめガイドから戻れます。" } else { "Try a topic path, search TABI, or start with one of the strongest guides selected by the local article score." }
  $SearchLabel = if (Is-Japanese) { "TABIを検索" } else { "Search TABI" }
  $PicksLabel = if (Is-Japanese) { "おすすめガイド" } else { "Recommended Guides" }
  $PageTitle = if (Is-Japanese) { "ページが見つかりません - TABI" } else { "Page Not Found - TABI" }
  $Main = @"
<section class="page-hero not-found-hero">
  $(New-Breadcrumbs @([pscustomobject]@{ label = "Home"; url = "/" }, [pscustomobject]@{ label = "404"; url = "" }))
  <p class="page-kicker">404</p>
  <h1 class="page-title">$(Html $Title)</h1>
  <p class="page-desc">$(Html $Description)</p>
  <div class="hero-actions light-actions">
    <a class="button" href="$(Href "/")">$(if (Is-Japanese) { "ホームへ戻る" } else { "Back to Home" })</a>
    <button class="button secondary" type="button" aria-expanded="false" aria-controls="site-search-panel" data-search-toggle>$(Html $SearchLabel)</button>
  </div>
  <div class="tag-list">
    $($TopicCards -join "`n")
  </div>
</section>
<section class="next-read" aria-labelledby="not-found-picks">
  <div class="section-label">
    <span class="section-label-jp">&#22320;</span>
    <h2 class="section-label-en" id="not-found-picks">$(Html $PicksLabel)</h2>
    <div class="section-label-line"></div>
  </div>
  <div class="compact-grid">
    $($PickCards -join "`n")
  </div>
</section>
"@
  $JsonLd = @{
    "@context" = "https://schema.org"
    "@type" = "WebPage"
    name = $PageTitle
    description = $Description
    inLanguage = $Script:CurrentLang
    isPartOf = @{ "@type" = "WebSite"; name = $Config.siteName; url = $Config.siteUrl }
    workTranslation = New-LanguageAlternates "/404.html"
    url = SiteUrl (Href "/404.html")
  } | ConvertTo-Json -Depth 6 -Compress
  return New-Layout $PageTitle $Description "/404.html" $Main "" "/assets/images/kyoto-shrine-hero.png" $JsonLd
}

function New-Sitemap {
  $OriginalLang = $Script:CurrentLang
  $Urls = @()
  foreach ($Lang in @("en", "ja")) {
    Set-RenderLanguage $Lang
    $Urls += [pscustomobject]@{ loc = Href "/"; basePath = "/"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += foreach ($Category in $Config.categories) { [pscustomobject]@{ loc = Get-CategoryUrl $Category.slug; basePath = "/categories/$($Category.slug).html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += foreach ($Topic in $TopicClusters) { [pscustomobject]@{ loc = Get-TopicUrl $Topic.slug; basePath = "/topics/$($Topic.slug).html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += [pscustomobject]@{ loc = Href "/genres/index.html"; basePath = "/genres/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += foreach ($Genre in $SubcategoryDefinitions) { [pscustomobject]@{ loc = Get-GenreUrl $Genre.slug; basePath = "/genres/$($Genre.slug).html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += [pscustomobject]@{ loc = Href "/areas/index.html"; basePath = "/areas/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += foreach ($Area in $AreaClusters) { [pscustomobject]@{ loc = Get-AreaUrl $Area.slug; basePath = "/areas/$($Area.slug).html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += [pscustomobject]@{ loc = Href "/itineraries/index.html"; basePath = "/itineraries/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += foreach ($Plan in $ItineraryPlans) { [pscustomobject]@{ loc = Get-ItineraryUrl $Plan.slug; basePath = "/itineraries/$($Plan.slug).html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += [pscustomobject]@{ loc = Href "/collections/index.html"; basePath = "/collections/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += foreach ($Collection in $CollectionDefinitions) { [pscustomobject]@{ loc = Get-CollectionUrl $Collection.slug; basePath = "/collections/$($Collection.slug).html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += [pscustomobject]@{ loc = Href "/planning/index.html"; basePath = "/planning/index.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += foreach ($Guide in $PlanningGuides) { [pscustomobject]@{ loc = Get-PlanningUrl $Guide.slug; basePath = "/planning/$($Guide.slug).html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += [pscustomobject]@{ loc = Href "/glossary.html"; basePath = "/glossary.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += [pscustomobject]@{ loc = Href "/legal.html"; basePath = "/legal.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += [pscustomobject]@{ loc = Href "/privacy.html"; basePath = "/privacy.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += [pscustomobject]@{ loc = Href "/disclaimer.html"; basePath = "/disclaimer.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Urls += [pscustomobject]@{ loc = Href "/source-policy.html"; basePath = "/source-policy.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) }
    $Tags = @($Articles | ForEach-Object { $_.tags } | Sort-Object -Unique)
    $Urls += foreach ($Tag in $Tags) { [pscustomobject]@{ loc = Get-TagUrl $Tag; basePath = "/tags/$Tag.html"; lastmod = $Today.ToString("yyyy-MM-dd", $EnglishCulture) } }
    $Urls += foreach ($Article in $Articles) { [pscustomobject]@{ loc = Get-ArticleUrl $Article; basePath = "/articles/$($Article.id).html"; lastmod = $Article.publishedAt } }
  }
  Set-RenderLanguage $OriginalLang
  $Items = foreach ($Url in $Urls) {
    $Priority = if ($Url.basePath -eq "/") { "1.0" } elseif ($Url.basePath -like "/articles/*") { "0.8" } else { "0.6" }
    $ChangeFreq = if ($Url.basePath -like "/articles/*") { "monthly" } else { "weekly" }
    @"
  <url>
    <loc>$(Html (SiteUrl $Url.loc))</loc>
    <xhtml:link rel="alternate" hreflang="en" href="$(Html (SiteUrl (LocalizePath $Url.basePath "en")))" />
    <xhtml:link rel="alternate" hreflang="ja" href="$(Html (SiteUrl (LocalizePath $Url.basePath "ja")))" />
    <xhtml:link rel="alternate" hreflang="x-default" href="$(Html (SiteUrl (LocalizePath $Url.basePath "en")))" />
    <lastmod>$($Url.lastmod)</lastmod>
    <changefreq>$ChangeFreq</changefreq>
    <priority>$Priority</priority>
  </url>
"@
  }
  return @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
$($Items -join "`n")
</urlset>
"@
}

function New-ImageSitemap {
  $OriginalLang = $Script:CurrentLang
  $Items = @()
  foreach ($Lang in @("en", "ja")) {
    Set-RenderLanguage $Lang
    $Items += foreach ($Article in $Articles) {
      @"
  <url>
    <loc>$(Html (SiteUrl (Get-ArticleUrl $Article)))</loc>
    <image:image>
      <image:loc>$(Html (SiteUrl $Article.image))</image:loc>
      <image:title>$(Html $Article.title)</image:title>
      <image:caption>$(Html $Article.imageAlt)</image:caption>
    </image:image>
  </url>
"@
    }
  }
  Set-RenderLanguage $OriginalLang
  return @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">
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
  Write-Page (Get-OutputPath "genres/index.html") (New-GenreIndexPage)
  foreach ($Genre in $SubcategoryDefinitions) {
    Write-Page (Get-OutputPath "genres/$($Genre.slug).html") (New-GenrePage $Genre)
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
  Write-Page (Get-OutputPath "collections/index.html") (New-CollectionIndexPage)
  foreach ($Collection in $CollectionDefinitions) {
    Write-Page (Get-OutputPath "collections/$($Collection.slug).html") (New-CollectionPage $Collection)
  }
  Write-Page (Get-OutputPath "planning/index.html") (New-PlanningIndexPage)
  foreach ($Guide in $PlanningGuides) {
    Write-Page (Get-OutputPath "planning/$($Guide.slug).html") (New-PlanningGuidePage $Guide)
  }
  Write-Page (Get-OutputPath "glossary.html") (New-GlossaryPage)
  Write-Page (Get-OutputPath "legal.html") (New-LegalPage)
  Write-Page (Get-OutputPath "privacy.html") (New-PrivacyPage)
  Write-Page (Get-OutputPath "disclaimer.html") (New-DisclaimerPage)
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
Write-Page "image-sitemap.xml" (New-ImageSitemap)
Write-Page "robots.txt" "User-agent: *`nAllow: /`nSitemap: $(SiteUrl '/sitemap.xml')`nSitemap: $(SiteUrl '/image-sitemap.xml')`n"
Write-Page "site.webmanifest" (New-WebManifest)
Write-Page "llms.txt" (New-LlmsText)

Write-Host "Generated localized TABI site in English and Japanese: $($BaseArticles.Count) articles, $($Config.categories.Count) categories, $($TopicClusters.Count) topics, $($AreaClusters.Count) areas, and $($ItineraryPlans.Count) itineraries per language, with $($SubcategoryDefinitions.Count) genre pages."
