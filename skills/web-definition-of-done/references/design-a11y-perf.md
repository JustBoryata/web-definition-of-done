# Design, accessibility, performance & SEO checklist

Accessibility is a legal requirement in many markets (EU Accessibility Act, ADA lawsuits in the US) as well as a design matter. Target **WCAG 2.2 AA**. For styling-only handoffs, this file is the main checklist.

## Accessibility (WCAG 2.2 AA)

- **A11Y-01 Text contrast** is ≥ 4.5:1 for body text and ≥ 3:1 for large text (≥ 24px, or ≥ 18.66px bold). UI components and focus indicators are ≥ 3:1 against adjacent colours. Compute the ratio from the actual CSS colours, including hover/disabled states and text over images.
- **A11Y-02 Visible focus** on every interactive element. No `outline: none` without a replacement. Focus isn't hidden behind sticky headers or cookie banners (2.4.11).
- **A11Y-03 Keyboard.** Everything works with Tab/Shift+Tab/Enter/Space/Esc: menus, modals, carousels, the consent banner, cart drawer, and filters. No keyboard traps. Modals move focus in, trap it while open, and return it on close. A skip-to-content link is present.
- **A11Y-04 Semantics.** Real `<button>` for actions, `<a href>` for navigation (no clickable `<div>`). Landmarks (`header`, `nav`, `main`, `footer`). One `h1` with a logical heading order. `lang` on `<html>`.
- **A11Y-05 Images.** Meaningful images have descriptive `alt`. Decorative ones have `alt=""`. Icon-only buttons have an accessible name (`aria-label` or visually hidden text). SVG icons are `aria-hidden` when decorative.
- **A11Y-06 Forms.** Every input has a programmatic `<label>`; a placeholder is not a label. Errors are identified in text (not colour alone), are associated with their field, and are announced. Autocomplete attributes are set on personal-data fields. No redundant re-entry (3.3.7). Login doesn't require puzzles or memory tests (3.3.8).
- **A11Y-07 Target size** is ≥ 24×24 CSS px (2.5.8). 44×44 is recommended for primary mobile controls.
- **A11Y-08 Motion & media.** Autoplaying motion longer than 5s can be paused. Respect `prefers-reduced-motion`. Videos have captions. Nothing flashes more than 3 times per second.
- **A11Y-09 Reflow & zoom.** Content works at 320px wide and at 200% zoom with no horizontal scrolling and no clipped text. `user-scalable=no` / `maximum-scale=1` is not set.
- **A11Y-10 ARIA used correctly.** ARIA doesn't override native semantics wrongly. `aria-expanded`/`aria-controls` sit on disclosure toggles. Live regions are used for cart and update messages.

## Design quality

These are judgement items, so give a short rationale with each FAIL.

- **DES-01 Responsive.** Check layouts at about 320, 375, 768, 1024 and 1440px. No overflow, overlapping elements or tiny text. Images are art-directed or cropped sensibly.
- **DES-02 Consistency.** Spacing, type scale, colours and radii come from tokens or variables (CSS custom properties, `theme.json`, Shopify settings), not one-off magic numbers. Components look and behave the same everywhere.
- **DES-03 All states designed:** hover, focus, active, disabled, loading, empty (empty cart, no search results), error, and success. Forms show clear success and failure feedback.
- **DES-04 Typography.** Body text ≥ 16px, line length about 45–80 characters, line-height ~1.4–1.6. Font loading uses `font-display: swap` or `optional` with no invisible text. Only the font weights actually used are loaded.
- **DES-05 Content robustness.** Layouts survive long product names, long translations (German about +30%), missing images and RTL where relevant. No lorem ipsum, placeholder images, "TODO" or demo content left in.
- **DES-06 Navigation and conversion paths are clear.** The primary action on each key page is obvious, and the user can always tell where they are and how to get back.
- **DES-07 Favicon, app icons, social share image (`og:image`), and a custom 404 page that helps people find their way.**

## Performance

Use Lighthouse or PageSpeed data if available. Otherwise inspect the code.

- **PERF-01 Core Web Vitals targets:** LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1. Lab data gives an estimate; field data (CrUX) is the real measure. Say which one you used.
- **PERF-02 Images.** Modern formats (WebP/AVIF), responsive `srcset`/`sizes`, explicit `width`/`height` or `aspect-ratio` (prevents CLS), `loading="lazy"` below the fold, and **not** lazy-loading the LCP image (consider `fetchpriority="high"`).
- **PERF-03 Render-blocking resources.** Scripts are `defer`/`async` or loaded as modules. CSS is reasonably sized. There are no large unused libraries (a whole jQuery UI for one accordion, etc.).
- **PERF-04 Third-party weight.** Count the third-party scripts. Each one costs performance, privacy and security. Flag duplicates (two analytics tools, several pixel copies).
- **PERF-05 Caching & compression.** Static assets have long cache lifetimes with fingerprinted names. Responses use gzip/brotli. On WP, page caching is configured.
- **PERF-06 Fonts.** Self-hosted, subset, `preload` only the critical font, and a limited number of families and weights.

## SEO basics

- **SEO-01 Unique `<title>` and meta description** on key templates.
- **SEO-02 No `noindex` or `Disallow: /` left over from staging** on production, and staging *is* noindexed or password-protected. Severity: Medium on production.
- **SEO-03 Canonical URLs** are correct (no staging domain, no duplicate-content traps from filters or parameters).
- **SEO-04 Structured data** (Organization, Product, BreadcrumbList, etc.) is valid and matches the visible content.
- **SEO-05 `sitemap.xml`** exists and is referenced in `robots.txt`. `hreflang` is set for multi-language sites.
- **SEO-06 No broken internal links or images** on the pages touched. Redirects are in place for URLs that changed.
