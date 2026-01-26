# SudoWP All-in-One Event Calendar (Legacy Rescue)

![WP Version](https://img.shields.io/badge/WordPress-6.7%2B-blue)
![PHP Version](https://img.shields.io/badge/PHP-8.2%2B-purple)
![Status](https://img.shields.io/badge/Status-Maintenance-orange)

**A community-maintained rescue of the All-in-One Event Calendar plugin.**

Maintained by **SudoWP**, this project ensures that the 100,000+ sites relying on this plugin can continue to function after the original developer (Timely) shut it down in August 2025.

## 🚨 The Situation
The original plugin was closed on WordPress.org to force a migration to a SaaS platform.
* **Problem:** The legacy code produces errors on WordPress 6.7 (`_load_textdomain_just_in_time`) and lacks PHP 8.2 support.
* **Solution:** This fork fixes the compatibility issues and acts as a stable, standalone version.

## 🛠 Patches & Improvements

### 1. WordPress 6.7 Compatibility
* **Issue:** The original plugin loaded translations too early, triggering PHP notices in the admin panel.
* **Fix:** We deferred `load_plugin_textdomain` to the `init` hook, complying with modern WP standards.

### 2. Modernization
* **Strict Typing:** The main entry point now enforces `declare(strict_types=1);`.
* **Bootloader:** Refactored the initialization logic to be more robust.

## 📦 Installation

1.  Download the repository.
2.  Deactivate the original "All-in-One Event Calendar".
3.  Upload `sudowp-all-in-one-event-calendar` to your plugins directory.
4.  Activate.

---
*Forked and maintained by the SudoWP Project.*
