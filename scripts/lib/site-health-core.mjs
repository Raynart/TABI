import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const defaultRoot = path.resolve(scriptDir, "../..");

const limits = {
  maxHtmlBytes: 180_000,
  maxCssBytes: 90_000,
  maxJsBytes: 60_000,
  maxArticleAgeDays: 180,
  maxSourceAgeDays: 120,
  minEnglishSummaryChars: 90,
  minJapaneseSummaryChars: 35,
  minArticleSections: 3
};

const requiredGeneratedFiles = [
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
];

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

function rel(root, file) {
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

function hasMojibake(value) {
  return /縺|繧|譁|荳|莠|蜃|謇|險|驥|螟|譛|邱|霈|逕|諠|蛯/.test(String(value || ""));
}

function japaneseSignalRatio(value) {
  const text = String(value || "").replace(/\s+/g, "");
  if (!text.length) return 0;
  const matches = text.match(/[\u3040-\u30ff\u3400-\u9fff]/g) || [];
  return matches.length / text.length;
}

function articleText(article) {
  const sectionText = Array.isArray(article.sections)
    ? article.sections.map((section) => `${section.heading || ""} ${section.body || ""}`).join(" ")
    : "";
  return `${article.title || ""} ${article.summary || ""} ${sectionText}`;
}

function validateEnglishArticle(article, config, errors, warnings, articleIds, defaultSourceNote) {
  if (articleIds.has(article.id)) errors.push(`articles.json: duplicate article id ${article.id}`);
  articleIds.add(article.id);

  for (const key of ["id", "title", "summary", "category", "tags", "publishedAt", "readingTime", "image", "imageAlt", "sections", "sourcePolicy", "verificationLevel", "lastChecked", "sourceNote"]) {
    if (article[key] === undefined || article[key] === null || article[key] === "") errors.push(`articles.json ${article.id}: missing ${key}`);
  }

  if (!config.categories.some((category) => category.slug === article.category)) {
    errors.push(`${article.id}: unknown category ${article.category}`);
  }
  if (!Array.isArray(article.sections) || article.sections.length < limits.minArticleSections) {
    errors.push(`${article.id}: fewer than ${limits.minArticleSections} sections`);
  }
  if (String(article.summary || "").length < limits.minEnglishSummaryChars) {
    warnings.push(`${article.id}: English summary is short`);
  }
  if (hasMojibake(articleText(article))) errors.push(`${article.id}: possible mojibake in English article`);
  if (daysSince(article.publishedAt) > limits.maxArticleAgeDays) warnings.push(`${article.id}: publishedAt is older than ${limits.maxArticleAgeDays} days`);
  if (daysSince(article.lastChecked) > limits.maxSourceAgeDays) warnings.push(`${article.id}: lastChecked is older than ${limits.maxSourceAgeDays} days`);
  if (article.sourceNote === defaultSourceNote) return 1;
  return 0;
}

function validateJapaneseArticle(article, englishArticle, errors, warnings) {
  for (const key of ["id", "title", "summary", "sections"]) {
    if (article[key] === undefined || article[key] === null || article[key] === "") errors.push(`articles.ja.json ${article.id}: missing ${key}`);
  }
  if (!englishArticle) {
    errors.push(`articles.ja.json: translation id has no English article ${article.id}`);
    return;
  }
  if (article.title === englishArticle.title) errors.push(`articles.ja.json ${article.id}: title matches English title`);
  if (article.summary === englishArticle.summary) errors.push(`articles.ja.json ${article.id}: summary matches English summary`);
  if (!Array.isArray(article.sections) || article.sections.length < limits.minArticleSections) {
    errors.push(`articles.ja.json ${article.id}: fewer than ${limits.minArticleSections} sections`);
  }
  if (String(article.summary || "").length < limits.minJapaneseSummaryChars) {
    warnings.push(`articles.ja.json ${article.id}: Japanese summary is short`);
  }
  const text = articleText(article);
  if (hasMojibake(text)) errors.push(`articles.ja.json ${article.id}: possible mojibake`);
  if (japaneseSignalRatio(text) < 0.28) warnings.push(`articles.ja.json ${article.id}: Japanese text ratio looks low`);
}

export async function runSiteHealth(options = {}) {
  const root = options.root ? path.resolve(options.root) : defaultRoot;
  const errors = [];
  const warnings = [];
  const files = await walk(root);
  const relativeFiles = files.map((file) => rel(root, file));
  const htmlFiles = files.filter((file) => file.endsWith(".html") && !rel(root, file).endsWith("tabi-mockup.html"));
  const sitemapHtmlFiles = htmlFiles.filter((file) => !rel(root, file).endsWith("404.html"));
  const articles = JSON.parse(await readFile(path.join(root, "articles.json"), "utf8"));
  const japaneseArticles = JSON.parse(await readFile(path.join(root, "articles.ja.json"), "utf8"));
  const config = JSON.parse(await readFile(path.join(root, "site.config.json"), "utf8"));
  const manifest = JSON.parse(await readFile(path.join(root, "site.webmanifest"), "utf8"));
  const contentPolicy = JSON.parse(await readFile(path.join(root, "content-policy.json"), "utf8"));
  const titles = new Map();
  const descriptions = new Map();
  const canonicals = new Map();

  for (const required of requiredGeneratedFiles) {
    if (!relativeFiles.includes(required)) errors.push(`missing generated file: ${required}`);
  }

  for (const file of htmlFiles) {
    const relative = rel(root, file);
    const text = await readFile(file, "utf8");
    const size = (await stat(file)).size;
    if (size > limits.maxHtmlBytes) warnings.push(`${relative}: HTML size ${size} exceeds ${limits.maxHtmlBytes}`);
    addDuplicate(titles, textBetween(text, /<title>([\s\S]*?)<\/title>/), relative);
    addDuplicate(descriptions, textBetween(text, /<meta name="description" content="([^"]*)">/), relative);
    addDuplicate(canonicals, textBetween(text, /<link rel="canonical" href="([^"]*)">/), relative);
    if (hasMojibake(text)) errors.push(`${relative}: possible mojibake`);
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

  for (const [name, limit] of [["styles.css", limits.maxCssBytes], ["script.js", limits.maxJsBytes]]) {
    const size = (await stat(path.join(root, name))).size;
    if (size > limit) warnings.push(`${name}: size ${size} exceeds ${limit}`);
  }

  const articleIds = new Set();
  const articleById = new Map(articles.map((article) => [article.id, article]));
  const defaultSourceNoteIds = [];
  for (const article of articles) {
    const usesDefaultSourceNote = validateEnglishArticle(article, config, errors, warnings, articleIds, contentPolicy.defaultArticleMeta?.sourceNote);
    if (usesDefaultSourceNote) defaultSourceNoteIds.push(article.id);
  }
  for (const article of japaneseArticles) {
    validateJapaneseArticle(article, articleById.get(article.id), errors, warnings);
  }

  const sitemap = await readFile(path.join(root, "sitemap.xml"), "utf8");
  const sitemapUrlCount = (sitemap.match(/<url>/g) || []).length;
  if (sitemapUrlCount !== sitemapHtmlFiles.length) {
    errors.push(`sitemap.xml: URL count ${sitemapUrlCount} does not match indexable HTML count ${sitemapHtmlFiles.length}`);
  }
  if (!new Set(["en", "ja"]).has(manifest.lang)) warnings.push(`site.webmanifest: unexpected lang ${manifest.lang}`);

  return {
    ok: errors.length === 0,
    errors,
    warnings,
    stats: {
      htmlFiles: htmlFiles.length,
      generatedFiles: requiredGeneratedFiles.length,
      indexableSitemapUrls: sitemapUrlCount,
      articles: articles.length,
      japaneseArticles: japaneseArticles.length,
      defaultSourceNotes: defaultSourceNoteIds.length,
      defaultSourceNoteIds
    }
  };
}
