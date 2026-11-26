<?php
/**
 * Plugin Name: SudoWP All-in-One Event Calendar (Legacy Rescue)
 * Plugin URI:  https://sudowp.com
 * Description: A community-maintained, modernization-focused fork of the All-in-One Event Calendar. Patched for WP 6.7+ and PHP 8.2. Security hardened following OWASP guidelines.
 * Version:     3.0.5 (SudoWP Security Edition)
 * Author:      SudoWP (Original: Time.ly)
 * Author URI:  https://sudowp.com
 * Text Domain: all-in-one-event-calendar
 * Domain Path: /language
 * Requires PHP: 7.2
 * License:     GPLv2 or later
 */

declare(strict_types=1);

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
}

// SudoWP constants for internal reference.
define( 'SUDOWP_AI1EC_VERSION', '3.0.5' );
define( 'SUDOWP_AI1EC_IS_RESCUE', true );

/**
 * Load translations on 'init' (WP 6.7 "_load_textdomain_just_in_time" fix).
 *
 * The folder name is read at runtime, so the plugin loads its own language
 * files whatever its directory is called.
 */
function sudowp_ai1ec_load_textdomain(): void {
	load_plugin_textdomain(
		'all-in-one-event-calendar',
		false,
		dirname( plugin_basename( __FILE__ ) ) . '/language'
	);
}
add_action( 'init', 'sudowp_ai1ec_load_textdomain', 0 );

// ======================================================================
// = Original Timely startup sequence (all-in-one-event-calendar.php,   =
// = 3.0.2). It must run while WordPress includes this file: the front  =
// = controller registers its own plugins_loaded, after_setup_theme and =
// = init hooks, and registers the [ai1ec] shortcode, during            =
// = initialize().                                                      =
// ======================================================================

$ai1ec_base_dir = dirname( __FILE__ );

$ai1ec_base_url = plugins_url( '', __FILE__ );

// The upstream constants file derives the basename from a hardcoded
// "all-in-one-event-calendar.php". Define it first from the real file so
// plugin_action_links_ and activation hooks match this plugin's file name.
if ( ! defined( 'AI1EC_PLUGIN_BASENAME' ) ) {
	define( 'AI1EC_PLUGIN_BASENAME', plugin_basename( __FILE__ ) );
}

$ai1ec_config_path = $ai1ec_base_dir . DIRECTORY_SEPARATOR . 'app' .
	DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR;

// Include configuration files and initiate global constants as they are used
// by the error/exception handler too.
foreach ( array( 'constants-local.php', 'constants.php' ) as $file ) {
	if ( is_file( $ai1ec_config_path . $file ) ) {
		require_once $ai1ec_config_path . $file;
	}
}

if ( ! function_exists( 'ai1ec_initiate_constants' ) ) {
	throw new Ai1ec_Exception(
		'No constant file was found.'
	);
}
ai1ec_initiate_constants( $ai1ec_base_dir, $ai1ec_base_url );

require $ai1ec_base_dir . DIRECTORY_SEPARATOR . 'lib' .
	DIRECTORY_SEPARATOR . 'exception' . DIRECTORY_SEPARATOR . 'ai1ec.php';
require $ai1ec_base_dir . DIRECTORY_SEPARATOR . 'lib' .
	DIRECTORY_SEPARATOR . 'exception' . DIRECTORY_SEPARATOR . 'error.php';
require $ai1ec_base_dir . DIRECTORY_SEPARATOR . 'lib' .
	DIRECTORY_SEPARATOR . 'exception' . DIRECTORY_SEPARATOR . 'handler.php';
require $ai1ec_base_dir . DIRECTORY_SEPARATOR . 'lib' .
	DIRECTORY_SEPARATOR . 'http' . DIRECTORY_SEPARATOR . 'response' .
	DIRECTORY_SEPARATOR . 'helper.php';
$ai1ec_exception_handler = new Ai1ec_Exception_Handler(
	'Ai1ec_Exception',
	'Ai1ec_Error_Exception'
);

// If an administrator clicked the "Try reactivating plugin" link. Checked on
// admin_init: capabilities and nonces are not available while WordPress is
// still including plugin files. Requests without the capability or a valid
// nonce leave the plugin disabled.
if ( isset( $_GET[ Ai1ec_Exception_Handler::DB_REACTIVATE_PLUGIN ] ) ) {
	add_action(
		'admin_init',
		static function () use ( $ai1ec_exception_handler ): void {
			if ( ! current_user_can( 'activate_plugins' ) ) {
				return;
			}
			check_admin_referer( Ai1ec_Exception_Handler::DB_REACTIVATE_PLUGIN );
			$ai1ec_exception_handler->reactivate_plugin();
			wp_safe_redirect(
				remove_query_arg(
					array( Ai1ec_Exception_Handler::DB_REACTIVATE_PLUGIN, '_wpnonce' )
				)
			);
			exit;
		}
	);
}
$soft_disable_message = $ai1ec_exception_handler->get_disabled_message();
if ( false !== $soft_disable_message ) {
	return $ai1ec_exception_handler->show_notices( $soft_disable_message );
}

$prev_er_handler = set_error_handler(
	array( $ai1ec_exception_handler, 'handle_error' )
);
$prev_ex_handler = set_exception_handler(
	array( $ai1ec_exception_handler, 'handle_exception' )
);
$ai1ec_exception_handler->set_prev_er_handler( $prev_er_handler );
$ai1ec_exception_handler->set_prev_ex_handler( $prev_ex_handler );

// Regular startup sequence starts here.

require $ai1ec_base_dir . DIRECTORY_SEPARATOR . 'lib' .
	DIRECTORY_SEPARATOR . 'bootstrap' . DIRECTORY_SEPARATOR . 'loader.php';

require $ai1ec_base_dir . DIRECTORY_SEPARATOR . 'lib' .
	DIRECTORY_SEPARATOR . 'global-functions.php';

require $ai1ec_base_dir . DIRECTORY_SEPARATOR . 'lib' .
	DIRECTORY_SEPARATOR . 'iCal' . DIRECTORY_SEPARATOR . 'iCalcreator-2.26.9' . DIRECTORY_SEPARATOR . 'autoload.php';

require $ai1ec_base_dir . DIRECTORY_SEPARATOR . 'app' .
	DIRECTORY_SEPARATOR . 'controller' . DIRECTORY_SEPARATOR . 'extension.php';

require $ai1ec_base_dir . DIRECTORY_SEPARATOR . 'app' .
	DIRECTORY_SEPARATOR . 'controller' . DIRECTORY_SEPARATOR . 'extension-license.php';

$ai1ec_loader = new Ai1ec_Loader( $ai1ec_base_dir );
@ini_set( 'unserialize_callback_func', 'spl_autoload_call' );
spl_autoload_register( array( $ai1ec_loader, 'load' ) );

$ai1ec_front_controller = new Ai1ec_Front_Controller();
$ai1ec_front_controller->initialize( $ai1ec_loader );
