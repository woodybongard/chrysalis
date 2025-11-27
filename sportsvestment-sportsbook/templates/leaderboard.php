<?php
/**
 * Leaderboard Template
 *
 * Shows top performers, ROI, wins, rankings
 *
 * @package SportsVestment_Sportsbook
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

?>

<div class="sv-leaderboard">
    <table class="sv-leaderboard-table">
        <thead>
            <tr>
                <th>RANK</th>
                <th>PLAYER</th>
                <th>SV COINS</th>
                <th>ROI</th>
                <th>WINS</th>
            </tr>
        </thead>
        <tbody>
            <!-- We'll populate this with real data -->
            <tr>
                <td>1</td>
                <td>
                    <span class="player-badge">PR</span>
                    <span class="player-name">ProBettor23</span>
                </td>
                <td>25,420</td>
                <td class="roi-positive">+24.2%</td>
                <td>87</td>
            </tr>
            <!-- More rows... -->
        </tbody>
    </table>
</div>
