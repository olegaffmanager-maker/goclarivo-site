@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: nav fixes + Champions League / La Liga pages
rem  --------------------------------------------------------------
rem  Everything from today's conversation, in one package (supersedes
rem  the earlier small nav_cards_fix_deploy.zip -- this one already
rem  includes both of its fixes, so you only need to run THIS script,
rem  not both):
rem
rem  1. Nav dropdown alignment fix (font-size 13px -^> 14px to match
rem     its neighbors) -- same fix as before.
rem  2. Removed the redundant "Explora por deporte" card list from the
rem     sports hub pages -- same fix as before.
rem  3. NEW: the 5 sport emoji in the dropdown are replaced with a
rem     consistent custom icon set.
rem  4. NEW: "Liga de Campeones" and "La Liga" added to the dropdown,
rem     below a thin divider, for all 7 geos.
rem  5. NEW: 13 new pages -- a Champions League guide and a La Liga
rem     guide for ar/bo/mx/pe/py/en (6 geos x 2), plus a La Liga guide
rem     for es (es already had Champions League). Each shows a REAL,
rem     auto-refreshing odds widget filtered to just that competition
rem     (not invented fixtures), and the real verified-operator cards
rem     for that geo.
rem  6. FIXED: the existing ES Champions League page used to show
rem     hand-typed, non-updating match data despite claiming it
rem     auto-refreshes -- it now uses the same real live widget as the
rem     13 new pages.
rem  7. scripts\onexbet_odds.py updated to fetch and inject those two
rem     new widgets every 30 minutes, and a real bug fix: a simulated
rem     ("VirtuaComp: La Liga") match was slipping past the existing
rem     virtual-match filter -- confirmed directly from a screenshot
rem     you sent earlier, now excluded.
rem  8. sitemap.xml updated with the 13 new page URLs.
rem
rem  154 page files total (all pages in these 7 geos carry the nav
rem  dropdown; 13 of those are brand new), plus the script and the
rem  sitemap.
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root.
rem  2. Extract the delivered zip so a "sports_dropdown_fix" folder
rem     sits right next to this .bat file.
rem  3. Run from PowerShell: .\deploy_sports_dropdown_fix.bat
rem  4. GitHub Desktop -^> Changes tab should show about 156 files
rem     (154 pages + the script + the sitemap). Spot-check a few,
rem     then commit and push as usual. Do NOT commit the .bak files.
rem  5. After pushing, the next scheduled "Rebuild 1xBet odds widget"
rem     run (or a manual "Run workflow") will fill in the real
rem     Champions League / La Liga matches on all 14 league pages.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%sports_dropdown_fix"

echo ============================================================
echo  goclarivo-site: nav fixes + Champions League / La Liga pages
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
    echo so there is a "sports_dropdown_fix" folder beside it.
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
echo Copying the 7 geo folders (nav fixes + icons + leagues + 13 new pages)...
echo.

for %%G in (ar bo en es mx pe py) do (
    xcopy "%SRC%\%%G" "%ROOT%%%G\" /E /I /Y /Q >nul
    echo   [OK] %%G\ updated
)

echo.
echo ============================================================
echo  Done. GitHub Desktop -^> Changes tab should show roughly 156
echo  files -- every page in these 7 geos got the nav dropdown
echo  update, 13 of those are brand-new Champions League / La Liga
echo  pages, plus the updated script and sitemap. The .bak files
echo  are untracked backups -- do NOT commit them.
echo.
echo  Spot-check a few file diffs in GitHub Desktop before
echo  committing. If something looks wrong, use "Discard changes"
echo  instead of committing.
echo ============================================================
echo.
pause
