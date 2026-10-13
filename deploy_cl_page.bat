@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  goclarivo-site: deploy Champions League page (ES pilot)
rem  --------------------------------------------------------------
rem  What this does: publishes ONE new page and updates 2 existing
rem  files, all from a "cl_page_fix" folder (next to this script):
rem
rem    1. es\guides\apuestas-champions-league\index.html  (NEW page)
rem    2. es\index.html   (adds one new article card linking to it)
rem    3. sitemap.xml     (adds one new <url> entry so it gets crawled)
rem
rem  es\index.html is a homepage, so as always it gets backed up to
rem  es\index.html.bak before being overwritten. sitemap.xml is
rem  backed up the same way. The new page folder has no previous
rem  version, so there is nothing to back up there.
rem
rem  HOW TO USE:
rem  1. Put this .bat file directly in the repo root.
rem  2. Extract the delivered zip so a "cl_page_fix" folder sits
rem     right next to this .bat file.
rem  3. Run from PowerShell: .\deploy_cl_page.bat
rem  4. GitHub Desktop -^> Changes tab should show: 1 new file
rem     under es\guides\apuestas-champions-league\, plus es\index.html
rem     and sitemap.xml as modified. Do NOT commit the .bak files.
rem ============================================================

set "ROOT=%~dp0"
set "SRC=%ROOT%cl_page_fix"

echo ============================================================
echo  goclarivo-site: deploy Champions League page - ES pilot
echo ============================================================
echo.
echo Repo root:     %ROOT%
echo Source folder: %SRC%
echo.

if not exist "%SRC%" (
    echo ERROR: Could not find the folder:
    echo   %SRC%
    echo.
    echo Extract the delivered zip HERE, right next to this .bat file,
    echo so there is a "cl_page_fix" folder beside it.
    echo Nothing was copied.
    pause
    exit /b 1
)

set "ALL_OK=1"

if not exist "%ROOT%es\index.html" (
    echo   [MISSING TARGET] %ROOT%es\index.html
    set "ALL_OK=0"
)
if not exist "%SRC%\es\index.html" (
    echo   [MISSING SOURCE] %SRC%\es\index.html
    set "ALL_OK=0"
)
if not exist "%ROOT%sitemap.xml" (
    echo   [MISSING TARGET] %ROOT%sitemap.xml
    set "ALL_OK=0"
)
if not exist "%SRC%\sitemap.xml" (
    echo   [MISSING SOURCE] %SRC%\sitemap.xml
    set "ALL_OK=0"
)
if not exist "%SRC%\es\guides\apuestas-champions-league\index.html" (
    echo   [MISSING SOURCE] %SRC%\es\guides\apuestas-champions-league\index.html
    set "ALL_OK=0"
)

if "!ALL_OK!"=="0" (
    echo.
    echo Stopped -- fix the problems listed above and run this script again.
    echo Nothing was copied.
    pause
    exit /b 1
)

echo All paths found. Backing up, then publishing...
echo.

copy /Y "%ROOT%es\index.html" "%ROOT%es\index.html.bak" >nul
copy /Y "%SRC%\es\index.html" "%ROOT%es\index.html" >nul
echo   [OK] es\index.html updated -- backup at es\index.html.bak

copy /Y "%ROOT%sitemap.xml" "%ROOT%sitemap.xml.bak" >nul
copy /Y "%SRC%\sitemap.xml" "%ROOT%sitemap.xml" >nul
echo   [OK] sitemap.xml updated -- backup at sitemap.xml.bak

if not exist "%ROOT%es\guides\apuestas-champions-league" mkdir "%ROOT%es\guides\apuestas-champions-league"
copy /Y "%SRC%\es\guides\apuestas-champions-league\index.html" "%ROOT%es\guides\apuestas-champions-league\index.html" >nul
echo   [OK] es\guides\apuestas-champions-league\index.html published - new page

echo.
echo ============================================================
echo  Done. GitHub Desktop -^> Changes tab should show: the new
echo  page under es\guides\apuestas-champions-league\, plus
echo  es\index.html and sitemap.xml as modified. The .bak files
echo  are untracked backups -- do NOT commit them.
echo ============================================================
echo.
pause
