# Web Definition of Done

A [Claude Code](https://claude.com/claude-code) skill and subagent that act as an independent "definition of done" check for WordPress, Shopify and general web work, run before a site is handed to its owner.

It checks:

- **Security**: secrets, escaping, CSRF, auth, uploads, headers, dependencies
- **Privacy & legal**: cookie consent and tracking before consent, forms, legal pages, EU consumer law
- **Accessibility**: WCAG 2.2 AA
- **Design, performance & SEO**: responsive layout, states, Core Web Vitals, leftover `noindex`
- **Platform practices**: WordPress (nonces, capabilities, `$wpdb->prepare`, …) and Shopify (Liquid escaping, Customer Privacy API, app webhooks, …)

Every item has an ID (`SEC-04`, `PRIV-03`, `WP-02`, …). Each item gets `PASS` (only with evidence), `FAIL`, `OWNER` (a business or legal decision), `UNVERIFIED` or `N/A`. The report ends with a **BLOCK / PASS WITH ISSUES / PASS** verdict.

## What's inside

```
skills/web-definition-of-done/
  SKILL.md                 workflow, statuses, severity, report template
  references/              the checklists (security, privacy-legal, design-a11y-perf, wordpress, shopify)
  scripts/scan.sh          static grep scan of a project: leads, not verdicts
  scripts/check_live.sh    light GET-only checks of a live URL (headers, cookies, exposed files)
agents/web-auditor.md      subagent that runs the skill independently of the agent that did the work
```

## Install

```bash
git clone https://github.com/JustBoryata/web-definition-of-done.git
cp -R web-definition-of-done/skills/web-definition-of-done ~/.claude/skills/
cp web-definition-of-done/agents/web-auditor.md ~/.claude/agents/
```

SKILL.md calls the scripts at `~/.claude/skills/web-definition-of-done/scripts/`. If you install the skill somewhere else (for example a project's `.claude/skills/`), update those two paths.

## Use

It is set up to run **only when you ask for it**, because a full audit is expensive. In Claude Code:

- `/web-definition-of-done`, or
- "run the DoD check on this project" / "run web-auditor"

For the most independent result, have the main agent delegate to the `web-auditor` subagent using the brief template in `agents/web-auditor.md`. The report is written to `<project>/.scratch/web-audit/audit-YYYY-MM-DD.md`. If the verdict is BLOCK, fix the Critical/High items and run it again with the previous report path. It re-verifies each earlier failure.

To make it run automatically at the end of web tasks instead, edit the `description` in `SKILL.md` and `agents/web-auditor.md`.

Optional tools are used when already installed (it never installs anything): `npm audit`, `composer audit`, `phpcs` with WordPress standards, WP-CLI, Shopify CLI, and browser MCP servers (Chrome DevTools, Playwright) for consent and keyboard checks.

## Caveats

- This is not legal advice. Legal adequacy is always left to the site owner as an `OWNER` item.
- Regulations change. The checklists reflect the rules as of October 2026.
- The live checks send only light GET requests. Only run them against sites you're allowed to test.

## License

MIT
