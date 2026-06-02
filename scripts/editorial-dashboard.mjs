import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadArticleData } from "./lib/content-loader.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const { articles, japaneseArticles } = await loadArticleData(root);
const siteData = JSON.parse(await readFile(path.join(root, "site-data.json"), "utf8"));
const contentPlan = JSON.parse(await readFile(path.join(root, "content-plan.json"), "utf8"));
const japaneseById = new Map(japaneseArticles.map((article) => [article.id, article]));
const subcategoryBySlug = new Map((siteData.subcategories || []).map((subcategory) => [subcategory.slug, subcategory]));
const planItems = contentPlan.items || [];
const planItemsById = new Map(planItems.map((item) => [item.id, item]));

const regionHints = [
  { slug: "tokyo", label: "Tokyo" },
  { slug: "osaka", label: "Osaka" },
  { slug: "kanagawa", label: "Kanagawa" },
  { slug: "chiba", label: "Chiba" },
  { slug: "saitama", label: "Saitama" }
];

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function daysSince(dateText) {
  const date = new Date(`${dateText}T00:00:00+09:00`);
  return Math.floor((Date.now() - date.getTime()) / 86_400_000);
}

function countBy(items, getKey) {
  const counts = new Map();
  for (const item of items) {
    const key = getKey(item) || "(none)";
    counts.set(key, (counts.get(key) || 0) + 1);
  }
  return [...counts.entries()]
    .map(([key, count]) => ({ key, count }))
    .sort((a, b) => b.count - a.count || a.key.localeCompare(b.key));
}

function articleRegion(article) {
  const planItem = planItemsById.get(article.id);
  if (planItem?.area) return planItem.area;
  const haystack = [
    article.id,
    article.title,
    article.summary,
    ...(article.tags || []),
    ...(article.searchAliases || [])
  ].join(" ").toLowerCase();
  return regionHints.find((region) => haystack.includes(region.slug))?.slug || "unassigned";
}

function issuesFor(article) {
  const issues = [];
  if (!japaneseById.has(article.id)) issues.push("Missing JA");
  if (!article.sourceUrls?.length) issues.push("Missing source URLs");
  if (!article.sourceNote?.trim()) issues.push("Missing source note");
  if (!article.subcategory) issues.push("Missing genre");
  if (!article.image) issues.push("Missing image");
  if (daysSince(article.lastChecked) > 120) issues.push("Review overdue");
  return issues;
}

function statusFor(article) {
  const issues = issuesFor(article);
  if (issues.length) return issues.join(", ");
  if (article.sourceNote.includes("Created from TABI-owned editorial drafts")) return "Needs source detail";
  return "OK";
}

function toRows(items, columns) {
  return items.map((item) => `<tr>${columns.map((column) => `<td>${escapeHtml(column(item))}</td>`).join("")}</tr>`).join("\n");
}

function renderCountTable(items, labelFor = (key) => key) {
  return `<table>
    <thead><tr><th>Name</th><th>Count</th></tr></thead>
    <tbody>${toRows(items, [(item) => labelFor(item.key), (item) => item.count])}</tbody>
  </table>`;
}

const publishedRegions = countBy(articles, articleRegion);
const publishedCategories = countBy(articles, (article) => article.category);
const publishedSubcategories = countBy(articles, (article) => article.subcategory);
const plannedRegions = countBy(planItems, (item) => item.area);
const plannedCategories = countBy(planItems, (item) => item.category);
const plannedSubcategories = countBy(planItems, (item) => item.subcategory);
const issueRows = articles
  .map((article) => ({ article, issues: issuesFor(article) }))
  .filter((item) => item.issues.length)
  .sort((a, b) => b.issues.length - a.issues.length || a.article.id.localeCompare(b.article.id));
const duplicateImages = countBy(articles, (article) => article.image).filter((item) => item.key !== "(none)" && item.count > 1);
const thinSubcategories = (siteData.subcategories || [])
  .map((subcategory) => ({
    key: subcategory.slug,
    title: subcategory.title || subcategory.slug,
    count: publishedSubcategories.find((item) => item.key === subcategory.slug)?.count || 0,
    category: subcategory.category
  }))
  .filter((item) => item.count < 3)
  .sort((a, b) => a.count - b.count || a.key.localeCompare(b.key));
const planJapaneseTitleMojibake = planItems.filter((item) => (item.titleJa || "").includes("?"));
const articlesNotInPlan = articles.filter((article) => !planItemsById.has(article.id));
const imageCounts = new Map(duplicateImages.map((item) => [item.key, item.count]));

const rows = articles.map((article) => {
  const ja = japaneseById.get(article.id);
  const duplicateImageCount = imageCounts.get(article.image) || 1;
  return `<tr>
    <td><a href="/articles/${escapeHtml(article.id)}.html">${escapeHtml(article.title)}</a></td>
    <td>${escapeHtml(article.category)}</td>
    <td>${escapeHtml(article.subcategory)}</td>
    <td>${escapeHtml(articleRegion(article))}</td>
    <td>${escapeHtml(article.lastChecked)}</td>
    <td>${escapeHtml(statusFor(article))}</td>
    <td>${ja ? "Yes" : "Missing"}</td>
    <td>${escapeHtml(article.sourceUrls?.length || 0)}</td>
    <td>${escapeHtml(duplicateImageCount)}</td>
    <td>${escapeHtml(article.sections?.length || 0)}</td>
  </tr>`;
}).join("\n");

