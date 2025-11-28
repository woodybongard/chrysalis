<?php
/**
 * Sportsbook Template - Main Odds Screen
 *
 * Clean, refined interface for making picks across all sports
 *
 * @package SportsVestment_Sportsbook
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

$user_id = get_current_user_id();
$user_balance = 10000; // TODO: Get from myCred

?>

<div class="sv-sportsbook-app">

    <!-- Header -->
    <div class="sv-header">
        <div class="sv-logo">
            <span class="sv-logo-icon">SV</span>
            <span class="sv-logo-text">SPORTSVESTMENT</span>
        </div>

        <div class="sv-balance">
            <span class="sv-coin-icon">SV</span>
            <span class="sv-balance-amount"><?php echo number_format($user_balance); ?></span>
        </div>

        <button class="sv-btn-primary">Buy SV Coins</button>
    </div>

    <!-- Navigation Tabs -->
    <div class="sv-nav-tabs">
        <button class="sv-tab active" data-tab="games">MARKET</button>
        <button class="sv-tab" data-tab="odds-screen">ODDS SCREEN</button>
        <button class="sv-tab" data-tab="leaderboard">LEADERBOARD</button>
        <button class="sv-tab" data-tab="my-bets">MY PLAYS</button>
    </div>

    <!-- Games & Odds Tab -->
    <div class="sv-tab-content active" id="tab-games">

        <!-- Sport Pills -->
        <div class="sv-sport-pills">
            <?php
            $enabled_sports = get_option('sv_enabled_sports', array(
                'basketball_nba' => true,
                'americanfootball_nfl' => true,
            ));

            $sport_labels = array(
                'basketball_nba' => 'NBA',
                'americanfootball_nfl' => 'NFL',
                'baseball_mlb' => 'MLB',
                'icehockey_nhl' => 'NHL',
                'basketball_ncaab' => 'NCAAB',
                'soccer_epl' => 'EPL',
                'soccer_uefa_champs_league' => 'Champions League',
                'tennis_atp' => 'ATP',
                'tennis_wta' => 'WTA',
                'mma_mixed_martial_arts' => 'MMA',
            );

            $sport_keys = array(
                'basketball_nba' => 'nba',
                'americanfootball_nfl' => 'nfl',
                'baseball_mlb' => 'mlb',
                'icehockey_nhl' => 'nhl',
                'basketball_ncaab' => 'ncaab',
                'soccer_epl' => 'soccer_epl',
                'soccer_uefa_champs_league' => 'soccer_uefa_champs_league',
                'tennis_atp' => 'tennis_atp',
                'tennis_wta' => 'tennis_wta',
                'mma_mixed_martial_arts' => 'mma',
            );

            $has_enabled_sports = false;
            foreach ($enabled_sports as $sport => $enabled) {
                if ($enabled) {
                    $has_enabled_sports = true;
                    break;
                }
            }

            if ($has_enabled_sports) {
                echo '<button class="sv-sport-pill active" data-sport="all">ALL</button>';
            }

            foreach ($enabled_sports as $sport => $enabled) {
                if ($enabled && isset($sport_labels[$sport])) {
                    $label = $sport_labels[$sport];
                    $key = $sport_keys[$sport];
                    echo '<button class="sv-sport-pill" data-sport="' . esc_attr($key) . '">' . esc_html($label) . '</button>';
                }
            }
            ?>
        </div>

        <!-- Search Bar -->
        <div class="sv-search-bar">
            <input type="text" id="sv-team-search" placeholder="Search for a team..." />
            <button id="sv-clear-search" style="display: none;">✕</button>
            <div class="sv-timezone-selector">
                <label for="sv-timezone">Timezone:</label>
                <select id="sv-timezone">
                    <option value="America/New_York">EST</option>
                    <option value="America/Chicago">CST</option>
                    <option value="America/Denver">MST</option>
                    <option value="America/Los_Angeles">PST</option>
                    <option value="UTC">UTC</option>
                </select>
            </div>
        </div>

        <!-- Games Grid -->
        <div class="sv-games-grid">
            <div class="sv-loading">Loading games...</div>
        </div>

    </div>

    <!-- Odds Screen Tab -->
    <div class="sv-tab-content" id="tab-odds-screen">
        <!-- Sport Pills (same as games tab) -->
        <div class="sv-sport-pills">
            <?php
            if ($has_enabled_sports) {
                echo '<button class="sv-sport-pill active" data-sport="all">ALL</button>';
            }

            foreach ($enabled_sports as $sport => $enabled) {
                if ($enabled && isset($sport_labels[$sport])) {
                    $label = $sport_labels[$sport];
                    $key = $sport_keys[$sport];
                    echo '<button class="sv-sport-pill" data-sport="' . esc_attr($key) . '">' . esc_html($label) . '</button>';
                }
            }
            ?>
        </div>

        <!-- Last Updated Info -->
        <div class="sv-odds-last-updated">
            <span>Last updated: <span id="sv-last-update-time">--</span></span>
        </div>

        <!-- Odds Grid -->
        <div class="sv-odds-grid">
            <div class="sv-loading">Loading odds...</div>
        </div>
    </div>

    <!-- Leaderboard Tab -->
    <div class="sv-tab-content" id="tab-leaderboard">
        <?php include 'leaderboard.php'; ?>
    </div>

    <!-- My Bets Tab -->
    <div class="sv-tab-content" id="tab-my-bets">
        <?php include 'my-bets.php'; ?>
    </div>

    <!-- Parlay Sidebar (hidden by default, slides in when needed) -->
    <div class="sv-parlay-sidebar" id="sv-parlay-sidebar">
        <div class="sv-parlay-header">
            <h3>Parlay Builder</h3>
            <button class="sv-parlay-close" id="sv-parlay-close">&times;</button>
        </div>

        <div class="sv-parlay-picks" id="sv-parlay-picks">
            <!-- Parlay picks go here -->
        </div>

        <div class="sv-parlay-footer">
            <div class="sv-parlay-units">
                <label>Total Units:</label>
                <input type="number" id="sv-parlay-units" min="1" max="100" value="10" />
            </div>
            <button class="sv-btn-submit-parlay" id="sv-submit-parlay">
                Submit Parlay
            </button>
        </div>
    </div>

    <!-- Floating Submit Button (appears when picks made) -->
    <button class="sv-floating-submit" id="sv-floating-submit" style="display: none;">
        Submit Picks (<span id="sv-total-picks">0</span>)
    </button>

</div>
