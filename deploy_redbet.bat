@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Add 1RedBet to the ranking on 2 country pages. 2 files.
REM
REM  New advertiser, from the form you sent - Google Sheet, file
REM  Forma dlya reklamodatelya.xlsx - plus the logo and referral
REM  link you pasted in chat on 2026-10-18. Added to Argentina
REM  and Mexico.
REM
REM  NOT added to Peru. You asked for AR/MX/PE, but the operator's
REM  own form lists its licensed geos as CL, MX, AR -- Peru isn't
REM  on that list, and there are no Peru-specific payment methods
REM  or deposit limits anywhere in the form either, only Argentina,
REM  Chile and Mexico ones. You confirmed this was a mix-up and the
REM  third geo should be Chile, not Peru -- but this site doesn't
REM  have a Chile page yet. There is an old, never-finished folder
REM  called cl_page_fix in the project history from a previous
REM  session, but no live /cl/ geo. So this round only covers the
REM  two geos that are both confirmed-licensed AND already live on
REM  the site: AR and MX. Building a new Chile geo from scratch is
REM  a separate, larger task -- say the word if you want that next.
REM
REM  License: Anjouan Gaming Authority, licence No. ALSI-132405050-FI3,
REM  entity ZOSMA LLC. Unlike most cards on this site, this one was
REM  actually independently checked against the regulator's public
REM  register -- both the operator's own verification URL and the
REM  registry screenshot you sent show the same record: ZOSMA LLC,
REM  status Valid, same licence number, issued 2024-05-28, expires
REM  2027-05-27, domain 1redbet.com. So the card includes a real
REM  Ver registro link straight to that verification page, the same
REM  way the existing PIN-UP card on this site does.
REM
REM  Bonus text is verbatim from the form - 150 percent plus 50 free
REM  spins on first deposit. The form gives one bonus text, not
REM  split by country and with no currency cap stated, so it is
REM  shown exactly as given on both pages, not converted into
REM  ARS or MXN.
REM
REM  Referral link is the single tracking link you gave in chat,
REM  the redbt.vordyne.com one, same on both pages -- the form's
REM  own referral link field pointed at the affiliate-network
REM  signup page instead of a player link, so the chat link is the
REM  one actually used.
REM
REM  Logo: the real 1RedBet logo file you sent, trimmed and embedded
REM  inline.
REM
REM  Commission, 45 percent RevShare, payout terms, payment rails,
REM  RG tools etc. from the form are on file but not shown on the
REM  card itself -- same as with Melbet, the card only carries what
REM  the existing card format shows.
REM
REM  The N more operators in review counters were left untouched,
REM  same as every previous operator addition.
REM
REM  Does not touch anything else on these 2 pages, and doesn't
REM  touch any other geo.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0redbet_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find redbet_deploy folder next to this script.
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

echo All 2 source files found. Starting deploy...
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
echo Done. 1RedBet is now listed on ar and mx.
echo Not added to Peru or Chile -- Peru isn't licensed per the
echo operator's own form, and Chile has no page on this site yet.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
