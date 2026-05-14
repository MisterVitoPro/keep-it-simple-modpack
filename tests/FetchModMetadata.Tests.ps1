BeforeAll {
    $script:script = "$PSScriptRoot\..\scripts\fetch-mod-metadata.ps1"
}

Describe "fetch-mod-metadata.ps1" -Tag 'Integration' {

    It "returns ok=true and project metadata for sodium on 1.20.1" {
        $json = & $script:script -Identifier 'sodium' -McVersions @('1.20.1') | Out-String | ConvertFrom-Json
        $json.ok                                    | Should -BeTrue
        $json.slug                                  | Should -Be 'sodium'
        $json.name                                  | Should -Be 'Sodium'
        $json.side                                  | Should -Be 'client'
        $json.suggested_category                    | Should -Be 'Performance'
        $json.sources.modrinth.found                | Should -BeTrue
        $json.per_version.'1.20.1'.available        | Should -BeTrue
        $json.per_version.'1.20.1'.release_type     | Should -Be 'release'
        $json.per_version.'1.20.1'.filename         | Should -Match 'sodium-fabric-0\.5\.13\+mc1\.20\.1\.jar'
    }

    It "marks per_version.available=false for an MC version with no compatible release" {
        $json = & $script:script -Identifier 'sodium' -McVersions @('1.5.2') | Out-String | ConvertFrom-Json
        $json.ok                          | Should -BeTrue
        $json.per_version.'1.5.2'.available | Should -BeFalse
        $json.per_version.'1.5.2'.reason    | Should -Match 'no release'
    }

    It "returns ok=false for a slug that does not exist" {
        $json = & $script:script -Identifier 'this-slug-does-not-exist-xyz-12345' -McVersions @('1.20.1') | Out-String | ConvertFrom-Json
        $json.ok | Should -BeFalse
        ($json.errors -join ' ') | Should -Match 'not found|404'
    }
}

Describe "fetch-mod-metadata.ps1 (offline)" {
    BeforeAll {
        . "$PSScriptRoot\..\scripts\lib\Modrinth.ps1"
    }

    It "Resolve-Slug: extracts slug from full Modrinth URL without any network call" {
        Resolve-Slug 'https://modrinth.com/mod/sodium' | Should -Be 'sodium'
    }

    It "Resolve-Slug: passes through plain slug unchanged" {
        Resolve-Slug 'lithium' | Should -Be 'lithium'
    }
}
