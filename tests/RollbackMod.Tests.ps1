BeforeAll {
    $script:script = "$PSScriptRoot\..\scripts\rollback-mod.ps1"
}

Describe "rollback-mod.ps1 (snapshot mode)" {

    BeforeEach {
        $id = [guid]::NewGuid().Guid.Substring(0,8)
        $script:repo = Join-Path $TestDrive "repo-$id"
        $script:snap = Join-Path $TestDrive "snap-$id"
        New-Item -ItemType Directory -Force -Path "$script:repo\Packwiz\1.20.1\mods" | Out-Null
        New-Item -ItemType Directory -Force -Path "$script:repo\Packwiz\1.21.1\mods" | Out-Null
        Set-Content "$script:repo\Packwiz\1.20.1\mods\sodium.pw.toml"  -Value "post-add v1.20.1" -Encoding utf8
        Set-Content "$script:repo\Packwiz\1.21.1\mods\sodium.pw.toml"  -Value "post-add v1.21.1" -Encoding utf8

        New-Item -ItemType Directory -Force -Path "$script:snap\1.20.1\mods" | Out-Null
        New-Item -ItemType Directory -Force -Path "$script:snap\1.21.1\mods" | Out-Null
        # Snapshot has NO sodium.pw.toml (representing pre-add state)
    }

    It "removes a mod that wasn't in the snapshot" {
        & $script:script -RepoRoot $script:repo -Slug 'sodium' -Versions @('1.20.1','1.21.1') -SnapshotPath $script:snap
        Test-Path "$script:repo\Packwiz\1.20.1\mods\sodium.pw.toml" | Should -BeFalse
        Test-Path "$script:repo\Packwiz\1.21.1\mods\sodium.pw.toml" | Should -BeFalse
    }

    It "restores a mod that WAS in the snapshot" {
        Set-Content "$script:snap\1.20.1\mods\sodium.pw.toml" -Value 'pre-add state' -Encoding utf8
        & $script:script -RepoRoot $script:repo -Slug 'sodium' -Versions @('1.20.1') -SnapshotPath $script:snap
        Get-Content "$script:repo\Packwiz\1.20.1\mods\sodium.pw.toml" -Raw | Should -Match 'pre-add state'
    }

    It "only affects listed versions" {
        & $script:script -RepoRoot $script:repo -Slug 'sodium' -Versions @('1.20.1') -SnapshotPath $script:snap
        Test-Path "$script:repo\Packwiz\1.20.1\mods\sodium.pw.toml" | Should -BeFalse
        Test-Path "$script:repo\Packwiz\1.21.1\mods\sodium.pw.toml" | Should -BeTrue
    }
}
