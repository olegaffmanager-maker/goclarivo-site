@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: fix auto-refresh for new sport pages +
rem  add a read-only "list sports" diagnostic workflow
rem  --------------------------------------------------------------
rem  Two things in this one:
rem
rem  1. BUG FIX: the scheduled job that refreshes odds every 30 min
rem     only ever committed the 7 "sports\index.html" hub pages --
rem     it never picked up the 35 new per-sport pages added earlier
rem     today (es\sports\futbol\index.html and so on), because the
rem     commit step's file pattern didn't reach one folder deeper.
rem     Confirmed on the run you just showed me: it updated those
rem     pages locally but never committed them, so they'd have
rem     quietly gone stale forever. This fixes
rem     .github\workflows\rebuild-1xbet-odds.yml so both page depths
rem     get committed from now on.
rem
rem  2. New file scripts\list_sports.py and a new workflow
rem     .github\workflows\list-sports-diagnostic.yml -- a manual-only,
rem     read-only check against the real 1xBet API to see whether it
rem     has a genuine esports/cybersport category, before building
rem     anything for it. It changes nothing on the site; it only
rem     prints what the API reports.
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root.
rem  2. Extract the delivered zip so an "esports_check_fix" folder
rem     sits right next to this .bat file.
rem  3. Run from PowerShell: .\deploy_esports_check.bat
rem  4. GitHub Desktop -^> Changes tab should show 3 files: one
rem     modified (.github\workflows\rebuild-1xbet-odds.yml) and two
rem     new. Commit and push as usual.
rem  5. After pushing, go to the Actions tab on GitHub -^> pick
rem     "List 1xBet sports (diagnostic)" in the left list -^> click
rem     "Run workflow" -^> wait about 10-20 seconds -^> open the run,
rem     expand "List sports from the API", and send me a screenshot
rem     of the output.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%esports_check_fix"

echo ============================================================
echo  goclarivo-site: auto-refresh fix + sports diagnostic
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
    echo so there is an "esports_check_fix" folder beside it.
    echo Nothing was copied.
    pause
    exit /b 1
)

set "ALL_OK=1"

if not exist "%ROOT%.github\workflows\rebuild-1xbet-odds.yml" (
    echo   [MISSING TARGET] %ROOT%.github\workflows\rebuild-1xbet-odds.yml
    set "ALL_OK=0"
)
if not exist "%SRC%\.github\workflows\rebuild-1xbet-odds.yml" (
    echo   [MISSING SOURCE] %SRC%\.github\workflows\rebuild-1xbet-odds.yml
    set "ALL_OK=0"
)
if not exist "%SRC%\.github\workflows\list-sports-diagnostic.yml" (
    echo   [MISSING SOURCE] %SRC%\.github\workflows\list-sports-diagnostic.yml
    set "ALL_OK=0"
)
if not exist "%SRC%\scripts\list_sports.py" (
    echo   [MISSING SOURCE] %SRC%\scripts\list_sports.py
    set "ALL_OK=0"
)

if "!ALL_OK!"=="0" (
    echo.
    echo Stopped -- fix the problems listed above and run this script again.
    echo Nothing was copied.
    pause
    exit /b 1
)

echo All paths found. Backing up, then publishing...
echo.

copy /Y "%ROOT%.github\workflows\rebuild-1xbet-odds.yml" "%ROOT%.github\workflows\rebuild-1xbet-odds.yml.bak" >nul
copy /Y "%SRC%\.github\workflows\rebuild-1xbet-odds.yml" "%ROOT%.github\workflows\rebuild-1xbet-odds.yml" >nul
echo   [OK] .github\workflows\rebuild-1xbet-odds.yml updated -- backup at .bak

copy /Y "%SRC%\.github\workflows\list-sports-diagnostic.yml" "%ROOT%.github\workflows\list-sports-diagnostic.yml" >nul
echo   [OK] .github\workflows\list-sports-diagnostic.yml published - new workflow

copy /Y "%SRC%\scripts\list_sports.py" "%ROOT%scripts\list_sports.py" >nul
echo   [OK] scripts\list_sports.py published - new file

echo.
echo ============================================================
echo  Done. GitHub Desktop -^> Changes tab should show 3 files.
echo  Commit and push, then go to the Actions tab on GitHub and
echo  manually run "List 1xBet sports (diagnostic)" -- see the
echo  instructions at the top of this script for exact steps.
echo ============================================================
echo.
pause
