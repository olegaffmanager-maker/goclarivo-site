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
