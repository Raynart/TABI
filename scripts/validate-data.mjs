import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadArticleData } from "./lib/content-loader.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const errors = [];

function requireString(item, key, label) {
  if (typeof item[key] !== "string" || !item[key].trim()) errors.push(`${label}: missing string ${key}`);
}

function requireArray(item, key, label) {
  if (!Array.isArray(item[key]) || item[key].length === 0) errors.push(`${label}: missing array ${key}`);
}

function validateArticle(article, label) {
  for (const key of ["id", "title", "summary", "category", "publishedAt", "image", "imageAlt", "sourcePolicy", "verificationLevel", "lastChecked", "sourceNote"]) {
    requireString(article, key, label);
  }
  requireArray(article, "tags", label);
  requireArray(article, "sections", label);
  if (!Number.isFinite(article.readingTime) || article.readingTime < 1) errors.push(`${label}: invalid readingTime`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(article.publishedAt || "")) errors.push(`${label}: invalid publishedAt`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(article.lastChecked || "")) errors.push(`${label}: invalid lastChecked`);
  for (const [index, section] of (article.sections || []).entries()) {
    requireString(section, "heading", `${label}.sections[${index}]`);
    requireString(section, "body", `${label}.sections[${index}]`);
  }
}

function validateJapaneseArticle(article, label) {
  for (const key of ["id", "title", "summary"]) requireString(article, key, label);
  requireArray(article, "sections", label);
  for (const [index, section] of (article.sections || []).entries()) {
    requireString(section, "heading", `${label}.sections[${index}]`);
    requireString(section, "body", `${label}.sections[${index}]`);
  }
}

const { articles, japaneseArticles } = await loadArticleData(root);
const config = JSON.parse(await readFile(path.join(root, "site.config.json"), "utf8"));
const siteData = JSON.parse(await readFile(path.join(root, "site-data.json"), "utf8"));
const policy = JSON.parse(await readFile(path.join(root, "content-policy.json"), "utf8"));
const categorySet = new Set(config.categories.map((category) => category.slug));
const articleIds = new Set();

for (const article of articles) {
  validateArticle(article, `articles:${article.id || "unknown"}`);
  if (articleIds.has(article.id)) errors.push(`duplicate article id: ${article.id}`);
  articleIds.add(article.id);
  if (!categorySet.has(article.category)) errors.push(`${article.id}: unknown category ${article.category}`);
}

for (const article of japaneseArticles) {
  validateJapaneseArticle(article, `articles.ja:${article.id || "unknown"}`);
  if (!articleIds.has(article.id)) errors.push(`articles.ja:${article.id} has no English source`);
}

for (const key of ["topics", "areas", "itineraries", "planning", "glossary"]) {
  if (!Array.isArray(siteData[key]) || siteData[key].length === 0) errors.push(`site-data.json: missing ${key}`);
}
for (const key of ["allowedSourceTypes", "disallowedSourceTypes", "reuseRules", "editorialPrinciples", "correctionPolicy"]) {
  if (!Array.isArray(policy[key]) || policy[key].length < 3) errors.push(`content-policy.json: weak ${key}`);
}

if (errors.length) {
  for (const error of errors) console.error(error);
  process.exit(1);
}

console.log(JSON.stringify({ ok: true, articles: articles.length, japaneseArticles: japaneseArticles.length }, null, 2));
