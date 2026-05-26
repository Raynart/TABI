import { runSiteHealth } from "./lib/site-health-core.mjs";

const result = await runSiteHealth();

if (result.errors.length) {
  for (const error of result.errors) console.error(error);
  process.exit(1);
}

console.log(JSON.stringify({
  ok: true,
  htmlFiles: result.stats.htmlFiles,
  articles: result.stats.articles,
  japaneseArticles: result.stats.japaneseArticles,
  generatedFiles: result.stats.generatedFiles,
  indexableSitemapUrls: result.stats.indexableSitemapUrls,
  defaultSourceNotes: result.stats.defaultSourceNotes,
  warnings: result.warnings.length,
  warningSamples: result.warnings.slice(0, 12)
}, null, 2));
