@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: deploy per-sport pages (ES pilot)
rem  --------------------------------------------------------------
rem  What this does: publishes 5 NEW pages and updates 3 existing
rem  files, all from a "sport_pages_fix" folder (next to this
rem  script):
rem
rem    NEW pages (real live odds, same 1xBet feed as before):
rem      1. es\sports\futbol\index.html
rem      2. es\sports\baloncesto\index.html
rem      3. es\sports\tenis\index.html
rem      4. es\sports\hockey-sobre-hielo\index.html
rem      5. es\sports\voleibol\index.html
rem
rem    UPDATED files:
rem      6. es\sports\index.html   -- football widget stays inline
rem         as before, the other 4 sports' tabs are replaced with a
rem         simple link list to their own new pages above.
rem      7. sitemap.xml            -- 5 new entries added.
rem      8. scripts\onexbet_odds.py -- the automated 30-minute
rem         refresh job now also keeps the 5 new ES pages updated
rem         with live data. This change only affects ES; every
rem         other geo keeps writing to its own sports\index.html
rem         exactly as before, nothing else changes for them.
rem
rem  es\sports\index.html and sitemap.xml are homepages/shared
rem  files, so as always they get backed up to .bak before being
rem  overwritten. scripts\onexbet_odds.py also gets backed up the
rem  same way, since it is a working automation script.
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root.
rem  2. Extract the delivered zip so a "sport_pages_fix" folder
rem     sits right next to this .bat file.
rem  3. Run from PowerShell: .\deploy_sport_pages.bat
rem  4. GitHub Desktop -^> Changes tab should show: 5 new pages
rem     under es\sports\, plus es\sports\index.html, sitemap.xml
rem     and scripts\onexbet_odds.py as modified. Do NOT commit the
rem     .bak files.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%sport_pages_fix"

echo ============================================================
echo  goclarivo-site: deploy per-sport pages - ES pilot
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
    echo so there is a "sport_pages_fix" folder beside it.
    echo Nothing was copied.
    pause
    exit /b 1
)

set "ALL_OK=1"

if not exist "%ROOT%es\sports\index.html" (
    echo   [MISSING TARGET] %ROOT%es\sports\index.html
    set "ALL_OK=0"
)
if not exist "%SRC%\es\sports\index.html" (
    echo   [MISSING SOURCE] %SRC%\es\sports\index.html
    set "ALL_OK=0"
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

for %%S in (futbol baloncesto tenis hockey-sobre-hielo voleibol) do (
    if not exist "%SRC%\es\sports\%%S\index.html" (
        echo   [MISSING SOURCE] %SRC%\es\sports\%%S\index.html
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

echo All paths found. Backing up, then publishing...
echo.

copy /Y "%ROOT%es\sports\index.html" "%ROOT%es\sports\index.html.bak" >nul
copy /Y "%SRC%\es\sports\index.html" "%ROOT%es\sports\index.html" >nul
echo   [OK] es\sports\index.html updated -- backup at es\sports\index.html.bak

copy /Y "%ROOT%sitemap.xml" "%ROOT%sitemap.xml.bak" >nul
copy /Y "%SRC%\sitemap.xml" "%ROOT%sitemap.xml" >nul
echo   [OK] sitemap.xml updated -- backup at sitemap.xml.bak

copy /Y "%ROOT%scripts\onexbet_odds.py" "%ROOT%scripts\onexbet_odds.py.bak" >nul
copy /Y "%SRC%\scripts\onexbet_odds.py" "%ROOT%scripts\onexbet_odds.py" >nul
echo   [OK] scripts\onexbet_odds.py updated -- backup at scripts\onexbet_odds.py.bak

for %%S in (futbol baloncesto tenis hockey-sobre-hielo voleibol) do (
    if not exist "%ROOT%es\sports\%%S" mkdir "%ROOT%es\sports\%%S"
    copy /Y "%SRC%\es\sports\%%S\index.html" "%ROOT%es\sports\%%S\index.html" >nul
    echo   [OK] es\sports\%%S\index.html published - new page
)

echo.
echo ============================================================
echo  Done. GitHub Desktop -^> Changes tab should show: 5 new pages
echo  under es\sports\, plus es\sports\index.html, sitemap.xml and
echo  scripts\onexbet_odds.py as modified. The .bak files are
echo  untracked backups -- do NOT commit them.
echo ============================================================
echo.
pause
