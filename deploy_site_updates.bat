@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Homepage + Calculator + Industry updates -- 29 files.
REM
REM  This package bundles everything from your latest request:
REM
REM  1) SUPERSEDES ranking_cards_deploy.zip for ar, mx, pe, ke, gh,
REM     en, de, it -- those 8 homepage files here already include
REM     the Mostbet / Richard Casino / Stay Casino / SlotoZen /
REM     WantedWin ranking cards from that package, PLUS the fix
REM     below. If you already ran ranking_cards_deploy.zip, running
REM     this is still safe (same content, just newer) -- if you
REM     haven't run it yet, you can skip it and just run this one.
REM
REM  2) Fixed: the hero stat tiles ("Verified casinos" / "In
REM     review" / the date) were not kept in sync with the real
REM     cards -- this is now corrected on all 15 geos. The "Last
REM     verified" date was also stuck on 3 October 2026 everywhere
REM     and is now updated to today, 15 October 2026, on all 15
REM     geos (ar, bf, bo, de, en, es, fr, gh, it, ke, mx, pe, pt,
REM     py, zm).
REM
REM  3) Bonus calculator (assets/js/bonus-calculator.js): now shows
REM     up to 3 verified operators per geo instead of 2 (your "top
REM     3" request). For geos with more than 3 verified operators
REM     (DE: 5, IT: 7) the 3 shown are simply the first 3 in
REM     casinos.json's file order -- no manual ranking was applied,
REM     per your choice. Requires casinos.json to already include
REM     Mostbet + the 4 DE/IT brands (op4_deploy.zip) to show the
REM     new operators -- if you haven't run that package yet, run
REM     it too (any order is fine, no conflict).
REM
REM  4) Industry page (13 geos -- all except bf/fr, which don't
REM     have an Industry section): added a prominent "Next on our
REM     calendar" banner announcing SiGMA World 2026 (2-5 November
REM     2026, Fiera Roma, Rome, Italy), linking to the official
REM     event site (sigma.world) -- verified via 3 independent
REM     sources (SiGMA's own site, cdcgaming.com, affpapa.com).
REM     We have not covered this event ourselves yet since it
REM     hasn't happened -- the banner honestly links out to the
REM     official site rather than linking to content that doesn't
REM     exist. The existing SBC Summit Lisbon 2026 article card
REM     (already clickable, leads to its own page) got a "Featured"
REM     badge and a bigger, nicer thumbnail.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0site_updates_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find site_updates_deploy folder next to this script.
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

echo All 29 source files found. Starting deploy...
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
echo Done.
echo.
echo What changed, in short:
echo   - 15 homepages: stat tiles + date fixed; 8 of them also
echo     have the new ranking cards (if not already deployed)
echo   - assets/js/bonus-calculator.js: now shows top 3 per geo
echo   - 13 Industry pages: SiGMA World 2026 (Rome) announcement
echo     banner + nicer featured article card
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push. Also run op4_deploy.zip first/alongside if you haven't,
echo so the calculator has the DE/IT operators to show.
echo ============================================================
pause
