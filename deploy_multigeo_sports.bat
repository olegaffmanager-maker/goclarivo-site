@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: roll out per-sport pages + nav dropdown
rem  to all 7 geos with a real 1xBet feed (ES, AR, BO, MX, PE, PY, EN)
rem  --------------------------------------------------------------
rem  This is a BIG update -- 143 files -- because the new "Apuestas
rem  deportivas / Sports" dropdown menu in the header touches every
rem  single page in these 7 geos (one line each: the old plain nav
rem  link becomes a dropdown with links to all 5 sports). Plus 30
rem  new per-sport pages (5 per geo x 6 new geos -- ES already had
rem  its 5 from the earlier pilot), the 7 "sports" hub pages, the
rem  sitemap, and the automation script.
rem
rem  Because this touches almost every page, individual .bak backups
rem  for all 143 files would be impractical clutter. Instead:
rem    - sitemap.xml and scripts\onexbet_odds.py (the two files where
rem      a mistake would be hardest to spot/undo by eye) still get
rem      their own .bak backup, as always.
rem    - every other file is plain copied over the existing one.
rem      Your safety net for those is GitHub Desktop itself: AFTER
rem      running this script, open the Changes tab and spot-check a
rem      few files' diffs (each should show just the nav line
rem      changing, except the 7 sports/index.html hub pages which
rem      show a bigger intentional change). If anything looks wrong,
rem      use "Discard changes" in GitHub Desktop instead of
rem      committing -- that fully reverts everything this script
rem      touched, back to your last pushed version.
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root.
rem  2. Extract the delivered zip so a "multigeo_fix" folder sits
rem     right next to this .bat file.
rem  3. Run from PowerShell: .\deploy_multigeo_sports.bat
rem  4. GitHub Desktop -^> Changes tab should show about 143 files.
rem     Spot-check a few, then commit and push as usual. Do NOT
rem     commit the .bak files.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%multigeo_fix"

echo ============================================================
echo  goclarivo-site: per-sport pages + nav dropdown - 7 geos
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
    echo so there is a "multigeo_fix" folder beside it.
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
if not exist "%ROOT%sitemap.xml" (
    echo   [MISSING TARGET] %ROOT%sitemap.xml
    set "ALL_OK=0"
)
if not exist "%SRC%\sitemap.xml" (
    echo   [MISSING SOURCE] %SRC%\sitemap.xml
    set "ALL_OK=0"
)
if not exist "%ROOT%scripts\onexbet_odds.py" (
    echo   [MISSING TARGET] %ROOT%scripts\onexbet_odds.py
    set "ALL_OK=0"
)
if not exist "%SRC%\scripts\onexbet_odds.py" (
    echo   [MISSING SOURCE] %SRC%\scripts\onexbet_odds.py
    set "ALL_OK=0"
)

if "!ALL_OK!"=="0" (
    echo.
    echo Stopped -- fix the problems listed above and run this script again.
    echo Nothing was copied.
    pause
    exit /b 1
)

echo All paths found. Backing up the two critical files, then publishing...
echo.

copy /Y "%ROOT%sitemap.xml" "%ROOT%sitemap.xml.bak" >nul
copy /Y "%SRC%\sitemap.xml" "%ROOT%sitemap.xml" >nul
echo   [OK] sitemap.xml updated -- backup at sitemap.xml.bak

copy /Y "%ROOT%scripts\onexbet_odds.py" "%ROOT%scripts\onexbet_odds.py.bak" >nul
copy /Y "%SRC%\scripts\onexbet_odds.py" "%ROOT%scripts\onexbet_odds.py" >nul
echo   [OK] scripts\onexbet_odds.py updated -- backup at scripts\onexbet_odds.py.bak

echo.
echo Copying the 7 geo folders (new pages + nav updates on every page)...
echo.

for %%G in (ar bo en es mx pe py) do (
    xcopy "%SRC%\%%G" "%ROOT%%%G\" /E /I /Y /Q >nul
    echo   [OK] %%G\ updated
)

echo.
echo ============================================================
echo  Done. GitHub Desktop -^> Changes tab should show about 143
echo  files -- almost every page in ar, bo, en, es, mx, pe, py got
echo  a one-line nav change, plus 30 new per-sport pages and the 7
echo  updated sports hub pages. sitemap.xml and
echo  scripts\onexbet_odds.py also changed. The .bak files are
echo  untracked backups -- do NOT commit them.
echo.
echo  Spot-check a few file diffs in GitHub Desktop before
echo  committing. If something looks wrong, use "Discard changes"
echo  instead of committing.
echo ============================================================
echo.
pause
