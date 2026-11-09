# JSON-Schema: neue Uninstall-Callerprofile mit installierten aktuellen Modulen.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,0)][int]$CaseIndex,[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='ADMISSION'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'JSON_SCHEMA_INSTALLED_SESSION_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'JSON_SCHEMA_INSTALLED_SESSION_HELPER_AMBIGUOUS'};. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
function Get-JsonSchemaSessionServerSnapshot($Control){
 $sql="SELECT configuration_id,name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations ORDER BY configuration_id; SELECT CONVERT(varchar(128),hash,2) Hash,description,create_date,created_by FROM sys.trusted_assemblies ORDER BY hash;"
 return (@(Invoke-ReleaseSql $Control $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
# Hash trust only for the already source-/package-checked release binaries.
function Start-JsonInstalledTrust($Control){
 $ready=@(Invoke-ReleaseSql $Control "SELECT CONVERT(int,value_in_use) Effective FROM sys.configurations WHERE name=N'clr enabled';" -Rows)
 if($ready.Count-ne1-or$ready[0].Effective-ne1){throw 'JSON_INSTALLED_CLR_MUST_ALREADY_BE_ENABLED'}
 foreach($file in @($binary,$coreBinary)){
  $hash=(Get-FileHash -LiteralPath $file -Algorithm SHA512).Hash
  $existing=Get-ClrCallerTrust $Control ([Convert]::FromHexString($hash))
  $entry=[ordered]@{hash=$hash;preexisting=($null-ne$existing);fingerprint=$null;state='PREEXISTING';description=$null}
  if($existing){$entry.fingerprint=$existing.Fingerprint};$ledger.trust+=@($entry);Save-ReleaseJournal
  if(-not$existing){
   Assert-ClrCallerTrustCleanupScope $Control ([Convert]::FromHexString($hash))
   $entry.description='Contoso JsonSchema Installed Session '+$ledger.owner;$entry.state='ADDING';Save-ReleaseJournal
   Invoke-ReleaseSql $Control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description;EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=[Convert]::FromHexString($hash);'@Description'=$entry.description}
   $actual=Get-ClrCallerTrust $Control ([Convert]::FromHexString($hash))
   if($null-eq$actual-or$actual.description-cne$entry.description){throw 'JSON_INSTALLED_TRUST_OWNERSHIP_UNKNOWN'}
   $entry.fingerprint=$actual.Fingerprint;$entry.state='OWNED';Save-ReleaseJournal
  }
 }
}
function Stop-JsonInstalledTrust($Control){
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
  throw 'JSON_SCHEMA_INSTALLED_SESSION_FIXTURE_EXCEEDS_SCOPE'
 }
}
try{
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version-cne'json-schema-installed-session/v1'-or$runset.cases.Count-ne1-or
  $runset.explicit_qualification_approved-isnot[bool]-or$runset.explicit_qualification_approved-ne$true){throw 'JSON_SCHEMA_INSTALLED_SESSION_RUNSET_SCOPE'}
 $started=[DateTimeOffset]::Parse($runset.started_utc);$deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 if($deadline-ne$started.AddMinutes(45)-or$started-gt[DateTimeOffset]::UtcNow-or
  (-not$AuditOnly-and[DateTimeOffset]::UtcNow.AddMinutes(7)-ge$deadline)){throw 'JSON_SCHEMA_INSTALLED_SESSION_ADMISSION_CLOSED'}
 $expected=@('windows/2025/CU8/170')
 for($i=0;$i-lt1;$i++){
  $c=$runset.cases[$i];$tuple=[string]$c.Platform+'/'+$c.Version+'/'+$c.Patch+'/'+$c.CL
  $modes='local'
  if($tuple-cne$expected[$i]-or(@($c.modes)-join',')-cne$modes){throw 'JSON_SCHEMA_INSTALLED_SESSION_CONTEXT_SCOPE'}
 }
 $case=$runset.cases[$CaseIndex];Assert-ReleaseInputs
 $fixtureRoot=Join-Path $PSScriptRoot 'Runtime'
 $fixtureNames=@('JsonSchema.InstalledSession.Contract.ps1')
 $fixtures=@($fixtureNames|ForEach-Object{Join-Path $fixtureRoot $_})
 $repeatDependencies=@((Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'),(Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),(Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-JsonSchemaCallerTransactionLab.ps1'),(Join-Path $repo 'Deployment/Deploy-All.ps1'))

 if(($runset.fixtures-join'|')-cne($fixtures-join'|')){throw 'JSON_SCHEMA_INSTALLED_SESSION_CANONICAL_FIXTURES_REQUIRED'}
 foreach($path in @($PSCommandPath,$runset.baseline,$runset.core_artifact.path,$runset.scripts.deploy,$runset.scripts.uninstall,$runset.artifact.path,$runset.provenance,$runset.package)+$fixtures+$repeatDependencies+@(
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'JSON_SCHEMA_INSTALLED_SESSION_REQUIRED_PIN_MISSING'}
 }
 foreach($fixture in $fixtures){ Assert-JsonSchemaSessionFixtureScope ([IO.File]::ReadAllText($fixture)) }
 $q=Get-Content $runset.provenance -Raw|ConvertFrom-Json -DateKind String
 if($runset.provenance-cne(Join-Path $repo 'Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json')-or$q.status-cne'PASS'-or
  $runset.package-cne(Join-Path $repo $q.package.path)-or(Get-FileHash $runset.package).Hash-ine$q.package.sha256){throw 'JSON_SCHEMA_INSTALLED_SESSION_PACKAGE_PROVENANCE'}
 $binary=Assert-ReleasePrivatePath $runset.artifact.path
 if((Get-FileHash $binary).Hash-ine$q.binaries.'Toolbelt.JsonSchema.dll'.sha256){throw 'JSON_SCHEMA_INSTALLED_SESSION_DLL_PROVENANCE'}

 . (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')
 $coreBinary=Assert-ReleasePrivatePath $runset.core_artifact.path
 if((Get-FileHash $coreBinary).Hash-ine$q.binaries.'Toolbelt.JsonCore.dll'.sha256){throw 'JSON_INSTALLED_CORE_PROVENANCE'}
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
 foreach($operation in @('deploy','uninstall')){
  $source=Join-Path $repo ('Modules/toolbelt.json.schema/Deployment/'+@{deploy='Deploy.sql';uninstall='Uninstall.sql'}[$operation])
  $tree=Get-SqlcmdScriptTree -Path $source
  function Assert-SessionNodePin($Node){
   if(@($runset.pins|Where-Object path -CEQ $Node.Path).Count-ne1){throw 'JSON_SCHEMA_INSTALLED_SESSION_INCLUDE_PIN_REQUIRED'}
   foreach($child in $Node.Children){Assert-SessionNodePin $child}
  }
  Assert-SessionNodePin $tree
  $canonical=ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode='local';AssemblyBits=('0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($binary)));ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules')
  if([IO.File]::ReadAllText($runset.scripts.$operation)-cne$canonical){throw 'JSON_SCHEMA_INSTALLED_SESSION_ORIGINAL_FULL_SCRIPT_REQUIRED'}
 }

 $parts=@()
 foreach($module in @('toolbelt.core.result-table','toolbelt.json.core')){
  $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo ('Modules/'+$module+'/Deployment/Deploy.sql'));Assert-SessionNodePin $tree
  $parts+=@(ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode='local';AssemblyBits=('0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($coreBinary)))} -ModulesRoot (Join-Path $repo 'Modules'))
 }
 if([IO.File]::ReadAllText($runset.baseline)-cne($parts-join"`nGO`n")){throw 'JSON_INSTALLED_ORIGINAL_BASELINE_REQUIRED'}
 if($ValidateOnly){'PASS JSON_SCHEMA_INSTALLED_SESSION_OFFLINE_ADMISSION; no Lab import or SQL';return}
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash-cne$runset.contract_sha256){throw 'JSON_SCHEMA_INSTALLED_SESSION_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count-ne1){throw 'JSON_SCHEMA_INSTALLED_SESSION_EXACT_TARGET_REQUIRED'};$target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $hash=(Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -DateKind String
  if($prior.state-cnotin@('COMPLETE','FAILED_CLEANED')-or$prior.owner-cnotmatch'^[a-f0-9]{32}$'){throw 'JSON_SCHEMA_INSTALLED_SESSION_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $now=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform;" -Rows)
  if($now.Count-ne1-or$now[0].Major-ne$prior.observedTarget.Major-or$now[0].Version-cne$prior.observedTarget.Version-or$now[0].Platform-cne$prior.observedTarget.Platform){throw 'JSON_SCHEMA_INSTALLED_SESSION_AUDIT_TARGET_DRIFT'}
  foreach($entry in $prior.databases){
   if($entry.name-cne('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix)-or$entry.state-cne'DROPPED'){throw 'JSON_SCHEMA_INSTALLED_SESSION_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count-ne1-or$rows[0].Id-isnot[DBNull]){throw 'JSON_SCHEMA_INSTALLED_SESSION_AUDIT_DATABASE_PRESENT'}
  }
  if($prior.serverSnapshot-and(Get-JsonSchemaSessionServerSnapshot $control)-cne$prior.serverSnapshot){throw 'JSON_SCHEMA_INSTALLED_SESSION_FOREIGN_SERVER_DRIFT'}
  Assert-ReleaseInputs
  if((Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash-cne$hash){throw 'JSON_SCHEMA_INSTALLED_SESSION_AUDIT_JOURNAL_DRIFT'}
  [IO.File]::WriteAllText(($journal+'.audit.json'),([ordered]@{state='COMPLETE';readOnly=$true;
   originalJournalSHA256=$hash;originalRunPassed=($prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and
   (@($prior.completedModes)-join',')-ceq'local'-and$prior.witnesses.Count-eq1-and$prior.results.Count-eq3-and
   (@($prior.results|ForEach-Object{([int][bool]$_.xact_abort).ToString()+'/'+([int][bool]$_.nocount).ToString()})-join',')-ceq'0/1,1/0,1/1'-and
   @($prior.results|Where-Object{-not$_.blocked-or-not$_.exact_error-or-not$_.transaction_preserved-or-not$_.session_preserved-or-not$_.options_preserved-or-not$_.module_snapshot_preserved-or-not$_.witness_preserved-or-not$_.application_locks_absent-or$_.xact_abort-isnot[bool]-or$_.nocount-isnot[bool]-or-not$_.installed_module}).Count-eq0);databaseAbsence=$true;
   serverConfigurationAndTrustUnchanged=$true;postPins=$true}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 }else{
  if(Test-Path -LiteralPath $journal){throw 'JSON_SCHEMA_INSTALLED_SESSION_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();witnesses=@();fixtureCompletions=@();profileCompletions=@();results=@();trust=@();definitionSnapshots=@();serverSnapshot=$null;observedTarget=$null;failure=$null};Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count-ne1-or$actual[0].Major-ne@{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version]-or$actual[0].Platform-ine$case.Platform-or$actual[0].Admin-ne1){throw 'JSON_SCHEMA_INSTALLED_SESSION_ACTUAL_TARGET_MISMATCH'}
  [void]@(Invoke-ReleaseSql $control 'SELECT @@VERSION Version; SELECT name,state_desc FROM sys.databases ORDER BY database_id;' -Rows)
  $ledger.observedTarget=$actual[0];$ledger.serverSnapshot=Get-JsonSchemaSessionServerSnapshot $control;Save-ReleaseJournal;Start-JsonInstalledTrust $control
  foreach($mode in $case.modes){
   $stage='CREATE_'+$mode;$suffix=if($mode-ceq'local'){'l'}else{'c'};$name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'};$ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($identity.Count-ne1){throw 'JSON_SCHEMA_INSTALLED_SESSION_DATABASE_IDENTITY'};$entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal;Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $actualCl=@(Invoke-ReleaseSql $db 'SELECT compatibility_level CL FROM sys.databases WHERE database_id=DB_ID();' -Rows)
   if($actualCl.Count-ne1-or$actualCl[0].CL-ne$case.CL){throw 'JSON_SCHEMA_INSTALLED_SESSION_ACTUAL_CL'}
   $stage='INSTALL_CURRENT_BASELINE';Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.baseline));Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.scripts.deploy))
   $stage='SESSION_GUARDS';$observer=Open-ReleaseConnection 'master'
   . ($fixtures[0])
   Invoke-JsonSchemaInstalledSessionProfiles $db $observer
   if($ledger.results.Count-ne3){throw 'JSON_SCHEMA_INSTALLED_SESSION_THREE_ORIGINAL_RECEIPTS_REQUIRED'}
   $state=@(Invoke-ReleaseSql $db 'DECLARE @Tc int=@@TRANCOUNT,@Xs smallint=XACT_STATE();SELECT @Tc TranCount,@Xs XactState;' -Rows)
   if($state.Count-ne1-or$state[0].TranCount-ne0-or$state[0].XactState-ne0){throw 'JSON_SCHEMA_INSTALLED_SESSION_NOT_NEUTRAL'}
   if([int](Read-Scalar $db "SELECT CASE WHEN OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema',N'P') IS NOT NULL THEN 1 ELSE 0 END ScalarValue;")-ne1){throw 'JSON_INSTALLED_SCHEMA_REMOVED'}
   $ledger.witnesses+=@(@{mode=$mode;fixtures=$fixtureNames;compatibilityLevel=$actualCl[0].CL;transactionNeutral=$true;moduleInstalled=$true});Save-ReleaseJournal
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
   Stop-JsonInstalledTrust $control
   if($ledger.serverSnapshot-and(Get-JsonSchemaSessionServerSnapshot $control)-cne$ledger.serverSnapshot){throw 'JSON_SCHEMA_INSTALLED_SESSION_FOREIGN_SERVER_DRIFT'}
   Assert-ReleaseInputs;$ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally{if($control){$control.Dispose()}}
 }
}
if($failure){if($ValidateOnly){throw $failure};'FAIL JSON_SCHEMA_INSTALLED_SESSION_TARGETS; inspect private journal; no automatic replay';exit 1}
if($AuditOnly){'PASS JSON_SCHEMA_INSTALLED_SESSION_TARGETS fresh independent final journal/absence audit'}else{'PASS JSON_SCHEMA_INSTALLED_SESSION three new installed Uninstall guard profiles; independent audit required'}
