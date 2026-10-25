@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  This closes the gap from the last verification removal pass.
REM  That pass only touched the home pages. It missed the sport
REM  category pages, football, basketball, tennis, volleyball,
REM  ice hockey, that also list casino cards, the two betting
REM  guide pages that list casino cards, and seven smaller geo
REM  home pages that were not in the original batch. 54 files
REM  change, nothing is deleted.
REM
REM  WHAT CHANGED
REM
REM  Every casino card on these 54 pages loses its verification
REM  badge block and its license text line, same as before, the
REM  green check mark, the amber in review tag, the gray not
REM  published tag, all of it, for every operator, no exceptions.
REM
REM  On eight home pages, bf, de, en, gh, in, ke, pt, zm, the two
REM  header counters, verified casinos and in review, are also
REM  removed, same as was already done earlier on the other home
REM  pages. The stat row is narrowed to two columns on these eight
REM  so the layout stays even.
REM
REM  Backups: a .bak is created for every changed file before it
REM  is overwritten.
REM ============================================================

set "SRC=%~dp0verify_fix_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find verify_fix_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "mx" (
    echo ERROR: mx folder not found in the current folder.
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
echo Done. No casino card on any sport page, betting guide page,
echo or the eight remaining home pages shows a verification badge
echo or a license line anymore, and the stale counters are gone
echo from those eight home pages too.
echo.
echo Next steps: review the changes in GitHub Desktop, then
echo commit and push.
echo ============================================================
pause
