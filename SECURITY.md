# Security Policy

## Overview

This document outlines the security measures implemented in SudoWP All-in-One Event Calendar and provides guidance for security researchers and users.

## Reporting Security Issues

If you discover a security vulnerability in this plugin, please report it to the SudoWP team:

- **Email**: security@sudowp.com
- **GitHub**: Create a private security advisory at https://github.com/Sudo-WP/sudowp-all-in-one-event-calendar/security/advisories

Please do NOT create public issues for security vulnerabilities.

## Security Audit Summary (February 2026)

A comprehensive security audit was performed following OWASP guidelines and WordPress security best practices. The following vulnerabilities were identified and fixed:

### Critical Vulnerabilities Fixed

#### 1. JSONP Callback Injection (XSS) - CVE-PENDING
- **Location**: `/lib/http/response/render/strategy/jsonp.php`
- **Severity**: HIGH
- **Description**: Unsanitized `$_GET['callback']` parameter was directly injected into JSONP response, allowing arbitrary JavaScript execution
- **Fix**: Implemented strict whitelist validation using regex pattern `/^[a-zA-Z_$][a-zA-Z0-9_$]*$/` to only allow valid JavaScript identifiers
- **Impact**: Prevents Cross-Site Scripting (XSS) attacks via JSONP callback manipulation

#### 2. Path Traversal via Theme Switching
- **Location**: `/lib/command/change-theme.php`
- **Severity**: MEDIUM-HIGH
- **Description**: Theme URL parameter was not sanitized, and realpath() was called on unsanitized input
- **Fix**: 
  - Added `sanitize_text_field()` before `realpath()`
  - Implemented strict validation to ensure paths remain within plugin directory
  - Added `esc_url_raw()` for URL sanitization
- **Impact**: Prevents directory traversal attacks and unauthorized theme switching

### Medium Priority Vulnerabilities Fixed

#### 3. Insufficient Email Validation
- **Location**: `/app/model/event/creating.php`
- **Severity**: MEDIUM
- **Description**: Email and URL fields used generic `sanitize_text_field()` instead of proper validators
- **Fix**: 
  - Changed to `sanitize_email()` for email addresses
  - Changed to `esc_url_raw()` for URLs
- **Impact**: Ensures proper email and URL validation

#### 4. Missing Authorization Checks on AJAX Endpoints
- **Location**: `/app/view/admin/get-repeat-box.php`
- **Severity**: MEDIUM
- **Description**: AJAX handlers lacked capability checks, potentially allowing unauthorized access
- **Fix**: Added `current_user_can('edit_ai1ec_events')` checks to AJAX handlers
- **Impact**: Prevents unauthorized users from accessing event editing functionality

#### 5. Unsanitized Request Parameters
- **Location**: Multiple files
- **Severity**: MEDIUM
- **Description**: Direct access to `$_REQUEST` and `$_GET` arrays without sanitization
- **Fix**: Added proper sanitization using WordPress functions:
  - `sanitize_text_field()`
  - `sanitize_email()`
  - `esc_url_raw()`
  - Type casting with `(int)` for numeric values
- **Impact**: Prevents injection attacks and data corruption

#### 6. Authorization Enhancement for ICS Feed Operations
- **Location**: `/lib/calendar-feed/ics.php`
- **Severity**: MEDIUM
- **Description**: Missing early authorization check for AJAX feed updates
- **Fix**: Added `current_user_can('manage_ai1ec_feeds')` check before processing
- **Impact**: Prevents unauthorized feed management

### Low Priority Issues Fixed

#### 7. Deprecated PHP Function Usage
- **Location**: `/lib/iCal/helper/SG_iCal_Query.php`
- **Severity**: LOW
- **Description**: Used deprecated `create_function()` (removed in PHP 8.0)
- **Fix**: Replaced with modern anonymous function syntax
- **Impact**: Ensures PHP 8.0+ compatibility

## Security Best Practices Implemented

### Input Validation
All user inputs are now validated and sanitized using appropriate WordPress functions:
- `sanitize_text_field()` - For general text inputs
- `sanitize_email()` - For email addresses
- `esc_url_raw()` - For URLs
- Type casting `(int)` - For numeric values
- Custom validation - For specific patterns (e.g., JSONP callbacks)

