@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Audit round 2 -- continuing GoClarivo_audit.docx, 11 files.
REM
REM  IMPORTANT: this does NOT touch de, it, es, pt, mx*, bo*, pe*,
REM  py*, ke* operator/licensing content -- those 9 geos are still
REM  on hold per your "let me think" / "come back later" answers.
REM  (*mx/bo/pe/py/ke ARE touched here, but only for a footer
REM  helpline badge or a wording fix unrelated to operators/
REM  licensing -- see the breakdown below. No casino card, no
REM  "Verified" badge, no licensing claim was changed on them.)
REM
REM  What this package does:
REM
REM  1) Local helplines added to the footer (verified via web
REM     research, each a real published number):
REM       mx: Linea de la Vida -- 800 911 2000
REM       pe: Linea 113 Salud -- 113
REM       bo: Familia Segura -- 800-11-3040 (single source found --
REM           shown plainly, not labeled "official gambling line")
REM       py: Linea 155 -- 155
REM       gh: Ghana Mental Health Authority -- 0800 678 678
REM       ke: Befrienders Kenya -- +254 722 178 177
REM       zm: Lifeline Zambia -- 933 (single source found)
REM     Deliberately NOT added: pt (only candidate number is
REM     unconfirmed by any official source) and bf (no verifiable
REM     number found at all). Both keep their existing
REM     international-resource badge only -- nothing removed.
REM
REM  2) Paraguay (py): "CONAJZAR" -> "DNIT" (Direccion Nacional de
REM     Ingresos Tributarios). Researched and confirmed: Paraguay's
REM     Law No 7438 (2024) merged CONAJZAR into DNIT. Updated the
REM     meta description, FAQ answers, methodology text, footer
REM     badge and footer link label on /py/ -- same dnit.gov.py URL
REM     kept throughout, only the name was outdated. The dedicated
REM     guide page explaining the old CONAJZAR/.bet.py system
REM     keeps its historical title (so the URL doesn't break) but
REM     now has an added "Update (2026)" note explaining the 2024
REM     merger, plus the same footer badge/link fix.
REM
REM  3) Fixed internal contradictions found in the audit:
REM       en: hero badge said "Rechecked monthly" while the FAQ
REM           says there is no fixed automated cycle yet -> changed
REM           badge to "Rechecked periodically" (matches the FAQ).
REM       en: the methodology-weights row showed only 4 tiles
REM           (one of them "Mobile + Bonus Terms" merged together)
REM           right under a "05 Rating criteria" stat -- now split
REM           into the 5 individual tiles (15% Mobile Experience +
REM           10% Bonus Terms) so the count actually matches what's
REM           shown, with the same total weights as before.
REM       en / gh / zm: FAQ said "Bonus Transparency" while the
REM           methodology section calls the same criterion "Bonus
REM           Terms" -- unified on "Bonus Terms" everywhere on
REM           these 3 geos (not touched on the paused geos).
REM       en / gh: "Featured Casino" (singular) + "the operator we
REM           already work with" now show 2 real cards each
REM           (1xBet + Mostbet / BetAndYou Africa + Mostbet) --
REM           pluralized the heading and reworded the paragraph to
REM           also make clear this placement doesn't skip the
REM           normal ranking methodology once review is done
REM           (this was an inconsistency with the "does a casino
REM           pay to be ranked higher? No." FAQ answer).
REM       ar: same fix -- "Casino destacado" (singular) now shows 3
REM           cards (1xBet, 20Bet, Mostbet) -- pluralized heading +
REM           paragraph the same way.
REM       en/sports: the Sports section said "under construction...
REM           the slots below are placeholders" directly above a
REM           real 1xBet card with a real affiliate link and a live
REM           odds widget with real match data -- reworded both the
REM           intro line and the "Top 10 Sportsbooks / placeholder
REM           list" heading to honestly describe what's actually
REM           there (one featured operator while in review, plus a
REM           live odds feed), instead of calling it a placeholder.
REM           The live odds widget/links themselves were NOT
REM           touched -- see the note you'll get separately about
REM           that, it needs your decision, not a silent edit.
REM
REM  Backups: a .bak is created for every file before overwriting.
REM ============================================================

set "SRC=%~dp0audit2_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find audit2_deploy folder next to this script.
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

echo All 11 source files found. Starting deploy...
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
echo Still on hold, untouched: de, it, es, pt and the operator/
echo licensing content on mx, bo, pe, py, ke -- waiting on you.
echo.
echo Still needs your decision (not done here, see chat):
echo   - the "Verified" badge wording on casino cards site-wide
echo   - the zm/bf "00 Verified casinos" vs a green Verified badge
echo     on the one card shown
echo   - the Sports section's live-odds widget linking to a 1xBet
echo     mirror domain (1xlite-29668.pro)
echo.
echo Next steps: review the changes in GitHub Desktop, commit and
echo push.
echo ============================================================
pause
