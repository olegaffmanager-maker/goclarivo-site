@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Paraguay removed, Chile added as a new geo. This is the
REM  biggest deploy in this project so far, 412 files changed,
REM  and it is also the first deploy that deletes a folder.
REM
REM  WHAT CHANGED
REM
REM  1, every page on the site had Paraguay in its geo switcher,
REM  its footer list and its flag icon set, since that list is
REM  repeated on every single page rather than pulled from one
REM  shared file. All of that -- the flag icon, the href, the
REM  hreflang tag, the label text -- now says Chile instead,
REM  across all 409 existing pages plus the homepage.
REM
REM  2, a new Chile section was built from the Bolivia pages as
REM  a starting template, 31 pages in total, at the cl folder.
REM  As you asked, it launches with zero casino cards, zero in
REM  the verified and in review counters, and an honest message
REM  saying no operators are verified yet instead of a card.
REM  The two Bolivia specific guides about its AJ regulator and
REM  its payment methods were not copied over, since that content
REM  is specific to Bolivia and would not be true for Chile.
REM
REM  3, every place that described Chile's gambling regulator --
REM  the FAQ, the methodology page, the responsible gambling page,
REM  a glossary line shown on every Chile page -- was rewritten
REM  using real research instead of copying Bolivia's AJ and Ley
REM  060, since those do not apply in Chile. As of today Chile has
REM  no dedicated regulator or license for online gambling, only
REM  a law covering physical casinos, and a bill covering online
REM  gambling still pending in the Senate.
REM
REM  4, sitemap.xml had its 33 Paraguay entries replaced with 31
REM  Chile entries, all dated today. assets/data/casinos.json had
REM  its leftover Paraguay references removed from the 1xBet entry.
REM
REM  5, the py folder itself is deleted by this script, 33 pages
REM  plus their backups, since you asked for Paraguay to be fully
REM  removed rather than just unlinked. This cannot be undone by
REM  this script. Your GitHub history still has it if you ever
REM  need it back.
REM
REM  Backups: a .bak is created for every changed file before it
REM  is overwritten. The py folder itself has no backup once
REM  deleted here, beyond GitHub history after you push.
REM ============================================================

set "SRC=%~dp0py_to_cl_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find py_to_cl_deploy folder next to this script.
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

echo All 412 source files found. Starting with the copy and backup step.
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
echo  NEXT STEP IS PERMANENT: deleting the py folder
echo ============================================================
echo The py folder, Paraguay, 33 pages plus their .bak backups,
echo is about to be deleted from this computer. This cannot be
echo undone by this script. Close this window now, or press
echo Ctrl+C, if you want to stop here and keep the py folder.
echo.
pause

if exist "py" (
    rmdir /s /q "py"
    echo py folder deleted.
) else (
    echo py folder was already gone, nothing to delete.
)

echo.
echo ============================================================
echo Done. Chile is live at /cl/ with no operator cards yet, and
echo Paraguay is gone from the site and from this folder.
echo.
echo Next steps: review the changes in GitHub Desktop -- this is a
echo big one, 412 changed files plus one deleted folder, so take a
echo moment to skim it -- then commit and push.
echo ============================================================
pause
