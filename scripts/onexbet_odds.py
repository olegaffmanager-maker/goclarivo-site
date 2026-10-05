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
        "pending": "Sincronización automática pendiente — los datos en vivo aparecerán aquí tras la primera actualización.",
        "unavailable": "Datos en vivo no disponibles en este momento. Mostrando la última actualización confirmada." ,
        "no_matches": "No hay partidos próximos disponibles en este momento.",
        "updated": "Última sincronización",
        "vs": "vs",
    },
    "en": {
        "title": "Upcoming matches & odds (1xBet)",
        "pending": "Automatic sync pending — live data will appear here after the first update.",
        "unavailable": "Live data temporarily unavailable. Showing the last confirmed update.",
        "no_matches": "No upcoming matches available right now.",
        "updated": "Last synced",
        "vs": "vs",
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


def _is_virtual_tournament(name):
    if not name:
        return False
    lowered = name.lower()
    return any(kw in lowered for kw in VIRTUAL_TOURNAMENT_KEYWORDS)


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


def fetch_upcoming_football_matches(session, token, ref, gr, lng, limit=4,
                                     max_tournaments=15, max_candidate_events=20,
                                     request_delay=1.2, debug_dir=None):
    """Returns up to `limit` upcoming (startDate > now) football matches with
    1X2 odds, soonest first. Never raises for "no matches found" -- returns
    an empty list in that case. Raises OnexbetError on actual API/auth
    failures so the caller can decide to keep the previous widget content
    rather than overwrite it with a blank/wrong state."""
    base_params = {"ref": ref}
    if gr:
        base_params["gr"] = gr

    tournaments = api_get(
        session, token, "/datafeed/loadtree/prematch/api/v1/tournaments",
        {**base_params, "SportId": FOOTBALL_SPORT_ID, "lng": lng},
        debug_dir, f"tournaments_{lng}.json",
    )
    items = tournaments.get("items", tournaments) if isinstance(tournaments, dict) else tournaments
    if not items:
        return []
    items = [t for t in items if not _is_virtual_tournament(t.get("tournamentNameLocalization"))]
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
                debug_dir, f"sporteventIds_{tid}.json",
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
                {**base_params, "sportEventId": event_id, "schemeOfGettingOdds": "Get1X2Odds", "lng": lng},
                debug_dir, f"sporteventDetail_{event_id}_{lng}.json",
            )
        except OnexbetError:
            continue
        start_date = detail.get("startDate")
        if not start_date or start_date <= now:
            continue
        odds = detail.get("oddsLocalization") or []
        odds_rows = [
            {"label": o.get("display"), "value": o.get("oddsMarket")}
            for o in odds
            if o.get("display") and o.get("oddsMarket") is not None and not o.get("isBlocked")
        ]
        if not odds_rows:
            continue
        matches.append({
            "tournament": detail.get("tournamentNameLocalization", ""),
            "opp1": detail.get("opponent1NameLocalization", "?"),
            "opp2": detail.get("opponent2NameLocalization", "?"),
            "img1": _opponent_image_url(detail.get("imageOpponent1")),
            "img2": _opponent_image_url(detail.get("imageOpponent2")),
            "start_date": start_date,
            "link": detail.get("link"),
            "odds": odds_rows,
        })

    matches.sort(key=lambda m: m["start_date"])
    return matches[:limit]


