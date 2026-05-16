#requires -Version 5.1
<#
.SYNOPSIS
  Patches a Fabric mod jar by removing a specified entrypoint key from fabric.mod.json.

.DESCRIPTION
  Some mod releases incorrectly declare a fabric-gametest entrypoint pointing to a class
  that was excluded from the production jar. This causes servers to crash on startup with
  ClassNotFoundException. This script removes the broken entrypoint declaration in place.

.PARAMETER JarPath
  Path to the jar to patch (modified in place).

.PARAMETER EntrypointKey
  The entrypoint key to remove from fabric.mod.json (default: 'fabric-gametest').
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$JarPath,
    [string]$EntrypointKey = 'fabric-gametest'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$resolvedPath = (Resolve-Path $JarPath).Path
$tempExtract  = Join-Path $env:TEMP ("patch-jar-" + [guid]::NewGuid().Guid)
$tempNew      = Join-Path $env:TEMP ("patch-jar-new-" + [guid]::NewGuid().Guid + ".jar")

try {
    New-Item -ItemType Directory -Path $tempExtract | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($resolvedPath, $tempExtract)

    $fmjPath = Join-Path $tempExtract 'fabric.mod.json'
    if (-not (Test-Path $fmjPath)) { throw "No fabric.mod.json in $resolvedPath" }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $fmj = [System.IO.File]::ReadAllText($fmjPath, $utf8NoBom) | ConvertFrom-Json

    if (-not ($fmj.entrypoints -and $fmj.entrypoints.PSObject.Properties[$EntrypointKey])) {
        Write-Host "Entrypoint '$EntrypointKey' not found - no patch needed."
        exit 0
    }

    $fmj.entrypoints.PSObject.Properties.Remove($EntrypointKey)
    [System.IO.File]::WriteAllText($fmjPath, ($fmj | ConvertTo-Json -Depth 20), $utf8NoBom)

    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $tempExtract, $tempNew,
        [System.IO.Compression.CompressionLevel]::Optimal, $false)

    [System.IO.File]::Copy($tempNew, $resolvedPath, $true)

    Write-Host "Patched: removed '$EntrypointKey' from $(Split-Path -Leaf $resolvedPath)"
}
finally {
    if (Test-Path $tempExtract) { Remove-Item -Recurse -Force $tempExtract }
    if (Test-Path $tempNew)     { Remove-Item -Force $tempNew }
}
