=== SudoWP All-in-One Event Calendar (Legacy Rescue) ===
Contributors: SudoWP, WP Republic
Original Authors: Timely (Time.ly)
Tags: calendar, events, sudowp, legacy, rescue, php8, security
Requires at least: 6.0
Tested up to: 6.7
Stable tag: 3.0.4
License: GPLv2 or later
License URI: http://www.gnu.org/licenses/gpl-2.0.html

A community-maintained rescue of the "All-in-One Event Calendar" plugin. Security hardened, fixes WP 6.7 notices and keeps the plugin alive after the official shutdown.

== Description ==

This is SudoWP All-in-One Event Calendar, a forked maintenance release of the original plugin by Timely.

**Why this fork?**
On August 2025, the original developers shut down this plugin ("Author Request") to migrate users to a SaaS platform. This left over 100,000 active installations with a plugin that throws warnings in WordPress 6.7 and has no update path.

**SudoWP Mission:**
We maintain this fork to ensure existing users can keep their calendars running on modern servers (PHP 8.2+) without being forced to migrate to a paid external service.

**Security & Stability Patches (v3.0.3 and v3.0.4):**
* **Boot fix (v3.0.4):** Restored the original startup sequence. Releases 3.0.2 and 3.0.3 activated but never started the calendar, so the [ai1ec] shortcode and the event post type were missing
* **Security Hardening:** Fixed XSS vulnerability (JSONP callback injection), path traversal, and enhanced input validation following OWASP guidelines
* **Authorization:** Added capability checks to all AJAX endpoints to prevent unauthorized access
* **Input Validation:** All user inputs properly sanitized using WordPress security functions
* **PHP 8 Compatibility:** Replaced deprecated functions for full PHP 8.0+ support
* **WP 6.7 Fix:** Translation loading deferred to the init hook. One "_load_textdomain_just_in_time" notice remains, listed under Known Issues in the 3.0.4 changelog
* **Modernization:** The main plugin file uses Strict Types
* **Documentation:** Added comprehensive security policy (SECURITY.md)
* **Branding:** Renamed to "sudowp-all-in-one-event-calendar" to separate it from the discontinued upstream version

For detailed security information, see the SECURITY.md file in the plugin directory.

== Installation ==

1. **Backup:** Always backup your database before switching plugins.
2. **Deactivate:** Deactivate the original "All-in-One Event Calendar".
3. **Upload:** Upload the "sudowp-all-in-one-event-calendar" folder to "/wp-content/plugins/".
4. **Activate:** Activate "SudoWP All-in-One Event Calendar".

== Changelog ==

= 3.0.4 (SudoWP Security Edition) - November 2026 =
* **FIX (critical):** 3.0.2 and 3.0.3 did not boot. They activated without error, but the bootloader written for 3.0.2 never started the calendar application: the [ai1ec] shortcode, the ai1ec_event post type, the admin menus and the front-end calendar were all missing. Sites that removed the original Timely plugin before switching had no working calendar.
* **FIX:** Restored the original Timely startup sequence (class loader, exception handler, front controller, with their original hooks and priorities) in the main plugin file. No option names, post types, taxonomies, shortcode names or database tables change: it is a drop-in update.
* **FIX:** Translations load from the plugin's own folder whatever the folder is called.
* **TESTS:** Added a boot smoke test (tests/smoke/smoke-test.sh; not shipped in the release zip).
* **SECURITY:** SQL injection fix using wpdb prepare on all raw queries.
* **SECURITY:** Unsafe unserialize replaced with safe deserialization (allowed_classes restriction).
* **SECURITY:** Added nonce and capability checks on 7 AJAX handlers.
* **SECURITY:** Input sanitization on recurrence fields and feed URLs.
* **SECURITY:** The "Try reactivating plugin" link (?ai1ec_reactivate_plugin) now requires the activate_plugins capability and a valid nonce. Before, any visitor, logged in or not, could re-enable the calendar after it had disabled itself because of an error. Administrators see the same button and one extra redirect.
* **KNOWN ISSUES (next release):** None of these stop the plugin working today.
* PHP 8.4+ future fatal: lib/exception/handler.php:93 uses the E_STRICT constant, deprecated since PHP 8.4. When PHP removes it, the plugin will stop with a fatal error while it starts.
* PHP 8.4+ deprecations: implicitly nullable parameters in lib/bootstrap/loader.php:123, lib/theme/loader.php:242, lib/less/lessphp.php:105, lib/css/frontend.php:222 and lib/database/helper.php:296; "case ...;" statements in vendor/lessphp/lessc.inc.php:748 and lib/iCal/iCalcnv-3.0/iCalcnv.class.php:1179 and :1771.
* PHP 8.2+ deprecations: dynamic properties Ai1ec_Scheduling_Utility::$_updated (lib/scheduling/utility.php), Ai1ec_Http_Request::$_registry (lib/http/request.php) and lessc::$formatterName, and "${var}" string interpolation in vendor/lessphp/lessc.inc.php.
* WordPress 6.7+ still logs one "_load_textdomain_just_in_time" notice because setting labels are translated while the plugin starts (app/model/settings.php).
* Hardening: the main plugin file sets unserialize_callback_func to spl_autoload_call for the whole request, so any unserialize() call on the site, including WordPress core and other plugins, can load this plugin's classes. To be narrowed or removed.

= 3.0.3 (SudoWP Security Edition) - February 2026 =
* **SECURITY:** Fixed JSONP callback injection vulnerability (XSS) - Added strict whitelist validation
* **SECURITY:** Fixed path traversal vulnerability in theme switching - Added directory validation
* **SECURITY:** Enhanced input validation across all AJAX endpoints
* **SECURITY:** Added authorization checks to AJAX handlers (get-repeat-box, ICS feed updates)
* **SECURITY:** Improved email and URL sanitization using proper WordPress functions
* **SECURITY:** Replaced deprecated create_function() for PHP 8.0+ compatibility
* **SECURITY:** Enhanced error logging to prevent information disclosure
* **Documentation:** Added comprehensive SECURITY.md file
* **Hardening:** All user inputs now properly sanitized and validated per OWASP guidelines

= 3.0.2 (SudoWP Edition) =
* **Fix:** Resolved "Function _load_textdomain_just_in_time was called incorrectly" notice for WP 6.7.
* **Update:** Rebranded as SudoWP All-in-One Event Calendar.
* **Update:** Modernized main plugin file with strict typing.

= 3.0.1 =
* Last official version by Timely before closure.