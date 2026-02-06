=== SudoWP All-in-One Event Calendar (Legacy Rescue) ===
Contributors: SudoWP, WP Republic
Original Authors: Timely (Time.ly)
Tags: calendar, events, sudowp, legacy, rescue, php8, security
Requires at least: 6.0
Tested up to: 6.7
Stable tag: 3.0.3
License: GPLv2 or later
License URI: http://www.gnu.org/licenses/gpl-2.0.html

A community-maintained rescue of the "All-in-One Event Calendar" plugin. Security hardened, fixes WP 6.7 notices and keeps the plugin alive after the official shutdown.

== Description ==

This is SudoWP All-in-One Event Calendar, a forked maintenance release of the original plugin by Timely.

**Why this fork?**
On August 2025, the original developers shut down this plugin ("Author Request") to migrate users to a SaaS platform. This left over 100,000 active installations with a plugin that throws warnings in WordPress 6.7 and has no update path.

**SudoWP Mission:**
We maintain this fork to ensure existing users can keep their calendars running on modern servers (PHP 8.2+) without being forced to migrate to a paid external service.

**Security & Stability Patches (v3.0.3):**
* **Security Hardening:** Fixed XSS vulnerability (JSONP callback injection), path traversal, and enhanced input validation following OWASP guidelines
* **Authorization:** Added capability checks to all AJAX endpoints to prevent unauthorized access
* **Input Validation:** All user inputs properly sanitized using WordPress security functions
* **PHP 8 Compatibility:** Replaced deprecated functions for full PHP 8.0+ support
* **WP 6.7 Fix:** Fixed the "_load_textdomain_just_in_time" notice by correctly deferring translation loading
* **Modernization:** Refactored the main bootloader to use Strict Types and proper Hook priority
* **Documentation:** Added comprehensive security policy (SECURITY.md)
* **Branding:** Renamed to "sudowp-all-in-one-event-calendar" to separate it from the discontinued upstream version

For detailed security information, see the SECURITY.md file in the plugin directory.

== Installation ==

1. **Backup:** Always backup your database before switching plugins.
2. **Deactivate:** Deactivate the original "All-in-One Event Calendar".
3. **Upload:** Upload the "sudowp-all-in-one-event-calendar" folder to "/wp-content/plugins/".
4. **Activate:** Activate "SudoWP All-in-One Event Calendar".

== Changelog ==

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