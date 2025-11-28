/**
 * SportsVestment Sportsbook JavaScript - FAST VERSION
 *
 * Instant picks, no clunk
 */

(function($) {
    'use strict';

    // State
    let games = [];
    let currentSport = 'all';
    let userPicks = [];
    let searchTerm = '';
    let selectedTimezone = localStorage.getItem('sv_timezone') || 'America/New_York';
    let currentTab = 'games';

    // Cache for loaded tabs (lazy loading)
    let tabsLoaded = {
        'games': true,  // Always load games tab initially
        'my-bets': false,
        'odds-screen': false,
        'leaderboard': false
    };

    /**
     * Debounce utility function
     * Delays function execution until after user stops typing
     */
    function debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    /**
     * Initialize
     */
    $(document).ready(function() {
        initTabs();
        initSportPills();
        initSearch();
        initTimezone();

        // Only load games tab initially (lazy load others)
        loadGames('all');

        // Don't load picks/stats until user switches to MY PLAYS tab
        // This saves database queries on initial page load
    });

    /**
     * Tab switching with lazy loading
     */
    function initTabs() {
        $('.sv-tab').on('click', function() {
            const tabName = $(this).data('tab');
            currentTab = tabName;

            $('.sv-tab').removeClass('active');
            $(this).addClass('active');
            $('.sv-tab-content').removeClass('active');
            $('#tab-' + tabName).addClass('active');

            // Lazy load tab data only when first accessed
            if (tabName === 'my-bets' && !tabsLoaded['my-bets']) {
                loadUserPicks();
                loadUserStats();
                tabsLoaded['my-bets'] = true;
            } else if (tabName === 'my-bets') {
                // Refresh data if tab already loaded
                loadUserPicks();
                loadUserStats();
            }

            // Load odds screen (server-side cron keeps it fresh)
            if (tabName === 'odds-screen' && !tabsLoaded['odds-screen']) {
                loadOddsScreen(currentSport);
                tabsLoaded['odds-screen'] = true;
            } else if (tabName === 'odds-screen') {
                // Refresh odds if already loaded
                loadOddsScreen(currentSport);
            }
        });
    }

    /**
     * Sport pills
     */
    function initSportPills() {
        $('.sv-sport-pill').on('click', function() {
            const sport = $(this).data('sport');
            $('.sv-sport-pill').removeClass('active');
            $(this).addClass('active');
            currentSport = sport;

            // Load appropriate tab
            if (currentTab === 'odds-screen') {
                loadOddsScreen(sport);
            } else {
                loadGames(sport);
            }
        });
    }

    /**
     * Search functionality with debouncing
     */
    function initSearch() {
        const $searchInput = $('#sv-team-search');
        const $clearBtn = $('#sv-clear-search');

        console.log('Search initialized, input found:', $searchInput.length);

        // Debounced filter function (300ms delay after user stops typing)
        const debouncedFilter = debounce(function() {
            console.log('Filtering with term:', searchTerm);
            filterGames();
        }, 300);

        // Handle search input - debounced for performance
        $searchInput.on('input keyup', function() {
            searchTerm = $(this).val().toLowerCase().trim();

            if (searchTerm) {
                $clearBtn.show();
            } else {
                $clearBtn.hide();
            }

            // Use debounced filter to avoid filtering on every keystroke
            debouncedFilter();
        });

        // Handle clear button
        $clearBtn.on('click', function() {
            $searchInput.val('');
            searchTerm = '';
            $(this).hide();
            $searchInput.focus();
            filterGames();
        });

        // Handle enter key
        $searchInput.on('keypress', function(e) {
            if (e.which === 13) {
                e.preventDefault();
            }
        });
    }

    /**
     * Timezone selector
     */
    function initTimezone() {
        const $timezoneSelect = $('#sv-timezone');

        // Set the saved timezone
        $timezoneSelect.val(selectedTimezone);

        // Handle timezone change
        $timezoneSelect.on('change', function() {
            selectedTimezone = $(this).val();
            localStorage.setItem('sv_timezone', selectedTimezone);

            // Re-render games with new timezone
            if (games.length > 0) {
                if (searchTerm) {
                    filterGames();
                } else {
                    renderGames(games);
                }
            }

            // Re-render My Bets if on that tab
            if ($('#tab-my-bets').hasClass('active') && userPicks.length > 0) {
                renderMyBets();
            }
        });
    }

    /**
     * Filter games based on search term
     */
    function filterGames() {
        console.log('Filtering games, total games:', games.length, 'search term:', searchTerm);

        if (!searchTerm || searchTerm === '') {
            // No search term, show all games
            console.log('No search term, showing all games');
            renderGames(games);
            return;
        }

        if (games.length === 0) {
            console.log('No games loaded yet');
            return;
        }

        // Filter games by team name
        const filtered = games.filter(game => {
            const awayTeam = (game.away_team || '').toLowerCase();
            const homeTeam = (game.home_team || '').toLowerCase();
            const matches = awayTeam.includes(searchTerm) || homeTeam.includes(searchTerm);
            if (matches) {
                console.log('Match found:', game.away_team, 'vs', game.home_team);
            }
            return matches;
        });

        console.log('Filtered results:', filtered.length);

        if (filtered.length === 0) {
            $('.sv-games-grid').html('<div class="sv-empty">No teams found matching "' + searchTerm + '"</div>');
        } else {
            renderGames(filtered);
        }
    }

    /**
     * Load odds screen (multi-bookmaker comparison)
     * Data is kept fresh by server-side cron job when auto-refresh is enabled
     */
    function loadOddsScreen(sport) {
        const $grid = $('.sv-odds-grid');
        const $refreshIndicator = $('#sv-refresh-indicator');

        // Show refresh animation
        $refreshIndicator.addClass('spinning');

        $.ajax({
            url: svSportsbook.ajaxUrl,
            method: 'POST',
            data: {
                action: 'sv_load_odds_screen',
                nonce: svSportsbook.nonce,
                sport: sport || 'all',
            },
            success: function(response) {
                $refreshIndicator.removeClass('spinning');

                if (response.success) {
                    games = response.data.games;

                    // Update API usage counter and server update time
                    $('#sv-api-remaining').text(response.data.api_remaining);

                    if (response.data.last_server_update && response.data.last_server_update !== '--') {
                        const updateDate = new Date(response.data.last_server_update);
                        $('#sv-last-update-time').text(updateDate.toLocaleTimeString());
                    } else {
                        $('#sv-last-update-time').text(new Date().toLocaleTimeString());
                    }

                    // Show data source in console for debugging
                    if (response.data.data_source) {
                        console.log('Odds data source:', response.data.data_source);
                    }

                    // Render odds comparison
                    renderOddsScreen(games);
                } else {
                    $grid.html('<div class="sv-error">Error: ' + response.data.message + '</div>');
                }
            },
            error: function() {
                $refreshIndicator.removeClass('spinning');
                $grid.html('<div class="sv-error">Network error. Please refresh.</div>');
            }
        });
    }

    /**
     * Render odds screen (multi-bookmaker comparison view)
     */
    function renderOddsScreen(gamesList) {
        const $grid = $('.sv-odds-grid');

        if (!gamesList || gamesList.length === 0) {
            $grid.html('<div class="sv-empty">No games available right now.</div>');
            return;
        }

        let html = '';
        gamesList.forEach(game => {
            html += renderOddsComparisonCard(game);
        });

        $grid.html(html);
    }

    /**
     * Render odds comparison card (multi-bookmaker table)
     */
    function renderOddsComparisonCard(game) {
        const gameTime = formatGameTime(game.commence_time);
        const isLive = game.completed === false && new Date(game.commence_time) < new Date();

        if (!game.bookmakers || Object.keys(game.bookmakers).length === 0) {
            return `
                <div class="sv-odds-comparison-card">
                    <div class="sv-odds-comparison-header">
                        <div class="sv-odds-matchup">
                            <div class="sv-team">${game.away_team}</div>
                            <div class="sv-at">@</div>
                            <div class="sv-team">${game.home_team}</div>
                        </div>
                        <div class="sv-odds-time">
                            ${isLive ? '<span class="sv-live-badge">LIVE</span>' : ''}
                            <span>${gameTime}</span>
                        </div>
                    </div>
                    <div class="sv-empty">No odds available from sportsbooks</div>
                </div>
            `;
        }

        // Get list of available bookmakers for this game
        const bookmakers = Object.keys(game.bookmakers);

        let html = `
            <div class="sv-odds-comparison-card">
                <div class="sv-odds-comparison-header">
                    <div class="sv-odds-matchup">
                        <div class="sv-team">${game.away_team}</div>
                        <div class="sv-at">@</div>
                        <div class="sv-team">${game.home_team}</div>
                    </div>
                    <div class="sv-odds-time">
                        ${isLive ? '<span class="sv-live-badge">LIVE</span>' : ''}
                        <span>${gameTime}</span>
                    </div>
                </div>

                <!-- Moneyline Comparison -->
                ${renderMoneylineComparison(game, bookmakers)}

                <!-- Spread Comparison -->
                ${renderSpreadComparison(game, bookmakers)}

                <!-- Total Comparison -->
                ${renderTotalComparison(game, bookmakers)}
            </div>
        `;

        return html;
    }

    /**
     * Render moneyline comparison table
     */
    function renderMoneylineComparison(game, bookmakers) {
        let html = '<div class="sv-comparison-section">';
        html += '<h4 class="sv-comparison-title">MONEYLINE</h4>';
        html += '<div class="sv-comparison-table">';

        // Header row
        html += '<div class="sv-comparison-row sv-comparison-header-row">';
        html += '<div class="sv-comparison-cell sv-team-label">Team</div>';
        bookmakers.forEach(bookKey => {
            const book = game.bookmakers[bookKey];
            html += `<div class="sv-comparison-cell sv-book-name">${book.title || bookKey}</div>`;
        });
        html += '</div>';

        // Away team row
        html += '<div class="sv-comparison-row">';
        html += `<div class="sv-comparison-cell sv-team-label">${game.away_team}</div>`;
        bookmakers.forEach(bookKey => {
            const book = game.bookmakers[bookKey];
            const odds = book.moneyline?.away || null;
            html += `<div class="sv-comparison-cell sv-odds-cell">${odds ? formatOdds(odds) : '--'}</div>`;
        });
        html += '</div>';

        // Home team row
        html += '<div class="sv-comparison-row">';
        html += `<div class="sv-comparison-cell sv-team-label">${game.home_team}</div>`;
        bookmakers.forEach(bookKey => {
            const book = game.bookmakers[bookKey];
            const odds = book.moneyline?.home || null;
            html += `<div class="sv-comparison-cell sv-odds-cell">${odds ? formatOdds(odds) : '--'}</div>`;
        });
        html += '</div>';

        html += '</div></div>';
        return html;
    }

    /**
     * Render spread comparison table
     */
    function renderSpreadComparison(game, bookmakers) {
        let html = '<div class="sv-comparison-section">';
        html += '<h4 class="sv-comparison-title">SPREAD</h4>';
        html += '<div class="sv-comparison-table">';

        // Header row
        html += '<div class="sv-comparison-row sv-comparison-header-row">';
        html += '<div class="sv-comparison-cell sv-team-label">Team</div>';
        bookmakers.forEach(bookKey => {
            const book = game.bookmakers[bookKey];
            html += `<div class="sv-comparison-cell sv-book-name">${book.title || bookKey}</div>`;
        });
        html += '</div>';

        // Away team row
        html += '<div class="sv-comparison-row">';
        html += `<div class="sv-comparison-cell sv-team-label">${game.away_team}</div>`;
        bookmakers.forEach(bookKey => {
            const book = game.bookmakers[bookKey];
            const spread = book.spread?.away;
            if (spread && spread.point !== null && spread.price !== null) {
                html += `<div class="sv-comparison-cell sv-odds-cell">${formatSpread(spread.point)} (${formatOdds(spread.price)})</div>`;
            } else {
                html += `<div class="sv-comparison-cell sv-odds-cell">--</div>`;
            }
        });
        html += '</div>';

        // Home team row
        html += '<div class="sv-comparison-row">';
        html += `<div class="sv-comparison-cell sv-team-label">${game.home_team}</div>`;
        bookmakers.forEach(bookKey => {
            const book = game.bookmakers[bookKey];
            const spread = book.spread?.home;
            if (spread && spread.point !== null && spread.price !== null) {
                html += `<div class="sv-comparison-cell sv-odds-cell">${formatSpread(spread.point)} (${formatOdds(spread.price)})</div>`;
            } else {
                html += `<div class="sv-comparison-cell sv-odds-cell">--</div>`;
            }
        });
        html += '</div>';

        html += '</div></div>';
        return html;
    }

    /**
     * Render total comparison table
     */
    function renderTotalComparison(game, bookmakers) {
        let html = '<div class="sv-comparison-section">';
        html += '<h4 class="sv-comparison-title">TOTAL</h4>';
        html += '<div class="sv-comparison-table">';

        // Header row
        html += '<div class="sv-comparison-row sv-comparison-header-row">';
        html += '<div class="sv-comparison-cell sv-team-label">Outcome</div>';
        bookmakers.forEach(bookKey => {
            const book = game.bookmakers[bookKey];
            html += `<div class="sv-comparison-cell sv-book-name">${book.title || bookKey}</div>`;
        });
        html += '</div>';

        // Over row
        html += '<div class="sv-comparison-row">';
        html += `<div class="sv-comparison-cell sv-team-label">Over</div>`;
        bookmakers.forEach(bookKey => {
            const book = game.bookmakers[bookKey];
            const total = book.total?.over;
            if (total && total.point !== null && total.price !== null) {
                html += `<div class="sv-comparison-cell sv-odds-cell">O ${total.point} (${formatOdds(total.price)})</div>`;
            } else {
                html += `<div class="sv-comparison-cell sv-odds-cell">--</div>`;
            }
        });
        html += '</div>';

        // Under row
        html += '<div class="sv-comparison-row">';
        html += `<div class="sv-comparison-cell sv-team-label">Under</div>`;
        bookmakers.forEach(bookKey => {
            const book = game.bookmakers[bookKey];
            const total = book.total?.under;
            if (total && total.point !== null && total.price !== null) {
                html += `<div class="sv-comparison-cell sv-odds-cell">U ${total.point} (${formatOdds(total.price)})</div>`;
            } else {
                html += `<div class="sv-comparison-cell sv-odds-cell">--</div>`;
            }
        });
        html += '</div>';

        html += '</div></div>';
        return html;
    }

    /**
     * Render odds market (read-only)
     */
    function renderOddsMarket(game, marketType, label) {
        if (!game[marketType]) return '';

        let oddsHtml = '';

        if (marketType === 'moneyline') {
            const ml = game.moneyline;
            oddsHtml = `
                <div class="sv-odds-row">
                    <span class="sv-odds-label">${game.away_team}</span>
                    <span class="sv-odds-value">${formatOdds(ml.away)}</span>
                </div>
                <div class="sv-odds-row">
                    <span class="sv-odds-label">${game.home_team}</span>
                    <span class="sv-odds-value">${formatOdds(ml.home)}</span>
                </div>
            `;
        } else if (marketType === 'spread') {
            const spread = game.spread;
            oddsHtml = `
                <div class="sv-odds-row">
                    <span class="sv-odds-label">${game.away_team} ${formatSpread(spread.away.point)}</span>
                    <span class="sv-odds-value">${formatOdds(spread.away.price)}</span>
                </div>
                <div class="sv-odds-row">
                    <span class="sv-odds-label">${game.home_team} ${formatSpread(spread.home.point)}</span>
                    <span class="sv-odds-value">${formatOdds(spread.home.price)}</span>
                </div>
            `;
        } else if (marketType === 'total') {
            const total = game.total;
            oddsHtml = `
                <div class="sv-odds-row">
                    <span class="sv-odds-label">Over ${total.over.point}</span>
                    <span class="sv-odds-value">${formatOdds(total.over.price)}</span>
                </div>
                <div class="sv-odds-row">
                    <span class="sv-odds-label">Under ${total.under.point}</span>
                    <span class="sv-odds-value">${formatOdds(total.under.price)}</span>
                </div>
            `;
        }

        return `
            <div class="sv-odds-market-column">
                <div class="sv-odds-market-label">${label}</div>
                ${oddsHtml}
            </div>
        `;
    }

    /**
     * Render alternate spreads section
     */
    function renderAlternateSpreadsSection(game) {
        if (!game.alternate_spreads || game.alternate_spreads.length === 0) {
            return '';
        }

        let html = '<div class="sv-odds-section"><h4 class="sv-odds-section-title">ALTERNATE SPREADS</h4><div class="sv-odds-alt-grid">';

        game.alternate_spreads.forEach(spread => {
            html += `
                <div class="sv-odds-alt-item">
                    <div class="sv-odds-row">
                        <span class="sv-odds-label">${game.away_team} ${formatSpread(spread.away.point)}</span>
                        <span class="sv-odds-value">${formatOdds(spread.away.price)}</span>
                    </div>
                    <div class="sv-odds-row">
                        <span class="sv-odds-label">${game.home_team} ${formatSpread(spread.home.point)}</span>
                        <span class="sv-odds-value">${formatOdds(spread.home.price)}</span>
                    </div>
                </div>
            `;
        });

        html += '</div></div>';
        return html;
    }

    /**
     * Render alternate totals section
     */
    function renderAlternateTotalsSection(game) {
        if (!game.alternate_totals || game.alternate_totals.length === 0) {
            return '';
        }

        let html = '<div class="sv-odds-section"><h4 class="sv-odds-section-title">ALTERNATE TOTALS</h4><div class="sv-odds-alt-grid">';

        game.alternate_totals.forEach(total => {
            html += `
                <div class="sv-odds-alt-item">
                    <div class="sv-odds-row">
                        <span class="sv-odds-label">Over ${total.over.point}</span>
                        <span class="sv-odds-value">${formatOdds(total.over.price)}</span>
                    </div>
                    <div class="sv-odds-row">
                        <span class="sv-odds-label">Under ${total.under.point}</span>
                        <span class="sv-odds-value">${formatOdds(total.under.price)}</span>
                    </div>
                </div>
            `;
        });

        html += '</div></div>';
        return html;
    }

    /**
     * Load games
     */
    function loadGames(sport) {
        const $grid = $('.sv-games-grid');
        $grid.html('<div class="sv-loading">Loading games...</div>');

        $.ajax({
            url: svSportsbook.ajaxUrl,
            method: 'POST',
            data: {
                action: 'sv_load_games',
                nonce: svSportsbook.nonce,
                sport: sport || 'all',
            },
            success: function(response) {
                if (response.success) {
                    games = response.data.games;
                    console.log('Loaded games:', games);
                    console.log('Games with alt lines:', games.filter(g => g.alternate_spreads || g.alternate_totals).length);

                    // DEBUG: Check first game structure
                    if (games.length > 0) {
                        console.log('🔍 FIRST GAME DEBUG:', {
                            id: games[0].id,
                            hasMoneyline: !!games[0].moneyline,
                            hasSpread: !!games[0].spread,
                            hasTotal: !!games[0].total,
                            totalData: games[0].total
                        });
                    }

                    // Apply search filter if active
                    if (searchTerm) {
                        filterGames();
                    } else {
                        renderGames(games);
                    }
                } else {
                    $grid.html('<div class="sv-error">Error: ' + response.data.message + '</div>');
                }
            },
            error: function() {
                $grid.html('<div class="sv-error">Network error. Please refresh.</div>');
            }
        });
    }

    /**
     * Render games
     */
    function renderGames(gamesList) {
        const $grid = $('.sv-games-grid');

        if (!gamesList || gamesList.length === 0) {
            $grid.html('<div class="sv-empty">No games available right now.</div>');
            return;
        }

        let html = '';
        gamesList.forEach(game => {
            html += renderGameCard(game);
        });

        $grid.html(html);
        bindOddsButtons();
    }


    /**
     * Render game card
     */
    function renderGameCard(game) {
        const gameTime = formatGameTime(game.commence_time);
        const isLive = game.completed === false && new Date(game.commence_time) < new Date();

        return `
            <div class="sv-game-card" data-game-id="${game.id}" data-sport="${game.sport}">
                <div class="sv-game-header">
                    <div class="sv-matchup">
                        <div class="sv-team sv-away">${game.away_team}</div>
                        <div class="sv-at">@</div>
                        <div class="sv-team sv-home">${game.home_team}</div>
                    </div>
                    <div class="sv-game-time">
                        ${isLive ? '<span class="sv-live-badge">LIVE</span>' : ''}
                        <span>${gameTime}</span>
                    </div>
                </div>

                <div class="sv-markets">
                    ${renderMarket(game, 'moneyline', 'MONEYLINE')}
                    ${renderMarket(game, 'spread', 'SPREAD')}
                    ${renderMarket(game, 'total', 'TOTAL')}
                </div>
            </div>
        `;
    }

    /**
     * Render market
     */
    function renderMarket(game, marketType, label) {
        if (!game[marketType]) return '';

        let oddsHtml = '';

        if (marketType === 'moneyline') {
            const ml = game.moneyline;
            oddsHtml = `
                ${renderOddButton(game, 'moneyline', game.away_team, ml.away)}
                ${renderOddButton(game, 'moneyline', game.home_team, ml.home)}
            `;
        } else if (marketType === 'spread') {
            const spread = game.spread;

            // Build alternate spreads button if available
            const hasAltSpreads = game.alternate_spreads && game.alternate_spreads.length > 0;
            const altAwayBtn = hasAltSpreads ? `<button class="sv-alt-lines-btn" data-game-id="${game.id}" data-team="away" data-market="spread">±</button>` : '';
            const altHomeBtn = hasAltSpreads ? `<button class="sv-alt-lines-btn" data-game-id="${game.id}" data-team="home" data-market="spread">±</button>` : '';

            oddsHtml = `
                <div class="sv-odd-with-alt">
                    ${renderOddButton(game, 'spread', `${game.away_team} ${formatSpread(spread.away.point)}`, spread.away.price)}
                    ${altAwayBtn}
                </div>
                <div class="sv-odd-with-alt">
                    ${renderOddButton(game, 'spread', `${game.home_team} ${formatSpread(spread.home.point)}`, spread.home.price)}
                    ${altHomeBtn}
                </div>
            `;
        } else if (marketType === 'total') {
            const total = game.total;
            oddsHtml = `
                ${renderOddButton(game, 'total', `O ${total.over.point}`, total.over.price)}
                ${renderOddButton(game, 'total', `U ${total.under.point}`, total.under.price)}
            `;
        }

        return `
            <div class="sv-market">
                <div class="sv-market-label">${label}</div>
                <div class="sv-market-odds">
                    ${oddsHtml}
                </div>
            </div>
        `;
    }

    /**
     * Render odd button with inline quick unit input
     */
    function renderOddButton(game, pickType, selection, odds) {
        const pickKey = `${game.id}_${pickType}_${selection}`;

        return `
            <div class="sv-odd-wrapper" data-pick-key="${pickKey}" data-game-id="${game.id}">
                <button class="sv-odd"
                        data-game-id="${game.id}"
                        data-pick-type="${pickType}"
                        data-selection="${selection}"
                        data-odds="${odds}"
                        data-pick-key="${pickKey}">
                    <span class="sv-odd-team">${selection}</span>
                    <span class="sv-odd-price">${formatOdds(odds)}</span>
                </button>
                <div class="sv-quick-submit" style="display: none;">
                    <div class="sv-quick-header">
                        <strong>${selection}</strong>
                        <span>${formatOdds(odds)}</span>
                    </div>
                    <div class="sv-current-plays"></div>
                    <div class="sv-quick-controls">
                        <div class="sv-unit-quick-buttons">
                            <button class="sv-unit-quick-btn" data-pick-key="${pickKey}" data-units="1">1</button>
                            <button class="sv-unit-quick-btn" data-pick-key="${pickKey}" data-units="2">2</button>
                            <button class="sv-unit-quick-btn" data-pick-key="${pickKey}" data-units="5">5</button>
                            <button class="sv-unit-quick-btn sv-unit-featured" data-pick-key="${pickKey}" data-units="10">10</button>
                        </div>
                        <div class="sv-unit-custom">
                            <input type="number" class="sv-unit-custom-input" placeholder="Custom units" min="1" max="1000" data-pick-key="${pickKey}" />
                            <button class="sv-unit-custom-submit" data-pick-key="${pickKey}">SUBMIT</button>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    /**
     * Bind odds buttons
     */
    function bindOddsButtons() {
        console.log('bindOddsButtons called, found ' + $('.sv-odd').length + ' odds buttons');

        // Click odd button - show quick submit widget
        $('.sv-odd').off('click').on('click', function(e) {
            e.preventDefault();
            console.log('Odds button clicked!');

            const pickKey = $(this).data('pick-key');
            const gameId = $(this).data('game-id');
            const $wrapper = $(this).closest('.sv-odd-wrapper');
            const $widget = $wrapper.find('.sv-quick-submit');

            console.log('pickKey:', pickKey);
            console.log('wrapper found:', $wrapper.length);
            console.log('widget found:', $widget.length);

            // Hide all other submit widgets
            $('.sv-quick-submit').hide();
            $('.sv-odd').removeClass('active');

            // Show current plays for this game
            showCurrentPlaysForGame($wrapper, gameId);

            // Show this one
            $(this).addClass('active');
            $widget.show();

            console.log('Widget should be visible now, display:', $widget.css('display'));

        });

        // Unit quick button - populate custom input (don't submit immediately)
        $('.sv-unit-quick-btn').off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            const pickKey = $(this).data('pick-key');
            const units = parseInt($(this).data('units'));
            const $wrapper = $(`.sv-odd-wrapper[data-pick-key="${pickKey}"]`);
            const $input = $wrapper.find('.sv-unit-custom-input');

            console.log('Unit button clicked:', units, 'units - populating custom input');

            // Populate the custom input field
            $input.val(units);

            // Highlight the input to show it's been updated
            $input.css('border', '2px solid var(--sv-yellow)');
            setTimeout(() => {
                $input.css('border', '1px solid #444');
            }, 1000);

            // Focus on submit button so user knows to click it
            $wrapper.find('.sv-unit-custom-submit').css('background', 'var(--sv-yellow)');
        });

        // Custom unit submit button
        $('.sv-unit-custom-submit').off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            const pickKey = $(this).data('pick-key');
            const $wrapper = $(`.sv-odd-wrapper[data-pick-key="${pickKey}"]`);
            const $input = $wrapper.find('.sv-unit-custom-input');
            const units = parseInt($input.val());
            const $btn = $wrapper.find('.sv-odd');

            if (!units || units < 1) {
                alert('Please enter a valid number of units');
                return;
            }

            console.log('Custom units submitted:', units);

            // Submit immediately
            submitPickInstantly($btn, units);

            // If this is an alternate spread temporary wrapper, remove it
            if ($wrapper.hasClass('sv-alt-temp-wrapper')) {
                setTimeout(() => {
                    $wrapper.remove();
                }, 500); // Small delay to show confirmation
            } else {
                // Hide the widget and clear input for normal buttons
                $wrapper.find('.sv-quick-submit').hide();
                $btn.removeClass('active');
                $input.val('');
            }
        });

        // Enter key on custom input
        $('.sv-unit-custom-input').off('keypress').on('keypress', function(e) {
            if (e.which === 13) {
                e.preventDefault();
                const pickKey = $(this).data('pick-key');
                $(`.sv-unit-custom-submit[data-pick-key="${pickKey}"]`).click();
            }
        });

        // Alternate lines button
        $('.sv-alt-lines-btn').off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            const gameId = $(this).data('game-id');
            const team = $(this).data('team'); // 'away' or 'home'
            const game = games.find(g => g.id === gameId);

            if (!game || !game.alternate_spreads) {
                alert('No alternate lines available');
                return;
            }

            // Build dropdown HTML with backdrop
            let html = '<div class="sv-alt-dropdown-backdrop"></div>';
            html += '<div class="sv-alt-dropdown">';
            html += '<div class="sv-alt-dropdown-title">';
            html += '<span>Alternate Spreads</span>';
            html += '<button class="sv-alt-dropdown-close">×</button>';
            html += '</div>';

            game.alternate_spreads.forEach(spread => {
                const teamSpread = team === 'away' ? spread.away : spread.home;
                const teamName = team === 'away' ? game.away_team : game.home_team;

                html += `
                    <button class="sv-alt-dropdown-item"
                            data-game-id="${gameId}"
                            data-team="${teamName}"
                            data-spread="${teamSpread.point}"
                            data-odds="${teamSpread.price}">
                        ${teamName} ${formatSpread(teamSpread.point)} (${formatOdds(teamSpread.price)})
                    </button>
                `;
            });

            html += '</div>';

            // Remove any existing dropdowns
            $('.sv-alt-dropdown, .sv-alt-dropdown-backdrop').remove();

            // Show dropdown centered on screen
            $('body').append(html);
        });

        // Alternate dropdown item click
        $(document).on('click', '.sv-alt-dropdown-item', function(e) {
            e.preventDefault();
            e.stopPropagation();

            const gameId = $(this).data('game-id');
            const team = $(this).data('team');
            const spread = $(this).data('spread');
            const odds = $(this).data('odds');
            const game = games.find(g => g.id === gameId);

            console.log('Alternate spread selected:', team, spread, odds);

            if (!game) {
                alert('Game not found');
                return;
            }

            // Close dropdown
            $('.sv-alt-dropdown, .sv-alt-dropdown-backdrop').remove();

            // Create selection label
            const selection = `${team} ${formatSpread(spread)}`;
            const pickKey = `${gameId}_spread_alt_${spread}`;

            // Create a temporary odd button wrapper with the units interface
            const tempButtonHtml = `
                <div class="sv-odd-wrapper sv-alt-temp-wrapper" data-pick-key="${pickKey}" data-game-id="${gameId}" style="position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); z-index: 10000; background: var(--sv-dark-gray); padding: 20px; border: 2px solid var(--sv-yellow); border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.8);">
                    <div style="text-align: center; margin-bottom: 15px;">
                        <div style="font-size: 16px; font-weight: 700; color: var(--sv-yellow); margin-bottom: 5px;">${selection}</div>
                        <div style="font-size: 14px; color: var(--sv-white);">${formatOdds(odds)}</div>
                    </div>
                    <button class="sv-odd" style="display: none;"
                            data-game-id="${gameId}"
                            data-pick-type="spread"
                            data-selection="${selection}"
                            data-odds="${odds}"
                            data-pick-key="${pickKey}">
                    </button>
                    <div class="sv-quick-submit" style="display: block; position: relative;">
                        <div class="sv-quick-controls">
                            <div class="sv-unit-quick-buttons">
                                <button class="sv-unit-quick-btn" data-pick-key="${pickKey}" data-units="1">1</button>
                                <button class="sv-unit-quick-btn" data-pick-key="${pickKey}" data-units="2">2</button>
                                <button class="sv-unit-quick-btn" data-pick-key="${pickKey}" data-units="5">5</button>
                                <button class="sv-unit-quick-btn sv-unit-featured" data-pick-key="${pickKey}" data-units="10">10</button>
                            </div>
                            <div class="sv-unit-custom">
                                <input type="number" class="sv-unit-custom-input" placeholder="Custom units" min="1" max="1000" data-pick-key="${pickKey}" />
                                <button class="sv-unit-custom-submit" data-pick-key="${pickKey}">SUBMIT</button>
                            </div>
                        </div>
                        <button class="sv-alt-cancel" style="margin-top: 10px; width: 100%; padding: 8px; background: var(--sv-medium-gray); color: var(--sv-white); border: 1px solid #444; border-radius: 4px; cursor: pointer;">CANCEL</button>
                    </div>
                </div>
            `;

            // Add to body
            $('body').append(tempButtonHtml);

            // Bind the cancel button
            $('.sv-alt-cancel').on('click', function() {
                $('.sv-alt-temp-wrapper').remove();
            });

            // Re-bind unit buttons for this new element
            bindOddsButtons();
        });

        // Click outside - hide widget and dropdowns
        $(document).off('click.quick').on('click.quick', function(e) {
            // Close regular odds widget if clicking outside
            if (!$(e.target).closest('.sv-odd-wrapper').length) {
                $('.sv-quick-submit').hide();
                $('.sv-odd').removeClass('active');
            }

            // Close alternate lines dropdown if clicking outside
            if (!$(e.target).closest('.sv-alt-lines-btn, .sv-alt-dropdown').length) {
                $('.sv-alt-dropdown, .sv-alt-dropdown-backdrop').remove();
            }

            // Close alternate spread modal if clicking outside
            if (!$(e.target).closest('.sv-alt-temp-wrapper').length) {
                $('.sv-alt-temp-wrapper').remove();
            }
        });

        // Click backdrop to close dropdown
        $(document).on('click', '.sv-alt-dropdown-backdrop, .sv-alt-dropdown-close', function() {
            $('.sv-alt-dropdown, .sv-alt-dropdown-backdrop').remove();
        });
    }

    /**
     * Submit pick instantly (no extra clicks)
     */
    function submitPickInstantly($btn, units) {
        const gameId = $btn.data('game-id');
        const pickType = $btn.data('pick-type');
        const selection = $btn.data('selection');
        const odds = $btn.data('odds');
        const pickKey = $btn.data('pick-key');

        // Find the game to get full context
        const game = games.find(g => g.id === gameId);

        if (!game) {
            alert('Game not found');
            return;
        }

        const pickData = {
            gameId: gameId,
            sport: game.sport_key || currentSport,
            awayTeam: game.away_team,
            homeTeam: game.home_team,
            eventDate: game.commence_time,
            pickType: pickType,
            selection: selection,
            odds: odds,
            units: units,
            matchup: `${game.away_team} @ ${game.home_team}`,
            timestamp: new Date().toISOString()
        };

        // Visual feedback
        $btn.addClass('selected pick-saved');

        // Save to database
        $.ajax({
            url: svSportsbook.ajaxUrl,
            method: 'POST',
            data: {
                action: 'sv_save_pick',
                nonce: svSportsbook.nonce,
                pick: JSON.stringify(pickData),
            },
            success: function(response) {
                if (response.success) {
                    // Show quick confirmation
                    showQuickConfirmation(selection, units);

                    // Reload picks in MY BETS tab
                    loadUserPicks();
                } else {
                    alert('Error saving pick: ' + (response.data ? response.data.message : 'Unknown error'));
                    $btn.removeClass('selected pick-saved');
                }
            },
            error: function() {
                alert('Network error saving pick');
                $btn.removeClass('selected pick-saved');
            }
        });
    }

    /**
     * Add pick to parlay
     */
    let parlayPicks = [];

    function addToParlay($btn, units) {
        const gameId = $btn.data('game-id');
        const pickType = $btn.data('pick-type');
        const selection = $btn.data('selection');
        const odds = $btn.data('odds');
        const pickKey = $btn.data('pick-key');

        const pickData = {
            gameId: gameId,
            pickType: pickType,
            selection: selection,
            odds: odds,
            units: units,
            pickKey: pickKey
        };

        // Check if already in parlay
        const existingIndex = parlayPicks.findIndex(p => p.pickKey === pickKey);
        if (existingIndex >= 0) {
            // Update units
            parlayPicks[existingIndex].units = units;
        } else {
            // Add new pick
            parlayPicks.push(pickData);
        }

        // Visual feedback
        $btn.addClass('in-parlay');
        showQuickConfirmation(`Added ${selection} to parlay`, null);

        // Update parlay sidebar
        updateParlaySidebar();

        // Open parlay sidebar
        $('.sv-parlay-sidebar').addClass('open');
    }

    /**
     * Update parlay sidebar
     */
    function updateParlaySidebar() {
        if (parlayPicks.length === 0) {
            $('#parlay-picks-list').html('<p style="color: #888; text-align: center;">No picks in parlay</p>');
            $('#parlay-total-odds').text('-');
            $('#parlay-potential-win').text('-');
            return;
        }

        let html = '';
        let totalOdds = 1;

        parlayPicks.forEach((pick, index) => {
            const americanOdds = parseFloat(pick.odds);
            let decimalOdds = 1;

            // Convert American odds to decimal
            if (americanOdds > 0) {
                decimalOdds = (americanOdds / 100) + 1;
            } else {
                decimalOdds = (100 / Math.abs(americanOdds)) + 1;
            }

            totalOdds *= decimalOdds;

            html += `
                <div class="sv-parlay-pick-item">
                    <div class="sv-parlay-pick-info">
                        <strong>${pick.selection}</strong>
                        <span>${formatOdds(pick.odds)}</span>
                    </div>
                    <button class="sv-remove-from-parlay" data-index="${index}">×</button>
                </div>
            `;
        });

        const totalUnits = parlayPicks[0]?.units || 10;
        const potentialWin = (totalOdds * totalUnits).toFixed(2);

        $('#parlay-picks-list').html(html);
        $('#parlay-total-odds').text(`+${Math.round((totalOdds - 1) * 100)}`);
        $('#parlay-potential-win').text(`${potentialWin} units`);

        // Bind remove buttons
        $('.sv-remove-from-parlay').off('click').on('click', function() {
            const index = $(this).data('index');
            const removedPick = parlayPicks[index];

            // Remove from array
            parlayPicks.splice(index, 1);

            // Remove visual indicator from button
            $(`.sv-odd[data-pick-key="${removedPick.pickKey}"]`).removeClass('in-parlay');

            // Update sidebar
            updateParlaySidebar();
        });
    }

    /**
     * Show quick confirmation toast
     */
    function showQuickConfirmation(selection, units) {
        const $toast = $(`
            <div class="sv-toast">
                ✓ ${selection} (${units} units) saved
            </div>
        `);

        $('body').append($toast);

        setTimeout(() => {
            $toast.addClass('show');
        }, 10);

        setTimeout(() => {
            $toast.removeClass('show');
            setTimeout(() => $toast.remove(), 300);
        }, 2000);
    }

    /**
     * Load user's picks for MY BETS tab
     */
    function loadUserPicks() {
        $.ajax({
            url: svSportsbook.ajaxUrl,
            method: 'POST',
            data: {
                action: 'sv_get_user_picks',
                nonce: svSportsbook.nonce,
            },
            success: function(response) {
                if (response.success) {
                    userPicks = response.data.picks || [];
                    renderMyBets();
                }
            }
        });
    }

    /**
     * Load user's weekly and monthly stats
     */
    function loadUserStats() {
        $.ajax({
            url: svSportsbook.ajaxUrl,
            method: 'POST',
            data: {
                action: 'sv_get_user_stats',
                nonce: svSportsbook.nonce,
            },
            success: function(response) {
                console.log('Stats response:', response);
                if (response.success) {
                    const weekly = response.data.weekly;
                    const monthly = response.data.monthly;

                    console.log('Weekly stats:', weekly);
                    console.log('Monthly stats:', monthly);

                    // Update weekly stats
                    $('#weekly-wins').text(weekly.wins);
                    $('#weekly-losses').text(weekly.losses);
                    $('#weekly-wagered').text(weekly.total_risked + 'u');
                    $('#weekly-profit').text(formatProfit(weekly.net_profit));
                    $('#weekly-svr').text(weekly.svr_score);

                    // Update monthly stats
                    $('#monthly-wins').text(monthly.wins);
                    $('#monthly-losses').text(monthly.losses);
                    $('#monthly-wagered').text(monthly.total_risked + 'u');
                    $('#monthly-profit').text(formatProfit(monthly.net_profit));
                    $('#monthly-svr').text(monthly.svr_score);

                    // Add color coding for profit
                    updateProfitColor('#weekly-profit', weekly.net_profit);
                    updateProfitColor('#monthly-profit', monthly.net_profit);

                    // Add color coding for SVR scores
                    updateSVRColor('#weekly-svr', weekly.svr_score);
                    updateSVRColor('#monthly-svr', monthly.svr_score);
                } else {
                    console.error('Stats error:', response.data);
                }
            },
            error: function(xhr, status, error) {
                console.error('Stats AJAX error:', status, error);
                console.log('Response:', xhr.responseText);
            }
        });
    }

    /**
     * Format profit with +/- sign
     */
    function formatProfit(profit) {
        const num = parseFloat(profit);
        if (num > 0) {
            return '+' + num + 'u';
        } else if (num < 0) {
            return num + 'u';
        } else {
            return '0u';
        }
    }

    /**
     * Update profit color based on value
     */
    function updateProfitColor(selector, profit) {
        const $elem = $(selector);
        $elem.removeClass('sv-profit-positive sv-profit-negative sv-profit-neutral');

        if (profit > 0) {
            $elem.addClass('sv-profit-positive');
        } else if (profit < 0) {
            $elem.addClass('sv-profit-negative');
        } else {
            $elem.addClass('sv-profit-neutral');
        }
    }

    /**
     * Update SVR score color based on value
     * SVR range is 20-100
     */
    function updateSVRColor(selector, score) {
        const $elem = $(selector);
        $elem.removeClass('sv-svr-excellent sv-svr-good sv-svr-average sv-svr-poor');

        if (score >= 80) {
            $elem.addClass('sv-svr-excellent'); // 80-100: Excellent
        } else if (score >= 60) {
            $elem.addClass('sv-svr-good'); // 60-79: Good
        } else if (score >= 40) {
            $elem.addClass('sv-svr-average'); // 40-59: Average
        } else {
            $elem.addClass('sv-svr-poor'); // 20-39: Poor
        }
    }

    /**
     * Render MY BETS tab
     */
    function renderMyBets() {
        const $container = $('#my-bets-list');

        if (!userPicks || userPicks.length === 0) {
            $container.html('<div class="sv-empty">No picks yet. Make some picks!</div>');
            return;
        }

        let html = '<div class="sv-my-picks-container">';

        userPicks.forEach(pick => {
            const pickTypeLabel = pick.pick_type.toUpperCase();
            const matchup = `${pick.away_team} @ ${pick.home_team}`;
            const eventTime = formatEventTime(pick.event_date);
            const placedTime = formatPlacedTime(pick.bet_placed_at);

            // Build detailed selection text
            let detailedSelection = '';
            if (pick.pick_type === 'moneyline') {
                detailedSelection = `${pick.selection} to win`;
            } else if (pick.pick_type === 'spread') {
                detailedSelection = `${pick.selection} in ${matchup}`;
            } else if (pick.pick_type === 'total') {
                // For totals, make it crystal clear
                if (pick.selection.startsWith('O')) {
                    detailedSelection = `Over ${pick.selection.substring(2)} in ${matchup}`;
                } else if (pick.selection.startsWith('U')) {
                    detailedSelection = `Under ${pick.selection.substring(2)} in ${matchup}`;
                } else {
                    detailedSelection = `${pick.selection} in ${matchup}`;
                }
            } else {
                detailedSelection = pick.selection;
            }

            // Status badge
            let statusBadge = '';
            let statusClass = '';
            if (pick.result === 'pending') {
                statusBadge = 'PENDING';
                statusClass = 'sv-status-pending';
            } else if (pick.result === 'won') {
                statusBadge = 'WON';
                statusClass = 'sv-status-won';
            } else if (pick.result === 'lost') {
                statusBadge = 'LOST';
                statusClass = 'sv-status-lost';
            } else if (pick.result === 'push') {
                statusBadge = 'PUSH';
                statusClass = 'sv-status-push';
            }

            // Live score if available
            let scoreHtml = '';
            if (pick.away_score !== null && pick.home_score !== null) {
                scoreHtml = `
                    <div class="sv-my-pick-score">
                        <span class="sv-score-label">Score:</span>
                        <span class="sv-score-value">${pick.away_score} - ${pick.home_score}</span>
                    </div>
                `;
            }

            // Graded time if completed
            let gradedHtml = '';
            if (pick.bet_graded_at) {
                const gradedTime = formatPlacedTime(pick.bet_graded_at);
                gradedHtml = `<div class="sv-my-pick-graded">Graded: ${gradedTime}</div>`;
            }

            // Payout if completed
            let payoutHtml = '';
            if (pick.payout !== null) {
                payoutHtml = `<div class="sv-my-pick-payout">Payout: ${pick.payout} units</div>`;
            }

            html += `
                <div class="sv-my-pick-card" data-slip-id="${pick.id}">
                    <div class="sv-my-pick-header">
                        <div class="sv-my-pick-slip-number">#${pick.slip_number}</div>
                        <div class="sv-my-pick-status ${statusClass}">${statusBadge}</div>
                    </div>

                    <div class="sv-my-pick-matchup-section">
                        <div class="sv-my-pick-matchup">${matchup}</div>
                        <div class="sv-my-pick-event-time">${eventTime}</div>
                    </div>

                    ${scoreHtml}

                    <div class="sv-my-pick-body">
                        <div class="sv-my-pick-main">
                            <div class="sv-my-pick-bet-details">
                                <div class="sv-my-pick-selection-full">${detailedSelection}</div>
                                <div class="sv-my-pick-odds-display">${formatOdds(pick.odds)}</div>
                            </div>
                        </div>
                        <div class="sv-my-pick-meta">
                            <div class="sv-my-pick-units">${pick.units} units</div>
                            <div class="sv-my-pick-time">Placed: ${placedTime}</div>
                            ${gradedHtml}
                            ${payoutHtml}
                        </div>
                    </div>
                </div>
            `;
        });

        html += '</div>';
        $container.html(html);
    }

    /**
     * Delete a pick
     */
    function deletePick(slipId) {
        if (!confirm('Delete this pick?')) return;

        $.ajax({
            url: svSportsbook.ajaxUrl,
            method: 'POST',
            data: {
                action: 'sv_delete_pick',
                nonce: svSportsbook.nonce,
                slip_id: slipId,
            },
            success: function(response) {
                if (response.success) {
                    loadUserPicks();
                } else {
                    alert('Error: ' + (response.data ? response.data.message : 'Could not delete pick'));
                }
            },
            error: function() {
                alert('Network error deleting pick');
            }
        });
    }

    /**
     * Show current plays for a game in the bet slip widget
     */
    function showCurrentPlaysForGame($wrapper, gameId) {
        const $currentPlays = $wrapper.find('.sv-current-plays');

        if (!userPicks || userPicks.length === 0) {
            $currentPlays.html('');
            return;
        }

        // Find all pending bets for this game
        const gameBets = userPicks.filter(pick =>
            pick.game_id === gameId && pick.result === 'pending'
        );

        if (gameBets.length === 0) {
            $currentPlays.html('');
            return;
        }

        // Build HTML for current plays
        let html = '<div class="sv-current-plays-section">';
        html += '<div class="sv-current-plays-header">CURRENT PLAYS:</div>';

        gameBets.forEach(bet => {
            html += `
                <div class="sv-current-play-item">
                    <span class="sv-current-play-selection">${bet.selection}</span>
                    <span class="sv-current-play-odds">${formatOdds(bet.odds)}</span>
                    <span class="sv-current-play-units">(${bet.units} units)</span>
                </div>
            `;
        });

        html += '</div>';
        $currentPlays.html(html);
    }

    /**
     * Format helpers
     */
    function formatOdds(odds) {
        if (!odds) return '';
        return odds > 0 ? '+' + odds : '' + odds;
    }

    function formatSpread(spread) {
        if (!spread) return '';
        return spread > 0 ? '+' + spread : '' + spread;
    }

    function formatGameTime(timestamp) {
        const date = new Date(timestamp);
        const options = {
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            timeZone: selectedTimezone,
            timeZoneName: 'short'
        };
        return date.toLocaleString('en-US', options);
    }

    function formatPickTime(timestamp) {
        const date = new Date(timestamp);
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);

        if (diffMins < 1) return 'Just now';
        if (diffMins < 60) return diffMins + ' min ago';
        if (diffMins < 1440) {
            const hours = Math.floor(diffMins / 60);
            return hours + (hours === 1 ? ' hour ago' : ' hours ago');
        }

        const days = Math.floor(diffMins / 1440);
        if (days === 1) return 'Yesterday';
        if (days < 7) return days + ' days ago';

        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }

    function formatEventTime(timestamp) {
        // If timestamp doesn't have timezone info (from database), treat as UTC
        let dateStr = timestamp;
        if (typeof dateStr === 'string' && !dateStr.includes('Z') && !dateStr.includes('+') && !dateStr.includes('T')) {
            // MySQL datetime format without timezone - treat as UTC
            dateStr = dateStr.replace(' ', 'T') + 'Z';
        }

        const date = new Date(dateStr);
        const options = {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
            timeZone: selectedTimezone,
            timeZoneName: 'short'
        };
        return date.toLocaleString('en-US', options);
    }

    function formatPlacedTime(timestamp) {
        // bet_placed_at is now saved as UTC with current_time('mysql', true)
        // Treat as UTC just like event_date
        let dateStr = timestamp;
        if (typeof dateStr === 'string' && !dateStr.includes('Z') && !dateStr.includes('+') && !dateStr.includes('T')) {
            // MySQL datetime format without timezone - treat as UTC
            dateStr = dateStr.replace(' ', 'T') + 'Z';
        }

        const date = new Date(dateStr);
        const options = {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
            timeZone: selectedTimezone,
            timeZoneName: 'short'
        };
        return date.toLocaleString('en-US', options);
    }

})(jQuery);
