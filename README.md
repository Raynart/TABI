# TABI - Discover Japan

TABI is a bilingual static editorial site for Japan travel, culture, food, hidden places, and thoughtful things to bring home.

The site is generated locally and committed as static HTML. It does not require a CMS, database, external search service, booking integration, or live data feed.

## Stack

- Static HTML
- PowerShell site generation
- Vanilla CSS and JavaScript
- JSON content files
- Netlify hosting

## Content Files

```text
articles.json          English article source data
articles.ja.json       Japanese article translations
site-data.json         Topics, areas, itineraries, planning guides, glossary terms
static.ja.json         Japanese translations for static site-data content
content-policy.json    Source policy, reuse rules, and article source metadata defaults
site.config.json       Site name, URL, navigation, and category config
```

## Generated Output

```text
index.html             English home page
ja/index.html          Japanese home page
articles/              English article pages
ja/articles/           Japanese article pages
categories/            English category pages
ja/categories/         Japanese category pages
topics/                English topic hubs
ja/topics/             Japanese topic hubs
areas/                 English area guides
ja/areas/              Japanese area guides
itineraries/           English itinerary pages
ja/itineraries/        Japanese itinerary pages
planning/              English planning tools
ja/planning/           Japanese planning tools
tags/                  English tag pages
ja/tags/               Japanese tag pages
feed.xml               English RSS feed
ja/feed.xml            Japanese RSS feed
feed.json              English JSON feed
ja/feed.json           Japanese JSON feed
sitemap.xml            Bilingual sitemap with hreflang alternates
robots.txt             Search crawler rules
llms.txt               LLM-readable site summary
```

## Generate Site

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\generate-site.ps1"
```

Run the generator after editing any JSON content file or generation template. Generated HTML, feeds, sitemap, `robots.txt`, and `llms.txt` should be committed.

## Editorial Algorithms

The generator includes local, static algorithms that do not require external services:

- Article scoring from freshness, seasonality, content quality, category priority, and editorial weight
- Related-article selection from shared tags, category fit, freshness, seasonality, and quality
- Topic cluster pages for internal-link hubs
- Area, itinerary, planning, category, and tag pages generated from local data
- Weighted client-side search metadata
- Editorial signal panels on article pages
- Bilingual RSS, JSON feed, sitemap, and `hreflang`

## Source Policy

TABI avoids sources that prohibit AI scraping, automated collection, quotation, republication, or reuse. It also excludes paywalled, private, leaked, scraped, rights-unclear, or ethically risky material.

The source rules live in `content-policy.json` and render to:

- `source-policy.html`
- `ja/source-policy.html`
- Article source panels

Volatile details such as hours, prices, closures, and transport rules should be confirmed with official sources before travel.

## Frontend Behavior

`script.js` powers:

- Search modal
- Weighted local search results
- Newsletter form validation and status messages
- English/Japanese UI messages based on the page language

## Deployment

Netlify publishes the repository root. The site is fully static, so deployment only needs the generated files committed to the repository.
