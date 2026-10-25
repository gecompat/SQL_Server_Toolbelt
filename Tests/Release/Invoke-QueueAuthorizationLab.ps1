# Begrenzte T-SQL-Rechtequalifikation ohne CLR-/Serverkonfigurationsaenderung.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,[switch]$AuditOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='PREPARE'
# Vorhandene begrenzte SQL-, Pin- und Ownership-Helfer ohne deren Teststart.
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'QUEUE_AUTH_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($nodes.Count -ne 1){throw 'QUEUE_AUTH_HELPER_AMBIGUOUS'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
try {
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
 if($runset.schema_version -cne 'queue-authorization/v1' -or $runset.cases.Count -ne 12){throw 'QUEUE_AUTH_RUNSET_INVALID'}
 $case=$runset.cases[$CaseIndex]
 if($case.Platform -cnotin @('windows','linux') -or $case.Version -cnotin @('2019','2022','2025') -or
  [int]$case.CL -notin @{ '2019'=@(150);'2022'=@(150,160);'2025'=@(150,160,170) }[[string]$case.Version]){throw 'QUEUE_AUTH_CASE_INVALID'}
 Assert-ReleaseInputs
 foreach($required in @($PSCommandPath,$runset.fixture,$runset.exports.local,$runset.exports.central,
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $required).Count -ne 1){throw 'QUEUE_AUTH_REQUIRED_PIN_MISSING'}
 }
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $runset.contract_sha256){throw 'QUEUE_AUTH_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count -ne 1){throw 'QUEUE_AUTH_EXACT_TARGET_REQUIRED'}
 $target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json
  if($prior.state -cnotin @('COMPLETE','FAILED_CLEANED') -or $prior.owner -cnotmatch '^[a-f0-9]{32}$') {throw 'QUEUE_AUTH_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  foreach($entry in $prior.databases){
   if($entry.name -cne ('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix) -or $entry.state -cne 'DROPPED'){throw 'QUEUE_AUTH_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'QUEUE_AUTH_AUDIT_DATABASE_PRESENT'}
  }
  Assert-ReleaseInputs
 } else {
  if(Test-Path -LiteralPath $journal){throw 'QUEUE_AUTH_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();failure=$null}
  Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count -ne 1 -or $actual[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version] -or
   $actual[0].Platform -ine $case.Platform -or $actual[0].Admin -ne 1){throw 'QUEUE_AUTH_ACTUAL_TARGET_MISMATCH'}
  foreach($mode in @('local','central')){
   $stage='CREATE_'+$mode;$suffix=if($mode -ceq 'local'){'l'}else{'c'}
   $name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'}
   $ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $id=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($id.Count -ne 1){throw 'QUEUE_AUTH_DATABASE_IDENTITY'}
   $entry.id=$id[0].Id;$entry.created=$id[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal
   Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $stage='INSTALL_'+$mode
   Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   if($markers.Count -ne 3 -or @($markers|Where-Object { $_.name -ceq 'Toolbelt.Module.toolbelt.core.work-queue.Version' -and $_.Value -ceq '2.1.0' }).Count -ne 1){throw 'QUEUE_AUTH_CLOSURE_MISMATCH'}
   $definitions="SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.is_ms_shipped=0 ORDER BY o.object_id;"
   $before=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   $db.Dispose();$stage='RIGHTS_'+$mode
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.fixture))
   $after=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   if($before -cne $after){throw 'QUEUE_AUTH_PRODUCT_OBJECT_DRIFT'}
   $db.Dispose();$ledger.completedModes+=@($mode);Save-ReleaseJournal
  }
  Assert-ReleaseInputs
 }
} catch {
 $failure=$_.Exception
 if($ledger -and -not $AuditOnly){$ledger.failure=@{stage=$stage;privateDiagnostic=$failure.Message;privatePosition=$_.ScriptStackTrace};Save-ReleaseJournal}
} finally {
 foreach($connection in $connections){try{$connection.Dispose()}catch{}}
 if($ledger -and -not $AuditOnly){
  $cleanup=$true
  try {
   $control=Open-ReleaseConnection 'master'
   foreach($entry in $ledger.databases){Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal}
   $ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  } catch {$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally {if($control){$control.Dispose()}}
 }
}
if($failure){Write-Output 'FAIL QUEUE_AUTH_RIGHTS; inspect private journal; never replay without reconciliation';exit 1}
if($AuditOnly){'PASS QUEUE_AUTH_RIGHTS independent input/absence audit'}else{'PASS QUEUE_AUTH_RIGHTS local/direct-central; independent audit required'}
