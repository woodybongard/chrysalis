<?php
/**
 * Odds API Fetcher
 *
 * Fetches odds and scores from The Odds API
 * Handles caching to stay within free tier limits (500 requests/month)
 *
 * @package SportsVestment_Sportsbook
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

class SV_Odds_API_Fetcher {

    /**
     * API Configuration
     */
    private $api_key;
    private $base_url = 'https://api.the-odds-api.com/v4';

    /**
     * Sport mappings (internal key => Odds API key)
     */
    private $sports = [
        'nba' => 'basketball_nba',
        'nfl' => 'americanfootball_nfl',
        'mlb' => 'baseball_mlb',
        'nhl' => 'icehockey_nhl',
        'ncaab' => 'basketball_ncaab',
        'soccer_epl' => 'soccer_epl',
        'soccer_uefa_champs_league' => 'soccer_uefa_champs_league',
        'tennis_atp' => 'tennis_atp',
        'tennis_wta' => 'tennis_wta',
        'mma' => 'mma_mixed_martial_arts',
    ];

    /**
     * Bookmakers to fetch for comparison
     */
    private $bookmakers = [
        'draftkings',
        'fanduel',
        'betmgm',
        'caesars',
        'pointsbetus',
        'wynnbet',
    ];

    /**
     * Get cache duration from settings
     */
    private function get_cache_duration() {
        return intval(get_option('sv_odds_refresh_interval', 1800)); // Default 30 minutes
    }

    /**
     * Constructor
     */
    public function __construct() {
        $this->api_key = get_option('sv_odds_api_key', '');

        // If no key in options, use the provided one
        if (empty($this->api_key)) {
            $this->api_key = 'fcd160fe184fb68bc30eafed42746d8d';
        }
    }

    /**
     * Fetch odds for a specific sport
     *
     * @param string $sport Sport key (nba, nfl, mlb, nhl)
     * @param bool $force_refresh Force API call (skip cache)
     * @return array|WP_Error Games with odds
     */
    public function fetch_odds($sport = 'nba', $force_refresh = false) {

        // Check cache first
        if (!$force_refresh) {
            $cached = $this->get_from_cache($sport, 'odds');
            if ($cached !== false) {
                return $cached;
            }
        }

        // Get sport key
        $sport_key = $this->get_sport_key($sport);
        if (!$sport_key) {
            return new WP_Error('invalid_sport', 'Invalid sport specified');
        }

        // Build API URL
        $url = sprintf(
            '%s/sports/%s/odds/',
            $this->base_url,
            $sport_key
        );

        // Add parameters - only fetch upcoming games
        $params = [
            'apiKey' => $this->api_key,
            'regions' => 'us',
            'markets' => 'h2h,spreads,totals',
            'oddsFormat' => 'american',
            'dateFormat' => 'iso',
            'commenceTimeFrom' => gmdate('Y-m-d\TH:i:s\Z'), // Only games starting from now
        ];

        $url .= '?' . http_build_query($params);

        // Make API request
        $response = wp_remote_get($url, [
            'timeout' => 15,
        ]);

        // Check for errors
        if (is_wp_error($response)) {
            return $response;
        }

        $status_code = wp_remote_retrieve_response_code($response);
        if ($status_code !== 200) {
            return new WP_Error(
                'api_error',
                sprintf('API returned status %d', $status_code)
            );
        }

        // Parse response
        $body = wp_remote_retrieve_body($response);
        $data = json_decode($body, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            return new WP_Error('parse_error', 'Failed to parse API response');
        }

        // Capture API usage stats from headers
        $headers = wp_remote_retrieve_headers($response);
        if (isset($headers['x-requests-remaining'])) {
            update_option('sv_api_requests_remaining', $headers['x-requests-remaining']);
        }
        if (isset($headers['x-requests-used'])) {
            update_option('sv_api_requests_used', $headers['x-requests-used']);
        }

        // Process games
        $games = $this->process_odds_response($data, $sport);

        // Cache the results
        $this->save_to_cache($sport, 'odds', $games);

        // Log API usage
        $this->log_api_request($sport, 'odds');

        return $games;
    }

    /**
     * Fetch odds from multiple bookmakers for comparison
     *
     * @param string $sport Sport key
     * @param bool $force_refresh Force API call
     * @return array|WP_Error Games with bookmaker odds
     */
    public function fetch_odds_multi_book($sport = 'nba', $force_refresh = false) {
        // Check cache first
        if (!$force_refresh) {
            $cached = $this->get_from_cache($sport, 'odds_multi_book');
            if ($cached !== false) {
                return $cached;
            }
        }

        // Get sport key
        $sport_key = $this->get_sport_key($sport);
        if (!$sport_key) {
            return new WP_Error('invalid_sport', 'Invalid sport specified');
        }

        // Build API URL with specific bookmakers
        $url = sprintf(
            '%s/sports/%s/odds/',
            $this->base_url,
            $sport_key
        );

        // Add parameters including bookmakers - only fetch upcoming games
        $params = [
            'apiKey' => $this->api_key,
            'regions' => 'us',
            'markets' => 'h2h,spreads,totals',
            'oddsFormat' => 'american',
            'dateFormat' => 'iso',
            'bookmakers' => implode(',', $this->bookmakers),
            'commenceTimeFrom' => gmdate('Y-m-d\TH:i:s\Z'), // Only games starting from now
        ];

        $url .= '?' . http_build_query($params);

        // Make API request
        $response = wp_remote_get($url, [
            'timeout' => 15,
        ]);

        // Check for errors
        if (is_wp_error($response)) {
            return $response;
        }

        $status_code = wp_remote_retrieve_response_code($response);
        if ($status_code !== 200) {
            return new WP_Error(
                'api_error',
                sprintf('API returned status %d', $status_code)
            );
        }

        // Parse response
        $body = wp_remote_retrieve_body($response);
        $data = json_decode($body, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            return new WP_Error('parse_error', 'Failed to parse API response');
        }

        // Capture API usage stats
        $headers = wp_remote_retrieve_headers($response);
        if (isset($headers['x-requests-remaining'])) {
            update_option('sv_api_requests_remaining', $headers['x-requests-remaining']);
        }
        if (isset($headers['x-requests-used'])) {
            update_option('sv_api_requests_used', $headers['x-requests-used']);
        }

        // Process games with bookmaker data
        $games = $this->process_multi_book_response($data, $sport);

        // Cache the results
        $this->save_to_cache($sport, 'odds_multi_book', $games);

        // Log API usage
        $this->log_api_request($sport, 'odds_multi_book');

        return $games;
    }

    /**
     * Fetch scores for a specific sport
     *
     * @param string $sport Sport key
     * @param bool $force_refresh Force API call
     * @return array|WP_Error Games with scores
     */
    public function fetch_scores($sport = 'nba', $force_refresh = false) {

        // Check cache
        if (!$force_refresh) {
            $cached = $this->get_from_cache($sport, 'scores');
            if ($cached !== false) {
                return $cached;
            }
        }

        $sport_key = $this->get_sport_key($sport);
        if (!$sport_key) {
            return new WP_Error('invalid_sport', 'Invalid sport specified');
        }

        // Build URL
        $url = sprintf(
            '%s/sports/%s/scores/',
            $this->base_url,
            $sport_key
        );

        $params = [
            'apiKey' => $this->api_key,
            'daysFrom' => 1,
            'dateFormat' => 'iso',
        ];

        $url .= '?' . http_build_query($params);

        // Make request
        $response = wp_remote_get($url, ['timeout' => 15]);

        if (is_wp_error($response)) {
            return $response;
        }

        $status_code = wp_remote_retrieve_response_code($response);
        if ($status_code !== 200) {
            return new WP_Error('api_error', sprintf('API returned status %d', $status_code));
        }

        $body = wp_remote_retrieve_body($response);
        $data = json_decode($body, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            return new WP_Error('parse_error', 'Failed to parse scores response');
        }

        // Process scores
        $games = $this->process_scores_response($data, $sport);

        // Cache
        $this->save_to_cache($sport, 'scores', $games);
        $this->log_api_request($sport, 'scores');

        return $games;
    }

    /**
     * Fetch all sports at once (only enabled sports)
     *
     * @return array All games across all enabled sports
     */
    public function fetch_all_sports() {
        $all_games = [];

        // Get enabled sports from settings
        $enabled_sports = get_option('sv_enabled_sports', array(
            'basketball_nba' => true,
            'americanfootball_nfl' => true,
        ));

        // Map enabled sport keys to our internal keys
        $sport_key_map = array(
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

        foreach ($enabled_sports as $sport_option_key => $enabled) {
            if (!$enabled) {
                continue;
            }

            // Get the internal sport key
            $sport = isset($sport_key_map[$sport_option_key]) ? $sport_key_map[$sport_option_key] : null;

            if ($sport && isset($this->sports[$sport])) {
                $games = $this->fetch_odds($sport);

                if (!is_wp_error($games)) {
                    $all_games = array_merge($all_games, $games);
                }
            }
        }

        // Fetch alternate lines if enabled
        if (get_option('sv_enable_alternate_lines', true)) {
            $all_games = $this->fetch_alternate_lines_batch($all_games);
        }

        return $all_games;
    }

    /**
     * Fetch all enabled sports with multi-bookmaker data
     */
    public function fetch_all_sports_multi_book() {
        $all_games = [];

        // Get enabled sports from settings
        $enabled_sports = get_option('sv_enabled_sports', array(
            'basketball_nba' => true,
            'americanfootball_nfl' => true,
        ));

        // Map enabled sport keys to our internal keys
        $sport_key_map = array(
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

        foreach ($enabled_sports as $sport_option_key => $enabled) {
            if (!$enabled) {
                continue;
            }

            // Get the internal sport key
            $sport = isset($sport_key_map[$sport_option_key]) ? $sport_key_map[$sport_option_key] : null;

            if ($sport && isset($this->sports[$sport])) {
                $games = $this->fetch_odds_multi_book($sport);

                if (!is_wp_error($games)) {
                    $all_games = array_merge($all_games, $games);
                }
            }
        }

        return $all_games;
    }

    /**
     * Fetch alternate lines for multiple events
     *
     * @param array $games Games with basic odds
     * @return array Games with alternate lines added
     */
    private function fetch_alternate_lines_batch($games) {
        error_log('Fetching alternate lines for ' . count($games) . ' games');

        foreach ($games as &$game) {
            $alt_lines = $this->fetch_event_alternate_lines($game['sport'], $game['id']);

            if (is_wp_error($alt_lines)) {
                error_log('Error fetching alt lines for game ' . $game['id'] . ': ' . $alt_lines->get_error_message());
            } else if (!empty($alt_lines)) {
                $game['alternate_spreads'] = $alt_lines['alternate_spreads'] ?? [];
                $game['alternate_totals'] = $alt_lines['alternate_totals'] ?? [];
                error_log('Added alt lines to game ' . $game['id'] . ' - spreads: ' . count($game['alternate_spreads']) . ', totals: ' . count($game['alternate_totals']));
            }
        }

        return $games;
    }

    /**
     * Fetch alternate lines for a specific event
     *
     * @param string $sport Sport key
     * @param string $event_id Event ID
     * @return array|WP_Error Alternate lines data
     */
    public function fetch_event_alternate_lines($sport, $event_id) {
        // Check cache first
        $cache_key = "sv_alt_lines_{$event_id}";
        $cached = get_transient($cache_key);
        if ($cached !== false) {
            return $cached;
        }

        // Get sport key
        $sport_key = $this->get_sport_key($sport);
        if (!$sport_key) {
            return new WP_Error('invalid_sport', 'Invalid sport specified');
        }

        // Build API URL for specific event
        $url = sprintf(
            '%s/sports/%s/events/%s/odds/',
            $this->base_url,
            $sport_key,
            $event_id
        );

        // Add parameters for alternate lines
        $params = [
            'apiKey' => $this->api_key,
            'regions' => 'us',
            'markets' => 'alternate_spreads,alternate_totals',
            'oddsFormat' => 'american',
            'dateFormat' => 'iso',
        ];

        $url .= '?' . http_build_query($params);

        // Make API request
        $response = wp_remote_get($url, ['timeout' => 15]);

        // Check for errors
        if (is_wp_error($response)) {
            return $response;
        }

        $status_code = wp_remote_retrieve_response_code($response);
        if ($status_code !== 200) {
            return new WP_Error('api_error', sprintf('API returned status %d', $status_code));
        }

        // Parse response
        $body = wp_remote_retrieve_body($response);
        $data = json_decode($body, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            return new WP_Error('parse_error', 'Failed to parse API response');
        }

        // Process alternate lines
        $alt_lines = $this->process_alternate_lines($data);

        // Cache the results
        set_transient($cache_key, $alt_lines, $this->get_cache_duration());

        // Log API usage
        $this->log_api_request($sport, 'alternate_lines');

        return $alt_lines;
    }

    /**
     * Process odds API response
     *
     * @param array $data Raw API response
     * @param string $sport Sport key
     * @return array Processed games
     */
    private function process_odds_response($data, $sport) {
        $games = [];

        foreach ($data as $event) {
            // Extract basic game info
            $game = [
                'id' => $event['id'],
                'sport' => $sport,
                'sport_key' => $event['sport_key'] ?? '',
                'home_team' => $event['home_team'],
                'away_team' => $event['away_team'],
                'commence_time' => $event['commence_time'],
                'completed' => $event['completed'] ?? false,
            ];

            // Extract odds from first bookmaker (we'll make this configurable later)
            if (!empty($event['bookmakers'])) {
                $bookmaker = $event['bookmakers'][0]; // Use first available
                $game['bookmaker'] = $bookmaker['title'];

                // Extract markets
                foreach ($bookmaker['markets'] as $market) {
                    switch ($market['key']) {
                        case 'h2h': // Moneyline
                            $game['moneyline'] = $this->extract_moneyline($market, $game);
                            break;

                        case 'spreads':
                            $game['spread'] = $this->extract_spreads($market, $game);
                            break;

                        case 'totals':
                            $game['total'] = $this->extract_totals($market);
                            break;
                    }
                }
            }

            $games[] = $game;
        }

        return $games;
    }

    /**
     * Process odds response with multiple bookmakers
     */
    private function process_multi_book_response($data, $sport) {
        $games = [];

        foreach ($data as $event) {
            // Extract basic game info
            $game = [
                'id' => $event['id'],
                'sport' => $sport,
                'sport_key' => $event['sport_key'] ?? '',
                'home_team' => $event['home_team'],
                'away_team' => $event['away_team'],
                'commence_time' => $event['commence_time'],
                'completed' => $event['completed'] ?? false,
                'bookmakers' => [],
            ];

            // Extract odds from ALL bookmakers
            if (!empty($event['bookmakers'])) {
                foreach ($event['bookmakers'] as $bookmaker) {
                    $book_key = $bookmaker['key'];
                    $book_data = [
                        'key' => $book_key,
                        'title' => $bookmaker['title'],
                        'moneyline' => null,
                        'spread' => null,
                        'total' => null,
                    ];

                    // Extract markets for this bookmaker
                    foreach ($bookmaker['markets'] as $market) {
                        switch ($market['key']) {
                            case 'h2h': // Moneyline
                                $book_data['moneyline'] = $this->extract_moneyline($market, $game);
                                break;

                            case 'spreads':
                                $book_data['spread'] = $this->extract_spreads($market, $game);
                                break;

                            case 'totals':
                                $book_data['total'] = $this->extract_totals($market);
                                break;
                        }
                    }

                    $game['bookmakers'][$book_key] = $book_data;
                }
            }

            $games[] = $game;
        }

        return $games;
    }

    /**
     * Extract moneyline odds
     */
    private function extract_moneyline($market, $game) {
        $moneyline = [];

        foreach ($market['outcomes'] as $outcome) {
            if ($outcome['name'] === $game['home_team']) {
                $moneyline['home'] = $outcome['price'];
            } else if ($outcome['name'] === $game['away_team']) {
                $moneyline['away'] = $outcome['price'];
            }
        }

        return $moneyline;
    }

    /**
     * Extract spread odds
     */
    private function extract_spreads($market, $game) {
        $spread = [];

        foreach ($market['outcomes'] as $outcome) {
            if ($outcome['name'] === $game['home_team']) {
                $spread['home'] = [
                    'point' => $outcome['point'],
                    'price' => $outcome['price'],
                ];
            } else if ($outcome['name'] === $game['away_team']) {
                $spread['away'] = [
                    'point' => $outcome['point'],
                    'price' => $outcome['price'],
                ];
            }
        }

        return $spread;
    }

    /**
     * Extract totals (over/under)
     */
    private function extract_totals($market) {
        $total = [];

        foreach ($market['outcomes'] as $outcome) {
            if ($outcome['name'] === 'Over') {
                $total['over'] = [
                    'point' => $outcome['point'],
                    'price' => $outcome['price'],
                ];
            } else if ($outcome['name'] === 'Under') {
                $total['under'] = [
                    'point' => $outcome['point'],
                    'price' => $outcome['price'],
                ];
            }
        }

        return $total;
    }

    /**
     * Process alternate lines API response
     *
     * @param array $data Raw API response for event
     * @return array Processed alternate lines
     */
    private function process_alternate_lines($data) {
        $alt_lines = [
            'alternate_spreads' => [],
            'alternate_totals' => [],
        ];

        if (empty($data['bookmakers'])) {
            return $alt_lines;
        }

        // Use first bookmaker
        $bookmaker = $data['bookmakers'][0];

        foreach ($bookmaker['markets'] as $market) {
            switch ($market['key']) {
                case 'alternate_spreads':
                    $alt_lines['alternate_spreads'] = $this->extract_alternate_spreads($market, $data);
                    break;

                case 'alternate_totals':
                    $alt_lines['alternate_totals'] = $this->extract_alternate_totals($market);
                    break;
            }
        }

        return $alt_lines;
    }

    /**
     * Extract alternate spreads
     */
    private function extract_alternate_spreads($market, $event_data) {
        $spreads = [];
        $home_team = $event_data['home_team'];
        $away_team = $event_data['away_team'];

        // Group by point value - use string keys to preserve decimals
        $home_spreads = [];
        $away_spreads = [];

        foreach ($market['outcomes'] as $outcome) {
            // Keep as float, don't convert to int
            $point = floatval($outcome['point']);
            $price = $outcome['price'];

            // Use string representation as key to avoid float precision issues
            $key = (string)$point;

            if ($outcome['name'] === $home_team) {
                $home_spreads[$key] = ['point' => $point, 'price' => $price];
            } else if ($outcome['name'] === $away_team) {
                $away_spreads[$key] = ['point' => $point, 'price' => $price];
            }
        }

        // Pair them up
        foreach ($home_spreads as $key => $home_data) {
            $home_point = $home_data['point'];
            $away_point = -$home_point;
            $away_key = (string)$away_point;

            if (isset($away_spreads[$away_key])) {
                $spreads[] = [
                    'home' => [
                        'point' => $home_point,
                        'price' => $home_data['price'],
                    ],
                    'away' => [
                        'point' => $away_point,
                        'price' => $away_spreads[$away_key]['price'],
                    ],
                ];
            }
        }

        return $spreads;
    }

    /**
     * Extract alternate totals
     */
    private function extract_alternate_totals($market) {
        $totals = [];

        // Group by point value - use string keys to preserve decimals
        $overs = [];
        $unders = [];

        foreach ($market['outcomes'] as $outcome) {
            // Keep as float, don't convert to int
            $point = floatval($outcome['point']);
            $price = $outcome['price'];

            // Use string representation as key to avoid float precision issues
            $key = (string)$point;

            if ($outcome['name'] === 'Over') {
                $overs[$key] = ['point' => $point, 'price' => $price];
            } else if ($outcome['name'] === 'Under') {
                $unders[$key] = ['point' => $point, 'price' => $price];
            }
        }

        // Pair them up
        foreach ($overs as $key => $over_data) {
            if (isset($unders[$key])) {
                $totals[] = [
                    'point' => $over_data['point'],
                    'over' => [
                        'point' => $over_data['point'],
                        'price' => $over_data['price'],
                    ],
                    'under' => [
                        'point' => $unders[$key]['point'],
                        'price' => $unders[$key]['price'],
                    ],
                ];
            }
        }

        return $totals;
    }

    /**
     * Process scores API response
     */
    private function process_scores_response($data, $sport) {
        $games = [];

        foreach ($data as $event) {
            $games[] = [
                'id' => $event['id'],
                'sport' => $sport,
                'home_team' => $event['home_team'],
                'away_team' => $event['away_team'],
                'commence_time' => $event['commence_time'],
                'completed' => $event['completed'],
                'scores' => $event['scores'] ?? null,
            ];
        }

        return $games;
    }

    /**
     * Get sport API key
     */
    private function get_sport_key($sport) {
        return $this->sports[$sport] ?? false;
    }

    /**
     * Cache management
     */
    private function get_from_cache($sport, $type) {
        $cache_key = "sv_odds_{$sport}_{$type}";
        return get_transient($cache_key);
    }

    private function save_to_cache($sport, $type, $data) {
        $cache_key = "sv_odds_{$sport}_{$type}";
        $duration = $this->get_cache_duration();
        set_transient($cache_key, $data, $duration);
    }

    /**
     * Log API requests (to track free tier usage)
     */
    private function log_api_request($sport, $type) {
        $log = get_option('sv_odds_api_log', []);

        $log[] = [
            'sport' => $sport,
            'type' => $type,
            'timestamp' => current_time('mysql'),
        ];

        // Keep only last 100 requests
        if (count($log) > 100) {
            $log = array_slice($log, -100);
        }

        update_option('sv_odds_api_log', $log);
    }

    /**
     * Get API usage stats
     */
    public function get_usage_stats() {
        $log = get_option('sv_odds_api_log', []);

        // Count requests in last 30 days
        $thirty_days_ago = strtotime('-30 days');
        $recent_requests = array_filter($log, function($entry) use ($thirty_days_ago) {
            return strtotime($entry['timestamp']) > $thirty_days_ago;
        });

        return [
            'total_requests' => count($log),
            'last_30_days' => count($recent_requests),
            'free_tier_limit' => 500,
            'remaining' => max(0, 500 - count($recent_requests)),
        ];
    }
}
