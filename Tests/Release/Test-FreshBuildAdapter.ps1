#Requires -Version 7.5
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runtime=Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime'
$inputs=@{}
foreach($file in @(Get-ChildItem $runtime -File;Get-ChildItem (Join-Path $runtime '../Fixtures') -File)){
 $inputs[[IO.Path]::GetRelativePath($repo,$file.FullName).Replace('\','/')]=(Get-FileHash $file.FullName).Hash
}
$driver=Join-Path $runtime 'Invoke-FreshBuildLab.ps1'
$args=@{Action='Run';Version='2019';Patch='CU32';CompatibilityLevel=150;DeploymentMode='central';ExpectedTargetKey='unused';ExpectedContractSha256=('0'*64);JournalDirectory=(Join-Path $repo '.runtime/unused-fresh-adapter');SsisReleaseDirectory='unused';ParserReleaseDirectory='unused';QualifiedProviderSha512=('0'*128);ExecutionInputSha256=$inputs;ValidateOnly=$true}
$checks=0
& $driver @args|Out-Null;$checks++
$text=(& $driver @args -DescribeOnly)|Out-String
foreach($required in @('$deadline=if($ssisNativeCleanupPhase){960}else{900}',
 'function Get-SsisNativeTimeout([int]$Maximum=45)',
 'Invoke-CurrentBuildCases.ps1','SSIS_LAB_PROTECTED_CONFIGURATION_PENDING_OR_DRIFT','finally')){
 if(-not $text.Contains($required,[StringComparison]::Ordinal)){throw ('FRESH_ADAPTER_LOST_GUARD_'+$required)}
 $checks++
}
if($text.Contains('$deadline=if($ssisNativeCleanupPhase){360}else{300}')){throw 'FRESH_OLD_COMBINED_DEADLINE'};$checks++
$missing=$inputs.Clone();$missing.Remove('Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-FreshBuildLab.ps1')
$bad=$args.Clone();$bad.ExecutionInputSha256=$missing
try{& $driver @bad|Out-Null;throw 'FRESH_EXPECTED_SELF_REJECTION'}catch{if($_.Exception.Message -cne 'SSIS_FRESH_BUILD_SELF_INPUT'){throw};$checks++}
$bad=$args.Clone();$bad.CompatibilityLevel=160
try{& $driver @bad|Out-Null;throw 'FRESH_EXPECTED_CL_REJECTION'}catch{if($_.Exception.Message -cne 'SSIS_BUILD_UNSUPPORTED_CL'){throw};$checks++}
"SSIS_FRESH_BUILD_ADAPTER_PASS $checks checks; no SQL"
