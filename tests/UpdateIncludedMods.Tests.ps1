BeforeAll {
    $script:script = "$PSScriptRoot\..\scripts\update-included-mods.ps1"
}

Describe "update-included-mods.ps1" {

    BeforeEach {
        $script:work = Join-Path $TestDrive 'MODS-LIST.md'
    }

    It "inserts a new row under a new Performance section when the file has no sections yet" {
        Copy-Item (Join-Path $PSScriptRoot 'fixtures\MODS-LIST-empty.md') $script:work -Force

        & $script:script -File $script:work `
            -Slug 'sodium' -Name 'Sodium' `
            -AuthorUrl 'https://modrinth.com/organization/caffeinemc' -AuthorName 'CaffeineMC' `
            -Description 'Rewrites chunk rendering' `
            -Side 'C' -Category 'Performance' `
            -McVersionsInTable @('1.20.1','1.21.1','1.21.4','26.1.2') `
            -VersionsAvailable @('1.20.1','1.21.1','1.21.4','26.1.2') `
            -VersionsAdded     @('1.20.1','1.21.1','1.21.4','26.1.2')

        $out = Get-Content $script:work -Raw -Encoding utf8
        $out | Should -Match '## Performance'
        $out | Should -Match '\[Sodium\]\(https://modrinth\.com/mod/sodium\) `C`'
        ($out -split '\n' | Where-Object { $_ -match '^\| \[Sodium\]' }).Count | Should -Be 1
    }

    It "is idempotent (running twice produces one row)" {
        Copy-Item (Join-Path $PSScriptRoot 'fixtures\MODS-LIST-empty.md') $script:work -Force
        $argsHash = @{
            File = $script:work; Slug='sodium'; Name='Sodium'
            AuthorUrl='https://modrinth.com/organization/caffeinemc'; AuthorName='CaffeineMC'
            Description='Rewrites'; Side='C'; Category='Performance'
            McVersionsInTable=@('1.20.1','1.21.1','1.21.4','26.1.2')
            VersionsAvailable=@('1.20.1','1.21.1','1.21.4','26.1.2')
            VersionsAdded    =@('1.20.1','1.21.1','1.21.4','26.1.2')
        }
        & $script:script @argsHash
        & $script:script @argsHash
        $out = Get-Content $script:work -Raw -Encoding utf8
        ($out -split '\n' | Where-Object { $_ -match '^\| \[Sodium\]' }).Count | Should -Be 1
    }

    It "inserts rows alphabetically within a section" {
        Copy-Item (Join-Path $PSScriptRoot 'fixtures\MODS-LIST-with-sodium.md') $script:work -Force
        & $script:script -File $script:work `
            -Slug 'lithium' -Name 'Lithium' `
            -AuthorUrl 'https://modrinth.com/organization/caffeinemc' -AuthorName 'CaffeineMC' `
            -Description 'Optimizes game logic' `
            -Side 'B' -Category 'Performance' `
            -McVersionsInTable @('1.20.1','1.21.1','1.21.4','26.1.2') `
            -VersionsAvailable @('1.20.1','1.21.1','1.21.4','26.1.2') `
            -VersionsAdded     @('1.20.1','1.21.1','1.21.4','26.1.2')

        $lines = Get-Content $script:work -Encoding utf8
        $litIdx = ($lines | Select-String -Pattern '^\| \[Lithium\]' | Select-Object -First 1).LineNumber
        $sodIdx = ($lines | Select-String -Pattern '^\| \[Sodium\]'  | Select-Object -First 1).LineNumber
        $litIdx | Should -BeLessThan $sodIdx
    }

    It "marks available-but-not-added versions with empty cells" {
        Copy-Item (Join-Path $PSScriptRoot 'fixtures\MODS-LIST-empty.md') $script:work -Force
        & $script:script -File $script:work `
            -Slug 'lithium' -Name 'Lithium' `
            -AuthorUrl 'https://modrinth.com/organization/caffeinemc' -AuthorName 'CaffeineMC' `
            -Description 'Optimizes' `
            -Side 'B' -Category 'Performance' `
            -McVersionsInTable @('1.20.1','1.21.1','1.21.4','26.1.2') `
            -VersionsAvailable @('1.20.1','1.21.1','1.21.4','26.1.2') `
            -VersionsAdded     @('1.20.1','1.21.4')

        $row = (Get-Content $script:work -Encoding utf8) -match '^\| \[Lithium\]'
        $row | Should -Match '\| .* \|  \| .* \|  \|'
    }

    It "creates the Performance section before Visual / Functional / Libraries" {
        $custom = @"
# Included Mods

| Symbol | Meaning |
| :---: | --- |
| $(([char]0x2705)) | shipped for that version |

## Libraries

| Name | Author | 1.20.1 | Description |
| --- | --- | :---: | --- |
| [YACL](https://example.com) ``B`` | [isXander](https://example.com) | $(([char]0x2705)) | Config UI library |
"@
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($script:work, $custom, $utf8NoBom)

        & $script:script -File $script:work `
            -Slug 'sodium' -Name 'Sodium' `
            -AuthorUrl 'https://modrinth.com/organization/caffeinemc' -AuthorName 'CaffeineMC' `
            -Description 'Renderer' `
            -Side 'C' -Category 'Performance' `
            -McVersionsInTable @('1.20.1') `
            -VersionsAvailable @('1.20.1') `
            -VersionsAdded     @('1.20.1')

        $out = Get-Content $script:work -Raw -Encoding utf8
        $perfIdx = $out.IndexOf('## Performance')
        $libIdx  = $out.IndexOf('## Libraries')
        $perfIdx | Should -BeLessThan $libIdx
        $perfIdx | Should -BeGreaterThan 0
    }

    It "round-trips UTF-8 checkmark characters without corruption" {
        Copy-Item (Join-Path $PSScriptRoot 'fixtures\MODS-LIST-with-sodium.md') $script:work -Force

        & $script:script -File $script:work `
            -Slug 'lithium' -Name 'Lithium' `
            -AuthorUrl 'https://modrinth.com/organization/caffeinemc' -AuthorName 'CaffeineMC' `
            -Description 'Optimizes' `
            -Side 'B' -Category 'Performance' `
            -McVersionsInTable @('1.20.1','1.21.1','1.21.4','26.1.2') `
            -VersionsAvailable @('1.20.1','1.21.1','1.21.4','26.1.2') `
            -VersionsAdded     @('1.20.1','1.21.1','1.21.4','26.1.2')

        $bytes = [System.IO.File]::ReadAllBytes($script:work)
        $checkmarkUtf8 = [System.Text.Encoding]::UTF8.GetBytes([char]0x2705)
        $encoded = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ' '
        $needle  = ($checkmarkUtf8 | ForEach-Object { $_.ToString('x2') }) -join ' '
        $encoded | Should -Match ([regex]::Escape($needle))
    }
}
