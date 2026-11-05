#Requires -Version 7.5
# Fresh combined ZIP scope: one finite clock for functional and procedure cases.
[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('Run','Audit')][string]$Action,
 [Parameter(Mandatory)][ValidateSet('2019','2022','2025')][string]$Version,
 [Parameter(Mandatory)][ValidatePattern('^CU[0-9]+$')][string]$Patch,
 [Parameter(Mandatory)][ValidateSet(150,160,170)][int]$CompatibilityLevel,
 [Parameter(Mandatory)][ValidateSet('local','central')][string]$DeploymentMode,
 [Parameter(Mandatory)][string]$ExpectedTargetKey,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedContractSha256,
 [Parameter(Mandatory)][string]$JournalDirectory,
 [Parameter(Mandatory)][string]$SsisReleaseDirectory,[Parameter(Mandatory)][string]$ParserReleaseDirectory,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
 [Parameter(Mandatory)][hashtable]$ExecutionInputSha256,
 [ValidateSet('Full','Functional','ProcedureBoundary')][string]$QualificationPhase='Full',
 [string]$InstallationPackageRoot,[ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedPackageManifestSha256,
 [switch]$ValidateOnly,[switch]$DescribeOnly
)
$ErrorActionPreference='Stop'
$selfKey='Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-FreshBuildLab.ps1'
if(-not $ExecutionInputSha256.ContainsKey($selfKey) -or (Get-FileHash $PSCommandPath).Hash -cne $ExecutionInputSha256[$selfKey]){throw 'SSIS_FRESH_BUILD_SELF_INPUT'}
$prior=Join-Path $PSScriptRoot 'Invoke-CurrentBuildLab.ps1'
$recordPath=Join-Path $PSScriptRoot '../Qualification/Current.Build.20261104.json'
if((Get-FileHash $recordPath).Hash -cne '8E17CA520F50E8385E744CF4B6464B97263B1AF17AF4C6B074DC36556F22D60C'){throw 'SSIS_FRESH_BUILD_RECORD_CHANGED'}
$record=Get-Content $recordPath -Raw|ConvertFrom-Json
if((Get-FileHash $prior).Hash.ToLowerInvariant() -cne $record.source_sha256.'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-CurrentBuildLab.ps1'){throw 'SSIS_FRESH_BUILD_METHOD_CHANGED'}
$source=[IO.File]::ReadAllText($prior)
$anchor='$bound=Bind-CurrentScriptRoot -Text $text -Root $PSScriptRoot'
if($source.Split($anchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_FRESH_BUILD_COMPOSITION_ANCHOR'}
$replacement=@'
# The old five-minute scope was designed for a focused phase. This newly
# requested combined ZIP run has 15 minutes plus one reserved cleanup minute.
# Never restart the clock between phases and never weaken command timeouts.
$deadlineAnchor='$deadline=if($ssisNativeCleanupPhase){360}else{300}'
if($text.Split($deadlineAnchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_FRESH_BUILD_DEADLINE_ANCHOR'}
$text=$text.Replace($deadlineAnchor,'$deadline=if($ssisNativeCleanupPhase){960}else{900}')
if($DescribeOnly){$text;return}
$bound=Bind-CurrentScriptRoot -Text $text -Root $PSScriptRoot
'@
$source=$source.Replace($anchor,$replacement)
$validationAnchor="if(`$ValidateOnly){'SSIS_CURRENT_BUILD_INPUTS_PASS; no SQL';return}"
if($source.Split($validationAnchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_FRESH_BUILD_VALIDATION_ANCHOR'}
$source=$source.Replace($validationAnchor,"if(`$ValidateOnly -and -not `$DescribeOnly){'SSIS_CURRENT_BUILD_INPUTS_PASS; no SQL';return}")
$freshLabSourceRoot=$PSScriptRoot
$errors=$null;$tree=[Management.Automation.Language.Parser]::ParseInput($source,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_FRESH_BUILD_SYNTAX'}
foreach($variable in @($tree.FindAll({param($n)$n -is [Management.Automation.Language.VariableExpressionAst] -and $n.VariablePath.UserPath -ceq 'PSScriptRoot'},$true)|Sort-Object {$_.Extent.StartOffset} -Descending)){
 $source=$source.Substring(0,$variable.Extent.StartOffset)+'$freshLabSourceRoot'+$source.Substring($variable.Extent.EndOffset)
}
$arguments=@{};foreach($key in $PSBoundParameters.Keys){if($key -cne 'DescribeOnly'){$arguments[$key]=$PSBoundParameters[$key]}}
. ([scriptblock]::Create($source)) @arguments
