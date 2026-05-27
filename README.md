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
content/articles/      English article source data split by category
content/articles.ja/   Japanese article overrides split by category
site-data.json         Topics, areas, itineraries, planning guides, glossary terms
static.ja.json         Japanese translations for static site-data content
content-policy.json    Source policy, reuse rules, and article source metadata defaults
site.config.json       Site name, URL, navigation, and category config
schemas/               JSON schema references for content files
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
legal.html             English legal and policy center
ja/legal.html          Japanese legal and policy center
privacy.html           English privacy policy
ja/privacy.html        Japanese privacy policy
disclaimer.html        English disclaimer and disclosures
ja/disclaimer.html     Japanese disclaimer and disclosures
feed.xml               English RSS feed
ja/feed.xml            Japanese RSS feed
feed.json              English JSON feed
ja/feed.json           Japanese JSON feed
sitemap.xml            Bilingual sitemap with hreflang alternates
image-sitemap.xml      Image sitemap for article hero images
maintenance-report.json Machine-readable local audit report
robots.txt             Search crawler rules
llms.txt               LLM-readable site summary
editorial-dashboard.html  Noindex static editorial maintenance dashboard
```

## Generate Site

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\generate-site.ps1"
```

Run the generator after editing any JSON content file or generation template. Generated HTML, feeds, sitemap, `robots.txt`, and `llms.txt` should be committed.

## Validate Site

```powershell
node ".\scripts\validate-site.mjs"
```

The validation script checks generated HTML links, anchors, assets, `hreflang`, JSON-LD, feeds, sitemap alternates, and frontend JavaScript syntax.

## Maintenance Check

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\check-site.ps1"
```

The maintenance check regenerates the site, runs validation, then runs `scripts/site-health.mjs` and `scripts/audit-ops.mjs`. The health check catches duplicate canonicals, missing generated files, sitemap count drift, stale article source dates, category mismatches, orphaned Japanese translations, and basic CSS/JS/HTML size budgets. The operational audit adds numbered checks 36-100 across freshness calendars, i18n parity, media, social metadata, JSON-LD, feeds, robots, deployment headers, page fundamentals, accessibility landmarks, hreflang, sitemap targets, and article data chronology.

Equivalent npm shortcuts are also available:

```powershell
npm run generate
npm run validate
npm run validate:data
npm run health
npm run audit:ops
npm run report
npm run split:content
npm run new:article -- article-slug travel-guide
npm run audit:content
npm run audit:i18n
npm run check
npm run visual
npm run serve
```

`npm run report` prints a compact maintenance report for review. `npm run visual` captures desktop and mobile screenshots for representative English and Japanese pages into `screenshots/visual-check/`; run `npm run serve` first if a local server is not already running.
`npm run split:content` refreshes the category-split article files from the canonical JSON files. `npm run new:article` creates a local draft article template in `content/articles/`.

## Editorial Algorithms

The generator includes local, static algorithms that do not require external services:

- Article scoring from freshness, seasonality, content quality, category priority, and editorial weight
- Related-article selection from shared tags, category fit, freshness, seasonality, and quality
- Topic cluster pages for internal-link hubs
- Area, itinerary, planning, category, and tag pages generated from local data
- Weighted client-side search metadata
- Editorial signal panels on article pages
- Article pathway blocks for related topic, area, itinerary, and glossary links
- Bilingual RSS, JSON feed, sitemap, and `hreflang`

## Source Policy

TABI avoids sources that prohibit AI scraping, automated collection, quotation, republication, or reuse. It also excludes paywalled, private, leaked, scraped, rights-unclear, or ethically risky material.

The source rules live in `content-policy.json` and render to:

- `source-policy.html`
- `ja/source-policy.html`
- `legal.html`, `privacy.html`, `disclaimer.html`
- `ja/legal.html`, `ja/privacy.html`, `ja/disclaimer.html`
- Article source panels

Volatile details such as hours, prices, closures, and transport rules should be confirmed with official sources before travel.

Each article also carries explicit source metadata fields:

- `sourcePolicy`
- `verificationLevel`
- `lastChecked`
- `sourceNote`

## Frontend Behavior

`script.js` powers:

- Search modal
- Weighted local search results
- Newsletter form validation and status messages
- English/Japanese UI messages based on the page language
- Recently viewed local navigation, stored only in the reader's browser

## Deployment

Netlify publishes the repository root. The site is fully static, so deployment only needs the generated files committed to the repository.

Netlify security and cache headers live in `netlify.toml`. HTML is revalidated on each request, long-lived image assets are immutable, and feed/sitemap files use short public cache windows.
