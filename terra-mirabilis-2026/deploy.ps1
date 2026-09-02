<#
    deploy.ps1 - Copy the version-controlled mod files into the Civ6 Mods folder.

    Only git-tracked files are deployed, so the 420 MB of compiled art in
    Platforms/ (which is git-ignored and lives only in the game folder) is
    never touched. Repo tooling (.gitignore, README, this script, etc.) is
    also skipped.

    Usage:
        .\deploy.ps1              # deploy to the default Mods\TerraMirabilis2026 folder
        .\deploy.ps1 -DryRun      # show what would be copied, change nothing
        .\deploy.ps1 -Target "D:\path\to\Mods\TerraMirabilis2026"
#>
param(
    [string]$Target = (Join-Path $env:USERPROFILE "OneDrive\Documents\My Games\Sid Meier's Civilization VI\Mods\TerraMirabilis2026"),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

if (-not (Test-Path $Target)) {
    Write-Error "Target mod folder not found:`n  $Target`nPass the correct path with -Target."
    exit 1
}

# Files that live in the repo but must NOT be copied into the mod
$skip = @('.gitignore', '.gitattributes', '.gitattributes.txt', 'README.md', 'deploy.ps1',
          'NOTICE', 'ISSUES.md', 'WONDER_TYPES.md', 'package.ps1')

Push-Location $repo
try {
    $files = git ls-files
} finally {
    Pop-Location
}

$count = 0
foreach ($f in $files) {
    if ($skip -contains $f) { continue }
    $src = Join-Path $repo $f
    $dst = Join-Path $Target $f
    if ($DryRun) {
        Write-Host "would copy: $f"
        $count++
        continue
    }
    $dstDir = Split-Path $dst -Parent
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }
    Copy-Item -LiteralPath $src -Destination $dst -Force
    $count++
}

if ($DryRun) {
    Write-Host "`nDry run: $count files would be deployed to`n  $Target"
} else {
    Write-Host "`nDeployed $count files to`n  $Target"
    Write-Host "Restart Civ VI (or reload the mod) to pick up the changes."
}
