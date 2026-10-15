@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Audit fix: France (/fr/) -- 1 file.
REM
REM  From the audit you sent (Priority 1, item 2 "France"):
REM  /fr/ correctly shows zero casino cards already -- that part
REM  was fine. What was missing was an explanation of WHY, and a
REM  French-specific helpline. This package adds:
REM
REM  1) A new FAQ question (both in the visible accordion and in
REM     the FAQPage JSON-LD, so it's consistent for search
REM     engines too): "Pourquoi n'y a-t-il pas de casino en ligne
REM     liste pour la France ?" -- explains that online casino
REM     games (slots/roulette/blackjack) are not licensed online
REM     in France, only in physical casinos; only sports betting,
REM     horse-race betting and poker are legal online, via
REM     ANJ-licensed operators. Verified against a gambling-law
REM     source (gaming.net, updated May 2026) before writing this.
REM
REM  2) Added the French gambling-helpline badge in the footer:
REM     "Joueurs Info Service : 09 74 75 13 13" -- verified against
REM     Addict Aide (addictaide.fr), an independent French
REM     addiction-support directory.
REM
REM  Nothing else on /fr/ was touched -- no casino cards added,
REM  since /fr/ genuinely has none to show per the audit itself.
REM
REM  Backup: fr\index.html.bak created before overwriting.
REM ============================================================

set "SRC=%~dp0fr_audit_deploy"
set "LIST=%~dp0files_list.txt"

if not exist "%SRC%" (
    echo ERROR: Could not find fr_audit_deploy folder next to this script.
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

echo Source file found. Starting deploy...
echo.

set "COUNT=0"
for /f "usebackq delims=" %%F in ("%LIST%") do (
    set "DESTDIR=%%~dpF"
    if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>&1
    if exist "%%F" copy /Y "%%F" "%%F.bak" >nul
    copy /Y "%SRC%\%%F" "%%F" >nul
    set /a COUNT+=1
)

echo Deployed !COUNT! file (fr\index.html).
echo.
echo ============================================================
echo Done.
echo.
echo Next steps: review the change in GitHub Desktop (one file,
echo fr\index.html), commit and push.
echo ============================================================
pause
