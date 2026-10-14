@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Pin-Up — Sports SUBPAGES deploy (MX + BO)
REM
REM  What this does:
REM    Adds the same PIN-UP sportsbook card (already placed on the
REM    top-level mx/sports/ and bo/sports/ pages) to the 5 per-sport
REM    subpages under each: baloncesto, futbol, hockey-sobre-hielo,
REM    tenis, voleibol. 10 files total. KE has no per-sport subpages,
REM    so it is not part of this package.
REM
REM    Same bonus figures, license line and CTA as before -- nothing
REM    new was fabricated, this just places the already-confirmed
REM    card on the pages it was still missing from.
REM
REM  This script backs up each file it touches (.bak) before
REM  overwriting, and aborts safely if any file is missing.
REM ============================================================

set "SRC=%~dp0pinup_sports_subpages_deploy"

if not exist "%SRC%" (
    echo ERROR: Could not find pinup_sports_subpages_deploy folder next to this script.
    echo Make sure deploy_pinup_sports_subpages.bat and that folder were
    echo extracted into the same place.
    pause
    exit /b 1
)

set SPORTS=baloncesto futbol hockey-sobre-hielo tenis voleibol
set GEOS=mx bo

for %%g in (%GEOS%) do (
    for %%s in (%SPORTS%) do (
        if not exist "%SRC%\%%g\sports\%%s\index.html" (
            echo ERROR: Missing %SRC%\%%g\sports\%%s\index.html
            pause
            exit /b 1
        )
    )
)

for %%g in (%GEOS%) do (
    for %%s in (%SPORTS%) do (
        if not exist "%%g\sports\%%s\index.html" (
            echo ERROR: %%g\sports\%%s\index.html not found in the current folder.
            echo Run this script from the root of your goclarivo-site repo.
            pause
            exit /b 1
        )
    )
)

echo Backing up current files...
for %%g in (%GEOS%) do (
    for %%s in (%SPORTS%) do (
        copy /Y "%%g\sports\%%s\index.html" "%%g\sports\%%s\index.html.bak" >nul
    )
)

echo Deploying updated files...
for %%g in (%GEOS%) do (
    for %%s in (%SPORTS%) do (
        copy /Y "%SRC%\%%g\sports\%%s\index.html" "%%g\sports\%%s\index.html" >nul
        if errorlevel 1 (
            echo ERROR: Failed to copy %%g\sports\%%s\index.html
            pause
            exit /b 1
        )
    )
)

echo.
echo Done. Updated 10 files: mx and bo, each of baloncesto / futbol /
echo hockey-sobre-hielo / tenis / voleibol under sports\.
echo.
echo Backups saved as .bak next to each file in case you need to revert.
echo.
echo Next steps: review the changes in GitHub Desktop, then commit and push.
pause
