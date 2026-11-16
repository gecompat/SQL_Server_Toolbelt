# Read-only-Abschluss eines nachweislich vor SQL abgewiesenen Präparationsaufrufs.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
      [Parameter(Mandatory)][string]$ExpectedRunsetSha256,
      [Parameter(Mandatory)][string]$DiagnosisPath,
      [Parameter(Mandatory)][string]$ReceiptPath,
      [ValidateRange(0,11)][int]$CaseIndex=0)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$script:clock=[Diagnostics.Stopwatch]::StartNew();$script:cleanup=$false
$script:connections=[Collections.Generic.List[object]]::new()
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$null)
$node=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($node.Count -ne 1){throw 'PRE_SQL_AUDIT_IMPORT'}
. ([scriptblock]::Create($node[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @('Assert-ReleasePin','Assert-ReleasePrivatePath','Assert-ReleaseInputs','Get-ReleaseTimeout','Open-ReleaseConnection','Invoke-ReleaseSql')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
. (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
$RunsetPath=Assert-ReleasePrivatePath $RunsetPath
$ReceiptPath=Assert-ReleasePrivatePath $ReceiptPath
$DiagnosisPath=Assert-ReleasePrivatePath $DiagnosisPath
if(Test-Path -LiteralPath $ReceiptPath){throw 'PRE_SQL_AUDIT_RECEIPT_EXISTS'}
Assert-ReleasePin $RunsetPath $ExpectedRunsetSha256
$script:runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
Assert-ReleaseInputs
$diagnosis=Get-Content -LiteralPath $DiagnosisPath -Raw|ConvertFrom-Json
if($diagnosis.status -cne 'REPRODUCED_OFFLINE' -or $diagnosis.reason -cne 'RELEASE_PRIVATE_PATH_REQUIRED' -or
   $diagnosis.original_case_journal_exists -or $diagnosis.source_commit -cne $script:runset.method_commit){throw 'PRE_SQL_AUDIT_DIAGNOSIS'}
$guard=$null;try{[void](Assert-ReleasePrivatePath $script:runset.fixture)}catch{$guard=$_.Exception.Message}
if($guard -cne 'RELEASE_PRIVATE_PATH_REQUIRED'){throw 'PRE_SQL_AUDIT_GUARD_NOT_REPRODUCED'}
$caseJournal=Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json')
if((Test-Path -LiteralPath $caseJournal) -or (Test-Path -LiteralPath ($caseJournal+'.previous'))){throw 'PRE_SQL_AUDIT_UNEXPECTED_JOURNAL'}
$case=$script:runset.cases[$CaseIndex]
$contract=Resolve-LabContract -TestPurpose Functional
Assert-ReleasePin $contract.Path $script:runset.contract_sha256
$targets=@(Get-LabTargetsForSelector -Contract $contract.Contract -Selector $case)
if($targets.Count -ne 1){throw 'PRE_SQL_AUDIT_TARGET'}
$script:target=$targets[0];$control=$null
try{
    $control=Open-ReleaseConnection 'master'
    $actual=@(Invoke-ReleaseSql $control "SELECT @@VERSION VersionText,CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin,(SELECT CONVERT(int,value_in_use) FROM sys.configurations WHERE name=N'clr strict security') StrictSecurity;" -Rows)
    if($actual.Count -ne 1 -or $actual[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version] -or
       $actual[0].Platform -ine $case.Platform -or $actual[0].Admin -ne 1 -or $actual[0].StrictSecurity -ne 1){throw 'PRE_SQL_AUDIT_ACTUAL_TARGET'}
    $inventory=@(Invoke-ReleaseSql $control 'SELECT name,state_desc FROM sys.databases ORDER BY database_id;' -Rows)
    if($inventory.Count -lt 4 -or @($inventory|Where-Object state_desc -cne 'ONLINE').Count){throw 'PRE_SQL_AUDIT_INVENTORY'}
    if(Test-Path -LiteralPath $caseJournal){throw 'PRE_SQL_AUDIT_JOURNAL_APPEARED'}
    $receipt=@{status='PASS_PRE_SQL_REJECTION_AUDIT';runset_sha256=$ExpectedRunsetSha256;case_index=$CaseIndex;
        method_commit=$script:runset.method_commit;diagnosis_sha256=(Get-FileHash $DiagnosisPath).Hash;
        audit_method_sha256=(Get-FileHash $PSCommandPath).Hash;own_mutating_stage_reached=$false;
        own_resource_ids_allocated=$false;read_only_target_probe=$true;actual_target_private=$actual;inventory_private=$inventory}
    $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($receipt|ConvertTo-Json -Depth 7))
    $stream=[IO.File]::Open($ReceiptPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
}finally{foreach($connection in $script:connections){$connection.Dispose()};[Data.SqlClient.SqlConnection]::ClearAllPools()}
'PASS XLSX PRE_SQL_REJECTION fresh read-only target audit; no mutation stage'
