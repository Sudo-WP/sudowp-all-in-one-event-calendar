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

### 1. Security Hardening (v3.0.3)
* **XSS Prevention:** Fixed JSONP callback injection vulnerability with strict whitelist validation
* **Path Traversal:** Secured theme switching with directory validation
* **Input Validation:** All user inputs sanitized following OWASP guidelines
* **Authorization:** Enhanced capability checks on AJAX endpoints
* **PHP 8 Compatibility:** Replaced deprecated `create_function()`
* **Documentation:** Added comprehensive [SECURITY.md](SECURITY.md) policy

### 2. WordPress 6.7 Compatibility
* **Issue:** The original plugin loaded translations too early, triggering PHP notices in the admin panel.
* **Fix:** We deferred `load_plugin_textdomain` to the `init` hook, complying with modern WP standards.

### 3. Modernization
* **Strict Typing:** The main entry point now enforces `declare(strict_types=1);`.
* **Bootloader:** Refactored the initialization logic to be more robust.
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

**Latest Version: 3.0.3 (Security Edition)**
- Fixed multiple security vulnerabilities
- Enhanced input validation and authorization
- PHP 8.0+ compatibility improvements

---
*Forked and maintained by the SudoWP Project.*