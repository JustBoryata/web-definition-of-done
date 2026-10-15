---
name: web-definition-of-done
description: Definition-of-done gate for WordPress, Shopify and general web work (security, cookie consent and tracking, privacy and legal pages, WCAG 2.2 accessibility, design, performance, platform practices). MANUAL ONLY — run it only when the user explicitly asks for the definition-of-done check / web audit (e.g. "/web-definition-of-done", "run the DoD check"). Do not run it automatically when a task finishes or before reporting work as done.
---

# Web Definition of Done

Web work is not done when it looks finished. It is done when this gate says so. Run it at the end of every build or styling task, before the work is handed to the site owner. The goal is that the owner never inherits a vulnerability, a consent problem or a broken flow that should have been caught.

You are the independent check that stands between the work and the site owner. The owner will trust anything you mark as passed, so **a false pass is the worst outcome**. A false pass lets a vulnerability or a compliance problem ship silently. "Unverified, here is how to check it" is always acceptable. "Pass" without evidence never is.

## Inputs

You are usually started as a subagent by the agent that did the work. A good brief contains:

- the project path, and what changed (files, diff, or "whole site")
- the live or staging URL, if there is one
- target markets (EU/UK/US/CA/…), and whether the site sells anything
- whether you should only report (the default) or also fix

If something is missing, don't stop to ask. Infer it from the code: currency, language, `hreflang`, shipping zones and legal pages all reveal the market. Record your assumptions at the top of the report. When the market is unknown, assume EU/GDPR rules, because they are the strictest common baseline.

## Workflow

### 1. Establish scope and platform

- **WordPress**: `wp-config.php`, `wp-content/`, `style.css` with a `Theme Name:` header, a PHP file with a `Plugin Name:` header, or `theme.json` next to `functions.php`.
- **Shopify theme**: `layout/theme.liquid`, `sections/`, `snippets/`, `config/settings_schema.json`.
- **Shopify app**: `shopify.app.toml`, `extensions/`, `@shopify/*` packages.
- **General web**: everything else (static, React/Next, PHP, Node, …). The general checklists apply to every platform.

Pick the depth from the kind of work being handed off:

- **Full site or new build** (new theme, plugin, app, site, or launch): run every checklist in full.
- **Feature or functionality change** (forms, checkout, integrations, new scripts, custom code): go deep on the changed code, plus the site-wide items it affects.
- **Styling or layout only** (CSS, templates, visual tweaks): focus on `design-a11y-perf.md`, i.e. contrast, focus states, responsive layout, CLS, and fonts and images. Also confirm that nothing outside styling slipped in. If the diff adds a script, font CDN, embed or form, treat it as a feature change.

For anything short of a full build, run `git diff` / `git status` to see what was touched. Audit those files in depth. Also check the **site-wide items the change can affect**. For example, a new `<script>` tag affects consent, CSP, performance and the privacy policy. A new form affects CSRF, validation, spam protection, the data retention notice and labels.

### 2. Run the static scan

```bash
bash ~/.claude/skills/web-definition-of-done/scripts/scan.sh <project-path>
```

It greps for common risk patterns: secrets, unescaped output, raw SQL, missing nonces, tracking scripts, debug leftovers, `noindex`, and so on. Its hits are **leads, not verdicts**. Open each relevant hit and confirm or dismiss it by reading the code. Empty output for a section does not prove the item passes. It only means that heuristic found nothing.

### 3. Work through the checklists

Read these reference files and go through every item that applies:

| Always | Platform-specific |
|---|---|
| `references/security.md` | `references/wordpress.md` |
| `references/privacy-legal.md` | `references/shopify.md` |
| `references/design-a11y-perf.md` | |

Each item has an ID (e.g. `SEC-04`, `WP-02`). Use those IDs in the report so re-audits can track them.

### 4. Use real tooling when it is already installed

Real tool output is stronger evidence than reading code. Check with `command -v` first. **Don't install global tools or add dependencies to the project.** If a tool is missing, mark the item `UNVERIFIED` and give the exact command the owner can run.

| Tool | Command |
|---|---|
| npm deps | `npm audit --omit=dev` |
| PHP deps | `composer audit` |
| WP coding/security standards | `phpcs --standard=WordPress <path>` |
| WP-CLI (needs a running site) | `wp core verify-checksums`, `wp plugin list --update=available` |
| Shopify theme | `shopify theme check --path <path>` |

### 5. Live checks (only if a URL was given or is in the project config)

```bash
bash ~/.claude/skills/web-definition-of-done/scripts/check_live.sh https://example.com
```

The script checks HTTPS redirects, security headers, cookies set before any interaction, exposed files (`.env`, `.git`, `debug.log`), WordPress user enumeration, and `noindex` left over from staging.

curl can't see cookies or requests made by JavaScript. If browser tools are available (chrome-devtools, playwright or claude-in-chrome MCP), use them for the checks that need a real browser:

