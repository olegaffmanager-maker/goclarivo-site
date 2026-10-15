@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Bonus calculator + author byline + Industry section -- FULL
REM  DEPLOY (all 15 geos). THIS PACKAGE SUPERSEDES BOTH
REM  calc_full_fix.zip AND calc_author_full.zip -- if you already
REM  ran either of those, running this is still safe (every file
REM  is simply overwritten again); if you haven't run anything
REM  yet, just run this one script, nothing else.
REM
REM  What this does (on top of everything already in
REM  calc_author_full.zip -- calculator pages, guide article,
REM  nav/FAQ links, author byline on all 89 guides):
REM
REM  NEW IN THIS PACKAGE -- the "Industry" section
REM  (GoClarivo_plan.docx section 3):
REM    1) Adds a new "Industry" hub/listing page on all 15 geos
REM       (e.g. /en/industry/, /de/branche/, /mx/industria/),
REM       with a tag filter (All / Conferences / Regulation /
REM       Trends) and a "Follow on Telegram" box instead of an
REM       email sign-up form (wiring a real double opt-in email
REM       provider needs an account only you can create -- see
REM       note at the end).
REM    2) Adds the first Industry article on all 15 geos: "SBC
REM       Summit Lisbon 2026: Key Takeaways" -- covering the
REM       event's scale, the new standalone Affiliate Leaders
REM       Summit, the new SBC-GRAF partnership for African
REM       regulators, and AI adoption trends discussed there.
REM       Every fact, date, name and figure in it was checked
REM       against real, current news coverage (SBC Americas, SBC
REM       News, CTO Magazine, Gambling.com); sources are listed
REM       at the bottom of the article itself. It is written as
REM       industry coverage, not a first-person conference diary
REM       -- it does not claim you personally attended.
REM    3) Adds an "Industry" link to the menu, mobile menu and
REM       footer navigation on all 15 geo homepages.
REM    4) Refreshes the header and footer navigation on all 89
REM       existing guide articles and all 15 calculator pages, so
REM       they also show the new Industry link (previously only
REM       homepages would have shown it) -- this is why so many
REM       already-existing files are included again in this
REM       package even though their main content didn't change.
REM
REM  NOT included: the full dedicated author bio page (still
REM  waiting on your photo and social links) and the quiz feature
REM  (still paused).
REM
REM  Backups: every file this script overwrites is first copied
REM  to the same name with ".bak" appended, in the same folder.
REM  Brand-new files/folders have nothing to back up.
REM ============================================================

set "SRC=%~dp0calc_industry_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find calc_industry_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

REM --- pre-flight: confirm we're at the repo root ---
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

REM --- pre-flight: confirm every one of the 151 source files exists ---
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

echo All 151 source files found. Starting deploy...
echo.

REM --- backup (if present) + copy every file ---
set "COUNT=0"
for /f "usebackq delims=" %%F in ("%LIST%") do (
    set "DESTDIR=%%~dpF"
    if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>&1
    if exist "%%F" copy /Y "%%F" "%%F.bak" >nul
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Deployed !COUNT! files:
echo   - 15 homepages (nav link, FAQ link, guide card, author byline, Industry link)
echo   - 15 calculator pages (header/footer refreshed with Industry link)
echo   - 89 guide articles (author byline; header/footer refreshed with Industry link)
echo   - 2 shared asset files
echo   - 30 NEW: Industry hub page + first article, one of each per geo
echo.
echo ============================================================
echo Done.
echo.
echo One manual step left, whenever you're ready: the Industry hub
echo page currently points "Follow on Telegram" at your existing
echo @olegmarketing_M channel (same handle already in your site
echo footer) instead of an email sign-up form. If you'd rather use
echo a real double opt-in email tool (MailerLite, Brevo,
echo Buttondown), you'll need to create that account yourself --
echo that's not something that can be done on your behalf -- and
echo then send me the form's action URL/embed code to wire in.
echo.
echo NOT included in this deploy (still pending/paused):
echo   - quiz feature (explicitly paused, unrelated to this deploy)
echo   - full dedicated author bio page (waiting on your photo/socials)
echo ============================================================
echo.
echo Next steps: review the changes in GitHub Desktop, then commit and push.
pause
