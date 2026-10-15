@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Audit round 5 -- country-switcher translation + small
REM  copy/language fixes, 293 files.
REM
REM  NOTE: this round was too big for one zip, so it came as 3
REM  zips (audit5_deploy_part1/2/3.zip). Extract all 3 into the
REM  SAME folder -- their audit5_deploy subfolders merge into one
REM  (Windows will just add the extra geo folders alongside the
REM  ones already there). This .bat and files_list.txt only exist
REM  in part1 -- once all 3 are extracted together, run this one
REM  script same as always.
REM
REM  The Sports mirror-domain widget (1xlite-29668.pro) was
REM  discussed separately -- your call was to leave it exactly as
REM  it is, so nothing in the Sports section was touched here.
REM
REM  What this package does:
REM
REM  1) The country-switcher dropdown (top-right flag menu) and
REM     the matching footer list of all 15 countries always showed
REM     English names (Germany, Mexico, Spain, Peru...) no matter
REM     what language the page itself was in. Translated both
REM     lists into the page's own language on every non-English
REM     geo -- es (ar/bo/mx/pe/py/es), de, it, fr (fr/bf), pt. The
REM     4 English-language geos (en/gh/ke/zm) already showed the
REM     English names correctly, so nothing changed there. Every
REM     one of the ~4900 individual replacements was done with an
REM     exact-match check first (so nothing got skipped or
REM     double-replaced), including the accents: Peru -> Peru
REM     (Peru doesn't take an accent) / Perú (Spanish) / Perù
REM     (Italian) / Pérou (French).
REM
REM  2) Small, isolated copy fixes found while going through the
REM     audit's language-consistency notes:
REM       de: the one footer sentence that used formal "Sie/Ihnen"
REM           while every other sentence on the page uses informal
REM           "du" -- reworded that one sentence to match.
REM       pt: "Se você..." (Brazilian "you") in the footer, and a
REM           separate "podes" (European "tu"-form) elsewhere on
REM           the same page -- two different registers on one
REM           page. Reworded both to the neutral/formal register
REM           already used everywhere else on the page ("verifique
REM           sempre...", "contacte um serviço..."), so the whole
REM           page now reads consistently.
REM       de/es/ar/it: the operator's own bonus-text line included
REM           an ALL-CAPS fragment (BONUSSPIEL / JUEGO DE BONO /
REM           BONUS GAME) describing a bonus-game feature of that
REM           offer. Changed the capitalization only (Bonusspiel /
REM           Juego de Bono / Bonus Game) -- the wording and the
REM           actual bonus terms are unchanged, this is purely a
REM           typographic fix, not a change to what the bonus says.
REM     Checked but found already correct, so NOT changed: the
REM     "beim Spielauswahl" typo the audit flagged on the German
REM     RTP guide -- it already reads "bei der Spielauswahl"
REM     everywhere on that page, nothing to fix there.
REM
REM  Does NOT touch any operator/casino-card content beyond the
REM  bonus-text capitalization above, and does NOT touch de, it,
REM  es, pt, mx, bo, pe, py, ke licensing content, which is still
REM  on hold.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0audit5_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find audit5_deploy folder next to this script.
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

echo All 293 source files found. Starting deploy...
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
echo Still open from the audit: author page for Oleg Melnikov
echo (waiting on real bio text), contact email/Telegram.
echo The Sports mirror-domain widget was discussed and you chose
echo to leave it as-is -- closed, no further action planned there
echo unless you change your mind.
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
