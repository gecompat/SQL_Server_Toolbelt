# Begrenzte vollständige SQLCMD-Caller-Abbruchprüfung mit eigener Ressourcenidentität.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='ADMISSION'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'CLONE_SQLCMD_CALLER_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'CLONE_SQLCMD_CALLER_HELPER_AMBIGUOUS'};. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
function Get-CloneSqlcmdCallerServerSnapshot($Control){
 $sql="SELECT configuration_id,name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations ORDER BY configuration_id; SELECT CONVERT(varchar(128),hash,2) Hash,description,create_date,created_by FROM sys.trusted_assemblies ORDER BY hash;"
 return (@(Invoke-ReleaseSql $Control $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Assert-CloneSqlcmdCallerFixtureScope([string]$Text){
 if($Text-match'(?i)\b(GRANT|DENY|REVOKE|TRUSTWORTHY|sp_configure|sp_add_trusted_assembly)\b|CREATE\s+(USER|LOGIN|ASSEMBLY)|ALTER\s+(AUTHORIZATION|DATABASE)|ALL\s+SERVER|IncludeTriggers\s*=\s*1'){
  throw 'CLONE_SQLCMD_CALLER_FIXTURE_EXCEEDS_SCOPE'
 }
}
function Get-CloneSqlcmdCallerSqlBatches([string]$Text){
 $Text=[regex]::Replace($Text,'(?im)^[\t ]*:ON[\t ]+ERROR[\t ]+EXIT[\t ]*\r?$','')
 if($Text-match'(?m)^[\t ]*:'-or$Text.Contains('$(')){throw 'CLONE_SQLCMD_CALLER_UNRESOLVED_SQLCMD'}
 # Nur horizontale Leerzeichen: der Kommentar der Folgezeile gehört zum SQL.
 return @([regex]::Split($Text,'(?im)^[\t ]*GO[\t ]*(?:--[^\r\n]*)?\r?$')|Where-Object{-not[string]::IsNullOrWhiteSpace($_)})
}
function Invoke-CloneSqlcmdCallerSqlBatches($Connection,[string]$Text){
 foreach($batch in Get-CloneSqlcmdCallerSqlBatches $Text){Invoke-ReleaseSql $Connection $batch}
}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Deployment/Deploy-All.ps1') @('Get-SqlcmdScriptTree','ConvertTo-StandaloneSql')){. $block}
function Initialize-SqlcmdCallerProcess {
 $blocks=@(Import-ClrFunctions (Join-Path $repo 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1') @('Invoke-OwnedProcess'))
 if($blocks.Count-ne1){throw 'SQLCMD_CALLER_PROCESS_SOURCE'}
 $original=$blocks[0].ToString();$text=$original
 $a='$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true'
 $b='if(-not $child.Start()){throw ''OWNED_PROCESS_START''};$started=$true'
 if(([regex]::Matches($text,[regex]::Escape($a))).Count-ne1-or([regex]::Matches($text,[regex]::Escape($b))).Count-ne1){throw 'SQLCMD_CALLER_PROCESS_ANCHOR'}
 $stream=';$info.RedirectStandardInput=$true;$info.StandardOutputEncoding=[Text.UTF8Encoding]::new($false,$true);$info.StandardErrorEncoding=[Text.UTF8Encoding]::new($false,$true)'
 $text=$text.Replace($a,$a+$stream).Replace($b,$b+';$child.StandardInput.Close()').Replace('function Invoke-OwnedProcess {','function Invoke-SqlcmdCallerOwnedProcess {')
 $reverse=$text.Replace('function Invoke-SqlcmdCallerOwnedProcess {','function Invoke-OwnedProcess {').Replace($stream,'').Replace(';$child.StandardInput.Close()','')
 if($reverse-cne$original){throw 'SQLCMD_CALLER_UNRELATED_PROCESS_CHANGE'}
 return [scriptblock]::Create($text)
}

function Assert-SqlcmdCallerTexts {
 foreach($mode in @('local','central')){foreach($kind in @('Deploy','Uninstall')){foreach($abort in @('OFF','ON')){
  $source=Join-Path $repo ('Modules/toolbelt.metadata.table-clone/Tests/Runtime/Lifecycle.CallerTransaction.'+$kind+'.sql')
  $node=Get-SqlcmdScriptTree -Path $source -Cache @{}
  if(([regex]::Matches($node.Text,[regex]::Escape('SET XACT_ABORT ON;'))).Count-ne1){throw 'SQLCMD_CALLER_ROOT_ABORT_ANCHOR'}
  $node.Text=$node.Text.Replace('SET XACT_ABORT ON;','SET XACT_ABORT '+$abort+';')
  $expected=ConvertTo-StandaloneSql -Node $node -Values @{DeploymentMode=$mode;ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules')
  $path=Assert-ReleasePrivatePath $runset.callerTexts.$mode.$kind.$abort
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'SQLCMD_CALLER_TEXT_PIN_REQUIRED'}
  if([IO.File]::ReadAllText($path)-cne$expected-or$expected.Contains('$(')-or$expected.Contains('frische Sitzung ohne laufende oder implizite Transaktion')-or
   $expected.IndexOf('BEGIN TRANSACTION;')-gt$expected.IndexOf('IF @@TRANCOUNT>0')-or$expected-notmatch'TBX_TABLE_CLONE_CALLER_TRANSACTION:'-or$expected-notmatch'THROW 54920'){
   throw 'SQLCMD_CALLER_CANONICAL_TEXT_DRIFT'
  }
 }}}
}

function Get-SqlcmdCallerModuleSnapshot($Connection){
 $sql=@'
SELECT o.object_id,o.type,s.name SchemaName,o.name,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) DefinitionHash
FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
WHERE o.is_ms_shipped=0 AND s.name LIKE N'toolbelt[_]%' ORDER BY o.object_id;
SELECT class,major_id,minor_id,name,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,'BaseType')) ValueType,
 CONVERT(varchar(max),CONVERT(varbinary(max),value),2) ValueBytes
FROM sys.extended_properties WHERE (class=0 AND name LIKE N'Toolbelt.Module.%')
 OR (class=1 AND major_id IN(SELECT o.object_id FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE s.name LIKE N'toolbelt[_]%'))
ORDER BY class,major_id,minor_id,name;
'@
 return (@(Invoke-ReleaseSql $Connection $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}

function Invoke-SqlcmdCallerProfile([string]$Mode,[string]$Kind,[string]$Abort,[string]$Database){
 if($ledger.cliProfiles.Count-ge8){throw 'SQLCMD_CALLER_CASE_DISPATCH_LIMIT'}
 $path=$runset.callerTexts.$Mode.$Kind.$Abort
 $entry=[ordered]@{mode=$Mode;kind=$Kind;abort=$Abort;sourceSHA256=(Get-FileHash -LiteralPath $path).Hash;state='DISPATCHED';exitCode=$null;passed=$false}
 $ledger.cliProfiles+=@($entry);Save-ReleaseJournal
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $script:target -TestPurpose Functional))
 $before=[Environment]::GetEnvironmentVariable('SQLCMDPASSWORD','Process')
 try{
  $arguments=@(New-SqlcmdCallerArguments $builder $Database $path)
  [Environment]::SetEnvironmentVariable('SQLCMDPASSWORD',$builder.Password,'Process')
  $result=Invoke-SqlcmdCallerOwnedProcess -FileName $runset.sqlcmd.path -Arguments $arguments -TimeoutMilliseconds ((Get-ReleaseTimeout)*1000)
  $prefix=Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.'+$Mode+'.'+$Kind+'.'+$Abort)
  [IO.File]::WriteAllText(($prefix+'.stdout.private.log'),$result.Stdout,[Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText(($prefix+'.stderr.private.log'),$result.Stderr,[Text.UTF8Encoding]::new($false))
  $entry.exitCode=[int]$result.ExitCode
  $combined=$result.Stdout+"`n"+$result.Stderr
  if(-not$result.CaptureComplete-or$result.ExitCode-ne1-or-not$combined.Contains('TBX_TABLE_CLONE_CALLER_TRANSACTION:')-or
   $combined-notmatch'50000'-or$combined-match'54920'){
   $entry.state='EXPECTED_GUARD_NOT_PROVEN';Save-ReleaseJournal;throw 'SQLCMD_CALLER_EXPECTED_GUARD_NOT_PROVEN'
  }
  $entry.state='PASS';$entry.passed=$true;Save-ReleaseJournal
 }finally{
  $builder.Clear();[Environment]::SetEnvironmentVariable('SQLCMDPASSWORD',$before,'Process')
  if(-not[string]::Equals($before,[Environment]::GetEnvironmentVariable('SQLCMDPASSWORD','Process'),[StringComparison]::Ordinal)){throw 'SQLCMD_CALLER_PASSWORD_ENVIRONMENT_DRIFT'}
 }
}

# Reine Argumentkonstruktion; keine Anmeldung und kein Prozessstart.
function New-SqlcmdCallerArguments([Data.SqlClient.SqlConnectionStringBuilder]$Builder,[string]$Database,[string]$InputPath){
 if($Builder.IntegratedSecurity-or[string]::IsNullOrEmpty($Builder.UserID)-or[string]::IsNullOrEmpty($Builder.Password)-or-not$Builder.Encrypt){throw 'SQLCMD_CALLER_EXPLICIT_SQL_ENCRYPTED_IDENTITY_REQUIRED'}
 if($Database-cnotmatch'^Toolbelt_Release_[a-f0-9]{32}_[lc]$'){throw 'SQLCMD_CALLER_OWN_DATABASE_REQUIRED'}
 if(-not[IO.Path]::IsPathRooted($InputPath)-or[IO.Path]::GetExtension($InputPath)-cne'.sql'){throw 'SQLCMD_CALLER_ABSOLUTE_INPUT_REQUIRED'}
 $arguments=@('-S',$Builder.DataSource,'-U',$Builder.UserID,'-d',$Database,'-N','-b','-r1','-f','65001','-l','30','-t','45','-i',$InputPath,'-X1')
 if($Builder.TrustServerCertificate){$arguments+=@('-C')}
 if($arguments-ccontains$Builder.Password-or$arguments-ccontains'-P'-or$arguments-ccontains'-E'){throw 'SQLCMD_CALLER_SECRET_OR_AUTH_FALLBACK_ARGUMENT'}
 return $arguments
}

try{
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version-cne'table-clone-sqlcmd-caller/v1'-or$runset.cases.Count-ne12-or
  $runset.explicit_qualification_approved-isnot[bool]-or$runset.explicit_qualification_approved-ne$true){throw 'CLONE_SQLCMD_CALLER_RUNSET_SCOPE'}
 $started=[DateTimeOffset]::Parse($runset.started_utc);$deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 if($deadline-ne$started.AddMinutes(60)-or$started-gt[DateTimeOffset]::UtcNow-or
  (-not$AuditOnly-and[DateTimeOffset]::UtcNow.AddMinutes(7)-ge$deadline)){throw 'CLONE_SQLCMD_CALLER_ADMISSION_CLOSED'}
 $expected=@('windows/2019/CU32/150','windows/2022/CU26/150','windows/2022/CU26/160',
  'windows/2025/CU8/150','windows/2025/CU8/160','windows/2025/CU8/170',
  'linux/2019/latest/150','linux/2022/latest/150','linux/2022/latest/160',
  'linux/2025/latest/150','linux/2025/latest/160','linux/2025/latest/170')
 for($i=0;$i-lt12;$i++){
  $c=$runset.cases[$i];$tuple=[string]$c.Platform+'/'+$c.Version+'/'+$c.Patch+'/'+$c.CL
  $modes='local,central'
  if($tuple-cne$expected[$i]-or(@($c.modes)-join',')-cne$modes){throw 'CLONE_SQLCMD_CALLER_CONTEXT_SCOPE'}
 }
 $case=$runset.cases[$CaseIndex];Assert-ReleaseInputs
 $fixtureRoot=Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Tests/Runtime'
 $fixtureNames=@('Lifecycle.CallerTransaction.Deploy.sql','Lifecycle.CallerTransaction.Uninstall.sql')
 $fixtures=@($fixtureNames|ForEach-Object{Join-Path $fixtureRoot $_})

 if(($runset.fixtures-join'|')-cne($fixtures-join'|')){throw 'CLONE_SQLCMD_CALLER_CANONICAL_FIXTURES_REQUIRED'}
 foreach($path in @($PSCommandPath,$runset.exports.local,$runset.exports.central)+$fixtures+@(
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),(Join-Path $repo 'Tests/CI/Set-SqlClientTlsPolicy.ps1'),(Join-Path $repo 'Tests/CI/Assert-LabQualifiedTlsBinding.ps1'),(Join-Path $repo 'Deployment/Deploy-All.ps1'),(Join-Path $repo 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'),(Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableClone.sql'),(Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Deployment/Deploy.sql'),(Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Deployment/Uninstall.sql'))){
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_SQLCMD_CALLER_REQUIRED_PIN_MISSING'}
 }
 foreach($fixture in $fixtures){
  $text=[IO.File]::ReadAllText($fixture)
  Assert-CloneSqlcmdCallerFixtureScope $text
 }
 foreach($mode in @('local','central')){
  $export=[IO.File]::ReadAllText($runset.exports.$mode)
  $modules=@([regex]::Matches($export,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)\r?$')|ForEach-Object{$_.Groups[1].Value})
  if(($modules-join',')-cne'toolbelt.core.result-table,toolbelt.metadata.table-clone'){throw 'CLONE_SQLCMD_CALLER_EXPORT_CLOSURE_REQUIRED'}
 }
 Assert-SqlcmdCallerTexts
 if(@($runset.pins|Where-Object path -CEQ $runset.sqlcmd.path).Count-ne1){throw 'SQLCMD_CALLER_EXECUTABLE_PIN_REQUIRED'}
 . (Initialize-SqlcmdCallerProcess)
 if($ValidateOnly){'PASS CLONE_SQLCMD_CALLER_OFFLINE_ADMISSION; no Lab import or SQL';return}
 if(-not[string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable('SQLCMDINI','Process'))){throw 'SQLCMD_CALLER_UNEXPECTED_STARTUP_SCRIPT'}
 if(-not$IsWindows){throw 'CLONE_SQLCMD_CALLER_WINDOWS_HOST_REQUIRED'}
 if(@('TBX_LAB_QUALIFIED_CONTEXT_FILE','TBX_LAB_QUALIFIED_CONTEXT_SHA256','TBX_LAB_QUALIFIED_PWSH')|Where-Object{-not[string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($_,'Process'))}){throw 'CLONE_SQLCMD_CALLER_UNEXPECTED_QUALIFIED_CONTEXT'}
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash-cne$runset.contract_sha256){throw 'CLONE_SQLCMD_CALLER_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count-ne1){throw 'CLONE_SQLCMD_CALLER_EXACT_TARGET_REQUIRED'};$target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $hash=(Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -DateKind String
  if($prior.state-cnotin@('COMPLETE','FAILED_CLEANED')-or$prior.owner-cnotmatch'^[a-f0-9]{32}$'){throw 'CLONE_SQLCMD_CALLER_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $now=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform;" -Rows)
  if($now.Count-ne1-or$now[0].Major-ne$prior.observedTarget.Major-or$now[0].Version-cne$prior.observedTarget.Version-or$now[0].Platform-cne$prior.observedTarget.Platform){throw 'CLONE_SQLCMD_CALLER_AUDIT_TARGET_DRIFT'}
  foreach($entry in $prior.databases){
   if($entry.name-cne('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix)-or$entry.state-cne'DROPPED'){throw 'CLONE_SQLCMD_CALLER_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count-ne1-or$rows[0].Id-isnot[DBNull]){throw 'CLONE_SQLCMD_CALLER_AUDIT_DATABASE_PRESENT'}
  }
  if($prior.serverSnapshot-and(Get-CloneSqlcmdCallerServerSnapshot $control)-cne$prior.serverSnapshot){throw 'CLONE_SQLCMD_CALLER_FOREIGN_SERVER_DRIFT'}
  Assert-ReleaseInputs
  if((Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash-cne$hash){throw 'CLONE_SQLCMD_CALLER_AUDIT_JOURNAL_DRIFT'}
  [IO.File]::WriteAllText(($journal+'.audit.json'),([ordered]@{state='COMPLETE';readOnly=$true;
   originalJournalSHA256=$hash;originalRunPassed=($prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and
   (@($prior.completedModes)-join',')-ceq(@($case.modes)-join',')-and$prior.witnesses.Count-eq2-and$prior.cliProfiles.Count-eq8-and@($prior.cliProfiles|Where-Object{$_.passed-ne$true-or$_.exitCode-ne1-or$_.state-cne'PASS'}).Count-eq0-and
   @($prior.witnesses|Where-Object{(@($_.fixtures)-join',')-cne($fixtureNames-join',')-or$_.compatibilityLevel-ne$case.CL-or$_.transactionNeutral-ne$true-or$_.definitionsUnchanged-ne$true-or$_.processEnvironmentRestored-ne$true-or$_.completeCliProfiles-ne4}).Count-eq0);databaseAbsence=$true;
   serverConfigurationAndTrustUnchanged=$true;postPins=$true}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 }else{
  if(Test-Path -LiteralPath $journal){throw 'CLONE_SQLCMD_CALLER_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();cliProfiles=@();completedModes=@();witnesses=@();serverSnapshot=$null;observedTarget=$null;failure=$null};Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count-ne1-or$actual[0].Major-ne@{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version]-or$actual[0].Platform-ine$case.Platform-or$actual[0].Admin-ne1){throw 'CLONE_SQLCMD_CALLER_ACTUAL_TARGET_MISMATCH'}
  $ledger.observedTarget=$actual[0];$ledger.serverSnapshot=Get-CloneSqlcmdCallerServerSnapshot $control;Save-ReleaseJournal
  foreach($mode in $case.modes){
   $stage='CREATE_'+$mode;$suffix=if($mode-ceq'local'){'l'}else{'c'};$name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'};$ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($identity.Count-ne1){throw 'CLONE_SQLCMD_CALLER_DATABASE_IDENTITY'};$entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal;Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $actualCl=@(Invoke-ReleaseSql $db 'SELECT compatibility_level CL FROM sys.databases WHERE database_id=DB_ID();' -Rows)
   if($actualCl.Count-ne1-or$actualCl[0].CL-ne$case.CL){throw 'CLONE_SQLCMD_CALLER_ACTUAL_CL'}
   $stage='INSTALL_'+$mode;Invoke-CloneSqlcmdCallerSqlBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   if($markers.Count-ne2-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.core.result-table.Version'-and$_.Value-ceq'1.0.0'}).Count-ne1-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.metadata.table-clone.Version'-and$_.Value-ceq'4.1.1'}).Count-ne1){throw 'CLONE_SQLCMD_CALLER_MODULE_CLOSURE'}
   $modeMarkers=@(Invoke-ReleaseSql $db "SELECT CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name IN(N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode',N'Toolbelt.Module.toolbelt.metadata.table-clone.DeploymentMode');" -Rows)
   if($modeMarkers.Count-ne2-or@($modeMarkers|Where-Object{$_.Value-cne$mode}).Count){throw 'CLONE_SQLCMD_CALLER_DEPLOYMENT_MODE'}
   if([int](@(Invoke-ReleaseSql $db 'SELECT COUNT(*) N FROM sys.assemblies WHERE is_user_defined=1;' -Rows)[0].N)-ne0){throw 'CLONE_SQLCMD_CALLER_UNEXPECTED_CLR'}
   $definitions="SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.is_ms_shipped=0 AND s.name LIKE N'toolbelt[_]%' ORDER BY o.object_id;"
   $before=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   $completedFixtures=@();$catalogue=Get-SqlcmdCallerModuleSnapshot $db
   foreach($kind in @('Deploy','Uninstall')){
    foreach($abort in @('OFF','ON')){
     $stage='SQLCMD_'+$mode+'_'+$kind+'_'+$abort
     Invoke-SqlcmdCallerProfile $mode $kind $abort $name
     if((Get-SqlcmdCallerModuleSnapshot $db)-cne$catalogue){throw 'SQLCMD_CALLER_CATALOGUE_DRIFT'}
     $session=@(Invoke-ReleaseSql $db 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
     if($session.Count-ne1-or$session[0].TranCount-ne0-or$session[0].XactState-ne0){throw 'SQLCMD_CALLER_PARENT_SESSION_DRIFT'}
    }
    $completedFixtures+=@('Lifecycle.CallerTransaction.'+$kind+'.sql')
   }
   if(($completedFixtures-join',')-cne($fixtureNames-join',')){throw 'SQLCMD_CALLER_INCOMPLETE_FIXTURES'}
   $after=@(Invoke-ReleaseSql $db $definitions -Rows)|ConvertTo-Json -Depth 4 -Compress
   if($before-cne$after){throw 'CLONE_SQLCMD_CALLER_PRODUCT_DEFINITION_DRIFT'}
   $ledger.witnesses+=@(@{mode=$mode;fixtures=$completedFixtures;compatibilityLevel=$actualCl[0].CL;transactionNeutral=$true;definitionsUnchanged=$true;processEnvironmentRestored=$true;completeCliProfiles=4})
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
   if($ledger.serverSnapshot-and(Get-CloneSqlcmdCallerServerSnapshot $control)-cne$ledger.serverSnapshot){throw 'CLONE_SQLCMD_CALLER_FOREIGN_SERVER_DRIFT'}
   Assert-ReleaseInputs;$ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally{if($control){$control.Dispose()}}
 }
}
if($failure){if($ValidateOnly){throw $failure};'FAIL CLONE_SQLCMD_CALLER_TARGETS; inspect private journal; no automatic replay';exit 1}
if($AuditOnly){'PASS CLONE_SQLCMD_CALLER_TARGETS fresh independent final journal/absence audit'}else{'PASS CLONE_SQLCMD_CALLER_TARGETS selected complete SQLCMD caller fixtures; independent audit required'}
