<?php
/**
 * My Bets Template
 *
 * Shows user's active picks with units and timestamps
 *
 * @package SportsVestment_Sportsbook
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

$user_id = get_current_user_id();

?>

<div class="sv-my-bets">
    <!-- Stats Bar -->
    <div class="sv-stats-bar">
        <div class="sv-stat-section">
            <div class="sv-stat-period-title">THIS WEEK</div>
            <div class="sv-stat-grid">
                <div class="sv-stat-box">
                    <div class="sv-stat-box-label">Record</div>
                    <div class="sv-stat-box-value">
                        <span class="sv-wins" id="weekly-wins">0</span>-<span class="sv-losses" id="weekly-losses">0</span>
                    </div>
                </div>
                <div class="sv-stat-box">
                    <div class="sv-stat-box-label">Wagered</div>
                    <div class="sv-stat-box-value" id="weekly-wagered">0u</div>
                </div>
                <div class="sv-stat-box">
                    <div class="sv-stat-box-label">Profit</div>
                    <div class="sv-stat-box-value sv-profit" id="weekly-profit">0u</div>
                </div>
                <div class="sv-stat-box sv-stat-box-highlight">
                    <div class="sv-stat-box-label">SVR</div>
                    <div class="sv-stat-box-value sv-svr-value" id="weekly-svr">50</div>
                </div>
            </div>
        </div>

        <div class="sv-stat-divider-vertical"></div>

        <div class="sv-stat-section">
            <div class="sv-stat-period-title">LAST 30 DAYS</div>
            <div class="sv-stat-grid">
                <div class="sv-stat-box">
                    <div class="sv-stat-box-label">Record</div>
                    <div class="sv-stat-box-value">
                        <span class="sv-wins" id="monthly-wins">0</span>-<span class="sv-losses" id="monthly-losses">0</span>
                    </div>
                </div>
                <div class="sv-stat-box">
                    <div class="sv-stat-box-label">Wagered</div>
                    <div class="sv-stat-box-value" id="monthly-wagered">0u</div>
                </div>
                <div class="sv-stat-box">
                    <div class="sv-stat-box-label">Profit</div>
                    <div class="sv-stat-box-value sv-profit" id="monthly-profit">0u</div>
                </div>
                <div class="sv-stat-box sv-stat-box-highlight">
                    <div class="sv-stat-box-label">SVR</div>
                    <div class="sv-stat-box-value sv-svr-value" id="monthly-svr">50</div>
                </div>
            </div>
        </div>
    </div>

    <div id="my-bets-list">
        <div class="sv-loading">Loading your picks...</div>
    </div>
</div>
