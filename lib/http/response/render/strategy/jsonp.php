<?php
/**
 * Render the request as jsonp.
 *
 * @author     Time.ly Network Inc.
 * @since      2.0
 *
 * @package    AI1EC
 * @subpackage AI1EC.Http.Response.Render.Strategy
 */
class Ai1ec_Render_Strategy_Jsonp extends Ai1ec_Http_Response_Render_Strategy {

    /* (non-PHPdoc)
     * @see Ai1ec_Http_Response_Render_Strategy::render()
     */
    public function render( array $params ) {
        $this->_dump_buffers();
        header( 'HTTP/1.1 200 OK' );
        header( 'Content-Type: application/json; charset=UTF-8' );
        $data   = Ai1ec_Http_Response_Helper::utf8( $params['data'] );
        $output = json_encode( $data );
        
        // Determine callback and validate it for security
        $callback = '';
        if ( ! empty( $params['callback'] ) ) {
            $callback = $params['callback'];
        } else if ( isset( $_GET['callback'] ) ) {
            $callback = $_GET['callback'];
        }
        
        // Validate callback name to prevent XSS via JSONP injection
        // Only allow valid JavaScript identifiers (alphanumeric, underscore, dollar sign)
        if ( ! empty( $callback ) ) {
            if ( preg_match( '/^[a-zA-Z_$][a-zA-Z0-9_$]*$/', $callback ) ) {
                $output = $callback . '(' . $output . ')';
            } else {
                // Invalid callback name - log and return JSON only
                error_log( 'SudoWP AI1EC Security: Invalid JSONP callback rejected: ' . esc_html( $callback ) );
            }
        }

        echo $output;
        return Ai1ec_Http_Response_Helper::stop( 0 );
    }

}