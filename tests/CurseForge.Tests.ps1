BeforeAll {
    . "$PSScriptRoot\..\scripts\lib\CurseForge.ps1"
    $script:fixture = Get-Content (Join-Path $PSScriptRoot 'fixtures\cf-sodium-files.json') -Raw | ConvertFrom-Json
}

Describe "Test-CurseForgeAvailable" {
    It "returns false when env var is missing" {
        $saved = $env:CURSEFORGE_API_KEY
        Remove-Item Env:CURSEFORGE_API_KEY -ErrorAction SilentlyContinue
        try { Test-CurseForgeAvailable | Should -BeFalse }
        finally { if ($saved) { $env:CURSEFORGE_API_KEY = $saved } }
    }
    It "returns true when env var is set" {
        $env:CURSEFORGE_API_KEY = 'abc'
        try { Test-CurseForgeAvailable | Should -BeTrue } finally { Remove-Item Env:CURSEFORGE_API_KEY }
    }
}

Describe "Select-CurseForgeFile" {
    It "prefers releaseType 1 over 2 over 3" {
        $mix = @(
            [pscustomobject]@{ id=1; releaseType=3; fileDate='2025-03-01' }
            [pscustomobject]@{ id=2; releaseType=2; fileDate='2025-02-01' }
            [pscustomobject]@{ id=3; releaseType=1; fileDate='2025-01-15' }
        )
        $sel = Select-CurseForgeFile -Files $mix
        $sel.id | Should -Be 3
        $sel.fallback_used | Should -BeFalse
    }
    It "falls back to beta" {
        $mix = @(
            [pscustomobject]@{ id=2; releaseType=2; fileDate='2025-02-01' }
            [pscustomobject]@{ id=3; releaseType=3; fileDate='2025-03-01' }
        )
        $sel = Select-CurseForgeFile -Files $mix
        $sel.id | Should -Be 2
        $sel.fallback_used | Should -BeTrue
    }
    It "real fixture: picks Sodium 1.20.1 file 6260639" {
        $sel = Select-CurseForgeFile -Files $script:fixture.data
        $sel.id | Should -Be 6260639
    }
    It "returns null on empty" {
        Select-CurseForgeFile -Files @() | Should -BeNullOrEmpty
    }
}
