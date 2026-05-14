# Load .env from repo root; profile-set vars take precedence
$_envFile = Join-Path $PSScriptRoot '..\..\\.env'
if (Test-Path $_envFile) {
    Get-Content $_envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and $line[0] -ne '#' -and $line -match '=') {
            $k, $v = $line -split '=', 2
            $k = $k.Trim()
            if ($k -and -not (Test-Path "Env:$k")) {
                Set-Item "Env:$k" $v.Trim()
            }
        }
    }
}
Remove-Variable _envFile

function Test-CurseForgeAvailable {
    [CmdletBinding()]
    param()
    try {
        $v = Get-Item -Path Env:CURSEFORGE_API_KEY -ErrorAction Stop
        return [bool]$v.Value
    } catch {
        return $false
    }
}

function Invoke-CurseForgeApi {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-CurseForgeAvailable)) {
        throw "CURSEFORGE_API_KEY not set - CurseForge enrichment unavailable"
    }
    $headers = @{
        'x-api-key' = $env:CURSEFORGE_API_KEY
        'Accept'    = 'application/json'
    }
    Invoke-RestMethod -Uri "https://api.curseforge.com/v1$Path" -Headers $headers -UseBasicParsing
}

function Get-CurseForgeProject {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Slug)
    $r = Invoke-CurseForgeApi "/mods/search?gameId=432&slug=$Slug"
    $r.data | Select-Object -First 1
}

function Get-CurseForgeFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][uint32]$ProjectId,
        [Parameter(Mandatory)][string]$McVersion,
        [int]$LoaderType = 4  # 4 = Fabric
    )
    $r = Invoke-CurseForgeApi "/mods/$ProjectId/files?gameVersion=$McVersion&modLoaderType=$LoaderType"
    @($r.data)
}

function Select-CurseForgeFile {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Files)
    if ($Files.Count -eq 0) { return $null }
    foreach ($rt in 1, 2, 3) {
        $candidates = $Files | Where-Object { $_.releaseType -eq $rt }
        if ($candidates) {
            $sel = $candidates | Sort-Object fileDate -Descending | Select-Object -First 1
            $sel | Add-Member -NotePropertyName fallback_used -NotePropertyValue ($rt -ne 1) -PassThru
            return
        }
    }
    $null
}