def render_widget_html(lang, matches, updated_at_iso, state):
    """state: 'ok' | 'pending' | 'unavailable' | 'empty'. Never fabricates a
    match -- 'pending'/'unavailable'/'empty' all render an honest text
    message instead of invented fixtures."""
    t = WIDGET_TEXT[lang]
    esc = html.escape

    if state == "pending":
        body = f'<div class="odds-widget-slot">{esc(t["pending"])}</div>'
    elif state == "unavailable":
        body = f'<div class="odds-widget-slot">{esc(t["unavailable"])}</div>'
    elif state == "empty" or not matches:
        body = f'<div class="odds-widget-slot">{esc(t["no_matches"])}</div>'
    else:
        def logo_img(url, name):
            # Never fabricates a logo: renders a plain placeholder circle
            # (no image) if the API didn't return one for this team, and
            # silently hides itself (onerror) rather than showing a
            # broken-image icon if the CDN 404s for some team.
            box = (
                "width:24px;height:24px;flex:0 0 24px;border-radius:6px;"
                "background:#fff;display:flex;align-items:center;justify-content:center;"
            )
            if not url:
                initial = esc(name[:1].upper()) if name else "?"
                return (
                    f'<div style="{box}color:#99a1ae;font-size:11px;font-weight:700;">{initial}</div>'
                )
            return (
                f'<img src="{esc(url)}" alt="" width="24" height="24" loading="lazy" '
                f'style="{box}object-fit:contain;padding:2px;" '
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

        rows = []
        for m in matches:
            dt = datetime.fromtimestamp(m["start_date"], tz=timezone.utc).strftime("%d.%m %H:%M UTC")
            pills = [odds_pill(o["label"], f'{o["value"]:.2f}') for o in m["odds"][:3]]
            odds_html = f'<div style="display:flex;gap:6px;flex-shrink:0;">{"".join(pills)}</div>'
            tourn_text = f'{esc(m["tournament"])} · {dt}' if m["tournament"] else dt
            tourn = f'<div style="color:var(--text-dim);font-size:11px;margin-bottom:8px;">{tourn_text}</div>'
            team_row = lambda url, name: (
                f'<div style="display:flex;align-items:center;gap:8px;">'
                f'{logo_img(url, name)}'
                f'<span style="font-size:13px;color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">{esc(name)}</span>'
                f'</div>'
            )
            teams = (
                f'<div style="display:flex;flex-direction:column;gap:6px;min-width:0;flex:1;">'
                f'{team_row(m.get("img1"), m["opp1"])}'
                f'{team_row(m.get("img2"), m["opp2"])}'
                f'</div>'
            )
            body_row = (
                f'<div style="padding:12px 0;border-bottom:1px dashed var(--border);">'
                f'{tourn}'
                f'<div style="display:flex;align-items:center;justify-content:space-between;gap:10px;">{teams}{odds_html}</div>'
                f'</div>'
            )
            rows.append(body_row)
        updated_line = f'<div style="margin-top:8px;font-size:11px;color:var(--text-dim);">{esc(t["updated"])}: {esc(updated_at_iso)}</div>'
        body = f'<div class="odds-widget-slot" style="border-style:solid;">{"".join(rows)}{updated_line}</div>'

    return (
        f'{MARKER_START}\n'
        f'<div style="margin-top:10px;font-size:11px;font-weight:700;letter-spacing:.04em;'
        f'text-transform:uppercase;color:var(--text-dim);">{esc(t["title"])}</div>\n'
        f'{body}\n'
        f'{MARKER_END}'
    )


def inject_widget(html_text, widget_html):
    start_idx = html_text.find(MARKER_START)
    end_idx = html_text.find(MARKER_END)
    if start_idx == -1 or end_idx == -1:
        raise OnexbetError(
            "markers not found in page — run scaffold_widget_markers.py first "
            "to insert them into the 1xBet card on this page"
        )
    end_idx += len(MARKER_END)
    return html_text[:start_idx] + widget_html + html_text[end_idx:]


def update_geo_page(site_root, geo, widget_html):
    path = os.path.join(site_root, geo, "sports", "index.html")
    with open(path, encoding="utf-8") as f:
        src = f.read()
    new_src = inject_widget(src, widget_html)
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
        print(f"[{geo}] fetching upcoming football matches (lng={lang})...")
        try:
            matches = fetch_upcoming_football_matches(
                session, token, ref, gr, lang,
                debug_dir=(os.path.join(args.debug_dir, geo) if args.debug_dir else None),
            )
            state = "ok" if matches else "empty"
        except OnexbetError as e:
            print(f"[{geo}] API error, leaving existing widget untouched: {e}", file=sys.stderr)
            any_failed = True
            continue  # do NOT overwrite a working widget with an error state

        widget_html = render_widget_html(lang, matches, updated_at_iso, state)

        if args.dry_run:
            print(f"--- {geo} widget preview ---")
            print(widget_html)
            continue

        try:
            changed = update_geo_page(args.site_root, geo, widget_html)
            print(f"[{geo}] {'updated' if changed else 'no change'} ({len(matches)} matches)")
        except (OnexbetError, FileNotFoundError) as e:
            print(f"[{geo}] failed to write page: {e}", file=sys.stderr)
            any_failed = True

    if any_failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
