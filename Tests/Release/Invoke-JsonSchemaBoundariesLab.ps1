# Five direct Core lifecycle boundaries; current known Core binary only.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='ADMISSION'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'SCHEMA_BOUNDARY_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'SCHEMA_BOUNDARY_HELPER_AMBIGUOUS'};. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
function Get-JsonSchemaSessionServerSnapshot($Control){
 $sql="SELECT configuration_id,name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations ORDER BY configuration_id; SELECT CONVERT(varchar(128),hash,2) Hash,description,create_date,created_by FROM sys.trusted_assemblies ORDER BY hash;"
 return (@(Invoke-ReleaseSql $Control $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
# Hash trust only for the already source-/package-checked release binaries.
function Start-CoreLockTrust($Control){
 $ready=@(Invoke-ReleaseSql $Control "SELECT CONVERT(int,value_in_use) Effective FROM sys.configurations WHERE name=N'clr enabled';" -Rows)
 if($ready.Count-ne1-or$ready[0].Effective-ne1){throw 'JSON_INSTALLED_CLR_MUST_ALREADY_BE_ENABLED'}
 foreach($file in @($binary,$coreBinary)){
  $hash=(Get-FileHash -LiteralPath $file -Algorithm SHA512).Hash
  $existing=Get-ClrCallerTrust $Control ([Convert]::FromHexString($hash))
  $entry=[ordered]@{hash=$hash;preexisting=($null-ne$existing);fingerprint=$null;state='PREEXISTING';description=$null}
  if($existing){$entry.fingerprint=$existing.Fingerprint};$ledger.trust+=@($entry);Save-ReleaseJournal
  if(-not$existing){
   Assert-ClrCallerTrustCleanupScope $Control ([Convert]::FromHexString($hash))
   $entry.description='Contoso Core Lock '+$ledger.owner;$entry.state='ADDING';Save-ReleaseJournal
   Invoke-ReleaseSql $Control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description;EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=[Convert]::FromHexString($hash);'@Description'=$entry.description}
   $actual=Get-ClrCallerTrust $Control ([Convert]::FromHexString($hash))
   if($null-eq$actual-or$actual.description-cne$entry.description){throw 'JSON_INSTALLED_TRUST_OWNERSHIP_UNKNOWN'}
   $entry.fingerprint=$actual.Fingerprint;$entry.state='OWNED';Save-ReleaseJournal
  }
 }
}
function Stop-CoreLockTrust($Control){
 foreach($entry in $ledger.trust){
  $hash=[Convert]::FromHexString($entry.hash);$actual=Get-ClrCallerTrust $Control $hash
  if($entry.preexisting){if($null-eq$actual-or$actual.Fingerprint-cne$entry.fingerprint){throw 'JSON_INSTALLED_PREEXISTING_TRUST_DRIFT'};continue}
  if($null-eq$actual-and$entry.state-in@('PREEXISTING','ADDING')){$entry.state='ABSENT';Save-ReleaseJournal;continue}
  if($entry.state-cne'OWNED'-or$null-eq$actual-or$actual.Fingerprint-cne$entry.fingerprint-or$actual.description-cne$entry.description){throw 'JSON_INSTALLED_TRUST_CLEANUP_IDENTITY'}
  Assert-ClrCallerTrustCleanupScope $Control $hash
  Invoke-ReleaseSql $Control 'DECLARE @H varbinary(64)=@Hash;EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
  if($null-ne(Get-ClrCallerTrust $Control $hash)){throw 'JSON_INSTALLED_TRUST_NOT_REMOVED'}
  $entry.state='REMOVED';Save-ReleaseJournal
 }
}

function Assert-JsonSchemaSessionFixtureScope([string]$Text){
 if($Text-match'(?i)\b(GRANT|DENY|REVOKE|TRUSTWORTHY|sp_configure|sp_add_trusted_assembly)\b|CREATE\s+(USER|LOGIN|ASSEMBLY)|ALTER\s+(AUTHORIZATION|DATABASE)|ALL\s+SERVER'){
  throw 'SCHEMA_BOUNDARY_FIXTURE_EXCEEDS_SCOPE'
 }
}
try{
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version-cne'json-schema-five-boundaries/v1'-or$runset.cases.Count-ne12-or
  $runset.explicit_qualification_approved-isnot[bool]-or$runset.explicit_qualification_approved-ne$true){throw 'SCHEMA_BOUNDARY_RUNSET_SCOPE'}
 $started=[DateTimeOffset]::Parse($runset.started_utc);$deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 if($deadline-ne$started.AddMinutes(45)-or$started-gt[DateTimeOffset]::UtcNow-or
  (-not$AuditOnly-and[DateTimeOffset]::UtcNow.AddMinutes(7)-ge$deadline)){throw 'SCHEMA_BOUNDARY_ADMISSION_CLOSED'}
 $expected=@('windows/2019/CU32/150','windows/2022/CU26/150','windows/2022/CU26/160','windows/2025/CU8/150','windows/2025/CU8/160','windows/2025/CU8/170','linux/2019/latest/150','linux/2022/latest/150','linux/2022/latest/160','linux/2025/latest/150','linux/2025/latest/160','linux/2025/latest/170')
 for($i=0;$i-lt12;$i++){
  $c=$runset.cases[$i];$tuple=[string]$c.Platform+'/'+$c.Version+'/'+$c.Patch+'/'+$c.CL
  $modes='local,central'
  if($tuple-cne$expected[$i]-or(@($c.modes)-join',')-cne$modes){throw 'SCHEMA_BOUNDARY_CONTEXT_SCOPE'}
 }
 $case=$runset.cases[$CaseIndex];Assert-ReleaseInputs
 $fixtureRoot=Join-Path $PSScriptRoot 'Runtime'
 $fixtureNames=@('JsonSchema.Boundaries.Contract.ps1')
 $fixtures=@($fixtureNames|ForEach-Object{Join-Path $fixtureRoot $_})
 $repeatDependencies=@((Join-Path $PSScriptRoot 'Invoke-JsonSchemaUninstallAppLockLab.ps1'),(Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'),(Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),(Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-JsonSchemaCallerTransactionLab.ps1'),(Join-Path $repo 'Deployment/Deploy-All.ps1'))

 if(($runset.fixtures-join'|')-cne($fixtures-join'|')){throw 'SCHEMA_BOUNDARY_CANONICAL_FIXTURES_REQUIRED'}
 foreach($path in @($PSCommandPath,$runset.exports.local,$runset.exports.central,$runset.uninstall,$runset.artifact.path,$runset.core_artifact.path,$runset.baselines.local,$runset.baselines.central,$runset.provenance,$runset.package)+$fixtures+$repeatDependencies+@(
  (Join-Path $PSScriptRoot 'Runtime/JsonCore.Lock.Contract.ps1'),
 (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'SCHEMA_BOUNDARY_REQUIRED_PIN_MISSING'}
 }
 foreach($fixture in $fixtures){ Assert-JsonSchemaSessionFixtureScope ([IO.File]::ReadAllText($fixture)) }
 $q=Get-Content $runset.provenance -Raw|ConvertFrom-Json -DateKind String
 if($runset.provenance-cne(Join-Path $repo 'Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json')-or$q.status-cne'PASS'-or
  $runset.package-cne(Join-Path $repo $q.package.path)-or(Get-FileHash $runset.package).Hash-ine$q.package.sha256){throw 'SCHEMA_BOUNDARY_PACKAGE_PROVENANCE'}
 $binary=Assert-ReleasePrivatePath $runset.artifact.path
 $coreBinary=Assert-ReleasePrivatePath $runset.core_artifact.path
 if((Get-FileHash $binary).Hash-ine$q.binaries.'Toolbelt.JsonSchema.dll'.sha256-or(Get-FileHash $coreBinary).Hash-ine$q.binaries.'Toolbelt.JsonCore.dll'.sha256){throw 'SCHEMA_BOUNDARY_DLL_PROVENANCE'}

 . (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')
 $registryPath=Join-Path $repo 'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'
 if(@($runset.pins|Where-Object path -CEQ $registryPath).Count-ne1){throw 'JSON_INSTALLED_REGISTRY_PIN_REQUIRED'}
 $registry=Get-Content -LiteralPath $registryPath -Raw|ConvertFrom-Json
 if($registry.status-cne'OFFLINE_QUALIFIED_KNOWN_ARTIFACTS'){throw 'JSON_INSTALLED_REGISTRY_STATUS'}
 foreach($module in @('toolbelt.json.core','toolbelt.json.schema')){
  $rows=@($registry.artifacts|Where-Object{$_.Fields.moduleId-ceq$module})
  if($rows.Count-ne1){throw 'JSON_INSTALLED_CLOSURE_ROW'};$fields=$rows[0].Fields
  $file=if($module-ceq'toolbelt.json.core'){$coreBinary}else{$binary}
  if((Get-FileHash $file).Hash-ine$fields.binarySha256-or(Get-FileHash $file -Algorithm SHA512).Hash-ine$fields.binarySha512){throw 'JSON_INSTALLED_KNOWN_BINARY_REQUIRED'}
  $sourceRoot=Join-Path $repo ('Modules/'+$module+'/Clr')
  $project=Join-Path $sourceRoot ($fields.managedAssembly+'.csproj')
  if(@($runset.pins|Where-Object path -CEQ $project).Count-ne1-or(Get-FileHash $project).Hash-ine$fields.projectSha256){throw 'JSON_INSTALLED_PROJECT_BINDING'}
  foreach($property in @($fields.PSObject.Properties|Where-Object{$_.Name.StartsWith('source/',[StringComparison]::Ordinal)})){
   $path=Join-Path $sourceRoot $property.Name.Substring(7)
   if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1-or(Get-FileHash $path).Hash-ine$property.Value){throw 'JSON_INSTALLED_COMPILED_SOURCE_BINDING'}
  }
 }
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Deployment/Deploy-All.ps1') @('Get-SqlcmdScriptTree','ConvertTo-StandaloneSql')){. $block}

 function Assert-CoreNodePin($Node){if(@($runset.pins|Where-Object path -CEQ $Node.Path).Count-ne1){throw 'SCHEMA_BOUNDARY_INCLUDE_PIN_REQUIRED'};foreach($child in $Node.Children){Assert-CoreNodePin $child}}
 foreach($mode in @('local','central')){
  $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo 'Modules/toolbelt.json.schema/Deployment/Deploy.sql');Assert-CoreNodePin $tree
  $canonical=ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode=$mode;AssemblyBits=('0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($binary)))} -ModulesRoot (Join-Path $repo 'Modules')
  if([IO.File]::ReadAllText($runset.exports.$mode)-cne$canonical){throw 'SCHEMA_BOUNDARY_ORIGINAL_DEPLOY_REQUIRED'}
 }
 $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo 'Modules/toolbelt.json.schema/Deployment/Uninstall.sql');Assert-CoreNodePin $tree
 $canonical=ConvertTo-StandaloneSql -Node $tree -Values @{ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules')
 if([IO.File]::ReadAllText($runset.uninstall)-cne$canonical){throw 'SCHEMA_BOUNDARY_ORIGINAL_UNINSTALL_REQUIRED'}
 $specs=@(@{id='mode-upper';operation='deploy';variable='DeploymentMode';value='LOCAL'},
 @{id='mode-space';operation='deploy';variable='DeploymentMode';value=' local '},
 @{id='confirm-invalid';operation='uninstall';variable='ConfirmNoExternalConsumers';value='2'},
 @{id='confirm-space';operation='uninstall';variable='ConfirmNoExternalConsumers';value=' 1'},
 @{id='central-unconfirmed';operation='uninstall';variable='ConfirmNoExternalConsumers';value='0'},
 @{id='confirm-leading-zero';operation='uninstall';variable='ConfirmNoExternalConsumers';value='01'})
 if($runset.argument_scripts.Count-ne6){throw 'SCHEMA_BOUNDARY_ARGUMENT_CLOSURE'}
 for($i=0;$i-lt6;$i++){
  $spec=$specs[$i];$row=$runset.argument_scripts[$i]
  if($row.id-cne$spec.id-or$row.operation-cne$spec.operation-or$row.value-cne$spec.value-or@($runset.pins|Where-Object path -CEQ $row.path).Count-ne1){throw 'SCHEMA_BOUNDARY_ARGUMENT_IDENTITY'}
  $name=if($spec.operation-ceq'deploy'){'Deploy.sql'}else{'Uninstall.sql'}
  $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo ('Modules/toolbelt.json.schema/Deployment/'+$name));Assert-CoreNodePin $tree
  $values=@{};$values[$spec.variable]=$spec.value;if($spec.operation-ceq'deploy'){$values['AssemblyBits']='0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($binary))}
  $text=ConvertTo-StandaloneSql -Node $tree -Values $values -ModulesRoot (Join-Path $repo 'Modules')
  if([IO.File]::ReadAllText($row.path)-cne$text){throw 'SCHEMA_BOUNDARY_ORIGINAL_ARGUMENT_SCRIPT'}
 }

 foreach($mode in @('local','central')){
  $parts=@()
  foreach($dependency in @('toolbelt.core.result-table','toolbelt.json.core')){
   $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo ('Modules/'+$dependency+'/Deployment/Deploy.sql'));Assert-CoreNodePin $tree
   $parts+=@(ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode=$mode;AssemblyBits=('0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($coreBinary)))} -ModulesRoot (Join-Path $repo 'Modules'))
  }
  if([IO.File]::ReadAllText($runset.baselines.$mode)-cne($parts-join"`nGO`n")){throw 'SCHEMA_BOUNDARY_CANONICAL_DEPENDENCIES_REQUIRED'}
 }
 . ($fixtures[0])
 $script:schemaBoundaryExcluded=@(Get-SchemaBoundaryReusedKeys)

 if($ValidateOnly){'PASS SCHEMA_BOUNDARY_OFFLINE_ADMISSION; no Lab import or SQL';return}
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash-cne$runset.contract_sha256){throw 'SCHEMA_BOUNDARY_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count-ne1){throw 'SCHEMA_BOUNDARY_EXACT_TARGET_REQUIRED'};$target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $hash=(Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -DateKind String
  if($prior.state-cnotin@('COMPLETE','FAILED_CLEANED')-or$prior.owner-cnotmatch'^[a-f0-9]{32}$'){throw 'SCHEMA_BOUNDARY_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $now=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform;" -Rows)
  if($now.Count-ne1-or$now[0].Major-ne$prior.observedTarget.Major-or$now[0].Version-cne$prior.observedTarget.Version-or$now[0].Platform-cne$prior.observedTarget.Platform){throw 'SCHEMA_BOUNDARY_AUDIT_TARGET_DRIFT'}
  foreach($entry in $prior.databases){
   if($entry.name-cne('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix)-or$entry.state-cne'DROPPED'){throw 'SCHEMA_BOUNDARY_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count-ne1-or$rows[0].Id-isnot[DBNull]){throw 'SCHEMA_BOUNDARY_AUDIT_DATABASE_PRESENT'}
  }
  if($prior.serverSnapshot-and(Get-JsonSchemaSessionServerSnapshot $control)-cne$prior.serverSnapshot){throw 'SCHEMA_BOUNDARY_FOREIGN_SERVER_DRIFT'}
  Assert-ReleaseInputs
  if((Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash-cne$hash){throw 'SCHEMA_BOUNDARY_AUDIT_JOURNAL_DRIFT'}
  [IO.File]::WriteAllText(($journal+'.audit.json'),([ordered]@{state='COMPLETE';readOnly=$true;
   originalJournalSHA256=$hash;originalRunPassed=($prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and
    (@($prior.completedModes)-join',')-ceq'local,central'-and$prior.witnesses.Count-eq2-and
    (Test-SchemaBoundaryCoverage $prior.profileCompletions $script:schemaBoundaryExcluded));databaseAbsence=$true;
   serverConfigurationAndTrustUnchanged=$true;postPins=$true}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 }else{
  if(Test-Path -LiteralPath $journal){throw 'SCHEMA_BOUNDARY_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();witnesses=@();fixtureCompletions=@();profileCompletions=@();results=@();trust=@();configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()};definitionSnapshots=@();serverSnapshot=$null;observedTarget=$null;failure=$null};Save-ReleaseJournal
  $ledger['declaredScope']=if($script:schemaBoundaryExcluded.Count){'UNEXECUTED_TAIL_ONLY'}else{'FULL_FIVE_POINT_PAIR'}
  $ledger['excludedOriginalProfiles']=@($script:schemaBoundaryExcluded);Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count-ne1-or$actual[0].Major-ne@{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version]-or$actual[0].Platform-ine$case.Platform-or$actual[0].Admin-ne1){throw 'SCHEMA_BOUNDARY_ACTUAL_TARGET_MISMATCH'}
  [void]@(Invoke-ReleaseSql $control 'SELECT @@VERSION Version; SELECT name,state_desc FROM sys.databases ORDER BY database_id;' -Rows)
  $ledger.observedTarget=$actual[0];$ledger.serverSnapshot=Get-JsonSchemaSessionServerSnapshot $control;Save-ReleaseJournal;Start-ClrCallerConfiguration $control;Start-CoreLockTrust $control
  foreach($mode in $case.modes){
   $stage='CREATE_'+$mode;$suffix=if($mode-ceq'local'){'l'}else{'c'};$name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'};$ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($identity.Count-ne1){throw 'SCHEMA_BOUNDARY_DATABASE_IDENTITY'};$entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal;Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $actualCl=@(Invoke-ReleaseSql $db 'SELECT compatibility_level CL FROM sys.databases WHERE database_id=DB_ID();' -Rows)
   if($actualCl.Count-ne1-or$actualCl[0].CL-ne$case.CL){throw 'SCHEMA_BOUNDARY_ACTUAL_CL'}
   $stage='SCHEMA_FIVE_BOUNDARIES_'+$mode
   Invoke-SchemaBoundaryProfiles $db $mode
   $state=@(Invoke-ReleaseSql $db 'DECLARE @Tc int=@@TRANCOUNT,@Xs smallint=XACT_STATE();SELECT @Tc TranCount,@Xs XactState;' -Rows)
   if($state.Count-ne1-or$state[0].TranCount-ne0-or$state[0].XactState-ne0){throw 'SCHEMA_BOUNDARY_NOT_NEUTRAL'}
   if([int](@(Invoke-ReleaseSql $db "SELECT COUNT(*) N FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema';" -Rows)[0].N)-ne0){throw 'SCHEMA_BOUNDARY_ASSEMBLY_NOT_REMOVED'}
   $ledger.witnesses+=@(@{mode=$mode;fixtures=$fixtureNames;compatibilityLevel=$actualCl[0].CL;transactionNeutral=$true;moduleAbsent=$true});Save-ReleaseJournal
   $ledger.completedModes+=@($mode);Save-ReleaseJournal;$db.Dispose()
  }
  Assert-ReleaseInputs
 }
}catch{$failure=$_.Exception;if($ledger-and-not$AuditOnly){$ledger.failure=@{stage=$stage;privateDiagnostic=$failure.Message;privatePosition=$_.ScriptStackTrace};Save-ReleaseJournal}}
finally{
 foreach($connection in $connections){try{$connection.Dispose()}catch{}};[Data.SqlClient.SqlConnection]::ClearAllPools()
 if($ledger-and-not$AuditOnly){
  $cleanup=$true
  try{
   $control=Open-ReleaseConnection 'master'
   foreach($entry in $ledger.databases){Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal}
   Stop-CoreLockTrust $control;Restore-ClrCallerConfiguration $control
   if($ledger.serverSnapshot-and(Get-JsonSchemaSessionServerSnapshot $control)-cne$ledger.serverSnapshot){throw 'SCHEMA_BOUNDARY_FOREIGN_SERVER_DRIFT'}
   Assert-ReleaseInputs;$ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally{if($control){$control.Dispose()}}
 }
}
if($failure){if($ValidateOnly){throw $failure};'FAIL SCHEMA_BOUNDARY_TARGETS; inspect private journal; no automatic replay';exit 1}
if($AuditOnly){'PASS SCHEMA_BOUNDARY_TARGETS fresh independent final journal/absence audit'}else{'PASS SCHEMA_BOUNDARY five Schema lifecycle boundary groups; independent audit required'}
