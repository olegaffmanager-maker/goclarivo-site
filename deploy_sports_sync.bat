@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Sports pages now show every brand that is on the geo's own
REM  main page. 43 files changed, no folders deleted.
REM
REM  WHAT CHANGED
REM
REM  1, ar, bo, es, mx, pe, py, en, ke. Each geo's sports section
REM  used to show only one or two of its operators, sometimes
REM  zero, even though the main page already showed more. Every
REM  sports page and sport sub page now shows the exact same
REM  brands, in the same order, as that geo's own main page.
REM
REM  2, no new brands were invented. For a brand already shown
REM  on a sports page, that card was kept exactly as it was. For
REM  a brand that only existed on the main page, the card was
REM  built from that same brand's real data already in use there
REM  -- same logo, same licence line, same real referral link.
REM  Where that brand's main page bonus explicitly covers sports
REM  betting too, it was reused as is. Where it does not, or
REM  there is no confirmed bonus at all, the card says bonus in
REM  review, confirm current terms on the operator's site, the
REM  same honest wording already used elsewhere on these pages.
REM
REM  3, gh, bf, de, it, pt, in, zm were left untouched. Their
REM  sports section shows zero operators today and says so, which
REM  is still accurate, so nothing needed to change there.
REM
REM  4, the text above the cards on all 43 changed pages used to
REM  say the section was under construction, a placeholder, or
REM  that only one operator was shown while in review -- all of
REM  which stopped being true the moment a real, working card was
REM  already there. That wording is now a short, accurate line
REM  saying these are the sportsbooks recommended here, reviewed
REM  the same way as the casino comparison. The now-empty
REM  more operators in review box under the cards was removed on
REM  these same 43 pages, since every brand from the main page is
REM  already shown.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0sports_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find sports_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "ar" (
    echo ERROR: ar folder not found in the current folder.
    echo Run this script from the root of your goclarivo-site repo.
    pause
    exit /b 1
)

set "MISSING=0"
for /f "usebackq delims=" %%F in ("%LIST%") do (
    if not exist "%SRC%\%%F" (
        echo ERROR: Missing source file %SRC%\%%F
        set "MISSING=1"
    )
)
if "!MISSING!"=="1" (
    echo.
    echo One or more source files are missing. Nothing was changed. Aborting.
    pause
    exit /b 1
)

echo All 43 source files found. Starting deploy...
echo.

set "COUNT=0"
for /f "usebackq delims=" %%F in ("%LIST%") do (
    set "DESTDIR=%%~dpF"
    if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>&1
    if exist "%%F" copy /Y "%%F" "%%F.bak" >nul
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Deployed !COUNT! files.
echo.
echo ============================================================
echo Done. Sports pages for ar, bo, es, mx, pe, py, en and ke now
echo list every brand from that geo's main page, in the same
echo order, plus the matching text above the cards.
echo.
echo gh, bf, de, it, pt, in and zm were left as they were.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
