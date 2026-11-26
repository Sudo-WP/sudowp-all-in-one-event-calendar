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
#   - debug.log contains no PHP fatal or parse errors and no uncaught exceptions
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
