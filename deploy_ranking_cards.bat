@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Add real casino-card entries to the "Casinos" ranking
REM  section (#top-liste) on the homepage -- 8 files.
REM
REM  This is DIFFERENT from mostbet_deploy.zip and op4_deploy.zip:
REM  those two only updated assets/data/casinos.json, which feeds
REM  the small bonus-calculator widget. THIS package edits each
REM  geo's own index.html directly, adding a real, visible
REM  casino-card in the main "Casinos" ranking list on the
REM  homepage (the one you see via the "Casinos" menu link).
REM  Run this regardless of whether you already ran the other two
REM  -- it does not touch casinos.json at all, no conflict.
REM
REM  Cards added:
REM    ar, mx, pe, ke, gh, en  -> + Mostbet
REM    de, it                  -> + Richard Casino, Stay Casino,
REM                                 SlotoZen, WantedWin
REM
REM  Each card uses the exact same layout/badges as your existing
REM  cards (green "Verified" + amber "In progress" editorial
REM  badge, same as every other operator already listed -- this
REM  matches your site's own established convention, not a new
REM  standard). Bonus text is the same verbatim per-geo text
REM  already used in casinos.json. Where a brand has no confirmed
REM  bonus data for a geo (Richard Casino / SlotoZen on IT,
REM  Mostbet on en/International), the card honestly says
REM  "in review" instead of guessing, and skips repeating that
REM  placeholder text inside the verification grid.
REM
REM  The "X more operators in review" counter at the bottom of
REM  each ranking section was decreased by exactly the number of
REM  cards added on that geo (e.g. ar: 9 -> 8, de: 10 -> 6, it:
REM  8 -> 4). This is my own assumption since it's your internal
REM  pipeline number -- if the real number should be different,
REM  just edit the text directly in GitHub Desktop after this
REM  runs, or tell me the correct number and I'll send a fix.
REM
REM  Backups: index.html.bak created for all 8 files before
REM  overwriting, in case you want to revert.
REM ============================================================

set "SRC=%~dp0ranking_cards_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find ranking_cards_deploy folder next to this script.
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

echo All 8 source files found. Starting deploy...
echo.

set "COUNT=0"
for /f "usebackq delims=" %%F in ("%LIST%") do (
    set "DESTDIR=%%~dpF"
    if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>&1
    if exist "%%F" copy /Y "%%F" "%%F.bak" >nul
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Deployed !COUNT! homepage files (ar, mx, pe, ke, gh, en, de, it).
echo.
echo ============================================================
echo Done.
echo.
echo What changed, in short:
echo   ar/mx/pe/ke/gh/en -- + Mostbet card in the Casinos ranking
echo   de/it -- + Richard Casino, Stay Casino, SlotoZen, WantedWin
echo            cards in the Casinos ranking
echo.
echo Next steps: review the changes in GitHub Desktop (8 files,
echo one index.html per geo), commit and push.
echo ============================================================
pause
