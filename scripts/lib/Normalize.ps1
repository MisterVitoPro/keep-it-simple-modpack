$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function ConvertTo-NormalizedLogLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Line
    )
    process {
        $n = $Line
        $n = $n -replace '^\[\d{2}:\d{2}:\d{2}\]\s*', ''
        $n = $n -replace '^\[[\w\s\-#]+/[A-Z]+\]:\s*', ''
        $n = $n -replace '(\w+\.java):\d+', '$1'

        $bsEscaped = [regex]::Escape($script:RepoRoot)
        $n = $n -replace ($bsEscaped + '\\?'), '<repo>\'

        $forwardForm = $script:RepoRoot -replace '\\', '/'
        $fwEscaped = [regex]::Escape($forwardForm)
        $n = $n -replace ('file:/' + $fwEscaped + '/?'), '<repo>/'
        $n = $n -replace ($fwEscaped + '/?'), '<repo>/'

        $n = $n -replace '\s+', ' '
        $n.Trim()
    }
}
