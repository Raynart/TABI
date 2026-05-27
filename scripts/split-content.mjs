import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

async function writeGrouped(sourceFile, targetDir, categoryById) {
  const items = JSON.parse(await readFile(path.join(root, sourceFile), "utf8"));
  const groups = new Map();
  for (const item of items) {
    const category = item.category || categoryById.get(item.id);
    if (!category) throw new Error(`${sourceFile}: ${item.id} has no category`);
    if (!groups.has(category)) groups.set(category, []);
    groups.get(category).push(item);
  }
  await mkdir(path.join(root, targetDir), { recursive: true });
  for (const [category, group] of [...groups.entries()].sort(([a], [b]) => a.localeCompare(b))) {
    await writeFile(path.join(root, targetDir, `${category}.json`), `${JSON.stringify(group, null, 2)}\n`);
  }
  return items;
}

const english = await writeGrouped("articles.json", "content/articles", new Map());
const categoryById = new Map(english.map((item) => [item.id, item.category]));
await writeGrouped("articles.ja.json", "content/articles.ja", categoryById);

console.log("Split article content by category.");
