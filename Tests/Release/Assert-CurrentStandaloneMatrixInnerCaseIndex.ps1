[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$driver=Join-Path $PSScriptRoot 'Invoke-CurrentStandaloneTsqlInstallerMatrixLab.ps1'
$frozen=Join-Path $PSScriptRoot 'Invoke-StandaloneTsqlInstallerLab.ps1'
$driverText=[IO.File]::ReadAllText($driver)
$oldRange='[ValidateRange(0,1)][int]$CaseIndex,'
$newRange='[ValidateRange(0,3)][int]$CaseIndex,'
if(([regex]::Matches($driverText,[regex]::Escape("`$caseRangeAnchor='$oldRange'"))).Count -ne 1 -or
   ([regex]::Matches($driverText,[regex]::Escape("`$text=`$text.Replace(`$caseRangeAnchor,'$newRange')"))).Count -ne 1){
    throw 'SSIS_CURRENT_MATRIX_INNER_RANGE_ADAPTER_DRIFT'
}
$source=[IO.File]::ReadAllText($frozen)
if(([regex]::Matches($source,[regex]::Escape($oldRange))).Count -ne 1){
    throw 'SSIS_CURRENT_MATRIX_FROZEN_RANGE_ANCHOR'
}
$adapted=$source.Replace($oldRange,$newRange)
$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseInput($adapted,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_CURRENT_MATRIX_ADAPTED_PARAM_PARSE'}
$block=$tree.ParamBlock
if($null -eq $block){throw 'SSIS_CURRENT_MATRIX_ADAPTED_PARAMBLOCK'}
$parameters=@($block.Parameters | Where-Object {$_.Name.VariablePath.UserPath -ceq 'CaseIndex'})
if($parameters.Count -ne 1){throw 'SSIS_CURRENT_MATRIX_ADAPTED_PARAMETER'}
$ranges=@($parameters[0].Attributes | Where-Object {$_.TypeName.FullName -ceq 'ValidateRange'})
if($ranges.Count -ne 1 -or $ranges[0].PositionalArguments.Count -ne 2 -or
   $ranges[0].PositionalArguments[0].Extent.Text -cne '0' -or
   $ranges[0].PositionalArguments[1].Extent.Text -cne '3'){
    throw 'SSIS_CURRENT_MATRIX_ADAPTED_RANGE_VALUES'
}
$binding=[scriptblock]::Create($block.Extent.Text+"`n`$CaseIndex")
$arguments=@{RunsetPath='offline-validation-only';ExpectedRunsetSha256=('0'*64)}
foreach($accepted in @(2,3)){
    $actual=& $binding @arguments -CaseIndex $accepted
    if([int]$actual -ne $accepted){throw 'SSIS_CURRENT_MATRIX_ADAPTED_RANGE_ACCEPTANCE'}
}
$rejected=$false
try{[void](& $binding @arguments -CaseIndex 4)}catch{$rejected=$true}
if(-not $rejected){throw 'SSIS_CURRENT_MATRIX_ADAPTED_RANGE_REJECTION'}
'PASS SSIS_CURRENT_MATRIX_ADAPTED_INNER_CASEINDEX_2_3_ACCEPT_4_REJECT; no SQL'
