@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Removed the explanatory paragraph under Featured Casinos on
REM  the main ranking list, on all 15 geo home pages. 15 files
REM  changed, no folders deleted.
REM
REM  WHAT CHANGED
REM
REM  Each home page had a short paragraph right under the Featured
REM  Casinos heading, saying the listed operators are shown while
REM  their editorial review is still in progress. That paragraph
REM  is now gone everywhere, the heading stays. Nothing else in
REM  that section changed, the casino cards below are untouched.
REM
REM  This was left in place on purpose during the earlier pass
REM  that removed the yellow In progress badges from the cards
REM  themselves, since that was a separate request. This deploy
REM  finishes the job on the one remaining leftover text.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0remove_paragraph_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find remove_paragraph_deploy folder next to this script.
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

echo All 15 source files found. Starting deploy...
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
echo Done. The Featured Casinos heading now has no explanatory
echo paragraph under it on any of the 15 home pages.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
