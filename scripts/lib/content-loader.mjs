import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";

async function exists(target) {
  try {
    await stat(target);
    return true;
  } catch {
    return false;
  }
}

async function readJson(file) {
  return JSON.parse(await readFile(file, "utf8"));
}

async function readSplitArray(root, folder, fallbackFile) {
  const dir = path.join(root, folder);
  if (await exists(dir)) {
    const files = (await readdir(dir)).filter((file) => file.endsWith(".json")).sort();
    if (files.length) {
      const groups = await Promise.all(files.map((file) => readJson(path.join(dir, file))));
      return groups.flat();
    }
  }
  return readJson(path.join(root, fallbackFile));
}

export async function loadArticleData(root) {
  return {
    articles: await readSplitArray(root, "content/articles", "articles.json"),
    japaneseArticles: await readSplitArray(root, "content/articles.ja", "articles.ja.json")
  };
}
