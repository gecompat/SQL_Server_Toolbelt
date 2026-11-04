#Requires -Version 7.5
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$inputs=@{}
foreach($file in @(Get-ChildItem (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime') -File;Get-ChildItem (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures') -File)){
 $inputs[[IO.Path]::GetRelativePath($repo,$file.FullName).Replace('\','/')]=(Get-FileHash -LiteralPath $file.FullName).Hash
}
$driver=Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-CurrentBuildLab.ps1'
$parameters=@{Action='Run';Version='2019';Patch='CU32';CompatibilityLevel=150;DeploymentMode='local';ExpectedTargetKey='unused';ExpectedContractSha256=('0'*64);JournalDirectory=(Join-Path $repo '.runtime/ci-current-build');SsisReleaseDirectory='unused';ParserReleaseDirectory='unused';QualifiedProviderSha512=('0'*128);ExecutionInputSha256=$inputs;ValidateOnly=$true}
$checks=0
function Reject-Adapter([hashtable]$Changes,[string]$Expected){
 $arguments=$parameters.Clone();foreach($key in $Changes.Keys){$arguments[$key]=$Changes[$key]}
 try{& $driver @arguments|Out-Null}catch{if($_.Exception.Message -cne $Expected){throw};$script:checks++;return}
 throw 'SSIS_BUILD_ADAPTER_EXPECTED_REJECTION'
}
& $driver @parameters|Out-Null;$checks++
$central=$parameters.Clone();$central.Version='2025';$central.CompatibilityLevel=170;$central.DeploymentMode='central'
& $driver @central|Out-Null;$checks++
Reject-Adapter @{CompatibilityLevel=160} 'SSIS_BUILD_UNSUPPORTED_CL'
Reject-Adapter @{JournalDirectory=(Join-Path $repo 'Contoso')} 'SSIS_BUILD_JOURNAL_SCOPE'
$missing=$inputs.Clone();$missing.Remove('Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-CurrentBuildCases.ps1')
Reject-Adapter @{ExecutionInputSha256=$missing} 'SSIS_BUILD_INPUT_CLOSURE'
$missing=$inputs.Clone();$missing.Remove('Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/procedure-bigint-8.dtsx')
Reject-Adapter @{ExecutionInputSha256=$missing} 'SSIS_BUILD_FIXTURE_CLOSURE'
$drift=$inputs.Clone();$drift['Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-ProcedureBoundaryCases.ps1']='0'*64
Reject-Adapter @{ExecutionInputSha256=$drift} 'SSIS_BUILD_INPUT_DRIFT'
$escape=$inputs.Clone();$escape['../Contoso']='0'*64
Reject-Adapter @{ExecutionInputSha256=$escape} 'SSIS_BUILD_INPUT_DRIFT'
"SSIS_CURRENT_BUILD_ADAPTER_PASS $checks checks; no SQL"
