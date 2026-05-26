import { runSiteHealth } from "./lib/site-health-core.mjs";

const result = await runSiteHealth();

const lines = [
  "# TABI Maintenance Report",
  "",
  `Generated pages: ${result.stats.htmlFiles}`,
  `Articles: ${result.stats.articles} EN / ${result.stats.japaneseArticles} JA`,
  `Generated file checks: ${result.stats.generatedFiles}`,
  `Indexable sitemap URLs: ${result.stats.indexableSitemapUrls}`,
  `Default source notes: ${result.stats.defaultSourceNotes}`,
  `Errors: ${result.errors.length}`,
  `Warnings: ${result.warnings.length}`,
  ""
];

if (result.errors.length) {
  lines.push("## Errors", "", ...result.errors.map((item) => `- ${item}`), "");
}
if (result.warnings.length) {
  lines.push("## Warnings", "", ...result.warnings.map((item) => `- ${item}`), "");
}
if (result.stats.defaultSourceNoteIds.length) {
  lines.push(
    "## Default Source Notes",
    "",
    ...result.stats.defaultSourceNoteIds.map((item) => `- ${item}`),
    ""
  );
}
if (!result.errors.length && !result.warnings.length) {
  lines.push("No issues detected.");
}

console.log(lines.join("\n"));

if (result.errors.length) process.exit(1);
