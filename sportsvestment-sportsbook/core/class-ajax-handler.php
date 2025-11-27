<?php
/**
 * AJAX Handler
 *
 * Handles all AJAX requests for the sportsbook
 *
 * @package SportsVestment_Sportsbook
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

class SV_Sportsbook_AJAX {

    /**
     * Constructor
     */
    public function __construct() {
        // Load games
        add_action('wp_ajax_sv_load_games', array($this, 'load_games'));
        add_action('wp_ajax_nopriv_sv_load_games', array($this, 'load_games'));

        // Submit picks
        add_action('wp_ajax_sv_submit_picks', array($this, 'submit_picks'));

        // Save single pick
        add_action('wp_ajax_sv_save_pick', array($this, 'save_pick'));

        // Get user picks
        add_action('wp_ajax_sv_get_user_picks', array($this, 'get_user_picks'));

        // Get user stats (weekly and monthly)
        add_action('wp_ajax_sv_get_user_stats', array($this, 'get_user_stats'));

        // Delete pick
        add_action('wp_ajax_sv_delete_pick', array($this, 'delete_pick'));

        // Get qualified pools
        add_action('wp_ajax_sv_get_qualified_pools', array($this, 'get_qualified_pools'));

        // Load alternate lines for a specific game
        add_action('wp_ajax_sv_load_alternate_lines', array($this, 'load_alternate_lines'));
        add_action('wp_ajax_nopriv_sv_load_alternate_lines', array($this, 'load_alternate_lines'));

        // Load odds screen (multi-bookmaker comparison)
        add_action('wp_ajax_sv_load_odds_screen', array($this, 'load_odds_screen'));
        add_action('wp_ajax_nopriv_sv_load_odds_screen', array($this, 'load_odds_screen'));
    }

    /**
     * Load games with odds
     */
    public function load_games() {
        check_ajax_referer('sv_sportsbook_nonce', 'nonce');

        $sport = isset($_POST['sport']) ? sanitize_text_field($_POST['sport']) : 'all';

        // Get fetcher
        $fetcher = new SV_Odds_API_Fetcher();

        // Fetch games
        if ($sport === 'all') {
            $games = $fetcher->fetch_all_sports();
        } else {
            $games = $fetcher->fetch_odds($sport);
        }

        // Check for errors
        if (is_wp_error($games)) {
            wp_send_json_error(array(
                'message' => $games->get_error_message(),
            ));
        }

        // Note: API only returns upcoming games (commenceTimeFrom parameter)
        // No filtering needed here

        // Get API usage stats
        $api_remaining = get_option('sv_api_requests_remaining', '--');
        $api_used = get_option('sv_api_requests_used', '--');

        // Return games with API stats
        wp_send_json_success(array(
            'games' => $games,
            'count' => count($games),
            'api_remaining' => $api_remaining,
            'api_used' => $api_used,
        ));
    }

    /**
     * Submit picks
     */
    public function submit_picks() {
        check_ajax_referer('sv_sportsbook_nonce', 'nonce');

        // Check if user is logged in
        if (!is_user_logged_in()) {
            wp_send_json_error(array(
                'message' => 'You must be logged in to submit picks.',
            ));
        }

        $user_id = get_current_user_id();

        // Get picks from POST
        $picks_json = isset($_POST['picks']) ? stripslashes($_POST['picks']) : '';
        $picks = json_decode($picks_json, true);

        if (empty($picks) || !is_array($picks)) {
            wp_send_json_error(array(
                'message' => 'No picks provided.',
            ));
        }

        // Save picks temporarily (we'll store properly later)
        update_user_meta($user_id, 'sv_pending_picks', $picks);
        update_user_meta($user_id, 'sv_pending_picks_time', current_time('mysql'));

        // Get qualified pools
        $qualified_pools = $this->find_qualified_pools($user_id, $picks);

        wp_send_json_success(array(
            'message' => 'Picks submitted successfully',
            'picks_count' => count($picks),
            'qualified_pools' => $qualified_pools,
        ));
    }

    /**
     * Save pick to database
     */
    public function save_pick() {
        global $wpdb;
        check_ajax_referer('sv_sportsbook_nonce', 'nonce');

        if (!is_user_logged_in()) {
            wp_send_json_error(array('message' => 'Must be logged in'));
        }

        $user_id = get_current_user_id();
        $pick_json = isset($_POST['pick']) ? stripslashes($_POST['pick']) : '';
        $pick = json_decode($pick_json, true);

        if (empty($pick)) {
            wp_send_json_error(array('message' => 'No pick data'));
        }

        // Generate slip number: SV-YYYYMMDD-XXXXX
        $slip_number = 'SV-' . date('Ymd') . '-' . str_pad(rand(1, 99999), 5, '0', STR_PAD_LEFT);

        // Convert API sport_key to internal key (e.g., 'basketball_ncaab' -> 'ncaab')
        $sport = $this->normalize_sport_key(sanitize_text_field($pick['sport']));

        // Insert into bet_slips table
        $table_name = $wpdb->prefix . 'sv_bet_slips';
        $inserted = $wpdb->insert(
            $table_name,
            array(
                'slip_number' => $slip_number,
                'user_id' => $user_id,
                'sport' => $sport,
                'game_id' => sanitize_text_field($pick['gameId']),
                'away_team' => sanitize_text_field($pick['awayTeam']),
                'home_team' => sanitize_text_field($pick['homeTeam']),
                'event_date' => date('Y-m-d H:i:s', strtotime($pick['eventDate'])),
                'pick_type' => sanitize_text_field($pick['pickType']),
                'selection' => sanitize_text_field($pick['selection']),
                'odds' => sanitize_text_field($pick['odds']),
                'units' => floatval($pick['units']),
                'bet_placed_at' => current_time('mysql', true), // true = get UTC time
                'result' => 'pending',
            ),
            array('%s', '%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%f', '%s', '%s')
        );

        if ($inserted === false) {
            wp_send_json_error(array('message' => 'Failed to save pick to database'));
        }

        // Clear user picks cache
        delete_transient('sv_user_picks_' . $user_id);

        wp_send_json_success(array(
            'message' => 'Pick saved',
            'slip_number' => $slip_number,
            'slip_id' => $wpdb->insert_id,
        ));
    }

    /**
     * Normalize sport key from API format to internal format
     *
     * @param string $sport_key API sport key (e.g., 'basketball_ncaab', 'americanfootball_nfl')
     * @return string Internal sport key (e.g., 'ncaab', 'nfl')
     */
    private function normalize_sport_key($sport_key) {
        // Map API sport keys to internal keys
        $mapping = array(
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

        // If it's already an internal key, return as-is
        if (in_array($sport_key, $mapping)) {
            return $sport_key;
        }

        // Otherwise, try to map it
        return $mapping[$sport_key] ?? $sport_key;
    }

    /**
     * Find pools that match user's picks
     *
     * @param int $user_id User ID
     * @param array $picks User's picks
     * @return array Qualified pools
     */
    private function find_qualified_pools($user_id, $picks) {
        global $wpdb;

        // For now, return mock pools
        // We'll build real pool matching logic later
        $pools = array(
            array(
                'id' => 1,
                'name' => 'NBA Premium Pool',
                'entry_cost' => 10,
                'prize_pool' => 450,
                'entries_count' => 47,
                'type' => 'spread',
                'sport' => 'nba',
            ),
            array(
                'id' => 2,
                'name' => 'Cross-Sport Parlay',
                'entry_cost' => 25,
                'prize_pool' => 1200,
                'entries_count' => 52,
                'type' => 'mixed',
                'sport' => 'all',
            ),
            array(
                'id' => 3,
                'name' => 'High Stakes VIP',
                'entry_cost' => 50,
                'prize_pool' => 2500,
                'entries_count' => 28,
                'type' => 'premium',
                'sport' => 'all',
            ),
        );

        // Filter pools based on picks
        // For now, show all pools if user has 1+ picks
        if (count($picks) >= 1) {
            return $pools;
        }

        return array();
    }

    /**
     * Get qualified pools (separate endpoint if needed)
     */
    public function get_qualified_pools() {
        check_ajax_referer('sv_sportsbook_nonce', 'nonce');

        if (!is_user_logged_in()) {
            wp_send_json_error(array('message' => 'Not logged in'));
        }

        $user_id = get_current_user_id();
        $picks = get_user_meta($user_id, 'sv_pending_picks', true);

        if (empty($picks)) {
            wp_send_json_error(array('message' => 'No pending picks'));
        }

        $qualified_pools = $this->find_qualified_pools($user_id, $picks);

        wp_send_json_success(array(
            'qualified_pools' => $qualified_pools,
        ));
    }

    /**
     * Get user's picks for MY BETS tab
     * Cached for 1 minute for performance
     */
    public function get_user_picks() {
        global $wpdb;
        check_ajax_referer('sv_sportsbook_nonce', 'nonce');

        if (!is_user_logged_in()) {
            wp_send_json_error(array('message' => 'Must be logged in'));
        }

        $user_id = get_current_user_id();

        // Check cache first (1 minute cache)
        $cache_key = 'sv_user_picks_' . $user_id;
        $cached_picks = get_transient($cache_key);

        if ($cached_picks !== false) {
            wp_send_json_success(array(
                'picks' => $cached_picks,
                'from_cache' => true,
            ));
            return;
        }

        $table_name = $wpdb->prefix . 'sv_bet_slips';

        // Get all picks for this user, ordered by most recent first
        $picks = $wpdb->get_results(
            $wpdb->prepare(
                "SELECT * FROM $table_name WHERE user_id = %d ORDER BY bet_placed_at DESC LIMIT 50",
                $user_id
            ),
            ARRAY_A
        );

        if (!$picks) {
            $picks = array();
        }

        // Cache for 1 minute (60 seconds)
        set_transient($cache_key, $picks, 60);

        wp_send_json_success(array(
            'picks' => $picks,
            'from_cache' => false,
        ));
    }

    /**
     * Get user's weekly and monthly stats
     */
    public function get_user_stats() {
        check_ajax_referer('sv_sportsbook_nonce', 'nonce');

        if (!is_user_logged_in()) {
            error_log('Stats error: User not logged in');
            wp_send_json_error(array('message' => 'Must be logged in'));
        }

        $user_id = get_current_user_id();
        error_log('Loading stats for user: ' . $user_id);

        // Get main plugin instance to access stats methods
        global $sv_sportsbook_instance;
        if (!$sv_sportsbook_instance) {
            error_log('Stats error: Plugin instance not found');
            wp_send_json_error(array('message' => 'Plugin not initialized'));
        }

        // Get weekly and monthly stats
        $weekly_stats = $sv_sportsbook_instance->get_weekly_stats($user_id);
        $monthly_stats = $sv_sportsbook_instance->get_monthly_stats($user_id);

        error_log('Weekly stats: ' . print_r($weekly_stats, true));
        error_log('Monthly stats: ' . print_r($monthly_stats, true));

        wp_send_json_success(array(
            'weekly' => $weekly_stats,
            'monthly' => $monthly_stats,
        ));
    }

    /**
     * Delete a user's pick
     */
    public function delete_pick() {
        global $wpdb;
        check_ajax_referer('sv_sportsbook_nonce', 'nonce');

        if (!is_user_logged_in()) {
            wp_send_json_error(array('message' => 'Must be logged in'));
        }

        $user_id = get_current_user_id();
        $slip_id = isset($_POST['slip_id']) ? intval($_POST['slip_id']) : 0;

        if (empty($slip_id)) {
            wp_send_json_error(array('message' => 'Invalid slip ID'));
        }

        $table_name = $wpdb->prefix . 'sv_bet_slips';

        // Delete the pick (only if it belongs to this user and is still pending)
        $deleted = $wpdb->delete(
            $table_name,
            array(
                'id' => $slip_id,
                'user_id' => $user_id,
                'result' => 'pending', // Only allow deleting pending bets
            ),
            array('%d', '%d', '%s')
        );

        if ($deleted) {
            // Clear user picks cache
            delete_transient('sv_user_picks_' . $user_id);

            // Clear stats cache since deleting a pick might affect stats
            global $sv_sportsbook_instance;
            if ($sv_sportsbook_instance) {
                $sv_sportsbook_instance->clear_stats_cache($user_id);
            }

            wp_send_json_success(array(
                'message' => 'Pick deleted',
            ));
        } else {
            wp_send_json_error(array('message' => 'Pick not found or already graded'));
        }
    }

    /**
     * Load alternate lines for a specific game (on-demand)
     */
    public function load_alternate_lines() {
        check_ajax_referer('sv_sportsbook_nonce', 'nonce');

        $game_id = isset($_POST['game_id']) ? sanitize_text_field($_POST['game_id']) : '';
        $sport = isset($_POST['sport']) ? sanitize_text_field($_POST['sport']) : '';

        if (empty($game_id) || empty($sport)) {
            wp_send_json_error(array('message' => 'Missing game_id or sport'));
        }

        // Check if alternate lines are enabled
        if (!get_option('sv_enable_alternate_lines', true)) {
            wp_send_json_error(array('message' => 'Alternate lines are disabled'));
        }

        // Get fetcher
        $fetcher = new SV_Odds_API_Fetcher();

        // Fetch alternate lines for this game
        $alt_lines = $fetcher->fetch_event_alternate_lines($sport, $game_id);

        // Check for errors
        if (is_wp_error($alt_lines)) {
            wp_send_json_error(array(
                'message' => $alt_lines->get_error_message(),
            ));
        }

        // Return alternate lines
        wp_send_json_success(array(
            'alternate_spreads' => $alt_lines['alternate_spreads'] ?? [],
            'alternate_totals' => $alt_lines['alternate_totals'] ?? [],
        ));
    }

    /**
     * Load odds screen data (multi-bookmaker comparison)
     * Reads from server-side cache populated by cron job
     */
    public function load_odds_screen() {
        check_ajax_referer('sv_sportsbook_nonce', 'nonce');

        $sport = isset($_POST['sport']) ? sanitize_text_field($_POST['sport']) : 'all';

        // Check if auto-refresh is enabled
        $auto_refresh_enabled = get_option('sv_enable_odds_screen_auto_refresh', false);

        if ($auto_refresh_enabled) {
            // Get cached data from cron job
            $games = get_transient('sv_odds_screen_data');

            // If no cache, fetch immediately as fallback
            if ($games === false) {
                $fetcher = new SV_Odds_API_Fetcher();
                $games = $fetcher->fetch_all_sports_multi_book();

                if (!is_wp_error($games)) {
                    set_transient('sv_odds_screen_data', $games, 120);
                }
            }
        } else {
            // Auto-refresh disabled, fetch on-demand
            $fetcher = new SV_Odds_API_Fetcher();

            if ($sport === 'all') {
                $games = $fetcher->fetch_all_sports_multi_book();
            } else {
                $games = $fetcher->fetch_odds_multi_book($sport);
            }
        }

        // Check for errors
        if (is_wp_error($games)) {
            wp_send_json_error(array(
                'message' => $games->get_error_message(),
            ));
        }

        // Filter by sport if needed and not from cache
        if ($sport !== 'all' && is_array($games)) {
            $games = array_filter($games, function($game) use ($sport) {
                return isset($game['sport']) && $game['sport'] === $sport;
            });
            $games = array_values($games); // Re-index
        }

        // Note: API only returns upcoming games (commenceTimeFrom parameter)
        // No filtering needed here

        // Get API usage stats
        $api_remaining = get_option('sv_api_requests_remaining', '--');
        $api_used = get_option('sv_api_requests_used', '--');
        $last_update = get_option('sv_odds_screen_last_update', '--');

        // Return games with multi-bookmaker data
        wp_send_json_success(array(
            'games' => $games,
            'count' => count($games),
            'api_remaining' => $api_remaining,
            'api_used' => $api_used,
            'auto_refresh_enabled' => $auto_refresh_enabled,
            'last_server_update' => $last_update,
            'data_source' => $auto_refresh_enabled ? 'server_cache' : 'on_demand',
        ));
    }
}

// Initialize
new SV_Sportsbook_AJAX();
