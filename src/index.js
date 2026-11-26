import { jsonResponse, hashClientIp } from "./utils.js";

const EDGE_CACHE_TTL_SECONDS = 1800;

// Maintain small rollup tables (~175 rows) alongside the append-only downloads
// log. Full-table COUNT/COUNT(DISTINCT) scans on /stats blew past D1's 5M
// daily free row-read quota when polled every 60s.
async function recordDownload(db, key, project, clientHash, country) {
  await db
    .prepare(
      "INSERT INTO downloads (file, project, client_hash, country) VALUES (?, ?, ?, ?)"
    )
    .bind(key, project, clientHash, country)
    .run();

  let isNewFileClient = 0;
  let isNewProjectClient = 0;

  if (clientHash) {
    const fileClientRes = await db
      .prepare(
        "INSERT OR IGNORE INTO file_clients (project, file, client_hash) VALUES (?, ?, ?)"
      )
      .bind(project, key, clientHash)
      .run();
    isNewFileClient = fileClientRes.meta?.changes > 0 ? 1 : 0;

    const projectClientRes = await db
      .prepare(
        "INSERT OR IGNORE INTO project_clients (project, client_hash) VALUES (?, ?)"
      )
      .bind(project, clientHash)
      .run();
    isNewProjectClient = projectClientRes.meta?.changes > 0 ? 1 : 0;
  }

  const stmts = [
    db
      .prepare(
        `INSERT INTO file_stats (project, file, count, unique_users)
         VALUES (?, ?, 1, ?)
         ON CONFLICT (project, file) DO UPDATE SET
           count = count + 1,
           unique_users = unique_users + excluded.unique_users`
      )
      .bind(project, key, isNewFileClient),
  ];

  if (isNewProjectClient) {
    stmts.push(
      db
        .prepare(
          `INSERT INTO project_stats (project, unique_users)
           VALUES (?, 1)
           ON CONFLICT (project) DO UPDATE SET
             unique_users = unique_users + 1`
        )
        .bind(project)
    );
  }

  await db.batch(stmts);
}

// Normalize GET cache keys to URL-only so bar widgets, bots, and browsers
// share the same per-PoP edge cache entry instead of bypassing on User-Agent.
async function withEdgeCache(request, ctx, buildResponse) {
  if (request.method !== "GET") {
    return buildResponse();
  }

  const cache = caches.default;
  const cacheKey = new Request(request.url, { method: "GET" });
  const cached = await cache.match(cacheKey);
  if (cached) {
    return cached;
  }

  const response = await buildResponse();
  if (response.ok) {
    ctx.waitUntil(cache.put(cacheKey, response.clone()));
  }
  return response;
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const hostname = url.hostname;  // "nhanes.kylegrealis.com"
    const pathname = url.pathname;  // "/demo.parquet"

    // Determine which project/bucket based on subdomain
    let bucket;
    let project;
    if (hostname.includes("nhanes")) {
      bucket = env.NHANES_BUCKET;
      project = "nhanes";
    } else if (hostname.includes("nascar")) {
      bucket = env.NASCAR_BUCKET;
      project = "nascar";
    } else {
      return new Response("Unknown project", { status: 404 });
    }

    // Route: serve parquet files
    if (pathname.endsWith(".parquet")) {
      const key = pathname.slice(1); // remove leading "/"
      const object = await bucket.get(key);

      if (!object) {
        return new Response("File not found", { status: 404 });
      }

      const clientIp = request.headers.get("CF-Connecting-IP");
      const country = request.cf?.country || null;

      // Log download and update D1 rollups in the background without blocking
      // the R2 parquet stream response.
      ctx.waitUntil(
        hashClientIp(clientIp).then((clientHash) =>
          recordDownload(env.DB, key, project, clientHash, country)
        )
      );

      return new Response(object.body, {
        headers: { "Content-Type": "application/octet-stream" },
      });
    }

    // Route: raw data (kept backwards-compatible for r2-dashboard Shiny app)
    if (pathname === "/raw") {
      const raw = await env.DB.prepare(
        "SELECT file, project, downloads_at as time FROM downloads WHERE project = ?"
      )
        .bind(project)
        .all();

      return jsonResponse(raw.results);
    }

    // Route: cleaned data by removing ".parquet" from file name
    if (pathname === "/cleaned") {
      const raw = await env.DB.prepare(
        "SELECT file, project, downloads_at as time FROM downloads WHERE project = ?"
      )
        .bind(project)
        .all();

      const cleaned = raw.results.map((item) => ({
        file: item.file.split(".")[0],
        project: item.project,
        time: item.time,
      }));

      return jsonResponse(cleaned);
    }

    // Route: stats (reads from rollup table + 30-min edge cache)
    if (pathname === "/stats") {
      return withEdgeCache(request, ctx, async () => {
        const stats = await env.DB.prepare(
          "SELECT file, project, count, unique_users FROM file_stats WHERE project = ?"
        )
          .bind(project)
          .all();

        return jsonResponse(stats.results, {
          "Cache-Control": `public, max-age=${EDGE_CACHE_TTL_SECONDS}`,
        });
      });
    }

    // Route: dashboard (reads from rollup tables + 30-min edge cache)
    if (pathname === "/dashboard") {
      return withEdgeCache(request, ctx, async () => {
        const [stats, projectTotals] = await env.DB.batch([
          env.DB.prepare(
            "SELECT file, project, count, unique_users FROM file_stats WHERE project = ? ORDER BY count DESC"
          ).bind(project),
          env.DB.prepare(
            "SELECT unique_users FROM project_stats WHERE project = ?"
          ).bind(project),
        ]);

        const totalDownloads = stats.results.reduce(
          (sum, r) => sum + Number(r.count || 0),
          0
        );
        const totalUniqueUsers = projectTotals.results[0]?.unique_users ?? 0;

        const rows = stats.results
          .map(
            (r) =>
              `<tr><td>${r.file}</td><td>${r.project}</td><td>${r.count}</td><td>${r.unique_users}</td></tr>`
          )
          .join("");

        const html = `<!DOCTYPE html>
<html>
<head>
  <title>${project.toUpperCase()} Data Tracking Dashboard</title>
  <style>
    body { font-family: system-ui; max-width: 680px; margin: 40px auto; padding: 0 20px; }
    table { width: 100%; border-collapse: collapse; }
    th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
    th { font-weight: 600; }
    .note { color: #666; font-size: 0.9em; }
  </style>
</head>
<body>
  <h1>${project.toUpperCase()} Data Tracking Dashboard</h1>
  <p>Total downloads: <strong>${totalDownloads}</strong> | Unique users (since Oct 22, 2026): <strong>${totalUniqueUsers}</strong></p>
  <table>
    <thead><tr><th>File</th><th>Project</th><th>Downloads</th><th>Unique Users*</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>
  <p class="note">*Unique user tracking (anonymized SHA-256 IP hash) began October 22, 2026.</p>
</body>
</html>`;

        return new Response(html, {
          headers: {
            "Content-Type": "text/html",
            "Cache-Control": `public, max-age=${EDGE_CACHE_TTL_SECONDS}`,
          },
        });
      });
    }

    // Everything else: 404
    return new Response("Not found", { status: 404 });
  },
};
