# link.ps1 — Replace each tool's skills folder with a Junction pointing to the central folder
param(
    [Parameter(Mandatory=$true)]
    [string]$Dest
)

$ErrorActionPreference = "Continue"

# All known AI tool skill paths (relative to USERPROFILE)
$TOOLS = @(
    @{ Path = '.trae-cn\skills';     Name = 'Trae' },
    @{ Path = '.kiro\skills';        Name = 'Kiro' },
    @{ Path = '.codex\skills';       Name = 'Codex' },
    @{ Path = '.doubao\skills';      Name = 'Doubao' },
    @{ Path = '.cc-switch\skills';   Name = 'CC Switch' },
    @{ Path = '.workbuddy\skills';   Name = 'WorkBuddy' },
    @{ Path = '.agents\skills';      Name = 'Agents (npx skills)' }
)

if (-not (Test-Path $Dest)) {
    Write-Host "Central folder does not exist: $Dest" -ForegroundColor Red
    Write-Host "Run merge.ps1 first, or create it manually." -ForegroundColor Red
    exit 1
}

$destResolved = (Resolve-Path $Dest).Path
Write-Host "Central folder: $destResolved`n" -ForegroundColor Cyan

$success = 0
$failed = 0

foreach ($tool in $TOOLS) {
    $fullPath = Join-Path $env:USERPROFILE $tool.Path
    $backupPath = "${fullPath}_backup"
    $name = $tool.Name

    Write-Host "[$name] $fullPath" -ForegroundColor Yellow

    # Check if already a Junction pointing to the right target
    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath -Force
        $isJP = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
        if ($isJP -and ($item.Target -eq $destResolved -or $item.Target -eq $Dest)) {
            Write-Host "  Already linked, skipping" -ForegroundColor Green
            $success++
            continue
        }
    } else {
        # Folder doesn't exist — just create Junction
        try {
            New-Item -ItemType Junction -Path $fullPath -Target $destResolved -Force | Out-Null
            Write-Host "  Junction created (folder did not exist)" -ForegroundColor Green
            $success++
        } catch {
            Write-Host "  Failed: $_" -ForegroundColor Red
            $failed++
        }
        continue
    }

    # Backup existing folder
    if (Test-Path $backupPath) {
        Remove-Item $backupPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    try {
        Rename-Item $fullPath "skills_backup" -ErrorAction Stop
        Write-Host "  Backed up to skills_backup" -ForegroundColor DarkGray
    } catch {
        Write-Host "  Backup failed: $_" -ForegroundColor Red
        $failed++
        continue
    }

    # Create Junction
    try {
        New-Item -ItemType Junction -Path $fullPath -Target $destResolved -Force | Out-Null
        Write-Host "  Junction created" -ForegroundColor Green
        $success++
    } catch {
        Write-Host "  Junction failed: $_" -ForegroundColor Red
        # Rollback
        try { Rename-Item $backupPath "skills" } catch {}
        $failed++
    }
}

Write-Host "`nResult: $success linked, $failed failed" -ForegroundColor Cyan

# Verify
Write-Host "`n=== Verification ===" -ForegroundColor Cyan
foreach ($tool in $TOOLS) {
    $fullPath = Join-Path $env:USERPROFILE $tool.Path
    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath -Force
        $isJP = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
        $count = (Get-ChildItem $fullPath -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '.*' }).Count
        if ($isJP) {
            Write-Host "  OK  ($count skills)  $fullPath -> $($item.Target)" -ForegroundColor Green
        } else {
            Write-Host "  !!  ($count skills)  $fullPath" -ForegroundColor Red
        }
    }
}
