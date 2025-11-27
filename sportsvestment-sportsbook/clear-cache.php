<?php
/**
 * Clear all sportsbook caches
 * Run this by visiting: yoursite.com/wp-content/plugins/sportsvestment-sportsbook/clear-cache.php
 */

// Load WordPress
$wp_load_path = '../../../wp-load.php';
if (file_exists($wp_load_path)) {
    require_once($wp_load_path);
} else {
    die('Cannot find WordPress. Make sure this file is in the plugin directory.');
}

// Clear all transients related to sportsbook
global $wpdb;

$deleted = 0;

// Delete all sv_odds transients
$result = $wpdb->query(
    "DELETE FROM {$wpdb->options}
     WHERE option_name LIKE '_transient_sv_%'
     OR option_name LIKE '_transient_timeout_sv_%'"
);

$deleted += $result;

echo "<h1>SportsVestment Cache Cleared!</h1>";
echo "<p>Deleted {$deleted} cache entries.</p>";
echo "<p><strong>Now refresh your sportsbook page (Ctrl+Shift+R)</strong></p>";
echo "<p><a href='/'>Go to site</a></p>";
