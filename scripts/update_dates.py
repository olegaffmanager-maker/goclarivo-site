#!/usr/bin/env python3
"""
Stamps today's date (UTC) into every "last verified / last updated" date on the
site. Run daily by .github/workflows/update-dates.yml; safe to run by hand
(`python3 scripts/update_dates.py [YYYY-MM-DD]`) and idempotent within a day.

Touches ONLY these things (never article publish dates -- .article-date,
datePublished, bylines' own publish date):
  1. Homepage hero stat      <b id="hero-last-verified-date">...</b>   (locale-formatted)
  2. Byline / meta lines     "Última verificación|Última actualización|Last verified|
                              Dernière vérification: DD/MM/YYYY"
  3. Legal pages (en / fr)   "Last updated: Month D, YYYY." / "Dernière mise à jour : D mois YYYY."
  4. bo payments guide       "actualizado DD/MM/YYYY"
  5. JSON-LD                 "dateModified": "YYYY-MM-DD"
  6. sitemap.xml             <lastmod>YYYY-MM-DD</lastmod>
"""
import re, sys, os, glob, datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

LANG = {"ar":"es","bo":"es","cl":"es","ec":"es","es":"es","mx":"es","pe":"es","py":"es",
        "en":"en","gh":"en","in":"en","ke":"en","zm":"en","bf":"fr"}
MONTHS = {
 "es":["enero","febrero","marzo","abril","mayo","junio","julio","agosto","septiembre","octubre","noviembre","diciembre"],
 "en":["January","February","March","April","May","June","July","August","September","October","November","December"],
 "fr":["janvier","février","mars","avril","mai","juin","juillet","août","septembre","octobre","novembre","décembre"],
}
def long_date(d, lang):
    m = MONTHS[lang][d.month-1]
    if lang == "en": return f"{m} {d.day}, {d.year}"
    if lang == "es": return f"{d.day} de {m} de {d.year}"
    return f"{d.day} {m} {d.year}"

LABELS = r'(?:Última verificación|Última actualización|Last verified|Last updated|Dernière vérification|Dernière mise à jour)'
SKIP = ("de/", "it/", "pt/", "fr/", ".git/", "node_modules/")

def stamp(html, d, geo):
    lang = LANG.get(geo, "en")
    num = d.strftime("%d/%m/%Y")
    iso = d.isoformat()
    html = re.sub(r'(<b id="hero-last-verified-date">)[^<]*(</b>)', lambda m: m.group(1)+long_date(d,lang)+m.group(2), html)
    html = re.sub(r'(\b'+LABELS+r'\s*:\s*)\d{1,2}/\d{1,2}/\d{4}', lambda m: m.group(1)+num, html)
    html = re.sub(r'(Last updated\s*:\s*)[A-Z][a-z]+ \d{1,2}, \d{4}', lambda m: m.group(1)+long_date(d,"en"), html)
    html = re.sub(r'(Dernière mise à jour\s*:\s*)\d{1,2} [^\W\d_]+ \d{4}', lambda m: m.group(1)+long_date(d,"fr"), html)
    html = re.sub(r'(&middot;\s*actualizado\s+)\d{1,2}/\d{1,2}/\d{4}', lambda m: m.group(1)+num, html)
    html = re.sub(r'("dateModified"\s*:\s*")\d{4}-\d{2}-\d{2}(")', lambda m: m.group(1)+iso+m.group(2), html)
    return html

def main():
    d = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else datetime.datetime.now(datetime.timezone.utc).date()
    changed = 0
    for f in glob.glob("**/*.html", recursive=True):
        if f.startswith(SKIP): continue
        geo = f.split("/")[0] if "/" in f else ""
        old = open(f, encoding="utf-8").read()
        new = stamp(old, d, geo)
        if new != old:
            open(f, "w", encoding="utf-8").write(new); changed += 1
    if os.path.exists("sitemap.xml"):
        old = open("sitemap.xml", encoding="utf-8").read()
        new = re.sub(r"<lastmod>[^<]*</lastmod>", f"<lastmod>{d.isoformat()}</lastmod>", old)
        if new != old: open("sitemap.xml", "w", encoding="utf-8").write(new); changed += 1
    print(f"Date stamped: {d.isoformat()} -- files changed: {changed}")

if __name__ == "__main__":
    main()
