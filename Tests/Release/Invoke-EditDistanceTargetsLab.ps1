# Edit-Distance-Paket: fehlende physische API-Kontexte, vorhandene CLR-Schutzhelfer.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,7)][int]$CaseIndex,[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='PREPARE'
# Vorhandene begrenzte SQL-, Pin- und Ownership-Helfer ohne deren Teststart.
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path (Join-Path $repo 'Tests/Release') 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'CLR_CALLER_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($nodes.Count -ne 1){throw 'CLR_CALLER_HELPER_AMBIGUOUS'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path (Join-Path $repo 'Tests/Release') 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
. (Join-Path (Join-Path $repo 'Tests/Release') 'ClrCaller.Environment.ps1')
function Get-DistanceServerSnapshot($Control){
 $sql="SELECT configuration_id,name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations ORDER BY configuration_id; SELECT CONVERT(varchar(128),hash,2) Hash,description,create_date,created_by FROM sys.trusted_assemblies ORDER BY hash;"
 return (@(Invoke-ReleaseSql $Control $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
try {
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version -cne 'edit-distance-targets/v1' -or $runset.cases.Count -ne 8){throw 'CLR_CALLER_RUNSET_INVALID'}
 $case=$runset.cases[$CaseIndex]
 $expected=@('windows/2019/CU32/150','windows/2022/CU26/150','windows/2022/CU26/160',
  'linux/2022/latest/150','linux/2022/latest/160','linux/2025/latest/150','linux/2025/latest/160','linux/2025/latest/170')
 if($runset.explicit_qualification_approved-isnot[bool]-or-not$runset.explicit_qualification_approved){throw 'DISTANCE_AUTHORITY_REQUIRED'}
 $started=[DateTimeOffset]::Parse($runset.started_utc);$deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 if($deadline-ne$started.AddMinutes(45)-or$started-gt[DateTimeOffset]::UtcNow-or(-not$AuditOnly-and[DateTimeOffset]::UtcNow.AddMinutes(7)-ge$deadline)){throw 'DISTANCE_ADMISSION_CLOSED'}
 for($i=0;$i-lt8;$i++){
  $c=$runset.cases[$i]
  if(([string]$c.Platform+'/'+$c.Version+'/'+$c.Patch+'/'+$c.CL)-cne$expected[$i]){throw 'DISTANCE_TARGET_SCOPE'}
 }
 Assert-ReleaseInputs
 foreach($required in @($PSCommandPath,$runset.provenance,$runset.package,$runset.artifacts[0].path,$runset.exports.local,$runset.exports.central,
  (Join-Path (Join-Path $repo 'Tests/Release') 'Invoke-ApiQualificationLab.ps1'),(Join-Path (Join-Path $repo 'Tests/Release') 'Invoke-StablePackageLab.ps1'),
  (Join-Path (Join-Path $repo 'Tests/Release') 'ClrCaller.Environment.ps1'),(Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $required).Count -ne 1){throw 'CLR_CALLER_REQUIRED_PIN_MISSING'}
 }
 $fixtureRoot=Join-Path $repo 'Modules/toolbelt.string.edit-distance/Tests/Runtime'
 $fixtureNames=@('Distance.Contract.sql','Distance.Boundaries.sql','Jaro.Contract.sql','Jaro.Boundaries.sql','InstalledMetadata.Contract.sql','Lifecycle.Contract.sql')
 $fixtures=@($fixtureNames|ForEach-Object{Join-Path $fixtureRoot $_})
 if(($runset.fixtures-join'|')-cne($fixtures-join'|')){throw 'DISTANCE_CANONICAL_FIXTURES_REQUIRED'}
 foreach($fixture in $fixtures){
  if(@($runset.pins|Where-Object path -CEQ $fixture).Count-ne1){throw 'DISTANCE_FIXTURE_PIN_REQUIRED'}
  if([IO.File]::ReadAllText($fixture)-match'(?i)\b(GRANT|DENY|REVOKE|TRUSTWORTHY|sp_configure|sp_add_trusted_assembly)\b|CREATE\s+(USER|LOGIN|ASSEMBLY)|ALTER\s+(AUTHORIZATION|DATABASE)'){throw 'DISTANCE_FIXTURE_SCOPE'}
 }
 $q=Get-Content -LiteralPath $runset.provenance -Raw|ConvertFrom-Json -DateKind String
 if($runset.provenance-cne(Join-Path $repo 'Releases/1.0.0/EDIT-DISTANCE-PACKAGE-QUALIFICATION.json')-or$q.status-cne'PASS'-or$q.module.id-cne'toolbelt.string.edit-distance'-or$q.module.version-cne'1.1.0'-or
  $runset.package-cne(Join-Path $repo $q.package.path)-or(Get-FileHash $runset.package).Hash-ine$q.package.sha256-or$runset.artifacts.Count-ne1){throw 'DISTANCE_PACKAGE_PROVENANCE'}
 if(@($runset.module_versions.PSObject.Properties).Count-ne1-or$runset.module_versions.'toolbelt.string.edit-distance'-cne'1.1.0'){throw 'DISTANCE_MODULE_VERSION_SCOPE'}
 foreach($mode in @('local','central')){
  $export=[IO.File]::ReadAllText($runset.exports.$mode)
  $modules=@([regex]::Matches($export,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)\r?$')|ForEach-Object{$_.Groups[1].Value})
  if(($modules-join',')-cne'toolbelt.string.edit-distance'){throw 'DISTANCE_EXPORT_CLOSURE'}
 }
 $artifact=$runset.artifacts[0];$artifactPath=Assert-ReleasePrivatePath $artifact.path
 if($artifact.module_id-cne'toolbelt.string.edit-distance'-or$artifact.sql_name-cne'Toolbelt_String_EditDistance'-or$artifact.sha256-ine$q.module.assembly_sha256-or
  (Get-FileHash $artifactPath).Hash-cne$artifact.sha256-or(Get-FileHash $artifactPath -Algorithm SHA512).Hash-cne$artifact.sha512){throw 'DISTANCE_BINARY_PROVENANCE'}
 foreach($p in $q.module_source_sha256.PSObject.Properties){
  $path=Join-Path $repo $p.Name
  if((Get-FileHash $path).Hash-ine$p.Value-or@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'DISTANCE_ORIGINAL_SOURCE_DRIFT'}
 }
 if($ValidateOnly){'PASS DISTANCE_OFFLINE_ADMISSION; no Lab import or SQL';return}
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
  $journalHash=(Get-FileHash $journal).Hash
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -DateKind String
  if($prior.state -cnotin @('COMPLETE','FAILED_CLEANED') -or $prior.owner -cnotmatch '^[a-f0-9]{32}$') {throw 'CLR_CALLER_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $actualTarget=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform;" -Rows)
  if($actualTarget.Count-ne1-or$actualTarget[0].Major-ne$prior.observedTarget.Major-or$actualTarget[0].Version-cne$prior.observedTarget.Version-or$actualTarget[0].Platform-cne$prior.observedTarget.Platform){throw 'DISTANCE_AUDIT_TARGET_DRIFT'}
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
  if($prior.serverSnapshot-and(Get-DistanceServerSnapshot $control)-cne$prior.serverSnapshot){throw 'DISTANCE_AUDIT_SERVER_DRIFT'}
  if((Get-FileHash $journal).Hash-cne$journalHash){throw 'DISTANCE_AUDIT_JOURNAL_DRIFT'}
  [IO.File]::WriteAllText(($journal+'.audit.json'),([ordered]@{state='COMPLETE';readOnly=$true;originalJournalSHA256=$journalHash;
   originalRunPassed=($prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and(@($prior.completedModes)-join',')-ceq'local,central'-and$prior.witnesses.Count-eq2-and
   @($prior.witnesses|Where-Object{(@($_.fixtures)-join',')-cne($fixtureNames-join',')-or$_.compatibilityLevel-ne$case.CL-or$_.transactionNeutral-ne$true}).Count-eq0);
   databaseAbsence=$true;serverConfigurationAndTrustUnchanged=$true;postPins=$true}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 } else {
  if(Test-Path -LiteralPath $journal){throw 'CLR_CALLER_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();trust=@();configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()};serverSnapshot=$null;observedTarget=$null;witnesses=@();failure=$null}
  Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count -ne 1 -or $actual[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version] -or
   $actual[0].Platform -ine $case.Platform -or $actual[0].Admin -ne 1){throw 'CLR_CALLER_ACTUAL_TARGET_MISMATCH'}
  $ledger.observedTarget=$actual[0];$ledger.serverSnapshot=Get-DistanceServerSnapshot $control;Save-ReleaseJournal
  [void]@(Invoke-ReleaseSql $control 'SELECT @@VERSION Version; SELECT name,state_desc FROM sys.databases ORDER BY database_id;' -Rows)
  if($runset.artifacts.Count -ne 1){throw 'CLR_CALLER_ARTIFACT_SCOPE'}
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
   $actualCl=@(Invoke-ReleaseSql $db 'SELECT compatibility_level CL FROM sys.databases WHERE database_id=DB_ID();' -Rows)
   if($actualCl.Count-ne1-or$actualCl[0].CL-ne$case.CL){throw 'DISTANCE_ACTUAL_CL'}
   $stage='INSTALL_'+$mode
   Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   $expected=@($runset.module_versions.PSObject.Properties)
   if(-not $expected.Count -or $markers.Count -ne $expected.Count){throw 'CLR_CALLER_CLOSURE_MISMATCH'}
   foreach($module in $expected){
    if($module.Name -cnotmatch '^toolbelt\.[a-z0-9.-]+$' -or [string]$module.Value -cnotmatch '^\d+\.\d+\.\d+$' -or
     @($markers|Where-Object { $_.name -ceq ('Toolbelt.Module.'+$module.Name+'.Version') -and $_.Value -ceq [string]$module.Value }).Count -ne 1){throw 'CLR_CALLER_CLOSURE_MISMATCH'}
   }
   $modeRows=@(Invoke-ReleaseSql $db "SELECT CONVERT(nvarchar(128),value) Mode FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.string.edit-distance.DeploymentMode';" -Rows)
   if($modeRows.Count-ne1-or$modeRows[0].Mode-cne$mode){throw 'DISTANCE_MODE_MARKER'}
   $assemblies=@(Invoke-ReleaseSql $db "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;" -Rows)
   if($assemblies.Count -ne 1){throw 'CLR_CALLER_ASSEMBLY_COUNT'}
   foreach($a in $runset.artifacts){if(@($assemblies|Where-Object {$_.name -ceq $a.sql_name -and $_.Hash -ceq $a.sha512 -and $_.Permission -ceq 'SAFE_ACCESS'}).Count -ne 1){throw 'CLR_CALLER_INSTALLED_ASSEMBLY_DRIFT'}}
   $definitions="SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash,a.assembly_id,a.assembly_class,a.assembly_method FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id LEFT JOIN sys.assembly_modules a ON a.object_id=o.object_id WHERE o.is_ms_shipped=0 ORDER BY o.object_id;"
   $before=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   $db.Dispose();$stage='CONTRACT_'+$mode
   $db=Open-ReleaseConnection $name
   $completed=@()
   foreach($fixture in $fixtures){
    $stage='FIXTURE_'+$mode+'_'+[IO.Path]::GetFileName($fixture)
    $sql=[IO.File]::ReadAllText($fixture).Replace('$(ExpectedInstalledAssemblyHash)',('0x'+$runset.artifacts[0].sha512))
    if($sql.Contains('$(')){throw 'DISTANCE_UNRESOLVED_FIXTURE'}
    Invoke-ReleaseBatches $db $sql
    $session=@(Invoke-ReleaseSql $db 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
    if($session.Count-ne1-or$session[0].TranCount-ne0-or$session[0].XactState-ne0){throw 'DISTANCE_SESSION_NOT_NEUTRAL'}
    $completed+=@([IO.Path]::GetFileName($fixture))
   }
   if(($completed-join',')-cne($fixtureNames-join',')){throw 'DISTANCE_INCOMPLETE_FIXTURES'}
   $ledger.witnesses+=@(@{mode=$mode;compatibilityLevel=$actualCl[0].CL;fixtures=$completed;transactionNeutral=$true});Save-ReleaseJournal
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
   if($ledger.serverSnapshot-and(Get-DistanceServerSnapshot $control)-cne$ledger.serverSnapshot){throw 'DISTANCE_SERVER_RESTORE_DRIFT'}
   $ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  } catch {$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally {if($control){$control.Dispose()}}
 }
}
if($failure){if($ValidateOnly){throw $failure};Write-Output 'FAIL CLR_CALLER_RIGHTS; inspect private journal; never replay without reconciliation';exit 1}
if($AuditOnly){'PASS DISTANCE_TARGETS independent final journal/absence audit'}else{'PASS DISTANCE_TARGETS eight selected targets local/direct-central; independent audit required'}
