@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  This removes the leftover deploy scratch material that has
REM  been piling up in the repository root and has been public
REM  on GitHub Pages this whole time, since Pages publishes
REM  everything in the repo. Nothing here is part of the live
REM  site, every one of these items is either an old working
REM  copy from a past deploy, a pre-edit backup file, or an old
REM  one-time deploy script.
REM
REM  WHAT GETS REMOVED
REM
REM  42 folders, old deploy and fix working copies, about 3570
REM  files total, roughly the names ending in _deploy or _fix.
REM
REM  410 files ending in .bak, pre-edit backup copies scattered
REM  across country folders, assets, and a couple of workflow
REM  files, none of them read by anything live.
REM
REM  43 .bat files sitting in the repository root, one-time
REM  deploy scripts from past updates, their job is done.
REM
REM  WHAT STAYS UNTOUCHED
REM
REM  Every country folder, assets, CNAME, robots.txt, sitemap.xml,
REM  .nojekyll, README.md, and the .github folder with its
REM  automation workflows and scripts.
REM
REM  This was checked against sitemap.xml and every live page
REM  before building this script, nothing live links to any of
REM  the removed items.
REM
REM  This change can be undone through git history if needed,
REM  since every one of these files stays in past commits.
REM ============================================================

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
if not exist ".github" (
    echo ERROR: .github folder not found in the current folder.
    echo Run this script from the root of your goclarivo-site repo.
    pause
    exit /b 1
)

if not exist "dirs_list.txt" (
    echo ERROR: Could not find dirs_list.txt next to this script.
    pause
    exit /b 1
)
if not exist "bak_list.txt" (
    echo ERROR: Could not find bak_list.txt next to this script.
    pause
    exit /b 1
)
if not exist "bat_list.txt" (
    echo ERROR: Could not find bat_list.txt next to this script.
    pause
    exit /b 1
)

echo This will permanently delete, from the current folder:
echo   - 42 old deploy/fix folders  ^(about 3570 files^)
echo   - 410 .bak backup files
echo   - 43 old .bat deploy scripts in the root
echo.
echo Nothing listed above is part of the live site. Country
echo folders, assets, CNAME, robots.txt, sitemap.xml, and the
echo .github folder are not touched.
echo.
echo This is recoverable through git history, but not through
echo this folder on disk once it runs.
echo.
set /p CONFIRM=Type YES to continue:
if /i not "!CONFIRM!"=="YES" (
    echo Cancelled, nothing was deleted.
    pause
    exit /b 0
)

echo.
echo Removing folders...
set "DCOUNT=0"
for /f "usebackq delims=" %%F in ("dirs_list.txt") do (
    if exist "%%F" (
        rmdir /s /q "%%F"
        set /a DCOUNT+=1
    )
)
echo Removed !DCOUNT! folders.

echo.
echo Removing .bak files...
set "BCOUNT=0"
for /f "usebackq delims=" %%F in ("bak_list.txt") do (
    if exist "%%F" (
        del /q "%%F"
        set /a BCOUNT+=1
    )
)
echo Removed !BCOUNT! .bak files.

echo.
echo Removing old root .bat deploy scripts...
set "TCOUNT=0"
for /f "usebackq delims=" %%F in ("bat_list.txt") do (
    if exist "%%F" (
        del /q "%%F"
        set /a TCOUNT+=1
    )
)
echo Removed !TCOUNT! old .bat files.

echo.
echo ============================================================
echo Done. The repository root should now only contain the live
echo site, assets, and the standard project files.
echo.
echo This script, dirs_list.txt, bak_list.txt and bat_list.txt are
echo themselves leftover now too, feel free to delete them from
echo this folder after you are done, they were never part of the
echo site.
echo.
echo Next steps: review the changes in GitHub Desktop, you should
echo see several thousand deletions and no modifications to any
echo live page, then commit and push.
echo ============================================================
pause
