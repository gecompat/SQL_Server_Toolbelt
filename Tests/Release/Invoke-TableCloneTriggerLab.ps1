# Begrenzte Windows-Triggerqualifikation mit exakt qualifiziertem Parserpaar und eigener Wiederherstellung.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,5)][int]$CaseIndex,[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='ADMISSION'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'CLONE_TRIGGER_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'CLONE_TRIGGER_HELPER_AMBIGUOUS'};. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
function Get-CloneTriggerServerSnapshot($Control){
 $sql="SELECT configuration_id,name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations ORDER BY configuration_id; SELECT CONVERT(varchar(128),hash,2) Hash,description,create_date,created_by FROM sys.trusted_assemblies ORDER BY hash;"
 return (@(Invoke-ReleaseSql $Control $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Assert-CloneTriggerFixtureScope([string]$Text){
 if($Text-match'(?i)\b(GRANT|DENY|REVOKE|TRUSTWORTHY|sp_configure|sp_add_trusted_assembly)\b|CREATE\s+(USER|LOGIN|ASSEMBLY)|ALTER\s+(AUTHORIZATION|DATABASE)|ALL\s+SERVER'){
  throw 'CLONE_TRIGGER_FIXTURE_EXCEEDS_SCOPE'
 }
}
function Get-CloneTriggerSqlBatches([string]$Text){
 $Text=[regex]::Replace($Text,'(?im)^[\t ]*:ON[\t ]+ERROR[\t ]+EXIT[\t ]*\r?$','')
 if($Text-match'(?m)^[\t ]*:'-or$Text.Contains('$(')){throw 'CLONE_TRIGGER_UNRESOLVED_SQLCMD'}
 # Nur horizontale Leerzeichen: der Kommentar der Folgezeile gehört zum SQL.
 return @([regex]::Split($Text,'(?im)^[\t ]*GO[\t ]*(?:--[^\r\n]*)?\r?$')|Where-Object{-not[string]::IsNullOrWhiteSpace($_)})
}
function Invoke-CloneTriggerSqlBatches($Connection,[string]$Text){
 foreach($batch in Get-CloneTriggerSqlBatches $Text){Invoke-ReleaseSql $Connection $batch}
}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1') @('Get-CsvTrust','Assert-CsvTrustCleanupScope') @{
 'Get-CsvTrust'='Get-CloneTriggerTrust';'Assert-CsvTrustCleanupScope'='Assert-CloneTriggerTrustCleanupScope';
 'Invoke-CsvOwnSql'='Invoke-ReleaseSql';'Invoke-CsvSql'='Invoke-ReleaseSql'}){. $block}
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1') @('Get-ClrCallerConfiguration','Get-ClrCallerPendingConfiguration','Get-ClrCallerUserAssemblyCount','Assert-ClrCallerConfiguration','Start-ClrCallerConfiguration','Restore-ClrCallerConfiguration')){. $block}
# Quellen-/Artefaktbindung vor jedem SQL-Zugriff, keine automatische Providerwahl.
function Assert-CloneTriggerParserArtifact {
 $artifact=Assert-ReleasePrivatePath $runset.parserArtifact
 $manifestPath=Join-Path $artifact 'Toolbelt.Tsql.ScriptParser.trust-manifest.json'
 $manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json -DateKind String
 $provider='F2213559FA9085BDAC9B6A4C1954D7BE18EAAE9BFBF950E2A29CC0121D8B36D6838D4366327D3A6B0C9ED655179ACBE898E2887D917AA0D0C2B7C243C891C16A'
 $dom='459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7'
 if($manifest.moduleId-cne'toolbelt.tsql.script-parser'-or$manifest.moduleVersion-cne'2.0.1'-or
  $manifest.deploymentArtifactSha256-cne'680469ACB052A928024BD124D3A12FA2E2E5DF8F85530777A8B20A6094DCDC8D'-or
  $manifest.sourceFingerprintSha256-cne'38CF81AF870B6FDE4FA5E7A16BBC1FD77348DE5BD652F1BBC33780A74F797A89'-or
  $manifest.sha512-cne$provider-or$manifest.scriptDomSha512-cne$dom-or
  $manifest.permissionSet-cne'UNSAFE'-or$manifest.scriptDomFileVersion-cne'18.0.117.0'-or
  $manifest.assemblyFileName-cne'Toolbelt.Tsql.ScriptParser.dll'-or
  $manifest.scriptDomAssemblyFileName-cne'Microsoft.SqlServer.TransactSql.ScriptDom.dll'){
  throw 'CLONE_TRIGGER_EXACT_QUALIFIED_PAIR_REQUIRED'
 }
 foreach($pair in @(@('Toolbelt.Tsql.ScriptParser.dll',$provider),@('Microsoft.SqlServer.TransactSql.ScriptDom.dll',$dom))){
  $path=Join-Path $artifact $pair[0]
  if((Get-FileHash -LiteralPath $path -Algorithm SHA512).Hash-cne$pair[1]){throw 'CLONE_TRIGGER_BINARY_DRIFT'}
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_TRIGGER_BINARY_PIN_MISSING'}
 }
 $module=Join-Path $repo 'Modules/toolbelt.tsql.script-parser'
 foreach($group in @('sourceFiles','deploymentSourceFiles')){
  if(@($manifest.$group).Count-ne5){throw 'CLONE_TRIGGER_MANIFEST_SOURCE_SET'}
  foreach($entry in $manifest.$group){
   if($entry-cnotmatch'^(Clr/[A-Za-z0-9./-]+|Deployment/Deploy.sql|Source/[A-Za-z0-9_-]+[.]sql):([A-F0-9]{64})$'-or$entry.Contains('..')){throw 'CLONE_TRIGGER_MANIFEST_SOURCE_PATH'}
   $relative=$Matches[1];$hash=$Matches[2];$path=Join-Path $module $relative
   Assert-ReleasePin $path $hash
   if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_TRIGGER_SOURCE_PIN_MISSING'}
  }
 }
 $recordPath=Join-Path $module 'Tests/Qualification/Current.Build.20261105.json'
 $record=Get-Content -LiteralPath $recordPath -Raw|ConvertFrom-Json -DateKind String
 if($record.result-cne'PASS_FOR_APPROVED_COMBINED_SCOPE'-or$record.moduleVersion-cne'2.0.1'-or
  @($record.productSources.PSObject.Properties).Count-ne20){throw 'CLONE_TRIGGER_QUALIFICATION_SCOPE'}
 foreach($property in $record.productSources.PSObject.Properties){
  if($property.Name-cnotmatch'^(Clr|Source|Deployment)/[A-Za-z0-9./_-]+$'-or$property.Name.Contains('..')){throw 'CLONE_TRIGGER_QUALIFICATION_PATH'}
  $path=Join-Path $module $property.Name;Assert-ReleasePin $path $property.Value
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_TRIGGER_QUALIFICATION_PIN_MISSING'}
 }
 $deployPath=Join-Path $artifact 'Deploy.WithAssembly.sql'
 Assert-ReleasePin $deployPath $manifest.deploymentArtifactSha256
 $original=[IO.File]::ReadAllText($deployPath)
 if(([regex]::Matches($original,[regex]::Escape('$(DeploymentMode)'))).Count-ne3){throw 'CLONE_TRIGGER_PARSER_MODE_BINDING'}
 foreach($mode in @('local','central')){
  $rendered=Assert-ReleasePrivatePath $runset.parserDeploy.$mode
  if([IO.File]::ReadAllText($rendered)-cne$original.Replace('$(DeploymentMode)',$mode)){throw 'CLONE_TRIGGER_PARSER_RENDER_DRIFT'}
  if(@($runset.pins|Where-Object path -CEQ $rendered).Count-ne1){throw 'CLONE_TRIGGER_PARSER_RENDER_PIN_MISSING'}
 }
 foreach($path in @($manifestPath,$recordPath,$deployPath)){
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_TRIGGER_PROVENANCE_PIN_MISSING'}
 }
 return @(@{hash=$provider;file='Toolbelt.Tsql.ScriptParser.dll'},@{hash=$dom;file='Microsoft.SqlServer.TransactSql.ScriptDom.dll'})
}

function Add-CloneTriggerExactTrust($Control,$Artifacts){
 foreach($artifact in $Artifacts){
  $hash=[Convert]::FromHexString($artifact.hash);$prior=Get-CloneTriggerTrust $Control $hash
  $entry=[ordered]@{hash=$artifact.hash;preexisting=($null-ne$prior);fingerprint=$null;description=$null;state='PREEXISTING'}
  if($prior){$entry.fingerprint=$prior.Fingerprint}
  $ledger.trust+=@($entry);Save-ReleaseJournal
  if($prior){continue}
  Assert-CloneTriggerTrustCleanupScope $Control $hash
  $entry.description='Toolbelt synthetic Trigger '+$ledger.owner+' '+$artifact.file
  $entry.state='ADDING';Save-ReleaseJournal
  Invoke-ReleaseSql $Control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; IF @Hash IS NULL OR DATALENGTH(@Hash)<>64 THROW 52096,N''Exact trust hash required.'',10; IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash) EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$hash;'@Description'=$entry.description}
  $actual=Get-CloneTriggerTrust $Control $hash
  if($null-eq$actual-or$actual.description-is[DBNull]-or$actual.description-cne$entry.description){throw 'CLONE_TRIGGER_TRUST_IDENTITY_UNKNOWN'}
  $entry.fingerprint=$actual.Fingerprint;$entry.state='OWNED';Save-ReleaseJournal
 }
}

