import { jsonResponse, hashClientIp } from "./utils.js";

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

      // Log download to D1 (non-blocking -- do not await)
      ctx.waitUntil(
        hashClientIp(clientIp).then((clientHash) =>
          env.DB.prepare(
            "INSERT INTO downloads (file, project, client_hash, country) VALUES (?, ?, ?, ?)"
          )
            .bind(key, project, clientHash, country)
            .run()
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

    // Route: stats (includes unique_users)
    if (pathname === "/stats") {
      const stats = await env.DB.prepare(
        "SELECT file, project, COUNT(*) as count, COUNT(DISTINCT client_hash) as unique_users FROM downloads WHERE project = ? GROUP BY file, project"
      )
        .bind(project)
        .all();

      return jsonResponse(stats.results);
    }

    // Route: dashboard (HTML table with Downloads + Unique Users)
    if (pathname === "/dashboard") {
      const stats = await env.DB.prepare(
        "SELECT file, project, COUNT(*) as count, COUNT(DISTINCT client_hash) as unique_users FROM downloads WHERE project = ? GROUP BY file, project ORDER BY count DESC"
      )
        .bind(project)
        .all();

      const totals = await env.DB.prepare(
        "SELECT COUNT(*) as total_downloads, COUNT(DISTINCT client_hash) as total_unique_users FROM downloads WHERE project = ?"
      )
        .bind(project)
        .first();

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
  <p>Total downloads: <strong>${totals?.total_downloads ?? 0}</strong> | Unique users (since Oct 22, 2026): <strong>${totals?.total_unique_users ?? 0}</strong></p>
  <table>
    <thead><tr><th>File</th><th>Project</th><th>Downloads</th><th>Unique Users*</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>
  <p class="note">*Unique user tracking (anonymized SHA-256 IP hash) began October 22, 2026.</p>
</body>
</html>`;

      return new Response(html, {
        headers: { "Content-Type": "text/html" },
      });
    }

    // Everything else: 404
    return new Response("Not found", { status: 404 });
  },
};