- In a fresh context, load the page **without clicking anything**, then list the cookies, localStorage entries and third-party requests. Anything non-essential at this point is a consent failure.
- Click "Reject" and repeat. Nothing non-essential should appear.
- Tab through the page with the keyboard only (focus visibility, traps, skip link).
- Check at 320px and 1440px widths.
- Run a Lighthouse audit for performance and accessibility if it's available.

Only test the site you were asked to audit. Use light GET requests only: no fuzzing, brute force, form spam or load testing. On a production site, don't submit forms or place orders unless the brief says to.

### 6. Write the report

Save it to `<project>/.scratch/web-audit/audit-YYYY-MM-DD.md`. If you are re-auditing on the same day, add `-2`, `-3`, … to the name. Use the template below.

### 7. Return to the caller

Reply with the verdict, the counts, every Critical/High finding (one line each, with `file:line` and the fix), the list of owner items, and the report path. The calling agent needs to act on this, so keep it scannable.

## Statuses and evidence

| Status | Meaning |
|---|---|
| `PASS` | Verified. Evidence **must** be given: `file:line`, command output, or a runtime observation. |
| `FAIL` | A problem was found. Give the severity, location, why it matters, and a concrete fix. |
| `OWNER` | Depends on business facts or legal judgement the code can't answer, e.g. "Do you sell to California residents?" or "Is this privacy policy reviewed by counsel?". State exactly what the owner must confirm. |
| `UNVERIFIED` | Should be checked but couldn't be (no URL, no browser, tool missing). Say what blocks it and how to check it. |
| `N/A` | Doesn't apply. Give a short reason. |

Don't mark legal matters as `PASS` on your own authority. You can verify that a privacy policy page exists and names the cookies you found. Whether its content is legally adequate is an `OWNER` item.

## Severity

- **Critical**: exploitable now, or data is exposed. Examples: SQL injection, auth or capability bypass, RCE, live secret or API token in the repo or public files, publicly readable `.env`/`.git`/backups, stored XSS reachable without login.
- **High**: serious risk or a clear legal exposure. Examples: reflected XSS, CSRF on state-changing actions, missing capability check on an admin action, non-essential tracking firing before consent (EU/UK), no HTTPS, a WCAG blocker on a core flow (e.g. keyboard users can't check out or submit the contact form), known-vulnerable dependency with a public exploit.
- **Medium**: weakens security or compliance, or noticeably hurts users. Examples: missing security headers, insecure cookie flags, missing legal page, contrast failures, missing form labels, Core Web Vitals in the "poor" range, `noindex` on production.
- **Low**: best-practice and polish items.

**Verdict:**
- `BLOCK` if there is any Critical or High FAIL.
- `PASS WITH ISSUES` if there is any Medium or Low FAIL, or any OWNER/UNVERIFIED item touching security or consent.
- `PASS` otherwise.

## Report template

```markdown
# Definition of Done: <project> (<platform>)
Date: YYYY-MM-DD · Scope: <change audit: files… | full site> · URL: <url or none>
Assumptions: <markets, e-commerce yes/no, anything inferred>

## Verdict: BLOCK | PASS WITH ISSUES | PASS
Critical: n · High: n · Medium: n · Low: n · Owner: n · Unverified: n

## Must fix before shipping
1. [SEC-03][High] <one line> (`path/file.php:42`). Fix: <concrete change>

## Owner decisions needed
- [LEG-02] <exact question for the site owner>

## Full checklist
### Security
| ID | Check | Status | Evidence / Fix |
|---|---|---|---|
### Privacy, cookies & legal
### Accessibility & design
### Performance & SEO
### <Platform>

## Not verified and how to verify
- <item>: <command or manual step>
```

## Re-audits

When the calling agent fixes things and asks you again, read the previous report in `.scratch/web-audit/` first. Re-verify every earlier FAIL with fresh evidence and mark it `FIXED (verified: …)` or still `FAIL`. Check that each fix didn't break something nearby, such as an escaping fix that double-escapes, or a CSP that blocks the consent banner. A fix described in the brief is a claim, not evidence. Look at the code yourself.

## Ground rules

- **Report only by default.** You are the independent check, so leave project files alone unless the brief explicitly asks you to fix things. Writing your report into `.scratch/` is fine.
- **Tie every finding to this site.** Generic advice ("consider adding a CSP") without a file, header or observation behind it is noise. Leave it out or make it specific.
- **Severity is about real impact.** A missing `Permissions-Policy` header is not High. A nonce-less AJAX handler that deletes data is not Low.
- **Other installed skills can go deeper**, e.g. `security-review`, `liquid-theme-a11y`, `shopify-app-store-review`, `seo-audit`, `gdpr-*`, `a11y-debugging`. Use them for a deeper pass on a specific area when they are available, but this checklist must be complete without them.
