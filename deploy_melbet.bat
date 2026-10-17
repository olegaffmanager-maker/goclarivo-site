@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Add Melbet to the ranking on 6 country pages. 6 files.
REM
REM  New advertiser, onboarded via the advertiser form you sent
REM  (Google Sheet "форма рекламодателя") plus the referral links
REM  and bonus text you pasted in chat on 2026-10-17. Added to:
REM  Mexico, Peru, Bolivia, Burkina Faso, Kenya, India. NOT added
REM  to the EN/International page -- you said to skip that for now
REM  since there's no dedicated link/bonus for it.
REM
REM  Per geo:
REM    mx -- melbet-mx.com, bonus verbatim from the form (MXN)
REM    pe -- melbet-pe.com, bonus verbatim from the form (PEN)
REM    bo -- melbet-bolivia.com, bonus verbatim from the form (BOB)
REM    ke -- melbet-44169.pro, bonus verbatim from the form (KES)
REM    in -- melbet-77465.pro (currency=EUR, type=fast, bonus=SPORT
REM          params kept exactly as given), bonus verbatim from
REM          your chat message (EUR -- that's what the operator's
REM          own link/bonus pair for India actually is, not a typo)
REM    bf -- melbet-99601.pro/fr/. No bonus text exists for Burkina
REM          Faso in the form or chat (it only covers MX/PE/AR/KE/
REM          BO), so per your choice this card shows the same
REM          honest "bonus in review -- confirm on the operator's
REM          site" fallback already used elsewhere on the site when
REM          there's no verified geo-specific figure -- no XOF
REM          amount was invented.
REM
REM  The Burkina Faso referral link's tracking tag is one digit
REM  shorter than the other 5 (...ml_365729 vs ...ml_3657291
REM  everywhere else). You confirmed this is correct, not a typo --
REM  used exactly as given.
REM
REM  License line ("Curaçao Gaming Control Board — Licence No.
REM  OGL/2024/561/0554, operated by Pelican Entertainment B.V.")
REM  is stated as given on the advertiser's own form -- no registry
REM  link was supplied, so no "Ver registro" / verified-registry
REM  link is shown (same honest standard as every other card here:
REM  a claim only gets a registry-check link when one was actually
REM  checked).
REM
REM  Logo: the real Melbet logo file you sent, trimmed and embedded
REM  inline (not a hand-drawn approximation).
REM
REM  Commission/payout terms, payment methods, responsible-gambling
REM  tools etc. from the form are all real and on file, but weren't
REM  added to these pages -- the per-operator card only shows what
REM  the existing card format shows (bonus, verification status,
REM  license line, CTA). Say if you want any of that surfaced
REM  elsewhere (e.g. in the payment-methods guide).
REM
REM  The "N more operators in review" counter on each page was left
REM  unchanged -- same as every previous operator addition on this
REM  site, that count has never been adjusted when a new card goes
REM  live.
REM
REM  Does not touch anything else on these 6 pages, and doesn't
REM  touch any other geo.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0melbet_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find melbet_deploy folder next to this script.
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

echo All 6 source files found. Starting deploy...
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
echo Done. Melbet is now listed on mx, pe, bo, bf, ke and in.
echo Not added to EN -- say the word if you get a link/bonus for
echo the international page later.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
