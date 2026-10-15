@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Audit round 3 -- technical SEO, 67 files.
REM
REM  This does NOT touch any operator/casino-card content, and
REM  does NOT touch de, it, es, pt, mx, bo, pe, py, ke licensing
REM  content -- still on hold as before. This round is purely
REM  sitemap.xml, the root language-picker page, and missing
REM  hreflang tags -- nothing a visitor reads is changed except
REM  two small pieces of actual UX: the root page now redirects
REM  French/Portuguese/Ghana/Kenya/Zambia browsers too.
REM
REM  What this package does:
REM
REM  1) sitemap.xml: was missing 130 real, existing pages (every
REM     geo's bonus calculator, Industry/Branche/Industria section
REM     and its one article, plus a handful of guides) -- all 130
REM     added. Also added <lastmod>2026-10-15</lastmod> to every
REM     one of the 405 URLs now in the file (this date marks when
REM     the sitemap itself was regenerated/verified, same as every
REM     static-site sitemap generator does -- it is not a claim
REM     that each page's content changed today). Nothing was
REM     removed -- the old 275 URLs were all still valid, just
REM     incomplete.
REM
REM  2) index.html (root "choose your region" page): the browser-
REM     language auto-redirect only recognized de/it/en plus the
REM     6 Spanish geos -- French, Portuguese, Ghanaian-English,
REM     Kenyan-English and Zambian-English visitors always fell
REM     through to the manual picker. Added fr-FR->/fr/, fr-BF->
REM     /bf/, pt-PT->/pt/, en-GH->/gh/, en-KE->/ke/, en-ZM->/zm/,
REM     plus unambiguous bare "fr" and "pt" fallbacks (bare "es"
REM     was deliberately left alone before, for the same good
REM     reason: too many Spanish geos to guess between -- that
REM     logic is untouched). Also added the hreflang tags for
REM     fr-FR, fr-BF, pt-PT, en-GH, en-KE, en-ZM on this page --
REM     they were already on all 15 geo homepages, just missing
REM     here. x-default still points at this page itself, which is
REM     the technically correct target for a language-picker page
REM     -- that part of the audit note needed a closer look rather
REM     than a blind change, so it was left as-is on purpose.
REM
REM  3) hreflang tags added to the 65 pages that were missing them:
REM     every geo's Industry/Branche/Industria index + its one
REM     article (30 pages), and the 5 sports sub-pages (football,
REM     basketball, tennis, ice-hockey, volleyball) on the 7 geos
REM     that have them -- ar, mx, es, pe, bo, py, en (35 pages).
REM     All other page types (about, compare, methodology, terms,
REM     the bonus calculator, etc.) already had correct hreflang
REM     from earlier work -- checked all 230 candidate pages first
REM     so nothing already-correct got overwritten.
REM
REM  NOT done in this package, on purpose:
REM   - hreflang on the /guides/ articles. The guide topics don't
REM     line up 1-to-1 across all geos (EN/ES-family have ~14
REM     guides each on matching topics, but DE/IT/FR/PT/BF only
REM     have ~5, some of which merge topics EN splits into 3
REM     separate articles -- e.g. DE's one "umsatzbedingungen-
REM     erklaert" vs EN's three wagering guides). Tagging these as
REM     equivalent without checking each pair would risk hreflang
REM     pointing at a page that isn't really the same article.
REM     This needs a proper per-topic pass, coming next.
REM   - the author page for Oleg Melnikov (still 404s). This needs
REM     real bio text from you -- I'm not going to invent
REM     credentials or background for a byline.
REM   - everything else still open from the audit (contact email,
REM     Sports mirror-domain widget, remaining language/copy fixes,
REM     duplicate meta descriptions, etc.)
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0audit3_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find audit3_deploy folder next to this script.
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

echo All 67 source files found. Starting deploy...
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
echo Done.
echo.
echo Still open from the audit (see chat for the full list):
echo   - hreflang on /guides/ articles -- needs a careful per-
echo     topic pass, not a blind copy
echo   - author page for Oleg Melnikov -- needs real bio text
echo     from you
echo   - contact email/Telegram, Sports mirror-domain widget,
echo     remaining language/copy fixes
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
