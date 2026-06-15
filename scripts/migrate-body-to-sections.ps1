# migrate-body-to-sections.ps1
# One-time migration: converts body[] paragraphs to sections[{heading, paragraphs}]
# Run once, then delete this file.

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

# Section heading map: articleId -> ordered headings (one per paragraph)
$headingMap = @{
    "ryokan-first-time-guide" = @(
        "Check-in, checkout, and why timing matters",
        "Shoes, slippers, and one rule about the toilet",
        "Your room",
        "The onsen",
        "Kaiseki dinner",
        "Breakfast",
        "What it costs",
        "On language"
    )
    "japan-winter-travel-guide" = @(
        "Why even consider January",
        "The actual weather",
        "Where the crowds went",
        "New Year rituals",
        "Onsen towns in winter",
        "Skiing in Hokkaido",
        "Flights, hotels, and prices",
        "What winter reveals"
    )
    "japan-convenience-store-guide" = @(
        "This is not convenience store food",
        "What konbini do beyond food",
        "Onigiri",
        "The egg salad sandwich",
        "Hot food",
        "Drinks",
        "Budget and how to order"
    )
    "kissaten-tokyo-coffee-culture" = @(
        "What kissaten means",
        "Why they are invisible to visitors",
        "Where to find them",
        "What you are drinking",
        "The morning set",
        "How to sit properly",
        "Three worth knowing in Tokyo",
        "What they represent"
    )
    "kanazawa-japan-guide" = @(
        "Why Kanazawa is overlooked",
        "Getting there",
        "Kenroku-en",
        "Higashi Chaya",
        "The food",
        "Gold leaf and contemporary art",
        "Where to stay",
        "What Kanazawa has that Kyoto lost"
    )
    "tsukiji-outer-market-guide" = @(
        "What stayed and what moved",
        "When to arrive",
        "Sushi",
        "Tamagoyaki",
        "Ikura on rice",
        "What to skip",
        "The knife shops",
        "Getting there"
    )
    "izakaya-guide-first-timers" = @(
        "What an izakaya is",
        "Ordering from the menu",
        "The opening round",
        "Otoshi: the charge you did not order",
        "What to eat",
        "Shochu and chuhai",
        "Getting the bill",
        "The golden rule"
    )
    "ic-card-japan-guide" = @(
        "Get one at the airport",
        "What an IC card is",
        "Suica or ICOCA",
        "Loading money",
        "How tapping works",
        "Vending machines",
        "Apple Pay and Google Pay",
        "When you leave Japan",
        "Why it matters"
    )
    "japanese-whisky-what-to-buy" = @(
        "The golden age and the scarcity",
        "Why availability is slowly improving",
        "What is genuinely worth buying",
        "The highball format",
        "Where to buy",
        "On labeling",
        "What you will actually find",
        "One bottle to look for"
    )
    "naoshima-art-island-guide" = @(
        "What Naoshima is",
        "How it became what it is",
        "The Chichu Art Museum",
        "The Art House Project",
        "Getting there",
        "Stay overnight",
        "On bicycles",
        "The right mindset"
    )
    "shinkansen-guide" = @(
        "The cost",
        "Break-even: when the pass wins",
        "Nozomi vs Hikari",
        "What the pass covers that people miss",
        "Alternatives to the JR Pass",
        "If you have decided to buy one"
    )
    "tokyo-neighborhoods-guide" = @(
        "Why neighborhood choice matters",
        "Shinjuku",
        "Asakusa",
        "Shibuya",
        "Ginza",
        "Ueno",
        "The general rule"
    )
    "ramen-regional-guide" = @(
        "Four styles, not one",
        "Hakata tonkotsu",
        "Tokyo shoyu",
        "Sapporo miso",
        "How to order"
    )
    "sumo-tournament-guide" = @(
        "Tournament schedule and cities",
        "Getting tickets",
        "What you are watching",
        "When to arrive",
        "Food and drink at Kokugikan",
        "What surprises you in person"
    )
    "japanese-onsen-etiquette" = @(
        "The rule everyone needs to know",
        "What you bring in",
        "Tattoos: the real policy",
        "Temperature",
        "Rotating between baths",
        "After the onsen"
    )
    "donki-shopping-guide" = @(
        "What Don Quijote is",
        "Skincare and cosmetics",
        "Japanese snacks",
        "Electronics and gadgets",
        "What to skip",
        "Navigation"
    )
    "hiroshima-guide" = @(
        "The Peace Memorial Museum",
        "Hiroshima beyond the park",
        "Hiroshima okonomiyaki",
        "Miyajima Island",
        "How long to stay"
    )
    "autumn-foliage-japan" = @(
        "When koyo happens where",
        "Kyoto in November",
        "Nikko: the underrated option",
        "The Japanese Alps",
        "Rain and overcast days",
        "The practical window"
    )
    "beppu-onsen-guide" = @(
        "What Beppu is",
        "The Hell Tour",
        "Bathing options",
        "Sand bathing",
        "Getting there and where to stay"
    )
    "japanese-stationery-guide" = @(
        "The Pilot Hi-Tec-C case for Japanese stationery",
        "The main chains",
        "Hobonichi planners and Midori notebooks",
        "MT masking tape",
        "Pens worth buying",
        "The suitcase argument"
    )
    "sushi-counter-guide" = @(
        "Counter sushi vs conveyor belt",
        "Three rules",
        "What to order",
        "Ginger and wasabi",
        "Budget guidance"
    )
    "nara-day-trip" = @(
        "The deer",
        "Todai-ji",
        "Kasuga Taisha",
        "Naramachi",
        "Getting there and timing"
    )
    "golden-week-avoid" = @(
        "What Golden Week is",
        "What actually happens",
        "If you are already booked",
        "Shinkansen strategy",
        "When to go instead"
    )
    "japanese-sake-guide" = @(
        "The two main variables",
        "Classifications that matter",
        "What to actually buy",
        "Nigori sake",
        "Where to buy",
        "Storage and shelf life"
    )
    "hokkaido-summer-guide" = @(
        "The climate case",
        "Lavender fields in Furano",
        "Biei and the Panorama Road",
        "Sapporo",
        "Daisetsuzan National Park",
        "Getting there"
    )
    "koenji-shimokitazawa" = @(
        "What these neighborhoods are",
        "Koenji: the vintage ecosystem",
        "Koenji: bars and izakaya",
        "Shimokitazawa: live music",
        "The Sunday market"
    )
    "wagyu-guide" = @(
        "What wagyu actually is",
        "Kobe, Matsusaka, and Omi",
        "Formats and prices",
        "The accessible option",
        "The one thing worth knowing"
    )
    "japanese-vending-machines" = @(
        "The density",
        "What is for sale",
        "Specialty machines",
        "Pricing",
        "IC card payment",
        "The cultural point"
    )
    "tokyo-day-trips" = @(
        "The problem with the usual recommendations",
        "Kawagoe",
        "Chichibu",
        "Izu Peninsula",
        "Mashiko"
    )
    "japanese-gift-omiyage" = @(
        "What omiyage is",
        "What makes good omiyage",
        "Format matters",
        "What to bring home",
        "Where to buy"
    )
}

$raw      = Get-Content "$root\articles.json" -Raw -Encoding UTF8
$articles = $raw | ConvertFrom-Json

$converted = 0
foreach ($a in $articles) {
    if (-not $a.body) { continue }
    if (-not $headingMap.ContainsKey($a.id)) {
        Write-Warning "No heading map for $($a.id) — skipping"
        continue
    }
    $headings = $headingMap[$a.id]
    $sections = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $a.body.Count; $i++) {
        $h   = if ($i -lt $headings.Count) { $headings[$i] } else { '' }
        $sec = [PSCustomObject]@{ heading = $h; paragraphs = @($a.body[$i]) }
        $sections.Add($sec)
    }
    $a | Add-Member -NotePropertyName 'sections' -NotePropertyValue ($sections.ToArray()) -Force
    $a.PSObject.Properties.Remove('body')
    $converted++
}

$json = $articles | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText("$root\articles.json", $json, [System.Text.Encoding]::UTF8)
Write-Host "Done. Converted $converted articles."
