/**
 * SudoWP All-in-One Event Calendar: admin AJAX nonce.
 *
 * Appends the ai1ec_admin_nonce issued in the ai1ec_config module to the
 * plugin's own admin-ajax.php requests whose action starts with "ai1ec_".
 * A request that already carries a "nonce" parameter (the iCal feed form
 * sends its own) is left unchanged.
 *
 * The plugin makes its AJAX calls through its bundled jQuery
 * (jquery_timely), not the WordPress jQuery, so the prefilter is
 * registered on that instance.
 */
( function ( root ) {
	'use strict';

	function hasParam( query, name ) {
		return new RegExp( '(^|&)' + name + '=' ).test( query );
	}

	function makePrefilter( nonce ) {
		return function ( options ) {
			var url  = String( options.url || '' );
			var data = options.data;
			var query;

			if ( -1 === url.indexOf( 'admin-ajax.php' ) ) {
				return;
			}
			// jQuery has already serialised plain objects to a string here;
			// anything else (FormData) is not sent by the plugin's handlers.
			if ( null !== data && undefined !== data && 'string' !== typeof data ) {
				return;
			}
			data  = data || '';
			query = data + '&' + ( url.split( '?' )[1] || '' );
			if ( ! /(^|&)action=ai1ec_/.test( query ) || hasParam( query, 'nonce' ) ) {
				return;
			}
			options.data = ( data ? data + '&' : '' ) +
				'nonce=' + encodeURIComponent( nonce );
		};
	}

	if ( ! root.timely || 'function' !== typeof root.timely.require ) {
		return;
	}
	root.timely.require( [ 'ai1ec_config', 'jquery_timely' ], function ( config, $ ) {
		if ( ! config || ! config.ai1ec_admin_nonce || ! $ || ! $.ajaxPrefilter ) {
			return;
		}
		$.ajaxPrefilter( makePrefilter( config.ai1ec_admin_nonce ) );
	} );
}( this ) );
