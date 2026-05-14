#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$File,
    [Parameter(Mandatory)][string]$Slug,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$AuthorUrl,
    [Parameter(Mandatory)][string]$AuthorName,
    [Parameter(Mandatory)][string]$Description,
    [Parameter(Mandatory)][ValidateSet('C','S','B')][string]$Side,
    [Parameter(Mandatory)][ValidateSet('Performance','Visual','Functional','Libraries')][string]$Category,
    [Parameter(Mandatory)][string[]]$McVersionsInTable,
    [Parameter(Mandatory)][string[]]$VersionsAvailable,
    [Parameter(Mandatory)][string[]]$VersionsAdded
)

$ErrorActionPreference = 'Stop'
$CategoryOrder = @('Performance','Visual','Functional','Libraries')

$lines = Get-Content $File -Encoding utf8

function Find-SectionRange([string[]]$ls, [string]$header) {
    $start = -1
    for ($i=0; $i -lt $ls.Count; $i++) {
        if ($ls[$i] -eq "## $header") { $start = $i; break }
    }
    if ($start -lt 0) { return @{ start = -1; end = -1 } }
    $end = $ls.Count
    for ($j = $start + 1; $j -lt $ls.Count; $j++) {
        if ($ls[$j] -match '^## ') { $end = $j; break }
    }
    @{ start = $start; end = $end }
}

function Build-Row {
    $modLink    = "[$Name](https://modrinth.com/mod/$Slug) ``$Side``"
    $authorLink = "[$AuthorName]($AuthorUrl)"
    $cells = @($modLink, $authorLink)
    foreach ($mc in $McVersionsInTable) {
        $cells += $(if ($VersionsAdded -contains $mc) { [char]0x2705 } else { '' })
    }
    $cells += $Description
    '| ' + ($cells -join ' | ') + ' |'
}

function Build-TableHeader {
    $cols  = @('Name','Author') + $McVersionsInTable + @('Description')
    $align = @('---','---') + ($McVersionsInTable | ForEach-Object { ':---:' }) + @('---')
    @(
        '| ' + ($cols  -join ' | ') + ' |'
        '| ' + ($align -join ' | ') + ' |'
    )
}

$range = Find-SectionRange $lines $Category
if ($range.start -lt 0) {
    $myIdx   = [array]::IndexOf($CategoryOrder, $Category)
    $insertAt = $lines.Count
    for ($k = $myIdx + 1; $k -lt $CategoryOrder.Count; $k++) {
        $other = Find-SectionRange $lines $CategoryOrder[$k]
        if ($other.start -ge 0 -and $other.start -lt $insertAt) { $insertAt = $other.start }
    }
    $newSection = @('', "## $Category", '') + (Build-TableHeader) + @('')
    $head = @(); $tail = @()
    if ($insertAt -gt 0) { $head = $lines[0..($insertAt-1)] }
    if ($insertAt -lt $lines.Count) { $tail = $lines[$insertAt..($lines.Count-1)] }
    $lines = $head + $newSection + $tail
    $range = Find-SectionRange $lines $Category
}

$existingRowIdx = -1
for ($i = $range.start; $i -lt $range.end; $i++) {
    if ($lines[$i] -match "^\| \[$([regex]::Escape($Name))\]\(") { $existingRowIdx = $i; break }
}

$newRow = Build-Row

if ($existingRowIdx -ge 0) {
    $lines[$existingRowIdx] = $newRow
} else {
    $dividerIdx = -1
    for ($i = $range.start; $i -lt $range.end; $i++) {
        if ($lines[$i] -match '^\| :?---') { $dividerIdx = $i; break }
    }
    if ($dividerIdx -lt 0) { throw "Section '$Category' has no table divider line." }

    $rowStart = $dividerIdx + 1
    $rowEnd   = $rowStart
    while ($rowEnd -lt $range.end -and $lines[$rowEnd] -match '^\|') { $rowEnd++ }

    $insertHere = $rowEnd
    for ($i = $rowStart; $i -lt $rowEnd; $i++) {
        if ($lines[$i] -match '^\| \[([^\]]+)\]') {
            if ([string]::Compare($Matches[1], $Name, $true) -gt 0) { $insertHere = $i; break }
        }
    }
    $head = $lines[0..($insertHere-1)]
    $tail = if ($insertHere -lt $lines.Count) { $lines[$insertHere..($lines.Count-1)] } else { @() }
    $lines = $head + @($newRow) + $tail
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($File, ($lines -join "`n") + "`n", $utf8NoBom)
