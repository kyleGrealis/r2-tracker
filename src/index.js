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

      // Log download to D1 (non-blocking -- don't await)
      ctx.waitUntil(
        env.DB.prepare("INSERT INTO downloads (file, project) VALUES (?, ?)")
          .bind(key, project)  // only used for filling the ? placeholders
          .run()
      );

      return new Response(object.body, {
        headers: { "Content-Type": "application/octet-stream" },
      });
    }

    // Route: stats (placeholder)
    if (pathname === "/stats") {
      // use await so the call doesn't return a Promise and waits until the 
      // SQL query completes
      const stats = await env.DB.prepare(
        "SELECT file, project, COUNT(*) as count FROM downloads WHERE project = ? GROUP BY file, project"
      )
        .bind(project)
        .all();
      
      return new Response(JSON.stringify(stats.results), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Route: dashboard (placeholder)
    if (pathname === "/dashboard") {
      const stats = await env.DB.prepare(
        "SELECT file, project, COUNT(*) as count FROM downloads WHERE project = ? GROUP by file, project ORDER BY count DESC"
      )
        .bind(project)
        .all();

      const rows = stats.results
        // for every element of the stats.return array, plug in the file, 
        // project, and count row cells. 
        .map((r) => `<tr><td>${r.file}</td><td>${r.project}</td><td>${r.count}</td></tr>`)
        .join("");

      const html = `<!DOCTYPE html>
<html>
<head>
  <title>${project.toUpperCase()} Data Tracking Dashboard</title>
  <style>
    body { font-family: system-ui; max-width: 600px; margin: 40px auto; padding: 0 20px; }
    table { width: 100%; border-collapse: collapse; }
    th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
    th { font-weight: 600; }
  </style>
</head>
<body>
  <h1>${project.toUpperCase()} Data Tracking Dashboard</h1>
  <p>Download counts across all projects</p>
  <table>
    <thead><tr><th>File</th><th>Project</th><th>Downloads</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>
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
