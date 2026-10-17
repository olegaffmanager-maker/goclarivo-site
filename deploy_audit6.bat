@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Audit round 6 -- remove France from navigation, add a new
REM  India geo. 413 files.
REM
REM  NOTE: this round was too big for one zip, so it came as 4
REM  zips (audit6_deploy_part1/2/3/4.zip). Extract all 4 into the
REM  SAME folder -- their audit6_deploy subfolders merge into one
REM  (Windows will just add the extra geo folders alongside the
REM  ones already there). This .bat and files_list.txt only exist
REM  in part1 -- once all 4 are extracted together, run this one
REM  script same as always.
REM
REM  WHAT CHANGED AND WHY
REM
REM  1) France (/fr/) is delisted from the rest of the site, but
REM     NOT deleted. Every file under fr/ is completely untouched
REM     -- the page still exists at goclarivo.bet/fr/ for anyone
REM     with the direct link, it's just no longer linked from
REM     anywhere else. Removed from: the country-switcher (header
REM     dropdown + footer list) on every other geo's pages, all
REM     19 /fr/* entries in sitemap.xml, every hreflang block
REM     site-wide that had an fr-FR line, and the root page's
REM     browser-language redirect map + hreflang list. Burkina
REM     Faso (/bf/, also French-speaking, hreflang fr-BF) is a
REM     completely different, still-live geo and was NOT touched
REM     anywhere -- only France's own fr-FR entries were removed.
REM
REM  2) A new India (/in/) geo was built from scratch: 26 pages in
REM     English, same page set as Ghana/Kenya/Zambia (homepage,
REM     about, bonus-calculator, compare, corrections, editorial-
REM     policy, glossary, industry + its one article, methodology,
REM     privacy, responsible-gambling, sports, terms, and 12
REM     guides). No sports sub-pages (football/basketball/etc.) --
REM     same as Ghana/Kenya/Zambia, India isn't in the 7-country
REM     tier that has those.
REM
REM     India went everywhere France came out of: the country-
REM     switcher (translated into every other language -- "Indien"
REM     in German, "India" in Spanish/Italian, "Índia" in
REM     Portuguese, "Inde" in French for Burkina Faso's pages),
REM     sitemap.xml (26 new URLs), hreflang (en-IN added to every
REM     block that already had en-GH/en-KE/en-ZM -- homepages, the
REM     10 core pages, the industry pages, and the English-tier
REM     guide groups; NOT added to the 7-geo sports sub-pages or
REM     the football-betting guides, which India doesn't have), and
REM     the root page's redirect map + hreflang list (en-in ->
REM     /in/). A new flag-in SVG symbol (saffron/white/green bands
REM     + a simplified navy Ashoka Chakra) was added next to every
REM     other flag symbol, site-wide.
REM
REM  3) India's content is honest and specific, not a copy-paste of
REM     another country with find-and-replace:
REM       - Legal status: explains India's gambling law is a state
REM         subject (Public Gambling Act 1867 baseline), that
REM         Telangana and Andhra Pradesh banned online betting
REM         outright, that the Supreme Court upheld Tamil Nadu's
REM         and Karnataka's bans on 27 May 2026, and that Sikkim/
REM         Nagaland's licensing regimes are narrow and don't cover
REM         real-money online casino games. Most importantly: a new
REM         FEDERAL law, the Promotion and Regulation of Online
REM         Gaming Act 2025 (in force since 1 May 2026), now bans
REM         real-money "online money games" nationwide -- including
REM         for offshore operators serving Indian users -- with
REM         real penalties for offering, advertising or processing
REM         payments for them. This is new information found during
REM         this round's research, confirmed via multiple sources;
REM         it's more precise than the "it's complicated" framing
REM         you'd originally approved, and more honest, not less.
REM       - Helplines: Tele-MANAS (14416 / 1800-891-4416) and iCall
REM         (022-2552-1111) -- both real, government/institutional,
REM         currently active. Stated honestly as general mental-
REM         health support, since no dedicated gambling-specific
REM         helpline exists in India as far as could be verified.
REM       - Consumer protection: India's National Cybercrime
REM         Reporting Portal (cybercrime.gov.in, 1930) and National
REM         Consumer Helpline (1915 / 1800-11-4000).
REM       - Payment methods: described honestly as "increasingly
REM         restricted and enforcement-targeted," not a flat "UPI is
REM         banned" claim -- that specific a claim isn't supported
REM         by a single clean source, the real picture is banks and
REM         payment processors facing growing legal pressure plus
REM         active enforcement against offshore platforms.
REM       - Operator cards: deliberately did NOT invent an INR
REM         bonus amount, a license number, or a new affiliate link
REM         for India -- there's no real advertiser data for this
REM         market. Instead, reused the exact same 1xBet and Mostbet
REM         cards already live on the EN (international) page: same
REM         real affiliate links, same honest "Bonus: in review --
REM         confirm current terms on the operator's site" text, same
REM         "Verified / Editorial review in progress" status. Zero
REM         fabricated commercial terms.
REM
REM  IMPORTANT -- you were shown this finding and explicitly chose
REM  to build India's casino/betting comparison page anyway (same
REM  pattern as DE/IT/ES/PT: operators shown, honestly marked as
REM  not locally licensed), even knowing the new 2026 law makes
REM  advertising such products in India a criminal offense for
REM  whoever advertises them. That's your call to make and this
REM  round carries it out as asked -- just flagging it again here
REM  since it's the kind of thing worth having in writing.
REM
REM  Does NOT touch: anything under fr/ itself; the Sports section's
REM  live-odds widget or the 1xlite-29668.pro mirror domain anywhere
REM  (separate standing decision -- left as-is); the licensing
REM  content on de, it, es, pt, mx, bo, pe, py, ke (separate standing
REM  hold -- only their switcher/hreflang/sitemap entries for the
REM  France/India swap were touched, nothing else on those 9 geos).
REM
REM  Two pre-existing HTML tag-balance issues were checked and are
REM  NOT new: the 35 sports sub-pages on the 7-country tier, and the
REM  root index.html page, both show the same imbalance in the
REM  original site before any of this project's changes -- confirmed
REM  by running the same check against an untouched reference copy.
REM  Nothing in this round introduced a new one.
REM
REM  Still open, unrelated to this round: author page for Oleg
REM  Melnikov (needs real bio text from you), contact email/
REM  Telegram handle, the Sports mirror-domain widget (closed per
REM  your "leave it as-is" decision).
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0audit6_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find audit6_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "mx" (
    echo ERROR: mx folder not found in the current folder.
    echo Run this script from the root of your goclarivo-site repo.
    pause
    exit /b 1
)
if not exist "assets" (
    echo ERROR: assets folder not found in the current folder.
    echo Run this script from the root of your goclarivo-site repo.
    pause
    exit /b 1
)

set "MISSING=0"
for /f "usebackq delims=" %%F in ("%LIST%") do (
    if not exist "%SRC%\%%F" (
        echo ERROR: Missing source file %SRC%\%%F
        set "MISSING=1"
    )
)
if "!MISSING!"=="1" (
    echo.
    echo One or more source files are missing. Nothing was changed. Aborting.
    pause
    exit /b 1
)

echo All 413 source files found. Starting deploy...
echo.

set "COUNT=0"
for /f "usebackq delims=" %%F in ("%LIST%") do (
    set "DESTDIR=%%~dpF"
    if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>&1
    if exist "%%F" copy /Y "%%F" "%%F.bak" >nul
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Deployed !COUNT! files.
echo.
echo ============================================================
echo Done. France is delisted from navigation (its own pages are
echo untouched), and a new 26-page India geo is live at /in/,
echo linked in the switcher, sitemap and hreflang everywhere
echo France used to be.
echo.
echo Still open: author page for Oleg Melnikov (needs real bio
echo text from you), contact email/Telegram. Sports mirror-domain
echo widget stays closed per your earlier decision.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
