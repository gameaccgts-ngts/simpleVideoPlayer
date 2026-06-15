<#
.SYNOPSIS
    Builds (or updates) videos.json from the video files in a folder.

.DESCRIPTION
    Scans a folder for video files and writes a videos.json the player can read.
    Re-running is safe: entries whose "src" already exists in videos.json keep
    their existing name and category, so any manual tweaks you've made are
    preserved. Only newly-found files are added.

.PARAMETER Path
    Folder to scan for videos. Defaults to the folder the script lives in.

.PARAMETER Output
    Where to write the JSON. Defaults to "<Path>\videos.json".

.EXAMPLE
    .\generate-videos.ps1
    Scans the current project folder and writes videos.json.

.EXAMPLE
    .\generate-videos.ps1 -Path "D:\Projects\NewClips"
    Generates videos.json for a different project's clips.
#>
[CmdletBinding()]
param(
    [string]$Path = $PSScriptRoot,
    [string]$Output
)

if (-not $Path) { $Path = (Get-Location).Path }
if (-not $Output) { $Output = Join-Path $Path 'videos.json' }

$extensions = @('.mp4', '.webm', '.mov', '.m4v')

# --- Turn a file name into a friendly title ---------------------------------
function Get-PrettyName([string]$baseName) {
    $n = $baseName
    $n = $n -replace '^mofm_', ''                                  # drop series prefix
    $n = $n -replace '(?i)_(is|are)_my_superpower$', ''            # drop superpower suffix
    $n = $n -replace '[_\-]+', ' '                                 # underscores/dashes -> spaces
    $n = $n -creplace '(?<=[a-z0-9])(?=[A-Z])', ' '                # split camelCase (case-sensitive)
    $n = ($n -replace '\s+', ' ').Trim()                           # collapse spaces
    if (-not $n) { return $baseName }
    $ti = (Get-Culture).TextInfo
    return $ti.ToTitleCase($n.ToLower())
}

# --- Guess a category from the file name ------------------------------------
function Get-Category([string]$baseName) {
    if ($baseName -match '(?i)superpower') { return 'Superpowers' }
    if ($baseName -match '^(?i)mofm_')     { return 'Magic of Me' }
    return 'Stories'
}

# --- Load existing videos.json so we can preserve manual edits --------------
$existing = @{}
$existingOrder = @()
if (Test-Path $Output) {
    try {
        $prev = Get-Content $Output -Raw | ConvertFrom-Json
        foreach ($item in $prev) {
            if ($item.src) {
                $existing[$item.src] = $item
                $existingOrder += $item.src
            }
        }
        Write-Host "Found existing videos.json with $($existing.Count) entries - preserving custom names and categories." -ForegroundColor Cyan
    } catch {
        Write-Warning "Could not parse existing videos.json; it will be rebuilt from scratch."
    }
}

# --- Scan the folder for videos ---------------------------------------------
$files = Get-ChildItem -Path $Path -File |
    Where-Object { $extensions -contains $_.Extension.ToLower() }

if (-not $files) {
    Write-Warning "No video files ($($extensions -join ', ')) found in '$Path'."
    return
}

$foundSrcs = $files | ForEach-Object { $_.Name }

# Keep previously-known files in their original order, then append new ones (A-Z).
$ordered = @()
$ordered += $existingOrder | Where-Object { $foundSrcs -contains $_ }
$ordered += ($foundSrcs | Where-Object { -not $existing.ContainsKey($_) } | Sort-Object)

$entries = foreach ($src in $ordered) {
    if ($existing.ContainsKey($src)) {
        $e = $existing[$src]
        [ordered]@{ name = $e.name; src = $e.src; category = $e.category }
    } else {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($src)
        [ordered]@{ name = (Get-PrettyName $base); src = $src; category = (Get-Category $base) }
    }
}

# --- Write JSON (UTF-8, no BOM, real array even for a single item) ----------
$json = $entries | ConvertTo-Json -Depth 3
if ($entries.Count -le 1) { $json = "[$json]" }
[System.IO.File]::WriteAllText($Output, $json, (New-Object System.Text.UTF8Encoding $false))

$newCount = ($ordered | Where-Object { -not $existing.ContainsKey($_) }).Count
$keptCount = $entries.Count - $newCount
Write-Host "Wrote $($entries.Count) entries to $Output. New: $newCount  Preserved: $keptCount" -ForegroundColor Green
Write-Host "Review the new names and categories, then commit videos.json." -ForegroundColor DarkGray
