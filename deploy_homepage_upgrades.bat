@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: deploy homepage upgrades (EN pilot)
rem  --------------------------------------------------------------
rem  What this does: copies ONE already-reviewed index.html from a
rem  "homepage_upgrades_fix" folder (next to this script) into
rem  en\index.html. This is a pilot on a single geo -- EN only.
rem
rem  What was added to en\index.html (nothing removed, nothing else
rem  touched): a trust strip under the hero buttons, a thin progress
rem  bar under the hero stats, a methodology-weights row reusing the
rem  site's own stat tiles, and a 3-question FAQ preview between the
rem  Featured Casino section and How We Rate.
rem
rem  Note: en\index.html IS the homepage. As always with homepage
rem  edits, this script backs up the current file to
rem  en\index.html.bak before overwriting it.
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root.
rem  2. Extract the delivered zip so a "homepage_upgrades_fix" folder
rem     sits right next to this .bat file.
rem  3. Run this script from PowerShell with: .\deploy_homepage_upgrades.bat
rem  4. Open GitHub Desktop -^> Changes tab. You should see EXACTLY
rem     ONE changed file: en\index.html. Do NOT commit the .bak file.
rem  5. Open the live site at /en/ and check it looks right before
rem     deciding whether to roll this out to the other geos.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%homepage_upgrades_fix"

echo ============================================================
echo  goclarivo-site: deploy homepage upgrades - EN pilot
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
    echo so there is a "homepage_upgrades_fix" folder beside it.
    echo Nothing was copied.
    pause
    exit /b 1
)

set "TARGET_FILE=%ROOT%en\index.html"
set "SRC_FILE=%SRC%\en\index.html"

if not exist "%TARGET_FILE%" (
    echo ERROR: Could not find %TARGET_FILE%
    echo This script may not be in the real repo root.
    pause
    exit /b 1
)
if not exist "%SRC_FILE%" (
    echo ERROR: Could not find %SRC_FILE%
    echo Did the zip extract correctly, with an "en" subfolder inside homepage_upgrades_fix?
    pause
    exit /b 1
)

echo Both paths found. Backing up current homepage, then copying the new one...
echo.

copy /Y "%TARGET_FILE%" "%TARGET_FILE%.bak" >nul
copy /Y "%SRC_FILE%" "%TARGET_FILE%" >nul
if errorlevel 1 (
    echo   [FAILED] en\index.html
) else (
    echo   [OK] en\index.html updated -- previous version saved as en\index.html.bak
)

echo.
echo ============================================================
echo  Done. Only en\index.html was touched -- no other geo, nothing
echo  else.
echo.
echo  Next: open GitHub Desktop -^> Changes tab. You should see
echo  EXACTLY ONE changed file: en\index.html. The .bak file is an
echo  untracked backup -- do NOT commit it.
echo  Then check the live /en/ page before deciding on the other geos.
echo ============================================================
echo.
pause
