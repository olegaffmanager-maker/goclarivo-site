@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  22bet, Betlabel and Planbet added as verified operators on
REM  the EN section, international English. Not destructive,
REM  8 files change, no folder is deleted.
REM
REM  WHAT CHANGED
REM
REM  1, en/index.html -- three new casino cards added below the
REM  existing 1xBet and Mostbet cards, using the real referral
REM  links you already confirmed for these three operators on
REM  other geos. No EN or USD specific bonus figure has been
REM  confirmed for these three yet, so the bonus line is left
REM  out of these cards, the same way it is already left out for
REM  1xBet, Mostbet and 22bet on the Kenya page. The verified
REM  casinos counter moves from 02 to 05, the in review counter
REM  moves from 08 to 05, and the in review sentence is updated
REM  to match.
REM
REM  2, en/sports and its five sport specific subpages, football,
REM  basketball, ice hockey, tennis, volleyball -- the same three
REM  cards added after 1xBet and Mostbet, this time with the
REM  honest in review bonus line, matching how 1xBet and Mostbet
REM  already show their bonus line on these pages.
REM
REM  3, assets/data/casinos.json -- en added to the countries
REM  list for 22bet, Betlabel and Planbet, plus an en entry in
REM  their bonus map set to the honest in review wording, and an
REM  en entry in their link map reusing the same referral link
REM  already live for their other geos, so the homepage quiz also
REM  correctly surfaces all three for EN visitors.
REM
REM  NOT INCLUDED
REM
REM  Pinn App was also mentioned but no data for it exists
REM  anywhere in this project yet, no link, no bonus, nothing, so
REM  nothing was built for it. Send its details the same way you
REM  sent these three and it can be added next.
REM
REM  Backups: a .bak is created for every changed file before it
REM  is overwritten.
REM ============================================================

set "SRC=%~dp0en_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find en_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "en" (
    echo ERROR: en folder not found in the current folder.
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
echo Done. 22bet, Betlabel and Planbet are now live on the EN
echo homepage and on all six EN sports pages, and the homepage
echo quiz will surface them for EN visitors too.
echo.
echo Next steps: review the changes in GitHub Desktop, then
echo commit and push.
echo ============================================================
pause
