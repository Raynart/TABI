import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const host = process.env.TABI_HOST || "127.0.0.1";
const port = Number.parseInt(process.env.TABI_PORT || "4200", 10);

const types = new Map([
  [".css", "text/css; charset=utf-8"],
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".jpeg", "image/jpeg"],
  [".jpg", "image/jpeg"],
  [".png", "image/png"],
  [".svg", "image/svg+xml"],
  [".txt", "text/plain; charset=utf-8"],
  [".webp", "image/webp"],
  [".xml", "application/xml; charset=utf-8"]
]);

async function pathExists(filePath) {
  try {
    await stat(filePath);
    return true;
  } catch {
    return false;
  }
}

async function resolveRequestPath(urlPath) {
  const decodedPath = decodeURIComponent(urlPath);

  if (decodedPath === "/" || decodedPath === "") {
    for (const defaultFile of ["index.html", "tabi-mockup.html"]) {
      const defaultPath = path.join(root, defaultFile);
      if (await pathExists(defaultPath)) return defaultPath;
    }
  }

  const candidate = path.resolve(root, decodedPath.replace(/^\/+/, ""));
  const relative = path.relative(root, candidate);
  if (relative.startsWith("..") || path.isAbsolute(relative)) return null;

  const info = await stat(candidate).catch(() => null);
  if (!info) return null;

  if (info.isDirectory()) {
    for (const defaultFile of ["index.html", "tabi-mockup.html"]) {
      const defaultPath = path.join(candidate, defaultFile);
      if (await pathExists(defaultPath)) return defaultPath;
    }
    return null;
  }

  return info.isFile() ? candidate : null;
}

const server = createServer(async (request, response) => {
  try {
    const requestUrl = new URL(request.url || "/", `http://${host}:${port}`);

    if (requestUrl.pathname === "/healthz") {
      response.writeHead(200, { "content-type": "application/json; charset=utf-8" });
      response.end(JSON.stringify({ ok: true, root, port, time: new Date().toISOString() }));
      return;
    }

    const filePath = await resolveRequestPath(requestUrl.pathname);
    if (!filePath) {
      response.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
      response.end("Not found");
      return;
    }

    const body = await readFile(filePath);
    response.writeHead(200, {
      "content-type": types.get(path.extname(filePath).toLowerCase()) || "application/octet-stream",
      "cache-control": "no-store"
    });
    response.end(body);
  } catch (error) {
    response.writeHead(500, { "content-type": "text/plain; charset=utf-8" });
    response.end("Internal server error");
    console.error(error);
  }
});

server.listen(port, host, () => {
  console.log(`worker listening on http://${host}:${port}/`);
});
