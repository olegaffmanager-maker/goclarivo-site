# ============================================================
#  goclarivo-site: restore per-sport widget markers
#  --------------------------------------------------------------
#  WHY THIS IS NEEDED: the odds-refresh script (scripts/onexbet_
#  odds.py) had a bug -- every time it updated a sport's section
#  on a /sports/ page, it rewrote that section's marker comments
#  to the generic <!-- ONEXBET_ODDS_WIDGET:START/END --> form,
#  even for basketball/tennis/hockey/volleyball (which should
#  keep their own tagged markers, e.g.
#  <!-- ONEXBET_ODDS_WIDGET_BASKETBALL:START -->). That happened
#  silently on the very first successful run. The next scheduled
#  run can no longer find those sports' markers and fails with
#  "markers not found" again -- same symptom as before, different
#  cause. The script itself is now fixed (separate file), but the
#  live pages already have the downgraded markers and need this
#  one-time repair so future runs keep working.
#
#  WHAT THIS SCRIPT DOES: for every {geo}\sports\index.html, finds
#  each sport's panel by its own data-tab="..." attribute and
#  restores that sport's correctly-tagged marker comments. It
#  leaves football's markers as-is (football always used the
#  plain, untagged marker -- that was never the bug) and does not
#  touch anything else on the page, including the live match data
#  itself.
#
#  Re-running this safely does nothing on a page that's already
#  correct (0 changes reported).
#
#  HOW TO USE: same as the other two scripts -- put this .ps1 in
#  the repo root, right-click -> "Run with PowerShell" (or, if
#  blocked, open PowerShell in this folder and run:
#    powershell -ExecutionPolicy Bypass -File .\fix_sports_markers.ps1
#  ), review the report, then GitHub Desktop -> Changes -> commit
#  -> push.
# ============================================================

$root = $PSScriptRoot
$pattern = [regex]'(?s)(<div class="sport-tab-panel" data-tab="(?<sport>[a-z]+)">)<!-- ONEXBET_ODDS_WIDGET:START -->(?<body>.*?)<!-- ONEXBET_ODDS_WIDGET:END -->'

Write-Host "============================================================"
Write-Host " goclarivo-site: restore per-sport widget markers"
Write-Host "============================================================"
Write-Host ""
Write-Host "Scanning under: $root"
Write-Host ""

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$geos = @("ar", "bo", "en", "es", "mx", "pe", "py")
$totalChanged = 0
$filesChanged = 0

foreach ($geo in $geos) {
    $path = Join-Path $root "$geo\sports\index.html"
    if (-not (Test-Path $path)) {
        Write-Host "  [SKIP] $geo\sports\index.html not found"
        continue
    }

    $content = [System.IO.File]::ReadAllText($path)
    $fileChangeCount = 0

    $evaluator = {
        param($m)
        $sport = $m.Groups['sport'].Value
        if ($sport -eq 'football') {
            return $m.Value
        }
        $script:fileChangeCount++
        $tag = $sport.ToUpper()
        $open = $m.Groups[1].Value
        $body = $m.Groups['body'].Value
        return "$open<!-- ONEXBET_ODDS_WIDGET_${tag}:START -->$body<!-- ONEXBET_ODDS_WIDGET_${tag}:END -->"
    }

    $script:fileChangeCount = 0
    $newContent = $pattern.Replace($content, $evaluator)

    if ($script:fileChangeCount -gt 0) {
        [System.IO.File]::WriteAllText($path, $newContent, $utf8NoBom)
        Write-Host "  [changed] $geo\sports\index.html -- $($script:fileChangeCount) marker pair(s) restored"
        $totalChanged += $script:fileChangeCount
        $filesChanged++
    } else {
        Write-Host "  [ok, no change needed] $geo\sports\index.html"
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host " Done. $filesChanged file(s) updated, $totalChanged marker pair(s) restored."
Write-Host " Expected on first run: 7 files, 28 marker pairs (4 sports x 7 geos)."
Write-Host ""
Write-Host " Next: open GitHub Desktop -> Changes tab, review the list"
Write-Host " (should be exactly the 7 sports/index.html files), commit, push."
Write-Host "============================================================"
Write-Host ""
Read-Host "Press Enter to close"
