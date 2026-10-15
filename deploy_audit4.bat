@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Audit round 4 -- hreflang on /guides/ articles, 155 files.
REM
REM  This is the piece I deliberately held back last time: the
REM  guide topics don't line up 1-to-1 across every geo, so each
REM  pair had to be checked by hand before linking them, instead
REM  of blindly copying the homepage's full 15-geo hreflang block
REM  onto every guide.
REM
REM  What I found, by actually listing every guide on every geo:
REM
REM  - 4 guides are genuinely unique to one country and have no
REM    equivalent anywhere else on the site: AR's provincial-
REM    licensing guide, BO's "AJ Ley 060" guide, PE's "Ley 31557
REM    MINCETUR" guide, and PY's CONAJZAR/.bet.py domain guide.
REM    These got NO hreflang -- tagging them as equivalent to
REM    something else would be wrong, there's nothing to point at.
REM  - 1 topic (the general "wagering requirements explained"
REM    guide) exists on all 15 geos and really is the same single
REM    topic everywhere -- including DE's "umsatzbedingungen-
REM    erklaert", which I'd first worried might be a merge of 3
REM    separate EN guides. It isn't: DE/IT/FR/BF/PT only have the
REM    one general explainer; EN/ES-family ALSO have two further,
REM    separate deep-dive guides (what counts toward wagering, and
REM    what happens if you don't finish it) that simply don't
REM    exist on DE/IT/FR/BF/PT, so those two stayed in their own,
REM    smaller 10-geo group instead of being lumped in with the
REM    general one.
REM  - "Payment methods" is one more case worth flagging: AR, BO,
REM    MX, PE and PY each have a country-specific payment-methods
REM    guide (local bank transfers, local e-wallets) instead of
REM    the generic one that ES/EN/DE/IT/etc. use. I treated these
REM    as the right hreflang match for their country anyway --
REM    that's what hreflang is for (the local-market equivalent of
REM    the same topic, not a byte-for-byte translation).
REM  - Same logic for MX's "how to recognize a trustworthy casino"
REM    guide, which is localized to Mexico specifically -- it's
REM    still the same topic as the generic version on ES/EN/DE/IT/
REM    etc., just with Mexico-specific detail. AR, BO, PE and PY
REM    don't have this topic at all, so they're excluded from this
REM    particular group (they're not missing anything -- it was
REM    never built for them to begin with).
REM
REM  14 topic groups in total, ranging from 7 geos (the 2 football-
REM  betting guides that only exist on EN + the 6 Spanish geos) up
REM  to all 15 (deposit limits, wagering explained, RTP, payment
REM  methods). Every href was checked against the real file on
REM  disk before this package was built -- none point at a page
REM  that doesn't exist.
REM
REM  Does NOT touch any operator/casino-card content, and does NOT
REM  touch the licensing content on de, it, es, pt, mx, bo, pe, py,
REM  ke that's still on hold.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0audit4_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find audit4_deploy folder next to this script.
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

echo All 155 source files found. Starting deploy...
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
echo Done. hreflang is now complete on every page type on the
echo site except the 4 country-unique regulatory guides (which
echo correctly have none).
echo.
echo Still open from the audit: author page for Oleg Melnikov
echo (waiting on real bio text), contact email/Telegram, the
echo Sports mirror-domain widget, remaining language/copy fixes.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
