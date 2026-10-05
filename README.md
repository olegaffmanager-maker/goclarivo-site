# 1xBet odds widget — periodic rebuild

Adds a small "Upcoming matches & odds" widget, sourced live from the 1xBet
Marketing API, inside the existing 1xBet card on each `/{geo}/sports/` page
(es, mx, ar, pe, bo, py, en — the same geos 1xBet is already placed on).

## What's in this folder

- `scripts/onexbet_odds.py` — the script that actually fetches matches/odds
  and rewrites the widget. This is what the scheduled workflow runs.
- `scripts/scaffold_widget_markers.py` — a **one-time** setup script. **You
  don't need to run this** — it has already been run against your site copy,
  so the marker placeholders are already sitting in your `/{geo}/sports/`
  pages (showing an honest "sync pending" message). It's included only in
  case you ever need to add a new geo to `GEO_LANG` in `onexbet_odds.py`
  later.
- `.github/workflows/rebuild-1xbet-odds.yml` — the scheduled GitHub Actions
  workflow. Runs every 30 minutes, calls the script, commits the change if
  the matches/odds moved.
- `.env.example` — copy to `.env` for a local test run before relying on
  the scheduled workflow.

## Setup (what you need to do)

1. Drop `scripts/`, `.github/workflows/rebuild-1xbet-odds.yml` into your
   site's git repo (same layout — `scripts/` and `.github/` at the repo
   root, next to your `es/`, `it/`, etc. folders).
2. In your repo's **Settings → Secrets and variables → Actions**, add:
   - `ONEXBET_CLIENT_ID` and `ONEXBET_CLIENT_SECRET` — the values your
     account manager sent you.
   - `ONEXBET_REF` — **you still need this from the manager.** It's the
     partner ID; don't use the docs' example value of `1`, that's a
     different account.
   - `ONEXBET_GR` (optional) — the manager declined to give this one as of
     2026-10-05 ("look it up in the manual yourselves"). The widget works
     without it; it only affects a video-availability flag and the
     deeplink host, neither of which this widget uses.
3. That's it — the workflow will start running on its 30-minute schedule
   once it's on the default branch. You can also trigger it by hand from
   the repo's **Actions** tab → "Rebuild 1xBet odds widget" → **Run
   workflow**.

## Before you trust it blindly

I was not able to test this against the live API from where I built it —
my sandbox's network policy blocks the 1xBet API domain outright, and I
don't have `ref` confirmed yet anyway. Everything here is built directly
from the API's own published reference (confirmed by actually reading
`https://docs-marketing-sport.com/api`'s token flow, endpoint paths,
parameter order and the `Market` schema — not guessed), and the HTML
generation and marker-injection logic are unit-tested (fake data in,
correct widget HTML out), but the **first real run against the live API is
unverified**. Two ways to check it before trusting the schedule:

```bash
cp .env.example .env    # fill in your real values
pip install requests python-dotenv   # or just `export $(cat .env | xargs)`
python scripts/onexbet_odds.py --dry-run --debug-dir out/
```

`--dry-run` fetches and prints the widget HTML for every geo without
writing anything. `--debug-dir out/` additionally dumps every raw API
response into `out/<geo>/` so you (or I, if you paste one back to me) can
confirm the shape matches what the widget expects before the scheduled
job starts rewriting real pages.

If `ONEXBET_REF` (or `ONEXBET_GR`, if your account needs it) is wrong,
every call will come back `403` — the script fails loudly and leaves every
page untouched rather than guessing or writing a broken state.

## Design notes

- **Never fabricates a match.** If the API is unreachable, returns nothing
  usable, or a secret is missing, the widget shows an honest "pending" /
  "temporarily unavailable" / "no upcoming matches" message — never
  invented fixtures or odds.
- **Only overwrites the marker block.** Everything else on the page is
  untouched, and a failed fetch for one geo leaves that geo's last-good
  widget in place rather than blanking it.
- **Odds labels come straight from the API's `display` field** (it's
  documented as "the localized market name for display on the client
  side"), not from guessing what a numeric market-type ID means — so a
  German/Spanish/English `lng` request naturally gets correctly localized
  labels without this script hardcoding any translation.
- **Excludes virtual/esports football** (added 2026-10-05): the API's
  Football tournament list also includes simulated leagues like "Esoccer
  Battle Volta" (gamers playing FIFA under nicknames, running almost
  around the clock) mixed in with real matches. A keyword filter on the
  tournament name excludes these so the widget only shows real-world
  football. Not a documented API flag — a name-keyword heuristic, so a new
  virtual-league name could in theory slip through and need a keyword
  added later.
