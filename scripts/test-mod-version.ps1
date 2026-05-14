#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Version,
    [Parameter(Mandatory)][ValidateSet('server','client-resolve')][string]$Mode,
    [string]$BaselinePath,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [int]$TimeoutSec = 180
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\ParseLog.ps1')
. (Join-Path $PSScriptRoot 'lib\PackHash.ps1')

if (-not $BaselinePath) { $BaselinePath = Join-Path $RepoRoot ".test\baselines\$Version.json" }
$packDir = Join-Path $RepoRoot "Packwiz\$Version"

if (-not (Test-Path $BaselinePath)) {
    & (Join-Path $PSScriptRoot 'update-baseline.ps1') -Version $Version -Mode $Mode | Out-Null
}

$baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json

$origBaseline = Get-Content $BaselinePath -Raw
try {
    & (Join-Path $PSScriptRoot 'update-baseline.ps1') -Version $Version -Mode $Mode | Out-Null
    $post = Get-Content $BaselinePath -Raw | ConvertFrom-Json
}
finally {
    Set-Content -Path $BaselinePath -Value $origBaseline -NoNewline -Encoding utf8
}

function Diff-LinesPreservingOrder($baseList, $postList) {
    if (-not $baseList) { return @($postList) }
    $bset = @{}
    foreach ($l in $baseList) { $bset[$l] = $true }
    @($postList | Where-Object { -not $bset.ContainsKey($_) })
}

$result = [ordered]@{
    ok             = $true
    version        = $Version
    mode           = $Mode
    baseline_match = if ($post.pack_content_hash -eq $baseline.pack_content_hash) { 'exact' } else { 'reused-after-hash-mismatch' }
    log_path       = (Join-Path $RepoRoot ".test\$Version-server\boot.log")
}

if ($Mode -eq 'server') {
    $b = $baseline.server
    $p = $post.server
    $result.new_errors     = Diff-LinesPreservingOrder $b.errors     $p.errors
    $result.new_warns      = Diff-LinesPreservingOrder $b.warns      $p.warns
    $result.new_exceptions = Diff-LinesPreservingOrder $b.exceptions $p.exceptions
    $result.boot_ok        = [bool]$p.ok
    $bLcCodes = @{}
    if ($b.loader_check -and $b.loader_check.issues) {
        foreach ($i in $b.loader_check.issues) { $bLcCodes["$($i.mod_id)|$($i.code)|$($i.detail)"] = $true }
    }
    $result.new_loader_issues = @()
    if ($p.loader_check -and $p.loader_check.issues) {
        foreach ($i in $p.loader_check.issues) {
            $k = "$($i.mod_id)|$($i.code)|$($i.detail)"
            if (-not $bLcCodes.ContainsKey($k)) { $result.new_loader_issues += $i }
        }
    }
}
else {
    $b = $baseline.client_resolve
    $p = $post.client_resolve
    $baseCodes = @{}
    if ($b -and $b.issues) { foreach ($i in $b.issues) { $baseCodes["$($i.mod_id)|$($i.code)|$($i.detail)"] = $true } }
    $result.new_issues = @()
    if ($p -and $p.issues) {
        foreach ($i in $p.issues) {
            $k = "$($i.mod_id)|$($i.code)|$($i.detail)"
            if (-not $baseCodes.ContainsKey($k)) { $result.new_issues += $i }
        }
    }
    $result.boot_ok = [bool]$p.ok
}

$hasNew =
    ($result.new_errors        -and $result.new_errors.Count -gt 0) -or
    ($result.new_warns         -and $result.new_warns.Count -gt 0) -or
    ($result.new_exceptions    -and $result.new_exceptions.Count -gt 0) -or
    ($result.new_issues        -and $result.new_issues.Count -gt 0) -or
    ($result.new_loader_issues -and $result.new_loader_issues.Count -gt 0)

if ($hasNew) { $result.ok = $false }

$result | ConvertTo-Json -Depth 10

if (-not $result.ok) { exit 2 }
exit 0