function Restore-CloneTriggerTrust($Control){
 foreach($entry in $ledger.trust){
  $hash=[Convert]::FromHexString($entry.hash);$actual=Get-CloneTriggerTrust $Control $hash
  if($entry.preexisting){
   if($null-eq$actual-or$actual.Fingerprint-cne$entry.fingerprint){throw 'CLONE_TRIGGER_PREEXISTING_TRUST_DRIFT'}
   continue
  }
  if($entry.state-ceq'ADDING'-and$null-eq$actual){$entry.state='ABSENT';Save-ReleaseJournal;continue}
  if($entry.state-cne'OWNED'-or$null-eq$entry.fingerprint-or$null-eq$actual-or
   $actual.Fingerprint-cne$entry.fingerprint){throw 'CLONE_TRIGGER_TRUST_OWNERSHIP_UNCERTAIN'}
  Assert-CloneTriggerTrustCleanupScope $Control $hash
  Invoke-ReleaseSql $Control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
  if($null-ne(Get-CloneTriggerTrust $Control $hash)){throw 'CLONE_TRIGGER_TRUST_STILL_PRESENT'}
  $entry.state='REMOVED';Save-ReleaseJournal
 }
}

try{
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version-cne'table-clone-trigger/v1'-or$runset.cases.Count-ne6-or
  $runset.explicit_qualification_approved-isnot[bool]-or$runset.explicit_qualification_approved-ne$true){throw 'CLONE_TRIGGER_RUNSET_SCOPE'}
 $started=[DateTimeOffset]::Parse($runset.started_utc);$deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 if($deadline-ne$started.AddMinutes(60)-or$started-gt[DateTimeOffset]::UtcNow-or
  (-not$AuditOnly-and[DateTimeOffset]::UtcNow.AddMinutes(7)-ge$deadline)){throw 'CLONE_TRIGGER_ADMISSION_CLOSED'}
 $expected=@('windows/2019/CU32/150','windows/2022/CU26/150','windows/2022/CU26/160',
  'windows/2025/CU8/150','windows/2025/CU8/160','windows/2025/CU8/170')
 for($i=0;$i-lt6;$i++){
  $c=$runset.cases[$i];$tuple=[string]$c.Platform+'/'+$c.Version+'/'+$c.Patch+'/'+$c.CL
  $modes='local,central'
  if($tuple-cne$expected[$i]-or(@($c.modes)-join',')-cne$modes){throw 'CLONE_TRIGGER_CONTEXT_SCOPE'}
 }
 $case=$runset.cases[$CaseIndex];Assert-ReleaseInputs
 $fixtureRoot=Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Tests/Runtime'
 $fixtureNames=@('Trigger.Contract.sql','Trigger.Safety.sql')
 $fixtures=@($fixtureNames|ForEach-Object{Join-Path $fixtureRoot $_})

 if(($runset.fixtures-join'|')-cne($fixtures-join'|')){throw 'CLONE_TRIGGER_CANONICAL_FIXTURES_REQUIRED'}
 foreach($path in @($PSCommandPath,$runset.exports.local,$runset.exports.central)+$fixtures+@(
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),(Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),(Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_TRIGGER_REQUIRED_PIN_MISSING'}
 }
 foreach($fixture in $fixtures){
  $text=[IO.File]::ReadAllText($fixture)
  Assert-CloneTriggerFixtureScope $text
 }
 foreach($mode in @('local','central')){
  $export=[IO.File]::ReadAllText($runset.exports.$mode)
  $modules=@([regex]::Matches($export,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)\r?$')|ForEach-Object{$_.Groups[1].Value})
  if(($modules-join',')-cne'toolbelt.core.result-table,toolbelt.metadata.table-clone'){throw 'CLONE_TRIGGER_EXPORT_CLOSURE_REQUIRED'}
 }
 $parserArtifacts=@(Assert-CloneTriggerParserArtifact)
 if($ValidateOnly){'PASS CLONE_TRIGGER_OFFLINE_ADMISSION; no Lab import or SQL';return}
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash-cne$runset.contract_sha256){throw 'CLONE_TRIGGER_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count-ne1){throw 'CLONE_TRIGGER_EXACT_TARGET_REQUIRED'};$target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $hash=(Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -DateKind String
  if($prior.state-cnotin@('COMPLETE','FAILED_CLEANED')-or$prior.owner-cnotmatch'^[a-f0-9]{32}$'){throw 'CLONE_TRIGGER_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $now=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform;" -Rows)
  if($now.Count-ne1-or$now[0].Major-ne$prior.observedTarget.Major-or$now[0].Version-cne$prior.observedTarget.Version-or$now[0].Platform-cne$prior.observedTarget.Platform){throw 'CLONE_TRIGGER_AUDIT_TARGET_DRIFT'}
  foreach($entry in $prior.databases){
   if($entry.name-cne('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix)-or$entry.state-cne'DROPPED'){throw 'CLONE_TRIGGER_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count-ne1-or$rows[0].Id-isnot[DBNull]){throw 'CLONE_TRIGGER_AUDIT_DATABASE_PRESENT'}
  }
  if($prior.serverSnapshot-and(Get-CloneTriggerServerSnapshot $control)-cne$prior.serverSnapshot){throw 'CLONE_TRIGGER_FOREIGN_SERVER_DRIFT'}
  Assert-ReleaseInputs
  if((Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash-cne$hash){throw 'CLONE_TRIGGER_AUDIT_JOURNAL_DRIFT'}
  [IO.File]::WriteAllText(($journal+'.audit.json'),([ordered]@{state='COMPLETE';readOnly=$true;
   originalJournalSHA256=$hash;originalRunPassed=($prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and
   (@($prior.completedModes)-join',')-ceq(@($case.modes)-join',')-and$prior.witnesses.Count-eq2-and
   @($prior.witnesses|Where-Object{(@($_.fixtures)-join',')-cne($fixtureNames-join',')-or$_.compatibilityLevel-ne$case.CL-or$_.transactionNeutral-ne$true-or$_.definitionsUnchanged-ne$true}).Count-eq0);databaseAbsence=$true;
   serverConfigurationAndTrustUnchanged=$true;postPins=$true}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 }else{
  if(Test-Path -LiteralPath $journal){throw 'CLONE_TRIGGER_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();trust=@();configuration=[ordered]@{before=@();changed=$false;state='NONE'};completedModes=@();witnesses=@();serverSnapshot=$null;observedTarget=$null;failure=$null};Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count-ne1-or$actual[0].Major-ne@{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version]-or$actual[0].Platform-ine$case.Platform-or$actual[0].Admin-ne1){throw 'CLONE_TRIGGER_ACTUAL_TARGET_MISMATCH'}
  $ledger.observedTarget=$actual[0];$ledger.serverSnapshot=Get-CloneTriggerServerSnapshot $control;Save-ReleaseJournal
  $ready=@(Invoke-ReleaseSql $control "SELECT IS_SRVROLEMEMBER(N'sysadmin') IsAdmin,(SELECT CONVERT(int,value_in_use) FROM sys.configurations WHERE name=N'clr enabled') ClrReady,(SELECT CONVERT(int,value_in_use) FROM sys.configurations WHERE name=N'clr strict security') StrictReady;" -Rows)
  if($ready.Count-ne1-or$ready[0].IsAdmin-ne1-or$ready[0].StrictReady-ne1){throw 'CLONE_TRIGGER_EXISTING_CLR_CONTEXT_REQUIRED'}
  $stage='CONFIGURATION';Start-ClrCallerConfiguration $control
  $stage='TRUST';Add-CloneTriggerExactTrust $control $parserArtifacts

  foreach($mode in $case.modes){
   $stage='CREATE_'+$mode;$suffix=if($mode-ceq'local'){'l'}else{'c'};$name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'};$ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($identity.Count-ne1){throw 'CLONE_TRIGGER_DATABASE_IDENTITY'};$entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal;Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $actualCl=@(Invoke-ReleaseSql $db 'SELECT compatibility_level CL FROM sys.databases WHERE database_id=DB_ID();' -Rows)
   if($actualCl.Count-ne1-or$actualCl[0].CL-ne$case.CL){throw 'CLONE_TRIGGER_ACTUAL_CL'}
   $stage='PARSER_'+$mode;Invoke-CloneTriggerSqlBatches $db ([IO.File]::ReadAllText($runset.parserDeploy.$mode));$stage='INSTALL_'+$mode;Invoke-CloneTriggerSqlBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   if($markers.Count-ne3-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.tsql.script-parser.Version'-and$_.Value-ceq'2.0.1'}).Count-ne1-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.core.result-table.Version'-and$_.Value-ceq'1.0.0'}).Count-ne1-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.metadata.table-clone.Version'-and$_.Value-ceq'4.1.1'}).Count-ne1){throw 'CLONE_TRIGGER_MODULE_CLOSURE'}
   $modeMarkers=@(Invoke-ReleaseSql $db "SELECT CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name IN(N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode',N'Toolbelt.Module.toolbelt.metadata.table-clone.DeploymentMode',N'Toolbelt.Module.toolbelt.tsql.script-parser.DeploymentMode');" -Rows)
   if($modeMarkers.Count-ne3-or@($modeMarkers|Where-Object{$_.Value-cne$mode}).Count){throw 'CLONE_TRIGGER_DEPLOYMENT_MODE'}
   if([int](@(Invoke-ReleaseSql $db 'SELECT COUNT(*) N FROM sys.assemblies WHERE is_user_defined=1;' -Rows)[0].N)-ne2){throw 'CLONE_TRIGGER_UNEXPECTED_CLR'}
   $definitions="SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.is_ms_shipped=0 AND s.name LIKE N'toolbelt[_]%' ORDER BY o.object_id;"
   $before=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   $completedFixtures=@()
   foreach($fixture in $fixtures){
    $stage='CLONE_TRIGGER_'+$mode+'_'+[IO.Path]::GetFileName($fixture)
    Invoke-CloneTriggerSqlBatches $db ([IO.File]::ReadAllText($fixture))
    $session=@(Invoke-ReleaseSql $db 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
    if($session.Count-ne1-or$session[0].TranCount-ne0-or$session[0].XactState-ne0){throw 'CLONE_TRIGGER_SESSION_NOT_NEUTRAL'}
    $completedFixtures+=@([IO.Path]::GetFileName($fixture))
   }
   if(($completedFixtures-join',')-cne($fixtureNames-join',')){throw 'CLONE_TRIGGER_INCOMPLETE_FIXTURES'}
   $after=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   if($before-cne$after){throw 'CLONE_TRIGGER_PRODUCT_DEFINITION_DRIFT'}
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
   Restore-CloneTriggerTrust $control;Restore-ClrCallerConfiguration $control
   if($ledger.serverSnapshot-and(Get-CloneTriggerServerSnapshot $control)-cne$ledger.serverSnapshot){throw 'CLONE_TRIGGER_FOREIGN_SERVER_DRIFT'}
   Assert-ReleaseInputs;$ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally{if($control){$control.Dispose()}}
 }
}
if($failure){if($ValidateOnly){throw $failure};'FAIL CLONE_TRIGGER_TARGETS; inspect private journal; no automatic replay';exit 1}
if($AuditOnly){'PASS CLONE_TRIGGER_TARGETS fresh independent final journal/absence audit'}else{'PASS CLONE_TRIGGER_TARGETS selected Trigger fixtures; independent audit required'}
