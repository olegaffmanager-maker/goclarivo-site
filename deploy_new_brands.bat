@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Five new operator cards added: 22bet, Betlabel, Planbet,
REM  RoyalXO, Safecasino. 26 files changed, no folders deleted.
REM
REM  WHAT CHANGED
REM
REM  1, main ranking pages. New cards were added to the end of
REM  the existing list on de, ar, es, it, pt, ke and zm, per your
REM  brand to geo list. Nothing already on these pages was
REM  removed, reordered or edited.
REM
REM  2, sports pages. The same new cards were added to the sports
REM  section of the same geos, home page and sports page always
REM  match now. On de, it, pt and zm the sports section had zero
REM  real cards before and said so in its own wording, so that
REM  placeholder heading and intro text was replaced with a real
REM  one and the now empty more operators in review box was
REM  removed there, the same honest pattern already used earlier
REM  this project for ar, bo, es, mx, pe, py, en and ke. On ar, es
REM  and ke the new cards were simply appended to the sports list
REM  that already existed.
REM
REM  3, licence lines. 22bet, Betlabel and Planbet gave Curacao as
REM  their regulator with no licence number and no registry link,
REM  so the card says Curacao plus a plain note that the licence
REM  number is not published by the operator -- the regulator
REM  name is shown as given, nothing beyond that is claimed.
REM  RoyalXO and Safecasino sent back blank forms, no licence, no
REM  bonus, no payment details, so those two cards say licence
REM  not published and show no bonus line, the same honest
REM  pattern already used for 1xBet on gh, ke, zm and bf earlier.
REM
REM  4, bonus text. Where the advertiser form gave a bonus that
REM  explicitly covers that page type, casino or sport, that exact
REM  figure is shown, translated into the page's own language
REM  with every number, percentage and condition kept as given.
REM  Nothing was invented for RoyalXO or Safecasino since none was
REM  provided.
REM
REM  5, two new logo files. RoyalXO and Safecasino sent their
REM  logos as very large exported files, hundreds of kilobytes
REM  each, which would have slowed every page they appear on. The
REM  artwork itself was not changed, only compressed and saved as
REM  assets/img/royalxo-logo.webp and assets/img/safecasino-
REM  logo.webp, which the new cards load from. 22bet, Betlabel and
REM  Planbet arrived as small vector files already, so those are
REM  embedded directly in the page the same way other logos on
REM  the site already are.
REM
REM  Referral links used are exactly the five you sent, one per
REM  brand, used as is on every page -- no tracking parameters
REM  were added or guessed.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0new_brands_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find new_brands_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "de" (
    echo ERROR: de folder not found in the current folder.
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

echo All 26 source files found. Starting deploy...
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
echo Done. 22bet is now on ar, es, it, pt, ke and zm. Betlabel is
echo now on de, ar, es, it and pt. Planbet is now on de, ar, it
echo and pt. RoyalXO is now on de and it. Safecasino is now on es
echo and it. Each one appears on both the main ranking page and
echo the sports section for its geos.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
