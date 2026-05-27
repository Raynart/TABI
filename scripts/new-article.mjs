import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const id = process.argv[2];
const category = process.argv[3] || "travel-guide";

if (!id || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
  console.error("Usage: npm run new:article -- article-slug [category]");
  process.exit(1);
}

const today = new Date().toISOString().slice(0, 10);
const template = [{
  id,
  title: "Draft title",
  summary: "Draft summary. Explain who this guide is for and what decision it helps the reader make.",
  category,
  tags: ["planning"],
  publishedAt: today,
  readingTime: 5,
  affiliate: false,
  featured: false,
  image: "/assets/images/kyoto-shrine-hero.png",
  imageAlt: "Draft image alt text",
  sections: [
    { heading: "Start here", body: "Draft body." },
    { heading: "What to know", body: "Draft body." },
    { heading: "How to use this guide", body: "Draft body." }
  ],
  sourcePolicy: "tabi-local-editorial",
  verificationLevel: "draft",
  lastChecked: today,
  sourceNote: "Draft created locally. Confirm volatile details with official sources before publishing."
}];

await mkdir(path.join(root, "content/articles"), { recursive: true });
const target = path.join(root, "content/articles", `${category}.${id}.draft.json`);
await writeFile(target, `${JSON.stringify(template, null, 2)}\n`);
console.log(`Created ${path.relative(root, target).replaceAll("\\", "/")}`);
