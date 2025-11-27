<?php
/**
 * Test Odds API Integration
 *
 * Run this file to test the Odds API fetcher
 * URL: /wp-content/plugins/sportsvestment-sportsbook/test-odds-api.php
 */

// Load WordPress
require_once('../../../wp-load.php');

// Load our fetcher class
require_once('core/class-odds-api-fetcher.php');

// Create instance
$fetcher = new SV_Odds_API_Fetcher();

echo "<h1>Odds API Test</h1>";
echo "<hr>";

// Test NBA odds
echo "<h2>Testing NBA Odds</h2>";
$nba_odds = $fetcher->fetch_odds('nba', true); // Force refresh

if (is_wp_error($nba_odds)) {
    echo "<p style='color: red;'>Error: " . $nba_odds->get_error_message() . "</p>";
} else {
    echo "<p style='color: green;'>Success! Found " . count($nba_odds) . " NBA games</p>";
    echo "<pre>" . print_r($nba_odds, true) . "</pre>";
}

echo "<hr>";

// Test NFL odds
echo "<h2>Testing NFL Odds</h2>";
$nfl_odds = $fetcher->fetch_odds('nfl', true);

if (is_wp_error($nfl_odds)) {
    echo "<p style='color: red;'>Error: " . $nfl_odds->get_error_message() . "</p>";
} else {
    echo "<p style='color: green;'>Success! Found " . count($nfl_odds) . " NFL games</p>";
    echo "<pre>" . print_r($nfl_odds, true) . "</pre>";
}

echo "<hr>";

// API Usage Stats
echo "<h2>API Usage Stats</h2>";
$stats = $fetcher->get_usage_stats();
echo "<pre>" . print_r($stats, true) . "</pre>";
echo "<p><strong>Remaining requests this month:</strong> " . $stats['remaining'] . " / " . $stats['free_tier_limit'] . "</p>";
