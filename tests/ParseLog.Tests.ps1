BeforeAll {
    . "$PSScriptRoot\..\scripts\lib\ParseLog.ps1"
    $script:cleanLog = Join-Path $PSScriptRoot 'fixtures\boot-log-clean.txt'
    $script:dirtyLog = Join-Path $PSScriptRoot 'fixtures\boot-log-with-mod-error.txt'
}

Describe "Get-LogIssues" {
    Context "clean log (only the harmless server.properties error)" {
        BeforeAll { $script:res = Get-LogIssues -LogPath $script:cleanLog }

        It "returns one error line" {
            $script:res.errors.Count | Should -Be 1
        }
        It "captures the normalised server.properties error" {
            $script:res.errors[0] | Should -Be "Failed to load properties from file: server.properties"
        }
        It "captures the exception" {
            $script:res.exceptions[0] | Should -Match "NoSuchFileException: server.properties"
        }
        It "has no WARNs" {
            $script:res.warns.Count | Should -Be 0
        }
    }
    Context "dirty log (mod failure + warning)" {
        BeforeAll { $script:res = Get-LogIssues -LogPath $script:dirtyLog }

        It "captures two errors" {
            $script:res.errors.Count | Should -Be 2
        }
        It "captures the mod resolve error" {
            $script:res.errors -contains "Failed to resolve mod 'badmod'" | Should -BeTrue
        }
        It "captures the WARN" {
            $script:res.warns[0] | Should -Match "Mixin target net/minecraft/Foo"
        }
        It "captures the NoClassDefFoundError" {
            ($script:res.exceptions | Where-Object { $_ -match 'NoClassDefFoundError' }).Count | Should -Be 1
        }
    }
    It "throws when file is missing" {
        { Get-LogIssues -LogPath "$TestDrive\nope.txt" } | Should -Throw
    }
}
