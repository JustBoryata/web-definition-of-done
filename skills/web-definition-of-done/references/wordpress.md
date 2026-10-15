# WordPress checklist (themes, plugins, sites)

This file adds WordPress-specific checks to `security.md`. Most WP vulnerabilities fall into a few categories: a missing escape, a missing sanitize, a missing nonce, a missing capability check, or an unprepared query. Check each custom PHP entry point (template output, form handler, AJAX action, REST route, admin page, shortcode, block render callback) against all of them.

## Custom code security

- **WP-01 Escape late, on output.** `esc_html()`, `esc_attr()`, `esc_url()`, `esc_js()`, `esc_textarea()`, `wp_kses_post()` / `wp_kses()` for allowed HTML. Translation helpers include `esc_html__()` / `esc_html_e()` / `esc_attr__()`. Flag `echo $var`, `<?= $var ?>`, and `printf` with unescaped arguments. Values from `get_option`, `get_post_meta` and `get_the_title` still need escaping, because they can contain user-entered data.
- **WP-02 Sanitize early, on input.** `sanitize_text_field()`, `sanitize_email()`, `sanitize_key()`, `absint()`/`intval()`, `esc_url_raw()`, `wp_unslash()` before sanitizing superglobals. Settings registered with `register_setting()` have a `sanitize_callback`.
- **WP-03 Nonces on every state change.** Forms use `wp_nonce_field()` with `check_admin_referer()`/`wp_verify_nonce()`. AJAX uses `check_ajax_referer()`. REST requests from the logged-in front end send `X-WP-Nonce`.
- **WP-04 Capability checks** with `current_user_can( '<specific_cap>' )` on every privileged handler. A nonce is **not** an authorization check, and neither is `is_admin()` (it only says the request targets an admin page). `wp_ajax_nopriv_*` handlers must be safe for anonymous users.
- **WP-05 REST routes** have a `permission_callback` that checks capabilities. `__return_true` is acceptable only for genuinely public, read-only data. Args declare `validate_callback`/`sanitize_callback`.
- **WP-06 `$wpdb` queries use `$wpdb->prepare()`** with placeholders for every external value. `LIKE` uses `$wpdb->esc_like()`. Table and column names that come from input are allow-listed.
- **WP-07 Direct file access guard.** Every PHP file that isn't a template entry point starts with `defined( 'ABSPATH' ) || exit;`.
- **WP-08 No dangerous functions on external input:** `unserialize` (use `maybe_unserialize` only on trusted data, or JSON), `extract`, `eval`, `base64_decode` used to hide code, `create_function`, `system`/`exec`, or `include` with a variable path. Obfuscated code in a theme or plugin is a malware indicator. Severity: Critical until explained.
- **WP-09 Uploads** go through `wp_handle_upload()` / `media_handle_upload()` with `wp_check_filetype_and_ext()`. Allowed MIME types aren't widened without a reason. Unsanitized SVG uploads are not allowed.
- **WP-10 Redirects** use `wp_safe_redirect()` followed by `exit`.
- **WP-11 Remote requests** use `wp_remote_get/post` (or `wp_safe_remote_*` for user-supplied URLs) and check the response codes.

## Theme & plugin practices

- **WP-12 Assets are enqueued properly.** `wp_enqueue_script/style` with version strings and dependencies, and scripts in the footer or with a `strategy` of `defer`/`async`. No hard-coded `<script>`/`<link>` tags in `header.php`. No bundled copy of jQuery replacing core's.
- **WP-13 Prefixing / namespacing.** Functions, classes, options, hooks, handles and CPT slugs are prefixed so they can't collide with other code.
- **WP-14 Child theme for customizations of third-party themes.** Edits to a parent theme or plugin are lost on the next update. Severity: Medium.
- **WP-15 Internationalization.** User-facing strings are wrapped in `__()`/`_e()`/`esc_html__()` with a consistent text domain.
- **WP-16 Block themes & blocks.** Colours, spacing and fonts are defined in `theme.json` rather than one-off CSS. Custom blocks have `block.json`, escape in the render callback, and give editors accessible defaults.
- **WP-17 No heavy work on every request.** No remote calls or uncached heavy queries on `init`/`wp_head`. Transients or object cache are used where appropriate. Cron jobs are scheduled once, not on every page load.
- **WP-18 Clean uninstall.** Plugins provide `uninstall.php` (or a hook) that removes their options and tables when the user asks for that.

## Site configuration (needs a running site or wp-config access)

- **WP-19 Core, themes and plugins are up to date.** Run `wp core verify-checksums` and `wp plugin verify-checksums --all` if WP-CLI is available. Remove unused and inactive plugins and themes, because inactive plugins still carry exploitable code.
- **WP-20 Plugin provenance.** Every plugin comes from wp.org or a reputable vendor with a licence. No nulled premium plugins. Check for known-vulnerable versions (WPScan/Patchstack/Wordfence databases, if the owner has access).
- **WP-21 `wp-config.php` hardening.** `WP_DEBUG` false on production (or `WP_DEBUG_LOG` pointing outside the web root with `WP_DEBUG_DISPLAY` false). `DISALLOW_FILE_EDIT` true. Unique salts. A non-default table prefix is nice to have.
- **WP-22 User enumeration & XML-RPC.** `/?author=1` and `/wp-json/wp/v2/users` don't expose login names to anonymous users unless that's intended. XML-RPC is disabled if nothing (Jetpack, the mobile app) needs it. `check_live.sh` tests these.
- **WP-23 Login hardening.** No `admin` username, 2FA for administrators, login rate limiting (security plugin or host level).
- **WP-24 File permissions.** Files are 644, directories 755, and `wp-config.php` is 640/600 where the host allows it. The uploads directory doesn't execute PHP.
- **WP-25 Privacy tooling.** Settings → Privacy has a privacy policy page assigned. WooCommerce sites set retention and erasure options (see `privacy-legal.md`).

## Tools

- `phpcs --standard=WordPress` (WordPress Coding Standards, including the `WordPress.Security` sniffs: EscapeOutput, NonceVerification, ValidatedSanitizedInput, `WordPress.DB.PreparedSQL`). Use it if it's installed. The security sniffs alone are the highest-value part.
- `wp` (WP-CLI) for checksums, plugin versions, `wp option get` and `wp user list --role=administrator`.
- Plugin Check (the `plugin-check` plugin / `wp plugin check`) for plugins meant for distribution.
