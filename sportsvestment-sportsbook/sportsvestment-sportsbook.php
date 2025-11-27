<?php
/**
 * Plugin Name: SportsVestment Sportsbook
 * Plugin URI: https://sportsvestment.com
 * Description: Unified sportsbook interface for multi-sport pick'em pools with Odds API integration
 * Version: 2.3.0
 * Author: SportsVestment
 * Author URI: https://sportsvestment.com
 * License: Proprietary
 * Text Domain: sv-sportsbook
 *
 * @package SportsVestment_Sportsbook
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Main SportsVestment Sportsbook Class
 *
 * This is the unified sportsbook app that replaces individual sport pick'em shortcodes.
 * Users can browse all sports, make picks, and enter pools from one interface.
 */
class SV_Sportsbook {

    /**
     * Plugin version
     */
    const VERSION = '2.3.0';

    /**
     * Singleton instance
     */
    private static $instance = null;

    /**
     * Get singleton instance
     */
    public static function get_instance() {
        if (null === self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Constructor
     */
    private function __construct() {
        $this->define_constants();
        $this->includes();
        $this->init_hooks();
    }

    /**
     * Define plugin constants
     */
    private function define_constants() {
        define('SV_SPORTSBOOK_VERSION', self::VERSION);
        define('SV_SPORTSBOOK_PLUGIN_DIR', plugin_dir_path(__FILE__));
        define('SV_SPORTSBOOK_PLUGIN_URL', plugin_dir_url(__FILE__));
        define('SV_SPORTSBOOK_PLUGIN_FILE', __FILE__);
    }

    /**
     * Include required files
     */
    private function includes() {
        // Core classes
        require_once SV_SPORTSBOOK_PLUGIN_DIR . 'core/class-odds-api-fetcher.php';
        require_once SV_SPORTSBOOK_PLUGIN_DIR . 'core/class-ajax-handler.php';
        require_once SV_SPORTSBOOK_PLUGIN_DIR . 'core/class-grading-engine.php';
        // require_once SV_SPORTSBOOK_PLUGIN_DIR . 'core/class-sportsbook-manager.php';

        // AJAX handler will initialize itself
    }

    /**
     * Initialize WordPress hooks
     */
    private function init_hooks() {
        // Activation/deactivation
        register_activation_hook(__FILE__, array($this, 'activate'));
        register_deactivation_hook(__FILE__, array($this, 'deactivate'));

        // Check database on every init
        add_action('init', array($this, 'check_database'));

        // Register shortcodes
        add_shortcode('sv_sportsbook', array($this, 'render_sportsbook'));

        // Enqueue assets
        add_action('wp_enqueue_scripts', array($this, 'enqueue_assets'));

        // Server-side odds refresh cron
        add_action('sv_refresh_odds_screen', array($this, 'cron_refresh_odds_screen'));
        add_action('init', array($this, 'schedule_odds_refresh'));

        // Auto-grading cron
        add_action('sv_grade_bets', array($this, 'cron_grade_bets'));
        add_action('init', array($this, 'schedule_grading'));
    }

    /**
     * Plugin activation
     */
    public function activate() {
        // Create database tables
        $this->create_bet_slips_table();
        update_option('sv_sportsbook_db_version', self::VERSION);

        // Flush rewrite rules
        flush_rewrite_rules();
    }

    /**
     * Plugin deactivation
     */
    public function deactivate() {
        // Clean up (if needed)
        flush_rewrite_rules();
    }

    /**
     * Check and create database tables if needed
     */
    public function check_database() {
        global $wpdb;

        $table_name = $wpdb->prefix . 'sv_bet_slips';
        $db_version = get_option('sv_sportsbook_db_version', '0');

        // Check if table exists
        $table_exists = $wpdb->get_var("SHOW TABLES LIKE '$table_name'") === $table_name;

        // If table doesn't exist or version mismatch, create/update it
        if (!$table_exists || version_compare($db_version, self::VERSION, '<')) {
            $this->create_bet_slips_table();
            update_option('sv_sportsbook_db_version', self::VERSION);
        }
    }

    /**
     * Create bet slips table
     */
    private function create_bet_slips_table() {
        global $wpdb;

        $table_name = $wpdb->prefix . 'sv_bet_slips';
        $charset_collate = $wpdb->get_charset_collate();

        $sql = "CREATE TABLE IF NOT EXISTS $table_name (
            id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
            slip_number varchar(50) NOT NULL,
            user_id bigint(20) UNSIGNED NOT NULL,
            sport varchar(20) NOT NULL,
            game_id varchar(100) NOT NULL,
            away_team varchar(100) NOT NULL,
            home_team varchar(100) NOT NULL,
            event_date datetime NOT NULL,
            pick_type varchar(20) NOT NULL,
            selection varchar(200) NOT NULL,
            odds varchar(20) NOT NULL,
            units decimal(10,2) NOT NULL,
            bet_placed_at datetime NOT NULL,
            bet_graded_at datetime DEFAULT NULL,
            result varchar(20) DEFAULT 'pending',
            away_score int(11) DEFAULT NULL,
            home_score int(11) DEFAULT NULL,
            payout decimal(10,2) DEFAULT NULL,
            created_at datetime DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY  (id),
            KEY user_id (user_id),
            KEY slip_number (slip_number),
            KEY result (result),
            KEY event_date (event_date),
            KEY game_id (game_id),
            KEY bet_placed_at (bet_placed_at),
            KEY user_result_date (user_id, result, bet_placed_at),
            KEY user_date (user_id, bet_placed_at)
        ) $charset_collate;";

        require_once(ABSPATH . 'wp-admin/includes/upgrade.php');
        dbDelta($sql);
    }

    /**
     * Enqueue CSS and JavaScript
     */
    public function enqueue_assets() {
        // Only load on pages with shortcode
        if (!is_singular()) {
            return;
        }

        global $post;
        if (!has_shortcode($post->post_content, 'sv_sportsbook')) {
            return;
        }

        // CSS
        wp_enqueue_style(
            'sv-sportsbook-styles',
            SV_SPORTSBOOK_PLUGIN_URL . 'assets/css/sportsbook.css',
            array(),
            SV_SPORTSBOOK_VERSION
        );

        // JavaScript
        wp_enqueue_script(
            'sv-sportsbook-scripts',
            SV_SPORTSBOOK_PLUGIN_URL . 'assets/js/sportsbook.js',
            array('jquery'),
            SV_SPORTSBOOK_VERSION,
            true
        );

        // Pass data to JavaScript
        wp_localize_script('sv-sportsbook-scripts', 'svSportsbook', array(
            'ajaxUrl' => admin_url('admin-ajax.php'),
            'nonce' => wp_create_nonce('sv_sportsbook_nonce'),
            'userId' => get_current_user_id(),
        ));
    }

    /**
     * Render admin page
     */
    public function render_admin_page() {
        // Handle form submissions
        if (isset($_POST['sv_clear_picks']) && check_admin_referer('sv_admin_actions', 'sv_admin_nonce')) {
            $this->clear_all_picks();
            echo '<div class="notice notice-success"><p>All picks cleared successfully.</p></div>';
        }

        if (isset($_POST['sv_grade_now']) && check_admin_referer('sv_admin_actions', 'sv_admin_nonce')) {
            $grader = new SV_Grading_Engine();
            $result = $grader->grade_pending_bets();
            echo '<div class="notice notice-success"><p>' . esc_html($result['message']) . '</p></div>';
        }

        if (isset($_POST['sv_delete_invalid_bets']) && check_admin_referer('sv_admin_actions', 'sv_admin_nonce')) {
            global $wpdb;
            $deleted = $wpdb->delete(
                $wpdb->prefix . 'sv_bet_slips',
                array('sport' => 'all'),
                array('%s')
            );
            echo '<div class="notice notice-success"><p>Deleted ' . intval($deleted) . ' invalid bets with sport="all"</p></div>';
        }

        if (isset($_POST['sv_fix_sport_keys']) && check_admin_referer('sv_admin_actions', 'sv_admin_nonce')) {
            global $wpdb;
            $table = $wpdb->prefix . 'sv_bet_slips';

            // Map API keys to internal keys
            $mappings = array(
                'basketball_nba' => 'nba',
                'americanfootball_nfl' => 'nfl',
                'baseball_mlb' => 'mlb',
                'icehockey_nhl' => 'nhl',
                'basketball_ncaab' => 'ncaab',
            );

            $fixed_count = 0;
            foreach ($mappings as $api_key => $internal_key) {
                $updated = $wpdb->update(
                    $table,
                    array('sport' => $internal_key),
                    array('sport' => $api_key),
                    array('%s'),
                    array('%s')
                );
                if ($updated) $fixed_count += $updated;
            }

            echo '<div class="notice notice-success"><p>Fixed ' . intval($fixed_count) . ' bets with incorrect sport keys</p></div>';
        }

        if (isset($_POST['sv_regrade_all']) && check_admin_referer('sv_admin_actions', 'sv_admin_nonce')) {
            $result = $this->regrade_all_completed_bets();
            if ($result['success']) {
                echo '<div class="notice notice-success"><p><strong>Re-Grading Complete!</strong><br>' . esc_html($result['message']) . '</p></div>';
                if (!empty($result['changes'])) {
                    echo '<div class="notice notice-info"><p><strong>Changes Made:</strong></p><ul style="margin: 5px 0; padding-left: 20px;">';
                    foreach ($result['changes'] as $change) {
                        echo '<li>' . esc_html($change) . '</li>';
                    }
                    echo '</ul></div>';
                }
            } else {
                echo '<div class="notice notice-error"><p>Error: ' . esc_html($result['message']) . '</p></div>';
            }
        }

        if (isset($_POST['sv_save_settings']) && check_admin_referer('sv_admin_actions', 'sv_admin_nonce')) {
            $this->save_sport_settings();
            echo '<div class="notice notice-success"><p>Settings saved successfully.</p></div>';
        }

        // Get current settings
        $enabled_sports = get_option('sv_enabled_sports', array(
            'basketball_nba' => true,
            'americanfootball_nfl' => true,
            'baseball_mlb' => true,
            'icehockey_nhl' => true,
        ));

        include SV_SPORTSBOOK_PLUGIN_DIR . 'templates/admin-page.php';
    }

    /**
     * Save sport settings
     */
    private function save_sport_settings() {
        $sports = array(
            'basketball_nba',
            'americanfootball_nfl',
            'baseball_mlb',
            'icehockey_nhl',
            'basketball_ncaab',
            'soccer_epl',
            'soccer_uefa_champs_league',
            'tennis_atp',
            'tennis_wta',
            'mma_mixed_martial_arts',
        );

        $enabled_sports = array();
        foreach ($sports as $sport) {
            $enabled_sports[$sport] = isset($_POST['sport_' . $sport]);
        }

        update_option('sv_enabled_sports', $enabled_sports);

        // Save API Key
        if (isset($_POST['odds_api_key'])) {
            update_option('sv_odds_api_key', sanitize_text_field($_POST['odds_api_key']));
        }

        // Save API refresh settings
        if (isset($_POST['odds_refresh_interval'])) {
            update_option('sv_odds_refresh_interval', intval($_POST['odds_refresh_interval']));
        }

        if (isset($_POST['enable_alternate_lines'])) {
            update_option('sv_enable_alternate_lines', true);
        } else {
            update_option('sv_enable_alternate_lines', false);
        }

        if (isset($_POST['enable_odds_screen_auto_refresh'])) {
            update_option('sv_enable_odds_screen_auto_refresh', true);
        } else {
            update_option('sv_enable_odds_screen_auto_refresh', false);
        }

        if (isset($_POST['enable_auto_grading'])) {
            update_option('sv_enable_auto_grading', true);
        } else {
            update_option('sv_enable_auto_grading', false);
        }
    }

    /**
     * Clear all picks
     */
    private function clear_all_picks() {
        global $wpdb;
        $table_name = $wpdb->prefix . 'sv_bet_slips';
        $wpdb->query("TRUNCATE TABLE $table_name");
    }

    /**
     * Render sportsbook shortcode
     *
     * Usage: [sv_sportsbook]
     */
    public function render_sportsbook($atts) {
        // Check if user is logged in
        if (!is_user_logged_in()) {
            return '<p>Please log in to access the sportsbook.</p>';
        }

        // Load template
        ob_start();
        include SV_SPORTSBOOK_PLUGIN_DIR . 'templates/sportsbook.php';
        return ob_get_clean();
    }

    /**
     * Schedule server-side odds refresh cron
     */
    public function schedule_odds_refresh() {
        $enabled = get_option('sv_enable_odds_screen_auto_refresh', false);

        if ($enabled) {
            // Schedule cron if not already scheduled
            if (!wp_next_scheduled('sv_refresh_odds_screen')) {
                wp_schedule_event(time(), 'every_minute', 'sv_refresh_odds_screen');
            }
        } else {
            // Unschedule if disabled
            $timestamp = wp_next_scheduled('sv_refresh_odds_screen');
            if ($timestamp) {
                wp_unschedule_event($timestamp, 'sv_refresh_odds_screen');
            }
        }
    }

    /**
     * Cron job: Refresh odds screen data
     */
    public function cron_refresh_odds_screen() {
        // Only run if enabled
        if (!get_option('sv_enable_odds_screen_auto_refresh', false)) {
            return;
        }

        // Fetch multi-book odds for all sports
        $fetcher = new SV_Odds_API_Fetcher();
        $games = $fetcher->fetch_all_sports_multi_book();

        // Store in transient (cache for 2 minutes in case cron misses)
        if (!is_wp_error($games)) {
            set_transient('sv_odds_screen_data', $games, 120);
            update_option('sv_odds_screen_last_update', current_time('mysql'));
        }
    }

    /**
     * Schedule auto-grading cron
     */
    public function schedule_grading() {
        $enabled = get_option('sv_enable_auto_grading', true);

        if ($enabled) {
            // Schedule cron if not already scheduled
            if (!wp_next_scheduled('sv_grade_bets')) {
                wp_schedule_event(time(), 'every_10_minutes', 'sv_grade_bets');
            }
        } else {
            // Unschedule if disabled
            $timestamp = wp_next_scheduled('sv_grade_bets');
            if ($timestamp) {
                wp_unschedule_event($timestamp, 'sv_grade_bets');
            }
        }
    }

    /**
     * Cron job: Grade pending bets
     */
    public function cron_grade_bets() {
        // Only run if enabled
        if (!get_option('sv_enable_auto_grading', true)) {
            return;
        }

        // Run grading engine
        $grader = new SV_Grading_Engine();
        $result = $grader->grade_pending_bets();

        // Log result
        if ($result['graded'] > 0) {
            error_log('Auto-grading: ' . $result['message']);
            update_option('sv_last_grading_run', current_time('mysql'));
            update_option('sv_last_grading_count', $result['graded']);
        }
    }

    /**
     * Re-grade all completed bets with fixed grading logic
     * This is used to fix bets that were graded incorrectly due to bugs
     *
     * @return array Result with success status, message, and list of changes
     */
    private function regrade_all_completed_bets() {
        global $wpdb;
        $table_name = $wpdb->prefix . 'sv_bet_slips';

        // Get all completed bets (won, lost, push)
        $completed_bets = $wpdb->get_results(
            "SELECT * FROM $table_name WHERE result IN ('won', 'lost', 'push') ORDER BY event_date DESC",
            ARRAY_A
        );

        if (empty($completed_bets)) {
            return array(
                'success' => true,
                'message' => 'No completed bets found to re-grade',
                'changes' => array()
            );
        }

        error_log('Re-grading: Found ' . count($completed_bets) . ' completed bets');

        // Group bets by sport for efficient API calls
        $bets_by_sport = array();
        foreach ($completed_bets as $bet) {
            $sport = $bet['sport'];
            if ($sport === 'all' || empty($sport)) {
                continue; // Skip invalid sports
            }
            if (!isset($bets_by_sport[$sport])) {
                $bets_by_sport[$sport] = array();
            }
            $bets_by_sport[$sport][] = $bet;
        }

        // Initialize results tracking
        $changes = array();
        $updated_count = 0;
        $checked_count = 0;

        // Fetch scores and re-grade each sport's bets
        $fetcher = new SV_Odds_API_Fetcher();

        foreach ($bets_by_sport as $sport => $bets) {
            error_log('Re-grading: Checking ' . count($bets) . ' ' . $sport . ' bets');

            // Fetch scores for this sport
            $scores = $fetcher->fetch_scores($sport);

            if (is_wp_error($scores)) {
                error_log('Re-grading error for ' . $sport . ': ' . $scores->get_error_message());
                continue;
            }

            // Re-grade each bet
            foreach ($bets as $bet) {
                $checked_count++;

                // Find the game
                $game = $this->find_game_in_scores($scores, $bet['game_id']);

                if (!$game || !isset($game['completed']) || !$game['completed']) {
                    continue; // Game not found or not completed
                }

                // Re-grade using the NEW fixed logic
                $new_result = $this->regrade_single_bet($bet, $game);

                if ($new_result === null) {
                    continue; // Couldn't grade
                }

                // Compare old vs new
                $old_result = $bet['result'];
                $old_payout = floatval($bet['payout']);

                if ($new_result['result'] !== $old_result || abs($new_result['payout'] - $old_payout) > 0.01) {
                    // Results differ - update database
                    $wpdb->update(
                        $table_name,
                        array(
                            'result' => $new_result['result'],
                            'payout' => $new_result['payout'],
                            'bet_graded_at' => current_time('mysql', true),
                        ),
                        array('id' => $bet['id']),
                        array('%s', '%f', '%s'),
                        array('%d')
                    );

                    // Log the change
                    $change_msg = sprintf(
                        'Bet #%d (%s vs %s - %s): %s (%+.2f) → %s (%+.2f)',
                        $bet['id'],
                        $bet['away_team'],
                        $bet['home_team'],
                        $bet['selection'],
                        strtoupper($old_result),
                        $old_payout,
                        strtoupper($new_result['result']),
                        $new_result['payout']
                    );

                    $changes[] = $change_msg;
                    error_log('Re-grading: ' . $change_msg);
                    $updated_count++;
                }
            }
        }

        $message = sprintf(
            'Re-graded %d completed bets. Found %d that needed corrections.',
            $checked_count,
            $updated_count
        );

        return array(
            'success' => true,
            'message' => $message,
            'changes' => $changes
        );
    }

    /**
     * Find game in scores array by game_id
     */
    private function find_game_in_scores($games, $game_id) {
        foreach ($games as $game) {
            if ($game['id'] === $game_id) {
                return $game;
            }
        }
        return null;
    }

    /**
     * Re-grade a single bet using FIXED grading logic
     */
    private function regrade_single_bet($bet, $game) {
        if (!isset($game['scores']) || empty($game['scores'])) {
            return null; // No scores
        }

        // Extract final scores
        $away_score = null;
        $home_score = null;

        foreach ($game['scores'] as $team_score) {
            if ($team_score['name'] === $game['away_team']) {
                $away_score = intval($team_score['score']);
            } elseif ($team_score['name'] === $game['home_team']) {
                $home_score = intval($team_score['score']);
            }
        }

        if ($away_score === null || $home_score === null) {
            return null; // Incomplete scores
        }

        // Grade based on pick type using FIXED logic
        $result = 'pending';

        switch ($bet['pick_type']) {
            case 'moneyline':
                $result = $this->regrade_moneyline($bet, $away_score, $home_score);
                break;

            case 'spread':
                $result = $this->regrade_spread($bet, $away_score, $home_score);
                break;

            case 'total':
                $result = $this->regrade_total($bet, $away_score, $home_score);
                break;
        }

        // Calculate payout
        $payout = $this->calculate_bet_payout($bet['units'], $bet['odds'], $result);

        return array(
            'result' => $result,
            'payout' => $payout,
        );
    }

    /**
     * Re-grade moneyline bet
     */
    private function regrade_moneyline($bet, $away_score, $home_score) {
        $selection = $bet['selection'];
        $away_team = $bet['away_team'];
        $home_team = $bet['home_team'];

        // Determine winner
        if ($away_score > $home_score) {
            $winner = $away_team;
        } elseif ($home_score > $away_score) {
            $winner = $home_team;
        } else {
            return 'push'; // Tie
        }

        // Check if user picked the winner
        if (strpos($selection, $winner) !== false) {
            return 'won';
        } else {
            return 'lost';
        }
    }

    /**
     * Re-grade spread bet with FIXED parsing (requires +/- sign)
     */
    private function regrade_spread($bet, $away_score, $home_score) {
        $selection = $bet['selection'];
        $away_team = $bet['away_team'];
        $home_team = $bet['home_team'];

        // Parse spread - FIXED: +/- is REQUIRED (not optional)
        // This prevents matching team numbers like "76" in "76ers +20"
        preg_match('/([+-]\d+\.?\d*)/', $selection, $matches);
        if (empty($matches)) {
            error_log('Re-grading: Cannot parse spread from selection: ' . $selection);
            return $bet['result']; // Keep original if can't parse
        }

        $spread = floatval($matches[1]);

        // Determine which team user picked
        if (strpos($selection, $away_team) !== false) {
            // User picked away team
            $adjusted_score = $away_score + $spread;
            if ($adjusted_score > $home_score) {
                return 'won';
            } elseif ($adjusted_score < $home_score) {
                return 'lost';
            } else {
                return 'push';
            }
        } else {
            // User picked home team
            $adjusted_score = $home_score + $spread;
            if ($adjusted_score > $away_score) {
                return 'won';
            } elseif ($adjusted_score < $away_score) {
                return 'lost';
            } else {
                return 'push';
            }
        }
    }

    /**
     * Re-grade total bet with FIXED over/under detection
     */
    private function regrade_total($bet, $away_score, $home_score) {
        $selection = $bet['selection'];
        $total_score = $away_score + $home_score;

        // Parse total from selection (e.g., "Over 215.5" or "O 215.5")
        preg_match('/(\d+\.?\d*)/', $selection, $matches);
        if (empty($matches)) {
            error_log('Re-grading: Cannot parse total from selection: ' . $selection);
            return $bet['result']; // Keep original if can't parse
        }

        $line = floatval($matches[1]);

        // FIXED: Check for both "Over"/"O" and "Under"/"U" formats
        $is_over = (stripos($selection, 'over') !== false || stripos($selection, 'O ') !== false || strpos($selection, 'O') === 0);

        if ($is_over) {
            if ($total_score > $line) {
                return 'won';
            } elseif ($total_score < $line) {
                return 'lost';
            } else {
                return 'push';
            }
        } else {
            // Under
            if ($total_score < $line) {
                return 'won';
            } elseif ($total_score > $line) {
                return 'lost';
            } else {
                return 'push';
            }
        }
    }

    /**
     * Calculate payout based on American odds
     */
    private function calculate_bet_payout($units, $odds, $result) {
        if ($result === 'lost') {
            return -$units;
        }

        if ($result === 'push') {
            return 0;
        }

        // Convert American odds to payout multiplier
        $odds_value = intval(str_replace('+', '', $odds));

        if ($odds_value >= 0) {
            // Positive odds: profit = (odds / 100) * units
            $profit = ($odds_value / 100) * $units;
        } else {
            // Negative odds: profit = (100 / abs(odds)) * units
            $profit = (100 / abs($odds_value)) * $units;
        }

        return round($profit, 2);
    }

    /**
     * Calculate user stats for a date range
     *
     * @param int $user_id User ID
     * @param string $start_date Start date (Y-m-d H:i:s)
     * @param string $end_date End date (Y-m-d H:i:s)
     * @return array Stats with wins, losses, net_profit, total_risked, svr_score
     */
    private function calculate_stats($user_id, $start_date, $end_date) {
        global $wpdb;
        $table_name = $wpdb->prefix . 'sv_bet_slips';

        // Use optimized SQL aggregation instead of PHP loops
        $stats = $wpdb->get_row($wpdb->prepare(
            "SELECT
                SUM(CASE WHEN result = 'won' THEN 1 ELSE 0 END) as wins,
                SUM(CASE WHEN result = 'lost' THEN 1 ELSE 0 END) as losses,
                SUM(CASE WHEN result = 'push' THEN 1 ELSE 0 END) as pushes,
                SUM(payout) as net_profit,
                SUM(units) as total_risked,
                COUNT(*) as total_bets
             FROM $table_name
             WHERE user_id = %d
             AND result IN ('won', 'lost', 'push')
             AND bet_placed_at >= %s
             AND bet_placed_at <= %s",
            $user_id,
            $start_date,
            $end_date
        ), ARRAY_A);

        // Handle empty result
        if (!$stats || $stats['total_bets'] == 0) {
            return array(
                'wins' => 0,
                'losses' => 0,
                'pushes' => 0,
                'net_profit' => 0,
                'total_risked' => 0,
                'svr_score' => 50,
                'total_bets' => 0,
            );
        }

        $wins = intval($stats['wins']);
        $losses = intval($stats['losses']);
        $pushes = intval($stats['pushes']);
        $net_profit = floatval($stats['net_profit']);
        $total_risked = floatval($stats['total_risked']);

        // Calculate SVR Score: 50 + 1000 × (Net Profit ÷ Total Risked)
        // Clamped between 20-100 range
        // 50 = break-even, 100 = excellent, 20 = terrible
        $svr_score = 50;
        if ($total_risked > 0) {
            $svr_score = 50 + 1000 * ($net_profit / $total_risked);
            $svr_score = max(20, min(100, $svr_score)); // Clamp to 20-100 range
        }

        return array(
            'wins' => $wins,
            'losses' => $losses,
            'pushes' => $pushes,
            'net_profit' => round($net_profit, 2),
            'total_risked' => round($total_risked, 2),
            'svr_score' => round($svr_score, 1),
            'total_bets' => intval($stats['total_bets']),
        );
    }

    /**
     * Get weekly stats (current week: Sunday to Saturday)
     * Cached for 5 minutes for performance
     *
     * @param int $user_id User ID
     * @return array Stats for current week
     */
    public function get_weekly_stats($user_id) {
        // Check cache first (5 minute cache)
        $cache_key = 'sv_weekly_stats_' . $user_id;
        $cached_stats = get_transient($cache_key);

        if ($cached_stats !== false) {
            return $cached_stats;
        }

        // Get current week's Sunday (start)
        $today = new DateTime('now', new DateTimeZone('America/New_York'));
        $day_of_week = $today->format('w'); // 0 (Sunday) to 6 (Saturday)

        // Calculate days since Sunday
        $days_since_sunday = $day_of_week;

        $sunday = clone $today;
        $sunday->modify("-{$days_since_sunday} days");
        $sunday->setTime(0, 0, 0);

        // Saturday is 6 days after Sunday
        $saturday = clone $sunday;
        $saturday->modify('+6 days');
        $saturday->setTime(23, 59, 59);

        $start_date = $sunday->format('Y-m-d H:i:s');
        $end_date = $saturday->format('Y-m-d H:i:s');

        $stats = $this->calculate_stats($user_id, $start_date, $end_date);

        // Cache for 5 minutes (300 seconds)
        set_transient($cache_key, $stats, 300);

        return $stats;
    }

    /**
     * Get monthly stats (last 30 days)
     * Cached for 5 minutes for performance
     *
     * @param int $user_id User ID
     * @return array Stats for last 30 days
     */
    public function get_monthly_stats($user_id) {
        // Check cache first (5 minute cache)
        $cache_key = 'sv_monthly_stats_' . $user_id;
        $cached_stats = get_transient($cache_key);

        if ($cached_stats !== false) {
            return $cached_stats;
        }

        $today = new DateTime('now', new DateTimeZone('America/New_York'));
        $today->setTime(23, 59, 59);

        $thirty_days_ago = clone $today;
        $thirty_days_ago->modify('-30 days');
        $thirty_days_ago->setTime(0, 0, 0);

        $start_date = $thirty_days_ago->format('Y-m-d H:i:s');
        $end_date = $today->format('Y-m-d H:i:s');

        $stats = $this->calculate_stats($user_id, $start_date, $end_date);

        // Cache for 5 minutes (300 seconds)
        set_transient($cache_key, $stats, 300);

        return $stats;
    }

    /**
     * Clear stats cache for a user (call this when bets are graded or deleted)
     *
     * @param int $user_id User ID
     */
    public function clear_stats_cache($user_id) {
        delete_transient('sv_weekly_stats_' . $user_id);
        delete_transient('sv_monthly_stats_' . $user_id);
    }
}

/**
 * Initialize the plugin
 */
function sv_sportsbook_init() {
    global $sv_sportsbook_instance;
    $sv_sportsbook_instance = SV_Sportsbook::get_instance();
    return $sv_sportsbook_instance;
}

// Start the plugin
add_action('plugins_loaded', 'sv_sportsbook_init');

/**
 * Admin menu - hooked separately to ensure it loads
 */
function sv_sportsbook_admin_menu() {
    add_menu_page(
        'SportsVestment Sportsbook',
        'Sportsbook',
        'manage_options',
        'sv-sportsbook',
        'sv_sportsbook_admin_page',
        'dashicons-tickets-alt',
        30
    );
}
add_action('admin_menu', 'sv_sportsbook_admin_menu');

/**
 * Render admin page
 */
function sv_sportsbook_admin_page() {
    $instance = SV_Sportsbook::get_instance();
    $instance->render_admin_page();
}

/**
 * Add custom cron schedules
 */
function sv_add_cron_schedules($schedules) {
    $schedules['every_minute'] = array(
        'interval' => 60,
        'display' => __('Every Minute')
    );
    $schedules['every_10_minutes'] = array(
        'interval' => 600,
        'display' => __('Every 10 Minutes')
    );
    return $schedules;
}
add_filter('cron_schedules', 'sv_add_cron_schedules');
