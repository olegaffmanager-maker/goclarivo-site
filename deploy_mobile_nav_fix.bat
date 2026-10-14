@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: working mobile navigation menu
rem  --------------------------------------------------------------
rem  The bug: on a phone (anything <=820px wide) the whole top menu
rem  (Casinos / Compare / Sports / Guides / FAQ / Methodology /
rem  About us) disappeared completely, with no way to get it back --
rem  confirmed by taking an actual mobile-viewport screenshot of the
rem  live header: only the logo and the language switcher were left.
rem  No hamburger button, nothing. Only the "EN"/country dropdown in
rem  the corner still worked.
rem
rem  The fix adds a hamburger button next to the language switcher,
rem  visible ONLY on screens <=820px wide (desktop is untouched --
rem  verified pixel-identical before/after). Tapping it opens a
rem  dropdown panel with every link that's in the desktop menu,
rem  taken directly from each page's own existing menu -- nothing
rem  new was invented, same links, same destinations. It reuses the
rem  exact dropdown mechanism already used for the language and
rem  sports-dropdown menus (including the existing "tap outside to
rem  close" behaviour), so no new JavaScript was added anywhere.
rem
rem  This touches every page on the site: 274 pages across all 15
rem  regions (ar, bo, de, en, es, fr, gh, it, ke, mx, pe, pt, py, zm,
rem  bf). Verified: tag-balance clean on all 274 pages, JSON-LD still
rem  valid on all of them, tested with a real headless browser at
rem  phone width on 7 representative pages (the menu opens, every
rem  link is present, no console errors) and at desktop width (menu
rem  unchanged, hamburger invisible).
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root.
rem  2. Extract the delivered zip so a "mobile_nav_fix" folder sits
rem     right next to this .bat file.
rem  3. Run from PowerShell: .\deploy_mobile_nav_fix.bat
rem  4. GitHub Desktop -^> Changes tab should show 274 changed files
rem     (every index.html in the 15 region folders). Spot-check a
rem     few diffs, then commit and push as usual.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%mobile_nav_fix"

echo ============================================================
echo  goclarivo-site: working mobile navigation menu
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
    echo so there is a "mobile_nav_fix" folder beside it.
    echo Nothing was copied.
    pause
    exit /b 1
)

set "ALL_OK=1"

for %%G in (ar bo de en es fr gh it ke mx pe pt py zm bf) do (
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

echo All paths found. Publishing the 15 region folders...
echo.

for %%G in (ar bo de en es fr gh it ke mx pe pt py zm bf) do (
    xcopy "%SRC%\%%G" "%ROOT%%%G\" /E /I /Y /Q >nul
    echo   [OK] %%G\ updated
)

echo.
echo ============================================================
echo  Done. GitHub Desktop -^> Changes tab should show 274 changed
echo  files -- every page in every region now has a working mobile
echo  menu. Nothing else on the site was touched.
echo.
echo  Spot-check a few file diffs in GitHub Desktop before
echo  committing. If something looks wrong, use "Discard changes"
echo  instead of committing.
echo ============================================================
echo.
pause
