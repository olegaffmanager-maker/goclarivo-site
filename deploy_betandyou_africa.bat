@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: add BetAndYou Africa as the featured operator
rem  on gh, ke, zm and bf
rem  --------------------------------------------------------------
rem  What this does:
rem  1. Replaces the generic "Casinos in Review" / "Casinos en cours
rem     de verification" placeholder on gh/index.html, ke/index.html,
rem     zm/index.html and bf/index.html with a real "Featured Casino"
rem     / "Casino a la une" card for BetAndYou Africa -- same card
rem     structure already used for 1xBet on en/index.html.
rem  2. Card shows: your affiliate link, your promo code GOAFRICA, the
rem     per-geo first-deposit bonus amount from the advertiser's own
rem     intake form, and an honest license line (Nevis Online Gaming
rem     Authority, licence LIC-B2C202607C633240002) shown as
rem     operator-provided data.
rem  3. "Operators in review" count drops from 10 to 9 on each page,
rem     since one of the ten is now a real, shown operator.
rem  4. Only these 4 files change. Nothing else on the site is
rem     touched.
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root.
rem  2. Extract the delivered zip so a "betandyou_deploy" folder sits
rem     right next to this .bat file.
rem  3. Run from PowerShell: .\deploy_betandyou_africa.bat
rem  4. GitHub Desktop -^> Changes tab should show exactly 4 files
rem     changed: gh/index.html, ke/index.html, zm/index.html,
rem     bf/index.html. Spot-check the diffs, then commit and push.
rem     Do NOT commit the .bak files.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%betandyou_deploy"

echo ============================================================
echo  goclarivo-site: add BetAndYou Africa (gh / ke / zm / bf)
echo ============================================================
echo.
echo Repo root:     %ROOT%
echo Source folder: %SRC%
echo.

if not exist "%SRC%" (
    echo ERROR: Could not find the folder:
    echo   %SRC%
    echo.
    echo Extract the delivered zip HERE, right next to this .bat file,
    echo so there is a "betandyou_deploy" folder beside it.
    echo Nothing was copied.
    pause
    exit /b 1
)

set "ALL_OK=1"

for %%G in (gh ke zm bf) do (
    if not exist "%ROOT%%%G\index.html" (
        echo   [MISSING TARGET] %ROOT%%%G\index.html
        set "ALL_OK=0"
    )
    if not exist "%SRC%\%%G\index.html" (
        echo   [MISSING SOURCE] %SRC%\%%G\index.html
        set "ALL_OK=0"
    )
)

if "!ALL_OK!"=="0" (
    echo.
    echo Stopped -- fix the problems listed above and run this script again.
    echo Nothing was copied.
    pause
    exit /b 1
)

echo All paths found. Backing up the 4 files, then publishing...
echo.

for %%G in (gh ke zm bf) do (
    copy /Y "%ROOT%%%G\index.html" "%ROOT%%%G\index.html.bak" >nul
    copy /Y "%SRC%\%%G\index.html" "%ROOT%%%G\index.html" >nul
    echo   [OK] %%G\index.html updated -- backup at %%G\index.html.bak
)

echo.
echo ============================================================
echo  Done. GitHub Desktop -^> Changes tab should show exactly 4
echo  files: gh/index.html, ke/index.html, zm/index.html,
echo  bf/index.html. The .bak files are untracked backups -- do
echo  NOT commit them.
echo.
echo  Spot-check the diffs in GitHub Desktop before committing.
echo  If something looks wrong, use "Discard changes" instead of
echo  committing.
echo ============================================================
echo.
pause
