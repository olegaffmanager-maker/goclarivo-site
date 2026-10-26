@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Audit fixes from 26.10, all in one package.
REM
REM  WHAT THIS DOES, IN ORDER
REM
REM  1. Fixed the broken PIN-UP link on the Mexico homepage by
REM     adding a real review page at mx/resenas/pin-up/.
REM  2. Fixed the Chile footer phone number, it showed Bolivia's
REM     Familia Segura line, now shows Chile's Salud Responde line.
REM  3. Built real comparison pages at /compare/ for the four
REM     countries that already have two or more reviews, Mexico,
REM     Argentina, Peru and Bolivia. Every other country still
REM     shows the same not yet published page as before.
REM  4. Shortened 178 page titles that were longer than 65
REM     characters, moved the keyword to the front of each.
REM  5. Made 46 groups of duplicate meta descriptions unique by
REM     naming the country, and added the country name to the
REM     11 bonus calculator page titles.
REM  6. Updated sitemap.xml so every changed page has today's
REM     date, including the new PIN-UP page.
REM  7. Repo cleanup. Removes every leftover deploy and fix
REM     staging folder at the repo root, the stray sports_pages
REM     folder, every .bak backup copy inside the site folders,
REM     and every old .bat script other than this one. Adds a
REM     .gitignore file so this kind of file is not picked up as
REM     a change to commit again in the future.
REM
REM  314 files are added or changed by step one, nothing else in
REM  those pages was touched. Checked against a fresh copy of the
REM  live site first.
REM
REM  Backups: a .bak is made for every existing file this script
REM  changes, before it is overwritten. Those backups are then
REM  removed in the cleanup step below, along with every other
REM  .bak file already sitting in the repo. Review the changes in
REM  GitHub Desktop before committing, that is the real safety
REM  net here.
REM ============================================================

set "SRC=%~dp0final_audit_deploy"
set "LIST=%~dp0files_list.txt"
set "SELF=%~nx0"

if not exist "%SRC%" (
    echo ERROR: Could not find final_audit_deploy folder next to this script.
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

echo Checking that all 314 source files are present...
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

echo All source files found.
echo.
echo ============================================================
echo Step 1 of 2: copying the 314 added or changed pages.
echo ============================================================
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
echo Step 2 of 2: repo cleanup.
echo ============================================================
echo Deleting leftover deploy and fix staging folders...
set "DELDIR=0"
for /d %%D in (*_deploy *_fix) do (
    if exist "%%D" (
        rd /s /q "%%D"
        set /a DELDIR+=1
    )
)
if exist "sports_pages" (
    rd /s /q "sports_pages"
    set /a DELDIR+=1
)

echo Deleting .bak backup files, including the ones just made above...
set "DELBAK=0"
for /r %%F in (*.bak) do (
    if exist "%%F" (
        del /q "%%F"
        set /a DELBAK+=1
    )
)

echo Deleting old .bat scripts...
set "DELBAT=0"
for %%F in (*.bat) do (
    if /I not "%%~nxF"=="!SELF!" (
        del /q "%%F"
        set /a DELBAT+=1
    )
)

echo Deleting leftover list text files...
set "DELLIST=0"
for %%F in (files_list.txt dirs_list.txt bat_list.txt bak_list.txt) do (
    if exist "%%F" (
        del /q "%%F"
        set /a DELLIST+=1
    )
)

echo.
echo ============================================================
echo Done.
echo   Updated or added 314 pages, including sitemap.xml
echo   Removed !DELDIR! staging folders
echo   Removed !DELBAK! .bak files
echo   Removed !DELBAT! old .bat scripts
echo   Removed !DELLIST! list text files
echo.
echo Next steps: open GitHub Desktop and check the change list.
echo You should see roughly 310 modified pages, one new page at
echo mx/resenas/pin-up, a new .gitignore file, and a large number
echo of removed files from the cleanup. Review it, then commit
echo and push in one commit. This script itself will not show up
echo as a change thanks to the new .gitignore, it is safe to
echo leave it in the folder or delete it by hand afterward.
echo ============================================================
pause
