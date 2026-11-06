# Direkte Constructor-Clientmetadaten; keine Rechtevergabe/Identitäten.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,5)][int]$CaseIndex,
 [ValidateSet('windows','linux')][string]$Platform='windows',[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='PREPARE'
# Vorhandene begrenzte SQL-, Pin- und Ownership-Helfer ohne deren Teststart.
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'CONSTRUCTOR_METADATA_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($nodes.Count -ne 1){throw 'CONSTRUCTOR_METADATA_HELPER_AMBIGUOUS'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
. (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')
. (Join-Path $PSScriptRoot 'JsonConstructors.ClientMetadata.ps1')
function Read-ConstructorMetadataTrust($Control){@(Invoke-ReleaseSql $Control 'SELECT CONVERT(varchar(128),hash,2) Hash,description,CONVERT(varchar(32),CONVERT(varbinary(max),create_date),2) Created,created_by FROM sys.trusted_assemblies ORDER BY hash;' -Rows)|ConvertTo-Json -Depth 4 -Compress}
function Read-ConstructorMetadataTarget($Control){
 $r=@(Invoke-ReleaseSql $Control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
 if($r.Count-ne1-or$r[0].Major-ne@{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version]-or$r[0].Platform-ine$case.Platform-or$r[0].Admin-ne1){throw 'CONSTRUCTOR_METADATA_ACTUAL_TARGET'}
 return $r[0]
}
try {
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version -cne 'json-constructors-client-metadata/v1' -or $runset.cases.Count -ne 6 -or
  $runset.explicit_qualification_approved -isnot [bool] -or
  $runset.explicit_qualification_approved -ne $true){throw 'CONSTRUCTOR_METADATA_RUNSET_INVALID'}
 # Neue endliche Welle; alte Ledgers und verbrauchte Grenzen bleiben geschlossen.
 $deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 $started=[DateTimeOffset]::Parse($runset.started_utc)
 if($deadline -ne $started.AddMinutes(45) -or $started -gt [DateTimeOffset]::UtcNow -or
  (-not $AuditOnly -and [DateTimeOffset]::UtcNow.AddMinutes(7) -ge $deadline)) {throw 'CONSTRUCTOR_CLIENT_METADATA_ADMISSION_CLOSED'}
 $case=$runset.cases[$CaseIndex]
 $expected=if($Platform -ceq 'windows'){
  @('2019/CU32/150','2022/CU26/150','2022/CU26/160','2025/CU8/150','2025/CU8/160','2025/CU8/170')
 }else{@('2019/latest/150','2022/latest/150','2022/latest/160','2025/latest/150','2025/latest/160','2025/latest/170')}
 # Das Profil ist explizit: keine Plattformmischung und kein Patchfallback,
 # auch nicht in den späteren, noch nicht ausgeführten Runsetkontexten.
 for($position=0;$position -lt 6;$position++){
  $selected=$runset.cases[$position]
  if($selected.Platform -cne $Platform -or
   ([string]$selected.Version+'/'+[string]$selected.Patch+'/'+[string]$selected.CL) -cne $expected[$position]){throw 'CONSTRUCTOR_CLIENT_METADATA_CASE_SCOPE'}
 }
 if($case.Platform -cne $Platform -or $case.Version -cnotin @('2019','2022','2025') -or
  [int]$case.CL -notin @{ '2019'=@(150);'2022'=@(150,160);'2025'=@(150,160,170) }[[string]$case.Version]){throw 'CONSTRUCTOR_METADATA_CASE_INVALID'}
 Assert-ReleaseInputs
 $knownPath=Join-Path $repo 'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'
 $known=Get-Content -LiteralPath $knownPath -Raw|ConvertFrom-Json
 if($runset.fixture-cne(Join-Path $repo 'Modules/toolbelt.json.constructors/Tests/Runtime/SelectMetadata.Contract.ps1')){throw 'CONSTRUCTOR_METADATA_CANONICAL_FIXTURE_REQUIRED'}
  if($runset.artifacts.Count -ne 2 -or @($runset.artifacts.module_id|Sort-Object -Unique).Count -ne 2){throw 'CONSTRUCTOR_METADATA_ARTIFACT_SCOPE'}
  foreach($artifact in $runset.artifacts){
   if($artifact.module_id -cnotin @('toolbelt.json.core','toolbelt.json.constructors')){throw 'CONSTRUCTOR_METADATA_ARTIFACT_MODULE'}
   $path=Assert-ReleasePrivatePath $artifact.path
   if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $artifact.sha256 -or (Get-FileHash -LiteralPath $path -Algorithm SHA512).Hash -cne $artifact.sha512){throw 'CONSTRUCTOR_METADATA_ARTIFACT_DRIFT'}
  }

 foreach($a in $runset.artifacts){
  $k=@($known.artifacts|Where-Object{$_.Fields.moduleId-ceq$a.module_id})
  if($k.Count-ne1-or$a.sha256-cne$k[0].Fields.binarySha256.ToUpperInvariant()-or$a.sha512-cne$k[0].Fields.binarySha512.ToUpperInvariant()-or$a.sql_name-cne$k[0].Fields.sqlAssembly){throw 'CONSTRUCTOR_METADATA_KNOWN_ARTIFACT_REQUIRED'}
 }
 foreach($required in @($PSCommandPath,$runset.fixture,$knownPath,(Join-Path $PSScriptRoot 'JsonConstructors.ClientMetadata.ps1'),$runset.exports.local,$runset.exports.central,
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'),(Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $required).Count -ne 1){throw 'CONSTRUCTOR_METADATA_REQUIRED_PIN_MISSING'}
 }
 if($ValidateOnly){$null=ConvertTo-ConstructorClientMetadataLoop ([IO.File]::ReadAllText($runset.fixture));'PASS CONSTRUCTOR_CLIENT_METADATA_OFFLINE_ADMISSION; no Lab import or SQL';return}
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $runset.contract_sha256){throw 'CONSTRUCTOR_METADATA_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count -ne 1){throw 'CONSTRUCTOR_METADATA_EXACT_TARGET_REQUIRED'}
 $target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $originalJournalHash=(Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json
  if($prior.state -cnotin @('COMPLETE','FAILED_CLEANED') -or $prior.owner -cnotmatch '^[a-f0-9]{32}$') {throw 'CONSTRUCTOR_METADATA_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $nowTarget=Read-ConstructorMetadataTarget $control
  if($prior.observedTarget-and($nowTarget.Version-cne$prior.observedTarget.Version-or$nowTarget.Platform-cne$prior.observedTarget.Platform)){throw 'CONSTRUCTOR_METADATA_AUDIT_TARGET_DRIFT'}
  foreach($entry in $prior.databases){
   if($entry.name -cne ('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix) -or $entry.state -cne 'DROPPED'){throw 'CONSTRUCTOR_METADATA_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'CONSTRUCTOR_METADATA_AUDIT_DATABASE_PRESENT'}
  }
  foreach($entry in $prior.trust){
   $actual=Get-ClrCallerTrust $control ([Convert]::FromHexString($entry.hash))
   if(($entry.preexisting -and ($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint)) -or (-not $entry.preexisting -and $null -ne $actual)){throw 'CONSTRUCTOR_METADATA_AUDIT_TRUST_DRIFT'}
  }
  Assert-ClrCallerConfiguration $control $prior.configuration
  if((@($prior.configuration.before).Count-and(@(Get-ClrCallerConfiguration $control)|ConvertTo-Json -Depth 4 -Compress)-cne(@($prior.configuration.before)|ConvertTo-Json -Depth 4 -Compress))-or($prior.trustSnapshotCaptured-and(Read-ConstructorMetadataTrust $control)-cne$prior.trustBefore)){throw 'CONSTRUCTOR_METADATA_AUDIT_SERVER_DRIFT'}
  Assert-ReleaseInputs
  if((Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash -cne $originalJournalHash){throw 'CONSTRUCTOR_CLIENT_METADATA_AUDIT_JOURNAL_DRIFT'}
  [IO.File]::WriteAllText(($journal+'.audit.json'),([ordered]@{
   state='COMPLETE';readOnly=$true;originalJournalSHA256=$originalJournalHash;
   originalRunPassed=($prior.state -ceq 'COMPLETE' -and $null -eq $prior.failure -and $prior.completedModes.Count -eq 2 -and $prior.witnesses.Count -eq 2 -and @($prior.witnesses|Where-Object{$_.metadata.state-cne'COMPLETE'-or$_.metadata.profiles-ne16-or$_.metadata.selectProfiles-ne8-or$_.metadata.helpProfiles-ne4-or$_.metadata.resultTableProfiles-ne4}).Count-eq0);
   databaseAbsence=$true;trustRestored=$true;configurationRestored=$true;postPins=$true
  }|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 } else {
  if(Test-Path -LiteralPath $journal){throw 'CONSTRUCTOR_METADATA_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();witnesses=@();trust=@();trustBefore=$null;trustSnapshotCaptured=$false;observedTarget=$null;configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()};failure=$null}
  Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $ledger['preflight']=@(Invoke-ReleaseSql $control 'SELECT @@VERSION Version; SELECT name,state_desc FROM sys.databases ORDER BY database_id;' -Rows)
  $ledger.observedTarget=Read-ConstructorMetadataTarget $control
  $ledger.trustBefore=Read-ConstructorMetadataTrust $control;$ledger.trustSnapshotCaptured=$true;Save-ReleaseJournal
  $stage='CONFIGURATION';Start-ClrCallerConfiguration $control
  $stage='TRUST'
  foreach($a in $runset.artifacts){
   $hash=[Convert]::FromHexString($a.sha512);$before=Get-ClrCallerTrust $control $hash
   $entry=[ordered]@{hash=$a.sha512;preexisting=($null -ne $before);fingerprint=$null;state='PREEXISTING';description=$null}
   if($before){$entry.fingerprint=$before.Fingerprint}
   $ledger.trust+=@($entry);Save-ReleaseJournal
   if(-not $before){
    Assert-ClrCallerTrustCleanupScope $control $hash
    $entry.state='ADDING';$entry.description='Contoso constructor metadata '+$ledger.owner+' '+$a.sql_name;Save-ReleaseJournal
    Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$hash;'@Description'=$entry.description}
    $actual=Get-ClrCallerTrust $control $hash
    if($null -eq $actual -or $actual.description -cne $entry.description){throw 'CONSTRUCTOR_METADATA_TRUST_OWNERSHIP_UNKNOWN'}
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
   if($id.Count -ne 1){throw 'CONSTRUCTOR_METADATA_DATABASE_IDENTITY'}
   $entry.id=$id[0].Id;$entry.created=$id[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal
   Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $stage='INSTALL_'+$mode
   Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   $expected=@($runset.module_versions.PSObject.Properties)
   if(-not $expected.Count -or $markers.Count -ne $expected.Count){throw 'CONSTRUCTOR_METADATA_CLOSURE_MISMATCH'}
   foreach($module in $expected){
    if($module.Name -cnotmatch '^toolbelt\.[a-z0-9.-]+$' -or [string]$module.Value -cnotmatch '^\d+\.\d+\.\d+$' -or
     @($markers|Where-Object { $_.name -ceq ('Toolbelt.Module.'+$module.Name+'.Version') -and $_.Value -ceq [string]$module.Value }).Count -ne 1){throw 'CONSTRUCTOR_METADATA_CLOSURE_MISMATCH'}
   }
   $assemblies=@(Invoke-ReleaseSql $db "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;" -Rows)
   if($assemblies.Count -ne 2){throw 'CONSTRUCTOR_METADATA_ASSEMBLY_COUNT'}
   foreach($a in $runset.artifacts){if(@($assemblies|Where-Object {$_.name -ceq $a.sql_name -and $_.Hash -ceq $a.sha512 -and $_.Permission -ceq 'SAFE_ACCESS'}).Count -ne 1){throw 'CONSTRUCTOR_METADATA_INSTALLED_ASSEMBLY_DRIFT'}}
   $definitions="SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash,a.assembly_id,a.assembly_class,a.assembly_method FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id LEFT JOIN sys.assembly_modules a ON a.object_id=o.object_id WHERE o.is_ms_shipped=0 ORDER BY o.object_id;"
   $before=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   $db.Dispose();$stage='CONTRACT_'+$mode
   $db=Open-ReleaseConnection $name
   $witness=@(Invoke-ConstructorClientMetadata $db)
   if($witness.Count-ne1-or$witness[0].state-cne'COMPLETE'-or$witness[0].profiles-ne16-or$witness[0].selectProfiles-ne8-or$witness[0].helpProfiles-ne4-or$witness[0].resultTableProfiles-ne4){throw 'CONSTRUCTOR_METADATA_WITNESS'}
   $ledger.witnesses+=@(@{mode=$mode;metadata=$witness[0]});Save-ReleaseJournal
   $session=@(Invoke-ReleaseSql $db 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
   if($session.Count -ne 1 -or $session[0].TranCount -ne 0 -or $session[0].XactState -ne 0){throw 'CONSTRUCTOR_CLIENT_METADATA_SESSION_NOT_NEUTRAL'}
   $afterAssemblies=@(Invoke-ReleaseSql $db "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;" -Rows)
   if(($assemblies|Sort-Object name|ConvertTo-Json -Depth 4 -Compress) -cne ($afterAssemblies|Sort-Object name|ConvertTo-Json -Depth 4 -Compress)){throw 'CONSTRUCTOR_METADATA_ASSEMBLY_POST_DRIFT'}
   $after=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   if($before -cne $after){throw 'CONSTRUCTOR_METADATA_PRODUCT_OBJECT_DRIFT'}
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
    if($entry.preexisting){if($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint){throw 'CONSTRUCTOR_METADATA_PREEXISTING_TRUST_DRIFT'};continue}
    if($entry.state -cne 'OWNED' -or $null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint -or $actual.description -cne $entry.description){throw 'CONSTRUCTOR_METADATA_TRUST_CLEANUP_IDENTITY'}
    Assert-ClrCallerTrustCleanupScope $control $hash
    Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
    if($null -ne (Get-ClrCallerTrust $control $hash)){throw 'CONSTRUCTOR_METADATA_TRUST_NOT_REMOVED'}
    $entry.state='REMOVED';Save-ReleaseJournal
   }
   Restore-ClrCallerConfiguration $control
   if($ledger.trustSnapshotCaptured-and(Read-ConstructorMetadataTrust $control)-cne$ledger.trustBefore){throw 'CONSTRUCTOR_METADATA_FOREIGN_TRUST_DRIFT'}
   $ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  } catch {$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally {if($control){$control.Dispose()}}
 }
}
if($failure){if($ValidateOnly){throw $failure};Write-Output 'FAIL CONSTRUCTOR_METADATA_RIGHTS; inspect private journal; never replay without reconciliation';exit 1}
if($AuditOnly){'PASS CONSTRUCTOR_METADATA_RIGHTS independent input/absence audit'}else{'PASS CONSTRUCTOR_METADATA_RIGHTS local/direct-central; independent audit required'}
