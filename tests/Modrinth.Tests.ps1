BeforeAll {
    . "$PSScriptRoot\..\scripts\lib\Modrinth.ps1"
    $script:projFixture = Get-Content (Join-Path $PSScriptRoot 'fixtures\modrinth-sodium-project.json') -Raw | ConvertFrom-Json
    $script:versFixture = Get-Content (Join-Path $PSScriptRoot 'fixtures\modrinth-sodium-versions.json') -Raw | ConvertFrom-Json
}

Describe "Resolve-Slug" {
    It "extracts slug from modrinth.com mod URL" {
        Resolve-Slug 'https://modrinth.com/mod/sodium' | Should -Be 'sodium'
    }
    It "extracts slug from modrinth.com datapack URL" {
        Resolve-Slug 'https://modrinth.com/datapack/my-pack' | Should -Be 'my-pack'
    }
    It "passes through plain slugs unchanged" {
        Resolve-Slug 'sodium' | Should -Be 'sodium'
    }
    It "extracts slug from CurseForge URL" {
        Resolve-Slug 'https://www.curseforge.com/minecraft/mc-mods/sodium' | Should -Be 'sodium'
    }
}

Describe "ConvertFrom-ModrinthProject" {
    BeforeAll { $script:p = ConvertFrom-ModrinthProject -Raw $script:projFixture }

    It "exposes the slug" { $script:p.slug | Should -Be 'sodium' }
    It "exposes the project_id"  { $script:p.project_id | Should -Be 'AANobbMI' }
    It "exposes the side" { $script:p.side | Should -Be 'client' }
    It "supports fabric" { $script:p.loaders_supported -contains 'fabric' | Should -BeTrue }
    It "suggests Performance" { $script:p.suggested_category | Should -Be 'Performance' }
}

Describe "Select-ModrinthVersion" {
    It "prefers release over beta over alpha" {
        $mix = @(
            [pscustomobject]@{ version_type='alpha'; date_published='2025-01-01'; id='a'; files=@() }
            [pscustomobject]@{ version_type='beta';  date_published='2025-02-01'; id='b'; files=@() }
            [pscustomobject]@{ version_type='release'; date_published='2025-01-15'; id='r'; files=@() }
        )
        $sel = Select-ModrinthVersion -Versions $mix
        $sel.id | Should -Be 'r'
        $sel.fallback_used | Should -BeFalse
    }
    It "falls back to beta if no release" {
        $mix = @(
            [pscustomobject]@{ version_type='beta';  date_published='2025-02-01'; id='b'; files=@() }
            [pscustomobject]@{ version_type='alpha'; date_published='2025-03-01'; id='a'; files=@() }
        )
        $sel = Select-ModrinthVersion -Versions $mix
        $sel.id | Should -Be 'b'
        $sel.fallback_used | Should -BeTrue
    }
    It "returns null when no versions exist" {
        Select-ModrinthVersion -Versions @() | Should -BeNullOrEmpty
    }
    It "real fixture: picks a release build for 1.20.1" {
        $sel = Select-ModrinthVersion -Versions $script:versFixture
        $sel.version_type   | Should -Be 'release'
        $sel.fallback_used  | Should -BeFalse
    }
}
