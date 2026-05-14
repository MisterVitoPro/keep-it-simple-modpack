#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$JavaPath = "$env:USERPROFILE\.jdks\corretto-21.0.4\bin\javaw.exe",
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$packwizExe = "$env:USERPROFILE\go\bin\packwiz.exe"
$utf8NoBom  = New-Object System.Text.UTF8Encoding($false)

$versionMeta = [ordered]@{
    '1.20.1'  = @{ mc = '1.20.1';  fabric = '0.19.2'  }
    '1.21.1'  = @{ mc = '1.21.1';  fabric = '0.16.14' }
    '1.21.4'  = @{ mc = '1.21.4';  fabric = '0.16.14' }
    '26.1.2'  = @{ mc = '26.1.2';  fabric = '0.19.2'  }
    '1.21.11' = @{ mc = '1.21.11'; fabric = '0.19.2'  }
}

$prismInstallDir = Join-Path $RepoRoot '.test\tools\prism-install'
$prismExe        = Join-Path $prismInstallDir 'prismlauncher.exe'
$instancesRoot   = Join-Path $prismInstallDir 'instances'
$mrpacksDir      = Join-Path $RepoRoot '.test\mrpacks'

# ---------------------------------------------------------------------------
# Step 1 - Download and extract portable Prism
# ---------------------------------------------------------------------------
if (-not (Test-Path $prismExe) -or $Force) {
    Write-Host 'Fetching latest Prism Launcher release info...'
    $release = Invoke-RestMethod 'https://api.github.com/repos/PrismLauncher/PrismLauncher/releases/latest' -UseBasicParsing
    $asset   = $release.assets |
        Where-Object { $_.name -match 'Windows' -and $_.name -match 'Portable' -and $_.name -like '*.zip' -and $_.name -notmatch 'arm64' } |
        Sort-Object { if ($_.name -match 'MSVC') { 0 } else { 1 } } |
        Select-Object -First 1
    if (-not $asset) {
        throw "Could not find a Windows Portable zip in the latest Prism release. Assets: $($release.assets.name -join ', ')"
    }

    $zipPath = Join-Path $env:TEMP "prism-portable-$($release.tag_name).zip"
    Write-Host "  Downloading $($asset.name) ($([math]::Round($asset.size/1MB,1)) MB)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing

    Write-Host '  Extracting...'
    New-Item -ItemType Directory -Force -Path $prismInstallDir | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $prismInstallDir -Force
    Remove-Item $zipPath -ErrorAction SilentlyContinue

    # Some zips wrap everything in a sub-folder; flatten if needed
    if (-not (Test-Path $prismExe)) {
        $sub = Get-ChildItem $prismInstallDir -Directory | Select-Object -First 1
        if ($sub -and (Test-Path (Join-Path $sub.FullName 'prismlauncher.exe'))) {
            Get-ChildItem $sub.FullName | Move-Item -Destination $prismInstallDir -Force
            Remove-Item $sub.FullName -Recurse -Force
        }
    }
    if (-not (Test-Path $prismExe)) { throw "prismlauncher.exe not found after extraction in $prismInstallDir" }
    Write-Host "  Prism extracted to $prismInstallDir"
}

# portable.txt tells Prism to store all data next to the executable
$portableFile = Join-Path $prismInstallDir 'portable.txt'
if (-not (Test-Path $portableFile)) {
    [System.IO.File]::WriteAllBytes($portableFile, @())
    Write-Host 'Created portable.txt (portable mode enabled)'
}

# ---------------------------------------------------------------------------
# Step 2 - Create one instance per MC version
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $instancesRoot | Out-Null
New-Item -ItemType Directory -Force -Path $mrpacksDir    | Out-Null

