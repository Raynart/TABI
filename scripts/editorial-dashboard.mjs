import { writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadArticleData } from "./lib/content-loader.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const { articles, japaneseArticles } = await loadArticleData(root);
const japaneseById = new Map(japaneseArticles.map((article) => [article.id, article]));

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

function statusFor(article) {
  const age = daysSince(article.lastChecked);
  if (age > 120) return "Review overdue";
  if (article.sourceNote.includes("Created from TABI-owned editorial drafts")) return "Needs source detail";
  return "OK";
}

const rows = articles.map((article) => {
  const ja = japaneseById.get(article.id);
  return `<tr>
    <td><a href="/articles/${escapeHtml(article.id)}.html">${escapeHtml(article.title)}</a></td>
    <td>${escapeHtml(article.category)}</td>
    <td>${escapeHtml(article.lastChecked)}</td>
    <td>${escapeHtml(statusFor(article))}</td>
    <td>${ja ? "Yes" : "Missing"}</td>
    <td>${escapeHtml(article.sections?.length || 0)}</td>
  </tr>`;
}).join("\n");

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
    table { width: 100%; border-collapse: collapse; background: #fff; }
    th, td { border: 1px solid #d8d0c3; padding: 10px; text-align: left; vertical-align: top; }
    th { font-size: 0.78rem; text-transform: uppercase; color: #6f6a62; }
  </style>
</head>
<body>
<main>
  <p class="page-kicker">Maintenance</p>
  <h1 class="page-title">TABI Editorial Dashboard</h1>
  <p class="page-desc">Static local dashboard for source review, translation coverage, and article maintenance.</p>
  <table>
    <thead><tr><th>Article</th><th>Category</th><th>Last checked</th><th>Status</th><th>JA</th><th>Sections</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>
</main>
</body>
</html>
`;

await writeFile(path.join(root, "editorial-dashboard.html"), html);
console.log("Generated editorial-dashboard.html");
