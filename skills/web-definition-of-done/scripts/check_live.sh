#!/usr/bin/env bash
# Light, non-intrusive live checks against the site being audited (GET/HEAD only).
# curl cannot run JavaScript: cookies/requests set by JS need a real browser check.
# Usage: check_live.sh <https://site.example> [--wordpress]

set -u
URL="${1:?usage: check_live.sh <url> [--wordpress]}"
URL="${URL%/}"
WP=0; [ "${2:-}" = "--wordpress" ] && WP=1
UA="Mozilla/5.0 (definition-of-done audit)"
C=(curl -sS -m 15 -A "$UA")
HOST=$(printf '%s' "$URL" | sed -E 's#^https?://##; s#/.*##')

section() { printf '\n=== %s ===\n' "$1"; }

section "HTTPS redirect (SEC-14)"
"${C[@]}" -o /dev/null -w 'http://%{url_effective} -> %{http_code} %{redirect_url}\n' "http://$HOST/"
"${C[@]}" -o /dev/null -w 'https status: %{http_code}  tls-verify: %{ssl_verify_result} (0 = ok)\n' "https://$HOST/"

section "Response headers (SEC-15..18)"
HDRS=$("${C[@]}" -D - -o /dev/null -L "$URL/")
for h in strict-transport-security content-security-policy content-security-policy-report-only \
         x-content-type-options x-frame-options referrer-policy permissions-policy; do
  v=$(printf '%s' "$HDRS" | grep -i "^$h:" | tail -n1 | cut -c1-200 | tr -d '\r')
  printf '%-36s %s\n' "$h" "${v:-MISSING}"
done
echo "--- disclosure"
printf '%s' "$HDRS" | grep -iE '^(server|x-powered-by|x-generator|x-aspnet-version):' | tr -d '\r'

section "Cookies set by the server on first load, before any interaction (PRIV-03, SEC-11)"
COOKIES=$(printf '%s' "$HDRS" | grep -i '^set-cookie:' | tr -d '\r' | cut -c1-220)
if [ -n "$COOKIES" ]; then printf '%s\n' "$COOKIES"; else echo "(none via Set-Cookie; JS-set cookies need a browser check)"; fi

section "Page HTML signals"
HTML=$("${C[@]}" -L "$URL/")
printf '%s' "$HTML" | grep -ioE '<meta[^>]+name=["'"'"']robots["'"'"'][^>]*>' | head -n 3 | sed 's/^/robots meta: /'
printf '%s' "$HTML" | grep -ioE '<link[^>]+rel=["'"'"']canonical["'"'"'][^>]*>' | head -n 1 | sed 's/^/canonical: /'
printf '%s' "$HTML" | grep -ioE '<html[^>]*>' | head -n 1 | sed 's/^/html tag: /'
printf '%s' "$HTML" | grep -oE '(src|href)=["'"'"']http://[^"'"'"']+' | sort -u | head -n 10 | sed 's/^/mixed content: /'
echo "--- third-party script origins in raw HTML (PRIV-01, SEC-21)"
printf '%s' "$HTML" | grep -oiE '<script[^>]+src=["'"'"'][^"'"'"']+' | sed -E 's/.*src=["'"'"']//' \
  | sed -E 's#^//#https://#' | grep -E '^https?://' | sed -E 's#^(https?://[^/]+).*#\1#' | grep -v "$HOST" | sort | uniq -c | sort -rn | head -n 20
echo "--- generator meta"
printf '%s' "$HTML" | grep -ioE '<meta[^>]+name=["'"'"']generator["'"'"'][^>]*>' | head -n 3

section "robots.txt / sitemap (SEO-02, SEO-05)"
"${C[@]}" "$URL/robots.txt" | head -n 20
"${C[@]}" -o /dev/null -w 'sitemap.xml: %{http_code}\n' "$URL/sitemap.xml"

PROBE=$(mktemp); trap 'rm -f "$PROBE"' EXIT
section "Exposed files (SEC-02/03/19) - 200 with real content = problem"
for p in .env .git/HEAD .git/config wp-config.php.bak wp-config.php~ debug.log wp-content/debug.log \
         backup.zip backup.sql database.sql phpinfo.php info.php .DS_Store composer.json package.json \
         wp-content/uploads/ ; do
  code=$("${C[@]}" -o "$PROBE" -w '%{http_code}' "$URL/$p")
  size=$(wc -c < "$PROBE" 2>/dev/null | tr -d ' ')
  flag=""
  [ "$code" = "200" ] && flag="  <-- inspect"
  [ "$p" = "wp-content/uploads/" ] && [ "$code" = "200" ] && grep -qi 'index of' "$PROBE" && flag="  <-- directory listing ON"
  printf '%-28s %s (%s bytes)%s\n' "$p" "$code" "$size" "$flag"
done
rm -f "$PROBE"

if [ "$WP" -eq 1 ] || printf '%s' "$HTML" | grep -q 'wp-content'; then
  section "WordPress exposure (WP-22)"
  "${C[@]}" -o /dev/null -w 'xmlrpc.php: %{http_code} (405 = enabled, POST-only)\n' "$URL/xmlrpc.php"
  "${C[@]}" -o /dev/null -w 'readme.html: %{http_code}\n' "$URL/readme.html"
  USERS=$("${C[@]}" "$URL/wp-json/wp/v2/users")
  if printf '%s' "$USERS" | grep -q '"slug"'; then
    echo "REST users endpoint exposes slugs:"; printf '%s' "$USERS" | grep -oE '"slug":"[^"]+"' | head -n 5
  else echo "REST users endpoint: not exposing slugs"; fi
  "${C[@]}" -o /dev/null -w '/?author=1 -> %{http_code} %{redirect_url}\n' "$URL/?author=1"
fi

echo
echo "Done. JS-set cookies, consent banner behaviour, keyboard nav and CWV need a real browser."
