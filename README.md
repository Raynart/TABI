# TABI - Discover Japan

> Your guide to the real Japan: travel, culture, food, hidden places, and the things worth bringing home.

TABI is an English-language static curation site for international visitors and Japan enthusiasts.

## Stack

- Static HTML
- PowerShell site generation
- Vanilla CSS and JavaScript
- Netlify hosting

## Structure

```text
.
├── articles/          Generated article pages
├── assets/images/     Site image assets
├── categories/        Generated category pages
├── scripts/           PowerShell generation scripts
├── tags/              Generated tag pages
├── articles.json      Source article data
├── index.html         Generated top page
├── script.js          Frontend interactions
├── site.config.json   Site-wide config
├── styles.css         Design system
└── tabi-mockup.html   Original visual mockup reference
```

## Generate Site

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\generate-site.ps1"
```

The generator reads `articles.json` and `site.config.json`, then writes the top page, article pages, category pages, tag pages, `sitemap.xml`, and `robots.txt`.

## Content Model

Each article includes a slug, title, summary, category, tags, publication date, reading time, affiliate flag, image metadata, and short editorial sections. The supported category slugs are:

- `travel-guide`
- `culture`
- `food`
- `things-to-buy`
- `hidden-gems`

## Deployment

Netlify publishes the repository root. Generated HTML files should be committed after running the generator.
