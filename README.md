# r2-tracker

A Cloudflare Worker that sits in front of R2 buckets and tracks file downloads to a D1 database. It serves multiple R packages that host data on Cloudflare R2.

## Projects

| Project | Subdomain | R2 Bucket |
|---------|-----------|-----------|
| nhanesdata | nhanes.kylegrealis.com | nhanes-data |
| nascaR.data | nascar.kylegrealis.com | nascar-data |

## How it works

```
User calls read_nhanes("demo")
  -> arrow::read_parquet("https://nhanes.kylegrealis.com/demo.parquet")
    -> Cloudflare Worker (this project)
      -> Logs download to D1 (non-blocking)
      -> Fetches file from R2 bucket
      -> Streams file back to user
```

## Routes

| Route | Response |
|-------|----------|
| `GET /{name}.parquet` | Logs hit to D1, proxies file from R2 |
| `GET /stats` | JSON download counts filtered by subdomain |
| `GET /dashboard` | HTML table showing download counts |
| Everything else | 404 |

## Development

```bash
# Install dependencies
npm install

# Run locally
npx wrangler dev

# Deploy to Cloudflare
wrangler deploy

# Query the D1 database
wrangler d1 execute r2-downloads --remote --command "SELECT * FROM downloads"
```

+ `wrangler`: the Node.js package for connecting to the Cloudflare services
+ `d1 execute`: the method for targeting the database by name
+ `r2-downloads`: the name of the D1 database
+ `--remote`: because this is not a local database
+ `--command`: what to be executed
+ `SELECT * FROM downloads`: SQL that will return everything from the downloads database table
