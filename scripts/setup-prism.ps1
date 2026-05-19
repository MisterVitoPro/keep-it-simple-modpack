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

# Locate the single Packwiz pack and read its MC + Fabric versions from pack.toml
$packDir = Get-ChildItem (Join-Path $RepoRoot 'Packwiz') -Directory | Select-Object -First 1
if (-not $packDir) { throw "No pack directory found under $RepoRoot\Packwiz" }

$packToml = Get-Content (Join-Path $packDir.FullName 'pack.toml') -Raw
if ($packToml -notmatch '(?m)^\s*minecraft\s*=\s*"([^"]+)"') { throw "Could not parse minecraft version from pack.toml" }
$mcVer  = $Matches[1]
if ($packToml -notmatch '(?m)^\s*fabric\s*=\s*"([^"]+)"')    { throw "Could not parse fabric loader version from pack.toml" }
$fabVer = $Matches[1]

$instanceName    = "Keep-It-Simple-$mcVer"
$prismInstallDir = Join-Path $RepoRoot '.test\tools\prism-install'
$prismExe        = Join-Path $prismInstallDir 'prismlauncher.exe'
$instanceDir     = Join-Path $prismInstallDir "instances\$instanceName"
$minecraftDir    = Join-Path $instanceDir '.minecraft'
$modsDir         = Join-Path $minecraftDir 'mods'
$mrpacksDir      = Join-Path $RepoRoot '.test\mrpacks'
$mrpackPath      = Join-Path $mrpacksDir "$instanceName.mrpack"

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
# Step 2 - Build the modpack instance
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $instanceDir) | Out-Null
New-Item -ItemType Directory -Force -Path $mrpacksDir                       | Out-Null

if ((Test-Path $instanceDir) -and -not $Force) {
    Write-Host "Instance '$instanceName' already exists -- skip (use -Force to recreate)"
} else {
    Write-Host "Building instance '$instanceName'..."

    # 2a. Export mrpack from packwiz
    Push-Location $packDir.FullName
    try   { & $packwizExe modrinth export -o $mrpackPath }
    catch { throw "packwiz modrinth export failed: $_" }
    finally { Pop-Location }

    # 2b. Read modrinth.index.json and download mods
    $tmpDir = Join-Path $env:TEMP "prism-setup-$mcVer"
    if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($mrpackPath, $tmpDir)

    $indexJson = Get-Content (Join-Path $tmpDir 'modrinth.index.json') -Raw -Encoding utf8 | ConvertFrom-Json
    $modFiles  = $indexJson.files
    Write-Host "  Downloading $($modFiles.Count) mod files..."

    New-Item -ItemType Directory -Force -Path $modsDir | Out-Null

    foreach ($modFile in $modFiles) {
        $relativePath = $modFile.path -replace '/', '\'
        $destPath     = Join-Path $minecraftDir $relativePath
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
    $instCfg  = "[General]${crlf}ConfigVersion=1.2${crlf}iconKey=default${crlf}name=${instanceName}${crlf}InstanceType=OneSix${crlf}IntendedVersion=${mcVer}${crlf}${javaLine}"
    [System.IO.File]::WriteAllText((Join-Path $instanceDir 'instance.cfg'), $instCfg, $utf8NoBom)

    # 2d. Write mmc-pack.json (build without here-strings to avoid PS 5.1 LF issues)
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

    Write-Host '  Done'
}

Write-Host ''
Write-Host 'Setup complete. Launch Prism from:'
Write-Host "  $prismExe"
