#requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

param(
    [string]$Path = "$PSScriptRoot",
    [string]$Tag,
    [switch]$ExcludeIntegration
)

$config = New-PesterConfiguration
$config.Run.Path = $Path
$config.Output.Verbosity = 'Detailed'
$config.Run.Exit = $true
if ($Tag) { $config.Filter.Tag = $Tag }
if ($ExcludeIntegration) { $config.Filter.ExcludeTag = 'Integration' }

Invoke-Pester -Configuration $config
