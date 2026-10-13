@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: deploy new casino cards (AR/PE/IT/ES/DE/PT)
rem  --------------------------------------------------------------
rem  What this does: copies 6 already-prepared, already-reviewed
rem  index.html files from a "casino_cards_fix" folder (next to
rem  this script) into {geo}\index.html for exactly these 6 geos:
rem  ar, pe, it, es, de, pt.
rem
rem  IMPORTANT: {geo}\index.html IS the homepage -- the same file
rem  type that got accidentally overwritten before. This script is
rem  DELIBERATELY touching homepages this time (that is the point --
rem  adding new casino cards to them), but it protects you from a
rem  repeat of that incident in two ways:
rem    1) it backs up each current homepage to {geo}\index.html.bak
rem       BEFORE overwriting it, so the previous version is never
rem       lost even for a second;
rem    2) it only ever touches these 6 named geos -- ar, pe, it, es,
rem       de, pt -- never bo, en, mx, py, or any other folder.
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root (same folder
rem     as README, ar, bo, en, es, mx, pe, py, scripts, .github).
rem  2. Extract the delivered zip so a "casino_cards_fix" folder
rem     sits right next to this .bat file (same folder).
rem  3. Double-click this .bat file.
rem  4. It checks everything first and copies only if ALL checks
rem     pass. If anything looks wrong, it stops and tells you why.
rem  5. Afterwards: open GitHub Desktop, check the Changes tab
rem     (should show exactly 6 changed files: ar\index.html,
rem     pe\index.html, it\index.html, es\index.html, de\index.html,
rem     pt\index.html -- nothing else), write a commit message,
rem     commit, push.
rem  6. Once you've confirmed the live site looks right, you can
rem     safely delete the 6 *.bak files this script created.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%casino_cards_fix"
set "GEOS=ar pe it es de pt"

echo ============================================================
echo  goclarivo-site: deploy new casino cards
echo ============================================================
echo.
echo Repo root (where this script lives): %ROOT%
echo Source folder:                       %SRC%
echo.

if not exist "%SRC%" (
    echo ERROR: Could not find the folder:
    echo   %SRC%
    echo.
    echo Extract the delivered zip HERE, right next to this .bat file,
    echo so there is a "casino_cards_fix" folder beside it.
    echo Nothing was copied.
    pause
    exit /b 1
)

echo Step 1/2: checking every source and target path BEFORE copying anything...
echo.

set "ALL_OK=1"

for %%G in (%GEOS%) do (
    set "TARGET_FILE=%ROOT%%%G\index.html"
    set "SRC_FILE=%SRC%\%%G\index.html"

    if not exist "!TARGET_FILE!" (
        echo   [MISSING TARGET] !TARGET_FILE!
        echo     -- this script may not be in the real repo root. Check the path above.
        set "ALL_OK=0"
    )
    if not exist "!SRC_FILE!" (
        echo   [MISSING SOURCE] !SRC_FILE!
        echo     -- did the zip extract correctly, with 6 geo subfolders inside casino_cards_fix?
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

echo   All 6 source files found, all 6 target homepages found. Looks correct.
echo.
echo Step 2/2: backing up current homepages, then copying new ones...
echo.

for %%G in (%GEOS%) do (
    copy /Y "%ROOT%%%G\index.html" "%ROOT%%%G\index.html.bak" >nul
    copy /Y "%SRC%\%%G\index.html" "%ROOT%%%G\index.html" >nul
    if errorlevel 1 (
        echo   [FAILED] %%G\index.html
    ) else (
        echo   [OK]     %%G\index.html updated -- previous version saved as %%G\index.html.bak
    )
)

echo.
echo ============================================================
echo  Done. Only ar, pe, it, es, de, pt homepages were touched --
echo  no other geo, no /sports/ page, nothing else.
echo.
echo  Next: open GitHub Desktop -^> Changes tab. You should see
echo  EXACTLY 6 changed files -- the 6 index.html files above. The .bak
echo  files are untracked backups -- GitHub Desktop will either
echo  ignore them or show them as new files; do NOT commit the
echo  .bak files, only the 6 index.html changes.
echo  If you see anything else changed, STOP and ask before committing.
echo ============================================================
echo.
pause
