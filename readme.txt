=== SudoWP All-in-One Event Calendar (Legacy Rescue) ===
Contributors: SudoWP, WP Republic
Original Authors: Timely (Time.ly)
Tags: calendar, events, sudowp, legacy, rescue, php8, security
Requires at least: 6.0
Tested up to: 6.7
Stable tag: 3.0.5
License: GPLv2 or later
License URI: http://www.gnu.org/licenses/gpl-2.0.html

A community-maintained rescue of the "All-in-One Event Calendar" plugin. Security hardened, fixes WP 6.7 notices and keeps the plugin alive after the official shutdown.

== Description ==

This is SudoWP All-in-One Event Calendar, a forked maintenance release of the original plugin by Timely.

**Why this fork?**
On August 2025, the original developers shut down this plugin ("Author Request") to migrate users to a SaaS platform. This left over 100,000 active installations with a plugin that throws warnings in WordPress 6.7 and has no update path.

**SudoWP Mission:**
We maintain this fork to ensure existing users can keep their calendars running on modern servers (PHP 8.2+) without being forced to migrate to a paid external service.

**Security & Stability Patches (v3.0.3 to v3.0.5):**
* **Admin AJAX fix (v3.0.5):** The event editor's Repeat dialog and the other admin AJAX actions work again, and every admin AJAX action now checks a nonce and a capability
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

= 3.0.5 (SudoWP Security Edition) - November 2026 =
* **NOTE:** 3.0.4 was tagged but never released. Its changes, listed under 3.0.4 below, ship for the first time in 3.0.5.
* **FIX (critical):** The admin AJAX actions blocked by the 3.0.4 code work again: the Repeat and Exclude dialogs and the recurrence summary in the event editor, deleting an iCal feed, removing a suggested event, dismissing the calendar's admin notices, and the Timely ticketing tax, ticket-details and attendee views. The nonce checks added in 3.0.4 expected a nonce (ai1ec_admin_nonce) that the plugin never issued. It is now issued in the admin script configuration, and a small new script (public/js/sudowp-admin-ajax-nonce.js) sends it with the plugin's admin AJAX requests.
* **SECURITY:** The feed import frequency (ai1ec_feeds_page_post) and suggested-event search (ai1ec_search_events) AJAX actions now require the manage_ai1ec_feeds capability and a nonce, and the template cache rescan (ai1ec_rescan_cache) requires manage_options and a nonce. Before, any logged-in user, a subscriber included, could use them.
* **SECURITY:** Importing a suggested event (ai1ec_import_suggested_event) and refreshing an iCal feed (ai1ec_update_ics) now check a nonce as well as the capability they already required.
* **TESTS:** The smoke test now also checks that the admin nonce is issued and accepted, that subscribers are refused by the actions above, that the nonce script is loaded on the event editor, and the script's request handling (node).
* **DOCS:** Corrected three 3.0.4 changelog lines that overstated what changed (SQL queries, unserialize, AJAX checks).
* **KNOWN ISSUES (next release):** None of these stop the plugin working today.
* PHP 8.4+ future fatal: lib/exception/handler.php:93 uses the E_STRICT constant, deprecated since PHP 8.4. When PHP removes it, the plugin will stop with a fatal error while it starts.
* PHP 8.4+ deprecations: implicitly nullable parameters in lib/bootstrap/loader.php:123, lib/theme/loader.php:242, lib/less/lessphp.php:105, lib/css/frontend.php:222 and lib/database/helper.php:296; "case ...;" statements in vendor/lessphp/lessc.inc.php:748 and lib/iCal/iCalcnv-3.0/iCalcnv.class.php:1179 and :1771.
* PHP 8.2+ deprecations: dynamic properties Ai1ec_Scheduling_Utility::$_updated (lib/scheduling/utility.php), Ai1ec_Http_Request::$_registry (lib/http/request.php) and lessc::$formatterName, and "${var}" string interpolation in vendor/lessphp/lessc.inc.php.
* WordPress 6.7+ still logs one "_load_textdomain_just_in_time" notice because setting labels are translated while the plugin starts (app/model/settings.php).
* Hardening: the main plugin file sets unserialize_callback_func to spl_autoload_call for the whole request, so any unserialize() call on the site, including WordPress core and other plugins, can load this plugin's classes. To be narrowed or removed.
* **3.0.6 BACKLOG:** found after the 3.0.5 release, during browser testing and review.
* PHP 8.1+ deprecations: return types not compatible with ArrayAccess, Countable or IteratorAggregate in Ai1ec_Abstract_Query (lib/http/request/abstract.php:198-222), SG_iCal_Line (lib/iCal/helper/SG_iCal_Line.php:114-162) and Twig_Node (vendor/twig/Node.php:217 and :222); automatic conversion of false to array in Ai1ec_Javascript_Controller::load_admin_js() (app/controller/javascript.php:366 and :381).
* PHP 8.4+ deprecations: implicitly nullable $argv in Ai1ec_Abstract_Query::__construct() (lib/http/request/abstract.php:46) and Ai1ec_Request_Parser::__construct() (lib/http/request/parser.php:67).
* Nonce in a public file: with the cache_dynamic_js setting on, the front-end calendar script written to public/js_cache/calendar.js includes calendar_feeds_nonce (app/controller/javascript.php:463) for the user whose visit generated it. The nonce is tied to that user's login session. To be removed from the front-end configuration.
* Not yet audited: the feeds page form submission (not the AJAX call) reaches handle_feeds_page_post() through app/controller/calendar-feeds.php:54-57 and app/view/admin/calendar-feeds.php:105; its nonce and capability checks have not been reviewed.
* Unsanitised feed inputs: feed_category in the add/edit feed handler (lib/calendar-feed/ics.php:610-611 and :686-691) and the feed submission fields ai1ec_calendar_url, ai1ec_submitter_email and ai1ec_categories (lib/calendar-feed/ics.php:243-248).

= 3.0.4 (tagged, not released) - November 2026 =
* **FIX (critical):** 3.0.2 and 3.0.3 did not boot. They activated without error, but the bootloader written for 3.0.2 never started the calendar application: the [ai1ec] shortcode, the ai1ec_event post type, the admin menus and the front-end calendar were all missing. Sites that removed the original Timely plugin before switching had no working calendar.
* **FIX:** Restored the original Timely startup sequence (class loader, exception handler, front controller, with their original hooks and priorities) in the main plugin file. No option names, post types, taxonomies, shortcode names or database tables change: it is a drop-in update.
* **FIX:** Translations load from the plugin's own folder whatever the folder is called.
* **TESTS:** Added a boot smoke test (tests/smoke/smoke-test.sh; not shipped in the release zip).
* **SECURITY:** Fixed an SQL injection in the suggested-event import handler: the feed ID from the request is now bound with $wpdb->prepare().
* **SECURITY:** The stored event cost value is unserialised with allowed_classes => false, so it cannot create PHP objects.
* **SECURITY:** Added nonce checks to 8 admin AJAX handlers, and capability checks to 6 of them (the other 2 already had one). The plugin never issued that nonce, so these handlers rejected every request; fixed in 3.0.5.
* **SECURITY:** Input sanitization on recurrence fields and feed URLs.
* **SECURITY:** The "Try reactivating plugin" link (?ai1ec_reactivate_plugin) now requires the activate_plugins capability and a valid nonce. Before, any visitor, logged in or not, could re-enable the calendar after it had disabled itself because of an error. Administrators see the same button and one extra redirect.

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