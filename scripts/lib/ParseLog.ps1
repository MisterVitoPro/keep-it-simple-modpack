. "$PSScriptRoot\Normalize.ps1"

# Warnings that are always safe to ignore and should never trigger test failures.
# These are dev-environment artifacts or explicitly marked ignorable by Fabric/mods themselves.
$script:WarnIgnorePatterns = @(
    # Fabric mixin refmap not found - only relevant in dev; Fabric says so explicitly
    'could not be read\. If this is a development environment you can ignore this message',
    # FerriteCore / Krypton intentionally force-disable certain mixins via their own rules
    'Force-disabling mixin .+ as rule .+ disables it',
    # Distant Horizons GC advisory - not a problem indicator
    'Distant Horizons: G1 Garbage collector detected',
    # Generic "Warnings were found!" header emitted before the actual warning list
    '^Warnings were found!$'
)

function Test-WarnIgnored {
    param([string]$Line)
    foreach ($p in $script:WarnIgnorePatterns) {
        if ($Line -match $p) { return $true }
    }
    return $false
}

function Get-LogIssues {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$LogPath)

    if (-not (Test-Path $LogPath)) {
        throw "Log file not found: $LogPath"
    }

    $errors     = New-Object System.Collections.Generic.List[string]
    $warns      = New-Object System.Collections.Generic.List[string]
    $exceptions = New-Object System.Collections.Generic.List[string]

    Get-Content $LogPath | ForEach-Object {
        $line = $_
        if ($line -match '\[[\w\s\-#]+/ERROR\]:') {
            $errors.Add((ConvertTo-NormalizedLogLine $line))
        }
        elseif ($line -match '\[[\w\s\-#]+/WARN\]:') {
            $normalized = ConvertTo-NormalizedLogLine $line
            if (-not (Test-WarnIgnored $normalized)) {
                $warns.Add($normalized)
            }
        }
        elseif ($line -match '^[\w\.]+(Exception|Error):') {
            $exceptions.Add((ConvertTo-NormalizedLogLine $line))
        }
    }

    [PSCustomObject]@{
        errors     = $errors.ToArray()
        warns      = $warns.ToArray()
        exceptions = $exceptions.ToArray()
    }
}
