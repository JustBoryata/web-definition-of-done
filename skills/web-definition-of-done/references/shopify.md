# Shopify checklist (themes, theme app extensions, apps)

Shopify hosts the storefront, so TLS, server headers, checkout PCI scope and core patching are platform-managed. Mark them `N/A (platform-managed)`. The risks you own are what the theme or app adds: unescaped Liquid, tracking scripts, leaked tokens, slow assets, inaccessible components and, for apps, the backend.

## Themes: security

- **SHOP-01 Escape untrusted Liquid output.** Shopify Liquid does **not** auto-escape `{{ }}`. Anything that originates from a visitor must use `| escape` in HTML/attribute context. That covers `search.terms`, URL/query params, `cart.note`, cart/line item attributes, `form.errors` values, customer-entered fields and `request.*`. Merchant-authored settings and richtext are trusted content, but they still need `| escape` when placed inside an attribute.
- **SHOP-02 Liquid → JavaScript uses `| json`.** E.g. `const product = {{ product | json }};` and never `'{{ product.title }}'` inside a script string. Prefer `<script type="application/json">` data islands for large data.
- **SHOP-03 No secrets in theme files.** Admin API tokens (`shpat_…`), app secrets and private API keys never go in the theme, because it's public. Storefront API *public* tokens are designed to be public, but give them minimal scopes.
- **SHOP-04 No `{{ content_for_header }}` manipulation.** It's required in `theme.liquid` and must be output as-is (don't parse or modify it).
- **SHOP-05 Third-party script inventory.** Scripts are added through app embeds / theme app extensions or customer events (Web Pixels), not pasted into `theme.liquid`. This feeds the consent check.

## Themes: privacy & consent

- **SHOP-06 Tracking is gated by consent.** Any analytics or marketing script in the theme checks `window.Shopify.customerPrivacy` (load it via `Shopify.loadFeatures([{ name: 'consent-tracking-api', version: '0.1' }], …)`) and listens for `visitorConsentCollected` before firing. Customer events / Web Pixels respect consent automatically, so prefer them. See `privacy-legal.md` PRIV-03.
- **SHOP-07 A cookie banner is enabled for the regions sold to** (Settings → Customer privacy, or a CMP app). This lives in admin rather than code, so it's `OWNER` unless you can see it.
- **SHOP-08 Legacy checkout customizations are retired.** `checkout.liquid` and "Additional scripts" on the order status page are deprecated in favour of Checkout Extensibility (checkout UI extensions, Web Pixels). Flag their presence.

## Themes: quality & performance

- **SHOP-09 `shopify theme check` passes** with no errors. Use it if the CLI is installed; otherwise mark `UNVERIFIED` and give the command `shopify theme check --path <theme>`.
- **SHOP-10 Images** use `image_url` with explicit `width` and `image_tag` (or `srcset`/`sizes` via `image_tag: widths:`), have `loading: 'lazy'` below the fold (not on the hero/LCP image), and output width/height to prevent CLS. No hard-coded CDN URLs at full resolution.
- **SHOP-11 Assets.** JS is `defer`/`type="module"`. No parser-blocking `<script src>` in `<head>`. No jQuery or other large libraries unless they're genuinely needed. Use `stylesheet_tag`/`asset_url`, and use `preload` sparingly. Liquid render cost stays reasonable: no nested loops over `all_products` or large collections.
- **SHOP-12 Sections & blocks are configurable and safe.** The schema has sensible defaults, `info` texts and limits. Settings have `"type"`s that match their use (e.g. `url` for links, `richtext` vs `text`). Sections work in any order and when empty. Presets exist for the theme editor.
- **SHOP-13 Translations.** Storefront strings use `{{ 'key' | t }}` with keys in `locales/*.json`, not hard-coded English. Schema labels use `t:` keys if the theme is distributed.
- **SHOP-14 Accessibility of Shopify components:** variant pickers (radio/select with labels and announced price/availability changes), cart drawer (focus management, live-region updates), predictive search (combobox ARIA pattern), quantity inputs (labelled +/− buttons), and product media galleries (keyboard and alt text). See `design-a11y-perf.md`.
- **SHOP-15 Structured data and SEO.** Product JSON-LD (`{{ product | structured_data }}` or a custom block) matches the visible price and availability. Canonical tags come from `canonical_url`. Pagination and collection filter URLs don't create indexable duplicates.

## Apps (backend + extensions)

- **SHOP-16 Webhooks are HMAC-verified** against the raw request body (`X-Shopify-Hmac-Sha256`) using a constant-time comparison before any processing.
- **SHOP-17 Mandatory compliance webhooks are implemented:** `customers/data_request`, `customers/redact` and `shop/redact`. They must actually export or delete the data, not just return 200.
- **SHOP-18 Auth.** OAuth uses state/nonce validation and HMAC on the callback. Embedded apps authenticate requests with session tokens (App Bridge) and verify the JWT on the backend. Access tokens are stored encrypted, server-side only, and never reach the browser.
- **SHOP-19 Least-privilege scopes.** Request only the access scopes the features use. Protected customer data (names, emails, addresses) requires the approved level and justification.
- **SHOP-20 Multi-tenant isolation.** Every DB query is scoped to the authenticated shop. A request for shop A can never read shop B's data (this is the IDOR check from SEC-10).
- **SHOP-21 Billing and uninstall.** Charges go through the Billing API or Shopify App Pricing. `app/uninstalled` cleans up. Theme changes are made via theme app extensions, not by editing merchant theme files.
- **SHOP-22 App Store requirements** if the app is listed publicly. Use the `shopify-app-store-review` skill if it's available.
