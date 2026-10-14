@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Pin-Up / Pin-Up Africa — Sports section deploy
REM
REM  What this does:
REM    Adds Pin-Up (MX, BO) and Pin-Up Africa (KE) as sportsbook
REM    cards on each geo's /sports/ page, using the SPORTS welcome
REM    bonus figures (not the casino bonus figures from the earlier
REM    deploy_pinup.bat). All numbers, license info and the CGA
REM    registry link come verbatim from the advertiser's own intake
REM    document.
REM
REM    - mx/sports, bo/sports: Pin-Up added as the 2nd sportsbook
REM      card (1xBet stays unchanged as the 1st). The old "lista de
REM      plantilla" placeholder paragraph is also corrected to the
REM      site's normal confirmed-operator wording.
REM    - ke/sports: Pin-Up Africa becomes the FIRST confirmed
REM      sportsbook card (the page previously had zero real
REM      operators there).
REM
REM  This script backs up each file it touches (.bak) before
REM  overwriting, and aborts safely if any file is missing.
REM ============================================================

set "SRC=%~dp0pinup_sports_deploy"

if not exist "%SRC%" (
    echo ERROR: Could not find pinup_sports_deploy folder next to this script.
    echo Make sure deploy_pinup_sports.bat and the pinup_sports_deploy folder
    echo were extracted into the same place.
    pause
    exit /b 1
)

if not exist "%SRC%\mx\sports\index.html" (
    echo ERROR: Missing %SRC%\mx\sports\index.html
    pause
    exit /b 1
)
if not exist "%SRC%\bo\sports\index.html" (
    echo ERROR: Missing %SRC%\bo\sports\index.html
    pause
    exit /b 1
)
if not exist "%SRC%\ke\sports\index.html" (
    echo ERROR: Missing %SRC%\ke\sports\index.html
    pause
    exit /b 1
)

if not exist "mx\sports\index.html" (
    echo ERROR: mx\sports\index.html not found in the current folder.
    echo Run this script from the root of your goclarivo-site repo.
    pause
    exit /b 1
)
if not exist "bo\sports\index.html" (
    echo ERROR: bo\sports\index.html not found in the current folder.
    echo Run this script from the root of your goclarivo-site repo.
    pause
    exit /b 1
)
if not exist "ke\sports\index.html" (
    echo ERROR: ke\sports\index.html not found in the current folder.
    echo Run this script from the root of your goclarivo-site repo.
    pause
    exit /b 1
)

echo Backing up current files...
copy /Y "mx\sports\index.html" "mx\sports\index.html.bak" >nul
copy /Y "bo\sports\index.html" "bo\sports\index.html.bak" >nul
copy /Y "ke\sports\index.html" "ke\sports\index.html.bak" >nul

echo Deploying updated files...
copy /Y "%SRC%\mx\sports\index.html" "mx\sports\index.html" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy mx\sports\index.html
    pause
    exit /b 1
)
copy /Y "%SRC%\bo\sports\index.html" "bo\sports\index.html" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy bo\sports\index.html
    pause
    exit /b 1
)
copy /Y "%SRC%\ke\sports\index.html" "ke\sports\index.html" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy ke\sports\index.html
    pause
    exit /b 1
)

echo.
echo Done. Updated files:
echo   mx\sports\index.html
echo   bo\sports\index.html
echo   ke\sports\index.html
echo.
echo Backups saved as .bak next to each file in case you need to revert.
echo.
echo Next steps: review the changes in GitHub Desktop, then commit and push.
pause