foreach ($entry in $versionMeta.GetEnumerator()) {
    $v            = $entry.Key
    $meta         = $entry.Value
    $instanceName = "Keep-It-Simple-$v"
    $instanceDir  = Join-Path $instancesRoot $instanceName
    $minecraftDir = Join-Path $instanceDir '.minecraft'
    $modsDir      = Join-Path $minecraftDir 'mods'

    if ((Test-Path $instanceDir) -and -not $Force) {
        Write-Host "[$v] Instance already exists -- skip (use -Force to recreate)"
        continue
    }

    Write-Host "[$v] Building instance '$instanceName'..."

    # 2a. Export mrpack
    $mrpackPath = Join-Path $mrpacksDir "$instanceName.mrpack"
    Push-Location (Join-Path $RepoRoot "Packwiz\$v")
    try   { & $packwizExe modrinth export -o $mrpackPath }
    catch { throw "packwiz modrinth export failed for $v : $_" }
    finally { Pop-Location }

    # 2b. Read modrinth.index.json and download mods
    $tmpDir = Join-Path $env:TEMP "prism-setup-$v"
    if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($mrpackPath, $tmpDir)

    $indexJson = Get-Content (Join-Path $tmpDir 'modrinth.index.json') -Raw -Encoding utf8 | ConvertFrom-Json
    $modFiles  = $indexJson.files
    Write-Host "  Downloading $($modFiles.Count) mod files..."

    New-Item -ItemType Directory -Force -Path $modsDir | Out-Null

    foreach ($modFile in $modFiles) {
        $relativePath = $modFile.path -replace '/', '\'
        $destPath = Join-Path $minecraftDir $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destPath) | Out-Null
        $url      = $modFile.downloads | Select-Object -First 1
        $fileName = Split-Path -Leaf $destPath
        Write-Host "    $fileName"
        Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing
    }

    # Copy any bundled overrides (configs, etc.)
    $overridesDir = Join-Path $tmpDir 'overrides'
    if (Test-Path $overridesDir) {
        Copy-Item -Path (Join-Path $overridesDir '*') -Destination $minecraftDir -Recurse -Force
    }
    Remove-Item $tmpDir -Recurse -Force

    # 2c. Write instance.cfg
    $crlf     = "`r`n"
    $javaLine = if ($JavaPath -and (Test-Path $JavaPath)) {
        "OverrideJava=true${crlf}JavaPath=$($JavaPath -replace '\\','/')${crlf}MinMemAlloc=512${crlf}MaxMemAlloc=2048${crlf}"
    } else { '' }
    $instCfg  = "[General]${crlf}ConfigVersion=1.2${crlf}iconKey=default${crlf}name=${instanceName}${crlf}InstanceType=OneSix${crlf}IntendedVersion=$($meta.mc)${crlf}${javaLine}"
    [System.IO.File]::WriteAllText((Join-Path $instanceDir 'instance.cfg'), $instCfg, $utf8NoBom)

    # 2d. Write mmc-pack.json (build without here-strings to avoid PS 5.1 LF issues)
    $mcVer  = $meta.mc
    $fabVer = $meta.fabric
    $mmcLines = @(
        '{'
        '    "components": ['
        '        {'
        '            "cachedName": "Minecraft",'
        "            `"cachedVersion`": `"$mcVer`","
        '            "important": true,'
        '            "uid": "net.minecraft",'
        "            `"version`": `"$mcVer`""
        '        },'
        '        {'
        '            "cachedName": "Fabric Loader",'
        "            `"cachedVersion`": `"$fabVer`","
        '            "uid": "net.fabricmc.fabric-loader",'
        "            `"version`": `"$fabVer`""
        '        }'
        '    ],'
        '    "formatVersion": 1'
        '}'
    )
    $mmcJson = $mmcLines -join "`r`n"
    [System.IO.File]::WriteAllText((Join-Path $instanceDir 'mmc-pack.json'), $mmcJson, $utf8NoBom)

    Write-Host "  [$v] Done"
}

Write-Host ''
Write-Host 'Setup complete. Launch Prism from:'
Write-Host "  $prismExe"
