<#
.SYNOPSIS
    Builds (or updates) videos.json from the clips in the "video" folder.

.DESCRIPTION
    Workflow for a new project:
      1. Copy this whole folder.
      2. Drop your clips into the "video" subfolder.
      3. Run this script (right-click > Run with PowerShell, or .\generate-videos.ps1).
      4. Upload everything to the server.

    Re-running is safe: entries whose "src" already exists in videos.json keep
    their existing name and category, so manual tweaks are preserved. Files no
    longer in the folder are dropped, and newly-added files are appended.

.PARAMETER Path
    Project root (where videos.json is written). Defaults to this script's folder.

.PARAMETER VideoDir
    Name of the subfolder that holds the clips. Defaults to "video".

.PARAMETER Output
    Where to write the JSON. Defaults to "<Path>\videos.json".

.EXAMPLE
    .\generate-videos.ps1
    Scans .\video and writes .\videos.json.
#>
[CmdletBinding()]
param(
    [string]$Path = $PSScriptRoot,
    [string]$VideoDir = 'video',
    [string]$Output
)

if (-not $Path) { $Path = (Get-Location).Path }
if (-not $Output) { $Output = Join-Path $Path 'videos.json' }
$videoPath = Join-Path $Path $VideoDir

$extensions = @('.mp4', '.webm', '.mov', '.m4v')

# --- Turn a file name into a friendly title ---------------------------------
function Get-PrettyName([string]$baseName) {
    $n = $baseName
    $n = $n -replace '^mofm_', ''                                  # drop series prefix
    $n = $n -replace '(?i)_(is|are)_my_superpower$', ''            # drop superpower suffix
    $n = $n -replace '[_\-]+', ' '                                 # underscores/dashes -> spaces
    $n = $n -creplace '(?<=[a-z0-9])(?=[A-Z])', ' '               # split camelCase (case-sensitive)
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

# --- Make sure the video folder exists --------------------------------------
if (-not (Test-Path $videoPath)) {
    Write-Warning "No '$VideoDir' folder found at '$videoPath'. Creating it - drop your clips in there and run this again."
    New-Item -ItemType Directory -Path $videoPath | Out-Null
    return
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

# --- Scan the video folder for clips ----------------------------------------
$files = Get-ChildItem -Path $videoPath -File |
    Where-Object { $extensions -contains $_.Extension.ToLower() }

if (-not $files) {
    Write-Warning "No video files ($($extensions -join ', ')) found in '$videoPath'."
    return
}

# src is stored web-style: "video/Filename.mp4"
$foundSrcs = $files | ForEach-Object { "$VideoDir/$($_.Name)" }

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
Write-Host "Review the new names and categories, then upload the folder." -ForegroundColor DarkGray
