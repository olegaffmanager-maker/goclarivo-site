#!/usr/bin/env python3
"""GoClarivo football section (14 countries + international): upcoming league / national-team / international matches + 1xBet odds
from the 1xBet Marketing API into data/matches.json, finished matches into data/results.json. Engine copied from Buteur.

Never invents data: on API failure the previous data/matches.json is kept untouched;
a match without a complete, unblocked 1X2 line is skipped.

Env: ONEXBET_CLIENT_ID, ONEXBET_CLIENT_SECRET, ONEXBET_REF (required), ONEXBET_GR (optional).
Usage: python scripts/odds.py [--dry-run] [--debug-dir out/]
"""
import argparse, datetime, json, os, sys, time
import requests

TOKEN_URL = os.environ.get("ONEXBET_TOKEN_URL", "https://cpservm.com/gateway/token")
API_BASE = os.environ.get("ONEXBET_API_BASE", "https://cpservm.com/gateway/marketing")
IMAGE_BASE = "https://nimblecd.com/sfiles/logo_teams/"
DATA_DIR = os.environ.get("OUT_DIR") or os.path.join(os.path.dirname(__file__), "..", "data")
OUT = os.path.join(DATA_DIR, "matches.json")
DELAY = 0.5

VIRTUAL = ("esoccer", "e-soccer", "efootball", "e-football", "cyber", "battle", "virtual", "gt league", "fifa", "virtuacomp")
YOUTH_WOMEN = ("(f)", "(w)", "women", "femin", "fémin", "femmes", "dames", "u17", "u19", "u20", "u21", "u23", "espoirs", "réserv", "reserv", "jeunes", "youth", "junior")

# key, display name, predicate(lowercased tournament name), limit. Names are Spanish (lng=es); the first run prints what matched.
def _c(*k): return lambda n: any(x in n for x in k)
# GoClarivo: una corrida por país del sitio (RG_COUNTRY=ar|mx|cl|pe|ec|bo|py|es|gh|ke|zm|bf|in) y una internacional (int).
# El idioma de los nombres sigue al del país en el sitio (LNG: es / en / fr). La primera corrida imprime qué torneos coincidieron.
RG = os.environ.get("RG_COUNTRY", "ar")
LNG = os.environ.get("LNG") or {"gh": "en", "ke": "en", "zm": "en", "in": "en", "en": "en", "bf": "fr"}.get(RG, "es")
NOT_LEAGUE = ("reserv", "femen", "fémin", "women", "(f)", "sub-", "sub ", "u1", "u2", "copa", "cup", "coupe", "segunda", "second", "deuxième", "2", "ascenso", "primera b", "primera nacional", "nacional b", "expansi", "jugador", "player", "especial", "special", "ganador", "winner", "vainqueur", "estad", "stat")
def LEAGUE(*starts, need=()):
    return lambda n: any(n.startswith(x) for x in starts) and (not need or _c(*need)(n)) and not _c(*NOT_LEAGUE)(n)
