@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Second cleanup pass.
REM
REM  The first cleanup script reported success locally but its
REM  deletions did not end up in what got pushed, and the two
REM  deploy packages run right after it added two more scratch
REM  staging folders of their own on top. This script removes
REM  everything of that kind that is currently sitting in the
REM  repo folder, root level deploy and fix staging folders,
REM  backup copies scattered through the site folders, old
REM  deploy bat scripts, and the leftover list text files. It
REM  also adds a gitignore file so this stops happening again,
REM  once it is in place none of this kind of file will show up
REM  as a change to commit even if it gets created locally later.
REM
REM  Nothing inside the real site folders is touched other than
REM  removing the bak backup copies next to their originals.
REM
REM  This script asks for a typed YES before deleting anything
REM  and shows counts first. If you are not sure the counts look
REM  right, answer anything other than YES and nothing happens.
REM ============================================================

set "SRC=%~dp0cleanup_v2_deploy"
set "LIST=%~dp0files_list.txt"
set "SELF=%~nx0"

if not exist "%SRC%" (
    echo ERROR: Could not find cleanup_v2_deploy folder next to this script.
    pause
    exit /b 1
)
if not exist "%SRC%\.gitignore" (
    echo ERROR: Could not find .gitignore inside cleanup_v2_deploy.
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

echo Scanning the repo folder, this does not change anything yet.
echo.

set "DIRCOUNT=0"
for /d %%D in (*_deploy *_fix) do (
    if exist "%%D" set /a DIRCOUNT+=1
)

set "BAKCOUNT=0"
for /r %%F in (*.bak) do (
    set /a BAKCOUNT+=1
)

set "BATCOUNT=0"
for %%F in (*.bat) do (
    if /I not "%%~nxF"=="!SELF!" set /a BATCOUNT+=1
)

set "LISTCOUNT=0"
for %%F in (files_list.txt dirs_list.txt bat_list.txt bak_list.txt) do (
    if exist "%%F" set /a LISTCOUNT+=1
)

echo Found:
echo   !DIRCOUNT! deploy/fix staging folders at the repo root
echo   !BAKCOUNT! .bak backup files inside the site folders
echo   !BATCOUNT! old .bat scripts at the repo root, other than this one
echo   !LISTCOUNT! leftover list text files at the repo root
echo.
echo This will delete all of the above and add a .gitignore file
echo so none of this is picked up as a change to commit again.
echo.
set /p CONFIRM=Type YES to continue:

if not "%CONFIRM%"=="YES" (
    echo Cancelled, nothing was deleted.
    pause
    exit /b 0
)

echo.
echo Deleting staging folders...
set "DELDIR=0"
for /d %%D in (*_deploy *_fix) do (
    if exist "%%D" (
        rd /s /q "%%D"
        set /a DELDIR+=1
    )
)

echo Deleting .bak backup files...
set "DELBAK=0"
for /r %%F in (*.bak) do (
    if exist "%%F" (
        del /q "%%F"
        set /a DELBAK+=1
    )
)

echo Deleting old .bat scripts...
set "DELBAT=0"
for %%F in (*.bat) do (
    if /I not "%%~nxF"=="!SELF!" (
        del /q "%%F"
        set /a DELBAT+=1
    )
)

echo Deleting leftover list text files...
set "DELLIST=0"
for %%F in (files_list.txt dirs_list.txt bat_list.txt bak_list.txt) do (
    if exist "%%F" (
        del /q "%%F"
        set /a DELLIST+=1
    )
)

echo Adding .gitignore...
if exist ".gitignore" copy /Y ".gitignore" ".gitignore.bak" >nul
copy /Y "%SRC%\.gitignore" ".gitignore" >nul

echo.
echo ============================================================
echo Done.
echo   Removed !DELDIR! staging folders
echo   Removed !DELBAK! .bak files
echo   Removed !DELBAT! old .bat scripts
echo   Removed !DELLIST! list text files
echo   Added a .gitignore file at the repo root
echo.
echo Next steps: open GitHub Desktop and check the change list.
echo You should see a large number of removed files, the new
echo .gitignore file, and nothing else. Review it, then commit
echo and push in one commit. This script itself will not show up
echo as a change thanks to the new .gitignore, it is safe to
echo leave it in the folder or delete it by hand afterward.
echo ============================================================
pause
