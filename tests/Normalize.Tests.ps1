BeforeAll {
    . "$PSScriptRoot\..\scripts\lib\Normalize.ps1"
}

Describe "ConvertTo-NormalizedLogLine" {
    It "strips timestamp prefix" {
        ConvertTo-NormalizedLogLine "[11:05:46] message body" | Should -Be "message body"
    }
    It "strips thread/level tag" {
        ConvertTo-NormalizedLogLine "[main/ERROR]: Failed to load class Foo" | Should -Be "Failed to load class Foo"
    }
    It "strips timestamp AND thread/level together" {
        ConvertTo-NormalizedLogLine "[11:05:46] [Server thread/INFO]: Done (12.2s)!" | Should -Be "Done (12.2s)!"
    }
    It "strips line numbers in stack frames" {
        ConvertTo-NormalizedLogLine "at Foo.bar(Foo.java:42)" | Should -Be "at Foo.bar(Foo.java)"
    }
    It "strips absolute repo paths (backslash form)" {
        ConvertTo-NormalizedLogLine "loaded D:\mc_mods\keep-it-simple\.test\1.20.1-server\mods\x.jar" `
            | Should -Be "loaded <repo>\.test\1.20.1-server\mods\x.jar"
    }
    It "strips absolute repo paths (file:/ form)" {
        ConvertTo-NormalizedLogLine "Source=file:/D:/mc_mods/keep-it-simple/libraries/foo.jar" `
            | Should -Be "Source=<repo>/libraries/foo.jar"
    }
    It "collapses runs of whitespace" {
        ConvertTo-NormalizedLogLine "a    b`tc" | Should -Be "a b c"
    }
    It "trims leading and trailing whitespace" {
        ConvertTo-NormalizedLogLine "  hello  " | Should -Be "hello"
    }
    It "accepts pipeline input" {
        $result = "[12:00:00] [main/WARN]: foo", "[12:00:01] [main/ERROR]: bar" | ConvertTo-NormalizedLogLine
        $result | Should -Be @("foo", "bar")
    }
}
