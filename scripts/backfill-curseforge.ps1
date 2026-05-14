<#
.SYNOPSIS
    Adds [update.curseforge] blocks to .pw.toml files that are missing them.

.DESCRIPTION
    Phase 1: Scans all .pw.toml files across every version to build a slug->projectId
    map from entries that already have [update.curseforge] blocks.
    Phase 2: For each .pw.toml still missing a CF block, looks up the project ID
    (from Phase 1 if available, otherwise by CF slug search) then queries CF for the
    right file ID for that MC version. Writes the block BOM-less UTF-8.

    After this script completes, run .\scripts\build-indexes.ps1 to regenerate
    packwiz indexes and export zips.

.PARAMETER Versions
    Packwiz directory names to process. Defaults to all five.

.PARAMETER WhatIf
    Report what would change without writing any files.
#>
[CmdletBinding()]
param(
    [string[]]$Versions = @('1.20.1', '1.21.1', '1.21.4', '26.1.2', '1.21.11'),
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\CurseForge.ps1"

if (-not (Test-CurseForgeAvailable)) {
    Write-Error "CURSEFORGE_API_KEY is not set. Set it in your .env file or environment."
    exit 1
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# --- Phase 1: build slug -> CF project ID map from existing blocks ---

Write-Host 'Phase 1: collecting known CF project IDs...'

$knownProjectId = @{}  # slug -> int

foreach ($v in $Versions) {
    $modsDir = "Packwiz\$v\mods"
    if (-not (Test-Path $modsDir)) { continue }

    foreach ($toml in (Get-ChildItem $modsDir -Filter *.pw.toml)) {
        $content = [System.IO.File]::ReadAllText($toml.FullName, $utf8NoBom)
        if ($content -match 'project-id\s*=\s*(\d+)') {
            $slug = $toml.BaseName -replace '\.pw$', ''
            $knownProjectId[$slug] = [int]$Matches[1]
        }
    }
}

$knownList = ($knownProjectId.Keys | Sort-Object) -join ', '
Write-Host "  $($knownProjectId.Count) project IDs already known: $knownList"

# --- Phase 2: backfill missing blocks ---

Write-Host ''
Write-Host 'Phase 2: backfilling missing [update.curseforge] blocks...'

$cntUpdated   = 0
$cntWould     = 0
$cntNotFound  = 0
$cntError     = 0

foreach ($v in $Versions) {
    $modsDir = "Packwiz\$v\mods"
    if (-not (Test-Path $modsDir)) {
        Write-Warning "[$v] No mods directory -- skipping"
        continue
    }

    $packToml  = [System.IO.File]::ReadAllText("Packwiz\$v\pack.toml", $utf8NoBom)
    $mcVersion = $v
    if ($packToml -match 'minecraft = "(\S+)"') { $mcVersion = $Matches[1] }

    $allToml  = Get-ChildItem $modsDir -Filter *.pw.toml
    $missing  = $allToml | Where-Object {
        ([System.IO.File]::ReadAllText($_.FullName, $utf8NoBom)) -notmatch 'update\.curseforge'
    }

    Write-Host ''
    Write-Host "[$v] MC $mcVersion -- $($missing.Count) of $($allToml.Count) mods need CF block"

    foreach ($toml in $missing) {
        $slug    = $toml.BaseName -replace '\.pw$', ''
        $content = [System.IO.File]::ReadAllText($toml.FullName, $utf8NoBom)

        # Resolve project ID
        $projectId = $null
        if ($knownProjectId.ContainsKey($slug)) {
            $projectId = $knownProjectId[$slug]
            Write-Host "  $slug -- project $projectId (reused from another version)"
        } else {
            Write-Host "  $slug -- searching CF..." -NoNewline
            try {
                $project = Get-CurseForgeProject -Slug $slug
                Start-Sleep -Milliseconds 250
            } catch {
                Write-Host " API error: $_"
                $cntError++
                continue
            }

            if (-not $project) {
                Write-Host " not found on CurseForge"
                $cntNotFound++
                continue
            }

            $projectId = [int]$project.id
            $knownProjectId[$slug] = $projectId
            Write-Host " found project $projectId"
        }

        # Resolve file ID for this MC version
        try {
            $files = Get-CurseForgeFiles -ProjectId $projectId -McVersion $mcVersion -LoaderType 4
            Start-Sleep -Milliseconds 250
        } catch {
            Write-Host "  $slug -- file lookup error: $_"
            $cntError++
            continue
        }
        # @($null) stays $null in PS5.1; guard before passing to Select-CurseForgeFile
        if ($null -eq $files) { $files = @() }
        $file = Select-CurseForgeFile -Files $files

        if (-not $file) {
            Write-Host "  $slug -- no Fabric file for MC $mcVersion (project $projectId)"
            $cntNotFound++
            continue
        }

        $fileId = [int]$file.id
        $note   = ''
        if ($file.fallback_used) { $note = ' [beta/alpha]' }

        if ($WhatIf) {
            Write-Host "  $slug -- WOULD add project-id=$projectId file-id=$fileId$note"
            $cntWould++
        } else {
            $append     = "[update.curseforge]`r`nfile-id = $fileId`r`nproject-id = $projectId`r`n"
            $newContent = $content.TrimEnd("`r", "`n") + "`r`n" + $append
            [System.IO.File]::WriteAllText($toml.FullName, $newContent, $utf8NoBom)
            Write-Host "  $slug -- wrote project-id=$projectId file-id=$fileId$note"
            $cntUpdated++
        }
    }
}

Write-Host ''
Write-Host '--- Summary ---'
if ($WhatIf) {
    Write-Host "  Would update : $cntWould"
} else {
    Write-Host "  Updated      : $cntUpdated"
}
Write-Host "  Not on CF    : $cntNotFound"
Write-Host "  Errors       : $cntError"

if ((-not $WhatIf) -and ($cntUpdated -gt 0)) {
    Write-Host ''
    Write-Host 'Run .\scripts\build-indexes.ps1 to regenerate packwiz indexes and export zips.'
}
