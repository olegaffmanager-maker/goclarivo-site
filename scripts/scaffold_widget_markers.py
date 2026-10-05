#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
One-time scaffold: insert the ONEXBET_ODDS_WIDGET marker pair (with an
honest "pending" placeholder) into the 1xBet real-partner card on each
ONEXBET_GEOS /{geo}/sports/ page, right after the existing
"¿Cómo verificamos a los operadores?" / "How do we verify operators?"
verify-link and before that card's closing </div>.

Run this ONCE per page (it raises if the markers are already present, so
it's safe to re-run accidentally -- it just won't double-insert). After
this, scripts/onexbet_odds.py's periodic runs only ever replace the content
*between* the markers, never touch anything else on the page.

Usage:
    python scripts/scaffold_widget_markers.py --site-root goclarivo-site
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from onexbet_odds import GEO_LANG, render_widget_html, MARKER_START, MARKER_END

VERIFY_LINK_TEXT = {
    "es": "¿Cómo verificamos a los operadores?",
    "en": "How do we verify operators?",
}


def scaffold_geo(site_root, geo, lang):
    path = os.path.join(site_root, geo, "sports", "index.html")
    with open(path, encoding="utf-8") as f:
        src = f.read()

    if MARKER_START in src:
        print(f"[{geo}] markers already present, skipping")
        return False

    verify_text = VERIFY_LINK_TEXT[lang]
    anchor = f'">{verify_text}</a>\n      </div>'
    count = src.count(anchor)
    if count != 1:
        raise ValueError(
            f"[{geo}] expected exactly 1 occurrence of the 1xBet card's verify-link "
            f"closing anchor, found {count} -- page structure may have changed, "
            f"check manually before scaffolding"
        )

    widget_html = render_widget_html(lang, [], updated_at_iso="", state="pending")
    # indent to match surrounding markup (8 spaces, matching casino-main's children)
    indented = "\n".join("        " + line if line.strip() else line for line in widget_html.splitlines())
    replacement = f'">{verify_text}</a>\n{indented}\n      </div>'

    new_src = src.replace(anchor, replacement, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(new_src)
    print(f"[{geo}] scaffolded ({len(new_src)} bytes)")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--site-root", default=os.environ.get("SITE_ROOT", "goclarivo-site"))
    parser.add_argument("--geos", default=",".join(GEO_LANG.keys()))
    args = parser.parse_args()

    for geo in [g.strip() for g in args.geos.split(",") if g.strip()]:
        lang = GEO_LANG.get(geo)
        if not lang:
            print(f"[skip] {geo}: not in GEO_LANG map", file=sys.stderr)
            continue
        scaffold_geo(args.site_root, geo, lang)


if __name__ == "__main__":
    main()
