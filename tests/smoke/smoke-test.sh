#!/usr/bin/env bash
# Boot smoke test for SudoWP All-in-One Event Calendar.
#
# Installs the plugin into a disposable WordPress (SQLite, no MySQL needed)
# under two folder names, activates it, and asserts:
#   - shortcode_exists( 'ai1ec' )        is true
#   - post_type_exists( 'ai1ec_event' )  is true
#   - the plugin has not soft-disabled itself (option ai1ec_deactivate_message)
#   - the "Try reactivating plugin" link (?ai1ec_reactivate_plugin) clears a
#     soft-disable only for a user with activate_plugins AND a valid nonce:
#     anonymous and nonce-less admin requests leave the plugin disabled
#   - admin AJAX nonce: ai1ec_admin_nonce is issued in the backend
#     ai1ec_config (and only there); with that nonce an administrator's
#     ai1ec_rrule_to_text and ai1ec_dismiss_notice succeed, without it they
#     return -1; a subscriber is refused by ai1ec_feeds_page_post,
#     ai1ec_search_events and ai1ec_rescan_cache; the nonce script is
#     enqueued on the event editor screen
#   - debug.log contains no PHP fatal or parse errors and no uncaught exceptions
#
# Once per run, before the sites, a node test checks the prefilter in
# public/js/sudowp-admin-ajax-nonce.js against the requests the plugin's
# admin scripts send (needs node; reported as FAIL when node is missing).
#
# The debug.log summary leaves out WP-CLI's own deprecation messages from
# inside its phar (php-cli-tools Colors.php); every plugin message is kept.
#
# Site directories are deliberately named site-1, site-2: the plugin's error
# handler treats any file whose path contains "all-in-one-event-calendar" as
# its own, so a site directory named after the plugin would misattribute
# WordPress core errors to the plugin.
#
# Usage:
#   tests/smoke/smoke-test.sh [--php <php binary>] [--src <plugin dir>] [--keep]
#
#   --php   PHP binary used to run WP-CLI (default: php)
#   --src   plugin source directory (default: this repository's root)
#   --keep  keep the disposable sites for inspection
#
# Requires: WP-CLI (wp), curl, unzip, tar. Downloads WordPress core and the
# SQLite Database Integration plugin from wordpress.org on first run and
# caches them in ${XDG_CACHE_HOME:-~/.cache}/sudowp-smoke.
#
# Exit status: 0 when every assertion passes, 1 otherwise.

set -euo pipefail

PHP_BIN=php
SRC="$(cd "$(dirname "$0")/../.." && pwd)"
KEEP=0
while [ $# -gt 0 ]; do
	case "$1" in
		--php)  PHP_BIN="$2"; shift 2 ;;
		--src)  SRC="$(cd "$2" && pwd)"; shift 2 ;;
		--keep) KEEP=1; shift ;;
		*) echo "Unknown argument: $1" >&2; exit 2 ;;
	esac
done

MAIN_FILE=sudowp-all-in-one-event-calendar.php
FOLDERS=( sudowp-all-in-one-event-calendar sudowp-all-in-one-event-calendar-main )
WP_CLI_PHAR="$(command -v wp)"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/sudowp-smoke"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sudowp-smoke.XXXXXX")"

# E_ALL & ~E_DEPRECATED for WP-CLI's own bootstrap only: newer PHP versions
# flag deprecations inside the WP-CLI phar. WP_DEBUG makes wp_debug_mode()
# reset error_reporting( E_ALL ) before any plugin loads, so plugin
# deprecations still reach debug.log.
wpc() { "$PHP_BIN" -d error_reporting=24575 "$WP_CLI_PHAR" "$@"; }

cleanup() {
	if [ "$KEEP" -eq 1 ]; then
		echo "Sites kept in $WORK"
	else
		rm -rf "$WORK"
	fi
}
trap cleanup EXIT

[ -f "$SRC/$MAIN_FILE" ] || { echo "No $MAIN_FILE in $SRC" >&2; exit 2; }

