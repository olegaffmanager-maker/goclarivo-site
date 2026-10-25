@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Safecasino card removed entirely, from every page it was on.
REM  10 files change, no folders deleted.
REM
REM  WHAT CHANGED
REM
REM  es/index.html, es/sports/index.html and the five es/sports
REM  subpages, futbol, baloncesto, hockey-sobre-hielo, tenis,
REM  voleibol -- the Safecasino card removed, nothing else on
REM  these pages touched.
REM
REM  it/index.html and it/sports/index.html -- same removal.
REM
REM  assets/data/casinos.json -- the safecasino entry removed, so
REM  it also drops out of the homepage quiz results.
REM
REM  Backups: a .bak is created for every changed file before it
REM  is overwritten.
REM ============================================================

set "SRC=%~dp0remove_safecasino_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find remove_safecasino_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "es" (
    echo ERROR: es folder not found in the current folder.
    echo Run this script from the root of your goclarivo-site repo.
    pause
    exit /b 1
)
if not exist "assets" (
    echo ERROR: assets folder not found in the current folder.
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
    set "DESTDIR=%%~dpF"
    if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>&1
    if exist "%%F" copy /Y "%%F" "%%F.bak" >nul
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Copied and backed up !COUNT! files.
echo.
echo ============================================================
echo Done. Safecasino is gone from es and it, home page, sports
echo page, and all five es sports subpages, and out of the quiz.
echo.
echo Next steps: review the changes in GitHub Desktop, then
echo commit and push.
echo ============================================================
pause
