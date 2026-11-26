# SudoWP All-in-One Event Calendar (Legacy Rescue)

![WP Version](https://img.shields.io/badge/WordPress-6.7%2B-blue)
![PHP Version](https://img.shields.io/badge/PHP-8.2%2B-purple)
![Status](https://img.shields.io/badge/Status-Maintenance-orange)
![Security](https://img.shields.io/badge/Security-Hardened-green)

**A community-maintained rescue of the All-in-One Event Calendar plugin.**

Maintained by **SudoWP**, this project ensures that the 100,000+ sites relying on this plugin can continue to function after the original developer (Timely) shut it down in August 2025.

## The Situation
The original plugin was closed on WordPress.org to force a migration to a SaaS platform.
* **Problem:** The legacy code produces errors on WordPress 6.7 (e.g., `_load_textdomain_just_in_time`) and lacks PHP 8.2 support.
* **Solution:** This fork fixes the compatibility issues and acts as a stable, standalone version.

## Patches & Improvements

### 1. Boot Fix (v3.0.4)
* **Issue:** Releases 3.0.2 and 3.0.3 activated but never started the calendar. The `[ai1ec]` shortcode and the event post type were missing.
* **Fix:** Restored the original Timely startup sequence in the main plugin file. Drop-in update: no option, post type, taxonomy, shortcode or database changes.

### 2. Security Hardening (v3.0.3 to v3.0.5)
* **XSS Prevention:** Fixed JSONP callback injection vulnerability with strict whitelist validation
* **Path Traversal:** Secured theme switching with directory validation
* **Input Validation:** All user inputs sanitized following OWASP guidelines
* **Authorization:** Enhanced capability checks on AJAX endpoints
* **PHP 8 Compatibility:** Replaced deprecated `create_function()`
* **Documentation:** Added comprehensive [SECURITY.md](SECURITY.md) policy

### 3. WordPress 6.7 Compatibility
* **Issue:** The original plugin loaded translations too early, triggering PHP notices in the admin panel.
* **Fix:** We deferred `load_plugin_textdomain` to the `init` hook, complying with modern WP standards.
* **Remaining:** One `_load_textdomain_just_in_time` notice is still logged, because setting labels are translated during startup (`app/model/settings.php`). Scheduled for the next release.

### 4. Modernization
* **Strict Typing:** The main entry point now enforces `declare(strict_types=1);`.
* **Security:** Follow OWASP Top 10 and WordPress security best practices.

## Security

This plugin has undergone a comprehensive security audit. See [SECURITY.md](SECURITY.md) for:
- Vulnerability disclosure policy
- Security audit results
- Fixed vulnerabilities (XSS, Path Traversal, Input Validation)
- Security best practices

To report security issues, please email: security@sudowp.com

## Installation

1.  Download the repository.
2.  Deactivate the original "All-in-One Event Calendar".
3.  Upload `sudowp-all-in-one-event-calendar` to your plugins directory.
4.  Activate.

**Disclaimer:** This is a Maintenance Fork. We are NOT adding new features. Our goal is to keep the existing calendar functionality working securely on modern servers.

## Changelog

See [readme.txt](readme.txt) for detailed changelog.

**Latest Version: 3.0.5 (Security Edition)**
- 3.0.4 was tagged but never released; its changes ship for the first time in 3.0.5
- Critical fix: the event editor's Repeat dialog and the other admin AJAX actions work again (3.0.4 checked a nonce it never issued)
- Every admin AJAX action now checks a nonce and a capability; subscribers can no longer change the feed import frequency, search suggested events or rescan the template cache
- Critical fix (from 3.0.4): 3.0.2 and 3.0.3 did not boot (missing `[ai1ec]` shortcode and event post type); the original startup sequence is restored
- From 3.0.4: an SQL injection fix in the suggested-event import, a restricted unserialize of the stored event cost, and the "Try reactivating plugin" link now requires the `activate_plugins` capability and a valid nonce

## Next Release
- **Future fatal:** `lib/exception/handler.php:93` uses the `E_STRICT` constant, deprecated since PHP 8.4. When PHP removes it, the plugin will stop with a fatal error while it starts.
- PHP 8.4+ deprecations: implicitly nullable parameters in `lib/bootstrap/loader.php:123`, `lib/theme/loader.php:242`, `lib/less/lessphp.php:105`, `lib/css/frontend.php:222` and `lib/database/helper.php:296`; `case ...;` statements in `vendor/lessphp/lessc.inc.php:748` and `lib/iCal/iCalcnv-3.0/iCalcnv.class.php:1179` and `:1771`
- PHP 8.2+ deprecations logged in debug.log: dynamic properties `Ai1ec_Scheduling_Utility::$_updated`, `Ai1ec_Http_Request::$_registry`, `lessc::$formatterName`, and `${var}` interpolation in `vendor/lessphp/lessc.inc.php`
- The remaining `_load_textdomain_just_in_time` notice from `app/model/settings.php`
- **Hardening:** the main plugin file sets `unserialize_callback_func` to `spl_autoload_call` for the whole request, so any `unserialize()` call on the site, including WordPress core and other plugins, can load this plugin's classes. To be narrowed or removed.

---
*Forked and maintained by the SudoWP Project.*