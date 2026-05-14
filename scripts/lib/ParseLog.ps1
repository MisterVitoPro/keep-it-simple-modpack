. "$PSScriptRoot\Normalize.ps1"

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
            $warns.Add((ConvertTo-NormalizedLogLine $line))
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