SEL = lambda n: _c("mundial", "world cup", "coupe du monde", "copa del mundo", "eliminatorias", "qualif", "conmebol", "copa américa", "copa america", "concacaf", "nations league", "liga de naciones", "gold cup", "copa oro", "africa cup", "coupe d'afrique", "can ", "afcon", "cosafa", "cecafa", "wafu", "saff", "asian cup", "amistos", "friendl", "amical", "selecciones", "national teams", "sélections")(n) and not _c("club", "libertadores", "sudamericana", "u1", "u2", "sub-", "sub ", "femen", "(f)", "women", "ganador", "winner", "campeones", "champions")(n)
CONF = {
    # país: (nombres de la selección en el idioma de la API, [grupo de liga])
    "ar": (("argentina",), [("liga", "Liga Profesional de Argentina", LEAGUE("argentina", need=("liga profesional", "primera división", "primera division", "superliga")), 16)]),
    "mx": (("mexico",), [("liga", "Liga MX", LEAGUE("méxico", "mexico", need=("liga mx",)), 18)]),
    "cl": (("chile",), [("liga", "Primera División de Chile", LEAGUE("chile", need=("primera", "campeonato")), 16)]),
    "pe": (("peru",), [("liga", "Liga 1 de Perú", LEAGUE("perú", "peru", need=("liga 1", "primera")), 18)]),
    "ec": (("ecuador",), [("liga", "LigaPro Serie A de Ecuador", LEAGUE("ecuador", need=("serie a", "ligapro", "liga pro")), 16)]),
    "bo": (("bolivia",), [("liga", "División Profesional de Bolivia", LEAGUE("bolivia", need=("divisi", "profesional", "primera", "liga")), 16)]),
    "py": (("paraguay",), [("liga", "Primera División de Paraguay", LEAGUE("paraguay", need=("primera", "divisi")), 12)]),
    "es": (("espana",), [("liga", "LaLiga", LEAGUE("españa", "espana", need=("laliga", "la liga", "primera")), 20)]),
    "gh": (("ghana",), [("liga", "Ghana Premier League", LEAGUE("ghana", need=("premier", "league")), 18)]),
    "ke": (("kenya",), [("liga", "Kenyan Premier League", LEAGUE("kenya", need=("premier", "league")), 18)]),
    "zm": (("zambia",), [("liga", "Zambia Super League", LEAGUE("zambia", need=("super", "league", "premier")), 18)]),
    "bf": (("burkina-faso",), [("liga", "Championnat du Burkina Faso", LEAGUE("burkina", need=("premier", "ligue", "championnat", "league")), 16)]),
    "in": (("india",), [("liga", "Indian Super League", LEAGUE("india", "inde", need=("super", "isl", "league")), 16)]),
    "en": ((), [("liga", "Premier League", lambda n: n.strip() in ("england. premier league",), 20)]),
    "int": ((), [
        ("copa-libertadores", "Copa Libertadores", lambda n: "libertadores" in n and not _c("femen", "(f)", "sub", "u2", "ganador", "winner", "especiales", "jugador")(n), 16),
        ("copa-sudamericana", "Copa Sudamericana", lambda n: "sudamericana" in n and not _c("femen", "(f)", "sub", "u2", "ganador", "winner", "especiales", "jugador")(n), 16),
        ("champions-league", "Champions League", lambda n: _c("uefa champions league", "liga de campeones de la uefa", "champions league")(n) and not _c("afc", "caf", "concacaf", "qualif", "clasif", "ganador", "winner", "femen")(n), 16),
        ("laliga", "LaLiga", lambda n: (n.startswith("españa") or n.startswith("espana") or n.startswith("spain")) and _c("laliga", "la liga", "primera")(n) and not _c("2", "segunda", "hypermotion", "rfef", "femen", "f)", "ganador", "winner", "jugador", "equipo vs")(n), 20),
        ("premier-league", "Premier League", lambda n: n.strip() in ("inglaterra. premier league", "england. premier league"), 20),
    ]),
}
NATIONS = CONF[RG][0]
GROUPS = CONF[RG][1] + ([("seleccion", "Selección", SEL, 30)] if NATIONS else [])
AFRICA = ("liga", "seleccion", "copa-libertadores", "copa-sudamericana", "champions-league", "laliga", "premier-league")  # groups with stored results
EUROPE = ()
EU_FROM = 0
INTL = ("champions-league", "laliga", "premier-league")


def slug(x):
    import unicodedata
    x = unicodedata.normalize("NFD", x or "").encode("ascii", "ignore").decode().lower()
    return __import__("re").sub(r"[^a-z0-9]+", "-", x).strip("-")


class ApiError(RuntimeError):
    pass


def retry(fn):
    """La API de 1xBet a veces tarda: 3 intentos ante timeout o error de conexión."""
    def w(*a, **k):
        for i in range(3):
            try:
                return fn(*a, **k)
            except (requests.exceptions.Timeout, requests.exceptions.ConnectionError):
                if i == 2:
                    raise
                time.sleep(5 * (i + 1))
    return w


@retry
def token(s, cid, secret):
    r = s.post(TOKEN_URL, data={"client_id": cid, "client_secret": secret},
               headers={"Content-Type": "application/x-www-form-urlencoded"}, timeout=30)
    if r.status_code != 200 or "access_token" not in r.text:
        raise ApiError(f"token: HTTP {r.status_code} {r.text[:200]}")
    return r.json()["access_token"]