# ---- Cached downloads -------------------------------------------------------
mkdir -p "$CACHE"
if [ ! -f "$CACHE/core/wp-includes/version.php" ]; then
	wpc core download --path="$CACHE/core" --locale=en_US --quiet
fi
if [ ! -f "$CACHE/sqlite-database-integration/db.copy" ]; then
	curl -sSL -o "$CACHE/sqlite.zip" \
		https://downloads.wordpress.org/plugin/sqlite-database-integration.latest-stable.zip
	unzip -q -o "$CACHE/sqlite.zip" -d "$CACHE"
	rm -f "$CACHE/sqlite.zip"
fi

echo "PHP:       $("$PHP_BIN" -r 'echo PHP_VERSION;')"
echo "WP-CLI:    $(wpc --version)"
echo "WordPress: $(sed -n "s/^\$wp_version = '\(.*\)';/\1/p" "$CACHE/core/wp-includes/version.php")"
echo "Plugin:    $(sed -n 's/^ \* Version: *//p' "$SRC/$MAIN_FILE")  ($SRC)"

FAILED=0
assert() { # assert <label> <expected> <actual>
	if [ "$2" = "$3" ]; then
		echo "  PASS  $1"
	else
		echo "  FAIL  $1 (expected '$2', got '$3')"
		FAILED=1
	fi
}

# ---- Admin AJAX nonce script (node) ------------------------------------------
# Runs the real script in a sandbox with stand-ins for the require.js loader
# (timely.require) and the bundled jQuery, then feeds the prefilter the
# request options jQuery builds for the plugin's own admin calls.
echo
echo "=== Admin AJAX nonce script (node)"
NONCE_JS="$SRC/public/js/sudowp-admin-ajax-nonce.js"
if ! command -v node >/dev/null 2>&1; then
	assert "node available for the prefilter test" "yes" "no"
elif [ ! -f "$NONCE_JS" ]; then
	assert "public/js/sudowp-admin-ajax-nonce.js exists" "yes" "no"
else
	node - "$NONCE_JS" <<'JSEOF' || FAILED=1
const fs = require( 'fs' ), vm = require( 'vm' );
const code = fs.readFileSync( process.argv[2], 'utf8' );
let failed = 0;
const check = ( label, ok ) => { console.log( '  ' + ( ok ? 'PASS' : 'FAIL' ) + '  ' + label ); if ( ! ok ) failed = 1; };
function load( config ) {
	const reg = { deps: null, filters: [] };
	const $ = { ajaxPrefilter: ( f ) => reg.filters.push( f ) };
	const sandbox = { timely: { require: ( deps, cb ) => { reg.deps = deps; cb( config, $ ); } } };
	vm.runInNewContext( code, sandbox );
	return reg;
}
const AJAX = 'http://localhost/wp-admin/admin-ajax.php';
const reg = load( { ai1ec_admin_nonce: 'N0nce' } );
check( 'prefilter registered on jquery_timely using ai1ec_config',
	JSON.stringify( reg.deps ) === '["ai1ec_config","jquery_timely"]' && reg.filters.length === 1 );
const run = ( opts ) => { reg.filters[0]( opts ); return opts.data; };
check( 'ai1ec_rrule_to_text POST gets the nonce',
	run( { url: AJAX, data: 'action=ai1ec_rrule_to_text&rrule=FREQ%3DDAILY%3B' } ) === 'action=ai1ec_rrule_to_text&rrule=FREQ%3DDAILY%3B&nonce=N0nce' );
check( 'ai1ec_dismiss_notice POST gets the nonce',
	run( { url: AJAX, data: 'action=ai1ec_dismiss_notice&key=abc' } ) === 'action=ai1ec_dismiss_notice&key=abc&nonce=N0nce' );
check( 'ai1ec_add_ics keeps its own feeds nonce',
	run( { url: AJAX, data: 'action=ai1ec_add_ics&nonce=FEED&feed_url=x' } ) === 'action=ai1ec_add_ics&nonce=FEED&feed_url=x' );
check( 'GET with the action in the URL gets the nonce',
	run( { url: AJAX + '?action=ai1ec_rescan_cache', data: undefined } ) === 'nonce=N0nce' );
