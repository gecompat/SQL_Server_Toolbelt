# Aktuelle Stable-19-Integration; historische Pakettreiber und deren Pins bleiben erhalten.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
      [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,[switch]$AuditOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new()
$ledger=$null;$failure=$null;$control=$null;$stage='PREPARE'
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'STABLE19_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($nodes.Count -ne 1){throw 'STABLE19_IMPORT_AMBIGUOUS'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Read-ReleaseUninstall','Save-ReleaseJournal',
 'Assert-ReleaseInputs','Assert-ReleaseOwnIdentity','Assert-ReleaseInstalled','Invoke-ReleaseSmoke')){. $block}
try {
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
 if($runset.schema_version -cne 'toolbelt-stable19-acceptance/v1' -or $runset.cases.Count -ne 12 -or
    $runset.source_commit -cnotmatch '^[a-f0-9]{40}$' -or $runset.modules.Count -ne 19){throw 'STABLE19_RUNSET'}
 $case=$runset.cases[$CaseIndex]
 if($case.Platform -cnotin @('windows','linux') -or $case.Version -cnotin @('2019','2022','2025') -or
  [int]$case.CL -notin @{'2019'=@(150);'2022'=@(150,160);'2025'=@(150,160,170)}[[string]$case.Version]){throw 'STABLE19_CASE'}
 Assert-ReleaseInputs
 foreach($path in @($PSCommandPath,$runset.exports.local,$runset.exports.central,$runset.fixture,
  (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),
  (Join-Path $PSScriptRoot 'Runtime/Invoke-ParameterHelpCases.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $path).Count -ne 1){throw 'STABLE19_REQUIRED_PIN'}
 }
 $stable=@($runset.modules)
 if(@($stable.module_id|Select-Object -Unique).Count -ne 19){throw 'STABLE19_DUPLICATE_MODULE'}
 $files=@{}
 foreach($entry in $runset.uninstall_files.PSObject.Properties){
  $expected=[IO.Path]::GetFullPath((Join-Path $repo $entry.Name))
  if($entry.Name -cnotmatch '^(Modules/toolbelt\.[a-z0-9.-]+|Scripts)/[a-zA-Z0-9_./-]+\.sql$' -or
     $expected -cne $entry.Value -or @($runset.pins|Where-Object path -CEQ $expected).Count -ne 1){throw 'STABLE19_UNINSTALL_PIN'}
  $files[$entry.Name]=[IO.File]::ReadAllText($expected)
 }
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $runset.contract_sha256 -or
    (Get-FileHash -LiteralPath $lab.SchemaPath -Algorithm SHA256).Hash -cne $runset.schema_sha256 -or
    (Get-FileHash -LiteralPath (Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE') -Algorithm SHA256).Hash -cne $runset.prompt_sha256){throw 'STABLE19_LAB_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count -ne 1){throw 'STABLE19_EXACT_TARGET'}
 $target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 $control=Open-ReleaseConnection 'master'
 Invoke-ReleaseSql $control 'SELECT @@VERSION; SELECT name,state_desc FROM sys.databases ORDER BY database_id;'
 if($AuditOnly){
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json
  if($prior.state -cnotin @('COMPLETE','FAILED_CLEANED') -or $prior.owner -cnotmatch '^[a-f0-9]{32}$'){throw 'STABLE19_AUDIT_STATE'}
  foreach($entry in $prior.databases){
   if($entry.name -cne ('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix) -or $entry.state -cne 'DROPPED'){throw 'STABLE19_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'STABLE19_AUDIT_PRESENT'}
  }
  Assert-ReleaseInputs
 } else {
  if(Test-Path -LiteralPath $journal){throw 'STABLE19_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();help=@();failure=$null}
  Save-ReleaseJournal
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count -ne 1 -or $actual[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version] -or
     $actual[0].Platform -ine $case.Platform -or $actual[0].Admin -ne 1){throw 'STABLE19_ACTUAL_TARGET'}
  $names=@{}
  foreach($label in @('local','central','consumer')){
   $stage='CREATE_'+$label;$suffix=@{local='l';central='c';consumer='u'}[$label]
   $name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'}
   $ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 51591,N'Database collision.',4; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($identity.Count -ne 1){throw 'STABLE19_DATABASE_IDENTITY'}
   $entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal
   Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $level=@(Invoke-ReleaseSql $control 'SELECT compatibility_level CL FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($level.Count -ne 1 -or $level[0].CL -ne $case.CL){throw 'STABLE19_CL'}
   $db.Dispose();$names[$label]=$name
  }
  foreach($mode in @('local','central')){
   $sql=[IO.File]::ReadAllText($runset.exports.$mode)
   $order=@([regex]::Matches($sql,'(?m)^-- BEGIN MODULE (toolbelt\.[a-z0-9.-]+)')|ForEach-Object{$_.Groups[1].Value})
   if($order.Count -ne 19 -or (Compare-Object ($stable.module_id|Sort-Object) ($order|Sort-Object))){throw 'STABLE19_EXPORT_COHORT'}
   $first=$null
   foreach($phase in @('INSTALL','REPEAT')){
    $stage=$phase+'_'+$mode;$db=Open-ReleaseConnection $names[$mode]
    Invoke-ReleaseBatches $db $sql
    $snapshot=Assert-ReleaseInstalled $db $mode
    if($phase -ceq 'REPEAT' -and $snapshot -cne $first){throw 'STABLE19_REPEAT_DRIFT'}
    $first=$snapshot
    $assemblies=@(Invoke-ReleaseSql $db 'SELECT COUNT(*) N FROM sys.assemblies WHERE is_user_defined=1;' -Rows)
    if($assemblies.Count -ne 1 -or $assemblies[0].N -ne 0){throw 'STABLE19_UNEXPECTED_CLR'}
    foreach($obj in $runset.public_objects){
     $rows=@(Invoke-ReleaseSql $db 'SELECT OBJECT_ID(@Name) Id;' @{'@Name'=($obj.schema+'.'+$obj.name)} -Rows)
     if($rows.Count -ne 1 -or $rows[0].Id -is [DBNull]){throw 'STABLE19_PUBLIC_API_MISSING'}
    }
    Invoke-ReleaseSmoke $db
    $help=& (Join-Path $PSScriptRoot 'Runtime/Invoke-ParameterHelpCases.ps1') -Connection $db -Fixture $runset.fixture -Platform Portable -Mode $mode -Deadline ([datetime]::UtcNow.AddSeconds((Get-ReleaseTimeout)))
    $ledger.help+=@([ordered]@{mode=$mode;phase=$phase;result=$help});Save-ReleaseJournal
    $db.Dispose()
   }
   if($mode -ceq 'central'){$db=Open-ReleaseConnection $names.consumer;Invoke-ReleaseSmoke $db ('['+$names.central+'].');$db.Dispose()}
   $stage='UNINSTALL_'+$mode;[array]::Reverse($order)
   foreach($repeat in 1..2){foreach($mid in $order){$db=Open-ReleaseConnection $names[$mode];Invoke-ReleaseBatches $db (Read-ReleaseUninstall "Modules/$mid/Deployment/Uninstall.sql");$db.Dispose()}}
   $db=Open-ReleaseConnection $names[$mode]
   $left=@(Invoke-ReleaseSql $db "SELECT (SELECT COUNT(*) FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE s.name LIKE N'toolbelt[_]%' AND o.is_ms_shipped=0) Objects,(SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%') Markers;" -Rows)
   if($left.Count -ne 1 -or $left[0].Objects -ne 0 -or $left[0].Markers -ne 0){throw 'STABLE19_UNINSTALL_RESIDUE'}
   $db.Dispose();$ledger.completedModes+=@($mode);Save-ReleaseJournal
  }
  Assert-ReleaseInputs
 }
} catch {
 $failure=$_.Exception
 if($ledger -and -not $AuditOnly){$ledger.failure=@{stage=$stage;privateDiagnostic=$failure.Message;privateStack=$_.ScriptStackTrace};Save-ReleaseJournal}
} finally {
 foreach($connection in $connections){try{$connection.Dispose()}catch{}}
 if($ledger -and -not $AuditOnly){
  $cleanup=$true
  try{$control=Open-ReleaseConnection 'master';foreach($entry in $ledger.databases){Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal};$ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal}
  catch{$ledger.state='CLEANUP_BLOCKED';Save-ReleaseJournal;$failure=$_.Exception}
 }
 if($control){$control.Dispose()}
}
if($failure){$code=if($failure.Message -cmatch '^(STABLE19_|RELEASE_)[A-Z0-9_]+$'){$failure.Message}else{'STABLE19_UNCLASSIFIED'};Write-Output ('FAIL STABLE19 '+$stage+' '+$code);exit 1}
if($AuditOnly){'PASS STABLE19 independent cleanup and pins'}else{'PASS STABLE19 current install/repeat/public API/Help/consumer/uninstall'}
