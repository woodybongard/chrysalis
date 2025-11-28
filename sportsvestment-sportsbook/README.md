# SportsVestment Sportsbook v1.0

**Unified sportsbook interface for multi-sport pick'em pools**

---

## What This Is

This is a **complete rewrite** of the SportsVestment pick'em system with a unified sportsbook interface.

**Old system (sportsvestment-pickem):**
- Separate shortcodes per sport: `[sv_nba_pickem]`, `[sv_nfl_pickem]`
- Individual pick'em pages
- No odds (spreads, totals, moneylines)

**New system (sportsvestment-sportsbook):**
- One unified interface: `[sv_sportsbook]`
- All sports in one place (NBA, NFL, MLB, NHL)
- Real odds from The Odds API
- Sportsbook-style UI (like DraftKings/FanDuel)
- Make picks → See qualified pools → Enter pools

---

## Architecture

### Shares With Old Plugin:
- ✅ Same database tables (`wp_sv_pickem_pools`, `wp_sv_pickem_games`, etc.)
- ✅ Same auto-grading engine (games get graded automatically)
- ✅ Same WooCommerce + myCred integration
- ✅ Same user/auth system (WordPress)

### New In This Plugin:
- ✅ Odds API integration (spreads, totals, moneylines)
- ✅ Unified multi-sport interface
- ✅ Bet slip (client-side pick tracking)
- ✅ Qualified pools flow (picks first, pools second)
- ✅ Modern sportsbook UI (black/yellow theme)

---

## Structure

```
sportsvestment-sportsbook/
├── sportsvestment-sportsbook.php   # Main plugin file
├── core/
│   ├── class-odds-api-fetcher.php  # Fetch odds from The Odds API
│   ├── class-sportsbook-manager.php # Handle picks, pools, logic
│   └── class-ajax-handler.php       # AJAX endpoints
├── templates/
│   ├── sportsbook.php               # Main odds screen (Games & Odds)
│   ├── my-bets.php                  # User's active picks/pools
│   └── leaderboard.php              # Rankings
└── assets/
    ├── css/sportsbook.css           # Sportsbook UI styles
    └── js/sportsbook.js             # Bet slip, interactions
```

---

## Installation

### 1. Upload Plugin
Copy this folder to:
```
wp-content/plugins/sportsvestment-sportsbook/
```

### 2. Activate
- Go to **Plugins** in WordPress admin
- Find "SportsVestment Sportsbook"
- Click **Activate**

### 3. Configure
- Get an Odds API key from https://the-odds-api.com
- Add to WordPress settings (we'll build this)

### 4. Add Shortcode
Create a page and add:
```
[sv_sportsbook]
```

---

## Usage

**User Flow:**
1. User visits sportsbook page
2. Sees all games with odds (NBA, NFL, MLB, NHL)
3. Clicks to make picks (Lakers -3.5, Over 215.5, etc.)
4. Clicks "Submit Picks"
5. System shows: "Your picks qualify for these pools:"
   - NBA Premium Pool ($10)
   - Cross-Sport Parlay ($25)
   - VIP Exclusive ($50)
6. User chooses which pool(s) to enter
7. Pays with SV Coins
8. Picks are locked, auto-graded when games finish

---

## Roadmap

### Phase 1: Core (Week 1)
- [x] Plugin skeleton
- [ ] Odds API fetcher
- [ ] Basic odds screen UI
- [ ] Bet slip (JavaScript)

### Phase 2: Pools (Week 2)
- [ ] Qualified pools logic
- [ ] Pool entry purchase flow
- [ ] My Bets page

### Phase 3: Social (Week 3)
- [ ] Leaderboard
- [ ] Expert picks system
- [ ] User profiles

### Phase 4: Polish (Week 4)
- [ ] Mobile responsive
- [ ] Live odds updates
- [ ] Animations/transitions
- [ ] Beta launch

---

## Development Notes

**Built in parallel with old plugin:**
- Old plugin (`sportsvestment-pickem`) still works
- This is a fresh start, cleaner codebase
- Can run both side-by-side during transition
- When ready, replace `[sv_nba_pickem]` with `[sv_sportsbook]`

**Database:**
- Uses existing tables (no migration needed)
- `sport_type` column handles multi-sport
- Pool manager already supports multiple sports

**API:**
- The Odds API (paid, $10-50/month)
- More reliable than ESPN unofficial API
- Includes spreads, totals, moneylines
- Props available on higher tiers

---

## Next Steps

1. Build Odds API fetcher
2. Build odds screen template
3. Wire them together
4. Test with real data
5. Ship to beta users

---

**Let's build.**
