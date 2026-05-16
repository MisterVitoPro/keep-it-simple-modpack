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
        # Patch and bundle any mods that have broken fabric-gametest entrypoints.
        # Source: the test-server mods dir (populated + patched by update-baseline.ps1).
        $serverMods = Join-Path $RepoRoot ".test\$v-server\mods"
        $patchScript = Join-Path $PSScriptRoot 'patch-jar-remove-gametest.ps1'
        @('inventorysorter') | ForEach-Object {
            $jar = Get-ChildItem $serverMods -Filter "$_*.jar" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($jar) {
                $tmp = Join-Path $env:TEMP ($jar.Name)
                Copy-Item $jar.FullName $tmp -Force
                & $patchScript -JarPath $tmp | Out-Null
                $mrModsDir = Join-Path $mrDir 'overrides\mods'
                New-Item -ItemType Directory -Force -Path $mrModsDir | Out-Null
                Copy-Item $tmp $mrModsDir -Force
                Remove-Item $tmp -Force
            }
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
        # Same patched-jar injection for CurseForge export
        @('inventorysorter') | ForEach-Object {
            $jar = Get-ChildItem $serverMods -Filter "$_*.jar" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($jar) {
                $tmp = Join-Path $env:TEMP ($jar.Name)
                Copy-Item $jar.FullName $tmp -Force
                & $patchScript -JarPath $tmp | Out-Null
                $cfModsDir = Join-Path $cfDir 'overrides\mods'
                New-Item -ItemType Directory -Force -Path $cfModsDir | Out-Null
                Copy-Item $tmp $cfModsDir -Force
                Remove-Item $tmp -Force
            }
        }
        Write-Host "  -> $cfDir"
    } else {
        Write-Warning "  CurseForge export produced no output for $v"
    }
}
