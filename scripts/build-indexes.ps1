#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Versions,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
$packwiz = if ($env:PACKWIZ) { $env:PACKWIZ } else { "$env:USERPROFILE\go\bin\packwiz.exe" }
if (-not (Test-Path $packwiz)) { throw "packwiz.exe not found at $packwiz" }

Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($v in $Versions) {
    Write-Host "=== $v ==="
    $packDir = Join-Path $RepoRoot "Packwiz\$v"
    if (-not (Test-Path $packDir)) { Write-Warning "No Packwiz/$v folder, skipping"; continue }

    $mrDir = Join-Path $RepoRoot "Modrinth\$v"
    $cfDir = Join-Path $RepoRoot "CurseForge\$v"

    # Modrinth mrpack
    $tmpMr = Join-Path $env:TEMP "kis-mr-$v-$([guid]::NewGuid().Guid.Substring(0,8)).mrpack"
    Push-Location $packDir
    try {
        & $packwiz modrinth export -o $tmpMr --yes 2>&1 | Out-Null
    } finally { Pop-Location }

    if (Test-Path $tmpMr) {
        if (Test-Path $mrDir) { Get-ChildItem $mrDir -Recurse | Remove-Item -Force -Recurse }
        New-Item -ItemType Directory -Force -Path $mrDir | Out-Null
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpMr, $mrDir)
        Remove-Item $tmpMr -Force
        # Copy pack-level overrides (e.g. patched jars) that packwiz export doesn't auto-include
        $packOverrides = Join-Path $packDir 'overrides'
        if (Test-Path $packOverrides) {
            $mrOverridesDir = Join-Path $mrDir 'overrides'
            New-Item -ItemType Directory -Force -Path $mrOverridesDir | Out-Null
            Copy-Item -Path "$packOverrides\*" -Destination $mrOverridesDir -Recurse -Force
        }
        Write-Host "  -> $mrDir"
    } else {
        Write-Warning "  Modrinth export produced no output for $v"
    }

    # CurseForge zip
    $tmpCf = Join-Path $env:TEMP "kis-cf-$v-$([guid]::NewGuid().Guid.Substring(0,8)).zip"
    Push-Location $packDir
    try {
        & $packwiz curseforge export -o $tmpCf --yes 2>&1 | Out-Null
    } finally { Pop-Location }

    if (Test-Path $tmpCf) {
        if (Test-Path $cfDir) { Get-ChildItem $cfDir -Recurse | Remove-Item -Force -Recurse }
        New-Item -ItemType Directory -Force -Path $cfDir | Out-Null
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpCf, $cfDir)
        Remove-Item $tmpCf -Force
        # Copy pack-level overrides (e.g. patched jars) that packwiz export doesn't auto-include
        if (Test-Path $packOverrides) {
            $cfOverridesDir = Join-Path $cfDir 'overrides'
            New-Item -ItemType Directory -Force -Path $cfOverridesDir | Out-Null
            Copy-Item -Path "$packOverrides\*" -Destination $cfOverridesDir -Recurse -Force
        }
        Write-Host "  -> $cfDir"
    } else {
        Write-Warning "  CurseForge export produced no output for $v"
    }
}
