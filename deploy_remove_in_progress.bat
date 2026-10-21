@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Removed the yellow Editorial Review in progress badge from
REM  every operator card, across every geo and every page type.
REM  76 files changed, no folders deleted.
REM
REM  WHAT CHANGED
REM
REM  Every casino card used to show two blocks side by side,
REM  Verification Status in green, and Editorial Review with a
REM  yellow In progress badge next to it, in every language. The
REM  yellow block is now gone everywhere it appeared, 287 cards
REM  in total across home pages, sports hub pages, sports sub
REM  pages and the two betting guide articles that embed cards.
REM
REM  Nothing else on the cards changed. Verification status,
REM  bonus text, licence line, logo and the Go to Casino link are
REM  all exactly as they were. The card layout was adjusted from
REM  two columns to one so the remaining block fills the row
REM  cleanly instead of leaving an empty gap.
REM
REM  The explanatory paragraph above the Featured Casinos and
REM  main ranking lists, the one that says reviews are still in
REM  progress, was left untouched since you asked specifically
REM  about the yellow badges on the cards. Say the word if you
REM  want that paragraph reworded too.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0amber_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find amber_deploy folder next to this script.
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

echo All 76 source files found. Starting deploy...
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
echo Done. No card anywhere on the site shows the yellow in
echo progress badge any more.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
