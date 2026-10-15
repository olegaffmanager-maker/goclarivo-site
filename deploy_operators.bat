@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Add 4 new advertisers -- 1 file.
REM
REM  This updates assets/data/casinos.json. THIS PACKAGE
REM  SUPERSEDES mostbet_deploy.zip -- Mostbet's entry is already
REM  included in this file too, so if you already ran
REM  mostbet_deploy.zip, running this is still safe (it's simply
REM  overwritten again with the same data); if you haven't run it
REM  yet, you can skip it and just run this one.
REM
REM  New advertisers added (geos: de, it):
REM    - Richard Casino  (https://www.rich-l.ink/asymi66pm)
REM    - Stay Casino     (https://stay-l.ink/acij4lzcy)
REM    - SlotoZen        (https://zelinks.net/avpvegzqs)
REM    - WantedWin       (https://want-l.ink/aaygk0lvi)
REM
REM  Bonus text for "de" is taken from each brand's own DE-specific
REM  numbers (sheet or file you sent). Richard Casino and SlotoZen
REM  have NO confirmed Italy-specific bonus data anywhere (checked
REM  both the pasted text and the live Google Sheet) -- their "it"
REM  entry is honestly marked "in Prüfung"/in review rather than
REM  guessed. Stay Casino and WantedWin use one global welcome
REM  package (same for de and it, per their own brand passport).
REM
REM  Where this shows up: casinos.json only feeds the "Boni mit
REM  klaren Umsatzbedingungen" box on each geo's bonus calculator
REM  page (max 2 verified operators per geo, in file order).
REM    DE: 20Bet + Richard Casino now show (the open 2nd slot,
REM        per your choice). Stay Casino / SlotoZen / WantedWin
REM        are saved in the data but won't show on the DE
REM        calculator unless you later ask to reorder.
REM    IT: unchanged (National Casino + NeedForSlots still show)
REM        -- none of the 4 new brands show on IT yet, per your
REM        decision to leave it as-is for now.
REM
REM  No promo code was added to any of these 4 brands' bonus text
REM  (none was given, unlike Mostbet's GOCLARIVO).
REM
REM  Backup: assets/data/casinos.json.bak is created before
REM  overwriting, in case you want to revert.
REM ============================================================

set "SRC=%~dp0op4_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find op4_deploy folder next to this script.
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

echo Deployed !COUNT! file (casinos.json with Mostbet + 4 new advertisers).
echo.
echo ============================================================
echo Done.
echo.
echo Next steps: review the change in GitHub Desktop (just one
echo file, casinos.json), commit and push.
echo ============================================================
pause
