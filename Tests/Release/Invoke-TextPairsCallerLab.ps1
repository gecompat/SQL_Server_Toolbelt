# Textpaar-Callerqualifikation mit privatem Trust-/Konfigurationsjournal.
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
if($errors.Count){throw 'CLR_CALLER_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($nodes.Count -ne 1){throw 'CLR_CALLER_HELPER_AMBIGUOUS'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
. (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')
try {
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
 if($runset.schema_version -cne 'text-pairs-caller-contract/v1' -or $runset.cases.Count -ne 12){throw 'CLR_CALLER_RUNSET_INVALID'}
 $case=$runset.cases[$CaseIndex]
 if($case.Platform -cnotin @('windows','linux') -or $case.Version -cnotin @('2019','2022','2025') -or
  [int]$case.CL -notin @{ '2019'=@(150);'2022'=@(150,160);'2025'=@(150,160,170) }[[string]$case.Version]){throw 'CLR_CALLER_CASE_INVALID'}
 Assert-ReleaseInputs
 foreach($required in @($PSCommandPath,$runset.fixture,$runset.exports.local,$runset.exports.central,
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'),(Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $required).Count -ne 1){throw 'CLR_CALLER_REQUIRED_PIN_MISSING'}
 }
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $runset.contract_sha256){throw 'CLR_CALLER_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count -ne 1){throw 'CLR_CALLER_EXACT_TARGET_REQUIRED'}
 $target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json
  if($prior.state -cnotin @('COMPLETE','FAILED_CLEANED') -or $prior.owner -cnotmatch '^[a-f0-9]{32}$') {throw 'CLR_CALLER_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  foreach($entry in $prior.databases){
   if($entry.name -cne ('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix) -or $entry.state -cne 'DROPPED'){throw 'CLR_CALLER_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'CLR_CALLER_AUDIT_DATABASE_PRESENT'}
  }
  foreach($entry in $prior.trust){
   $actual=Get-ClrCallerTrust $control ([Convert]::FromHexString($entry.hash))
   if(($entry.preexisting -and ($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint)) -or (-not $entry.preexisting -and $null -ne $actual)){throw 'CLR_CALLER_AUDIT_TRUST_DRIFT'}
  }
  Assert-ClrCallerConfiguration $control $prior.configuration
  Assert-ReleaseInputs
 } else {
  if(Test-Path -LiteralPath $journal){throw 'CLR_CALLER_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();trust=@();configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()};failure=$null}
  Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT @@VERSION VersionText,CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count -ne 1 -or $actual[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version] -or
   $actual[0].Platform -ine $case.Platform -or $actual[0].Admin -ne 1){throw 'CLR_CALLER_ACTUAL_TARGET_MISMATCH'}
  if([string]::IsNullOrWhiteSpace([string]$actual[0].VersionText)){throw 'TEXT_PAIRS_PREFLIGHT_VERSION'}
  $inventory=@(Invoke-ReleaseSql $control 'SELECT name,state_desc FROM sys.databases ORDER BY database_id;' -Rows)
  if($inventory.Count -lt 4 -or @($inventory|Where-Object state_desc -CNE 'ONLINE').Count){throw 'TEXT_PAIRS_PREFLIGHT_DATABASE_STATE'}
  if($runset.artifacts.Count -ne 1 -or @($runset.artifacts.module_id|Sort-Object -Unique).Count -ne 1){throw 'CLR_CALLER_ARTIFACT_SCOPE'}
  foreach($artifact in $runset.artifacts){
   if($artifact.module_id -cnotin @('toolbelt.string.edit-distance')){throw 'CLR_CALLER_ARTIFACT_MODULE'}
   $path=Assert-ReleasePrivatePath $artifact.path
   if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $artifact.sha256 -or (Get-FileHash -LiteralPath $path -Algorithm SHA512).Hash -cne $artifact.sha512){throw 'CLR_CALLER_ARTIFACT_DRIFT'}
  }
  $stage='CONFIGURATION';Start-ClrCallerConfiguration $control
  $stage='TRUST'
  foreach($a in $runset.artifacts){
   $hash=[Convert]::FromHexString($a.sha512);$before=Get-ClrCallerTrust $control $hash
   $entry=[ordered]@{hash=$a.sha512;preexisting=($null -ne $before);fingerprint=$null;state='PREEXISTING';description=$null}
   if($before){$entry.fingerprint=$before.Fingerprint}
   $ledger.trust+=@($entry);Save-ReleaseJournal
   if(-not $before){
    Assert-ClrCallerTrustCleanupScope $control $hash
    $entry.state='ADDING';$entry.description='Contoso CLR caller '+$ledger.owner+' '+$a.sql_name;Save-ReleaseJournal
    Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$hash;'@Description'=$entry.description}
    $actual=Get-ClrCallerTrust $control $hash
    if($null -eq $actual -or $actual.description -cne $entry.description){throw 'CLR_CALLER_TRUST_OWNERSHIP_UNKNOWN'}
    $entry.fingerprint=$actual.Fingerprint;$entry.state='OWNED';Save-ReleaseJournal
   }
  }
  foreach($mode in @('local','central')){
   $stage='CREATE_'+$mode;$suffix=if($mode -ceq 'local'){'l'}else{'c'}
   $name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'}
   $ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $id=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($id.Count -ne 1){throw 'CLR_CALLER_DATABASE_IDENTITY'}
   $entry.id=$id[0].Id;$entry.created=$id[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal
   Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $stage='INSTALL_'+$mode
   Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   $expected=@($runset.module_versions.PSObject.Properties)
   if(-not $expected.Count -or $markers.Count -ne $expected.Count){throw 'CLR_CALLER_CLOSURE_MISMATCH'}
   foreach($module in $expected){
    if($module.Name -cnotmatch '^toolbelt\.[a-z0-9.-]+$' -or [string]$module.Value -cnotmatch '^\d+\.\d+\.\d+$' -or
     @($markers|Where-Object { $_.name -ceq ('Toolbelt.Module.'+$module.Name+'.Version') -and $_.Value -ceq [string]$module.Value }).Count -ne 1){throw 'CLR_CALLER_CLOSURE_MISMATCH'}
   }
   $assemblies=@(Invoke-ReleaseSql $db "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;" -Rows)
   if($assemblies.Count -ne 1){throw 'CLR_CALLER_ASSEMBLY_COUNT'}
   foreach($a in $runset.artifacts){if(@($assemblies|Where-Object {$_.name -ceq $a.sql_name -and $_.Hash -ceq $a.sha512 -and $_.Permission -ceq 'SAFE_ACCESS'}).Count -ne 1){throw 'CLR_CALLER_INSTALLED_ASSEMBLY_DRIFT'}}
   $definitions="SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash,a.assembly_id,a.assembly_class,a.assembly_method FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id LEFT JOIN sys.assembly_modules a ON a.object_id=o.object_id WHERE o.is_ms_shipped=0 ORDER BY o.object_id;"
   $before=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   $db.Dispose();$stage='CONTRACT_'+$mode
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.fixture))
   $afterAssemblies=@(Invoke-ReleaseSql $db "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;" -Rows)
   if(($assemblies|Sort-Object name|ConvertTo-Json -Depth 4 -Compress) -cne ($afterAssemblies|Sort-Object name|ConvertTo-Json -Depth 4 -Compress)){throw 'CLR_CALLER_ASSEMBLY_POST_DRIFT'}
   $after=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   if($before -cne $after){throw 'CLR_CALLER_PRODUCT_OBJECT_DRIFT'}
   $db.Dispose();$ledger.completedModes+=@($mode);Save-ReleaseJournal
  }
  Assert-ReleaseInputs
 }
} catch {
 $failure=$_.Exception
 if($ledger -and -not $AuditOnly){$ledger.failure=@{stage=$stage;privateDiagnostic=$failure.Message;privatePosition=$_.ScriptStackTrace};Save-ReleaseJournal}
} finally {
 foreach($connection in $connections){try{$connection.Dispose()}catch{}}
 [Data.SqlClient.SqlConnection]::ClearAllPools()
 if($ledger -and -not $AuditOnly){
  $cleanup=$true
  try {
   $control=Open-ReleaseConnection 'master'
   foreach($entry in $ledger.databases){Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal}
   foreach($entry in $ledger.trust){
    $hash=[Convert]::FromHexString($entry.hash);$actual=Get-ClrCallerTrust $control $hash
    if($entry.preexisting){if($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint){throw 'CLR_CALLER_PREEXISTING_TRUST_DRIFT'};continue}
    if($entry.state -cne 'OWNED' -or $null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint -or $actual.description -cne $entry.description){throw 'CLR_CALLER_TRUST_CLEANUP_IDENTITY'}
    Assert-ClrCallerTrustCleanupScope $control $hash
    Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
    if($null -ne (Get-ClrCallerTrust $control $hash)){throw 'CLR_CALLER_TRUST_NOT_REMOVED'}
    $entry.state='REMOVED';Save-ReleaseJournal
   }
   Restore-ClrCallerConfiguration $control
   $ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  } catch {$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally {if($control){$control.Dispose()}}
 }
}
if($failure){Write-Output 'FAIL CLR_CALLER_RIGHTS; inspect private journal; never replay without reconciliation';exit 1}
if($AuditOnly){'PASS CLR_CALLER_RIGHTS independent input/absence audit'}else{'PASS CLR_CALLER_RIGHTS local/direct-central; independent audit required'}
