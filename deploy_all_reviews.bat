@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  19 new casino review pages across 5 priority geos, plus the
REM  5 homepage files that link to them and the sitemap. 25 files
REM  change in total, several new folders are added, nothing is
REM  deleted.
REM
REM  WHAT CHANGED
REM
REM  New review pages, same honest approach as the PIN-UP Mexico
REM  pilot, only confirmed data is shown, everything else is
REM  marked no publicado rather than guessed
REM
REM  mx, 1xBet, Mostbet, 1RedBet, Melbet
REM  pe, 1xBet, Granawin, Mostbet, Melbet
REM  cl, Melbet
REM  bo, 1xBet, PIN-UP, Melbet
REM  ar, 1xBet, 20Bet, Mostbet, 1RedBet, 22bet, Betlabel, Planbet
REM
REM  Two of these, Melbet in Chile and 1xBet in Peru, have no
REM  confirmed bonus on the site yet, the bonus section on those
REM  two pages honestly says so instead of showing a number.
REM
REM  Five pages, 20Bet, 22bet, Betlabel and Planbet in Argentina
REM  and Granawin in Peru, have a bonus text that looks like
REM  generic multi country marketing copy rather than numbers
REM  confirmed for that specific country, this is flagged openly
REM  on the page itself.
REM
REM  Licence lines reuse the exact wording already on each brand
REM  card before the badges were removed, only PIN-UP and 1RedBet
REM  have a real registry link, so only those two show a verified
REM  badge, everyone else shows either declared not verifiable or
REM  not published, matching what is actually true.
REM
REM  index.html for mx, pe, cl, bo, ar -- each casino card for
REM  these brands gets a Leer resena link pointing to its new
REM  review page.
REM
REM  sitemap.xml -- all 19 new review page URLs added.
REM
REM  Backups: a .bak is created for every changed file before it
REM  is overwritten. New resenas folders have no backup since they
REM  did not exist before.
REM ============================================================

set "SRC=%~dp0batch_review_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find batch_review_deploy folder next to this script.
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
if not exist "sitemap.xml" (
    echo ERROR: sitemap.xml not found in the current folder.
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

echo All source files found. Starting the copy and backup step.
echo.

set "COUNT=0"
for /f "usebackq delims=" %%F in ("%LIST%") do (
    set "DESTDIR=%%~dpF"
    if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>&1
    if exist "%%F" copy /Y "%%F" "%%F.bak" >nul
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Copied and backed up !COUNT! files.
echo.
echo ============================================================
echo Done. 19 new review pages are live across mx, pe, cl, bo, ar,
echo linked from their casino cards, and added to the sitemap.
echo.
echo Next steps: review the changes in GitHub Desktop, then
echo commit and push.
echo ============================================================
pause
