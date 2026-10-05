#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GoClarivo — periodic rebuild: "Upcoming matches & odds" widget sourced from
the 1xBet Marketing API, for the /{geo}/sports/ pages.

Owner decision (2026-10-05): render only a lightweight widget inside the
existing real-partner (1xBet) card on each ONEXBET_GEOS page, reusing the
already-defined-but-unused `.odds-widget-slot` CSS hook (see
sports_content.py's header comment: "3 of the 10 slots additionally carry a
clearly marked empty odds widget container"). Marker-based injection is used
instead of the one-off anchor-replace pattern used for the Spinania/NFS
cards, because this script is meant to run unattended and repeatedly (via a
scheduled GitHub Actions workflow) -- a marker is idempotent; a plain
anchor-replace is not (it would fail the second time it runs, because the
"old" text it looks for no longer exists after the first successful run).

Data source confirmed directly against the live API docs
(https://docs-marketing-sport.com/api, 2026-10-05) via an authenticated
browser session -- NOT guessed. Specifically:
  - OAuth2 token: POST https://cpservm.com/gateway/token (form-urlencoded
    client_id + client_secret) -> {"access_token": "...", "expires_in": N}
  - Football tournaments: GET /datafeed/loadtree/prematch/api/v1/tournaments
    ?ref={ref}&SportId=1&lng={lng}  (sportId=1 = Football, confirmed from
    the Results section's sports list example: {"id":1,"name":"Football"})
  - Main event ids per tournament: GET
    /datafeed/loadtree/prematch/api/v1/sporteventIds?ref={ref}&tournamentId={id}
  - Event detail + odds together: GET
    /datafeed/loadtree/prematch/api/v1/sporteventDetail?ref={ref}
    &sportEventId={id}&schemeOfGettingOdds=Get1X2Odds&lng={lng}
    Each odds item's "display" field is ALREADY the localized, ready-to-show
    label ("Localized market name for display on the client side" per the
    Market schema) -- so this script shows {display}: {oddsMarket} verbatim
    rather than guessing what a numeric market "type" id means. No odds
    value, team name or market label is invented; if the API call fails or
    returns nothing usable, the widget falls back to an honest
    "temporarily unavailable" state -- it never fabricates a match.
  - Club/opponent logos (added 2026-10-05, also confirmed from the live docs,
    not guessed): sporteventDetail returns imageOpponent1/imageOpponent2 as
    filenames; the docs' "Загрузка изображений" page documents the download
    URL pattern as https://nimblecd.com/sfiles/logo_teams/{filename}. If the
    API doesn't return a filename for a team, no logo is rendered for it --
    never a placeholder/fake badge.
  - Clickable match cards (added 2026-10-05): sporteventDetail already
    includes a "link" field (the match's page on the bookmaker's own site)
    that the widget fetched but never used. Each card is now wrapped in that
    link when present -- never a fabricated or guessed URL, and a match
    whose detail happens not to include a link simply renders as a plain,
    non-clickable card instead of linking somewhere wrong.
  - Live ("in-play") matches (added 2026-10-05, same confirmed-against-docs
    standard as everything else here): the API has a SEPARATE feed for
    matches currently being played, mirroring the prematch one path-for-path
    under /datafeed/loadtree/live/api/v1/ instead of .../prematch/api/v1/
    (tournaments -> sporteventIds -> sporteventDetail). The live
    sporteventDetail additionally returns curScore ({"sc1":N,"sc2":N}) and
    currentPeriodName/timeSec. The widget shows curScore and currentPeriodName
    exactly as returned, and timeSec truncated to whole minutes (timeSec//60)
    -- it never estimates or interpolates a score or a match clock itself.
    A failure fetching the live feed never blocks the (already-working)
    upcoming-matches widget -- it just means no "live now" section that run,
    same no-fabrication-on-failure rule as everywhere else in this script.
  - Basketball & Tennis sub-tabs (added 2026-10-05, owner request): the
    exact same tournaments -> sporteventIds -> sporteventDetail path works
    for any sportId, prematch and live alike -- nothing sport-specific in
    the API shape itself. sportId 3 (Basketball) and sportId 4 (Tennis) are
    confirmed directly from the docs, not guessed: 3 appears in the
    LoadSingle "vids" parameter note ("3 (Баскетбол) ... "), and 4 appears
    as the sportId on the Tennis sporteventDetail response sample ("ITF.
    Santa Margherita di Pula. Women"). See the SPORTS list below -- each
    sport gets its own page section (build_sports.py renders them as
    CSS-only sub-tabs) and its own marker pair, fetched and injected
    independently so one sport's API trouble never blocks another's.
    Basketball/tennis get smaller max_tournaments/max_candidate_events than
    football (see SPORTS) since they're secondary content and every sport
    now does two fetches (upcoming + live) -- keeping their footprint small
    is what keeps a full 3-sport x 7-geo run inside the 30-minute schedule.
  - Virtual/esports filter extended to every sport (2026-10-06): the
    basketball live feed was observed showing a real match: "NBA 2K26. Cyber
    League" with "Detroit Pistons (cyber)" vs "Milwaukee Bucks (cyber)" --
    confirmed virtual/esports content under sportId 3, not real basketball.
    Separately, the docs' OWN example response for the sports-with-results
    endpoint also shows a tournament "NBA 2K21. Cyber ..." under sportId 3.
    Two independent, directly-observed confirmations that virtual/esports
    content isn't confined to football -- it can appear under any sport's
    normal sportId, not a separate dedicated id. VIRTUAL_TOURNAMENT_KEYWORDS
    is therefore now applied to every sport in SPORTS, not football alone.
    The keyword list itself is unchanged (still not guessed): "cyber" is
    what actually caught both observed cases above.
  - More markets per card (added 2026-10-06, owner request): sporteventDetail
    is now requested with schemeOfGettingOdds=GetAllOdds instead of
    Get1X2Odds, returning every market instead of just the three 1X2
    outcomes. Which extra markets to show is NOT guessed from market names --
    it's matched against the API's own "Справочник маркетов" (Market
    dictionary, GET /datafeed/directories/api/v2/sportevents) confirmed
    directly from its documented example response: id 1/2/3 = W1/X/W2 (the
    existing 1X2 pills), 7/8 = Handicap 1/Handicap 2, 9/10 = Total
    Over/Total Under. Each oddsLocalization item's own `type` field (per the
    deeplink endpoint's docs: "type ... oddsLocalization.type из ответа
    метода получения маркетов") is matched against these confirmed ids; see
    _extract_odds(). As always, every pill's label is the API's own
    already-localized `display` text, never relabeled. A match missing a
    given market (e.g. no total offered) just shows fewer pills; only a
    missing 1X2 line disqualifies the match from the widget entirely, same
    as before.
  - "Recent results" section (added 2026-10-06, owner request): sourced from
    the API's separate Results feed (/result/api/v1/..., confirmed from the
    docs as its own path, distinct from LoadSingle/LoadList/LoadTree), via
    /result/api/v1/tournaments (sports/tournaments with finished matches in
    a date window) then /result/api/v1/sportevents (per tournament, the
    matches' final score). Field names (opponent1NameLocalization, score as
    a single string like "2:1 (1:1,0:0,1:0)", startDate, imageOpponent1/2,
    type, vid) are confirmed directly from the docs' own expanded example
    response for that endpoint -- not guessed. The Results API caps a single
    dateFrom/dateTo window to 48 hours; this script looks back 47 hours. A
    finished match the API reports as cancelled (no score field) is skipped
    rather than inventing a cancellation message from an unconfirmed field
    name. Only type=1/vid=1 (the main match-result event) is used.
  - Hockey & Volleyball sub-tabs (added 2026-10-06, owner request, picked
    from a list of docs-confirmed sports): sportId 2 (Ice Hockey) and
    sportId 6 (Volleyball), both confirmed directly from the docs' own
    example response for "Справочник спортов" (GET
    /datafeed/directories/api/v2/sports), the same example that reconfirmed
    1=Football, 3=Basketball, 4=Tennis exactly as already used. Same small
    per-sport fetch budgets as basketball/tennis, for the same reason: every
    additional sport (now x3 fetches each: upcoming, live, results) adds to
    total run time, which already approached the 30-minute schedule window
    at 3 sports -- this should be watched after the first run with 5.

ref and gr: ref is required (ID партнёра, "уточнять у менеджера"); gr is
needed only for the video-availability flag and the deeplink host, not for
getting odds/matches, so this script treats ONEXBET_REF as required and
ONEXBET_GR as optional. As of 2026-10-05 the manager had NOT confirmed
either value for this account (gr explicitly refused: "в мануале ищут
пусть"; ref not resolved either) -- running this for real requires
ONEXBET_REF to be set to the account's real confirmed value, never the
OpenAPI doc's example default (1), which belongs to a different account.

Usage:
    python scripts/onexbet_odds.py --dry-run     # fetch + print only, no HTML writes
    python scripts/onexbet_odds.py --debug-dir out/  # also dump raw JSON responses
    python scripts/onexbet_odds.py                # fetch + update all ONEXBET_GEOS pages

Required environment variables (see .env.example):
    ONEXBET_CLIENT_ID, ONEXBET_CLIENT_SECRET, ONEXBET_REF
Optional:
    ONEXBET_GR, ONEXBET_TOKEN_URL, ONEXBET_API_BASE, SITE_ROOT
"""
import argparse
import html
import json
import os
import sys
import time
from datetime import datetime, timezone

try:
    import requests
except ImportError:
    sys.exit("Missing dependency: pip install requests")

TOKEN_URL = os.environ.get("ONEXBET_TOKEN_URL", "https://cpservm.com/gateway/token")
API_BASE = os.environ.get("ONEXBET_API_BASE", "https://cpservm.com/gateway/marketing")
FOOTBALL_SPORT_ID = 1  # confirmed: Results > "Спорты с доступными результатами" example {"id":1,"name":"Football"}

# Club/opponent logo CDN, confirmed directly from the live docs'
# "Загрузка изображений" page (https://docs-marketing-sport.com/intro/downloads,
# checked 2026-10-05): GET https://nimblecd.com/sfiles/{logo_path}/{image},
# logo_path is "logo_teams" for opponents and "logo-champ" for tournaments.
# {image} is exactly the filename sporteventDetail returns in
# imageOpponent1/imageOpponent2 (e.g. "295169.png"). Not guessed -- this is
# the documented download URL pattern.
IMAGE_BASE = "https://nimblecd.com/sfiles"

# Geos that carry the real 1xBet partner card (sports_content.py ONEXBET_GEOS),
# each mapped to the language its /sports/ page is written in and the API
# "lng" code to request localized tournament/market text in.
GEO_LANG = {
    "es": "es", "mx": "es", "ar": "es", "pe": "es", "bo": "es", "py": "es",
    "en": "en",
}

WIDGET_TEXT = {
    "es": {
        "title": "Próximos partidos y cuotas (1xBet)",
        "live_badge": "En vivo",
        "powered_by": "Datos de 1xBet",
        "pending": "Sincronización automática pendiente — los datos en vivo aparecerán aquí tras la primera actualización.",
        "unavailable": "Datos en vivo no disponibles en este momento. Mostrando la última actualización confirmada." ,
        "no_matches": "No hay partidos próximos disponibles en este momento.",
        "updated": "Última sincronización",
        "vs": "vs",
        "live_now_heading": "En vivo ahora",
        "upcoming_heading": "Próximos partidos",
        "recent_results_heading": "Resultados recientes",
    },
    "en": {
        "title": "Upcoming matches & odds (1xBet)",
        "live_badge": "Live",
        "powered_by": "Data by 1xBet",
        "pending": "Automatic sync pending — live data will appear here after the first update.",
        "unavailable": "Live data temporarily unavailable. Showing the last confirmed update.",
        "no_matches": "No upcoming matches available right now.",
        "updated": "Last synced",
        "vs": "vs",
        "live_now_heading": "Live now",
        "upcoming_heading": "Upcoming matches",
        "recent_results_heading": "Recent results",
    },
}

MARKER_START = "<!-- ONEXBET_ODDS_WIDGET:START -->"
MARKER_END = "<!-- ONEXBET_ODDS_WIDGET:END -->"


class OnexbetError(RuntimeError):
    pass


#  Owner decision (2026-10-05): the API's Football tournament list (SportId=1)
#  also includes virtual/esports simulated leagues (confirmed live: a real
#  pull returned "Esoccer Battle Volta" -- gamers playing FIFA under
#  nicknames, running almost around the clock, which crowded out real
#  matches from the "soonest upcoming" list). Owner asked these excluded so
#  the widget only ever shows real-world football. This is a conservative
#  name-keyword filter, not a documented API flag (the docs don't expose an
#  "is this virtual" field on the LoadTree tournaments response) -- it may
#  need a keyword added later if another virtual-league name slips through.
VIRTUAL_TOURNAMENT_KEYWORDS = (
    "esoccer", "e-soccer", "efootball", "e-football", "cyber", "cybersport",
    "battle", "virtual football", "gt league", "fifa",
)


def _is_virtual_tournament(name, keywords):
    # keywords is None only if a caller explicitly opts a sport out (no
    # sport currently does -- see SPORTS below, 2026-10-06: the filter now
    # applies everywhere, see module docstring for why).
    if not keywords or not name:
        return False
    lowered = name.lower()
    return any(kw in lowered for kw in keywords)


# Market type IDs from the API's own "Справочник маркетов" (Market
# dictionary, GET /datafeed/directories/api/v2/sportevents), confirmed
# directly from its documented example response (not guessed):
#   1=W1, 2=X, 3=W2           -- the three 1X2 outcomes (already used)
#   4=1X, 5=12, 6=2X          -- double chance (unused -- not asked for)
#   7=Handicap 1, 8=Handicap 2
#   9=Total Over, 10=Total Under
MARKET_TYPE_1X2 = (1, 2, 3)
MARKET_TYPE_HANDICAP = (7, 8)
MARKET_TYPE_TOTAL = (9, 10)


def _extract_odds(odds_items):
    """Builds the pill list for a match card from the API's own
    oddsLocalization array (requested with schemeOfGettingOdds=GetAllOdds,
    which returns every market, not just 1X2 -- see module docstring).
    Returns (main_rows, extra_rows): main_rows is the 1X2 pills (same as
    before), extra_rows is Handicap 1/2 and Total Over/Under, each taken as
    the FIRST line the API lists for that market type -- this script doesn't
    pick a "preferred" handicap/total line itself. Every label is the API's
    own already-localized `display` text, verbatim, never relabeled."""
    usable = [
        o for o in odds_items
        if o.get("display") and o.get("oddsMarket") is not None and not o.get("isBlocked")
    ]
    by_type = {}
    for o in usable:
        t = o.get("type")
        if t not in by_type:  # first occurrence only, per market type
            by_type[t] = o

    def rows_for(type_ids):
        return [
            {"label": by_type[t]["display"], "value": by_type[t]["oddsMarket"]}
            for t in type_ids if t in by_type
        ]

    return rows_for(MARKET_TYPE_1X2), rows_for(MARKET_TYPE_HANDICAP + MARKET_TYPE_TOTAL)


# Sports the widget covers, confirmed directly from the live docs (not
# guessed): sportId 1 (Football), 3 (Basketball), 4 (Tennis) were already
# confirmed (see module docstring); sportId 2 (Ice Hockey) and 6 (Volleyball)
# were added 2026-10-06, confirmed the same way, from the docs' own example
# response for "Справочник спортов" (/datafeed/directories/api/v2/sports),
# which also reconfirmed 1/3/4 exactly. The owner picked hockey + volleyball
# from the full confirmed list (which also included Baseball=5, Rugby=7).
#
# The virtual/esports keyword filter now applies to every sport (2026-10-06
# -- see module docstring for the two independent confirmations that led to
# this, one of them basketball itself).
#
# max_tournaments/max_candidate_events/limit are intentionally smaller than
# football's for every other sport: they're secondary/bonus sections and
# every sport now does THREE fetches (upcoming, live, results), so keeping
# their footprint small is what keeps the whole run inside the 30-minute
# schedule -- this got noticeably tighter going from 3 to 5 sports plus the
# new results fetch, so run time is worth watching after the first live run.
_SECONDARY_BUDGET = dict(
    upcoming=dict(limit=3, max_tournaments=6, max_candidate_events=8, request_delay=0.8),
    live=dict(limit=2, max_tournaments=5, max_candidate_events=6, request_delay=0.8),
    results=dict(limit=2, max_tournaments=3, request_delay=0.8),
)
SPORTS = [
    {
        "key": "football", "sport_id": FOOTBALL_SPORT_ID,
        "virtual_keywords": VIRTUAL_TOURNAMENT_KEYWORDS, "icon": "⚽",
        "upcoming": dict(limit=4, max_tournaments=15, max_candidate_events=20, request_delay=1.2),
        "live": dict(limit=3, max_tournaments=10, max_candidate_events=12, request_delay=1.2),
        "results": dict(limit=2, max_tournaments=3, request_delay=1.0),
    },
    {
        "key": "basketball", "sport_id": 3,
        "virtual_keywords": VIRTUAL_TOURNAMENT_KEYWORDS, "icon": "\U0001f3c0",
        **_SECONDARY_BUDGET,
    },
    {
        "key": "tennis", "sport_id": 4,
        "virtual_keywords": VIRTUAL_TOURNAMENT_KEYWORDS, "icon": "\U0001f3be",
        **_SECONDARY_BUDGET,
    },
    {
        "key": "hockey", "sport_id": 2,
        "virtual_keywords": VIRTUAL_TOURNAMENT_KEYWORDS, "icon": "\U0001f3d2",
        **_SECONDARY_BUDGET,
    },
    {
        "key": "volleyball", "sport_id": 6,
        "virtual_keywords": VIRTUAL_TOURNAMENT_KEYWORDS, "icon": "\U0001f3d0",
        **_SECONDARY_BUDGET,
    },
]


def _opponent_image_url(image_field):
    """image_field is the raw imageOpponent1/imageOpponent2 value from the
    API -- a list of filenames (sometimes containing null), sometimes
    missing entirely. Returns a full downloadable URL for the first real
    filename found, or None if there isn't one (never fabricates a logo)."""
    if not image_field:
        return None
    for name in image_field:
        if name:
            return f"{IMAGE_BASE}/logo_teams/{name}"
    return None


def get_token(session, client_id, client_secret):
    resp = session.post(
        TOKEN_URL,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data={"client_id": client_id, "client_secret": client_secret},
        timeout=15,
    )
    if resp.status_code != 200:
        raise OnexbetError(f"token request failed: HTTP {resp.status_code}: {resp.text[:300]}")
    data = resp.json()
    if "access_token" not in data:
        raise OnexbetError(f"token response missing access_token: {data}")
    return data["access_token"]


def api_get(session, token, path, params, debug_dir=None, debug_name=None):
    url = API_BASE + path
    resp = session.get(url, headers={"Authorization": f"Bearer {token}"}, params=params, timeout=20)
    if debug_dir and debug_name:
        os.makedirs(debug_dir, exist_ok=True)
        with open(os.path.join(debug_dir, debug_name), "w", encoding="utf-8") as f:
            f.write(f"GET {resp.url}\nHTTP {resp.status_code}\n\n{resp.text}")
    if resp.status_code == 403:
        raise OnexbetError(
            f"403 from {path} — check ref/gr are correct (ask the 1xBet account manager), "
            f"or this ref doesn't have access to this method yet. Body: {resp.text[:300]}"
        )
    if resp.status_code != 200:
        raise OnexbetError(f"{path} failed: HTTP {resp.status_code}: {resp.text[:300]}")
    try:
        return resp.json()
    except ValueError:
        raise OnexbetError(f"{path} did not return JSON: {resp.text[:300]}")


def fetch_upcoming_matches(session, token, ref, gr, lng, sport_id, virtual_keywords=None,
                            limit=4, max_tournaments=15, max_candidate_events=20,
                            request_delay=1.2, debug_dir=None, debug_prefix=""):
    """Returns up to `limit` upcoming (startDate > now) matches with 1X2 odds
    for the given sport_id, soonest first. Never raises for "no matches
    found" -- returns an empty list in that case. Raises OnexbetError on
    actual API/auth failures so the caller can decide to keep the previous
    widget content rather than overwrite it with a blank/wrong state."""
    base_params = {"ref": ref}
    if gr:
        base_params["gr"] = gr

    tournaments = api_get(
        session, token, "/datafeed/loadtree/prematch/api/v1/tournaments",
        {**base_params, "SportId": sport_id, "lng": lng},
        debug_dir, f"{debug_prefix}tournaments_{lng}.json",
    )
    items = tournaments.get("items", tournaments) if isinstance(tournaments, dict) else tournaments
    if not items:
        return []
    items = [t for t in items if not _is_virtual_tournament(t.get("tournamentNameLocalization"), virtual_keywords)]
    if not items:
        return []

    candidate_event_ids = []
    for t in items[:max_tournaments]:
        tid = t.get("tournamentId")
        if tid is None:
            continue
        time.sleep(request_delay)
        try:
            ev = api_get(
                session, token, "/datafeed/loadtree/prematch/api/v1/sporteventIds",
                {**base_params, "tournamentId": tid},
                debug_dir, f"{debug_prefix}sporteventIds_{tid}.json",
            )
        except OnexbetError:
            continue  # one bad tournament shouldn't kill the whole run
        ev_items = ev.get("items", []) if isinstance(ev, dict) else (ev or [])
        candidate_event_ids.extend(ev_items)
        if len(candidate_event_ids) >= max_candidate_events:
            break

    now = int(time.time())
    matches = []
    for event_id in candidate_event_ids[:max_candidate_events]:
        time.sleep(request_delay)
        try:
            detail = api_get(
                session, token, "/datafeed/loadtree/prematch/api/v1/sporteventDetail",
                {**base_params, "sportEventId": event_id, "schemeOfGettingOdds": "GetAllOdds", "lng": lng},
                debug_dir, f"{debug_prefix}sporteventDetail_{event_id}_{lng}.json",
            )
        except OnexbetError:
            continue
        start_date = detail.get("startDate")
        if not start_date or start_date <= now:
            continue
        odds = detail.get("oddsLocalization") or []
        main_odds, extra_odds = _extract_odds(odds)
        if not main_odds:
            continue
        matches.append({
            "tournament": detail.get("tournamentNameLocalization", ""),
            "opp1": detail.get("opponent1NameLocalization", "?"),
            "opp2": detail.get("opponent2NameLocalization", "?"),
            "img1": _opponent_image_url(detail.get("imageOpponent1")),
            "img2": _opponent_image_url(detail.get("imageOpponent2")),
            "start_date": start_date,
            "link": detail.get("link"),
            "odds": main_odds + extra_odds,
        })

    matches.sort(key=lambda m: m["start_date"])
    return matches[:limit]


def fetch_live_matches(session, token, ref, gr, lng, sport_id, virtual_keywords=None,
                        limit=3, max_tournaments=10, max_candidate_events=12,
                        request_delay=1.2, debug_dir=None, debug_prefix=""):
    """Mirrors fetch_upcoming_matches but against the API's SEPARATE live
    ("in-play") feed (/datafeed/loadtree/live/api/v1/... instead of
    .../prematch/api/v1/...) -- confirmed from the docs as its own parallel
    tournaments -> sporteventIds -> sporteventDetail path, not a filter on
    the prematch one. Returns up to `limit` currently-live matches with
    curScore/currentPeriodName/timeSec exactly as the API returns them.
    Never raises for "nothing live right now" -- returns an empty list.
    Raises OnexbetError only on actual API/auth failures; the caller treats
    that as "no live matches to show this run" rather than blocking the
    (already-working) upcoming-matches widget -- live is a bonus layered on
    top, not a required piece."""
    base_params = {"ref": ref}
    if gr:
        base_params["gr"] = gr

    tournaments = api_get(
        session, token, "/datafeed/loadtree/live/api/v1/tournaments",
        {**base_params, "SportId": sport_id, "lng": lng},
        debug_dir, f"{debug_prefix}live_tournaments_{lng}.json",
    )
    items = tournaments.get("items", tournaments) if isinstance(tournaments, dict) else tournaments
    if isinstance(items, dict):
        items = [items]  # docs show a single live tournament returned as a bare object, not a list
    if not items:
        return []
    items = [t for t in items if not _is_virtual_tournament(t.get("tournamentNameLocalization"), virtual_keywords)]
    if not items:
        return []

    candidate_event_ids = []
    for t in items[:max_tournaments]:
        tid = t.get("tournamentId")
        if tid is None:
            continue
        time.sleep(request_delay)
        try:
            ev = api_get(
                session, token, "/datafeed/loadtree/live/api/v1/sporteventIds",
                {**base_params, "tournamentId": tid},
                debug_dir, f"{debug_prefix}live_sporteventIds_{tid}.json",
            )
        except OnexbetError:
            continue  # one bad tournament shouldn't kill the whole run
        ev_items = ev.get("items", []) if isinstance(ev, dict) else (ev or [])
        candidate_event_ids.extend(ev_items)
        if len(candidate_event_ids) >= max_candidate_events:
            break

    matches = []
    for event_id in candidate_event_ids[:max_candidate_events]:
        time.sleep(request_delay)
        try:
            detail = api_get(
                session, token, "/datafeed/loadtree/live/api/v1/sporteventDetail",
                {**base_params, "sportEventId": event_id, "schemeOfGettingOdds": "Get1X2Odds", "lng": lng},
                debug_dir, f"{debug_prefix}live_sporteventDetail_{event_id}_{lng}.json",
            )
        except OnexbetError:
            continue
        cur_score = detail.get("curScore") or {}
        matches.append({
            "tournament": detail.get("tournamentNameLocalization", ""),
            "opp1": detail.get("opponent1NameLocalization", "?"),
            "opp2": detail.get("opponent2NameLocalization", "?"),
            "img1": _opponent_image_url(detail.get("imageOpponent1")),
            "img2": _opponent_image_url(detail.get("imageOpponent2")),
            "sc1": cur_score.get("sc1"),
            "sc2": cur_score.get("sc2"),
            "period_name": detail.get("currentPeriodName") or "",
            "time_sec": detail.get("timeSec"),
            "link": detail.get("link"),
        })
        if len(matches) >= limit:
            break

    return matches[:limit]


def fetch_recent_results(session, token, ref, gr, lng, sport_id, virtual_keywords=None,
                          limit=2, max_tournaments=3, request_delay=0.8,
                          debug_dir=None, debug_prefix=""):
    """Returns up to `limit` most-recently-finished matches for sport_id,
    most recent first, sourced from the API's SEPARATE Results feed
    (/result/api/v1/..., confirmed from the docs as its own path -- not a
    filter on LoadSingle/LoadList/LoadTree). The Results API caps a single
    dateFrom/dateTo window to 48 hours; this looks back 47 hours (never
    widens the window to find more results). Only type=1/vid=1 events (the
    main match-result event, not a corner/card sub-event) with a `score`
    the API actually returned are included -- a match the API reports as
    cancelled (no score field) is silently skipped rather than guessing a
    cancellation message from an unconfirmed field name. Never raises for
    "nothing finished recently" -- returns an empty list. Raises
    OnexbetError only on actual API/auth failures; same "bonus section,
    never blocks the rest of the page" rule as fetch_live_matches."""
    base_params = {"ref": ref}
    if gr:
        base_params["gr"] = gr
    now = int(time.time())
    date_from, date_to = now - 47 * 3600, now

    tournaments = api_get(
        session, token, "/result/api/v1/tournaments",
        {**base_params, "sportId": sport_id, "dateFrom": date_from, "dateTo": date_to, "lng": lng},
        debug_dir, f"{debug_prefix}results_tournaments_{lng}.json",
    )
    items = tournaments.get("items", tournaments) if isinstance(tournaments, dict) else tournaments
    if not items:
        return []
    items = [t for t in items if not _is_virtual_tournament(t.get("tournamentNameLocalization"), virtual_keywords)]
    if not items:
        return []

    results = []
    for t in items[:max_tournaments]:
        tid = t.get("tournamentId")
        if tid is None:
            continue
        time.sleep(request_delay)
        try:
            ev = api_get(
                session, token, "/result/api/v1/sportevents",
                {**base_params, "tournamentIds": tid, "dateFrom": date_from, "dateTo": date_to, "lng": lng},
                debug_dir, f"{debug_prefix}results_sportevents_{tid}.json",
            )
        except OnexbetError:
            continue  # one bad tournament shouldn't kill the whole run
        ev_items = ev.get("items", []) if isinstance(ev, dict) else (ev or [])
        for e in ev_items:
            if e.get("type") != 1 or e.get("vid") != 1:
                continue
            score = e.get("score")
            if not score:
                continue  # cancelled or otherwise scoreless -- never invent a score/status
            results.append({
                "tournament": t.get("tournamentNameLocalization", ""),
                "opp1": e.get("opponent1NameLocalization", "?"),
                "opp2": e.get("opponent2NameLocalization", "?"),
                "img1": _opponent_image_url(e.get("imageOpponent1")),
                "img2": _opponent_image_url(e.get("imageOpponent2")),
                "score": score,
                "start_date": e.get("startDate") or 0,
            })

    results.sort(key=lambda r: r["start_date"], reverse=True)
    return results[:limit]


def _card_tags(url):
    """A match card links straight to its page on the bookmaker's site when
    the API actually returned a link for it, and stays a plain (non-clickable)
    card otherwise -- never a guessed or fabricated URL. rel="sponsored" is
    the correct annotation for an affiliate/partner link."""
    if not url:
        return '<div class="live-match-card">', '</div>'
    esc = html.escape
    return (
        f'<a class="live-match-card" href="{esc(url)}" target="_blank" '
        f'rel="noopener noreferrer sponsored" style="display:block;text-decoration:none;color:inherit;">',
        '</a>'
    )


def render_widget_html(lang, matches, updated_at_iso, state, live_matches=None, recent_results=None):
    """state: 'ok' | 'pending' | 'unavailable' | 'empty'. Never fabricates a
    match -- 'pending'/'unavailable'/'empty' all render an honest text
    message instead of invented fixtures.

    Owner decision (2026-10-05): live matches are now the main element of
    the /sports/ page (full-width hero section, see build_sports.py's
    _live_matches_section_html), not a small box tucked inside the 1xBet
    ranking card. This renders into that hero section's marker slot using
    the shared-contract CSS classes defined in build_sports.py's
    ODDS_WIDGET_CSS (.live-widget-header / .live-badge-dot /
    .live-matches-grid / .live-match-card / .live-match-message) -- if a
    class name changes on one side, it must change on the other."""
    t = WIDGET_TEXT[lang]
    esc = html.escape
    live_matches = live_matches or []
    has_live = bool(live_matches)
    recent_results = recent_results or []
    has_recent = bool(recent_results)

    # Only claim "live" (pulsing dot + live_badge label) when there is
    # actually a live-now match to show -- a pending/unavailable/empty
    # upcoming state, or simply no match currently in play, still shows the
    # "powered by 1xBet" + last-synced line, but never the live claim, so the
    # header itself never says more than the sections below it.
    if has_live:
        badge_left = (
            f'<div class="badge-left">'
            f'<span class="live-badge-dot"></span>'
            f'<span class="badge-label">{esc(t["live_badge"])}</span>'
            f'<span class="badge-powered">· {esc(t["powered_by"])}</span>'
            f'</div>'
        )
    else:
        badge_left = f'<div class="badge-left"><span class="badge-powered">{esc(t["powered_by"])}</span></div>'
    header = (
        f'<div class="live-widget-header">'
        f'{badge_left}'
        f'<div class="badge-updated">{esc(t["updated"])}: {esc(updated_at_iso)}</div>'
        f'</div>'
    )

    def logo_img(url, name):
        # Never fabricates a logo: renders a plain placeholder circle (no
        # image) if the API didn't return one for this team, and silently
        # hides itself (onerror) rather than showing a broken-image icon if
        # the CDN 404s for some team.
        box = (
            "width:28px;height:28px;flex:0 0 28px;border-radius:7px;"
            "background:#fff;display:flex;align-items:center;justify-content:center;"
        )
        if not url:
            initial = esc(name[:1].upper()) if name else "?"
            return f'<div style="{box}color:#99a1ae;font-size:12px;font-weight:700;">{initial}</div>'
        return (
            f'<img src="{esc(url)}" alt="" width="28" height="28" loading="lazy" '
            f'style="{box}object-fit:contain;padding:3px;" '
            f'onerror="this.style.display=\'none\'">'
        )

    def odds_pill(label, value):
        return (
            f'<div style="text-align:center;background:var(--bg-2);border:1px solid var(--border);'
            f'border-radius:6px;padding:4px 9px;min-width:40px;">'
            f'<div style="font-size:10px;color:var(--text-dim);line-height:1.4;">{esc(str(label))}</div>'
            f'<div style="font-size:13px;font-weight:700;color:var(--text);line-height:1.4;">{esc(value)}</div>'
            f'</div>'
        )

    def section_heading(text, first):
        margin = "0" if first else "20px"
        return (
            f'<div style="font-size:12px;font-weight:700;letter-spacing:.03em;text-transform:uppercase;'
            f'color:var(--text-dim);margin:{margin} 0 10px;">{esc(text)}</div>'
        )

    sections = []

    if has_live:
        live_cards = []
        for m in live_matches:
            # timeSec is truncated to whole minutes, not estimated/interpolated
            # -- a direct, honest transformation of the API's own field.
            minutes = None
            if m.get("time_sec") is not None:
                try:
                    minutes = int(m["time_sec"]) // 60
                except (TypeError, ValueError):
                    minutes = None
            meta_bits = [b for b in [m.get("period_name"), f"{minutes}'" if minutes is not None else None] if b]
            meta_text = " · ".join(meta_bits)
            tourn_text = f'{esc(m["tournament"])} · {esc(meta_text)}' if m["tournament"] and meta_text else (esc(m["tournament"]) or esc(meta_text))
            live_tag = (
                f'<div style="display:flex;align-items:center;gap:6px;color:var(--text-dim);font-size:11px;margin-bottom:10px;">'
                f'<span style="width:6px;height:6px;border-radius:50%;background:var(--red);display:inline-block;flex:0 0 6px;"></span>'
                f'<span>{tourn_text}</span>'
                f'</div>'
            )

            def score_row(url, name, score):
                score_html = (
                    f'<span style="font-size:14px;font-weight:700;color:var(--text);min-width:18px;text-align:right;">{esc(str(score))}</span>'
                    if score is not None else ''
                )
                return (
                    f'<div style="display:flex;align-items:center;justify-content:space-between;gap:8px;">'
                    f'<div style="display:flex;align-items:center;gap:8px;min-width:0;">'
                    f'{logo_img(url, name)}'
                    f'<span style="font-size:13px;color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">{esc(name)}</span>'
                    f'</div>{score_html}</div>'
                )

            teams = (
                f'<div style="display:flex;flex-direction:column;gap:8px;">'
                f'{score_row(m.get("img1"), m["opp1"], m.get("sc1"))}'
                f'{score_row(m.get("img2"), m["opp2"], m.get("sc2"))}'
                f'</div>'
            )
            open_tag, close_tag = _card_tags(m.get("link"))
            live_cards.append(f'{open_tag}{live_tag}{teams}{close_tag}')
        sections.append(section_heading(t["live_now_heading"], first=True))
        sections.append(f'<div class="live-matches-grid">{"".join(live_cards)}</div>')

    if state == "pending":
        upcoming_body = f'<div class="live-match-message">{esc(t["pending"])}</div>'
    elif state == "unavailable":
        upcoming_body = f'<div class="live-match-message">{esc(t["unavailable"])}</div>'
    elif state == "empty" or not matches:
        # Don't show a "no upcoming matches" note next to a live section that
        # already has real content -- it would read as a contradiction even
        # though both statements are individually true.
        upcoming_body = None if has_live else f'<div class="live-match-message">{esc(t["no_matches"])}</div>'
    else:
        cards = []
        for m in matches:
            # Teams stack full-width above the odds row (rather than squeezed
            # beside the pills) so a longer club name never gets clipped --
            # the grid column itself is already narrow at 3-up, and real
            # names/pills together don't fit side by side there.
            dt = datetime.fromtimestamp(m["start_date"], tz=timezone.utc).strftime("%d.%m %H:%M UTC")
            # No longer capped to 3: GetAllOdds (see module docstring) can
            # return 1X2 plus Handicap 1/2 and Total Over/Under pills too --
            # wrap rather than overflow a narrow card.
            pills = [odds_pill(o["label"], f'{o["value"]:.2f}') for o in m["odds"]]
            odds_html = f'<div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:10px;">{"".join(pills)}</div>'
            tourn_text = f'{esc(m["tournament"])} · {dt}' if m["tournament"] else dt
            tourn = f'<div style="color:var(--text-dim);font-size:11px;margin-bottom:10px;">{tourn_text}</div>'
            team_row = lambda url, name: (
                f'<div style="display:flex;align-items:center;gap:8px;min-width:0;">'
                f'{logo_img(url, name)}'
                f'<span style="font-size:13px;color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">{esc(name)}</span>'
                f'</div>'
            )
            teams = (
                f'<div style="display:flex;flex-direction:column;gap:8px;">'
                f'{team_row(m.get("img1"), m["opp1"])}'
                f'{team_row(m.get("img2"), m["opp2"])}'
                f'</div>'
            )
            open_tag, close_tag = _card_tags(m.get("link"))
            cards.append(f'{open_tag}{tourn}{teams}{odds_html}{close_tag}')
        upcoming_body = f'<div class="live-matches-grid">{"".join(cards)}</div>'

    if upcoming_body is not None:
        sections.append(section_heading(t["upcoming_heading"], first=not sections))
        sections.append(upcoming_body)

    if has_recent:
        def score_text(score):
            # score looks like "2:1 (1:1,0:0,1:0)" -- the API's own string,
            # shown verbatim; split only to emphasize the final score over
            # the period breakdown, never reinterpreted or recomputed.
            parts = str(score).split(" ", 1)
            return parts[0], (parts[1] if len(parts) > 1 else "")

        recent_cards = []
        for r in recent_results:
            main_score, detail_score = score_text(r["score"])
            tourn = (
                f'<div style="color:var(--text-dim);font-size:11px;margin-bottom:10px;">{esc(r["tournament"])}</div>'
                if r["tournament"] else ""
            )
            team_row = lambda url, name: (
                f'<div style="display:flex;align-items:center;gap:8px;min-width:0;">'
                f'{logo_img(url, name)}'
                f'<span style="font-size:13px;color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">{esc(name)}</span>'
                f'</div>'
            )
            teams = (
                f'<div style="display:flex;flex-direction:column;gap:8px;">'
                f'{team_row(r.get("img1"), r["opp1"])}'
                f'{team_row(r.get("img2"), r["opp2"])}'
                f'</div>'
            )
            detail_html = (
                f'<div style="font-size:10px;color:var(--text-dim);margin-top:2px;">{esc(detail_score)}</div>'
                if detail_score else ""
            )
            score_html = (
                f'<div style="text-align:center;margin-top:10px;">'
                f'<div style="font-size:16px;font-weight:700;color:var(--text);">{esc(main_score)}</div>'
                f'{detail_html}'
                f'</div>'
            )
            # The Results API never returns a "link" field (confirmed from
            # its docs' expanded example response) -- these cards are never
            # clickable, same honest fallback _card_tags already uses for
            # an upcoming/live match the API didn't give a link for.
            open_tag, close_tag = _card_tags(None)
            recent_cards.append(f'{open_tag}{tourn}{teams}{score_html}{close_tag}')
        sections.append(section_heading(t["recent_results_heading"], first=not sections))
        sections.append(f'<div class="live-matches-grid">{"".join(recent_cards)}</div>')

    body = "".join(sections)
    return f'{MARKER_START}\n{header}\n{body}\n{MARKER_END}'


def _widget_markers(sport_key):
    """Football keeps the original, already-deployed marker pair unchanged
    (ONEXBET_ODDS_WIDGET:START/END) so its existing path on the page needs no
    changes. Basketball/tennis (added 2026-10-05, for the per-sport sub-tabs
    on /sports/) get their own marker pair each -- this naming must match
    build_sports.py's _widget_markers() exactly; it's the shared contract
    between the two codebases, duplicated here on purpose (see module
    docstring)."""
    if sport_key == "football":
        return MARKER_START, MARKER_END
    tag = sport_key.upper()
    return f"<!-- ONEXBET_ODDS_WIDGET_{tag}:START -->", f"<!-- ONEXBET_ODDS_WIDGET_{tag}:END -->"


def inject_widget(html_text, widget_html, start_marker=MARKER_START, end_marker=MARKER_END):
    start_idx = html_text.find(start_marker)
    end_idx = html_text.find(end_marker)
    if start_idx == -1 or end_idx == -1:
        raise OnexbetError(
            f"markers {start_marker!r}/{end_marker!r} not found in page — run "
            "scaffold_widget_markers.py (football) or regenerate the page from "
            "build_sports.py (other sports) first"
        )
    end_idx += len(end_marker)
    return html_text[:start_idx] + widget_html + html_text[end_idx:]


def update_geo_page(site_root, geo, widget_html, start_marker=MARKER_START, end_marker=MARKER_END):
    path = os.path.join(site_root, geo, "sports", "index.html")
    with open(path, encoding="utf-8") as f:
        src = f.read()
    new_src = inject_widget(src, widget_html, start_marker, end_marker)
    if new_src == src:
        return False
    with open(path, "w", encoding="utf-8") as f:
        f.write(new_src)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true", help="fetch and print only, never write HTML")
    parser.add_argument("--debug-dir", default=None, help="dump raw API responses here for manual inspection")
    parser.add_argument("--site-root", default=os.environ.get("SITE_ROOT", "goclarivo-site"))
    parser.add_argument("--geos", default=",".join(GEO_LANG.keys()), help="comma-separated geo list to update")
    args = parser.parse_args()

    client_id = os.environ.get("ONEXBET_CLIENT_ID")
    client_secret = os.environ.get("ONEXBET_CLIENT_SECRET")
    ref = os.environ.get("ONEXBET_REF")
    gr = os.environ.get("ONEXBET_GR")

    missing = [n for n, v in [("ONEXBET_CLIENT_ID", client_id), ("ONEXBET_CLIENT_SECRET", client_secret), ("ONEXBET_REF", ref)] if not v]
    if missing:
        sys.exit(f"Missing required environment variable(s): {', '.join(missing)}. "
                  f"See .env.example — ref/gr must be the account's REAL confirmed values from the "
                  f"1xBet manager, never the docs' example default.")

    session = requests.Session()
    try:
        token = get_token(session, client_id, client_secret)
    except OnexbetError as e:
        sys.exit(f"Auth failed, aborting without touching any page: {e}")

    geos = [g.strip() for g in args.geos.split(",") if g.strip()]
    updated_at_iso = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    any_failed = False
    for geo in geos:
        lang = GEO_LANG.get(geo)
        if not lang:
            print(f"[skip] {geo}: not in GEO_LANG map", file=sys.stderr)
            continue

        for sport in SPORTS:
            key = sport["key"]
            start_marker, end_marker = _widget_markers(key)
            debug_dir = os.path.join(args.debug_dir, geo) if args.debug_dir else None

            print(f"[{geo}/{key}] fetching upcoming matches (lng={lang})...")
            try:
                matches = fetch_upcoming_matches(
                    session, token, ref, gr, lang, sport["sport_id"],
                    virtual_keywords=sport["virtual_keywords"],
                    debug_dir=debug_dir, debug_prefix=f"{key}_",
                    **sport["upcoming"],
                )
                state = "ok" if matches else "empty"
            except OnexbetError as e:
                print(f"[{geo}/{key}] API error, leaving existing widget untouched: {e}", file=sys.stderr)
                any_failed = True
                continue  # do NOT overwrite a working widget with an error state -- next sport

            # Live matches are a bonus layered on top of the (already-working)
            # upcoming-matches widget above -- a failure here is logged but
            # never blocks the page update, and just means no "live now"
            # section for this sport this run.
            print(f"[{geo}/{key}] fetching live matches (lng={lang})...")
            try:
                live_matches = fetch_live_matches(
                    session, token, ref, gr, lang, sport["sport_id"],
                    virtual_keywords=sport["virtual_keywords"],
                    debug_dir=debug_dir, debug_prefix=f"{key}_",
                    **sport["live"],
                )
            except OnexbetError as e:
                print(f"[{geo}/{key}] live API error, showing upcoming matches only: {e}", file=sys.stderr)
                live_matches = []

            # Recent results are a bonus layered on top too -- same
            # never-block-the-page rule as live matches above.
            print(f"[{geo}/{key}] fetching recent results (lng={lang})...")
            try:
                recent_results = fetch_recent_results(
                    session, token, ref, gr, lang, sport["sport_id"],
                    virtual_keywords=sport["virtual_keywords"],
                    debug_dir=debug_dir, debug_prefix=f"{key}_",
                    **sport["results"],
                )
            except OnexbetError as e:
                print(f"[{geo}/{key}] results API error, showing without recent results: {e}", file=sys.stderr)
                recent_results = []

            widget_html = render_widget_html(
                lang, matches, updated_at_iso, state,
                live_matches=live_matches, recent_results=recent_results,
            )

            if args.dry_run:
                print(f"--- {geo}/{key} widget preview ---")
                print(widget_html)
                continue

            try:
                changed = update_geo_page(args.site_root, geo, widget_html, start_marker, end_marker)
                print(f"[{geo}/{key}] {'updated' if changed else 'no change'} "
                      f"({len(matches)} upcoming, {len(live_matches)} live, {len(recent_results)} results)")
            except (OnexbetError, FileNotFoundError) as e:
                print(f"[{geo}/{key}] failed to write page: {e}", file=sys.stderr)
                any_failed = True

    if any_failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
