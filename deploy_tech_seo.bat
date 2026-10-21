@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Technical SEO hygiene fixes. 7 files changed, no folders
REM  deleted.
REM
REM  WHAT CHANGED
REM
REM  1, nojekyll. A new, empty file at the root of the repo. The
REM  site is not a Jekyll project, so this tells GitHub Pages to
REM  skip Jekyll processing entirely and just publish the files
REM  as they are. Checked first that this is safe -- none of the
REM  sites HTML files have Jekyll front matter, so nothing was
REM  actually being templated before either way. This is just
REM  standard hygiene for a plain static site on GitHub Pages.
REM
REM  2, zm, gh, bf, ke index pages and ke sports index. Fixed a
REM  CSS typo in the BetAndYou Africa logo markup. The style tag
REM  had doubled curly braces, st0 fill colon hex semicolon with
REM  an extra brace on each side, which is not valid CSS and
REM  likely made the browser drop the color rule, so the logo may
REM  have shown without its yellow and red brand colors. Changed
REM  to single braces, standard CSS. Nothing else on these pages
REM  was touched.
REM
REM  3, sitemap.xml. The lastmod date was stuck at 15 Oct for
REM  every one of the 412 pages, even ones changed more recently.
REM  Updated lastmod to todays date only for the 49 pages that
REM  actually changed in this round and the two previous rounds,
REM  the India wording page, the 4 geos that got a 1xBet card,
REM  and the 43 sports pages that were synced to match each
REM  geos main page. Every other page keeps its original date,
REM  nothing else in the file was touched.
REM
REM  Note on the Ahrefs screenshot you shared, zero backlinks and
REM  zero organic traffic, going through sitemap, robots.txt,
REM  meta robots, canonical tags and this Jekyll question did not
REM  turn up anything that blocks indexing. That picture matches
REM  a brand new site with no backlinks yet, not a technical
REM  fault, and fixing it is a question of time and outside links
REM  rather than a setting on the site itself.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0tech_seo_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find tech_seo_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%LIST%" (
    echo ERROR: Could not find files_list.txt next to this script.
    pause
    exit /b 1
)

if not exist "zm" (
    echo ERROR: zm folder not found in the current folder.
    echo Run this script from the root of your goclarivo-site repo.
    pause
    exit /b 1
)
if not exist "sitemap.xml" (
    echo ERROR: sitemap.xml not found in the current folder.
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

echo All 7 source files found. Starting deploy...
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
echo Done. nojekyll added, BetAndYou Africa logo CSS fixed on
echo zm, gh, bf, ke and ke sports, and sitemap.xml lastmod dates
echo refreshed for the 49 pages changed so far.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
