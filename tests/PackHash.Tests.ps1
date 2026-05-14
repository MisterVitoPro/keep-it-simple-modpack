BeforeAll {
    . "$PSScriptRoot\..\scripts\lib\PackHash.ps1"
}

Describe "Get-PackContentHash" {
    BeforeEach {
        $script:tmp = Join-Path $TestDrive "pkg"
        New-Item -ItemType Directory -Force -Path "$script:tmp\mods" | Out-Null
        Set-Content -Path "$script:tmp\pack.toml"  -Value "name = 'p'" -Encoding utf8
        Set-Content -Path "$script:tmp\index.toml" -Value "files = []" -Encoding utf8
        Set-Content -Path "$script:tmp\mods\sodium.pw.toml"  -Value "name='Sodium'"  -Encoding utf8
        Set-Content -Path "$script:tmp\mods\lithium.pw.toml" -Value "name='Lithium'" -Encoding utf8
    }

    It "returns a 64-char lowercase hex hash" {
        $h = Get-PackContentHash -VersionDir $script:tmp
        $h | Should -Match '^[0-9a-f]{64}$'
    }
    It "is deterministic" {
        (Get-PackContentHash -VersionDir $script:tmp) | Should -Be (Get-PackContentHash -VersionDir $script:tmp)
    }
    It "is independent of file enumeration order" {
        $h1 = Get-PackContentHash -VersionDir $script:tmp
        Rename-Item "$script:tmp\mods\lithium.pw.toml" "z-lithium.pw.toml"
        Rename-Item "$script:tmp\mods\z-lithium.pw.toml" "lithium.pw.toml"
        (Get-PackContentHash -VersionDir $script:tmp) | Should -Be $h1
    }
    It "changes when a .pw.toml content changes" {
        $h1 = Get-PackContentHash -VersionDir $script:tmp
        Set-Content -Path "$script:tmp\mods\sodium.pw.toml" -Value "name='Sodium-X'" -Encoding utf8
        (Get-PackContentHash -VersionDir $script:tmp) | Should -Not -Be $h1
    }
    It "excludes the named mod" {
        $hAll       = Get-PackContentHash -VersionDir $script:tmp
        $hExcSodium = Get-PackContentHash -VersionDir $script:tmp -ExcludeMod sodium
        $hAll       | Should -Not -Be $hExcSodium
    }
    It "ExcludeMod hash matches the hash with that file actually removed" {
        $h1 = Get-PackContentHash -VersionDir $script:tmp -ExcludeMod sodium
        Remove-Item "$script:tmp\mods\sodium.pw.toml"
        (Get-PackContentHash -VersionDir $script:tmp) | Should -Be $h1
    }
}
