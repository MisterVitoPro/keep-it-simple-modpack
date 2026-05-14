$script:UserAgent = "keep-it-simple/0.1 (https://github.com/MisterVitoPro)"

function Resolve-Slug {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Identifier)
    if ($Identifier -match 'modrinth\.com/(mod|datapack|resourcepack|shader)/([^/?#]+)') { return $Matches[2] }
    if ($Identifier -match 'curseforge\.com/minecraft/[^/]+/([^/?#]+)')                  { return $Matches[1] }
    $Identifier
}

function Invoke-ModrinthApi {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $url = "https://api.modrinth.com/v2$Path"
    Invoke-RestMethod -Uri $url -Headers @{ 'User-Agent' = $script:UserAgent } -UseBasicParsing
}

function Get-ModrinthProject {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$IdOrSlug)
    Invoke-ModrinthApi "/project/$IdOrSlug"
}

function Get-ModrinthVersions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [string]$Loader = 'fabric',
        [string]$McVersion
    )
    $loaderArg = '["' + $Loader + '"]'
    $path = "/project/$ProjectId/version?loaders=$loaderArg"
    if ($McVersion) {
        $path += '&game_versions=["' + $McVersion + '"]'
    }
    Invoke-ModrinthApi $path
}

function ConvertFrom-ModrinthProject {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Raw)

    $side =
        if      ($Raw.client_side -eq 'required' -and $Raw.server_side -eq 'unsupported') { 'client' }
        elseif  ($Raw.server_side -eq 'required' -and $Raw.client_side -eq 'unsupported') { 'server' }
        else                                                                              { 'both'   }

    $cats = @($Raw.categories)
    $suggested =
        if      ($cats -contains 'optimization')                                          { 'Performance' }
        elseif  ($cats -contains 'library')                                               { 'Libraries'   }
        elseif  ($cats | Where-Object { $_ -in 'decoration','models','shaders','fonts' }) { 'Visual'      }
        else                                                                              { 'Functional'  }

    [PSCustomObject]@{
        slug               = $Raw.slug
        project_id         = $Raw.id
        name               = $Raw.title
        description        = $Raw.description
        side               = $side
        loaders_supported  = @($Raw.loaders)
        suggested_category = $suggested
    }
}

function Select-ModrinthVersion {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Versions)
    if ($Versions.Count -eq 0) { return $null }
    foreach ($pref in 'release', 'beta', 'alpha') {
        $candidates = $Versions | Where-Object { $_.version_type -eq $pref }
        if ($candidates) {
            $sel = $candidates | Sort-Object date_published -Descending | Select-Object -First 1
            $sel | Add-Member -NotePropertyName fallback_used -NotePropertyValue ($pref -ne 'release') -PassThru
            return
        }
    }
    $null
}