@retry
def get(s, tok, p, params, dbg=None, name=None):
    r = s.get(API_BASE + p, headers={"Authorization": f"Bearer {tok}"}, params=params, timeout=20)
    if dbg and name:
        os.makedirs(dbg, exist_ok=True)
        open(os.path.join(dbg, name), "w", encoding="utf-8").write(f"GET {r.url}\nHTTP {r.status_code}\n\n{r.text}")
    if r.status_code != 200:
        raise ApiError(f"{p}: HTTP {r.status_code} {r.text[:200]}")
    return r.json()


def items(x):
    return x.get("items", []) if isinstance(x, dict) else (x or [])


def has(name, kws):
    n = (name or "").lower()
    return any(k in n for k in kws)


def odds_1x2(lst):
    by = {}
    for o in lst or []:
        if o.get("isBlocked") or o.get("oddsMarket") is None:
            continue
        t = o.get("type")
        if t in (1, 2, 3) and t not in by:
            by[t] = float(o["oddsMarket"])
    if len(by) < 3:
        return None
    return {"1": by[1], "X": by[2], "2": by[3]}


COUPON_RE = __import__("re").compile(r"coupon-code=([A-Za-z0-9]+)")
_shown = []


def coupons(s, tok, base, eid, odds_list):
    """Pre-filled bet-slip codes per 1X2 outcome via /sharecoupon. Best effort: errors are skipped."""
    by = {}
    for o in odds_list or []:
        t = o.get("type")
        if t in (1, 2, 3) and t not in by and not o.get("isBlocked") and o.get("oddsMarket") is not None:
            by[t] = o
    res = {}
    for t, k in ((1, "1"), (2, "X"), (3, "2")):
        o = by.get(t)
        if not o:
            continue
        time.sleep(0.15)
        try:
            r = get(s, tok, "/datafeed/directories/api/v1/sharecoupon",
                    {**base, "oddsMarket": o["oddsMarket"], "sportEventId": eid, "type": t, "kind": 3, "lng": LNG})
        except ApiError as e:
            if not _shown:
                _shown.append(1)
                print(f"sharecoupon error: {e}", file=sys.stderr)
            continue
        url = r if isinstance(r, str) else json.dumps(r)
        m = COUPON_RE.search(url)
        if m:
            res[k] = m.group(1)
            if not _shown:
                _shown.append(1)
                print(f"sharecoupon sample: {url}", file=sys.stderr)
    return res or None


def markets(lst):
    """Extra markets from a full odds list: double chance, over/under 2.5 goals, both teams score. Only unblocked odds."""
    by = {}
    for o in lst or []:
        if o.get("isBlocked") or o.get("oddsMarket") is None:
            continue
        by.setdefault((o.get("type"), float(o.get("parameter") or 0)), float(o["oddsMarket"]))
    res = {}
    dc = {k: by.get((t, 0.0)) for k, t in (("1X", 4), ("12", 5), ("X2", 6))}
    if all(dc.values()): res["dc"] = dc
    ou = {"o": by.get((9, 2.5)), "u": by.get((10, 2.5))}
    if all(ou.values()): res["ou25"] = ou
    bt = {"y": by.get((180, 0.0)), "n": by.get((181, 0.0))}
    if all(bt.values()): res["btts"] = bt
    return res or None


