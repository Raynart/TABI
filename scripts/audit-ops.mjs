import { readdir, readFile, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadArticleData } from "./lib/content-loader.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const siteUrl = "https://tabi.guide";
const today = new Date();

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

function targetFile(url) {
  if (!url || /^(mailto:|tel:|data:|#)/.test(url)) return null;
  let clean = url.replace(/&amp;/g, "&").split("#")[0].split("?")[0];
  if (clean.startsWith(siteUrl)) clean = clean.slice(siteUrl.length);
  if (/^https?:\/\//.test(clean)) return null;
  if (clean.startsWith("/")) clean = clean.slice(1);
  if (!clean) clean = "index.html";
  else if (clean.endsWith("/")) clean += "index.html";
  else if (!path.posix.extname(clean)) clean += "/index.html";
  return clean;
}

function attrs(text, name) {
  const values = [];
  const re = new RegExp(`${name}=["']([^"']+)["']`, "g");
  let match;
  while ((match = re.exec(text))) values.push(match[1]);
  return values;
}

function attrMap(tag) {
  const pairs = {};
  for (const match of tag.matchAll(/([\w:-]+)=["']([^"']*)["']/g)) pairs[match[1]] = match[2];
  return pairs;
}

function metaContent(text, key, value) {
  const escaped = value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const re = new RegExp(`<meta\\s+[^>]*${key}=["']${escaped}["'][^>]*>`, "i");
  const tag = text.match(re)?.[0] || "";
  return attrMap(tag).content || "";
}

function jsonLdNodes(text) {
  const nodes = [];
  for (const match of text.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)) {
    const parsed = JSON.parse(match[1]);
    if (Array.isArray(parsed["@graph"])) nodes.push(...parsed["@graph"]);
    else nodes.push(parsed);
  }
  return nodes;
}

function nodeTypes(node) {
  return Array.isArray(node["@type"]) ? node["@type"] : [node["@type"]];
}

function daysSince(dateText) {
  const date = new Date(`${dateText}T00:00:00+09:00`);
  if (Number.isNaN(date.getTime())) return Number.POSITIVE_INFINITY;
  return Math.floor((today - date) / 86_400_000);
}

function addDays(dateText, days) {
  const date = new Date(`${dateText}T00:00:00+09:00`);
  if (Number.isNaN(date.getTime())) return null;
  date.setDate(date.getDate() + days);
  return date.toISOString().slice(0, 10);
}

function normalizeText(value) {
  return String(value || "")
    .toLowerCase()
    .replace(/<[^>]+>/g, " ")
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim();
}

function estimateReadingTime(article, lang) {
  const text = normalizeText([
    article.title,
    article.summary,
    ...(article.sections || []).flatMap((section) => [section.heading, section.body])
  ].join(" "));
  if (lang === "ja") return Math.max(1, Math.round(text.length / 500));
  return Math.max(1, Math.round(text.split(/\s+/).filter(Boolean).length / 180));
}

function localPathFromAbsoluteUrl(url) {
  if (!url?.startsWith(siteUrl)) return null;
  return targetFile(url.slice(siteUrl.length));
}

const errors = [];
const warnings = [];
const { articles, japaneseArticles } = await loadArticleData(root);
const config = JSON.parse(await readFile(path.join(root, "site.config.json"), "utf8"));
const manifest = JSON.parse(await readFile(path.join(root, "site.webmanifest"), "utf8"));
const netlify = await readFile(path.join(root, "netlify.toml"), "utf8");
const files = await walk(root);
const fileSet = new Set(files.map(rel));
const htmlFiles = files.filter((file) => file.endsWith(".html") && !rel(file).endsWith("tabi-mockup.html"));
const publicHtmlFiles = htmlFiles.filter((file) => !rel(file).endsWith("editorial-dashboard.html"));
const externalLinks = new Map();
const articleById = new Map(articles.map((article) => [article.id, article]));
const japaneseById = new Map(japaneseArticles.map((article) => [article.id, article]));
const categories = new Set(config.categories.map((category) => category.slug));
const tagCounts = new Map();
const phraseOwners = new Map();
const sourcePolicies = new Set();
const freshnessRows = [];

for (const article of articles) {
  if (!categories.has(article.category)) errors.push(`${article.id}: unknown category ${article.category}`);
  for (const tag of article.tags || []) {
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(tag)) errors.push(`${article.id}: invalid tag slug ${tag}`);
    tagCounts.set(tag, (tagCounts.get(tag) || 0) + 1);
  }
  sourcePolicies.add(article.sourcePolicy);
  const image = targetFile(article.image);
  if (!image || !fileSet.has(image)) errors.push(`${article.id}: article image is missing on disk`);
  if (String(article.imageAlt || "").trim().length < 12) warnings.push(`${article.id}: imageAlt is too short`);
  const estimated = estimateReadingTime(article, "en");
  if (article.readingTime < 2 || article.readingTime > 20) warnings.push(`${article.id}: readingTime is outside the editorial range`);
  if (estimated > article.readingTime * 2) warnings.push(`${article.id}: readingTime ${article.readingTime} is lower than estimate ${estimated}`);
  const age = daysSince(article.lastChecked);
  const reviewInterval = article.category === "things-to-buy" || article.category === "travel-guide" ? 90 : 180;
  freshnessRows.push({
    id: article.id,
    category: article.category,
    lastChecked: article.lastChecked,
    nextReview: addDays(article.lastChecked, reviewInterval),
    status: age > reviewInterval ? "overdue" : age > reviewInterval - 21 ? "due-soon" : "ok"
  });
  for (const section of article.sections || []) {
    const phrase = normalizeText(`${section.heading} ${section.body}`).slice(0, 180);
    if (!phrase) continue;
    if (phraseOwners.has(phrase) && phraseOwners.get(phrase) !== article.id) {
      warnings.push(`${article.id}: possible duplicated section text with ${phraseOwners.get(phrase)}`);
    }
    phraseOwners.set(phrase, article.id);
  }
}

if (!sourcePolicies.has("tabi-local-editorial")) {
  errors.push("content source policy set does not include tabi-local-editorial");
}

for (const article of japaneseArticles) {
  const english = articleById.get(article.id);
  if (!english) errors.push(`ja:${article.id}: missing English source`);
  if (english && (article.sections || []).length !== (english.sections || []).length) {
    warnings.push(`ja:${article.id}: section count differs from English source`);
  }
  const estimated = estimateReadingTime(article, "ja");
  if (english && estimated > english.readingTime * 2) warnings.push(`ja:${article.id}: localized reading time may need review`);
}

for (const article of articles) {
  if (!japaneseById.has(article.id)) errors.push(`${article.id}: missing Japanese translation`);
}

for (const [tag] of tagCounts) {
  if (!fileSet.has(`tags/${tag}.html`)) errors.push(`tag ${tag}: missing English tag page`);
  if (!fileSet.has(`ja/tags/${tag}.html`)) errors.push(`tag ${tag}: missing Japanese tag page`);
}

for (const category of categories) {
  const count = articles.filter((article) => article.category === category).length;
  if (count < 3) warnings.push(`category ${category}: only ${count} articles`);
}

for (const file of publicHtmlFiles) {
  const relative = rel(file);
  const text = await readFile(file, "utf8");
  const expectedLang = relative.startsWith("ja/") ? "ja" : "en";
  const ogImage = metaContent(text, "property", "og:image");

  for (const [key, value] of [
    ["property", "og:title"],
    ["property", "og:description"],
    ["property", "og:url"],
    ["property", "og:image"],
    ["property", "og:image:alt"],
    ["name", "twitter:card"],
    ["name", "twitter:title"],
    ["name", "twitter:description"],
    ["name", "twitter:image"]
  ]) {
    if (!metaContent(text, key, value)) errors.push(`${relative}: missing social meta ${value}`);
  }

  const ogTarget = localPathFromAbsoluteUrl(ogImage);
  if (ogTarget && !fileSet.has(ogTarget)) errors.push(`${relative}: og:image target missing ${ogTarget}`);

  for (const imageTag of text.matchAll(/<img\b[^>]*>/g)) {
    const values = attrMap(imageTag[0]);
    if (!values.alt?.trim()) errors.push(`${relative}: image missing alt text`);
    if (!values.width || !values.height) warnings.push(`${relative}: image missing width or height`);
  }

  for (const anchorTag of text.matchAll(/<a\b[^>]*>/g)) {
    const values = attrMap(anchorTag[0]);
    if (!values.href) continue;
    if (/^https?:\/\//.test(values.href) && !values.href.startsWith(siteUrl)) {
      const key = values.href;
      externalLinks.set(key, (externalLinks.get(key) || 0) + 1);
      if (values.target === "_blank" && !String(values.rel || "").includes("noopener")) {
        errors.push(`${relative}: external target=_blank link missing noopener`);
      }
    }
  }

  const nodes = jsonLdNodes(text);
  const typeSet = new Set(nodes.flatMap(nodeTypes).filter(Boolean));
  if (relative.includes("/articles/") || relative.startsWith("articles/")) {
    if (!typeSet.has("BreadcrumbList")) errors.push(`${relative}: missing BreadcrumbList JSON-LD`);
    const articleNode = nodes.find((node) => nodeTypes(node).includes("Article"));
    if (!articleNode) errors.push(`${relative}: missing Article JSON-LD`);
    else {
      for (const key of ["headline", "datePublished", "dateModified", "author", "publisher", "image", "inLanguage"]) {
        if (!articleNode[key]) errors.push(`${relative}: Article JSON-LD missing ${key}`);
      }
      if (articleNode.inLanguage !== expectedLang) errors.push(`${relative}: Article JSON-LD language mismatch`);
    }
  }
}

for (const file of ["feed.json", "ja/feed.json"]) {
  const feed = JSON.parse(await readFile(path.join(root, file), "utf8"));
  const expectedLang = file.startsWith("ja/") ? "ja" : "en";
  if (feed.language !== expectedLang) errors.push(`${file}: language mismatch`);
  for (const item of feed.items || []) {
    const target = localPathFromAbsoluteUrl(item.url);
    if (!target || !fileSet.has(target)) errors.push(`${file}: item URL missing generated page ${item.url}`);
    if (!Array.isArray(item.tags) || !item.tags.length) warnings.push(`${file}: item missing tags ${item.url}`);
  }
}

if (!Array.isArray(manifest.icons) || manifest.icons.length === 0) {
  warnings.push("site.webmanifest: icons are not configured yet");
}

const dashboard = await readFile(path.join(root, "editorial-dashboard.html"), "utf8");
if (!dashboard.includes('name="robots" content="noindex')) {
  errors.push("editorial-dashboard.html: missing noindex robots meta");
}
const robots = await readFile(path.join(root, "robots.txt"), "utf8");
if (!robots.includes("Sitemap: https://tabi.guide/sitemap.xml") || !robots.includes("image-sitemap.xml")) {
  errors.push("robots.txt: missing sitemap declarations");
}

for (const header of ["X-Frame-Options", "X-Content-Type-Options", "Referrer-Policy", "Permissions-Policy"]) {
  if (!netlify.includes(header)) errors.push(`netlify.toml: missing security header ${header}`);
}

const report = {
  ok: errors.length === 0,
  generatedAt: new Date().toISOString(),
  implementedChecks: {
    "36": "content freshness calendar",
    "37": "content gap report",
    "38": "i18n parity report",
    "39": "media alt and dimension audit",
    "40": "external link inventory",
    "41": "external noopener audit",
    "42": "social meta audit",
    "43": "Open Graph image audit",
    "44": "Article JSON-LD audit",
    "45": "BreadcrumbList JSON-LD audit",
    "46": "tag taxonomy audit",
    "47": "duplicate content phrase audit",
    "48": "reading time consistency audit",
    "49": "source policy consistency audit",
    "50": "source freshness severity report",
    "51": "feed item URL parity audit",
    "52": "manifest icon audit",
    "53": "robots and dashboard noindex audit",
    "54": "Netlify security header audit",
    "55": "machine-readable maintenance report"
  },
  stats: {
    htmlFiles: publicHtmlFiles.length,
    articles: articles.length,
    japaneseArticles: japaneseArticles.length,
    tags: tagCounts.size,
    externalLinks: externalLinks.size,
    overdueReviews: freshnessRows.filter((row) => row.status === "overdue").length,
    dueSoonReviews: freshnessRows.filter((row) => row.status === "due-soon").length
  },
  freshness: freshnessRows.sort((a, b) => String(a.nextReview).localeCompare(String(b.nextReview))),
  contentGaps: [...categories].map((category) => ({
    category,
    articles: articles.filter((article) => article.category === category).length
  })),
  externalLinks: [...externalLinks.entries()].map(([url, count]) => ({ url, count })).sort((a, b) => a.url.localeCompare(b.url)),
  warnings,
  errors
};

await writeFile(path.join(root, "maintenance-report.json"), `${JSON.stringify(report, null, 2)}\n`);

if (errors.length) {
  for (const error of errors) console.error(error);
  process.exit(1);
}

console.log(JSON.stringify({
  ok: true,
  checks: Object.keys(report.implementedChecks).length,
  warnings: warnings.length,
  externalLinks: externalLinks.size,
  overdueReviews: report.stats.overdueReviews
}, null, 2));
