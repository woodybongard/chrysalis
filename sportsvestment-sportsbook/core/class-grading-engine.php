<?php
/**
 * Grading Engine
 *
 * Automatically grades bets when games complete
 *
 * @package SportsVestment_Sportsbook
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

class SV_Grading_Engine {

    /**
     * Grade all pending bets
     *
     * @return array Results summary
     */
    public function grade_pending_bets() {
        global $wpdb;

        $table_name = $wpdb->prefix . 'sv_bet_slips';

        // Get all pending bets
        $pending_bets = $wpdb->get_results(
            "SELECT * FROM $table_name WHERE result = 'pending' ORDER BY event_date ASC",
            ARRAY_A
        );

        if (empty($pending_bets)) {
            return array(
                'graded' => 0,
                'message' => 'No pending bets to grade'
            );
        }

        error_log('Grading: Found ' . count($pending_bets) . ' pending bets');

        // Group bets by sport for efficient API calls
        $bets_by_sport = array();
        foreach ($pending_bets as $bet) {
            $sport = $bet['sport'];
            if (!isset($bets_by_sport[$sport])) {
                $bets_by_sport[$sport] = array();
            }
            $bets_by_sport[$sport][] = $bet;
        }

        // Fetch scores for each sport and grade bets
        $fetcher = new SV_Odds_API_Fetcher();
        $graded_count = 0;

        foreach ($bets_by_sport as $sport => $bets) {
            // Skip invalid sports (like 'all' from old bug)
            if ($sport === 'all' || empty($sport)) {
                error_log('Grading: Skipping ' . count($bets) . ' bets with invalid sport "' . $sport . '" - these bets cannot be graded');
                continue;
            }

            error_log('Grading: Checking ' . count($bets) . ' ' . $sport . ' bets');

            // Fetch scores for this sport (one API call per sport)
            $scores = $fetcher->fetch_scores($sport);

            if (is_wp_error($scores)) {
                error_log('Grading error for ' . $sport . ': ' . $scores->get_error_message());
                continue;
            }

            error_log('Grading: Got ' . count($scores) . ' games from scores API for ' . $sport);

            // Grade each bet against the scores
            foreach ($bets as $bet) {
                error_log('Grading: Looking for game_id ' . $bet['game_id'] . ' for bet #' . $bet['id']);

                $game = $this->find_game_by_id($scores, $bet['game_id']);

                if ($game) {
                    error_log('Grading: Found game. Completed: ' . ($game['completed'] ? 'YES' : 'NO'));
                } else {
                    error_log('Grading: Game not found in scores API');
                }

                // Only grade if game is completed
                if ($game && isset($game['completed']) && $game['completed'] === true) {
                    $result = $this->grade_bet($bet, $game);

                    if ($result) {
                        error_log('Grading: Bet #' . $bet['id'] . ' result: ' . $result['result']);
                        $this->update_bet_result($bet['id'], $result, $bet['user_id']);
                        $graded_count++;
                    }
                }
            }
        }

        return array(
            'graded' => $graded_count,
            'message' => sprintf('Graded %d bets', $graded_count)
        );
    }

    /**
     * Find game in scores array by game_id
     */
    private function find_game_by_id($games, $game_id) {
        foreach ($games as $game) {
            if ($game['id'] === $game_id) {
                return $game;
            }
        }
        return null;
    }

    /**
     * Grade a single bet
     *
     * @param array $bet Bet record
     * @param array $game Game with scores
     * @return array|null Grade result (result, away_score, home_score, payout)
     */
    private function grade_bet($bet, $game) {
        if (!isset($game['scores']) || empty($game['scores'])) {
            return null; // No scores available
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

        // Grade based on pick type
        $result = 'pending';

        switch ($bet['pick_type']) {
            case 'moneyline':
                $result = $this->grade_moneyline($bet, $away_score, $home_score);
                break;

            case 'spread':
                $result = $this->grade_spread($bet, $away_score, $home_score);
                break;

            case 'total':
                $result = $this->grade_total($bet, $away_score, $home_score);
                break;
        }

        // Calculate payout
        $payout = $this->calculate_payout($bet['units'], $bet['odds'], $result);

        return array(
            'result' => $result,
            'away_score' => $away_score,
            'home_score' => $home_score,
            'payout' => $payout,
        );
    }

    /**
     * Grade moneyline bet
     */
    private function grade_moneyline($bet, $away_score, $home_score) {
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
     * Grade spread bet
     */
    private function grade_spread($bet, $away_score, $home_score) {
        $selection = $bet['selection'];
        $away_team = $bet['away_team'];
        $home_team = $bet['home_team'];

        // Parse spread from selection (e.g., "Lakers -5.5" or "Lakers +20.5")
        // Look for +/- sign followed by number (not optional - spreads always have a sign)
        preg_match('/([+-]\d+\.?\d*)/', $selection, $matches);
        if (empty($matches)) {
            error_log('Grading: Cannot parse spread from selection: ' . $selection);
            return 'pending'; // Can't parse spread
        }

        $spread = floatval($matches[1]);

        // Determine which team user picked
        if (strpos($selection, $away_team) !== false) {
            // User picked away team
            $adjusted_score = $away_score + $spread;
            error_log(sprintf('Grading spread: %s with %+.1f | Away: %d + %.1f = %.1f vs Home: %d | Result: %s',
                $away_team, $spread, $away_score, $spread, $adjusted_score, $home_score,
                ($adjusted_score > $home_score ? 'WON' : ($adjusted_score < $home_score ? 'LOST' : 'PUSH'))
            ));
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
            error_log(sprintf('Grading spread: %s with %+.1f | Home: %d + %.1f = %.1f vs Away: %d | Result: %s',
                $home_team, $spread, $home_score, $spread, $adjusted_score, $away_score,
                ($adjusted_score > $away_score ? 'WON' : ($adjusted_score < $away_score ? 'LOST' : 'PUSH'))
            ));
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
     * Grade total (over/under) bet
     */
    private function grade_total($bet, $away_score, $home_score) {
        $selection = $bet['selection'];
        $total_score = $away_score + $home_score;

        // Parse total from selection (e.g., "Over 215.5" or "O 215.5")
        preg_match('/(\d+\.?\d*)/', $selection, $matches);
        if (empty($matches)) {
            error_log('Grading: Cannot parse total from selection: ' . $selection);
            return 'pending'; // Can't parse total
        }

        $line = floatval($matches[1]);

        // Check if over or under (handle both "Over" and "O", "Under" and "U")
        $is_over = (stripos($selection, 'over') !== false || stripos($selection, 'O ') !== false || strpos($selection, 'O') === 0);

        error_log(sprintf('Grading total: "%s" (detected as %s) | Total score: %d vs Line: %.1f | Result: %s',
            $selection, ($is_over ? 'OVER' : 'UNDER'), $total_score, $line,
            ($is_over ?
                ($total_score > $line ? 'WON' : ($total_score < $line ? 'LOST' : 'PUSH')) :
                ($total_score < $line ? 'WON' : ($total_score > $line ? 'LOST' : 'PUSH'))
            )
        ));

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
     *
     * @param float $units Units wagered
     * @param string $odds American odds (e.g., "-110", "+150")
     * @param string $result won/lost/push
     * @return float Payout amount
     */
    private function calculate_payout($units, $odds, $result) {
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
     * Update bet result in database
     */
    private function update_bet_result($bet_id, $result_data, $user_id) {
        global $wpdb;

        $table_name = $wpdb->prefix . 'sv_bet_slips';

        $updated = $wpdb->update(
            $table_name,
            array(
                'result' => $result_data['result'],
                'away_score' => $result_data['away_score'],
                'home_score' => $result_data['home_score'],
                'payout' => $result_data['payout'],
                'bet_graded_at' => current_time('mysql', true),
            ),
            array('id' => $bet_id),
            array('%s', '%d', '%d', '%f', '%s'),
            array('%d')
        );

        if ($updated === false) {
            error_log('Failed to update bet #' . $bet_id);
        } else {
            // Clear user caches after grading
            delete_transient('sv_user_picks_' . $user_id);

            global $sv_sportsbook_instance;
            if ($sv_sportsbook_instance) {
                $sv_sportsbook_instance->clear_stats_cache($user_id);
            }
        }
    }
}
