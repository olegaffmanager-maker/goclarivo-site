@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: fix sports nav dropdown alignment +
rem  remove the now-redundant "Explora por deporte" card list
rem  --------------------------------------------------------------
rem  Two small fixes to the 7 geos with live odds data
rem  (ES, AR, BO, MX, PE, PY, EN):
rem
rem  1. The "Apuestas deportivas / Sports" dropdown in the top nav
rem     was rendering at 13px while every other nav link is 14px
rem     (confirmed with a browser check, not a guess) -- that is
rem     what made it look shifted / out of line. Fixed so it
rem     matches its neighbors exactly.
rem
rem  2. Removed the "Explora por deporte / Explore by sport" card
rem     list block from the sports hub pages -- it duplicated the
rem     nav dropdown and you asked for it to be taken off the
rem     pages. The live-odds section above it is untouched.
rem
rem  141 files total (every page in these 7 geos got the nav fix;
rem  only the 7 hub pages also lost the card block).
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root.
rem  2. Extract the delivered zip so a "nav_cards_fix" folder sits
rem     right next to this .bat file.
rem  3. Run from PowerShell: .\deploy_nav_cards_fix.bat
rem  4. GitHub Desktop -^> Changes tab should show about 141 files.
rem     Spot-check a couple of diffs, then commit and push as usual.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%nav_cards_fix"

echo ============================================================
echo  goclarivo-site: nav alignment fix + remove sport cards block
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
    echo so there is a "nav_cards_fix" folder beside it.
    echo Nothing was copied.
    pause
    exit /b 1
)

set "ALL_OK=1"

for %%G in (ar bo en es mx pe py) do (
    if not exist "%ROOT%%%G" (
        echo   [MISSING TARGET] %ROOT%%%G
        set "ALL_OK=0"
    )
    if not exist "%SRC%\%%G" (
        echo   [MISSING SOURCE] %SRC%\%%G
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

echo All paths found. Publishing...
echo.

for %%G in (ar bo en es mx pe py) do (
    xcopy "%SRC%\%%G" "%ROOT%%%G\" /E /I /Y /Q >nul
    echo   [OK] %%G\ updated
)

echo.
echo ============================================================
echo  Done. GitHub Desktop -^> Changes tab should show about 141
echo  files -- a one-line nav fix on every page in these 7 geos,
echo  plus the removed card block on the 7 sports hub pages.
echo.
echo  Spot-check a couple of diffs in GitHub Desktop before
echo  committing. If something looks wrong, use "Discard changes"
echo  instead of committing.
echo ============================================================
echo.
pause
