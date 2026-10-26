@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  1xBet referral link and real logo, site wide.
REM
REM  WHAT CHANGED
REM
REM  Referral link -- every 1xBet card and the 4 review pages
REM  pointed at the old reffpa.com link ending in site=6171730.
REM  All 71 of those now point at the new one ending in
REM  site=6266915 and r=registration, exactly as given.
REM
REM  Logo -- the drawn placeholder badge that just spelled out
REM  1xBet in text has been replaced by the real logo image you
REM  sent, in 67 ranking and comparison cards across every geo.
REM  The 4 review pages, ar, bo, mx and pe, had no logo at all
REM  before, just a plain text heading, a small logo image has
REM  been added above the heading on all 4.
REM
REM  New file: assets/img/1xbet-logo.webp, the logo you sent,
REM  resized and saved as webp like the other operator logos
REM  already on the site.
REM
REM  72 files total, 71 existing pages updated plus the 1 new
REM  logo file. Nothing else on any of these pages was touched.
REM  Checked against a fresh copy of the live site first --
REM  every one of the 71 old occurrences was byte for byte
REM  identical, so this is a clean, exact replacement everywhere.
REM
REM  Backups: a .bak is created for every changed file before it
REM  is overwritten. No backup for the new logo file since there
REM  is nothing to back up.
REM ============================================================

set "SRC=%~dp0logo_ref_fix_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find logo_ref_fix_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "bo" (
    echo ERROR: bo folder not found in the current folder.
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
    if not exist "%%~dpF" mkdir "%%~dpF"
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Copied and backed up !COUNT! files.
echo.
echo ============================================================
echo Done. 72 files updated: the new 1xBet logo file, the ref
echo link fixed in 71 pages, and the logo swapped in on 67 of
echo those same pages plus added fresh on the 4 review pages.
echo.
echo Next steps: review the changes in GitHub Desktop, then
echo commit and push.
echo ============================================================
pause
