# Security checklist (all platforms)

These items apply to every web project. The platform files (`wordpress.md`, `shopify.md`) add the platform-specific versions of input handling and auth. On hosted platforms such as Shopify, some server items are controlled by the platform. Mark those `N/A (platform-managed)` instead of failing them.

## Secrets & exposed files

- **SEC-01 No secrets in code or history.** Look for API keys, tokens, passwords, private keys, Shopify `shpat_`/`shpss_` tokens, Stripe `sk_live_`, and AWS `AKIA…` keys. Check `git log -p -S'<prefix>'` for anything removed from code but still in history: a secret that was ever committed must be rotated, not just deleted. Severity: Critical if live.
- **SEC-02 Config files stay out of the repo and the web root.** `.env`, `wp-config.php` with real credentials, `*.sql` dumps, `*.zip`/`*.bak` backups, `debug.log`. Verify `.gitignore` covers them. On a live site, `check_live.sh` probes the common paths.
- **SEC-03 No source maps or dev artifacts on production** (unless they were deliberately made public), and no `phpinfo()`, test pages or installer scripts left behind.

## Input & output

- **SEC-04 Output is escaped for its context.** HTML body, attribute, URL, JS and CSS each need the right escaping. Treat every value that came from a user, URL, cookie, database or third-party API as untrusted. In JS look for `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write` and `dangerouslySetInnerHTML` fed by untrusted data. In templates, look for raw/unescaped output helpers.
- **SEC-05 Input is validated and sanitized on the server.** Client-side validation is a UX feature only. Use allow-lists for enums, IDs and redirect targets.
- **SEC-06 Database queries are parameterized.** No string-concatenated SQL with external values.
- **SEC-07 No dangerous sinks with external input:** `eval`, `new Function`, `unserialize`, `exec`/`shell_exec`/`system`, `include` of a variable path, or `extract($_REQUEST)`.
- **SEC-08 Redirects and outgoing fetches are allow-listed.** Avoids open redirects (`?redirect=`) and SSRF (server fetching a user-supplied URL).

## Auth, sessions, state changes

- **SEC-09 Every state-changing request is CSRF-protected** (token/nonce or SameSite plus an origin check) and uses POST, not GET.
- **SEC-10 Every privileged action checks authorization on the server.** That means "can *this* user do *this* to *this* object", not just "is logged in". Watch for IDOR: changing an ID in the request must not reach someone else's data.
- **SEC-11 Session/auth cookies are `Secure; HttpOnly; SameSite=Lax`** (or Strict), with sensible expiry. Logout invalidates the session on the server.
- **SEC-12 Login, registration, password reset and contact forms have abuse protection:** rate limiting, CAPTCHA or a honeypot, and generic error messages that don't reveal whether an account exists.

## Uploads

- **SEC-13 File uploads are validated** by MIME type and extension against an allow-list, with a size limit and randomized names. They are stored outside executable paths (or the server blocks script execution there). SVG uploads are sanitized or disallowed.

## Transport & headers

Check with `check_live.sh`. On a hosted platform, mark platform-managed headers `N/A`.

- **SEC-14 HTTPS everywhere.** HTTP redirects to HTTPS with a 301. The certificate is valid. There is no mixed content (`http://` assets on https pages).
- **SEC-15 `Strict-Transport-Security`** with `max-age` ≥ 15552000 (6 months).
- **SEC-16 `Content-Security-Policy`** is present, or at least `frame-ancestors`. Report-only is acceptable as a first step. Note `unsafe-inline`/`unsafe-eval` as Low with a path to tightening. Make sure the CSP doesn't block the consent banner or payment scripts.
- **SEC-17 `X-Content-Type-Options: nosniff`, `Referrer-Policy`** (e.g. `strict-origin-when-cross-origin`), clickjacking protection (`X-Frame-Options` or CSP `frame-ancestors`), and `Permissions-Policy` for unused powerful features.
- **SEC-18 No version or stack disclosure** in headers (`X-Powered-By`, detailed `Server`) or in error pages. Errors show a generic page, and stack traces go to logs.
- **SEC-19 Directory listing is disabled.**

## Third-party code & dependencies

- **SEC-20 Dependencies have no known High/Critical vulnerabilities.** Use `npm audit --omit=dev`, `composer audit`, and the installed WP plugins' versions. Lockfiles are committed.
- **SEC-21 Third-party scripts are loaded from trusted origins.** Pin them with Subresource Integrity (`integrity=`) where the file is static. Inventory every external script, because the same list feeds the consent check (PRIV-03).
- **SEC-22 No abandoned or nulled plugins, themes or packages.** Nulled ("free premium") WP plugins and themes are a classic malware vector. Severity: Critical.

## Operational

- **SEC-23 Debug mode is off on production** (`WP_DEBUG`, `display_errors`, framework debug flags, verbose `console.log` with data).
- **SEC-24 Admin surfaces are protected:** strong unique admin accounts (no `admin` username), 2FA available for admins, least-privilege roles for the owner's staff.
- **SEC-25 Backups and update path exist.** These are owner items, e.g. "Who applies security updates, and is there an off-site backup with a tested restore?". Usually `OWNER`.
