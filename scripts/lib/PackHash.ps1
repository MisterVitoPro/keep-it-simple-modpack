function Get-PackContentHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$VersionDir,
        [string]$ExcludeMod
    )

    if (-not (Test-Path $VersionDir)) { throw "VersionDir not found: $VersionDir" }

    $paths = @()
    foreach ($f in 'pack.toml', 'index.toml') {
        $p = Join-Path $VersionDir $f
        if (Test-Path $p) { $paths += (Resolve-Path $p).Path }
    }
    $modsDir = Join-Path $VersionDir 'mods'
    if (Test-Path $modsDir) {
        $modFiles = Get-ChildItem $modsDir -Filter '*.pw.toml' -File
        if ($ExcludeMod) {
            $modFiles = $modFiles | Where-Object { $_.Name -ne "$ExcludeMod.pw.toml" }
        }
        $paths += ($modFiles | Sort-Object Name | ForEach-Object { $_.FullName })
    }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $ms = New-Object System.IO.MemoryStream
        foreach ($p in $paths) {
            $rel = (Split-Path -Leaf $p)
            $relBytes = [System.Text.Encoding]::UTF8.GetBytes("$rel`n")
            $ms.Write($relBytes, 0, $relBytes.Length)
            $bytes = [System.IO.File]::ReadAllBytes($p)
            $ms.Write($bytes, 0, $bytes.Length)
            $sep = [System.Text.Encoding]::UTF8.GetBytes("`n--`n")
            $ms.Write($sep, 0, $sep.Length)
        }
        $ms.Position = 0
        $hashBytes = $sha.ComputeHash($ms)
        ($hashBytes | ForEach-Object { $_.ToString('x2') }) -join ''
    }
    finally { $sha.Dispose() }
}