- **Club logos** (added 2026-10-05): the API returns a logo filename per
  opponent (`imageOpponent1`/`imageOpponent2`); the script turns that into
  a download URL using the pattern documented on the API's own "Загрузка
  изображений" (image download) page —
  `https://nimblecd.com/sfiles/logo_teams/{filename}` — not guessed. If a
  team has no logo filename in the response, none is rendered for it (no
  placeholder badge), and if the CDN ever 404s for a given file, the
  broken-image icon is hidden client-side rather than shown.
- **Clickable match cards** (added 2026-10-05): `sporteventDetail` already
  includes a `link` field (the match's page on 1xBet's own site). Every
  card is wrapped in that link when the API actually returned one for that
  match, and stays a plain, non-clickable card otherwise — never a guessed
  or constructed URL.
- **Live ("in-play") matches** (added 2026-10-05): the API has a second,
  separate feed for matches currently being played
  (`/datafeed/loadtree/live/api/v1/...`, mirroring the prematch path
  `tournaments -> sporteventIds -> sporteventDetail`). When there's a match
  live right now, the widget shows an "En vivo ahora / Live now" section
  above the upcoming-matches one, with the score (`curScore`) and current
  period/elapsed time (`currentPeriodName`, `timeSec // 60`) exactly as the
  API returns them — nothing interpolated or estimated between syncs. A
  failure on this second feed never blocks the upcoming-matches widget; it
  just means no live section that run. Same virtual/esports keyword filter
  applies here as on the prematch feed.
- **Basketball & Tennis sub-tabs** (added 2026-10-05): the page's live-match
  section now has sport sub-tabs (CSS-only, no JS) — see "Hockey &
  Volleyball" below, this grew to five sports on 2026-10-06. sportId 3
  (Basketball) and sportId 4 (Tennis) come straight from the docs (the
  LoadSingle `vids` parameter note, and the Tennis sporteventDetail response
  sample), not guessed. Each sport is independently fetched and injected
  into its own marker pair — one sport's API trouble never blocks another's.
- **Virtual/esports filter extended to every sport** (2026-10-06): basketball
  was observed live showing "NBA 2K26. Cyber League" — a simulated match
  (gamers playing NBA2K), not real basketball, under basketball's normal
  sportId rather than a separate one. The docs' own example response for
  the Results API independently shows the same thing ("NBA 2K21. Cyber
  ..." under sportId 3). With two independent confirmations that this
  contamination isn't football-specific, `VIRTUAL_TOURNAMENT_KEYWORDS` (the
  same keyword list, unchanged — "cyber" is what caught both cases above)
  now applies to every sport, not football alone.
- **More markets per card** (added 2026-10-06): cards now show Handicap and
  Total (Over/Under) odds alongside the existing 1X2, when the API offers
  them for that match. This isn't a guessed addition — `sporteventDetail` is
  now requested with `schemeOfGettingOdds=GetAllOdds` instead of
  `Get1X2Odds`, and the extra markets shown are matched against the API's
  own "Справочник маркетов" (Market dictionary) confirmed example response:
  market type IDs 7/8 = Handicap 1/2, 9/10 = Total Over/Under. Every pill's
  label is still the API's own already-localized `display` text, verbatim.
- **Recent results** (added 2026-10-06): a "Recent results" section shows
  the last 1–2 finished matches per sport, sourced from the API's separate
  Results feed (`/result/api/v1/...`, confirmed as its own path, not a
  filter on the match-odds feeds used elsewhere). The score is shown exactly
  as the API returns it (e.g. `2:1 (1:1,0:0,1:0)`) — split only to put the
  final score first visually, never reinterpreted. A finished match the API
  reports as cancelled (no `score` field) is skipped rather than guessing a
  cancellation message from a field name this project hasn't confirmed.
- **Hockey & Volleyball sub-tabs** (added 2026-10-06): sportId 2 (Ice
  Hockey) and 6 (Volleyball), picked from the full list of sports confirmed
  directly from the docs' own "Справочник спортов" example response (which
  also reconfirmed Football=1, Basketball=3, Tennis=4). That response also
  listed Baseball=5 and Rugby=7, not added this round. Every sport beyond
  football now does three fetches per geo (upcoming, live, results) with
  deliberately small limits (see `SPORTS` in `onexbet_odds.py`) to try to
  keep a full 5-sport × 7-geo run inside the 30-minute schedule — this is
  noticeably tighter than the 3-sport version and is worth watching on the
  first few live runs.
