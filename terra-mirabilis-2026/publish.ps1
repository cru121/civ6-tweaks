<#
    publish.ps1 - Publish this dev repo's current state to the PUBLIC repo.

    This dev repo (civ6-terra-mira) has NO git remote on purpose:
      * its commits are authored under the maintainer's REAL name/email, and
      * its root maps to a SUBFOLDER of the public multi-project repo.
    So we never `git push` this repo. Instead this script mirrors the repo's
    git-tracked files into the public repo's subfolder and commits them there
    under the pseudonym, leaving your real identity out of anything public.

    What it does:
      1. clones the public repo fresh to a temp dir (source-only, ~small),
      2. replaces <Subfolder>/ with this repo's tracked files at HEAD
         (adds, edits AND deletions are mirrored),
      3. commits as cru121 and pushes (HTTPS auth via Git Credential Manager).

    It does NOT touch the release ZIP. If a shipped file changed and you want
    the download to match, re-run package.ps1 and update the release asset
    (e.g. gh release upload tm-2026-v1 dist\TerraMirabilis2026.zip --clobber).

    Usage:
        .\publish.ps1
        .\publish.ps1 -Message "Fountain of Youth text fix; link docs site"
        .\publish.ps1 -DryRun
#>
param(
    [string]$Repo        = $PSScriptRoot,
    [string]$RemoteUrl   = "https://github.com/cru121/civ6-tweaks.git",
    [string]$Branch      = "main",
    [string]$Subfolder   = "terra-mirabilis-2026",
    [string]$AuthorName  = "cru121",
    [string]$AuthorEmail = "cru121@users.noreply.github.com",
    [string]$Message,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Refuse to publish a dirty tree - only committed state is mirrored.
Push-Location $Repo
try {
    $dirty = git status --porcelain
    if ($dirty) {
        Write-Error "Dev repo has uncommitted changes - commit them first so the public copy matches:`n$dirty"
        exit 1
    }
    $devHead = (git rev-parse --short HEAD).Trim()
} finally { Pop-Location }

if (-not $Message) { $Message = "Sync $Subfolder from dev repo ($devHead)" }

$work = Join-Path $env:TEMP ("tm_publish_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null
try {
    # git writes progress to stderr; under PS 5.1 do NOT use 2>&1 (it turns
    # stderr into a terminating NativeCommandError). Check $LASTEXITCODE instead.
    function Invoke-Git { param([Parameter(ValueFromRemainingArguments)]$GitArgs)
        $eap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        try { & git @GitArgs } finally { $ErrorActionPreference = $eap }
        if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed (exit $LASTEXITCODE)" }
    }

    $clone = Join-Path $work "repo"
    $sub   = Join-Path $clone $Subfolder
    Write-Host "Cloning $RemoteUrl ..."
    Invoke-Git clone --quiet --depth 1 --branch $Branch $RemoteUrl $clone

    # Replace the subfolder wholesale so deletions propagate.
    if (Test-Path $sub) { Remove-Item -LiteralPath $sub -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $sub | Out-Null

    # Export exactly the tracked files at HEAD (git-ignored art is excluded).
    $treeZip = Join-Path $work "tree.zip"
    Push-Location $Repo
    try { Invoke-Git archive --format=zip --output=$treeZip HEAD } finally { Pop-Location }
    Expand-Archive -LiteralPath $treeZip -DestinationPath $sub -Force

    Push-Location $clone
    try {
        Invoke-Git add -A -- $Subfolder
        $changes = git status --porcelain -- $Subfolder
        if (-not $changes) {
            Write-Host "Public repo already matches dev HEAD ($devHead) - nothing to publish."
            return
        }
        Write-Host "`nChanges to publish in ${Subfolder}:"
        git status --short -- $Subfolder

        if ($DryRun) { Write-Host "`nDry run - not committing or pushing."; return }

        # Set identity via env (avoids passing '-c' to the wrapper function).
        $env:GIT_AUTHOR_NAME = $AuthorName;    $env:GIT_AUTHOR_EMAIL = $AuthorEmail
        $env:GIT_COMMITTER_NAME = $AuthorName; $env:GIT_COMMITTER_EMAIL = $AuthorEmail
        Invoke-Git commit -q -m $Message
        Write-Host "`nCommitted as $AuthorName. Pushing to $Branch ..."
        Invoke-Git push --quiet origin "HEAD:$Branch"
        $pub = (git rev-parse --short HEAD).Trim()
        Write-Host "Published $pub -> $RemoteUrl ($Branch), subfolder $Subfolder."
    } finally { Pop-Location }
}
finally {
    if (Test-Path $work) { Remove-Item -LiteralPath $work -Recurse -Force }
}
