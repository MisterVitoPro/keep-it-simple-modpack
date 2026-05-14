#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [Parameter(Mandatory)][string]$Slug,
    [Parameter(Mandatory)][string[]]$Versions,
    [string]$SnapshotPath
)

$ErrorActionPreference = 'Stop'

function Remove-FromPackwizFolder($versionDir, $slug) {
    $modFile = Join-Path $versionDir "mods\$slug.pw.toml"
    if (Test-Path $modFile) {
        Remove-Item $modFile -Force
        Write-Host "removed: $modFile"
    }
}

function Restore-FromSnapshot($versionDir, $snapVersionDir, $slug) {
    $snapFile = Join-Path $snapVersionDir "mods\$slug.pw.toml"
    $destFile = Join-Path $versionDir "mods\$slug.pw.toml"
    $destDir  = Split-Path -Parent $destFile

    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }

    if (Test-Path $snapFile) {
        Copy-Item $snapFile $destFile -Force
        Write-Host "restored: $destFile"
    } else {
        Remove-FromPackwizFolder $versionDir $slug
    }
}

foreach ($v in $Versions) {
    $vDir = Join-Path $RepoRoot "Packwiz\$v"
    if (-not (Test-Path $vDir)) { Write-Warning "skip $v (no folder)"; continue }

    if ($SnapshotPath) {
        $sDir = Join-Path $SnapshotPath $v
        Restore-FromSnapshot $vDir $sDir $Slug
    } else {
        $pw = if ($env:PACKWIZ) { $env:PACKWIZ } else { "$env:USERPROFILE\go\bin\packwiz.exe" }
        if (-not (Test-Path $pw)) { throw "packwiz.exe not found at $pw" }
        Push-Location $vDir
        try { & $pw remove $Slug --yes | Out-Null }
        finally { Pop-Location }
        Write-Host "packwiz remove $Slug in $v"
    }
}

[pscustomobject]@{ ok = $true; versions = $Versions; slug = $Slug } | ConvertTo-Json
