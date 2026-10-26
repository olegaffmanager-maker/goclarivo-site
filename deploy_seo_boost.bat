@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  SEO push for two pages already ranking close to page one,
REM  plus a de-duplication pass on a guide that was almost word
REM  for word the same across five geos. 7 files change, nothing
REM  is deleted.
REM
REM  WHAT CHANGED
REM
REM  bo/sports/index.html -- new title and meta description with
REM  Bolivia earlier in both, H1 reworded to match, a new section
REM  up top covering legality and the AJ and Ley 060 situation,
REM  deposit methods, popular football and leagues, and what to
REM  check in a bonus, plus a working FAQ section with 5
REM  questions and FAQPage markup, which also fixes the footer
REM  FAQ link that previously pointed at nothing.
REM
REM  in/guides/what-is-wagering-explained-simply/index.html --
REM  expanded from about 450 to about 1130 words. New title and
REM  meta description, a multiplier table from times 10 to times
REM  50, a worked bonus-only versus bonus-plus-deposit comparison,
REM  a worked example of how game contribution changes the real
REM  amount you must bet, a section on the expected cost of
REM  wagering at a typical 96 percent RTP, guidance on judging
REM  whether a bonus is worth it, and a fifth FAQ question. Also
REM  fixed a stray inLanguage tag that said en-GH on an India
REM  page.
REM
REM  en, gh, ke and zm versions of the same guide -- the one
REM  worked example in each was identical dollar figures copied
REM  across all five geos. Each now uses its own currency and its
REM  own numbers instead, Ghana cedi, Kenyan shilling, Zambian
REM  kwacha and a distinct dollar example for the international
REM  page.
REM
REM  sitemap.xml -- lastmod bumped to today for these 6 page
REM  URLs.
REM
REM  Backups: a .bak is created for every changed file before it
REM  is overwritten.
REM
REM  Still pending from before this: the odds_fix_deploy.zip sent
REM  earlier, if you have not run it yet.
REM ============================================================

set "SRC=%~dp0seo_boost_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find seo_boost_deploy folder next to this script.
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
    if exist "%%F" copy /Y "%%F" "%%F.bak" >nul
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Copied and backed up !COUNT! files.
echo.
echo ============================================================
echo Done. 7 files updated: bo/sports, the wagering guide on all
echo five of its geos, and sitemap.xml.
echo.
echo Next steps: review the changes in GitHub Desktop, then
echo commit and push.
echo ============================================================
pause
