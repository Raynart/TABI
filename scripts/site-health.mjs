import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const maxHtmlBytes = 180_000;
const maxCssBytes = 90_000;
const maxJsBytes = 60_000;
const maxArticleAgeDays = 180;
const maxSourceAgeDays = 120;
const expectedLanguages = new Set(["en", "ja"]);
const errors = [];
const warnings = [];

async function walk(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    if (entry.name === ".git") continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) files.push(...await walk(full));
    else files.push(full);
  }
  return files;
}

function rel(file) {
  return path.relative(root, file).replaceAll("\\", "/");
}

function textBetween(text, pattern) {
  const match = text.match(pattern);
  return match ? match[1].trim() : "";
}

function daysSince(dateText) {
  const date = new Date(`${dateText}T00:00:00+09:00`);
  if (Number.isNaN(date.getTime())) return Number.POSITIVE_INFINITY;
  return Math.floor((Date.now() - date.getTime()) / 86_400_000);
}

function addDuplicate(map, key, file) {
  if (!key) return;
  if (!map.has(key)) map.set(key, []);
  map.get(key).push(file);
}

const files = await walk(root);
const htmlFiles = files.filter((file) => file.endsWith(".html") && !rel(file).endsWith("tabi-mockup.html"));
const sitemapHtmlFiles = htmlFiles.filter((file) => !rel(file).endsWith("404.html"));
const articles = JSON.parse(await readFile(path.join(root, "articles.json"), "utf8"));
const japaneseArticles = JSON.parse(await readFile(path.join(root, "articles.ja.json"), "utf8"));
const config = JSON.parse(await readFile(path.join(root, "site.config.json"), "utf8"));
const titles = new Map();
const descriptions = new Map();
const canonicals = new Map();

for (const required of [
  "index.html",
  "ja/index.html",
  "sitemap.xml",
  "robots.txt",
  "feed.xml",
  "ja/feed.xml",
  "feed.json",
  "ja/feed.json",
  "llms.txt",
  "source-policy.html",
  "ja/source-policy.html"
]) {
  if (!files.map(rel).includes(required)) errors.push(`missing generated file: ${required}`);
}

for (const file of htmlFiles) {
  const relative = rel(file);
  const text = await readFile(file, "utf8");
  const size = (await stat(file)).size;
  if (size > maxHtmlBytes) warnings.push(`${relative}: HTML size ${size} exceeds ${maxHtmlBytes}`);
  addDuplicate(titles, textBetween(text, /<title>([\s\S]*?)<\/title>/), relative);
  addDuplicate(descriptions, textBetween(text, /<meta name="description" content="([^"]*)">/), relative);
  addDuplicate(canonicals, textBetween(text, /<link rel="canonical" href="([^"]*)">/), relative);
}

for (const [title, paths] of titles) {
  if (paths.length > 1) warnings.push(`duplicate title "${title}" in ${paths.slice(0, 4).join(", ")}`);
}
for (const [description, paths] of descriptions) {
  if (description && paths.length > 3) warnings.push(`reused description in ${paths.length} pages: ${description.slice(0, 90)}`);
}
for (const [canonical, paths] of canonicals) {
  if (paths.length > 1) errors.push(`duplicate canonical ${canonical}: ${paths.join(", ")}`);
}

for (const asset of [
  ["styles.css", maxCssBytes],
  ["script.js", maxJsBytes]
]) {
  const [name, limit] = asset;
  const size = (await stat(path.join(root, name))).size;
  if (size > limit) warnings.push(`${name}: size ${size} exceeds ${limit}`);
}

const articleIds = new Set();
for (const article of articles) {
  if (articleIds.has(article.id)) errors.push(`articles.json: duplicate article id ${article.id}`);
  articleIds.add(article.id);
  if (daysSince(article.publishedAt) > maxArticleAgeDays) warnings.push(`${article.id}: publishedAt is older than ${maxArticleAgeDays} days`);
  if (daysSince(article.lastChecked) > maxSourceAgeDays) warnings.push(`${article.id}: lastChecked is older than ${maxSourceAgeDays} days`);
  if (!config.categories.some((category) => category.slug === article.category)) {
    errors.push(`${article.id}: unknown category ${article.category}`);
  }
}

for (const article of japaneseArticles) {
  if (!articleIds.has(article.id)) errors.push(`articles.ja.json: translation id has no English article ${article.id}`);
}

const sitemap = await readFile(path.join(root, "sitemap.xml"), "utf8");
const sitemapUrlCount = (sitemap.match(/<url>/g) || []).length;
if (sitemapUrlCount !== sitemapHtmlFiles.length) {
  errors.push(`sitemap.xml: URL count ${sitemapUrlCount} does not match indexable HTML count ${sitemapHtmlFiles.length}`);
}

const manifests = JSON.parse(await readFile(path.join(root, "site.webmanifest"), "utf8"));
if (!expectedLanguages.has(manifests.lang)) warnings.push(`site.webmanifest: unexpected lang ${manifests.lang}`);

if (errors.length) {
  for (const error of errors) console.error(error);
  process.exit(1);
}

console.log(JSON.stringify({
  ok: true,
  htmlFiles: htmlFiles.length,
  articles: articles.length,
  warnings: warnings.length,
  warningSamples: warnings.slice(0, 12)
}, null, 2));
