#!/usr/bin/env bash
# Static heuristic scan for web projects (WordPress, Shopify, general).
# Output is LEADS for manual review, not verdicts. Read each hit in context.
# Usage: scan.sh <project-path> [max-hits-per-check]

set -u
ROOT="${1:-.}"
MAX="${2:-25}"
[ -d "$ROOT" ] || { echo "Not a directory: $ROOT" >&2; exit 1; }
echo "Project: $(cd "$ROOT" && pwd)  (paths below are relative to it)"
cd "$ROOT" || exit 1
ROOT=.

EXCLUDES=(--exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git
  --exclude-dir=dist --exclude-dir=build --exclude-dir=.next --exclude-dir=.scratch
  --exclude-dir=wp-admin --exclude-dir=wp-includes --exclude='*.min.js' --exclude='*.min.css'
  --exclude='*.map' --exclude='*.lock' --exclude='package-lock.json')
WEB=(--include='*.php' --include='*.js' --include='*.mjs' --include='*.ts' --include='*.tsx'
  --include='*.jsx' --include='*.vue' --include='*.svelte' --include='*.html' --include='*.htm'
  --include='*.liquid' --include='*.twig' --include='*.json' --include='*.env*' --include='*.yml'
  --include='*.yaml' --include='*.toml' --include='*.ini' --include='*.txt' --include='*.xml')

section() { printf '\n=== %s ===\n' "$1"; }

# hits <label> <regex> <include-args...>
hits() {
  local label="$1" re="$2"; shift 2
  local out
  out=$(grep -rnIE "${EXCLUDES[@]}" "$@" -e "$re" "$ROOT" 2>/dev/null | cut -c1-240)
  if [ -n "$out" ]; then
    local n; n=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
    printf -- '--- %s (%s hits%s)\n' "$label" "$n" "$([ "$n" -gt "$MAX" ] && echo ", showing $MAX")"
    printf '%s\n' "$out" | head -n "$MAX"
  fi
}

# --- platform detection ---------------------------------------------------
section "Platform detection"
PLATFORM="general"
if [ -f "$ROOT/wp-config.php" ] || [ -d "$ROOT/wp-content" ] \
   || grep -rqlE "${EXCLUDES[@]}" --include='*.php' --include='style.css' "^[[:space:]/*]*(Plugin|Theme) Name:" "$ROOT" 2>/dev/null; then
  PLATFORM="wordpress"
fi
if [ -f "$ROOT/layout/theme.liquid" ] || [ -d "$ROOT/sections" -a -d "$ROOT/snippets" ]; then
  PLATFORM="shopify-theme"
fi
if [ -f "$ROOT/shopify.app.toml" ]; then PLATFORM="shopify-app"; fi
echo "Detected: $PLATFORM"
[ -d "$ROOT/.git" ] && { echo "Git: yes"; git -C "$ROOT" status --short 2>/dev/null | head -n 30; }

# --- secrets & exposed files ----------------------------------------------
section "Secrets (SEC-01) - rotate anything real, even if later removed"
hits "Possible secrets/tokens" \
  '(sk_live_[0-9A-Za-z]{10,}|rk_live_|AKIA[0-9A-Z]{16}|shp(at|ss|ca|pa)_[0-9a-fA-F]{20,}|xox[baprs]-[0-9A-Za-z-]{10,}|gh[pousr]_[A-Za-z0-9]{30,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(api[_-]?key|secret|password|passwd|token)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$ {]{12,}["'"'"'])' \
  "${WEB[@]}"

section "Sensitive files present in tree (SEC-02/03)"
find "$ROOT" \( -path '*/node_modules' -o -path '*/vendor' -o -path '*/.git' \) -prune -o -type f \
  \( -name '.env' -o -name '.env.*' -o -name '*.sql' -o -name '*.sql.gz' -o -name '*.bak' -o -name '*.old' \
     -o -name 'debug.log' -o -name 'error_log' -o -name 'phpinfo.php' -o -name '*.zip' -o -name 'id_rsa*' -o -name '*.pem' \) \
  -print 2>/dev/null | grep -v '\.env\.example$' | head -n "$MAX"
if [ -f "$ROOT/.gitignore" ]; then
  for p in .env '*.sql' '*.log' wp-config.php; do
    grep -qF "$p" "$ROOT/.gitignore" || echo "note: .gitignore has no entry matching '$p'"
  done
elif [ -d "$ROOT/.git" ]; then echo "note: no .gitignore"; fi

