@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Remove false local-licensing promises, per your document of
REM  17.10.2026. 234 files changed, no folders deleted.
REM
REM  WHAT CHANGED
REM
REM  1, meta description and og-description on the main page of
REM  mx, es, pe, bo, py, ar, it. These used to promise the site
REM  evaluates operators against the local regulator -- SEGOB,
REM  DGOJ, MINCETUR, AJ, DNIT, provincial, ADM. Now they say the
REM  site evaluates licence, payments, games and bonus terms, and
REM  tell the reader to check local rules themselves. de, en, gh,
REM  ke, zm, in, bf, pt were already neutral -- not touched.
REM
REM  2, the 30-percent rating criterion, main page and methodology
REM  page, same 7 geos. Renamed to Licencia y seguridad -- Licenza
REM  e sicurezza on it -- everywhere it was not already called
REM  that, and the description now explains which licence the
REM  operator holds and whether it is valid in your country,
REM  naming the local regulator for context, rather than treating
REM  a local licence as assumed. Weight is still 30 percent. Also
REM  fixed the ar intro sentence that said we verify the specific
REM  provincial licence -- now it says we show which licence each
REM  operator has and whether it includes a provincial one.
REM
REM  3, the how-do-I-choose-a-casino FAQ answer on mx, pe, bo, ar,
REM  it. Used to list the local permit as something to look for
REM  as if every operator had one. Now it says to check which
REM  licence the operator holds and whether it is valid locally,
REM  alongside payout speed, bonus transparency and payment
REM  methods. The is-online-gambling-legal-in FAQ and the guides
REM  that name regulators and laws were NOT touched anywhere --
REM  confirmed both still present on every geo, unchanged.
REM
REM  4, footer badge. Regulado por la SEGOB and the same pattern
REM  on es, pe, bo, py, it, ar read as if the regulator oversees
REM  this site. Changed to the neutral Regulador local, Regolatore
REM  locale on it, across every page of those 7 geos -- 217 pages
REM  in total. On py specifically, the homepage said DNIT and every
REM  other page said CONAJZAR -- both the badge and the footer
REM  link label now read DNIT, antes CONAJZAR, the same everywhere,
REM  link address unchanged.
REM
REM  5, licence line on every operator card, every geo, 72 pages.
REM  Checked every card against the project's own data and, where
REM  missing, researched the operator's own official site. Real,
REM  already-on-file licence data was kept and reformatted into
REM  the new standard line -- 1RedBet, PIN-UP and PIN-UP Africa
REM  keep their working Ver registro or View registry link,
REM  BetAndYou Africa and Melbet keep their real licence text
REM  without a registry link since that was never checked. No
REM  operator on this site holds a licence that is local to the
REM  geo it is shown on, so the local-licence line format is not
REM  used anywhere -- every card is either the non-local format or
REM  the not-published fallback. 1xBet, Mostbet, 20Bet, Granawin,
REM  Spinania, NeedForSlots, DragonSlots, National Casino, Richard
REM  Casino, Stay Casino, SlotoZen and WantedWin get the not-
REM  published line since no licence number could be confirmed
REM  anywhere, including each operator's own official pages where
REM  reachable. Full detail in the chat report.
REM
REM  6, verification badge and header counter. Per your explicit
REM  instruction in chat after I flagged this, the green License
REM  checked / Licencia verificada badge and the header count stay
REM  exactly as they already were on every card, every geo -- not
REM  restricted to only registry-checked cards. This is a deliberate
REM  departure from item 6 of your own document, done only because
REM  you confirmed it twice in chat. Nothing to deploy for this
REM  item, since it matches what the site already shows.
REM
REM  Everything above was driven by the document you sent plus the
REM  chat follow-up on item 6. Nothing outside that was touched --
REM  no card removed or reordered, no legality FAQ or guide edited.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0license_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find license_deploy folder next to this script.
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

echo All 234 source files found. Starting deploy...
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
echo Done. Meta descriptions, the licence-and-security criterion,
echo the choose-a-casino FAQ, the footer regulator badge and the
echo per-card licence line are all updated on mx, es, pe, bo, py,
echo ar and it, plus the licence line on every other geo's cards.
echo.
echo Verification badges and header counters were left as they
echo already were, per your chat confirmation -- not tightened.
echo.
echo Short report on which operators had no licence anywhere, and
echo where the licence data on file came from, is in the chat.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
