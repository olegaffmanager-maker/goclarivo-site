@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  Safe deploy helper for goclarivo-site /sports/ page updates
rem  --------------------------------------------------------------
rem  What it does: copies each geo's index.html from a "sports_fix"
rem  folder (next to this script) into {geo}\sports\index.html.
rem
rem  What it refuses to do: it NEVER writes to {geo}\index.html
rem  (the homepage) -- that path is not even mentioned below, so
rem  there is no way for a typo or wrong drag-and-drop to repeat
rem  the mistake that broke the homepages before.
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root (same folder
rem     as README, ar, bo, en, es, mx, pe, py, scripts, .github).
rem  2. Extract the delivered zip so a "sports_fix" folder sits
rem     right next to this .bat file (same folder).
rem  3. Double-click this .bat file.
rem  4. It checks everything first and copies only if ALL checks
rem     pass. If anything looks wrong, it stops and tells you why
rem     -- it never partially copies.
rem  5. Afterwards: open GitHub Desktop, check the Changes tab
rem     (should show exactly 7 files, all ending in \sports\index.html),
rem     write a commit message, commit, push.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%sports_fix"
set "GEOS=ar bo en es mx pe py"

echo ============================================================
echo  goclarivo-site: deploy /sports/ page update
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
    echo so there is a "sports_fix" folder beside it.
    echo Nothing was copied.
    pause
    exit /b 1
)

echo Step 1/2: checking every source and target path BEFORE copying anything...
echo.

set "ALL_OK=1"

for %%G in (%GEOS%) do (
    set "TARGET_DIR=%ROOT%%%G\sports"
    set "SRC_FILE=%SRC%\%%G\index.html"

    if not exist "!TARGET_DIR!" (
        echo   [MISSING TARGET] !TARGET_DIR!
        echo     -- this script may not be in the real repo root. Check the path above.
        set "ALL_OK=0"
    )
    if not exist "!SRC_FILE!" (
        echo   [MISSING SOURCE] !SRC_FILE!
        echo     -- did the zip extract correctly, with 7 geo subfolders inside sports_fix?
        set "ALL_OK=0"
    )
)

if "!ALL_OK!"=="0" (
    echo.
    echo Stopped -- fix the problem(s) above and run this script again.
    echo Nothing was copied.
    pause
    exit /b 1
)

echo   All 7 source files found, all 7 target folders found. Looks correct.
echo.
echo Step 2/2: copying...
echo.

for %%G in (%GEOS%) do (
    copy /Y "%SRC%\%%G\index.html" "%ROOT%%%G\sports\index.html" >nul
    if errorlevel 1 (
        echo   [FAILED] %%G\sports\index.html
    ) else (
        echo   [OK]     %%G\sports\index.html  updated
    )
)

echo.
echo ============================================================
echo  Done. Homepages ({geo}\index.html) were never touched --
echo  only the 7 files above, inside each geo's \sports\ folder.
echo.
echo  Next: open GitHub Desktop -^> Changes tab. You should see
echo  EXACTLY 7 changed files, all ending in \sports\index.html.
echo  If you see anything else, STOP and ask before committing.
echo ============================================================
echo.
pause