# --- generic code risks ---------------------------------------------------
section "Dangerous JS sinks (SEC-04/07) - check data source"
hits "DOM HTML injection / eval" '(\.innerHTML[[:space:]]*\+?=|outerHTML[[:space:]]*=|insertAdjacentHTML|document\.write\(|dangerouslySetInnerHTML|[^.a-zA-Z_]eval\(|new Function\()' \
  --include='*.js' --include='*.mjs' --include='*.ts' --include='*.tsx' --include='*.jsx' --include='*.vue' --include='*.svelte' --include='*.html' --include='*.liquid' --include='*.php'

section "Mixed content / insecure URLs (SEC-14)"
hits "http:// in src/href/url()" '(src|href|action)=["'"'"']http://|url\(["'"'"']?http://' \
  --include='*.html' --include='*.php' --include='*.liquid' --include='*.css' --include='*.scss' --include='*.js' --include='*.jsx' --include='*.tsx' --include='*.twig'

section "Debug leftovers (SEC-23)"
hits "Debug flags / dumps" "(WP_DEBUG['\"]?[[:space:]]*,[[:space:]]*true|display_errors|error_reporting\(E_ALL|var_dump\(|print_r\(|phpinfo\(|debugger;)" \
  --include='*.php' --include='*.js' --include='*.ts' --include='*.ini'
hits "console.log (verify no personal data)" 'console\.(log|debug)\(' \
  --include='*.js' --include='*.mjs' --include='*.ts' --include='*.tsx' --include='*.jsx' --include='*.liquid' --include='*.vue'

section "Placeholder content (DES-05)"
hits "Lorem / TODO / FIXME / demo" '(lorem ipsum|TODO|FIXME|XXX:|example\.com|placeholder\.com|via\.placeholder)' \
  --include='*.php' --include='*.liquid' --include='*.html' --include='*.json' --include='*.js' --include='*.jsx' --include='*.tsx' --include='*.twig'

# --- privacy / tracking ---------------------------------------------------
section "Tracking & third-party scripts (PRIV-01/03) - each must be consent-gated or strictly necessary"
hits "Analytics / ads / pixels / replay" '(googletagmanager\.com|gtag\(|google-analytics\.com|analytics\.js|fbq\(|connect\.facebook\.net|hotjar|clarity\.ms|snap\.licdn\.com|tiktok\.com/i18n/pixel|analytics\.tiktok|pinimg\.com/ct|matomo|plausible|segment\.(com|io)|mixpanel|fullstory|mouseflow|klaviyo|criteo|doubleclick|adsbygoogle|bing\.com/bat|tawk\.to|intercom|crisp\.chat|hs-scripts|hubspot)' \
  --include='*.php' --include='*.liquid' --include='*.html' --include='*.js' --include='*.jsx' --include='*.tsx' --include='*.twig' --include='*.json'
hits "Third-party embeds / fonts (PRIV-03)" '(youtube\.com/embed|player\.vimeo|maps\.google|google\.com/maps|fonts\.googleapis\.com|fonts\.gstatic\.com|use\.typekit|instagram\.com/embed|platform\.twitter)' \
  --include='*.php' --include='*.liquid' --include='*.html' --include='*.css' --include='*.scss' --include='*.js' --include='*.jsx' --include='*.tsx' --include='*.json'
hits "Consent mechanisms found" '(consent|cookiebot|onetrust|complianz|cookieyes|iubenda|usercentrics|borlabs|customerPrivacy|wp_has_consent|gtag\(.consent)' \
  --include='*.php' --include='*.liquid' --include='*.html' --include='*.js' --include='*.jsx' --include='*.tsx'
grep -rqIE "${EXCLUDES[@]}" --include='*.php' --include='*.liquid' --include='*.html' --include='*.js' --include='*.jsx' --include='*.tsx' \
  '(consent|cookiebot|onetrust|complianz|cookieyes|iubenda|usercentrics|borlabs|customerPrivacy|wp_has_consent)' "$ROOT" 2>/dev/null \
  || echo "--- No consent mechanism found in code (may be platform/plugin-managed; verify in a browser or mark OWNER)"

section "SEO leftovers (SEO-02)"
hits "noindex / disallow" '(noindex|Disallow:[[:space:]]*/[[:space:]]*$|blog_public)' \
  --include='*.php' --include='*.liquid' --include='*.html' --include='robots.txt' --include='*.txt' --include='*.json'

