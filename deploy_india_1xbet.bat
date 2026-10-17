@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  India wording softened, plus 1xBet added for gh, ke, zm, bf.
REM  6 files changed, no folders deleted.
REM
REM  WHAT CHANGED
REM
REM  1, in/index.html and in/responsible-gambling/index.html.
REM  Per your instruction, the absolute banned/illegal wording
REM  was softened. The page no longer says casinos are banned
REM  or that offering or advertising them is explicitly illegal.
REM  It now says the legal status for Indian users is unsettled
REM  and restricted, and points to the Responsible Gambling page.
REM  Every fact was kept exactly as it was -- state names, the
REM  2026 Supreme Court ruling date, the Promotion and Regulation
REM  of Online Gaming Act 2025 and its 1 May 2026 effective date,
REM  the exact penalty figures for offering, advertising and
REM  facilitating payments, and the bank account freezing detail.
REM  Nothing was deleted, only the tone of a few sentences.
REM
REM  2, gh, ke, zm, bf index pages. Added a 1xBet card as the
REM  first card on each page, same position as you asked. Used
REM  the real referral link already live on your other geos --
REM  no made up tracking parameters. No bonus line is shown
REM  since there is no confirmed bonus for 1xBet on these geos,
REM  the same honest pattern already used for 1xBet on en, es,
REM  pe and in. Licence line reads not published by the operator,
REM  French on bf, English on gh, ke, zm, matching the wording
REM  already used for 1xBet elsewhere on the site. Verification
REM  badge and editorial status match every other card on the
REM  page, unchanged from the site's current pattern.
REM
REM  ke/sports/index.html was NOT touched -- it only shows one
REM  card, PIN-UP Africa, and gh/sports, zm/sports and bf/sports
REM  show no operator cards at all, so this is a separate, older
REM  page layout, not the same ranking as the homepage. Say the
REM  word if you want 1xBet added there too.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0round2_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find round2_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "in" (
    echo ERROR: in folder not found in the current folder.
    echo Run this script from the root of your goclarivo-site repo.
    pause
    exit /b 1
)
if not exist "gh" (
    echo ERROR: gh folder not found in the current folder.
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

echo All 6 source files found. Starting deploy...
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
echo Done. India wording is softened on in and in responsible
echo gambling, substance kept. 1xBet is added first on gh, ke,
echo zm and bf.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