def h2h(s, tok, base, st, home, away):
    """Head-to-head + recent form of both teams from /statistics. Finished games only (status 3)."""
    d = get(s, tok, "/statistics/sportevent/h2h", {**base, "statEventId": st, "lng": LNG})
    titles = {t["id"]: t.get("title") for t in d.get("teams") or []}
    games = {g["id"]: g for g in d.get("gameShorts") or [] if g.get("status") == 3 and g.get("score1") is not None}
    e = d.get("entity") or {}
    def ids_common(gids):
        sets = [{games[g]["team1"], games[g]["team2"]} for g in gids if g in games]
        return (set.intersection(*sets) if sets else set())
    hid, aid = ids_common(e.get("team1GameIds") or []), ids_common(e.get("team2GameIds") or [])
    if len(hid) != 1 or len(aid) != 1 or hid == aid:
        return None
    hid, aid = hid.pop(), aid.pop()
    def row(g):
        return {"d": g["dateStart"], "h": titles.get(g["team1"], "?"), "a": titles.get(g["team2"], "?"),
                "s": [g["score1"], g["score2"]], "t": g.get("tournamentTitle") or "", "hh": g["team1"] == hid}
    def lst(gids, n):
        out = sorted((games[g] for g in gids if g in games), key=lambda g: -g["dateStart"])[:n]
        return [row(g) for g in out]
    hh = [g for g in lst(e.get("gameIds") or [], 30) if {g["h"], g["a"]} == {titles.get(hid), titles.get(aid)}]
    def form(gids, tid):
        r = []
        for g in sorted((games[x] for x in gids if x in games), key=lambda g: -g["dateStart"])[:5]:
            me = 0 if g["team1"] == tid else 1
            gf, ga = (g["score1"], g["score2"]) if me == 0 else (g["score2"], g["score1"])
            r.append({"d": g["dateStart"], "o": titles.get(g["team2"] if me == 0 else g["team1"], "?"), "gf": gf, "ga": ga, "dom": me == 0})
        return r
    out = {"h2h": hh[:8], "f1": form(e.get("team1GameIds") or [], hid), "f2": form(e.get("team2GameIds") or [], aid)}
    return out if (out["h2h"] or out["f1"] or out["f2"]) else None


STAGES = {}


def stage(s, tok, base, st, tid, home, away):
    """Official table of the stage (1xBet statistics). For group stages: the group of one of the two teams."""
    if tid not in STAGES:
        try:
            STAGES[tid] = get(s, tok, "/statistics/sportevent/stage", {**base, "statEventId": st, "lng": LNG})
        except ApiError:
            STAGES[tid] = None
    d = STAGES[tid]
    if not d:
        return None
    titles = {t["id"]: t.get("title") for t in d.get("teams") or []}
    ent = d.get("entity") or {}
    stt = ent.get("stageTable") or {}
    tables = [(g.get("title") or "", g.get("table") or {}) for g in stt.get("groups") or []] or [("", stt.get("table") or {})]
    want = {slug(home), slug(away)}
    for gt, t in tables:
        rows = []
        for r in ((t.get("tableBody") or [[]])[0] or []):
            v = {c.get("id"): c for c in r.get("valueCol") or []}
            try:
                name = titles.get(v[2].get("competitorId"))
                gf, ga = (v[7]["value"][0]).split(":")
                rows.append({"pos": int(v[1]["value"][0]), "team": name, "pj": int(v[3]["value"][0]), "g": int(v[4]["value"][0]),
                             "p": int(v[5]["value"][0]), "n": int(v[6]["value"][0]), "bp": int(gf), "bc": int(ga), "pts": int(v[8]["value"][0])})
            except (KeyError, IndexError, ValueError, TypeError, AttributeError):
                return None
        if rows and want & {slug(r["team"]) for r in rows}:
            return {"title": ent.get("title") or "", "group": gt, "rows": rows,
                    "foot": [f.get("title") for f in (t.get("footer") or []) if f.get("title")][:4]}
    return None


TIDS = {}  # group key -> [tournamentId]
TNAME = {}  # tournamentId -> name
RESULTS = os.path.join(DATA_DIR, "results.json")
SEASON_FROM = int(datetime.datetime(2025, 7, 1, tzinfo=datetime.timezone.utc).timestamp())  # seasons 2025 + 2026: H2H history
SCORE_RE = __import__("re").compile(r"^\s*(\d+)\s*:\s*(\d+)")


