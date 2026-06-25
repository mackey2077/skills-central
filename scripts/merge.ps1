# merge.ps1 — Scan all tool skill folders and copy unique skills to the central folder
param(
    [string]$Dest = "$env:USERPROFILE\skills-central",
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"

# All known AI tool skill paths (relative to USERPROFILE)
$SOURCES = @(
    @{ Path = '.trae-cn\skills';     Name = 'Trae' },
    @{ Path = '.kiro\skills';        Name = 'Kiro' },
    @{ Path = '.codex\skills';      Name = 'Codex' },
    @{ Path = '.doubao\skills';     Name = 'Doubao' },
    @{ Path = '.cc-switch\skills';  Name = 'CC Switch' },
    @{ Path = '.workbuddy\skills';  Name = 'WorkBuddy' },
    @{ Path = '.agents\skills';     Name = 'Agents (npx skills)' }
)

# Skip package bundles, temp dirs, and hidden entries
$EXCLUDE_NAMES = @(
    'huashu-skills-master', 'huashu-temp', 'khazix-skills',
    'ljg-skills-master', '__pycache__', 'node_modules'
)

function Count-Files([string]$Path) {
    $total = 0
    Get-ChildItem $Path -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object { $total++ }
    return $total
}

# Create central folder if it doesn't exist
if (-not (Test-Path $Dest)) {
    New-Item -ItemType Directory -Path $Dest -Force | Out-Null
}

# Load existing central skills (skip Junctions pointing back — avoid circular scan)
$central = @{}
Get-ChildItem $Dest -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -notlike '.*' -and
    $_.Name -notin $EXCLUDE_NAMES -and
    -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
} | ForEach-Object {
    $central[$_.Name] = Count-Files $_.FullName
}

Write-Host "Central folder: $Dest" -ForegroundColor Cyan
Write-Host "Existing skills: $($central.Count)`n" -ForegroundColor Cyan

# Scan all sources, deduplicate by file count (more files = more complete version)
$registry = @{}
foreach ($src in $SOURCES) {
    $fullPath = Join-Path $env:USERPROFILE $src.Path
    if (-not (Test-Path $fullPath)) { continue }

    # Skip if already a Junction (pointing elsewhere)
    $item = Get-Item $fullPath -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        Write-Host "[$($src.Name)] Junction detected, skipping: $($item.Target)" -ForegroundColor DarkGray
        continue
    }

    $added = 0
    Get-ChildItem $fullPath -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notlike '.*' -and $_.Name -notin $EXCLUDE_NAMES
    } | ForEach-Object {
        $name = $_.Name
        $fc = Count-Files $_.FullName
        if (-not $registry.ContainsKey($name) -or $fc -gt $registry[$name].FileCount) {
            $registry[$name] = @{ Source = $_.FullName; FileCount = $fc; Tool = $src.Name }
            $added++
        }
    }
    Write-Host "[$($src.Name)] Found $added new/better candidates"
}

# Copy missing skills to central folder
$copied = 0
$skipped = 0
foreach ($name in ($registry.Keys | Sort-Object)) {
    $dstPath = Join-Path $Dest $name
    if ($central.ContainsKey($name)) {
        $skipped++
        continue
    }
    $srcPath = $registry[$name].Source
    if ($srcPath -eq $dstPath) { $skipped++; continue }

    if ($DryRun) {
        Write-Host "  [DRY] + $name ($($registry[$name].FileCount) files, from $($registry[$name].Tool))"
    } else {
        Copy-Item $srcPath $dstPath -Recurse -Force
        Write-Host "  + $name ($($registry[$name].FileCount) files, from $($registry[$name].Tool))" -ForegroundColor Green
    }
    $copied++
}

Write-Host "`nResult: +$copied new, $skipped already existed" -ForegroundColor Cyan
$total = (Get-ChildItem $Dest -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '.*' }).Count
Write-Host "Central folder now has $total skills"
