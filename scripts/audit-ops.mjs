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

function dateValue(dateText) {
  return new Date(`${dateText}T00:00:00+09:00`).getTime();
}

function countMatches(text, pattern) {
  return (text.match(pattern) || []).length;
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
const canonicalByFile = new Map();
const hreflangByFile = new Map();

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
  if (dateValue(article.publishedAt) > today.getTime()) errors.push(`${article.id}: publishedAt is in the future`);
  if (dateValue(article.lastChecked) < dateValue(article.publishedAt)) errors.push(`${article.id}: lastChecked is older than publishedAt`);
  if (article.affiliate === true && article.category !== "things-to-buy") errors.push(`${article.id}: affiliate is true outside things-to-buy`);
  if (article.category === "things-to-buy" && article.affiliate !== true) errors.push(`${article.id}: things-to-buy article must mark affiliate true`);
  if ((article.tags || []).length < 3 || (article.tags || []).length > 6) warnings.push(`${article.id}: tag count should stay between 3 and 6`);
  const sectionHeadings = new Set();
  for (const section of article.sections || []) {
    const heading = normalizeText(section.heading);
    if (sectionHeadings.has(heading)) errors.push(`${article.id}: duplicate section heading ${section.heading}`);
    sectionHeadings.add(heading);
    if (String(section.body || "").length < 80) warnings.push(`${article.id}: section "${section.heading}" is short`);
  }
  if (/<[^>]+>/.test(article.summary || "")) errors.push(`${article.id}: summary contains HTML`);
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
  const ids = attrs(text, "id");
  const idSet = new Set(ids);
  if (!text.includes("<!DOCTYPE html>")) errors.push(`${relative}: missing doctype`);
  if (!text.includes(`<html lang="${expectedLang}">`)) errors.push(`${relative}: html lang mismatch`);
  if (!text.includes('<meta charset="UTF-8">')) errors.push(`${relative}: missing UTF-8 charset`);
  if (!text.includes('name="viewport" content="width=device-width, initial-scale=1.0"')) errors.push(`${relative}: missing responsive viewport`);
  if (!text.includes(`http-equiv="content-language" content="${expectedLang}"`)) errors.push(`${relative}: content-language mismatch`);
  if (!text.includes('name="robots" content="index, follow, max-image-preview:large"')) errors.push(`${relative}: missing indexable robots meta`);
  if (!text.includes('name="googlebot" content="index, follow, max-snippet:-1, max-image-preview:large, max-video-preview:-1"')) errors.push(`${relative}: missing googlebot meta`);
  if (!text.includes('name="theme-color" content="#111111"')) errors.push(`${relative}: missing theme-color`);
  if (!text.includes('rel="alternate" type="application/rss+xml"')) errors.push(`${relative}: missing RSS alternate`);
  if (!text.includes('rel="alternate" type="application/feed+json"')) errors.push(`${relative}: missing JSON feed alternate`);
  if (!text.includes('rel="manifest" href="/site.webmanifest"')) errors.push(`${relative}: missing manifest link`);
  if (!text.includes('rel="stylesheet" href="/styles.css"')) errors.push(`${relative}: missing stylesheet link`);
  if (!text.includes('<script src="/script.js"></script>')) errors.push(`${relative}: missing script.js load`);
  if (!text.includes('<a class="skip-link" href="#main"')) errors.push(`${relative}: missing skip link`);
  if (!text.includes('<main id="main">')) errors.push(`${relative}: missing main landmark`);
  if (!text.includes('id="site-search-panel" data-search-panel hidden')) errors.push(`${relative}: search panel is not initially hidden`);
  if (!text.includes("window.TABI_ARTICLES = [")) errors.push(`${relative}: missing embedded search index`);
  if (/<button(?![^>]*\stype=)/.test(text)) errors.push(`${relative}: button without explicit type`);
  if (/\son[a-z]+=/i.test(text)) errors.push(`${relative}: inline event handler detected`);
  if (/http:\/\/(?!www\.w3\.org|www\.sitemaps\.org)/.test(text)) errors.push(`${relative}: insecure http URL detected`);
  if (/href=["']\s*["']/.test(text)) errors.push(`${relative}: empty href detected`);
  if (ids.length !== idSet.size) errors.push(`${relative}: duplicate id attribute detected`);
  for (const href of attrs(text, "href")) {
    if (href.startsWith("#") && href.length > 1 && !idSet.has(href.slice(1))) {
      errors.push(`${relative}: local anchor target missing ${href}`);
    }
  }

  const canonical = metaContent(text, "rel", "canonical") || attrMap(text.match(/<link\b[^>]*rel=["']canonical["'][^>]*>/i)?.[0] || "").href || "";
  canonicalByFile.set(relative, canonical);
  if (!canonical.startsWith(siteUrl)) errors.push(`${relative}: canonical is not absolute`);
  const hreflangs = Object.fromEntries([...text.matchAll(/<link\b[^>]*rel=["']alternate["'][^>]*hreflang=["']([^"']+)["'][^>]*>/g)]
    .map((match) => [match[1], attrMap(match[0]).href || ""]));
  hreflangByFile.set(relative, hreflangs);
  for (const lang of ["en", "ja", "x-default"]) {
    if (!hreflangs[lang]?.startsWith(siteUrl)) errors.push(`${relative}: missing absolute ${lang} hreflang`);
  }

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

for (const [relative, hreflangs] of hreflangByFile) {
  const expectedSelf = canonicalByFile.get(relative);
  const expectedDefault = hreflangs.en;
  if (hreflangs[relative.startsWith("ja/") ? "ja" : "en"] !== expectedSelf) {
    errors.push(`${relative}: self hreflang does not match canonical`);
  }
  if (hreflangs["x-default"] !== expectedDefault) errors.push(`${relative}: x-default should point to English URL`);
  for (const lang of ["en", "ja"]) {
    const target = localPathFromAbsoluteUrl(hreflangs[lang]);
    if (target && !fileSet.has(target)) errors.push(`${relative}: hreflang target missing ${target}`);
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
for (const legalPage of ["legal.html", "privacy.html", "disclaimer.html", "ja/legal.html", "ja/privacy.html", "ja/disclaimer.html"]) {
  if (!fileSet.has(legalPage)) errors.push(`${legalPage}: legal policy page is missing`);
  else {
    const text = await readFile(path.join(root, legalPage), "utf8");
    if (!text.includes('name="robots" content="index, follow, max-image-preview:large"')) errors.push(`${legalPage}: legal policy page must be indexable`);
    if (!text.includes("TABI") || !text.includes("hello@tabi.guide")) warnings.push(`${legalPage}: legal policy page may be missing site identity or contact`);
  }
}
const robots = await readFile(path.join(root, "robots.txt"), "utf8");
if (!robots.includes("Sitemap: https://tabi.guide/sitemap.xml") || !robots.includes("image-sitemap.xml")) {
  errors.push("robots.txt: missing sitemap declarations");
}
if (!robots.includes("User-agent: *") || !robots.includes("Allow: /")) errors.push("robots.txt: missing default allow rule");

const sitemap = await readFile(path.join(root, "sitemap.xml"), "utf8");
const sitemapLocs = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((match) => match[1]);
const sitemapSet = new Set(sitemapLocs);
if (sitemapLocs.length !== sitemapSet.size) errors.push("sitemap.xml: duplicate loc entries");
for (const loc of sitemapLocs) {
  const target = localPathFromAbsoluteUrl(loc);
  if (!target || !fileSet.has(target)) errors.push(`sitemap.xml: loc does not resolve to generated file ${loc}`);
  if (target?.endsWith("404.html") || target === "editorial-dashboard.html") errors.push(`sitemap.xml: non-indexable URL included ${loc}`);
}
const imageSitemap = await readFile(path.join(root, "image-sitemap.xml"), "utf8");
const imageLocs = [...imageSitemap.matchAll(/<image:loc>([^<]+)<\/image:loc>/g)].map((match) => match[1]);
for (const loc of imageLocs) {
  const target = localPathFromAbsoluteUrl(loc);
  if (!target || !fileSet.has(target)) errors.push(`image-sitemap.xml: image loc does not resolve ${loc}`);
}
if (imageLocs.length < articles.length) errors.push("image-sitemap.xml: too few image entries");

for (const header of ["X-Frame-Options", "X-Content-Type-Options", "Referrer-Policy", "Permissions-Policy"]) {
  if (!netlify.includes(header)) errors.push(`netlify.toml: missing security header ${header}`);
}
for (const cacheTarget of ["/assets/*", "/feed.xml", "/ja/feed.xml", "/sitemap.xml", "/image-sitemap.xml", "/feed.json", "/ja/feed.json"]) {
  if (!netlify.includes(`for = "${cacheTarget}"`)) errors.push(`netlify.toml: missing cache header for ${cacheTarget}`);
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
    "55": "machine-readable maintenance report",
    "56": "doctype audit",
    "57": "html lang audit",
    "58": "UTF-8 charset audit",
    "59": "responsive viewport audit",
    "60": "content-language audit",
    "61": "robots index directive audit",
    "62": "googlebot directive audit",
    "63": "theme color audit",
    "64": "RSS alternate audit",
    "65": "JSON Feed alternate audit",
    "66": "manifest link audit",
    "67": "stylesheet link audit",
    "68": "script loading audit",
    "69": "skip link audit",
    "70": "main landmark audit",
    "71": "search panel hidden-state audit",
    "72": "embedded search index audit",
    "73": "button type audit",
    "74": "inline handler audit",
    "75": "mixed-content URL audit",
    "76": "empty href audit",
    "77": "duplicate id audit",
    "78": "local anchor target audit",
    "79": "canonical absolute URL audit",
    "80": "hreflang absolute URL audit",
    "81": "hreflang self-reference audit",
    "82": "x-default hreflang audit",
    "83": "hreflang target existence audit",
    "84": "sitemap loc uniqueness audit",
    "85": "sitemap target existence audit",
    "86": "sitemap indexability audit",
    "87": "image sitemap target audit",
    "88": "robots allow-rule audit",
    "89": "feed cache header audit",
    "90": "image sitemap cache header audit",
    "91": "article future-date audit",
    "92": "lastChecked chronology audit",
    "93": "affiliate category audit",
    "94": "shopping affiliate disclosure audit",
    "95": "tag count range audit",
    "96": "section heading uniqueness audit",
    "97": "summary plain-text audit",
    "98": "section body depth audit",
    "99": "generated report completeness audit",
    "100": "full local release gate",
    "101": "legal policy pages audit",
    "102": "legal policy indexability audit"
  },
  stats: {
    htmlFiles: publicHtmlFiles.length,
    articles: articles.length,
    japaneseArticles: japaneseArticles.length,
    tags: tagCounts.size,
    externalLinks: externalLinks.size,
    legalPages: 6,
    sitemapUrls: sitemapLocs.length,
    imageSitemapImages: imageLocs.length,
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

if (Object.keys(report.implementedChecks).length !== 67) {
  errors.push("maintenance report: expected 67 implemented checks covering 36-102");
  report.ok = false;
}

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
