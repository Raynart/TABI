import { access, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadArticleData } from "./lib/content-loader.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const errors = [];
const warnings = [];

function localAssetPath(url) {
  if (!url || /^(https?:|data:|#)/.test(url)) return null;
  return url.startsWith("/") ? url.slice(1) : url;
}

async function exists(relativePath) {
  try {
    await access(path.join(root, relativePath));
    return true;
  } catch {
    return false;
  }
}

function responsiveVariants(imagePath) {
  const parsed = path.posix.parse(imagePath);
  return [640, 1024, 1536].map((size) => `${parsed.dir}/${parsed.name}-${size}.webp`);
}

const { articles } = await loadArticleData(root);
const uniqueImages = new Map();

for (const article of articles) {
  const imagePath = localAssetPath(article.image);
  if (!imagePath) {
    errors.push(`${article.id}: image must be a local asset path`);
    continue;
  }

  if (!imagePath.startsWith("assets/images/")) {
    warnings.push(`${article.id}: image is outside assets/images/: ${article.image}`);
  }

  uniqueImages.set(imagePath, article.id);

  if (!(await exists(imagePath))) {
    errors.push(`${article.id}: missing image ${article.image}`);
    continue;
  }

  const imageStat = await stat(path.join(root, imagePath));
  if (imageStat.size < 10_000) {
    warnings.push(`${article.id}: source image is unusually small (${imageStat.size} bytes)`);
  }

  for (const variant of responsiveVariants(imagePath)) {
    if (!(await exists(variant))) {
      errors.push(`${article.id}: missing responsive image variant /${variant}`);
    } else {
      const variantStat = await stat(path.join(root, variant));
      if (variantStat.size < 5_000) {
        warnings.push(`${article.id}: responsive variant is unusually small (${variantStat.size} bytes): /${variant}`);
      }
    }
  }

  const alt = String(article.imageAlt || "").trim();
  if (alt.length < 24) warnings.push(`${article.id}: imageAlt is short`);
  if (/\b(image|photo|picture)\s+of\b/i.test(alt)) {
    warnings.push(`${article.id}: imageAlt can be more descriptive without 'image/photo/picture of'`);
  }
}

if (errors.length) {
  for (const error of errors) console.error(error);
  process.exit(1);
}

console.log(JSON.stringify({
  ok: true,
  articles: articles.length,
  uniqueImages: uniqueImages.size,
  requiredResponsiveVariants: uniqueImages.size * 3,
  warnings: warnings.length,
  warningSamples: warnings.slice(0, 12)
}, null, 2));