check( 'non-plugin admin-ajax action left unchanged',
	run( { url: AJAX, data: 'action=heartbeat&x=1' } ) === 'action=heartbeat&x=1' );
check( 'request to another URL left unchanged',
	run( { url: 'http://example.invalid/api', data: 'action=ai1ec_x' } ) === 'action=ai1ec_x' );
check( 'no prefilter when ai1ec_config has no nonce',
	load( {} ).filters.length === 0 );
process.exit( failed );
JSEOF
fi

N=0
for FOLDER in "${FOLDERS[@]}"; do
	N=$((N + 1))
	SITE="$WORK/site-$N"
	echo
	echo "=== Folder: $FOLDER"

	cp -a "$CACHE/core" "$SITE"
	cp -a "$CACHE/sqlite-database-integration" "$SITE/wp-content/plugins/"
	sed -e "s#{SQLITE_IMPLEMENTATION_FOLDER_PATH}#$SITE/wp-content/plugins/sqlite-database-integration#" \
	    -e "s#{SQLITE_PLUGIN}#sqlite-database-integration/load.php#" \
	    "$SITE/wp-content/plugins/sqlite-database-integration/db.copy" > "$SITE/wp-content/db.php"

	wpc --path="$SITE" config create --dbname=smoke --dbuser=smoke --dbpass=smoke --skip-check --quiet
	wpc --path="$SITE" config set WP_DEBUG true --raw --quiet
	wpc --path="$SITE" config set WP_DEBUG_LOG true --raw --quiet
	wpc --path="$SITE" config set WP_DEBUG_DISPLAY false --raw --quiet
	wpc --path="$SITE" core install --url=http://localhost --title=smoke \
		--admin_user=admin --admin_password=smoke --admin_email=admin@example.invalid \
		--skip-email --quiet

	mkdir "$SITE/wp-content/plugins/$FOLDER"
	tar -C "$SRC" --exclude=.git --exclude=tests -cf - . \
		| tar -C "$SITE/wp-content/plugins/$FOLDER" -xf -

	ACTIVATE_OUT="$(wpc --path="$SITE" plugin activate "$FOLDER" 2>&1)" || true
	echo "$ACTIVATE_OUT" | sed 's/^/  wp: /'
	STATUS="$(wpc --path="$SITE" plugin get "$FOLDER" --field=status 2>/dev/null || echo error)"
	assert "plugin is active" "active" "$STATUS"

	SHORTCODE="$(wpc --path="$SITE" eval 'echo shortcode_exists( "ai1ec" ) ? "true" : "false";' 2>/dev/null || echo error)"
	assert 'shortcode_exists( "ai1ec" )' "true" "$SHORTCODE"

	POST_TYPE="$(wpc --path="$SITE" eval 'echo post_type_exists( "ai1ec_event" ) ? "true" : "false";' 2>/dev/null || echo error)"
	assert 'post_type_exists( "ai1ec_event" )' "true" "$POST_TYPE"

	DISABLED="$(wpc --path="$SITE" option get ai1ec_deactivate_message >/dev/null 2>&1 && echo set || echo unset)"
	assert "plugin not soft-disabled (ai1ec_deactivate_message unset)" "unset" "$DISABLED"

	# --- Reactivation link -------------------------------------------------
	# Soft-disable the plugin, then send ?ai1ec_reactivate_plugin requests.
	# --exec sets $_GET before WordPress (and the plugin) loads, as a real
	# request would; admin_init is fired explicitly because WP-CLI is not an
	# admin request.
	REACT_GET='$_GET["ai1ec_reactivate_plugin"] = "true";'
	opt_state() { wpc --path="$SITE" option get ai1ec_deactivate_message >/dev/null 2>&1 && echo set || echo unset; }
	soft_disable() { wpc --path="$SITE" option update ai1ec_deactivate_message "smoke-test soft-disable" --quiet >/dev/null 2>&1; }

	soft_disable
	wpc --path="$SITE" --exec="$REACT_GET" eval 'do_action( "admin_init" );' >/dev/null 2>&1 || true
	assert "reactivation link ignored for anonymous request" "set" "$(opt_state)"

	soft_disable
	wpc --path="$SITE" --user=admin --exec="$REACT_GET" eval 'do_action( "admin_init" );' >/dev/null 2>&1 || true
	assert "reactivation link refused for admin without nonce" "set" "$(opt_state)"

	soft_disable
	wpc --path="$SITE" --user=admin --exec="$REACT_GET" \
		eval '$_REQUEST["_wpnonce"] = wp_create_nonce( "ai1ec_reactivate_plugin" ); do_action( "admin_init" );' >/dev/null 2>&1 || true
	assert "reactivation link works for admin with valid nonce" "unset" "$(opt_state)"

	# --- Admin AJAX nonce ----------------------------------------------------
	# The nonce is read from ai1ec_config exactly as the backend script load
	# builds it (?is_backend=true). WP_ADMIN and DOING_AJAX are defined before
	# WordPress loads, as admin-ajax.php does, so the plugin registers its
	# wp_ajax_ handlers.
	wpc --path="$SITE" user create subscriber subscriber@example.invalid --role=subscriber --user_pass=smoke --quiet >/dev/null 2>&1 || true
	AJAX_CTX='define( "WP_ADMIN", true ); define( "DOING_AJAX", true );'
	CFG_NONCE='$ai1ec_js = apply_filters( "ai1ec_registry", false )->get( "controller.javascript" ); $_GET["is_backend"] = "true"; $ai1ec_cfg = $ai1ec_js->get_translation_data(); unset( $_GET["is_backend"] ); $ai1ec_nonce = isset( $ai1ec_cfg["ai1ec_admin_nonce"] ) ? $ai1ec_cfg["ai1ec_admin_nonce"] : "";'
	# ajax_call <user> <action> <php array of POST fields> <with-nonce: yes|no>
	ajax_call() {
		wpc --path="$SITE" --user="$1" --exec="$AJAX_CTX" eval "$CFG_NONCE \$_POST = array_merge( array( 'action' => '$2' ), $3 ); if ( 'yes' === '$4' ) { \$_POST['nonce'] = \$ai1ec_nonce; } \$_REQUEST = \$_POST; do_action( 'wp_ajax_$2' ); echo '[completed]';" 2>/dev/null | tr -d '\n' | tail -c 400
	}
	cron_freq() { wpc --path="$SITE" eval 'echo apply_filters( "ai1ec_registry", false )->get( "model.settings" )->get( "ics_cron_freq" );' 2>/dev/null; }

	ISSUED="$(wpc --path="$SITE" --user=admin --exec="$AJAX_CTX" eval "$CFG_NONCE echo ( '' !== \$ai1ec_nonce && wp_verify_nonce( \$ai1ec_nonce, 'ai1ec_admin_nonce' ) ) ? 'issued' : 'missing';" 2>/dev/null)"
	assert "ai1ec_admin_nonce issued in the backend ai1ec_config" "issued" "$ISSUED"

	FRONT="$(wpc --path="$SITE" --user=admin eval '$c = apply_filters( "ai1ec_registry", false )->get( "controller.javascript" )->get_translation_data(); echo isset( $c["ai1ec_admin_nonce"] ) ? "present" : "absent";' 2>/dev/null)"
	assert "ai1ec_admin_nonce absent from the non-backend config (JS cache, widget)" "absent" "$FRONT"

	OUT="$(ajax_call admin ai1ec_rrule_to_text "array( 'rrule' => 'FREQ=DAILY;' )" yes)"
	assert "admin: ai1ec_rrule_to_text succeeds with the issued nonce" "ok" "$(echo "$OUT" | grep -q '"message":"Daily' && echo ok || echo "$OUT")"
	OUT="$(ajax_call admin ai1ec_rrule_to_text "array( 'rrule' => 'FREQ=DAILY;' )" no)"
	assert "admin: ai1ec_rrule_to_text returns -1 without the nonce" "-1" "$OUT"
	OUT="$(ajax_call admin ai1ec_dismiss_notice "array( 'key' => 'smoke' )" yes)"
	assert "admin: ai1ec_dismiss_notice succeeds with the issued nonce" "[completed]" "$OUT"
	OUT="$(ajax_call admin ai1ec_dismiss_notice "array( 'key' => 'smoke' )" no)"
	assert "admin: ai1ec_dismiss_notice returns -1 without the nonce" "-1" "$OUT"

	BEFORE="$(cron_freq)"
	OUT="$(ajax_call subscriber ai1ec_feeds_page_post "array( 'cron_freq' => 'smoke-subscriber' )" yes)"
	assert "subscriber: ai1ec_feeds_page_post refused" "Unauthorized" "$OUT"
	assert "subscriber: feed import frequency unchanged" "$BEFORE" "$(cron_freq)"
	OUT="$(ajax_call subscriber ai1ec_search_events "array( 'term' => 'x' )" yes)"
	assert "subscriber: ai1ec_search_events refused" "Unauthorized" "$OUT"
	OUT="$(ajax_call subscriber ai1ec_rescan_cache "array()" yes)"
	assert "subscriber: ai1ec_rescan_cache refused" "Unauthorized" "$OUT"
	OUT="$(ajax_call admin ai1ec_feeds_page_post "array( 'cron_freq' => 'twicedaily' )" yes)"
	assert "admin: ai1ec_feeds_page_post saves the import frequency" "twicedaily" "$(cron_freq)"
	ajax_call admin ai1ec_feeds_page_post "array( 'cron_freq' => '$BEFORE' )" yes >/dev/null

	ENQ="$(wpc --path="$SITE" --user=admin --exec='define( "WP_ADMIN", true ); $GLOBALS["pagenow"] = "post-new.php"; $_GET["post_type"] = "ai1ec_event";' eval 'require_once ABSPATH . "wp-admin/includes/admin.php"; set_current_screen( "ai1ec_event" ); do_action( "admin_enqueue_scripts", "post-new.php" ); $s = wp_scripts()->query( "sudowp_ai1ec_admin_ajax_nonce" ); echo ( wp_script_is( "sudowp_ai1ec_admin_ajax_nonce", "enqueued" ) && $s && in_array( "ai1ec_requirejs", $s->deps, true ) && false !== strpos( $s->src, "/public/js/sudowp-admin-ajax-nonce.js" ) ) ? "enqueued" : "missing";' 2>/dev/null)"
	assert "nonce script enqueued on the event editor screen (after ai1ec_requirejs)" "enqueued" "$ENQ"
	assert "nonce script file present in the installed plugin" "yes" "$( [ -f "$SITE/wp-content/plugins/$FOLDER/public/js/sudowp-admin-ajax-nonce.js" ] && echo yes || echo no )"

	LOG="$SITE/wp-content/debug.log"
	FATAL_RE='PHP (Fatal|Parse) error|Uncaught'
	FATALS=0
	if [ -f "$LOG" ]; then
		FATALS="$(grep -cE "$FATAL_RE" "$LOG" || true)"
	fi
	assert "debug.log has no PHP fatal/parse errors or uncaught exceptions" "0" "$FATALS"

	if [ -f "$LOG" ]; then
		WPCLI_RE='phar://.*/php-cli-tools/lib/cli/Colors\.php'
		WPCLI_LINES="$(grep -cE "$WPCLI_RE" "$LOG" || true)"
		echo "  debug.log: $(wc -l < "$LOG") lines ($WPCLI_LINES WP-CLI phar lines left out); unique messages (timestamps and paths stripped):"
		grep -vE "$WPCLI_RE" "$LOG" \
			| sed -E -e 's/^\[[^]]*\] //' -e "s#$SITE/##g" -e 's/<[^>]+>//g' \
			| cut -c1-160 | sort | uniq -c | sort -rn | sed 's/^/    /'
	else
		echo "  debug.log: not written"
	fi
done

echo
if [ "$FAILED" -eq 0 ]; then
	echo "RESULT: PASS"
else
	echo "RESULT: FAIL"
fi
exit "$FAILED"
