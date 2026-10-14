@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: add Pin-Up (MX, BO) and Pin-Up Africa (KE)
rem  as a second confirmed operator
rem  --------------------------------------------------------------
rem  What this does:
rem  1. Adds a real "PIN-UP" card to mx/index.html and bo/index.html,
rem     right below the existing 1xBet card -- same card structure
rem     already used for 1xBet and BetAndYou Africa.
rem  2. Adds a real "PIN-UP Africa" card to ke/index.html, right below
rem     the existing BetAndYou Africa card.
rem  3. Every number in these cards (bonus amount, license number,
rem     registration number) comes verbatim from Pin-Up's own intake
rem     document -- nothing invented. The license line links to the
rem     operator's real public registry entry at cert.cga.cw.
rem  4. Section headings switch from singular ("Casino destacado" /
rem     "Featured Casino") to plural, and the "more operators in
rem     review" counters drop by one on all three pages, since one of
rem     those operators is now a real, shown card.
rem  5. Only these 3 files change: mx/index.html, bo/index.html,
rem     ke/index.html. Nothing else on the site is touched.
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root.
rem  2. Extract the delivered zip so a "pinup_deploy" folder sits
rem     right next to this .bat file.
rem  3. Run from PowerShell: .\deploy_pinup.bat
rem  4. GitHub Desktop -^> Changes tab should show exactly 3 files
rem     changed: mx/index.html, bo/index.html, ke/index.html.
rem     Spot-check the diffs, then commit and push.
rem     Do NOT commit the .bak files.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%pinup_deploy"

echo ============================================================
echo  goclarivo-site: add Pin-Up (MX, BO) and Pin-Up Africa (KE)
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
    echo so there is a "pinup_deploy" folder beside it.
    echo Nothing was copied.
    pause
    exit /b 1
)

set "ALL_OK=1"

for %%G in (mx bo ke) do (
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

echo All paths found. Backing up the 3 files, then publishing...
echo.

for %%G in (mx bo ke) do (
    copy /Y "%ROOT%%%G\index.html" "%ROOT%%%G\index.html.bak" >nul
    copy /Y "%SRC%\%%G\index.html" "%ROOT%%%G\index.html" >nul
    echo   [OK] %%G\index.html updated -- backup at %%G\index.html.bak
)

echo.
echo ============================================================
echo  Done. GitHub Desktop -^> Changes tab should show exactly 3
echo  files: mx/index.html, bo/index.html, ke/index.html.
echo.
echo  Spot-check the diffs in GitHub Desktop before committing.
echo  If something looks wrong, use "Discard changes" instead of
echo  committing. The .bak files are untracked backups -- do NOT
echo  commit them.
echo ============================================================
echo.
pause
