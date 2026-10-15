# Privacy, cookies & legal checklist

You can verify **technical behaviour** (what loads, when, and what is stored) directly. **Legal adequacy** (is this policy text sufficient, does this business need X) belongs to the owner. Mark it `OWNER` with a precise question, never `PASS`. This checklist targets the strictest common baseline (EU GDPR + ePrivacy, UK GDPR + PECR) and notes US/CA variations. Requirements change: if a rule here looks outdated against what you know, say so in the report and don't apply it blindly.

## Cookies, storage & tracking (verifiable)

- **PRIV-01 Inventory.** List every cookie, localStorage/sessionStorage key and third-party request the site makes, with its origin and purpose. Sources: the scan's tracking-script section, the theme/plugin code, tag managers, and a browser run if available. The inventory goes in the report and feeds PRIV-03 to PRIV-07.
- **PRIV-02 Classify each entry** as strictly necessary (cart, session, security, load balancing, the consent choice itself) or non-essential (analytics, ads, marketing pixels, heatmaps/session replay, A/B tools, most chat widgets, embedded video/maps that set cookies, social embeds).
- **PRIV-03 Nothing non-essential runs before consent** (EU/UK). On first load with no interaction there must be no analytics/ads cookies, no pixel requests, and no session-replay scripts. Check in a real browser if possible. Severity: High.
  - Google tags: Consent Mode v2 must set `ad_storage`, `analytics_storage`, `ad_user_data` and `ad_personalization` to `denied` by default **before** gtag/GTM loads. Advanced mode (cookieless pings before consent) is an `OWNER` decision. Flag it.
  - Embeds (YouTube, Vimeo, Maps, Instagram) are blocked behind a click-to-load placeholder, or use privacy-enhanced modes (`youtube-nocookie.com`) only where that actually avoids storage.
  - Google Fonts or other CDN assets loaded from third-party servers send visitor IPs to that provider. EU courts have penalized this (LG München 2022). Self-host fonts, or flag it as Medium.
- **PRIV-04 The consent banner is fair.** "Reject all" is as easy to reach as "Accept all" (same layer, similar prominence). There are no pre-ticked non-essential categories. The banner doesn't claim "by continuing you agree". Granular categories are offered. Closing the banner is not consent.
- **PRIV-05 Consent is respected and revocable.** After "Reject", non-essential scripts stay off across page loads. A persistent link or button reopens the preferences. Withdrawing consent stops the tags.
- **PRIV-06 Consent is recorded** with timestamp, version and choices (a consent-management tool or server log) so the owner can prove it. Usually confirmed through the CMP config. `OWNER` if unclear.
- **PRIV-07 US opt-out signals.** If the site targets California or similar states and "sells/shares" data (ad pixels count), it needs a "Do Not Sell or Share My Personal Information" link and must honour Global Privacy Control (`navigator.globalPrivacyControl`). `OWNER` to confirm the audience.

## Forms & personal data (verifiable)

- **PRIV-08 Data minimisation.** Forms collect only what the stated purpose needs. Optional fields are marked.
- **PRIV-09 Notice at collection.** Each form that collects personal data links to the privacy policy near the submit button. Marketing opt-in is a separate, unticked checkbox, never bundled with terms acceptance. (Germany: double opt-in for newsletters is the established practice.)
- **PRIV-10 Personal data in transit and at rest.** Forms submit over HTTPS. Submissions don't land in public logs, URLs (no PII in GET params) or analytics events (no emails in `dataLayer` or page titles).
- **PRIV-11 Retention.** Form entries and logs stored by plugins/apps have a retention or cleanup setting. `OWNER` to choose the period.

## Legal pages & disclosures (existence verifiable, content → OWNER)

- **LEG-01 Privacy policy** is present, linked from every page (footer) and from forms. It names the data processors and cookies actually found in PRIV-01. You can verify a mismatch: e.g. the site loads Hotjar but the policy doesn't mention it is a `FAIL`. Whether the overall content is adequate is `OWNER`.
- **LEG-02 Cookie policy / cookie list** is reachable and matches the PRIV-01 inventory.
- **LEG-03 Imprint / Impressum** for sites targeting DE/AT (and similar legal-notice requirements elsewhere): company name, address, contact, register and VAT number. `OWNER` if the market is unclear.
- **LEG-04 Terms & conditions** for any site that sells or offers accounts.
- **LEG-05 Accessibility statement.** Required under the European Accessibility Act (in force since 28 June 2025) for in-scope e-commerce and services. Micro-enterprises (<10 staff and ≤ €2M turnover) are exempt for services. `OWNER` to confirm whether the business is in scope.

## E-commerce consumer law (if the site sells)

- **LEG-06 Pre-contract information.** Total price incl. taxes, shipping costs before checkout, delivery times, payment methods, and seller identity.
- **LEG-07 Withdrawal / returns.** EU/UK consumers have a 14-day right of withdrawal. The policy and the model withdrawal form are reachable. Since 19 June 2026, EU online contracts need an easy withdrawal function on the interface (Directive (EU) 2023/2673). Confirm the current requirement and flag it as `OWNER` if not implemented.
- **LEG-08 Order button wording.** The final button makes clear that clicking creates a payment obligation (e.g. "Order with obligation to pay" / "Buy now", required in DE/EU).
- **LEG-09 Price reductions** show the lowest price of the prior 30 days (EU Omnibus Directive) when a "was" price is displayed.
- **LEG-10 No dark patterns.** No fake countdowns, fake scarcity, fake reviews, pre-ticked add-ons or forced continuity, and cancellation is as easy as sign-up. These are regulated in the EU (DSA/UCPD) and US (FTC rules). Verifiable in code. Severity: High when found.
- **LEG-11 Obsolete links removed.** The EU ODR platform link requirement was dropped in July 2025, so stale ODR links can be removed. Low.

## Platform notes

- **WordPress:** the WP Consent API (`wp_has_consent()`) plus a compatible CMP plugin lets other plugins respect consent. Check that analytics/marketing plugins actually honour it rather than assuming. WooCommerce stores order data, so check its privacy settings (Settings → Accounts & Privacy: retention, erasure requests). Enable the WP core privacy tools (export/erase personal data).
- **Shopify:** tracking in themes must be gated by the Customer Privacy API (`window.Shopify.customerPrivacy`: `analyticsProcessingAllowed()`, `marketingAllowed()`, `preferencesProcessingAllowed()`, `saleOfDataAllowed()`, plus the `visitorConsentCollected` event). Prefer Shopify's customer events / Web Pixels over hard-coded theme scripts. Confirm that a cookie banner is enabled for the markets sold to (Shopify's banner or a CMP app). Apps must implement the mandatory compliance webhooks (see `shopify.md`).
