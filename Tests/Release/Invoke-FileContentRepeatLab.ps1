# Befüllter File-Content-Repeat ohne Datei-I/O oder neue Rechte.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,8)][int]$CaseIndex,[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='ADMISSION'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'FILE_REPEAT_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'FILE_REPEAT_HELPER_AMBIGUOUS'};. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
function Get-FileRepeatServerSnapshot($Control){
 $sql="SELECT configuration_id,name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations ORDER BY configuration_id; SELECT CONVERT(varchar(128),hash,2) Hash,description,create_date,created_by FROM sys.trusted_assemblies ORDER BY hash;"
 return (@(Invoke-ReleaseSql $Control $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Get-FileRepeatText([string]$Mode){
 $base=Join-Path $repo 'Modules/toolbelt.file.content/Deployment'
 $moduleRoot=[IO.Path]::GetFullPath((Join-Path $base '..'))+[IO.Path]::DirectorySeparatorChar
 function Expand-FileRepeat([string]$Path,[string[]]$Stack=@()){
  $full=[IO.Path]::GetFullPath($Path)
  if(-not$full.StartsWith($moduleRoot,[StringComparison]::OrdinalIgnoreCase)-or$Stack-contains$full){throw 'FILE_REPEAT_INCLUDE_OUTSIDE_OR_CYCLE'}
  # Wie Get-SqlcmdScriptTree: Zeilen einlesen, Dateiende nicht doppelt einbetten.
  $text=[IO.File]::ReadAllLines($full) -join "`n"
  return [regex]::Replace($text,'(?m)^[ \t]*:r[ \t]+([^\r\n]+)[ \t]*\r?$',{
   param($m)
   $name=$m.Groups[1].Value.Trim()
   if($name.Contains('$(')){throw 'FILE_REPEAT_DYNAMIC_INCLUDE'}
   Expand-FileRepeat (Join-Path $base $name) ($Stack+@($full))
  })
 }
 $text=Expand-FileRepeat (Join-Path $base '../Tests/Runtime/RepeatCurrent.Contract.sql')
 # Dieselbe LF-Normalisierung wie der kanonische Erstinstallations-Export.
 return $text.Replace('$(DeploymentMode)',$Mode).Replace("`r`n","`n").Replace("`r","`n")
}
function Assert-FileRepeatFixtureScope([string]$Text){
 if($Text-match'(?i)\b(GRANT|DENY|REVOKE|TRUSTWORTHY|sp_configure|sp_add_trusted_assembly)\b|CREATE\s+(USER|LOGIN|ASSEMBLY)|ALTER\s+(AUTHORIZATION|DATABASE)|ALL\s+SERVER'){
  throw 'FILE_REPEAT_FIXTURE_EXCEEDS_SCOPE'
 }
}
try{
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version-cne'file-content-repeat-current/v1'-or$runset.cases.Count-ne9-or
  $runset.explicit_qualification_approved-isnot[bool]-or$runset.explicit_qualification_approved-ne$true){throw 'FILE_REPEAT_RUNSET_SCOPE'}
 $started=[DateTimeOffset]::Parse($runset.started_utc);$deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 if($deadline-ne$started.AddMinutes(45)-or$started-gt[DateTimeOffset]::UtcNow-or
  (-not$AuditOnly-and[DateTimeOffset]::UtcNow.AddMinutes(7)-ge$deadline)){throw 'FILE_REPEAT_ADMISSION_CLOSED'}
 $expected=@('windows/2019/CU32/150','windows/2022/CU26/150','windows/2022/CU26/160',
  'windows/2025/CU8/150','windows/2025/CU8/160','windows/2025/CU8/170',
  'linux/2022/latest/150',
  'linux/2025/latest/150','linux/2025/latest/160')
 for($i=0;$i-lt9;$i++){
  $c=$runset.cases[$i];$tuple=[string]$c.Platform+'/'+$c.Version+'/'+$c.Patch+'/'+$c.CL
  $modes='local,central'
  if($tuple-cne$expected[$i]-or(@($c.modes)-join',')-cne$modes){throw 'FILE_REPEAT_CONTEXT_SCOPE'}
 }
 $case=$runset.cases[$CaseIndex];Assert-ReleaseInputs
 $fixtureRoot=Join-Path $repo 'Modules/toolbelt.file.content/Tests/Runtime'
 $fixtureNames=@('RepeatCurrent.Contract.sql','Lifecycle.Contract.sql')
 $fixtures=@($fixtureNames|ForEach-Object{Join-Path $fixtureRoot $_})
 $repeatDependencies=@('RepeatCurrent.Capture.sql','RepeatCurrent.Assert.sql')|ForEach-Object{Join-Path $fixtureRoot $_}

 if(($runset.fixtures-join'|')-cne($fixtures-join'|')){throw 'FILE_REPEAT_CANONICAL_FIXTURES_REQUIRED'}
 foreach($path in @($PSCommandPath,$runset.exports.local,$runset.exports.central)+$fixtures+$repeatDependencies+@(
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'FILE_REPEAT_REQUIRED_PIN_MISSING'}
 }
 foreach($fixture in $fixtures){
  $text=[IO.File]::ReadAllText($fixture)
  Assert-FileRepeatFixtureScope $text
 }
 foreach($mode in @('local','central')){
  $expanded=Get-FileRepeatText $mode;Assert-FileRepeatFixtureScope $expanded
  if($expanded.Contains('$(')-or$expanded-match'(?m)^[ \t]*:r\b'){throw 'FILE_REPEAT_UNRESOLVED_FIXTURE'}
  $export=[IO.File]::ReadAllText($runset.exports.$mode)
  $modules=@([regex]::Matches($export,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)\r?$')|ForEach-Object{$_.Groups[1].Value})
  if(($modules-join',')-cne'toolbelt.core.result-table,toolbelt.file.content'){throw 'FILE_REPEAT_EXPORT_CLOSURE_REQUIRED'}
 }
 if($ValidateOnly){'PASS FILE_REPEAT_OFFLINE_ADMISSION; no Lab import or SQL';return}
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash-cne$runset.contract_sha256){throw 'FILE_REPEAT_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count-ne1){throw 'FILE_REPEAT_EXACT_TARGET_REQUIRED'};$target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $hash=(Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -DateKind String
  if($prior.state-cnotin@('COMPLETE','FAILED_CLEANED')-or$prior.owner-cnotmatch'^[a-f0-9]{32}$'){throw 'FILE_REPEAT_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $now=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform;" -Rows)
  if($now.Count-ne1-or$now[0].Major-ne$prior.observedTarget.Major-or$now[0].Version-cne$prior.observedTarget.Version-or$now[0].Platform-cne$prior.observedTarget.Platform){throw 'FILE_REPEAT_AUDIT_TARGET_DRIFT'}
  foreach($entry in $prior.databases){
   if($entry.name-cne('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix)-or$entry.state-cne'DROPPED'){throw 'FILE_REPEAT_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count-ne1-or$rows[0].Id-isnot[DBNull]){throw 'FILE_REPEAT_AUDIT_DATABASE_PRESENT'}
  }
  if($prior.serverSnapshot-and(Get-FileRepeatServerSnapshot $control)-cne$prior.serverSnapshot){throw 'FILE_REPEAT_FOREIGN_SERVER_DRIFT'}
  Assert-ReleaseInputs
  if((Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash-cne$hash){throw 'FILE_REPEAT_AUDIT_JOURNAL_DRIFT'}
  [IO.File]::WriteAllText(($journal+'.audit.json'),([ordered]@{state='COMPLETE';readOnly=$true;
   originalJournalSHA256=$hash;originalRunPassed=($prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and
   (@($prior.completedModes)-join',')-ceq(@($case.modes)-join',')-and$prior.witnesses.Count-eq2-and
   @($prior.witnesses|Where-Object{(@($_.fixtures)-join',')-cne($fixtureNames-join',')-or$_.compatibilityLevel-ne$case.CL-or$_.transactionNeutral-ne$true-or$_.definitionsUnchanged-ne$true}).Count-eq0);databaseAbsence=$true;
   serverConfigurationAndTrustUnchanged=$true;postPins=$true}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 }else{
  if(Test-Path -LiteralPath $journal){throw 'FILE_REPEAT_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();witnesses=@();fixtureCompletions=@();definitionSnapshots=@();serverSnapshot=$null;observedTarget=$null;failure=$null};Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count-ne1-or$actual[0].Major-ne@{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version]-or$actual[0].Platform-ine$case.Platform-or$actual[0].Admin-ne1){throw 'FILE_REPEAT_ACTUAL_TARGET_MISMATCH'}
  [void]@(Invoke-ReleaseSql $control 'SELECT @@VERSION Version; SELECT name,state_desc FROM sys.databases ORDER BY database_id;' -Rows)
  $ledger.observedTarget=$actual[0];$ledger.serverSnapshot=Get-FileRepeatServerSnapshot $control;Save-ReleaseJournal
  foreach($mode in $case.modes){
   $stage='CREATE_'+$mode;$suffix=if($mode-ceq'local'){'l'}else{'c'};$name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'};$ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($identity.Count-ne1){throw 'FILE_REPEAT_DATABASE_IDENTITY'};$entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal;Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $actualCl=@(Invoke-ReleaseSql $db 'SELECT compatibility_level CL FROM sys.databases WHERE database_id=DB_ID();' -Rows)
   if($actualCl.Count-ne1-or$actualCl[0].CL-ne$case.CL){throw 'FILE_REPEAT_ACTUAL_CL'}
   $stage='INSTALL_'+$mode;Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   if($markers.Count-ne2-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.core.result-table.Version'-and$_.Value-ceq'1.0.0'}).Count-ne1-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.file.content.Version'-and$_.Value-ceq'1.0.0'}).Count-ne1){throw 'FILE_REPEAT_MODULE_CLOSURE'}
   $modeMarkers=@(Invoke-ReleaseSql $db "SELECT CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name IN(N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode',N'Toolbelt.Module.toolbelt.file.content.DeploymentMode');" -Rows)
   if($modeMarkers.Count-ne2-or@($modeMarkers|Where-Object{$_.Value-cne$mode}).Count){throw 'FILE_REPEAT_DEPLOYMENT_MODE'}
   if([int](@(Invoke-ReleaseSql $db 'SELECT COUNT(*) N FROM sys.assemblies WHERE is_user_defined=1;' -Rows)[0].N)-ne0){throw 'FILE_REPEAT_UNEXPECTED_CLR'}
   $definitions="SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.is_ms_shipped=0 AND s.name LIKE N'toolbelt[_]%' ORDER BY o.object_id;"
   $beforeRows=@(Invoke-ReleaseSql $db $definitions -Rows)
   $before=$beforeRows|ConvertTo-Json -Depth 4 -Compress
   $completedFixtures=@()
   foreach($fixture in $fixtures){
    $stage='FILE_REPEAT_'+$mode+'_'+[IO.Path]::GetFileName($fixture)
    $sql=if([IO.Path]::GetFileName($fixture)-ceq'RepeatCurrent.Contract.sql'){Get-FileRepeatText $mode}else{[IO.File]::ReadAllText($fixture)}
    Invoke-ReleaseBatches $db $sql
    $session=@(Invoke-ReleaseSql $db 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
    if($session.Count-ne1-or$session[0].TranCount-ne0-or$session[0].XactState-ne0){throw 'FILE_REPEAT_SESSION_NOT_NEUTRAL'}
    $completedFixtures+=@([IO.Path]::GetFileName($fixture))
    $ledger.fixtureCompletions+=@(@{mode=$mode;fixture=[IO.Path]::GetFileName($fixture);transactionNeutral=$true});Save-ReleaseJournal
   }
   if(($completedFixtures-join',')-cne($fixtureNames-join',')){throw 'FILE_REPEAT_INCOMPLETE_FIXTURES'}
   $afterRows=@(Invoke-ReleaseSql $db $definitions -Rows)
   $after=$afterRows|ConvertTo-Json -Depth 4 -Compress
   $ledger.definitionSnapshots+=@(@{mode=$mode;before=$beforeRows;after=$afterRows});Save-ReleaseJournal
   if($before-cne$after){throw 'FILE_REPEAT_PRODUCT_DEFINITION_DRIFT'}
   $ledger.witnesses+=@(@{mode=$mode;fixtures=$completedFixtures;compatibilityLevel=$actualCl[0].CL;transactionNeutral=$true;definitionsUnchanged=$true})
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
   if($ledger.serverSnapshot-and(Get-FileRepeatServerSnapshot $control)-cne$ledger.serverSnapshot){throw 'FILE_REPEAT_FOREIGN_SERVER_DRIFT'}
   Assert-ReleaseInputs;$ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally{if($control){$control.Dispose()}}
 }
}
if($failure){if($ValidateOnly){throw $failure};'FAIL FILE_REPEAT_TARGETS; inspect private journal; no automatic replay';exit 1}
if($AuditOnly){'PASS FILE_REPEAT_TARGETS fresh independent final journal/absence audit'}else{'PASS FILE_REPEAT_TARGETS selected populated repeat fixture; independent audit required'}
