<#
    package.ps1 - Build a complete, installable release ZIP of the mod.

    The repo tracks only editable logic/text; the ~420 MB of compiled art
    (Platforms\**, *.blp) is git-ignored and lives only in the installed mod
    folder. A release ZIP must bundle both so end users get a working mod.

    This script stages:
      * git-tracked files from the repo (minus repo-only tooling), and
      * the compiled art copied from an installed mod folder (-ArtSource),
    then zips them under a single top-level folder "TerraMirabilis2026".

    Usage:
        .\package.ps1
        .\package.ps1 -ArtSource "D:\...\Mods\TerraMirabilis2026" -Out ".\dist\TM2026.zip"
#>
param(
    [string]$ArtSource = (Join-Path $env:USERPROFILE "OneDrive\Documents\My Games\Sid Meier's Civilization VI\Mods\TerraMirabilis2026"),
    [string]$Out       = (Join-Path $PSScriptRoot "dist\TerraMirabilis2026.zip"),
    [string]$FolderName = "TerraMirabilis2026"
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

if (-not (Test-Path $ArtSource)) {
    Write-Error "Art source (installed mod folder) not found:`n  $ArtSource`nInstall/deploy the mod first, or pass -ArtSource."
    exit 1
}

# Repo files that must NOT ship inside the mod (dev tooling / trackers).
$skip = @('.gitignore', '.gitattributes', '.gitattributes.txt', 'deploy.ps1', 'package.ps1',
          'publish.ps1', 'ISSUES.md', 'WONDER_TYPES.md')
# NOTE: README.md and NOTICE are intentionally shipped (info + attribution).

$stageRoot = Join-Path $env:TEMP ("tm_pkg_" + [guid]::NewGuid().ToString('N'))
$stage     = Join-Path $stageRoot $FolderName
New-Item -ItemType Directory -Force -Path $stage | Out-Null

try {
    # 1) git-tracked logic/text from the repo
    Push-Location $repo
    try { $tracked = git ls-files } finally { Pop-Location }

    $nLogic = 0
    foreach ($f in $tracked) {
        if ($skip -contains $f) { continue }
        # art may also be tracked-as-ignored? it isn't; art comes from ArtSource below
        $src = Join-Path $repo $f
        if (-not (Test-Path $src)) { continue }
        $dst = Join-Path $stage $f
        $dir = Split-Path $dst -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        Copy-Item -LiteralPath $src -Destination $dst -Force
        $nLogic++
    }

    # 2) compiled art from the installed folder (Platforms\** and any stray *.blp)
    $nArt = 0
    $artItems = Get-ChildItem -LiteralPath $ArtSource -Recurse -File |
                Where-Object { $_.FullName -match '\\Platforms\\' -or $_.Extension -eq '.blp' }
    foreach ($item in $artItems) {
        $rel = $item.FullName.Substring($ArtSource.TrimEnd('\').Length + 1)
        $dst = Join-Path $stage $rel
        $dir = Split-Path $dst -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        Copy-Item -LiteralPath $item.FullName -Destination $dst -Force
        $nArt++
    }

    if ($nArt -eq 0) {
        Write-Warning "No art files found under $ArtSource (expected Platforms\**). The ZIP will have no models/textures."
    }

    # 3) zip it -- build entries by hand so paths use FORWARD slashes (spec-
    #    compliant; Windows' Compress-Archive writes backslashes, which breaks
    #    extraction on macOS/Linux, and this mod ships MacOS art).
    $outDir = Split-Path $Out -Parent
    if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
    if (Test-Path $Out) { Remove-Item -LiteralPath $Out -Force }
    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::Open($Out, 'Create')
    try {
        $prefixLen = $stageRoot.TrimEnd('\').Length + 1
        foreach ($item in (Get-ChildItem -LiteralPath $stage -Recurse -File)) {
            $arc = $item.FullName.Substring($prefixLen) -replace '\\', '/'
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zip, $item.FullName, $arc,
                [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    } finally { $zip.Dispose() }

    $sizeMB = [math]::Round((Get-Item $Out).Length / 1MB, 1)
    Write-Host ""
    Write-Host "Packaged: $Out"
    Write-Host "  logic/text files: $nLogic"
    Write-Host "  art files:        $nArt"
    Write-Host "  archive size:     $sizeMB MB"
    Write-Host "  top-level folder: $FolderName  (extracts straight into Mods\)"
}
finally {
    if (Test-Path $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force }
}
