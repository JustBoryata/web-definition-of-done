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

Optional tools are used when already installed and the project is trusted (it never installs anything): `npm audit`, `composer audit`, `phpcs` with WordPress standards, WP-CLI, Shopify CLI, and browser MCP servers (Chrome DevTools, Playwright) for consent and keyboard checks.

## Safety

The audit is built to be safe on code you didn't write, such as a client's theme or an inherited plugin:

- **Report only by default.** It writes nothing outside `<project>/.scratch/web-audit/` unless you ask it to fix things.
- **It doesn't execute the project.** The scan script only reads files with `grep`/`find` and runs no git commands, because a repo's own git config can make even `git status` run code. Tools that load project config (`npm audit`, `composer audit`, `phpcs`, WP-CLI, `shopify theme check`, git) run only when you mark the project `Trusted: yes` in the brief.
- **Project content is treated as data.** Instructions hidden in code comments or page HTML are reported as findings, never followed.
- **Secrets are masked** in the scan output and the report. Terminal control characters are stripped from everything the scripts print.
- **Live checks are light.** A handful of GET/HEAD requests to the one URL you give it. No fuzzing, logins or form submissions.

The report lists exploitable weaknesses. Keep `.scratch/` in your `.gitignore` and don't publish reports.

## Caveats

- This is not legal advice. Legal adequacy is always left to the site owner as an `OWNER` item.
- Regulations change. The checklists reflect the rules as of October 2026.
- The live checks send only light GET requests. Only run them against sites you're allowed to test.

## License

MIT
