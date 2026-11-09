# Split: echte minimale SQL-Netzwerkanmeldung mit zwei eigenen SID-Mappings.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,0)][int]$CaseIndex,[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='ADMISSION'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'SPLIT_MAPPED_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'SPLIT_MAPPED_HELPER_AMBIGUOUS'};. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
function Get-SplitMappedServerSnapshot($Control){
 $sql="SELECT configuration_id,name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations ORDER BY configuration_id; SELECT CONVERT(varchar(128),hash,2) Hash,description,create_date,created_by FROM sys.trusted_assemblies ORDER BY hash;"
 return (@(Invoke-ReleaseSql $Control $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Get-SplitMappedText([string]$Mode){
 $base=Join-Path $repo 'Modules/toolbelt.string.split-advanced/Deployment'
 $moduleRoot=[IO.Path]::GetFullPath((Join-Path $base '..'))+[IO.Path]::DirectorySeparatorChar
 function Expand-SplitMapped([string]$Path,[string[]]$Stack=@()){
  $full=[IO.Path]::GetFullPath($Path)
  if(-not$full.StartsWith($moduleRoot,[StringComparison]::OrdinalIgnoreCase)-or$Stack-contains$full){throw 'SPLIT_MAPPED_INCLUDE_OUTSIDE_OR_CYCLE'}
  # Wie Get-SqlcmdScriptTree: Zeilen einlesen, Dateiende nicht doppelt einbetten.
  $text=[IO.File]::ReadAllLines($full) -join "`n"
  return [regex]::Replace($text,'(?m)^[ \t]*:r[ \t]+([^\r\n]+)[ \t]*\r?$',{
   param($m)
   $name=$m.Groups[1].Value.Trim()
   if($name.Contains('$(')){throw 'SPLIT_MAPPED_DYNAMIC_INCLUDE'}
   Expand-SplitMapped (Join-Path $base $name) ($Stack+@($full))
  })
 }
 $text=Expand-SplitMapped (Join-Path $base 'Deploy.sql')
 # Dieselbe LF-Normalisierung wie der kanonische Erstinstallations-Export.
 return $text.Replace('$(DeploymentMode)',$Mode).Replace("`r`n","`n").Replace("`r","`n")
}
function Assert-SplitMappedFixtureScope([string]$Text){
 if($Text-match'(?i)\b(DENY|TRUSTWORTHY\s+ON|sp_configure|sp_add_trusted_assembly|IMPERSONATE)\b|CREATE\s+ASSEMBLY|ALTER\s+(AUTHORIZATION|SERVER\s+ROLE|ROLE)|ALL\s+SERVER'){
  throw 'SPLIT_MAPPED_FIXTURE_EXCEEDS_SCOPE'
 }
 foreach($match in [regex]::Matches($Text,'(?im)(?<![\w.@])(?:GRANT|REVOKE)[\t ]+[^;"\r\n]+')){
  $op=[regex]::Replace($match.Value.Trim(),'[\t ]+',' ')
  if($op-notmatch'^GRANT CONNECT TO \[\$login\]$'-and
     $op-notmatch'^GRANT SELECT ON OBJECT::toolbelt_string\.TVF_SplitAdvanced TO \[\$login\]$'-and
     $op-notmatch'^REVOKE SELECT ON OBJECT::toolbelt_string\.TVF_SplitAdvanced FROM \[\$login\]$'){
   throw 'SPLIT_MAPPED_RIGHT_SET_EXCEEDED'
  }
 }
 foreach($match in [regex]::Matches($Text,'(?im)\bCREATE[\t ]+USER[\t ]+[^;"\r\n]+')){
  if([regex]::Replace($match.Value.Trim(),'[\t ]+',' ')-notmatch'^CREATE USER \[\$login\] FOR LOGIN \[\$login\]$'){throw 'SPLIT_MAPPED_FOREIGN_USER_SCOPE'}
 }
 if($Text-match'(?im)\bCREATE[\t ]+LOGIN[\t ]+(?![''"])\S'){throw 'SPLIT_MAPPED_FOREIGN_LOGIN_SCOPE'}
}
try{
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version-cne'split-advanced-mapped-caller/v1'-or$runset.cases.Count-ne1-or
  $runset.explicit_qualification_approved-isnot[bool]-or$runset.explicit_qualification_approved-ne$true){throw 'SPLIT_MAPPED_RUNSET_SCOPE'}
 $started=[DateTimeOffset]::Parse($runset.started_utc);$deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 if($deadline-ne$started.AddMinutes(45)-or$started-gt[DateTimeOffset]::UtcNow-or
  (-not$AuditOnly-and[DateTimeOffset]::UtcNow.AddMinutes(7)-ge$deadline)){throw 'SPLIT_MAPPED_ADMISSION_CLOSED'}
 $expected=@('windows/2025/CU8/170')
 for($i=0;$i-lt1;$i++){
  $c=$runset.cases[$i];$tuple=[string]$c.Platform+'/'+$c.Version+'/'+$c.Patch+'/'+$c.CL
  if($tuple-cne$expected[$i]-or(@($c.modes)-join',')-cne'central'){throw 'SPLIT_MAPPED_CONTEXT_SCOPE'}
 }
 if($runset.temporary_identity_rights_approved-isnot[bool]-or$runset.temporary_identity_rights_approved-ne$true-or
  (@($runset.database_right_set)-join',')-cne'CONNECT consumer,CONNECT installation,SELECT installation.toolbelt_string.TVF_SplitAdvanced'){throw 'SPLIT_MAPPED_RIGHTS_AUTHORITY'}
 $case=$runset.cases[$CaseIndex];Assert-ReleaseInputs
 $fixtureRoot=Join-Path $PSScriptRoot 'Runtime'
 $fixtureNames=@('SplitAdvanced.MappedCaller.Contract.ps1')
 $fixtures=@($fixtureNames|ForEach-Object{Join-Path $fixtureRoot $_})
 $repeatDependencies=@((Join-Path $repo 'Modules/toolbelt.string.split-advanced/Deployment/Uninstall.sql'),(Join-Path $PSScriptRoot 'Runtime/SplitAdvanced.LifecycleProfiles.Contract.ps1'))

 if(($runset.fixtures-join'|')-cne($fixtures-join'|')){throw 'SPLIT_MAPPED_CANONICAL_FIXTURES_REQUIRED'}
 foreach($path in @($PSCommandPath,$runset.exports.local,$runset.exports.central)+$fixtures+$repeatDependencies+@(
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'SPLIT_MAPPED_REQUIRED_PIN_MISSING'}
 }
 foreach($id in @('toolbelt.core.result-table','toolbelt.string.split-advanced')){
  $module=Join-Path $repo ('Modules/'+$id)
  $required=@((Join-Path $module 'module.yaml'))+@(Get-ChildItem -LiteralPath (Join-Path $module 'Deployment'),(Join-Path $module 'Source') -Recurse -File|Where-Object Extension -EQ '.sql'|ForEach-Object FullName)
  foreach($path in $required){if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'SPLIT_MAPPED_PRODUCT_PIN_MISSING'}}
 }
 foreach($fixture in $fixtures){ Assert-SplitMappedFixtureScope ([IO.File]::ReadAllText($fixture)) }
 foreach($mode in @('local','central')){
  $expanded=Get-SplitMappedText $mode;Assert-SplitMappedFixtureScope $expanded
  if($expanded.Contains('$(')-or$expanded-match'(?m)^[ \t]*:r\b'){throw 'SPLIT_MAPPED_UNRESOLVED_FIXTURE'}
  $export=[IO.File]::ReadAllText($runset.exports.$mode)
  $modules=@([regex]::Matches($export,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)\r?$')|ForEach-Object{$_.Groups[1].Value})
  if(($modules-join',')-cne'toolbelt.core.result-table,toolbelt.string.split-advanced'){throw 'SPLIT_MAPPED_EXPORT_CLOSURE_REQUIRED'}
 }
 if($ValidateOnly){'PASS SPLIT_MAPPED_OFFLINE_ADMISSION; no Lab import or SQL';return}
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash-cne$runset.contract_sha256){throw 'SPLIT_MAPPED_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count-ne1){throw 'SPLIT_MAPPED_EXACT_TARGET_REQUIRED'};$target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 . ($fixtures[0])
 if($AuditOnly){
  $hash=(Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -DateKind String
  if($prior.state-cnotin@('COMPLETE','FAILED_CLEANED')-or$prior.owner-cnotmatch'^[a-f0-9]{32}$'){throw 'SPLIT_MAPPED_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $now=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform;" -Rows)
  if($now.Count-ne1-or$now[0].Major-ne$prior.observedTarget.Major-or$now[0].Version-cne$prior.observedTarget.Version-or$now[0].Platform-cne$prior.observedTarget.Platform){throw 'SPLIT_MAPPED_AUDIT_TARGET_DRIFT'}
  foreach($entry in $prior.databases){
   if($entry.name-cne('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix)-or$entry.state-cne'DROPPED'){throw 'SPLIT_MAPPED_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count-ne1-or$rows[0].Id-isnot[DBNull]){throw 'SPLIT_MAPPED_AUDIT_DATABASE_PRESENT'}
  }
  if($prior.serverSnapshot-and(Get-SplitMappedServerSnapshot $control)-cne$prior.serverSnapshot){throw 'SPLIT_MAPPED_FOREIGN_SERVER_DRIFT'}
  Assert-SplitMappedLoginAbsent $control $prior.login
  Assert-ReleaseInputs
  if((Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash-cne$hash){throw 'SPLIT_MAPPED_AUDIT_JOURNAL_DRIFT'}
  [IO.File]::WriteAllText(($journal+'.audit.json'),([ordered]@{state='COMPLETE';readOnly=$true;
   originalJournalSHA256=$hash;originalRunPassed=($prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and
   (@($prior.completedModes)-join',')-ceq'central'-and$prior.witnesses.Count-eq1-and$prior.databases.Count-eq2-and$prior.mappedReceipts.Count-eq1-and
   $prior.mappedReceipts[0].passed-eq$true-and$prior.mappedReceipts[0].realNetwork-eq$true-and$prior.mappedReceipts[0].sidMappings-eq$true-and$prior.mappedReceipts[0].goldenRows-eq3-and$prior.login.state-ceq'DROPPED'-and$prior.login.connectionCount-eq0-and
   (@($prior.profileCompletions|ForEach-Object profile)-join',')-ceq'unmapped-916,connect-only-229,select-golden,other-api-229,helper-229,revoked-229'-and
   @($prior.witnesses|Where-Object{(@($_.fixtures)-join',')-cne($fixtureNames-join',')-or$_.compatibilityLevel-ne170-or$_.transactionNeutral-ne$true-or$_.definitionsUnchanged-ne$true}).Count-eq0);databaseAbsence=$true;
   serverConfigurationAndTrustUnchanged=$true;postPins=$true}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 }else{
  if(Test-Path -LiteralPath $journal){throw 'SPLIT_MAPPED_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();witnesses=@();fixtureCompletions=@();profileCompletions=@();mappedReceipts=@();definitionSnapshots=@();login=$null;serverSnapshot=$null;observedTarget=$null;failure=$null};Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count-ne1-or$actual[0].Major-ne@{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version]-or$actual[0].Platform-ine$case.Platform-or$actual[0].Admin-ne1){throw 'SPLIT_MAPPED_ACTUAL_TARGET_MISMATCH'}
  [void]@(Invoke-ReleaseSql $control 'SELECT @@VERSION Version; SELECT name,state_desc FROM sys.databases ORDER BY database_id;' -Rows)
  $ledger.observedTarget=$actual[0];$ledger.serverSnapshot=Get-SplitMappedServerSnapshot $control;Save-ReleaseJournal
  $environment=@(Invoke-ReleaseSql $control "SELECT (SELECT COUNT(*) FROM sys.server_triggers WHERE is_disabled=0) ServerTriggers,(SELECT CONVERT(int,value_in_use) FROM sys.configurations WHERE name=N'cross db ownership chaining') CrossChaining;" -Rows)
  if($environment.Count-ne1-or$environment[0].ServerTriggers-ne0-or$environment[0].CrossChaining-ne0){throw 'SPLIT_MAPPED_ENVIRONMENT_OUTSIDE_SCOPE'}
  foreach($mode in $case.modes){
   $stage='CREATE_'+$mode;$suffix=if($mode-ceq'local'){'l'}else{'c'};$name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'};$ledger.databases+=@($entry);Save-ReleaseJournal
   $collation=if($mode-ceq'local'){'Latin1_General_100_CS_AS'}else{'Latin1_General_100_BIN2'}
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE $collation;"
   $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($identity.Count-ne1){throw 'SPLIT_MAPPED_DATABASE_IDENTITY'};$entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal;Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $actualCl=@(Invoke-ReleaseSql $db 'SELECT compatibility_level CL,collation_name Collation FROM sys.databases WHERE database_id=DB_ID();' -Rows)
   if($actualCl.Count-ne1-or$actualCl[0].CL-ne$case.CL-or$actualCl[0].Collation-cne$collation){throw 'SPLIT_MAPPED_ACTUAL_CL_OR_COLLATION'}
   $stage='INSTALL_'+$mode;Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   if($markers.Count-ne2-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.core.result-table.Version'-and$_.Value-ceq'1.0.0'}).Count-ne1-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.string.split-advanced.Version'-and$_.Value-ceq'1.1.0'}).Count-ne1){throw 'SPLIT_MAPPED_MODULE_CLOSURE'}
   $modeMarkers=@(Invoke-ReleaseSql $db "SELECT CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name IN(N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode',N'Toolbelt.Module.toolbelt.string.split-advanced.DeploymentMode');" -Rows)
   if($modeMarkers.Count-ne2-or@($modeMarkers|Where-Object{$_.Value-cne$mode}).Count){throw 'SPLIT_MAPPED_DEPLOYMENT_MODE'}
   if([int](@(Invoke-ReleaseSql $db 'SELECT COUNT(*) N FROM sys.assemblies WHERE is_user_defined=1;' -Rows)[0].N)-ne0){throw 'SPLIT_MAPPED_UNEXPECTED_CLR'}
   $definitions="SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.is_ms_shipped=0 AND s.name=N'toolbelt_core' ORDER BY o.object_id;"
   $beforeRows=@(Invoke-ReleaseSql $db $definitions -Rows)
   $before=$beforeRows|ConvertTo-Json -Depth 4 -Compress
   $completedFixtures=@()
   foreach($fixture in $fixtures){
    $stage='SPLIT_MAPPED_'+$mode+'_'+[IO.Path]::GetFileName($fixture)
    Invoke-SplitMappedProfiles $db $mode
    $session=@(Invoke-ReleaseSql $db 'DECLARE @Tc int=@@TRANCOUNT,@Xs smallint=XACT_STATE();SELECT @Tc TranCount,@Xs XactState;' -Rows)
    if($session.Count-ne1-or$session[0].TranCount-ne0-or$session[0].XactState-ne0){throw 'SPLIT_MAPPED_SESSION_NOT_NEUTRAL'}
    $completedFixtures+=@([IO.Path]::GetFileName($fixture))
    $ledger.fixtureCompletions+=@(@{mode=$mode;fixture=[IO.Path]::GetFileName($fixture);transactionNeutral=$true});Save-ReleaseJournal
   }
   if(($completedFixtures-join',')-cne($fixtureNames-join',')){throw 'SPLIT_MAPPED_INCOMPLETE_FIXTURES'}
   $afterRows=@(Invoke-ReleaseSql $db $definitions -Rows)
   $after=$afterRows|ConvertTo-Json -Depth 4 -Compress
   $ledger.definitionSnapshots+=@(@{mode=$mode;before=$beforeRows;after=$afterRows});Save-ReleaseJournal
   if($before-cne$after){throw 'SPLIT_MAPPED_PRODUCT_DEFINITION_DRIFT'}
   $ledger.witnesses+=@(@{mode=$mode;fixtures=$completedFixtures;compatibilityLevel=$actualCl[0].CL;collation=$actualCl[0].Collation;transactionNeutral=$true;definitionsUnchanged=$true})
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
   Assert-SplitMappedCleanupConsumers $control $ledger.login @($ledger.databases|ForEach-Object name)
   foreach($entry in $ledger.databases){Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal}
   Remove-SplitMappedLogin $control $ledger.login
   Save-ReleaseJournal
   if($ledger.serverSnapshot-and(Get-SplitMappedServerSnapshot $control)-cne$ledger.serverSnapshot){throw 'SPLIT_MAPPED_FOREIGN_SERVER_DRIFT'}
   Assert-ReleaseInputs;$ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally{if($control){$control.Dispose()}}
 }
}
if($failure){if($ValidateOnly){throw $failure};'FAIL SPLIT_MAPPED_TARGETS; inspect private journal; no automatic replay';exit 1}
if($AuditOnly){'PASS SPLIT_MAPPED_TARGETS fresh independent final journal/login/SID/database absence audit'}else{'PASS SPLIT_MAPPED_TARGETS real SQL TCP caller and exact cross-database SID mappings; independent audit required'}
