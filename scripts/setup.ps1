# setup.ps1 — One-step setup: merge skills + create Junctions
param(
    [Parameter(Mandatory=$true)]
    [string]$Dest,
    [switch]$DryRun
)

Write-Host "=== skills-central setup ===" -ForegroundColor Cyan
Write-Host "Central folder: $Dest`n"

# Step 1: Merge
Write-Host "--- Step 1: Merging skills ---" -ForegroundColor Yellow
if ($DryRun) {
    & "$PSScriptRoot\merge.ps1" -Dest $Dest -DryRun
} else {
    & "$PSScriptRoot\merge.ps1" -Dest $Dest
}

# Step 2: Link
Write-Host "`n--- Step 2: Creating Junctions ---" -ForegroundColor Yellow
& "$PSScriptRoot\link.ps1" -Dest $Dest

Write-Host "`n=== Done! Restart your AI tools to see unified skills. ===" -ForegroundColor Cyan
