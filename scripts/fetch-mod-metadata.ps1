#requires -Version 5.1
<#
.SYNOPSIS
  Fetch mod metadata from Modrinth (and optionally CurseForge) and emit JSON.
.PARAMETER Identifier
  Modrinth slug ("sodium"), project ID, full URL, or numeric CF project ID.
.PARAMETER McVersions
  Array of MC version strings to evaluate.
.PARAMETER Loader
  Loader to require (default "fabric").
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Identifier,
    [Parameter(Mandatory)][string[]]$McVersions,
    [string]$Loader = 'fabric'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Modrinth.ps1')
. (Join-Path $PSScriptRoot 'lib\CurseForge.ps1')

$slug = Resolve-Slug $Identifier
$result = [ordered]@{
    ok          = $false
    slug        = $slug
    sources     = [ordered]@{
        modrinth   = [ordered]@{ found = $false }
        curseforge = [ordered]@{ found = $false }
    }
    per_version = [ordered]@{}
    warnings    = @()
    errors      = @()
}

try {
    $proj = Get-ModrinthProject -IdOrSlug $slug
    $p    = ConvertFrom-ModrinthProject -Raw $proj
}
catch {
    $msg = $_.Exception.Message
    if ($msg -match '404|Not Found') { $result.errors += "Mod '$slug' not found on Modrinth" }
    else                              { $result.errors += "Modrinth lookup failed: $msg" }
    $result | ConvertTo-Json -Depth 10
    exit 0
}

if (-not ($p.loaders_supported -contains $Loader)) {
    $result.errors += "Mod '$slug' does not support loader '$Loader' (supports: $($p.loaders_supported -join ', '))"
    $result | ConvertTo-Json -Depth 10
    exit 0
}

$result.name               = $p.name
$result.description        = $p.description
$result.side               = $p.side
$result.loaders_supported  = $p.loaders_supported
$result.suggested_category = $p.suggested_category
$result.sources.modrinth.project_id = $p.project_id
$result.sources.modrinth.found = $true

$cfAvailable = Test-CurseForgeAvailable
if ($cfAvailable) {
    try {
        $cfProj = Get-CurseForgeProject -Slug $slug
        if ($cfProj) {
            $result.sources.curseforge.project_id = $cfProj.id
            $result.sources.curseforge.found = $true
        } else {
            $result.warnings += "CurseForge: project not found for slug '$slug' (Modrinth-only)"
        }
    } catch {
        $result.warnings += "CurseForge lookup failed: $($_.Exception.Message)"
    }
} else {
    $result.warnings += "CURSEFORGE_API_KEY not set; skipping CurseForge enrichment"
}

foreach ($mc in $McVersions) {
    $perV = [ordered]@{ available = $false }

    try {
        $vers = Get-ModrinthVersions -ProjectId $p.project_id -Loader $Loader -McVersion $mc
        $sel  = Select-ModrinthVersion -Versions $vers
    } catch {
        $perV.reason = "Modrinth version lookup failed: $($_.Exception.Message)"
        $result.per_version[$mc] = [pscustomobject]$perV
        continue
    }

    if (-not $sel) {
        $perV.reason = "no release of any type for $mc with loader $Loader"
        $result.per_version[$mc] = [pscustomobject]$perV
        continue
    }

    $primary = $sel.files | Where-Object { $_.primary } | Select-Object -First 1
    if (-not $primary) { $primary = $sel.files | Select-Object -First 1 }

    $deps = @()
    foreach ($d in @($sel.dependencies)) {
        if ($d.dependency_type -eq 'required') {
            $deps += [pscustomobject]@{
                slug         = $d.project_id
                type         = 'required'
                modrinth_id  = $d.project_id
            }
        }
    }

    $perV.available = $true
    $perV.release_type = $sel.version_type
    $perV.release_type_fallback_used = [bool]$sel.fallback_used
    $perV.modrinth_version_id = $sel.id
    $perV.filename = $primary.filename
    $perV.dependencies = $deps

    if ($sel.fallback_used) {
        $result.warnings += "$mc`: no stable release, falling back to $($sel.version_type) $($sel.version_number)"
    }

    if ($result.sources.curseforge.found) {
        try {
            $cfFiles = Get-CurseForgeFiles -ProjectId $result.sources.curseforge.project_id -McVersion $mc
            $cfSel = Select-CurseForgeFile -Files $cfFiles
            if ($cfSel) { $perV.curseforge_file_id = $cfSel.id }
        } catch {
            $result.warnings += "$mc`: CurseForge file lookup failed: $($_.Exception.Message)"
        }
    }

    $result.per_version[$mc] = [pscustomobject]$perV
}

$result.ok = $true
$result | ConvertTo-Json -Depth 10