section "Accessibility quick leads (A11Y)"
hits "outline removed" 'outline:[[:space:]]*(none|0)' --include='*.css' --include='*.scss' --include='*.liquid' --include='*.php' --include='*.html'
hits "zoom disabled" '(user-scalable[[:space:]]*=[[:space:]]*no|maximum-scale[[:space:]]*=[[:space:]]*1[^.0-9])' --include='*.html' --include='*.php' --include='*.liquid'
hits "clickable non-buttons" '<(div|span)[^>]*on[Cc]lick' --include='*.html' --include='*.php' --include='*.liquid' --include='*.jsx' --include='*.tsx' --include='*.vue'
NOALT=$(grep -rnIE "${EXCLUDES[@]}" --include='*.html' --include='*.php' --include='*.liquid' --include='*.twig' '<img[^>]*>' "$ROOT" 2>/dev/null \
  | grep -v 'alt=' | cut -c1-200 | head -n "$MAX")
[ -n "$NOALT" ] && printf -- '--- <img> tags without alt on the same line\n%s\n' "$NOALT"

# --- WordPress ------------------------------------------------------------
if [ "$PLATFORM" = "wordpress" ]; then
  PHP=(--include='*.php')
  section "WordPress (wordpress.md)"
  hits "WP-01 echo/print of variables (check escaping)" '(echo|print)[[:space:]]+\$[a-zA-Z_]|<\?=[[:space:]]*\$' "${PHP[@]}"
  hits "WP-01 echo of functions that are often unescaped" 'echo[[:space:]]+(get_option|get_post_meta|get_the_title|get_field|get_query_var|\$_)' "${PHP[@]}"
  hits "WP-02 superglobals (check sanitize + unslash)" '\$_(GET|POST|REQUEST|COOKIE|SERVER|FILES)\[' "${PHP[@]}"
  echo "--- WP-06 \$wpdb queries without prepare() on the same line"
  grep -rnIE "${EXCLUDES[@]}" "${PHP[@]}" '\$wpdb->(query|get_results|get_row|get_var|get_col)\(' "$ROOT" 2>/dev/null \
    | grep -v 'prepare' | cut -c1-240 | head -n "$MAX"
  hits "WP-03/04 AJAX handlers (verify nonce + capability)" "add_action\([[:space:]]*['\"]wp_ajax_(nopriv_)?" "${PHP[@]}"
  hits "WP-03/04 admin-post handlers" "add_action\([[:space:]]*['\"]admin_post_(nopriv_)?" "${PHP[@]}"
  hits "WP-05 REST routes (verify permission_callback)" 'register_rest_route\(' "${PHP[@]}"
  hits "WP-05 public REST permission" "permission_callback['\"]?[[:space:]]*=>[[:space:]]*['\"]__return_true" "${PHP[@]}"
  hits "Nonce / capability usage (for cross-check)" '(wp_verify_nonce|check_admin_referer|check_ajax_referer|current_user_can)\(' "${PHP[@]}"
  hits "WP-08 dangerous functions" '([^_a-z]unserialize\(|[^_a-z]extract\(|base64_decode\(|create_function\(|shell_exec\(|[^_a-z]system\(|passthru\(|[^_a-z]exec\(|assert\(|preg_replace\(.*/e)' "${PHP[@]}"
  hits "WP-09 uploads" '(\$_FILES|move_uploaded_file|upload_mimes|wp_handle_upload)' "${PHP[@]}"
  hits "WP-10 redirects (prefer wp_safe_redirect)" '(wp_redirect\(|header\([[:space:]]*["'"'"']Location)' "${PHP[@]}"
  hits "WP-12 hard-coded script/style tags in PHP" '<(script[^>]+src=|link[^>]+stylesheet)' "${PHP[@]}"
  echo "--- WP-07 PHP files without ABSPATH guard (excluding templates is your call)"
  grep -rLIE "${EXCLUDES[@]}" "${PHP[@]}" "(defined\([[:space:]]*['\"]ABSPATH|ABSPATH[[:space:]]*\)[[:space:]]*\|\||WPINC)" "$ROOT" 2>/dev/null \
    | grep -vE '/(index|header|footer|sidebar|single|page|archive|search|404|front-page|home|comments|functions|wp-config)[^/]*\.php$|/templates?/|/template-parts/|/parts/|/patterns/' | head -n "$MAX"
  if [ -f "$ROOT/wp-config.php" ]; then
    echo "--- wp-config.php hardening (WP-21)"
    grep -nE "WP_DEBUG|DISALLOW_FILE_EDIT|table_prefix|WP_ENVIRONMENT_TYPE" "$ROOT/wp-config.php" | sed 's/DB_PASSWORD.*/DB_PASSWORD [redacted]/'
    grep -q DISALLOW_FILE_EDIT "$ROOT/wp-config.php" || echo "note: DISALLOW_FILE_EDIT not set"
  fi
