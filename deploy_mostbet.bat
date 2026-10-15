@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Add Mostbet as a new advertiser -- 1 file.
REM
REM  This updates assets/data/casinos.json to add Mostbet, based
REM  on the advertiser form you sent (brand, Curacao license,
REM  referral link https://oikimjmb.com/mqtU, promo code
REM  GOCLARIVO) plus the real brand colors/logo shape from the
REM  Mostbet brandbook PDF you sent (orange #FB4D00 circle with a
REM  white star replacing the "O", white "M" and "STBET").
REM
REM  Where this shows up on the site: casinos.json only feeds the
REM  "Bonuses with clear wagering terms" box on each geo's bonus
REM  calculator page (up to 2 verified operators per geo, in
REM  file order). Mostbet was added for geos: ar, mx, pe, ke, gh,
REM  en (International).
REM
REM  Confirmed showing after this deploy: en, gh (both currently
REM  have fewer than 2 verified operators, so Mostbet fills the
REM  open slot).
REM  NOT shown yet (slot already full with 2 other verified
REM  operators -- per your decision, left as-is for now): ar, mx,
REM  pe, ke. The Mostbet data is still saved in casinos.json for
REM  these geos, it's just not surfaced on the calculator page
REM  unless you later ask to reorder/replace an existing operator
REM  there.
REM
REM  Bonus text per geo was taken directly from your bonus sheet
REM  (the "TOTAL" column, combined sport+casino headline offer).
REM  The "en" (International) bonus is marked "in review" because
REM  the form had no actual bonus text for that geo -- only
REM  general company info (founding year, currencies, languages).
REM  Send real International bonus copy whenever you have it and
REM  this can be updated.
REM
REM  Backup: assets/data/casinos.json.bak is created before
REM  overwriting, in case you want to revert.
REM ============================================================

set "SRC=%~dp0mostbet_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find mostbet_deploy folder next to this script.
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

echo Source file found. Starting deploy...
echo.

set "COUNT=0"
for /f "usebackq delims=" %%F in ("%LIST%") do (
    set "DESTDIR=%%~dpF"
    if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>&1
    if exist "%%F" copy /Y "%%F" "%%F.bak" >nul
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Deployed !COUNT! file (casinos.json with Mostbet added).
echo.
echo ============================================================
echo Done.
echo.
echo Next steps: review the change in GitHub Desktop (just one
echo file, casinos.json), commit and push.
echo ============================================================
pause
