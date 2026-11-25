export function jsonResponse(item, extraHeaders = {}) {
  return new Response(JSON.stringify(item), {
    headers: { "Content-Type": "application/json", ...extraHeaders },
  });
}

export async function hashClientIp(ip) {
  if (!ip) return null;
  const data = new TextEncoder().encode(ip);
  const digest = await crypto.subtle.digest("SHA-256", data);
  const hex = Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return hex.slice(0, 16);
}