### Authorization
- All AJAX endpoints verify user capabilities
- Custom WordPress capabilities used:
  - `edit_ai1ec_events` - Edit calendar events
  - `manage_ai1ec_feeds` - Manage calendar feeds
  - `switch_ai1ec_themes` - Switch calendar themes
- Nonce verification maintained where already implemented

### Output Escaping
- All dynamic output is properly escaped using WordPress functions
- JSONP responses validated before output
- Error messages sanitized in logs

### Path Security
- All file paths validated to remain within plugin directory
- `realpath()` used with additional validation
- Input sanitized before path operations

## Supported Security Standards

This plugin follows:
- **OWASP Top 10** - Web Application Security Risks
- **WordPress Coding Standards** - Security section
- **PHP Security Best Practices**
- **Common Vulnerability Scoring System (CVSS) v3.1**

## Known Limitations

### Custom Capabilities
The plugin uses custom WordPress capabilities that are registered during activation:
- `edit_ai1ec_events`
- `manage_ai1ec_feeds`
- `switch_ai1ec_themes`
- `manage_ai1ec_options`

These capabilities are automatically assigned to appropriate user roles (Administrator, Editor, Author) during plugin activation.

### Third-Party Dependencies
This plugin includes third-party libraries:
- iCalendar parser (SG_iCal)
- Legacy calendar functionality from Time.ly

Users should monitor for updates and security advisories related to these dependencies.

## Security Checklist for Administrators

When using this plugin:

✅ Keep WordPress core updated
✅ Use strong passwords for all user accounts
✅ Limit user capabilities to minimum required
✅ Regular backup of calendar data
✅ Monitor error logs for security events
✅ Review user permissions periodically
✅ Use HTTPS for all admin operations

## Version History

### v3.0.5 (SudoWP Security Edition)
- 3.0.4 was tagged but never released; its fixes ship for the first time in 3.0.5
- Issued the admin AJAX nonce (ai1ec_admin_nonce) that the 3.0.4 checks expected, so the protected admin AJAX actions work again
- Added a capability and a nonce check to ai1ec_feeds_page_post and ai1ec_search_events (manage_ai1ec_feeds) and ai1ec_rescan_cache (manage_options); before, any logged-in user could use them
- Added a nonce check to ai1ec_import_suggested_event and ai1ec_update_ics, which already checked a capability

### Planned for 3.0.6
- Remove calendar_feeds_nonce from the front-end configuration: with cache_dynamic_js on, it is written into the public file public/js_cache/calendar.js for the user whose visit generated it (tied to that user's login session)
- Review the nonce and capability checks on the non-AJAX feeds page form submission (handle_feeds_page_post() via app/controller/calendar-feeds.php:54-57 and app/view/admin/calendar-feeds.php:105)
- Sanitise feed_category in the add/edit feed handler and the feed submission fields ai1ec_calendar_url, ai1ec_submitter_email and ai1ec_categories
- Narrow or remove the request-wide unserialize_callback_func = spl_autoload_call setting

### v3.0.4 (tagged, not released)
- Fixed an SQL injection in the suggested-event import handler (feed ID bound with $wpdb->prepare())
- Unserialised the stored event cost value with allowed_classes => false
- Added nonce checks to 8 admin AJAX handlers and capability checks to 6 of them; the nonce was never issued, so these handlers rejected every request until 3.0.5
- Sanitized recurrence fields and feed URLs
- Protected the "Try reactivating plugin" link (?ai1ec_reactivate_plugin) with the activate_plugins capability and a nonce; before, any visitor, logged in or not, could re-enable the plugin after it had disabled itself because of an error
- Next release hardening: narrow or remove the request-wide unserialize_callback_func = spl_autoload_call setting in the main plugin file
- Restored the plugin's startup sequence: 3.0.2 and 3.0.3 did not boot, so none of their fixes were active on live sites

### v3.0.3 (SudoWP Security Edition) - Security Hardening
- Fixed JSONP callback injection (XSS)
- Fixed path traversal vulnerability
- Enhanced input validation and sanitization
- Added authorization checks to AJAX endpoints
- Replaced deprecated PHP functions
- Improved error logging security

### v3.0.1 and earlier
Legacy versions maintained by Time.ly - No longer supported

## Credits

Security audit and fixes performed by:
- SudoWP Security Team
- GitHub Copilot Security Analysis
- Community vulnerability reports

## License

This security policy is part of the SudoWP All-in-One Event Calendar plugin, licensed under GPLv2 or later.
