<?php
/**
 * Admin Page Template
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

global $wpdb;
$table_name = $wpdb->prefix . 'sv_bet_slips';
$total_picks = $wpdb->get_var("SELECT COUNT(*) FROM $table_name");
$pending_picks = $wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE result = 'pending'");
$graded_picks = $wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE result != 'pending'");

?>

<div class="wrap">
    <h1>SportsVestment Sportsbook Settings</h1>

    <div style="background: #fff; padding: 20px; margin: 20px 0; border: 1px solid #ccc; border-radius: 5px;">
        <h2>Database Statistics</h2>
        <table class="widefat" style="max-width: 600px;">
            <tbody>
                <tr>
                    <td><strong>Total Picks:</strong></td>
                    <td><?php echo number_format($total_picks); ?></td>
                </tr>
                <tr>
                    <td><strong>Pending Picks:</strong></td>
                    <td><?php echo number_format($pending_picks); ?></td>
                </tr>
                <tr>
                    <td><strong>Graded Picks:</strong></td>
                    <td><?php echo number_format($graded_picks); ?></td>
                </tr>
            </tbody>
        </table>
    </div>

    <div style="background: #fff; padding: 20px; margin: 20px 0; border: 1px solid #ccc; border-radius: 5px;">
        <h2>Sport Settings</h2>
        <p>Enable or disable sports in the sportsbook interface:</p>

        <form method="post" action="">
            <?php wp_nonce_field('sv_admin_actions', 'sv_admin_nonce'); ?>

            <table class="form-table">
                <tbody>
                    <tr>
                        <th scope="row">NBA Basketball</th>
                        <td>
                            <label>
                                <input type="checkbox" name="sport_basketball_nba" value="1" <?php checked(isset($enabled_sports['basketball_nba']) && $enabled_sports['basketball_nba']); ?>>
                                Enable NBA
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row">NFL Football</th>
                        <td>
                            <label>
                                <input type="checkbox" name="sport_americanfootball_nfl" value="1" <?php checked(isset($enabled_sports['americanfootball_nfl']) && $enabled_sports['americanfootball_nfl']); ?>>
                                Enable NFL
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row">MLB Baseball</th>
                        <td>
                            <label>
                                <input type="checkbox" name="sport_baseball_mlb" value="1" <?php checked(isset($enabled_sports['baseball_mlb']) && $enabled_sports['baseball_mlb']); ?>>
                                Enable MLB
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row">NHL Hockey</th>
                        <td>
                            <label>
                                <input type="checkbox" name="sport_icehockey_nhl" value="1" <?php checked(isset($enabled_sports['icehockey_nhl']) && $enabled_sports['icehockey_nhl']); ?>>
                                Enable NHL
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row">Soccer - EPL</th>
                        <td>
                            <label>
                                <input type="checkbox" name="sport_soccer_epl" value="1" <?php checked(isset($enabled_sports['soccer_epl']) && $enabled_sports['soccer_epl']); ?>>
                                Enable English Premier League
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row">Soccer - Champions League</th>
                        <td>
                            <label>
                                <input type="checkbox" name="sport_soccer_uefa_champs_league" value="1" <?php checked(isset($enabled_sports['soccer_uefa_champs_league']) && $enabled_sports['soccer_uefa_champs_league']); ?>>
                                Enable UEFA Champions League
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row">Tennis - ATP</th>
                        <td>
                            <label>
                                <input type="checkbox" name="sport_tennis_atp" value="1" <?php checked(isset($enabled_sports['tennis_atp']) && $enabled_sports['tennis_atp']); ?>>
                                Enable ATP Tennis
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row">Tennis - WTA</th>
                        <td>
                            <label>
                                <input type="checkbox" name="sport_tennis_wta" value="1" <?php checked(isset($enabled_sports['tennis_wta']) && $enabled_sports['tennis_wta']); ?>>
                                Enable WTA Tennis
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row">UFC / MMA</th>
                        <td>
                            <label>
                                <input type="checkbox" name="sport_mma_mixed_martial_arts" value="1" <?php checked(isset($enabled_sports['mma_mixed_martial_arts']) && $enabled_sports['mma_mixed_martial_arts']); ?>>
                                Enable UFC / MMA
                            </label>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row">NCAA Basketball</th>
                        <td>
                            <label>
                                <input type="checkbox" name="sport_basketball_ncaab" value="1" <?php checked(isset($enabled_sports['basketball_ncaab']) && $enabled_sports['basketball_ncaab']); ?>>
                                Enable NCAA Basketball
                            </label>
                        </td>
                    </tr>
                </tbody>
            </table>

            <h3 style="margin-top: 30px;">The Odds API Settings</h3>
                    <table class="form-table">
                        <tbody>
                            <tr>
                                <th scope="row">API Key</th>
                                <td>
                                    <input type="text" name="odds_api_key" value="<?php echo esc_attr(get_option('sv_odds_api_key', '')); ?>" class="regular-text" placeholder="Enter your Odds API key">
                                    <p class="description">Your API key from <a href="https://the-odds-api.com/" target="_blank">The Odds API</a></p>
                                    <?php if (get_option('sv_odds_api_key')): ?>
                                        <p class="description" style="color: #46b450;">✓ API Key is configured</p>
                                    <?php else: ?>
                                        <p class="description" style="color: #dc3232;">⚠ No API key set - using fallback key</p>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        </tbody>
                    </table>

            <h3 style="margin-top: 30px;">API Refresh Settings</h3>
                    <table class="form-table">
                        <tbody>
                            <tr>
                                <th scope="row">Odds Refresh Interval</th>
                                <td>
                                    <select name="odds_refresh_interval">
                                        <option value="3600" <?php selected(get_option('sv_odds_refresh_interval', 1800), 3600); ?>>60 minutes</option>
                                        <option value="1800" <?php selected(get_option('sv_odds_refresh_interval', 1800), 1800); ?>>30 minutes</option>
                                        <option value="900" <?php selected(get_option('sv_odds_refresh_interval', 1800), 900); ?>>15 minutes</option>
                                        <option value="600" <?php selected(get_option('sv_odds_refresh_interval', 1800), 600); ?>>10 minutes</option>
                                        <option value="300" <?php selected(get_option('sv_odds_refresh_interval', 1800), 300); ?>>5 minutes</option>
                                    </select>
                                    <p class="description">How often to fetch fresh odds data (main lines + alternate lines)</p>
                                </td>
                            </tr>
                            <tr>
                                <th scope="row">Fetch Alternate Lines</th>
                                <td>
                                    <label>
                                        <input type="checkbox" name="enable_alternate_lines" value="1" <?php checked(get_option('sv_enable_alternate_lines', true)); ?>>
                                        Fetch and display alternate spreads and totals
                                    </label>
                                    <p class="description">Increases API usage but provides more betting options</p>
                                </td>
                            </tr>
                            <tr>
                                <th scope="row">Odds Screen Auto-Refresh</th>
                                <td>
                                    <label>
                                        <input type="checkbox" name="enable_odds_screen_auto_refresh" value="1" <?php checked(get_option('sv_enable_odds_screen_auto_refresh', false)); ?>>
                                        Enable server-side auto-refresh (background cron every 60 seconds)
                                    </label>
                                    <p class="description"><strong>API Usage:</strong> Exactly 60 requests/hour when enabled (server-side cron job). All users see the same cached data. Disable to fetch on-demand only.</p>
                                </td>
                            </tr>
                            <tr>
                                <th scope="row">Auto-Grading</th>
                                <td>
                                    <label>
                                        <input type="checkbox" name="enable_auto_grading" value="1" <?php checked(get_option('sv_enable_auto_grading', true)); ?>>
                                        Automatically grade bets when games complete
                                    </label>
                                    <p class="description">
                                        <strong>Frequency:</strong> Every 10 minutes (checks completed games only)<br>
                                        <?php
                                        $last_run = get_option('sv_last_grading_run', '--');
                                        $last_count = get_option('sv_last_grading_count', 0);
                                        ?>
                                        <strong>Last run:</strong> <?php echo esc_html($last_run); ?><br>
                                        <strong>Last graded:</strong> <?php echo intval($last_count); ?> bets
                                    </p>
                                </td>
                            </tr>
                        </tbody>
                    </table>

            <p class="submit">
                <input type="submit" name="sv_save_settings" class="button button-primary" value="Save All Settings">
            </p>
        </form>
    </div>

    <div style="background: #fff; padding: 20px; margin: 20px 0; border: 1px solid #ccc; border-radius: 5px;">
        <h2>Grading Management</h2>
        <?php
        global $wpdb;
        $table_name = $wpdb->prefix . 'sv_bet_slips';
        $pending_count = $wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE result = 'pending'");
        $invalid_count = $wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE sport = 'all'");
        $broken_keys_count = $wpdb->get_var("SELECT COUNT(*) FROM $table_name WHERE sport IN ('basketball_nba', 'americanfootball_nfl', 'basketball_ncaab', 'baseball_mlb', 'icehockey_nhl')");
        ?>
        <p>
            <strong>Pending bets:</strong> <?php echo intval($pending_count); ?><br>
            <?php if ($invalid_count > 0): ?>
                <strong style="color: #dc3232;">Invalid bets (sport="all"):</strong> <?php echo intval($invalid_count); ?><br>
            <?php endif; ?>
            <?php if ($broken_keys_count > 0): ?>
                <strong style="color: #ff9800;">Bets with API sport keys:</strong> <?php echo intval($broken_keys_count); ?> (need fixing)<br>
            <?php endif; ?>
            Manually trigger grading to check completed games and update bet results.
        </p>

        <form method="post" action="" style="display: inline-block; margin-right: 10px;">
            <?php wp_nonce_field('sv_admin_actions', 'sv_admin_nonce'); ?>
            <p class="submit">
                <input type="submit" name="sv_grade_now" class="button button-secondary" value="Grade Pending Bets Now">
            </p>
        </form>

        <?php if ($broken_keys_count > 0): ?>
        <form method="post" action="" style="display: inline-block; margin-right: 10px;">
            <?php wp_nonce_field('sv_admin_actions', 'sv_admin_nonce'); ?>
            <p class="submit">
                <input type="submit" name="sv_fix_sport_keys" class="button button-secondary" value="Fix Sport Keys" style="background: #ff9800; color: #fff; border-color: #ff9800;">
            </p>
        </form>
        <?php endif; ?>

        <?php if ($invalid_count > 0): ?>
        <form method="post" action="" style="display: inline-block;" onsubmit="return confirm('Delete <?php echo intval($invalid_count); ?> invalid bets?');">
            <?php wp_nonce_field('sv_admin_actions', 'sv_admin_nonce'); ?>
            <p class="submit">
                <input type="submit" name="sv_delete_invalid_bets" class="button button-secondary" value="Delete Invalid Bets" style="background: #dc3232; color: #fff; border-color: #dc3232;">
            </p>
        </form>
        <?php endif; ?>

        <hr style="margin: 20px 0;">

        <h3>Re-Grade Completed Bets</h3>
        <p>Use this if bets were graded incorrectly due to bugs (e.g., over/under backwards, spreads with team numbers). This will re-run grading logic on all completed bets and fix any that were wrong.</p>
        <form method="post" action="" style="display: inline-block;" onsubmit="return confirm('Re-grade all completed bets with fixed grading logic?\n\nThis will:\n- Re-run grading on all won/lost/push bets\n- Fix incorrectly graded spreads and totals\n- Update payouts\n- Log all changes\n\nContinue?');">
            <?php wp_nonce_field('sv_admin_actions', 'sv_admin_nonce'); ?>
            <p class="submit">
                <input type="submit" name="sv_regrade_all" class="button button-primary" value="Re-Grade All Completed Bets" style="background: #2271b1; border-color: #2271b1;">
            </p>
        </form>
    </div>

    <div style="background: #fff; padding: 20px; margin: 20px 0; border: 1px solid #ccc; border-radius: 5px;">
        <h2>Grading Debug Log</h2>
        <?php
        // Show last 50 lines of debug.log that contain "Grading:"
        $debug_log_path = WP_CONTENT_DIR . '/debug.log';
        $grading_logs = [];
        if (file_exists($debug_log_path)) {
            $lines = file($debug_log_path);
            $lines = array_reverse($lines); // Newest first
            foreach ($lines as $line) {
                if (stripos($line, 'Grading:') !== false) {
                    $grading_logs[] = $line;
                    if (count($grading_logs) >= 50) break;
                }
            }
        }
        ?>
        <?php if (!empty($grading_logs)): ?>
            <div style="background: #000; color: #0f0; font-family: monospace; font-size: 11px; padding: 10px; max-height: 300px; overflow-y: scroll; white-space: pre-wrap;">
<?php foreach ($grading_logs as $log): ?>
<?php echo esc_html($log); ?>
<?php endforeach; ?>
            </div>
        <?php else: ?>
            <p style="color: #dc3232;">No grading logs found. Grading may not have run yet, or debug logging is not enabled.</p>
            <p><strong>To enable debug logging:</strong> Add these lines to wp-config.php:<br>
            <code style="background: #f0f0f0; padding: 2px 6px;">define('WP_DEBUG', true);<br>define('WP_DEBUG_LOG', true);</code></p>
        <?php endif; ?>
    </div>

    <div style="background: #fff; padding: 20px; margin: 20px 0; border: 1px solid #ccc; border-radius: 5px;">
        <h2>Recent Bets (Debug View)</h2>
        <?php
        $recent_bets = $wpdb->get_results(
            "SELECT id, user_id, sport, game_id, pick_type, selection, result, event_date, bet_placed_at
             FROM $table_name
             ORDER BY bet_placed_at DESC
             LIMIT 20",
            ARRAY_A
        );
        ?>
        <p>Showing last 20 bets to verify data is saving correctly:</p>
        <div style="overflow-x: auto;">
            <table class="wp-list-table widefat fixed striped" style="font-size: 12px;">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>User</th>
                        <th style="background: #fff3cd;">Sport</th>
                        <th>Game ID</th>
                        <th>Pick Type</th>
                        <th>Selection</th>
                        <th>Result</th>
                        <th>Placed At</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (!empty($recent_bets)): ?>
                        <?php foreach ($recent_bets as $bet): ?>
                            <tr>
                                <td><?php echo esc_html($bet['id']); ?></td>
                                <td><?php echo esc_html($bet['user_id']); ?></td>
                                <td style="<?php echo ($bet['sport'] === 'all') ? 'background: #ff000020; font-weight: bold;' : 'background: #00ff0020;'; ?>">
                                    <?php echo esc_html($bet['sport']); ?>
                                    <?php if ($bet['sport'] === 'all'): ?>
                                        <span style="color: red;">❌ INVALID</span>
                                    <?php endif; ?>
                                </td>
                                <td style="font-size: 10px;"><?php echo esc_html(substr($bet['game_id'], 0, 30)); ?>...</td>
                                <td><?php echo esc_html($bet['pick_type']); ?></td>
                                <td><?php echo esc_html($bet['selection']); ?></td>
                                <td><?php echo esc_html($bet['result']); ?></td>
                                <td><?php echo esc_html($bet['bet_placed_at']); ?></td>
                            </tr>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="8">No bets found</td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>

    <div style="background: #fff; padding: 20px; margin: 20px 0; border: 1px solid #ccc; border-radius: 5px;">
        <h2>Data Management</h2>
        <p>Clear all user picks from the database. <strong>This action cannot be undone!</strong></p>

        <form method="post" action="" onsubmit="return confirm('Are you sure you want to delete ALL picks? This cannot be undone!');">
            <?php wp_nonce_field('sv_admin_actions', 'sv_admin_nonce'); ?>
            <p class="submit">
                <input type="submit" name="sv_clear_picks" class="button button-secondary" value="Clear All Picks" style="background: #dc3232; color: #fff; border-color: #dc3232;">
            </p>
        </form>
    </div>
</div>