def fetch_results(s, tok, base, tid, frm, to):
    """Finished matches of one tournament between frm and to (API allows windows of at most 2 days)."""
    out, t = [], to
    while t - frm >= 60:
        df = max(frm, t - 2 * 86400 + 60)
        time.sleep(0.3)
        try:
            r = get(s, tok, "/result/api/v1/sportevents", {**base, "tournamentIds": tid, "dateFrom": df, "dateTo": t, "lng": LNG})
        except ApiError as e:
            print(f"results error {tid}: {e}", file=sys.stderr)
            t = df
            continue
        for it in items(r):
            if it.get("type") != 1:  # type 1 = the match itself; other types are corners, cards, etc.
                continue
            m = SCORE_RE.match(it.get("score") or "")
            h, w = it.get("opponent1NameLocalization"), it.get("opponent2NameLocalization")
            if not m or not h or not w or not it.get("startDate"):
                continue
            out.append({"id": it.get("sportEventId"), "tid": tid, "tname": TNAME.get(tid, ""), "home": h, "away": w,
                        "score": [int(m.group(1)), int(m.group(2))], "detail": it.get("score"), "start": it["startDate"]})
        t = df
    return out


def img(field):
    for f in field or []:
        if f:
            return IMAGE_BASE + f
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--debug-dir")
    a = ap.parse_args()
    cid, sec, ref = ((os.environ.get(k) or "").strip() for k in ("ONEXBET_CLIENT_ID", "ONEXBET_CLIENT_SECRET", "ONEXBET_REF"))
    print(f"secret lengths: client_id={len(cid)} client_secret={len(sec)} ref={len(ref)}", file=sys.stderr)
    if not (cid and sec and ref):
        sys.exit("Missing ONEXBET_CLIENT_ID / ONEXBET_CLIENT_SECRET / ONEXBET_REF")
    base = {"ref": ref}
    if os.environ.get("ONEXBET_GR"):
        base["gr"] = os.environ["ONEXBET_GR"]

    s = requests.Session()
    try:
        try:
            tok = token(s, cid, sec)
        except ApiError:
            alt = cid[len("partners-"):] if cid.startswith("partners-") else "partners-" + cid
            tok = token(s, alt, sec)
            print("token OK with alternate client_id form (fix the secret)", file=sys.stderr)
        tours = items(get(s, tok, "/datafeed/loadtree/prematch/api/v1/tournaments",
                          {**base, "SportId": 1, "lng": LNG}, a.debug_dir, "tournaments.json"))
    except ApiError as e:
        sys.exit(f"API error, keeping previous data: {e}")
    tours = [t for t in tours if not has(t.get("tournamentNameLocalization"), VIRTUAL + YOUTH_WOMEN)]

    now = int(time.time())
    out = []
    if os.environ.get("RG_DEBUG"):
        for t in tours:
            nm = (t.get("tournamentNameLocalization") or "").lower()
            if any(w.replace("-", " ") in nm for w in NATIONS) or any(w in nm for w in ("libertadores", "sudamericana", "champions", "premier league", "laliga", "la liga")):
                print(f"DEBUG tour {t.get('tournamentId')}: {nm}", file=sys.stderr)
    for key, name, pred, limit in GROUPS:
        sel = [t for t in tours if pred((t.get("tournamentNameLocalization") or "").lower())]
        print(f"{key}: " + " | ".join(t.get("tournamentNameLocalization") or "" for t in sel[:10]), file=sys.stderr)
        if key == "seleccion":
            sel = sel[:15]
        for t in sel[:15]:
            TNAME[t["tournamentId"]] = t.get("tournamentNameLocalization") or ""
        TIDS[key] = [t["tournamentId"] for t in sel[:15 if key == "seleccion" else 6]]
        ids = []
        for t in sel[:15 if key == "seleccion" else 6]:
            time.sleep(DELAY)
            try:
                ids += items(get(s, tok, "/datafeed/loadtree/prematch/api/v1/sporteventIds", {**base, "tournamentId": t["tournamentId"]}))
            except (ApiError, KeyError):
                continue
        ms = []
        for eid in ids[: limit * 2 if key != "seleccion" else 80]:
            time.sleep(DELAY)
            try:
                d = get(s, tok, "/datafeed/loadtree/prematch/api/v1/sporteventDetail",
                        {**base, "sportEventId": eid, "schemeOfGettingOdds": "Get1X2Odds", "lng": LNG})
            except ApiError:
                continue
            st, o = d.get("startDate"), odds_1x2(d.get("oddsLocalization"))
            h, w = d.get("opponent1NameLocalization"), d.get("opponent2NameLocalization")
            if not st or st <= now or not o or not h or not w:
                continue
            if key == "seleccion" and not any(slug(x) in NATIONS for x in (h, w)):
                continue
            ms.append({"tournament": d.get("tournamentNameLocalization", name), "home": h, "away": w, "start": st,
                       "odds": o, "img1": img(d.get("imageOpponent1")), "img2": img(d.get("imageOpponent2")), "link": d.get("link"), "_eid": eid, "_ol": d.get("oddsLocalization"), "_st": d.get("statGameId"), "_tid": d.get("tournamentId")})
        ms.sort(key=lambda m: m["start"])
        ms = ms[:limit]
        full = {}
        if ms:
            time.sleep(DELAY)
            try:
                for it in items(get(s, tok, "/datafeed/prematch/api/v2/sportevents",
                                    {**base, "lng": LNG, "sportEventIds": ",".join(str(m["_eid"]) for m in ms), "schemeOfGettingOddsOperations": "GetAllOdds"})):
                    full[it.get("sportEventId")] = it.get("oddsLocalization")
            except ApiError as e:
                print(f"markets error {key}: {e}", file=sys.stderr)
        for m in ms:
            eid, st, tid = m.pop("_eid"), m.pop("_st", None), m.pop("_tid", None)
            m["eid"], m["tid"] = eid, tid  # used by the live-score feature (worker /api/live)
            c = coupons(s, tok, base, eid, m.pop("_ol"))
            if c:
                m["coupon"] = c
            mk = markets(full.get(eid))
            if mk:
                m["markets"] = mk
            if st:
                time.sleep(0.3)
                try:
                    hs = h2h(s, tok, base, st, m["home"], m["away"])
                    if hs:
                        m["stats"] = hs
                    tb = stage(s, tok, base, st, tid, m["home"], m["away"])
                    if tb:
                        m["table"] = tb
                except (ApiError, KeyError, TypeError, ValueError) as e:
                    print(f"stats error {eid}: {e}", file=sys.stderr)
        out.append({"key": key, "name": name, "matches": ms})
        print(f"{key}: {len(sel)} tournaments, {len(ms)} matches", file=sys.stderr)

    # Results (finished matches with scores): league table + result pages. Never invented: only what the API returns.
    if not a.dry_run and TIDS:
        try:
            prev = json.load(open(RESULTS, encoding="utf-8"))
        except (OSError, ValueError):
            prev = {}
        old = {r["id"]: r for r in prev.get("matches", [])}
        backfilled = prev.get("backfilled", [])
        got = []
        for key, tids in TIDS.items():
            if key not in AFRICA and key not in EUROPE:
                continue
            for tid in tids:
                frm = now - 4 * 86400
                if tid not in backfilled:
                    frm = SEASON_FROM if key == "liga" else now - 200 * 86400  # one-time backfill of the season
                    backfilled.append(tid)
                rs = fetch_results(s, tok, base, tid, frm, now)
                for r in rs:
                    r["group"] = key
                if key == "seleccion":
                    rs[:] = [r for r in rs if slug(r["home"]) in NATIONS or slug(r["away"]) in NATIONS]
                got += rs
        for r in got:
            old[r["id"]] = r
        keep = [r for r in old.values() if r["start"] >= now - 400 * 86400]
        keep.sort(key=lambda r: r["start"])
        print(f"results: {len(got)} fetched, {len(keep)} stored", file=sys.stderr)
        with open(RESULTS, "w", encoding="utf-8") as f:
            json.dump({"updated": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
                       "backfilled": backfilled, "matches": keep}, f, ensure_ascii=False, indent=1)
            f.write("\n")

    data = {"updated": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"), "groups": out}
    if a.dry_run:
        print(json.dumps(data, ensure_ascii=False, indent=1))
        return
    if not any(g["matches"] for g in out):
        sys.exit("No matches returned, keeping previous data")
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
        f.write("\n")


if __name__ == "__main__":
    main()
