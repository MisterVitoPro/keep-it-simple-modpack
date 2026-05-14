#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Version,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [int]$TimeoutSec = 600
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\ParseLog.ps1')

$instanceName = "Keep-It-Simple-$Version"
$prismDir     = Join-Path $RepoRoot ".test\tools\prism-install"
$prismExe     = Join-Path $prismDir "prismlauncher.exe"
$instanceDir  = Join-Path $prismDir "instances\$instanceName"
$logPath      = Join-Path $instanceDir ".minecraft\logs\latest.log"

if (-not (Test-Path $prismExe))    { throw "Prism launcher not found: $prismExe" }
if (-not (Test-Path $instanceDir)) { throw "Prism instance not found: $instanceDir" }

$logsDir = Split-Path -Parent $logPath
if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
if (Test-Path $logPath) { Clear-Content $logPath }

$result = [ordered]@{
    ok                   = $false
    version              = $Version
    reached_title_screen = $false
    crashed              = $false
    timed_out            = $false
    errors               = @()
    warns                = @()
    exceptions           = @()
    log_path             = $logPath
}

# Snapshot java/javaw PIDs before we launch so we can kill exactly our game process later
$javaBefore = Get-Process -Name 'java','javaw' -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Id

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName         = $prismExe
$psi.Arguments        = "--launch `"$instanceName`""
$psi.WorkingDirectory = $prismDir
$psi.UseShellExecute  = $true   # must be true for a GUI app

Write-Host "Launching $instanceName (timeout ${TimeoutSec}s)..."

$proc     = [System.Diagnostics.Process]::Start($psi)
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$reached  = $false
$crashed  = $false

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 500

    if (Test-Path $logPath) {
        $content = Get-Content $logPath -Raw -ErrorAction SilentlyContinue
        if ($content -match 'Sound engine started') {
            $reached = $true
            break
        }
        if ($content -match 'FATAL|Game crashed') {
            $crashed = $true
            break
        }
    }
}

# Kill the game (new java/javaw processes) then Prism
$javaNew = Get-Process -Name 'java','javaw' -ErrorAction SilentlyContinue |
    Where-Object { $_.Id -notin $javaBefore }
if ($javaNew) {
    $javaNew | Stop-Process -Force -ErrorAction SilentlyContinue
    $javaNew | ForEach-Object { $_.WaitForExit(5000) | Out-Null }
}
if (-not $proc.HasExited) {
    try { $proc.Kill() } catch {}
    $proc.WaitForExit(5000) | Out-Null
}

if (Test-Path $logPath) {
    $issues             = Get-LogIssues -LogPath $logPath
    $result.errors      = $issues.errors
    $result.warns       = $issues.warns
    $result.exceptions  = $issues.exceptions
}

if (-not $reached -and -not $crashed) { $crashed = $true }   # Prism exited without the game starting

$result.reached_title_screen = $reached
$result.crashed  = $crashed
$result.timed_out = (-not $reached -and -not $crashed)
$result.ok        = $reached

$result | ConvertTo-Json -Depth 5

if (-not $result.ok) { exit 2 }
exit 0