fi

# --- Shopify --------------------------------------------------------------
case "$PLATFORM" in shopify-*)
  LQ=(--include='*.liquid')
  section "Shopify (shopify.md)"
  echo "--- SHOP-01 visitor-controlled output without | escape"
  grep -rnIE "${EXCLUDES[@]}" "${LQ[@]}" '\{\{[^}]*(search\.terms|request\.|cart\.note|\.attributes|form\.errors|customer\.(first_name|last_name|name|email)|params)[^}]*\}\}' "$ROOT" 2>/dev/null \
    | grep -v 'escape' | cut -c1-240 | head -n "$MAX"
  echo "--- SHOP-02 Liquid inside JS without | json (heuristic)"
  grep -rnIE "${EXCLUDES[@]}" "${LQ[@]}" "(=|:)[[:space:]]*['\"]?\{\{[^}]*\}\}['\"]?[[:space:]]*[,;]" "$ROOT" 2>/dev/null \
    | grep -v '| *json' | cut -c1-240 | head -n "$MAX"
  hits "SHOP-06 consent API usage" '(customerPrivacy|consent-tracking-api|visitorConsentCollected|analyticsProcessingAllowed|marketingAllowed)' "${LQ[@]}" --include='*.js'
  hits "SHOP-08 legacy checkout files" 'checkout' --include='checkout.liquid'
  hits "SHOP-10 img tags not using image_url/image_tag" '<img[^>]*src=["'"'"'][^"'"'"']*(\{\{[^}]*(img_url|asset_url)|https?://)' "${LQ[@]}"
  hits "SHOP-10 deprecated img_url filter" '\|[[:space:]]*img_url' "${LQ[@]}"
  hits "SHOP-11 blocking scripts" '<script[^>]+src=[^>]*>' "${LQ[@]}"
  hits "SHOP-13 hard-coded English (sample)" '>[[:space:]]*(Add to cart|Sold out|Checkout|Subscribe|Search|Your cart)[[:space:]]*<' "${LQ[@]}"
  [ -f "$ROOT/layout/theme.liquid" ] && { grep -q 'content_for_header' "$ROOT/layout/theme.liquid" && echo "content_for_header: present" || echo "content_for_header: MISSING in layout/theme.liquid"; }
  if [ "$PLATFORM" = "shopify-app" ]; then
    hits "SHOP-16 webhook HMAC verification" '(X-Shopify-Hmac-Sha256|validateHmac|verifyWebhook|authenticate\.webhook|timingSafeEqual)' --include='*.js' --include='*.ts' --include='*.rb' --include='*.php' --include='*.py'
    hits "SHOP-17 compliance webhooks" '(customers/data_request|customers/redact|shop/redact|CUSTOMERS_DATA_REQUEST|CUSTOMERS_REDACT|SHOP_REDACT)' --include='*.toml' --include='*.js' --include='*.ts' --include='*.rb' --include='*.php' --include='*.py'
    [ -f "$ROOT/shopify.app.toml" ] && { echo "--- SHOP-19 scopes"; grep -nE '^\s*scopes' "$ROOT/shopify.app.toml"; }
  fi
;; esac

# --- dependency tooling hints --------------------------------------------
section "Dependency audit (SEC-20) - run if tools are installed"
[ -f "$ROOT/package.json" ] && echo "package.json found -> npm audit --omit=dev $( [ -f "$ROOT/package-lock.json" ] || echo '(no package-lock.json!)')"
[ -f "$ROOT/composer.json" ] && echo "composer.json found -> composer audit $( [ -f "$ROOT/composer.lock" ] || echo '(no composer.lock!)')"
command -v phpcs >/dev/null && echo "phpcs available" || echo "phpcs not installed"
command -v wp >/dev/null && echo "wp-cli available" || echo "wp-cli not installed"
command -v shopify >/dev/null && echo "shopify cli available" || echo "shopify cli not installed"

echo
echo "Scan complete. Hits are leads, not findings: confirm each in context before reporting."
