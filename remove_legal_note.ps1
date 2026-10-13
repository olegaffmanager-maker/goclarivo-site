# ============================================================
#  goclarivo-site: remove leftover "note to site owner" paragraph
#  --------------------------------------------------------------
#  What it does: scans every index.html under this script's folder
#  (recursively -- all 15 geos) and removes ONLY the one paragraph
#  that matches:
#
#    <p class="legal-note-inline"> ... </p>
#
#  This is the internal placeholder note ("Nota para el operador
#  del sitio / Note to site owner: this is a generic template...")
#  that ended up visible on 120 live pages (8 page types x 15 geos:
#  compare, methodology, corrections, responsible-gambling, terms,
#  editorial-policy, privacy, about).
#
#  What it does NOT touch: anything else on the page. If a file
#  does not contain that exact paragraph, it is skipped untouched
#  (safe to re-run any time, including after this fix is already
#  applied -- it will just report 0 changed on a second run).
#
#  HOW TO USE:
#  1. Put this .ps1 file in the repo root (next to deploy_sports_
#     pages.bat, README, ar, bo, en, es, mx, pe, py, etc.)
#  2. Right-click it -> "Run with PowerShell".
#     (If Windows blocks it with an execution-policy message, open
#     PowerShell, cd into the repo root, and run:
#       powershell -ExecutionPolicy Bypass -File .\remove_legal_note.ps1
#     This only affects this one script run, nothing permanent.)
#  3. It prints every file it changes. Review the count.
#  4. Open GitHub Desktop -> Changes tab. You should see ~120
#     changed files, every one of them an existing page (never a
#     new file, never a homepage-only change, never touching
#     anything under /sports/). If something looks different,
#     STOP and ask before committing.
# ============================================================

$root = $PSScriptRoot
$pattern = '(?s)\s*<p class="legal-note-inline">.*?</p>\s*\n?'

Write-Host "============================================================"
Write-Host " goclarivo-site: remove leftover site-owner note"
Write-Host "============================================================"
Write-Host ""
Write-Host "Scanning under: $root"
Write-Host ""

$files = Get-ChildItem -Path $root -Filter "index.html" -Recurse -File
$changedCount = 0
$changedFiles = @()
# Write plain UTF-8 with NO byte-order-mark, matching the original files --
# PowerShell's own "-Encoding UTF8" adds a BOM, which would add a pointless
# extra byte-diff to every single file touched.
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    if ($content -match $pattern) {
        $newContent = [regex]::Replace($content, $pattern, '')
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)
        $changedCount++
        $relPath = $file.FullName.Substring($root.Length + 1)
        $changedFiles += $relPath
        Write-Host "  [changed] $relPath"
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host " Done. $changedCount file(s) changed out of $($files.Count) scanned."
Write-Host ""
Write-Host " Expected: around 120 files (8 page types x 15 geos)."
Write-Host " Nothing else on any page was touched -- only that one"
Write-Host " paragraph, wherever it was found."
Write-Host ""
Write-Host " Next: open GitHub Desktop -> Changes tab, review the list,"
Write-Host " write a commit message, commit, push."
Write-Host "============================================================"
Write-Host ""
Read-Host "Press Enter to close"