const report = {
  generatedAt: new Date().toISOString(),
  published: {
    english: articles.length,
    japanese: japaneseArticles.length,
    categories: publishedCategories,
    subcategories: publishedSubcategories,
    regions: publishedRegions
  },
  plan: {
    targetPublishedArticles: contentPlan.targetPublishedArticles,
    plannedNewArticles: contentPlan.plannedNewArticles,
    existingPublishedArticlesIncluded: contentPlan.existingPublishedArticlesIncluded,
    items: planItems.length,
    statuses: countBy(planItems, (item) => item.status),
    categories: plannedCategories,
    subcategories: plannedSubcategories,
    regions: plannedRegions
  },
  quality: {
    issueArticles: issueRows.map(({ article, issues }) => ({ id: article.id, title: article.title, issues })),
    duplicateImages,
    thinSubcategories,
    planJapaneseTitleMojibake: planJapaneseTitleMojibake.length,
    articlesNotInPlan: articlesNotInPlan.map((article) => article.id)
  }
};

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="robots" content="noindex, nofollow">
  <title>TABI Editorial Dashboard</title>
  <link rel="stylesheet" href="/styles.css">
  <style>
    main { max-width: 1180px; margin: 0 auto; padding: 48px 24px; }
    section { margin-top: 36px; }
    .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin: 24px 0; }
    .metric { border: 1px solid #d8d0c3; background: #fff; padding: 16px; }
    .metric strong { display: block; font-size: 1.8rem; line-height: 1; }
    .grid-two { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 18px; }
    table { width: 100%; border-collapse: collapse; background: #fff; }
    th, td { border: 1px solid #d8d0c3; padding: 10px; text-align: left; vertical-align: top; }
    th { font-size: 0.78rem; text-transform: uppercase; color: #6f6a62; }
    code { overflow-wrap: anywhere; }
  </style>
</head>
<body>
<main>
  <p class="page-kicker">Maintenance</p>
  <h1 class="page-title">TABI Editorial Dashboard</h1>
  <p class="page-desc">Static local dashboard for article volume, genre balance, source review, translation coverage, image reuse, and plan maintenance.</p>
  <div class="metric-grid">
    <div class="metric"><strong>${articles.length}</strong><span>English articles</span></div>
    <div class="metric"><strong>${japaneseArticles.length}</strong><span>Japanese articles</span></div>
    <div class="metric"><strong>${issueRows.length}</strong><span>Articles with issues</span></div>
    <div class="metric"><strong>${thinSubcategories.length}</strong><span>Genres below 3 articles</span></div>
    <div class="metric"><strong>${duplicateImages.length}</strong><span>Reused image files</span></div>
    <div class="metric"><strong>${planJapaneseTitleMojibake.length}</strong><span>Plan JA title mojibake candidates</span></div>
  </div>

  <section>
    <h2>Published Coverage</h2>
    <div class="grid-two">
      <div><h3>Categories</h3>${renderCountTable(publishedCategories)}</div>
      <div><h3>Genres</h3>${renderCountTable(publishedSubcategories, (key) => subcategoryBySlug.get(key)?.title || key)}</div>
      <div><h3>Regions</h3>${renderCountTable(publishedRegions)}</div>
      <div><h3>Thin Genres</h3>${renderCountTable(thinSubcategories.map((item) => ({ key: `${item.title} (${item.category})`, count: item.count })))}</div>
    </div>
  </section>

  <section>
    <h2>1000 Article Plan</h2>
    <div class="grid-two">
      <div><h3>Planned Regions</h3>${renderCountTable(plannedRegions)}</div>
      <div><h3>Planned Categories</h3>${renderCountTable(plannedCategories)}</div>
      <div><h3>Planned Genres</h3>${renderCountTable(plannedSubcategories, (key) => subcategoryBySlug.get(key)?.title || key)}</div>
      <div>
        <h3>Plan Maintenance</h3>
        <table>
          <tbody>
            <tr><td>Target published articles</td><td>${escapeHtml(contentPlan.targetPublishedArticles)}</td></tr>
            <tr><td>Planned new articles</td><td>${escapeHtml(contentPlan.plannedNewArticles)}</td></tr>
            <tr><td>Plan items</td><td>${escapeHtml(planItems.length)}</td></tr>
            <tr><td>Published articles not in plan items</td><td>${escapeHtml(articlesNotInPlan.length)}</td></tr>
            <tr><td>JA title mojibake candidates</td><td>${escapeHtml(planJapaneseTitleMojibake.length)}</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <section>
    <h2>Quality Watchlist</h2>
    <div class="grid-two">
      <div>
        <h3>Article Issues</h3>
        <table>
          <thead><tr><th>Article</th><th>Issues</th></tr></thead>
          <tbody>${toRows(issueRows, [
            (item) => item.article.title,
            (item) => item.issues.join(", ")
          ])}</tbody>
        </table>
      </div>
      <div>
        <h3>Duplicate Images</h3>
        <table>
          <thead><tr><th>Image</th><th>Uses</th></tr></thead>
          <tbody>${toRows(duplicateImages, [
            (item) => item.key,
            (item) => item.count
          ])}</tbody>
        </table>
      </div>
    </div>
  </section>

  <section>
    <h2>Article Detail</h2>
    <table>
      <thead><tr><th>Article</th><th>Category</th><th>Genre</th><th>Region</th><th>Last checked</th><th>Status</th><th>JA</th><th>Sources</th><th>Image uses</th><th>Sections</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>
  </section>
</main>
</body>
</html>
`;

await writeFile(path.join(root, "editorial-dashboard.json"), `${JSON.stringify(report, null, 2)}\n`);
await writeFile(path.join(root, "editorial-dashboard.html"), html);
console.log("Generated editorial-dashboard.html and editorial-dashboard.json");
