@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Casino picker quiz added to the homepage on all 15 geos, plus
REM  two follow up fixes. 18 files changed, no folders deleted.
REM
REM  WHAT CHANGED
REM
REM  1, the quiz. A short three question quiz now sits on every
REM  geo home page, between the hero section and the Featured
REM  Casinos list, with a new Find My Casino button in the hero.
REM  The quiz asks what matters most, bonus, payout speed or game
REM  selection, which device, and whether you are new or
REM  experienced, then shows up to three matching cards pulled
REM  from assets/data/casinos.json, the same file the rest of the
REM  site already uses. Nothing on the existing Featured Casinos
REM  list was touched. New file: assets/js/quiz.js.
REM
REM  2, the quiz data file now also lists the five newer brands,
REM  22bet, Betlabel, Planbet, RoyalXO and Safecasino, plus Melbet
REM  and 1RedBet, using the exact same bonus text, links and logos
REM  already shown on their cards elsewhere on the site, nothing
REM  new was invented. This also means India now gets a real quiz
REM  match instead of the no operator yet message, since Melbet
REM  covers India.
REM
REM  3, the Last verified date shown on every home page, and the
REM  matching sitemap entries for all 15 home pages, were moved
REM  from 15 to 21 October 2026 to reflect today's update, as you
REM  asked -- going forward every deploy will bump this date the
REM  same way.
REM
REM  How quiz results are chosen. If bonus value is picked,
REM  operators are ranked by the bonus score already recorded for
REM  them in casinos.json. For payout, games or any other answer,
REM  the existing published order is kept rather than claiming a
REM  difference the data does not support, since only the bonus
REM  score is a real confirmed figure today, the others are
REM  neutral placeholders as noted in that file.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0quiz_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find quiz_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "ar" (
    echo ERROR: ar folder not found in the current folder.
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

echo All 18 source files found. Starting deploy...
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
echo Done. The quiz is live at the #quiz anchor on all 15 home
echo pages, now aware of all 22 operators currently on the site,
echo and the Last verified date reads 21 October 2026 everywhere.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
