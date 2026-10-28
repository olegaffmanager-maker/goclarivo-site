#!/usr/bin/env python3
"""
Keeps the "Last verified" hero stat on each locale homepage current.

Why this exists: the site has no build process or CMS -- every deploy is a
manual copy-paste of changed HTML files via GitHub Desktop. Each of the 15
locale homepages (ar/bo/cl/de/en/es/gh/in/it/ke/mx/pe/pt/zm/bf -- NOT py/,
which is a redirect-only stub with no real homepage) already had a hero
stat box reading e.g. "21 October 2026 / Last verified" (in its own
language) sitting next to the "05 / Rating criteria" box at the top of the
page. That date was hardcoded in the HTML and nobody had a way to keep it
current -- this script is that way.

HOW TO USE THIS ON EVERY FUTURE DEPLOY:
  python3 scripts/update_last_updated_date.py
This stamps today's date (read from the system clock) into all 15 pages'
hero stat, each in its own language, and only rewrites a file if the date
actually changed (so running it twice in the same day, or multiple times
during one deploy's prep, is always safe and touches nothing on the second
run).
To stamp a specific date instead of "today" (e.g. backfilling, or testing):
  python3 scripts/update_last_updated_date.py 2026-11-03

The markup convention (added 2026-10-27, replacing the plain hardcoded
"<b>21 October 2026</b>"): inside each page's hero .stats-row, the second
.stat box is:
  <div class="stat"><b id="hero-last-verified-date">{locale-formatted date}</b><span>{locale label, e.g. "Last verified"}</span></div>
Only the text inside <b id="hero-last-verified-date">...</b> is ever
touched by this script -- the surrounding label stays in that page's own
language and is never regenerated, so translations made by hand are never
clobbered.
"""
import re
import sys
import datetime

REPO_ROOT = __file__.rsplit("/scripts/", 1)[0] if "/scripts/" in __file__ else "."

# geo -> language family used for date formatting
LOCALES = {
    "ar": "es", "bo": "es", "cl": "es", "es": "es", "mx": "es", "pe": "es",
    "en": "en", "gh": "en", "in": "en", "ke": "en", "zm": "en",
    "de": "de",
    "it": "it",
    "pt": "pt",
    "bf": "fr",
}

MONTHS = {
    "es": ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
           "agosto", "septiembre", "octubre", "noviembre", "diciembre"],
    "en": ["January", "February", "March", "April", "May", "June", "July",
           "August", "September", "October", "November", "December"],
    "de": ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli",
           "August", "September", "Oktober", "November", "Dezember"],
    "it": ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno",
           "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"],
    "pt": ["janeiro", "fevereiro", "março", "abril", "maio", "junho",
           "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"],
    "fr": ["janvier", "février", "mars", "avril", "mai", "juin", "juillet",
           "août", "septembre", "octobre", "novembre", "décembre"],
}


def format_date(d, lang):
    month = MONTHS[lang][d.month - 1]
    if lang == "en":
        return f"{month} {d.day}, {d.year}"
    if lang == "de":
        return f"{d.day}. {month} {d.year}"
    if lang in ("es", "pt"):
        return f"{d.day} de {month} de {d.year}"
    return f"{d.day} {month} {d.year}"  # fr and anything else "D month YYYY"


TAG_RE = re.compile(
    r'(<b id="hero-last-verified-date">)([^<]*)(</b>)'
)


def update_file(path, new_text):
    with open(path, encoding="utf-8") as f:
        content = f.read()
    if 'id="hero-last-verified-date"' not in content:
        return "MISSING_MARKER"
    m = TAG_RE.search(content)
    if m and m.group(2) == new_text:
        return "UNCHANGED"
    new_content = TAG_RE.sub(lambda mo: mo.group(1) + new_text + mo.group(3), content, count=1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(new_content)
    return "UPDATED"


def main():
    if len(sys.argv) > 1:
        d = datetime.date.fromisoformat(sys.argv[1])
    else:
        d = datetime.date.today()

    changed = []
    unchanged = []
    missing = []
    for geo, lang in LOCALES.items():
        path = f"{REPO_ROOT}/{geo}/index.html" if REPO_ROOT != "." else f"{geo}/index.html"
        new_text = format_date(d, lang)
        try:
            result = update_file(path, new_text)
        except FileNotFoundError:
            missing.append(path)
            continue
        if result == "UPDATED":
            changed.append(path)
        elif result == "UNCHANGED":
            unchanged.append(path)
        else:
            missing.append(path)

    print(f"Date stamped: {d.isoformat()}")
    print(f"Updated ({len(changed)}): {', '.join(changed) or '-'}")
    print(f"Already current ({len(unchanged)}): {', '.join(unchanged) or '-'}")
    if missing:
        print(f"WARNING -- marker not found, skipped ({len(missing)}): {', '.join(missing)}")


if __name__ == "__main__":
    main()
