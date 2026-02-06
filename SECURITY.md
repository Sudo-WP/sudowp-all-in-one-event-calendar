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

### v3.0.2 (SudoWP Edition) - Security Hardening
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
