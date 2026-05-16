#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Version,
    [ValidateSet('server','client-resolve','both')][string]$Mode = 'both',
    [string]$ExcludeMod,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\ParseLog.ps1')
. (Join-Path $PSScriptRoot 'lib\PackHash.ps1')

$packDir = Join-Path $RepoRoot "Packwiz\$Version"
if (-not (Test-Path $packDir)) { throw "No Packwiz/$Version folder" }

$baselineDir  = Join-Path $RepoRoot ".test\baselines"
$baselineFile = Join-Path $baselineDir "$Version.json"
New-Item -ItemType Directory -Force -Path $baselineDir | Out-Null

$hash = Get-PackContentHash -VersionDir $packDir -ExcludeMod $ExcludeMod

$loaderCheck = Join-Path $RepoRoot ".test\cf-loader-check\LoaderCheck.jar"
$loaderSrc   = Join-Path $RepoRoot 'scripts\LoaderCheck.java'
if (-not (Test-Path $loaderCheck) -or (Get-Item $loaderSrc).LastWriteTime -gt (Get-Item $loaderCheck).LastWriteTime) {
    $javaHome = if ($env:JAVA_HOME) { $env:JAVA_HOME } else { Split-Path (Get-Command javac -ErrorAction Stop).Source }
    $javac = Join-Path $javaHome 'bin\javac.exe'
    $jar   = Join-Path $javaHome 'bin\jar.exe'
    New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot '.test\cf-loader-check\classes') | Out-Null
    & $javac --release 17 -d (Join-Path $RepoRoot '.test\cf-loader-check\classes') $loaderSrc
    & $jar --create --file $loaderCheck --main-class LoaderCheck -C (Join-Path $RepoRoot '.test\cf-loader-check\classes') .
}

$bl = [ordered]@{
    version           = $Version
    captured_at       = (Get-Date).ToUniversalTime().ToString("o")
    pack_content_hash = $hash
    excluded_mod      = $ExcludeMod
}

if ($Mode -in 'server','both') {
    $serverDir = Join-Path $RepoRoot ".test\$Version-server"
    $logPath   = Join-Path $serverDir 'boot.log'

    $bootstrap = Join-Path $RepoRoot ".test\tools\packwiz-installer-bootstrap.jar"
    if (-not (Test-Path $bootstrap)) { throw "Bootstrap jar missing: $bootstrap" }

    if (Test-Path "$serverDir\mods") { Remove-Item "$serverDir\mods\*.jar" -Force -ErrorAction SilentlyContinue }
    $packUrl = "file:///" + ($packDir.Replace('\','/')) + "/pack.toml"
    Push-Location $serverDir
    try {
        & java -jar $bootstrap -g -s server $packUrl | Out-Null
    } finally { Pop-Location }

    # Patch jars with broken fabric-gametest entrypoints (class declared but missing from release jar)
    $patchScript = Join-Path $PSScriptRoot 'patch-jar-remove-gametest.ps1'
    Get-ChildItem "$serverDir\mods" -Filter 'inventorysorter*.jar' -ErrorAction SilentlyContinue | ForEach-Object {
        & $patchScript -JarPath $_.FullName | Out-Null
    }

    $java = if ($Version -eq '26.1.2') {
        Join-Path $RepoRoot ".test\tools\jdk25\jdk25.0.3_9\bin\java.exe"
    } else { 'java' }

    $lcOut    = & $java -jar $loaderCheck (Join-Path $serverDir 'mods') | Out-String
    $lcResult = $lcOut | ConvertFrom-Json

    $bl.server = [ordered]@{
        loader_check = $lcResult
        ok           = $false
        errors       = @()
        warns        = @()
        exceptions   = @()
    }

    if ($lcResult.ok) {
        Set-Content -Path (Join-Path $serverDir 'eula.txt') -Value 'eula=true' -Encoding ascii

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $java
        $psi.Arguments = '-Xmx2G -jar fabric-server-launch.jar --nogui'
        $psi.WorkingDirectory = $serverDir
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.RedirectStandardInput = $true
        $psi.UseShellExecute = $false

        $proc = [System.Diagnostics.Process]::Start($psi)
        Set-Content -Path $logPath -Value '' -Encoding utf8
        $done = $false
        $deadline = (Get-Date).AddSeconds(180)
        while (-not $proc.HasExited -and (Get-Date) -lt $deadline) {
            while (-not $proc.StandardOutput.EndOfStream) {
                $line = $proc.StandardOutput.ReadLine()
                if ($null -eq $line) { break }
                Add-Content -Path $logPath -Value $line
                if ($line -match 'Done \(.*\)! For help') { $done = $true; break }
            }
            if ($done) { break }
            Start-Sleep -Milliseconds 250
        }
        if (-not $proc.HasExited) {
            try { $proc.StandardInput.WriteLine('stop'); $proc.StandardInput.Flush() } catch {}
            $proc.WaitForExit(30000) | Out-Null
        }
        if (-not $proc.HasExited) { $proc.Kill() | Out-Null }
        while (-not $proc.StandardOutput.EndOfStream) {
            $line = $proc.StandardOutput.ReadLine()
            if ($line) { Add-Content -Path $logPath -Value $line }
        }

        $issues = Get-LogIssues -LogPath $logPath
        $bl.server.ok         = $done
        $bl.server.errors     = $issues.errors
        $bl.server.warns      = $issues.warns
        $bl.server.exceptions = $issues.exceptions
    }
}

if ($Mode -in 'client-resolve','both') {
    $clientDir = Join-Path $RepoRoot ".test\$Version-client"
    $bootstrap = Join-Path $RepoRoot ".test\tools\packwiz-installer-bootstrap.jar"
    New-Item -ItemType Directory -Force -Path $clientDir | Out-Null
    if (Test-Path "$clientDir\mods") { Remove-Item "$clientDir\mods\*.jar" -Force -ErrorAction SilentlyContinue }
    $packUrl = "file:///" + ($packDir.Replace('\','/')) + "/pack.toml"
    Push-Location $clientDir
    try { & java -jar $bootstrap -g -s client $packUrl | Out-Null }
    finally { Pop-Location }

    $java = if ($Version -eq '26.1.2') {
        Join-Path $RepoRoot ".test\tools\jdk25\jdk25.0.3_9\bin\java.exe"
    } else { 'java' }

    $modsArg = Join-Path $clientDir 'mods'
    $out = & $java -jar $loaderCheck $modsArg | Out-String
    $bl.client_resolve = ($out | ConvertFrom-Json)
}

$json = ($bl | ConvertTo-Json -Depth 10)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($baselineFile, $json + "`n", $utf8NoBom)

[pscustomobject]@{ ok = $true; baseline = $baselineFile; pack_content_hash = $hash } | ConvertTo-Json
