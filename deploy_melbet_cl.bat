@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Melbet added as Chile's first verified operator. Small and
REM  not destructive, only 2 files change, no folder is deleted.
REM
REM  WHAT CHANGED
REM
REM  1, cl/index.html -- the empty state message in the top list
REM  section is replaced with a real Melbet casino card, built
REM  using the real data you sent from the advertiser, account
REM  manager, KYC steps, support channels, slot and live casino
REM  provider lists, payout speed by method, and the Chile
REM  tagged referral link with currency set to CLP. No Chile
REM  specific bonus amount was given, so the bonus line still
REM  uses the honest in review wording instead of a made up
REM  number, swap that in later once you send the real figure.
REM  The verified casinos counter on that page moves from 00 to
REM  01 as well.
REM
REM  2, assets/data/casinos.json -- Melbet's entry gets cl added
REM  to its countries list, plus matching cl entries in its bonus
REM  and link maps, so the homepage quiz also correctly surfaces
REM  Melbet for Chile visitors instead of the no operator yet
REM  fallback.
REM
REM  NOT INCLUDED ON PURPOSE
REM
REM  This deploy does not touch cl/sports and its six subpages,
REM  since those were part of the merge conflict you said you
REM  already resolved on your own machine, and this clone has no
REM  visibility into what that resolution left in place. Let me
REM  know if you want the same Melbet card added there too, or
REM  whether that is already done.
REM
REM  Backups: a .bak is created for every changed file before it
REM  is overwritten.
REM ============================================================

set "SRC=%~dp0melbet_cl_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find melbet_cl_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "cl" (
    echo ERROR: cl folder not found in the current folder.
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
echo Done. Melbet is now live on the Chile page as the first
echo verified operator, and the homepage quiz will surface it
echo for Chile visitors too.
echo.
echo Next steps: review the changes in GitHub Desktop, then
echo commit and push.
echo ============================================================
pause
