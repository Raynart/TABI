import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

async function walk(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...await walk(full));
    } else {
      files.push(full);
    }
  }
  return files;
}

function rel(file) {
  return path.relative(root, file).replaceAll("\\", "/");
}

function attrs(text, name) {
  const values = [];
  const re = new RegExp(`${name}=["']([^"']+)["']`, "g");
  let match;
  while ((match = re.exec(text))) values.push(match[1]);
  return values;
}

function targetFile(url) {
  if (!url || /^(https?:|mailto:|tel:|data:|#)/.test(url)) return null;
  let clean = url.replace(/&amp;/g, "&").split("#")[0].split("?")[0];
  if (clean.startsWith("/")) clean = clean.slice(1);
  if (!clean) clean = "index.html";
  else if (clean.endsWith("/")) clean += "index.html";
  else if (!path.posix.extname(clean)) clean += "/index.html";
  return clean;
}

function fail(errors) {
  for (const error of errors) console.error(error);
  process.exit(1);
}

const files = await walk(root);
const fileSet = new Set(files.map(rel));
const htmlFiles = files.filter((file) => file.endsWith(".html") && !rel(file).endsWith("tabi-mockup.html") && !rel(file).endsWith("editorial-dashboard.html"));
const errors = [];
const articles = JSON.parse(await readFile(path.join(root, "articles.json"), "utf8"));
const policy = JSON.parse(await readFile(path.join(root, "content-policy.json"), "utf8"));

for (const key of [
  "allowedSourceTypes",
  "allowedSourceTypesJa",
  "disallowedSourceTypes",
  "disallowedSourceTypesJa",
  "reuseRules",
  "reuseRulesJa",
  "editorialPrinciples",
  "editorialPrinciplesJa",
  "correctionPolicy",
  "correctionPolicyJa"
]) {
  if (!Array.isArray(policy[key]) || policy[key].length < 3) {
    errors.push(`content-policy.json: ${key} must contain at least 3 items`);
  }
}
if (!policy.trustSummary?.en || !policy.trustSummary?.ja) {
  errors.push("content-policy.json: missing bilingual trustSummary");
}
if (!policy.defaultArticleMeta?.sourceNote || !policy.defaultArticleMetaJa?.sourceNote) {
  errors.push("content-policy.json: missing bilingual default source notes");
}
for (const article of articles) {
  for (const key of ["sourcePolicy", "verificationLevel", "lastChecked", "sourceNote"]) {
    if (!article[key]) errors.push(`articles.json: ${article.id} missing ${key}`);
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(article.lastChecked || "")) {
    errors.push(`articles.json: ${article.id} has invalid lastChecked`);
  }
}

for (const file of htmlFiles) {
  const relative = rel(file);
  const text = await readFile(file, "utf8");
  const expectedLang = relative.startsWith("ja/") ? "ja" : "en";
  if (!text.includes(`<html lang="${expectedLang}">`)) {
    errors.push(`${relative}: missing expected html lang ${expectedLang}`);
  }
  for (const hreflang of ['hreflang="en"', 'hreflang="ja"', 'hreflang="x-default"']) {
    if (!text.includes(hreflang)) errors.push(`${relative}: missing ${hreflang}`);
  }

  const ids = new Set(attrs(text, "id"));
  for (const href of attrs(text, "href")) {
    if (href.startsWith("#") && href.length > 1 && !ids.has(href.slice(1))) {
      errors.push(`${relative}: broken page anchor ${href}`);
    }
    const target = targetFile(href);
    if (target && !fileSet.has(target)) errors.push(`${relative}: missing linked file ${href}`);
  }

  for (const src of [...attrs(text, "src"), ...attrs(text, "poster")]) {
    const target = targetFile(src);
    if (target && !fileSet.has(target)) errors.push(`${relative}: missing asset ${src}`);
  }

  for (const srcset of attrs(text, "srcset")) {
    for (const part of srcset.split(",")) {
      const target = targetFile(part.trim().split(/\s+/)[0]);
      if (target && !fileSet.has(target)) errors.push(`${relative}: missing srcset asset ${part.trim()}`);
    }
  }

  const jsonLdNodes = [];
  for (const match of text.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)) {
    try {
      const parsed = JSON.parse(match[1]);
      if (Array.isArray(parsed["@graph"])) jsonLdNodes.push(...parsed["@graph"]);
      else jsonLdNodes.push(parsed);
    } catch (error) {
      errors.push(`${relative}: invalid JSON-LD ${error.message}`);
    }
  }
  const jsonLdTypes = new Set(jsonLdNodes.flatMap((node) => Array.isArray(node["@type"]) ? node["@type"] : [node["@type"]]).filter(Boolean));
  for (const type of ["Organization", "WebSite", "WebPage"]) {
    if (!jsonLdTypes.has(type)) errors.push(`${relative}: missing JSON-LD ${type}`);
  }
  if (text.includes('class="listing-grid"') && !jsonLdTypes.has("ItemList")) {
    errors.push(`${relative}: listing page missing JSON-LD ItemList`);
  }
  if (relative.includes("/articles/") || relative.startsWith("articles/")) {
    for (const marker of ["Source &amp; Verification", "Source note", "Corrections", "出所と検証", "出所メモ", "訂正"]) {
      const isJapanese = relative.startsWith("ja/");
      const englishMarker = ["Source &amp; Verification", "Source note", "Corrections"].includes(marker);
      if ((isJapanese && !englishMarker && !text.includes(marker)) || (!isJapanese && englishMarker && !text.includes(marker))) {
        errors.push(`${relative}: missing trust marker ${marker}`);
      }
    }
  }
}

const sitemap = await readFile(path.join(root, "sitemap.xml"), "utf8");
if (!sitemap.includes('xmlns:xhtml="http://www.w3.org/1999/xhtml"')) {
  errors.push("sitemap.xml: missing xhtml namespace");
}
if (!sitemap.includes("<changefreq>") || !sitemap.includes("<priority>")) {
  errors.push("sitemap.xml: missing changefreq or priority");
}
if ((sitemap.match(/xhtml:link/g) || []).length < htmlFiles.length) {
  errors.push("sitemap.xml: hreflang alternate count is unexpectedly low");
}
const imageSitemap = await readFile(path.join(root, "image-sitemap.xml"), "utf8");
if (!imageSitemap.includes("xmlns:image") || !imageSitemap.includes("<image:image>")) {
  errors.push("image-sitemap.xml: missing image sitemap entries");
}

for (const feed of ["feed.json", "ja/feed.json"]) {
  JSON.parse(await readFile(path.join(root, feed), "utf8"));
}
for (const feed of ["feed.xml", "ja/feed.xml"]) {
  const text = await readFile(path.join(root, feed), "utf8");
  if (!text.includes("<rss")) errors.push(`${feed}: missing rss root`);
}

const script = await readFile(path.join(root, "script.js"), "utf8");
new Function(script);

if (errors.length) fail(errors);

console.log(JSON.stringify({
  ok: true,
  htmlFiles: htmlFiles.length,
  japaneseHtmlFiles: htmlFiles.filter((file) => rel(file).startsWith("ja/")).length,
  sitemapAlternates: (sitemap.match(/xhtml:link/g) || []).length
}, null, 2));
