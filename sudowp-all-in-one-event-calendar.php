<?php
/**
 * Plugin Name: SudoWP All-in-One Event Calendar (Legacy Rescue)
 * Plugin URI:  https://sudowp.com
 * Description: A community-maintained, modernization-focused fork of the All-in-One Event Calendar. Patched for WP 6.7+ and PHP 8.2.
 * Version:     3.0.2 (SudoWP Edition)
 * Author:      SudoWP (Original: Time.ly)
 * Author URI:  https://sudowp.com
 * Text Domain: all-in-one-event-calendar
 * License:     GPLv2 or later
 */

declare(strict_types=1);

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
}

// Define the new SudoWP constants for internal reference
define( 'SUDOWP_AI1EC_VERSION', '3.0.2' );
define( 'SUDOWP_AI1EC_IS_RESCUE', true );

/**
 * Modernized Bootloader
 * Fixes: _load_textdomain_just_in_time (WP 6.7 compatibility)
 */
function sudowp_ai1ec_boot(): void {
	// Original Constants Logic (Preserved but encapsulated)
	if ( ! defined( 'AI1EC_PATH' ) ) {
		define( 'AI1EC_PATH', plugin_dir_path( __FILE__ ) );
	}
	if ( ! defined( 'AI1EC_URL' ) ) {
		define( 'AI1EC_URL', plugin_dir_url( __FILE__ ) );
	}
	if ( ! defined( 'AI1EC_PLUGIN_BASENAME' ) ) {
		define( 'AI1EC_PLUGIN_BASENAME', plugin_basename( __FILE__ ) );
	}

	// Initialize Constants
	require_once AI1EC_PATH . 'app/config/constants.php';
	
	if ( function_exists( 'ai1ec_initiate_constants' ) ) {
		ai1ec_initiate_constants( AI1EC_PATH, AI1EC_URL );
	}

	// Initialize the Autoloader/Registry
	// We defer this to 'plugins_loaded' to ensure WP core is ready
	add_action( 'plugins_loaded', 'sudowp_ai1ec_init_plugin', 10 );
}

/**
 * Core Initialization Hook
 */
function sudowp_ai1ec_init_plugin(): void {
	// Load Text Domain on 'init' to fix the "Just in Time" notice
	load_plugin_textdomain( 
		'all-in-one-event-calendar', 
		false, 
		dirname( plugin_basename( __FILE__ ) ) . '/language' 
	);

	// Bootstrap the original MVC Application
	try {
		global $ai1ec_registry;
		
		// Load the main app loader if it exists
		if ( file_exists( AI1EC_PATH . 'app/bootstrap/registry.php' ) ) {
			require_once AI1EC_PATH . 'app/bootstrap/registry.php';
		} elseif ( file_exists( AI1EC_PATH . 'lib/bootstrap/registry.php' ) ) {
			// Fallback for older versions
			require_once AI1EC_PATH . 'lib/bootstrap/registry.php';
		}
	} catch ( Throwable $e ) {
		error_log( 'SudoWP AI1EC Rescue Error: ' . $e->getMessage() );
	}
}

// Start the boot process
sudowp_ai1ec_boot();

// Register Activation Hook
register_activation_hook( __FILE__, 'sudowp_ai1ec_activation' );

function sudowp_ai1ec_activation(): void {
	// Placeholder for future activation logic
}