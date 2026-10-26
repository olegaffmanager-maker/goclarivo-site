@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Fixes why the 1xBet odds widget stopped refreshing after
REM  Paraguay was removed. One file changes, scripts
REM  onexbet_odds.py, nothing else.
REM
REM  WHAT WAS WRONG
REM
REM  The script still had py listed as a geo to update, with
REM  file paths pointing at py sports and py guides pages.
REM  Once the py folder was removed from the site, every single
REM  scheduled run hit a file not found error for py, which made
REM  the script exit with a failure code at the very end. The
REM  workflow step that commits and pushes the refreshed widget
REM  only runs when the previous step succeeds, so every run
REM  since then quietly refreshed the widget in a temporary
REM  copy and then threw it away, nothing ever reached the live
REM  site.
REM
REM  WHAT CHANGED
REM
REM  Every mention of py removed from the script, the geo list
REM  and all the per sport file path tables. es, mx, ar, pe, bo
REM  and en are untouched and unaffected.
REM
REM  After this is pushed, either wait for the next scheduled
REM  run, every 30 minutes, or open the Actions tab on GitHub,
REM  pick Rebuild 1xBet odds widget, and press Run workflow to
REM  trigger it immediately.
REM
REM  Backups: a .bak is created for the changed file before it
REM  is overwritten.
REM ============================================================

set "SRC=%~dp0odds_fix_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find odds_fix_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "scripts" (
    echo ERROR: scripts folder not found in the current folder.
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

echo All source files found. Starting the copy and backup step.
echo.

set "COUNT=0"
for /f "usebackq delims=" %%F in ("%LIST%") do (
    if exist "%%F" copy /Y "%%F" "%%F.bak" >nul
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Copied and backed up !COUNT! file.
echo.
echo ============================================================
echo Done. scripts\onexbet_odds.py no longer references py.
echo.
echo Next steps: review the change in GitHub Desktop, commit and
echo push, then trigger the workflow manually from the Actions
echo tab if you do not want to wait for the next 30 minute run.
echo ============================================================
pause
