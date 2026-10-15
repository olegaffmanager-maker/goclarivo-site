@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  7 new Q&A guide pages (EN+ES) -- INCREMENTAL deploy, 70 files.
REM
REM  IMPORTANT: unlike previous packages, this one is NOT a full
REM  "everything" supersede -- it's too big to send as one file
REM  together with the calculator/author/Industry pages (which
REM  haven't changed), so this package only contains the 70 BRAND
REM  NEW files below. Run this AFTER you've already deployed
REM  calc_industry_full.zip (or any later full package) at least
REM  once. If you haven't deployed that one yet, deploy it first,
REM  then run this.
REM
REM  New pages added to EN geos (en, gh, ke, zm) and ES geos
REM  (ar, bo, es, mx, pe, py) = 70 new pages total:
REM    1) What is a wagering requirement, explained simply
REM    2) What happens if you don't complete wagering
REM    3) Why won't the casino pay out: 7 reasons
REM    4) Why does the casino ask for documents (KYC)
REM    5) How to check a casino's license in 5 minutes
REM    6) How long does a casino withdrawal take
REM    7) How to choose your first online casino
REM  Each page has a direct-answer box, a visible FAQ accordion
REM  with matching FAQPage JSON-LD, a "what to do next" box
REM  linking to 3 related pages, and (where a real external
REM  source applies) a short sources list.
REM
REM  NOT included (deliberately deferred per your decision --
REM  revisit once the operator roster is more complete across all
REM  geos, and for Kenya once the pending gambling-law court case
REM  is resolved):
REM    - 3 country legal-status pages (Argentina/Mexico/Kenya)
REM    - 3 payment-method pages (M-Pesa/Mercado Pago/OXXO)
REM  Also not included: the full dedicated author bio page (still
REM  waiting on your photo/social links) and the quiz feature
REM  (still paused).
REM
REM  No nav/homepage changes in this package -- these 70 pages
REM  are reachable only via internal "what to do next" links
REM  between themselves and the existing wagering guide/
REM  calculator/trustworthy-casino pages, by design.
REM
REM  All 70 files here are brand new -- nothing to back up, but
REM  the script still checks and creates a .bak just in case you
REM  run it twice or a file somehow already exists.
REM ============================================================

set "SRC=%~dp0calc_qna_only_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find calc_qna_only_deploy folder next to this script.
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

REM --- pre-flight: confirm every one of the 70 source files exists ---
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

echo All 70 source files found. Starting deploy...
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

echo Deployed !COUNT! new Q&A guide pages.
echo.
echo ============================================================
echo Done.
echo.
echo Reminder -- NOT included in this deploy (still pending/deferred):
echo   - 3 country legal-status pages (AR/MX/KE)
echo   - 3 payment-method pages (M-Pesa/Mercado Pago/OXXO)
echo   - quiz feature (explicitly paused)
echo   - full dedicated author bio page (waiting on your photo/socials)
echo ============================================================
echo.
echo Next steps: review the changes in GitHub Desktop, then commit and push.
pause
