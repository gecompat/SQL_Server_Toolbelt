[CmdletBinding()]
param(
 [ValidateSet('linux','windows')][string]$Platform='linux',
 [ValidateSet('2019','2022','2025')][string]$Version='2019',
 [string]$Patch='latest',
 [ValidateSet(150,160,170)][int]$CompatibilityLevel=150,
 [Parameter(Mandatory)][string]$JournalManifestPath,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedPromptSHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedDriverSHA256,
 [ValidateSet('local','central')][string[]]$DeploymentModes=@('local','central')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$stage='PREPARATION';$batchIndex=0
$script:scopeClock=$null;$script:cleanupPhase=$false
$script:workMilliseconds=300000L;$script:totalMilliseconds=360000L
$script:modulePinPaths=@()
# Eigene synthetische Datenbanken, keine CLR-/Trust-/Konfigurations- oder Rechteänderung.
# Der aufrufende Rootprozess begrenzt zusätzlich den gesamten Prozess mit eigenem Watchdog.

function Get-SafeCastCommandTimeout {
 param([ValidateRange(1,60)][int]$Maximum=60)
 if($null -eq $script:scopeClock){throw 'SAFE_CAST_SCOPE_CLOCK_REQUIRED'}
 $limit=if($script:cleanupPhase){$script:totalMilliseconds}else{$script:workMilliseconds}
 $remaining=$limit-$script:scopeClock.ElapsedMilliseconds
 if($remaining -lt 1000){throw 'SAFE_CAST_SCOPE_DEADLINE'}
 return [int][Math]::Min($Maximum,[Math]::Floor($remaining/1000))
}

function Assert-SafeCastReadBudget($Command){
 try{[void](Get-SafeCastCommandTimeout)}catch{try{$Command.Cancel()}catch{};throw}
}

function Invoke-SafeCastOwnSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
 # Nur administrative OwnScope-Batches; Original-Produkt-DDL bleibt direkt.
 $prefix="IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',5;"+[Environment]::NewLine
 Invoke-SafeCastSql $Connection ($prefix+$Sql) $Parameters -Rows:$Rows
}

function Get-SafeCastFailure($Exception){
 $sql=$null;$cursor=$Exception;$reason='UNCLASSIFIED'
 while($null -ne $cursor){
  if($cursor -is [Data.SqlClient.SqlException]){$sql=$cursor}
  if($cursor.Message -cmatch '^SAFE_CAST_[A-Z0-9_]+$'){$reason=$cursor.Message}
  $cursor=$cursor.InnerException
 }
 [ordered]@{Stage=$script:stage;Batch=$script:batchIndex;SqlNumber=$(if($sql){$sql.Number}else{0});SqlState=$(if($sql){$sql.State}else{0});Reason=$reason}
}

function Invoke-SafeCastSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
 $timeout=Get-SafeCastCommandTimeout
 $command=$Connection.CreateCommand();$command.CommandTimeout=$timeout;$command.CommandText=$Sql
 try{
  foreach($name in $Parameters.Keys){
   $value=$Parameters[$name]
   if($value -is [byte[]]){$parameter=$command.Parameters.Add($name,[Data.SqlDbType]::VarBinary,-1)}
   elseif($value -is [int]){$parameter=$command.Parameters.Add($name,[Data.SqlDbType]::Int)}
   else{$parameter=$command.Parameters.Add($name,[Data.SqlDbType]::NVarChar,-1)}
   $parameter.Value=$value
  }
  $reader=$command.ExecuteReader()
  try{
   $result=[Collections.Generic.List[object]]::new()
   do{Assert-SafeCastReadBudget $command;while($reader.Read()){
    Assert-SafeCastReadBudget $command
    if($Rows){$record=[ordered]@{};for($index=0;$index -lt $reader.FieldCount;$index++){$record[$reader.GetName($index)]=$reader.GetValue($index)};$result.Add([pscustomobject]$record)}
    else{for($index=0;$index -lt $reader.FieldCount;$index++){[void]$reader.GetValue($index)}}
   };Assert-SafeCastReadBudget $command}while($reader.NextResult())
   if($Rows){return $result.ToArray()}
  }finally{$reader.Dispose()}
 }finally{$command.Dispose()}
}

function Read-SafeCastSql([string]$Path,[hashtable]$Variables){
 $text=[IO.File]::ReadAllText($Path)
 $text=[regex]::Replace($text,'(?im)^\s*:r\s+([^\r\n]+)\s*$',{param($match)
  Read-SafeCastSql (Join-Path (Split-Path -Parent $Path) $match.Groups[1].Value.Trim()) $Variables
 })
 $text=[regex]::Replace($text,'(?im)^\s*:On\s+Error\s+exit\s*$','')
 foreach($key in $Variables.Keys){$text=$text.Replace('$('+ $key +')',[string]$Variables[$key])}
 if($text -match '(?m)^\s*:' -or $text -match '\$\('){throw 'SAFE_CAST_SQL_TEMPLATE_UNRESOLVED'}
 return $text
}

function Invoke-SafeCastBatches($Connection,[string]$Sql){
 $script:batchIndex=0
 foreach($batch in [regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
  if(-not [string]::IsNullOrWhiteSpace($batch)){$script:batchIndex++;Invoke-SafeCastSql $Connection $batch}
 }
}

function Open-SafeCastConnection($Target,[string]$Database){
 $builder=$null;$connection=$null
 try{
  $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString $Target))
  $builder['Initial Catalog']=$Database;$builder['Pooling']=$false;$builder['Enlist']=$false
  $builder['ConnectRetryCount']=0;$builder['Connect Timeout']=Get-SafeCastCommandTimeout 15
  $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
  $connection.Open();return $connection
 }catch{if($connection){try{$connection.Dispose()}catch{}};throw}
 finally{if($builder){try{$builder.Clear()}catch{}}}
}

function Save-SafeCastJournal{
 try{
  $temporary=$script:journal+'.writing'
  [IO.File]::WriteAllText($temporary,($script:ledger|ConvertTo-Json -Depth 9),[Text.UTF8Encoding]::new($false))
  [IO.File]::Move($temporary,$script:journal,$true)
 }catch{$script:journalHealthy=$false;throw 'SAFE_CAST_PRIVATE_JOURNAL_FAILED'}
}

function New-SafeCastDatabase($Control,$Target,[string]$Label,[string]$Collation){
 $name='Toolbelt_SafeCast_'+[guid]::NewGuid().ToString('N')
 $entry=[ordered]@{Name=$name;Label=$Label;State='CREATING';Id=$null;Creation=$null;Marker=$false}
 $script:ledger.Databases+=@($entry);Save-SafeCastJournal
 Invoke-SafeCastOwnSql $Control ("IF DB_ID(N'$name') IS NOT NULL THROW 51591,N'Synthetic database collision.',1; CREATE DATABASE [$name] COLLATE $Collation;")
 $connection=Open-SafeCastConnection $Target $name
 try{
  Invoke-SafeCastOwnSql $connection 'DECLARE @MarkerOwner nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Test.SafeCast.Owner'',@value=@MarkerOwner;' @{'@Owner'=$script:ledger.RunId}
  $identity=@(Invoke-SafeCastOwnSql $connection @'
SELECT DB_ID() Id,CONVERT(varchar(32),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)),2) Creation,
 (SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N'Test.SafeCast.Owner'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner)) MarkerCount
FROM sys.databases WHERE database_id=DB_ID();
'@ @{'@Owner'=$script:ledger.RunId} -Rows)
  if($identity.Count -ne 1 -or $identity[0].MarkerCount -ne 1 -or $identity[0].Creation -notmatch '^[A-F0-9]{18}$'){throw 'SAFE_CAST_DATABASE_IDENTITY_UNKNOWN'}
  $entry.Id=[int]$identity[0].Id;$entry.Creation=$identity[0].Creation;$entry.Marker=$true;$entry.State='OWNED';Save-SafeCastJournal
 }finally{$connection.Dispose()}
 return $name
}

function Remove-SafeCastOwnedDatabase($Control,$Entry){
 if($Entry.State -eq 'DROPPED'){return}
 if(-not $Entry.Marker -or $null -eq $Entry.Id -or $null -eq $Entry.Creation){throw 'SAFE_CAST_DATABASE_CLEANUP_IDENTITY_UNKNOWN'}
 $name=$Entry.Name
 if($name -notmatch '^Toolbelt_SafeCast_[a-f0-9]{32}$'){throw 'SAFE_CAST_DATABASE_CLEANUP_NAME_INVALID'}
 Invoke-SafeCastOwnSql $Control @"
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),@Name)
 AND CONVERT(varbinary(max),CONVERT(datetime2(7),create_date))=@Created)
 THROW 51591,N'Owned database identity changed.',2;
DECLARE @MarkerCount int;
EXEC [$name].sys.sp_executesql N'SELECT @Count=COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N''Test.SafeCast.Owner'' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner);',
 N'@Owner nvarchar(32),@Count int OUTPUT',@Owner,@MarkerCount OUTPUT;
IF @MarkerCount IS NULL OR @MarkerCount<>1 THROW 51591,N'Owned database marker changed.',3;
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',5;
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),@Name)
 AND CONVERT(varbinary(max),CONVERT(datetime2(7),create_date))=@Created)
 THROW 51591,N'Owned database identity changed before removal.',2;
DROP DATABASE [$name];
IF DB_ID(@Name) IS NOT NULL THROW 51591,N'Owned database removal not verified.',4;
"@ @{'@Id'=[int]$Entry.Id;'@Name'=$name;'@Created'=[Convert]::FromHexString($Entry.Creation);'@Owner'=$script:ledger.RunId}
 $Entry.State='DROPPED';Save-SafeCastJournal
}

function Assert-SafeCastDisposition($Control){
 foreach($entry in $script:ledger.Databases){
  if($entry.State-cne'DROPPED'-or$entry.Name-notmatch'^Toolbelt_SafeCast_[a-f0-9]{32}$'){throw 'SAFE_CAST_FINAL_DATABASE_STATE'}
  $rows=@(Invoke-SafeCastOwnSql $Control 'SELECT DB_ID(@Name) Id;' @{'@Name'=[string]$entry.Name} -Rows)
  if($rows.Count-ne1-or$rows[0].Id-isnot[DBNull]){throw 'SAFE_CAST_FINAL_DATABASE_PRESENT'}
 }
}
function Get-SafeCastModulePinPaths{
 $paths=@((Join-Path $script:module 'module.yaml'))
 foreach($directory in @('Source','Deployment','Tests/Runtime','Scripts')){
  $paths+=@(Get-ChildItem -LiteralPath (Join-Path $script:module $directory) -File -Recurse|ForEach-Object FullName)
 }
 return @($paths|Sort-Object -Unique -CaseSensitive)
}
function Assert-SafeCastPins{
 if(((@(Get-SafeCastModulePinPaths)) -join '|')-cne($script:modulePinPaths -join '|')){throw 'SAFE_CAST_SOURCE_SET_CHANGED'}
 foreach($path in $script:freeze.Keys){
  if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash-cne$script:freeze[$path]){throw 'SAFE_CAST_SOURCE_PIN_CHANGED'}
 }
}

try{
 $repo=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
 $script:module=Join-Path $repo 'Modules/toolbelt.conversion.safe-cast'
 $JournalManifestPath=[IO.Path]::GetFullPath($JournalManifestPath)
 $repositoryPrefix=$repo.TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
 $privatePrefix=Join-Path $repositoryPrefix '.runtime/'
 if($JournalManifestPath.StartsWith($repositoryPrefix,[StringComparison]::OrdinalIgnoreCase)-and
  -not$JournalManifestPath.StartsWith($privatePrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'SAFE_CAST_PRIVATE_JOURNAL_MANIFEST_REQUIRED'}
 if(-not(Test-Path -LiteralPath $JournalManifestPath -PathType Leaf)-or[IO.File]::ReadAllText($JournalManifestPath).Length-ne0){throw 'SAFE_CAST_EMPTY_OWN_JOURNAL_MANIFEST_REQUIRED'}
 if($CompatibilityLevel-gt@{'2019'=150;'2022'=160;'2025'=170}[$Version]){throw 'SAFE_CAST_SCOPE_COMPATIBILITY_INVALID'}
 if((Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash-cne$ExpectedDriverSHA256.ToUpperInvariant()){throw 'SAFE_CAST_DRIVER_PIN'}
 $helperPath=Join-Path $PSScriptRoot 'run-lab-local.ps1'
 $helperBytes=[IO.File]::ReadAllBytes($helperPath);$parseErrors=$null
 $tree=[Management.Automation.Language.Parser]::ParseInput([Text.Encoding]::UTF8.GetString($helperBytes).TrimStart([char]0xFEFF),[ref]$null,[ref]$parseErrors)
 if($parseErrors.Count){throw 'SAFE_CAST_LAB_HELPER_PARSE'}
 foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
  $definitions=@($tree.FindAll({param($node)$node-is[Management.Automation.Language.FunctionDefinitionAst]-and$node.Name-ceq$name},$true))
  if($definitions.Count-ne1){throw 'SAFE_CAST_LAB_HELPER_AMBIGUOUS'}
  . ([scriptblock]::Create($definitions[0].Extent.Text))
 }
 $lifecyclePath=Join-Path $PSScriptRoot 'SafeCastLifecycle.Helpers.ps1';$lifecycleErrors=$null
 $lifecycleBytes=[IO.File]::ReadAllBytes($lifecyclePath)
 $lifecycleTree=[Management.Automation.Language.Parser]::ParseInput([Text.Encoding]::UTF8.GetString($lifecycleBytes).TrimStart([char]0xFEFF),[ref]$null,[ref]$lifecycleErrors)
 if($lifecycleErrors.Count-or@($lifecycleTree.EndBlock.Statements|Where-Object {$_-isnot[Management.Automation.Language.FunctionDefinitionAst]}).Count){throw 'SAFE_CAST_LIFECYCLE_HELPER_EFFECTS'}
 foreach($definition in @($lifecycleTree.EndBlock.Statements)){
  if($definition-isnot[Management.Automation.Language.FunctionDefinitionAst]){throw 'SAFE_CAST_LIFECYCLE_HELPER_EFFECTS'}
  . ([scriptblock]::Create($definition.Extent.Text))
 }
 $prompt=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
 if(-not$prompt-or(Get-FileHash -LiteralPath $prompt -Algorithm SHA256).Hash-cne$ExpectedPromptSHA256.ToUpperInvariant()-or[string]::IsNullOrWhiteSpace([IO.File]::ReadAllText($prompt))){throw 'SAFE_CAST_REVIEWED_PROMPT_REQUIRED'}
 $discovery=@(& {Resolve-LabContract} *>&1)
 $contracts=@($discovery|Where-Object {$_-is[pscustomobject]-and$_.PSObject.Properties.Name-contains'Contract'})
 if($contracts.Count-ne1-or@($discovery|Where-Object {$_-is[Management.Automation.ErrorRecord]}).Count){throw 'SAFE_CAST_LAB_SCHEMA_INVALID'}
 $targets=@(Get-LabTargetsForSelector -Contract $contracts[0].Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
 if(-not$targets.Count){throw 'SAFE_CAST_EXACT_TARGET_NOT_READY'}
 if(@($DeploymentModes|Select-Object -Unique).Count-ne$DeploymentModes.Count-or$DeploymentModes.Count-lt1){throw 'SAFE_CAST_DUPLICATE_OR_EMPTY_MODE'}
 $expectedSources=@('TVF_TryCastBigInt.sql','TVF_TryCastBit.sql','TVF_TryCastDate.sql','TVF_TryCastDateTime2.sql','TVF_TryCastDecimal.sql','TVF_TryCastUniqueIdentifier.sql')
 if((@(Get-ChildItem -LiteralPath (Join-Path $module 'Source') -File|ForEach-Object Name|Sort-Object -CaseSensitive)-join'|')-cne($expectedSources-join'|')){throw 'SAFE_CAST_SOURCE_SET_INVALID'}
 $script:modulePinPaths=@(Get-SafeCastModulePinPaths);$script:freeze=@{}
 foreach($path in @($PSCommandPath,$helperPath,$lifecyclePath,$prompt,$contracts[0].Path,$contracts[0].SchemaPath)+$script:modulePinPaths){
  $script:freeze[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
 }
 if($script:freeze[$helperPath]-cne[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($helperBytes))-or
  $script:freeze[$lifecyclePath]-cne[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($lifecycleBytes))){throw 'SAFE_CAST_PARSED_HELPER_PIN_CHANGED'}
 $frozenInputs=@(foreach($path in @($script:freeze.Keys|Sort-Object -CaseSensitive)){
  if($path.StartsWith($repositoryPrefix,[StringComparison]::OrdinalIgnoreCase)){
   [ordered]@{Role='Repository';Path=$path.Substring($repositoryPrefix.Length).Replace('\','/');SHA256=$script:freeze[$path]}
  }else{
   $role=if($path-ceq$prompt){'Prompt'}elseif($path-ceq$contracts[0].SchemaPath){'Schema'}elseif($path-ceq$contracts[0].Path){'Contract'}else{throw 'SAFE_CAST_EXTERNAL_FROZEN_ROLE_UNKNOWN'}
   [ordered]@{Role=$role;SHA256=$script:freeze[$path]}
  }
 })
 $sourcePins=@(Get-ChildItem -LiteralPath (Join-Path $module 'Source') -File|Sort-Object Name|ForEach-Object {[ordered]@{Name=$_.Name;SHA256=$script:freeze[$_.FullName]}})
 Assert-SafeCastPins
}catch{$failure=Get-SafeCastFailure $_.Exception;Write-Output ('FAILED: SAFE_CAST_PREPARATION_SQL'+$failure.SqlNumber+'_STATE'+$failure.SqlState+'_'+$failure.Reason);exit 1}

foreach($target in $targets){
 $runId=[guid]::NewGuid().ToString('N')
 $script:journal=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltSafeCastRestore-'+$runId+'.json')
 if((Test-Path -LiteralPath $script:journal)-or(Test-Path -LiteralPath ($script:journal+'.writing'))){throw 'SAFE_CAST_JOURNAL_COLLISION'}
 $script:scopeClock=[Diagnostics.Stopwatch]::StartNew();$script:cleanupPhase=$false
 $script:ledger=[ordered]@{RunId=$runId;SelectorIdentity=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$target.key)));Platform=$Platform;Version=$Version;Patch=[string]$target.patch;CompatibilityLevel=$CompatibilityLevel;State='PREPARED';Databases=@();ConfigurationChanges=0;RightsChanges=0;TrustChanges=0;OriginalFailure=$null;CleanupFailure=$null;DispositionVerified=$false;RuntimeTests=@('Contract.Tests.sql','Lifecycle.Tests.sql');CompletedModes=@();LifecycleCasesPassed=0;MarkerFixtures=@();ForeignFixtures=@();DriverSHA256=$ExpectedDriverSHA256.ToUpperInvariant();SourcePins=$sourcePins;FrozenInputs=$frozenInputs}
 $script:journalHealthy=$true;$control=$null;$failed=$false;$cleanupBlocked=$false
 $capturedClock=$script:scopeClock;$capturedWork=$script:workMilliseconds
 $timeoutProvider={
  $remaining=$capturedWork-$capturedClock.ElapsedMilliseconds
  if($remaining-lt1000){throw 'SAFE_CAST_SCOPE_DEADLINE'}
  [int][Math]::Min(60,[Math]::Floor($remaining/1000))
 }.GetNewClosure()
 $capturedTimeout=$timeoutProvider
 $readBudgetProvider={param($Command)try{[void](& $capturedTimeout)}catch{try{$Command.Cancel()}catch{};throw}}.GetNewClosure()
 try{
  Save-SafeCastJournal
  [IO.File]::AppendAllText($JournalManifestPath,$script:journal+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
  Assert-SafeCastPins
  $stage='PREFLIGHT';$control=Open-SafeCastConnection $target 'master'
  # Der Lab-Zusatzprompt verlangt diese gelesene Anmeldung/Inventarsicht; keine Ausgabe/Persistenz.
  Invoke-SafeCastSql $control 'SELECT @@VERSION; SELECT name,state_desc FROM sys.databases ORDER BY database_id;'
  $ready=@(Invoke-SafeCastSql $control 'SELECT TRY_CONVERT(int,SERVERPROPERTY(N''ProductMajorVersion'')) Major,IS_SRVROLEMEMBER(N''sysadmin'') Admin;' -Rows)
  if($ready.Count-ne1-or$ready[0].Major-ne@{'2019'=15;'2022'=16;'2025'=17}[$Version]-or$ready[0].Admin-ne1){throw 'SAFE_CAST_PREFLIGHT_REQUIRED'}
  foreach($mode in $DeploymentModes){
   Assert-SafeCastPins;$stage='CREATE_'+$mode
   $database=New-SafeCastDatabase $control $target $mode $(if($mode-ceq'local'){'Latin1_General_100_CS_AS'}else{'Latin1_General_100_BIN2'})
   $connection=$null
   $variables=@{DeploymentMode=$mode;ConfirmNoExternalConsumers=1;ToolbeltDatabase=''}
   try{
    $connection=Open-SafeCastConnection $target $database
    Invoke-SafeCastSql $control ("ALTER DATABASE [$database] SET COMPATIBILITY_LEVEL=$CompatibilityLevel;")
    $deploy=Read-SafeCastSql (Join-Path $module 'Deployment/Deploy.sql') $variables
    $uninstall=Read-SafeCastSql (Join-Path $module 'Deployment/Uninstall.sql') $variables
    $stage='INSTALL_'+$mode;Invoke-SafeCastBatches $connection $deploy
    $connection.Dispose();$connection=Open-SafeCastConnection $target $database
    $stage='REPEAT_'+$mode;Invoke-SafeCastBatches $connection $deploy
    $connection.Dispose();$connection=Open-SafeCastConnection $target $database
    $stage='NATIVE_'+$mode
    Invoke-SafeCastSql $connection @'
DECLARE @Slots TABLE(Name sysname);
INSERT @Slots VALUES(N'TVF_TryCastBigInt'),(N'TVF_TryCastDecimal'),(N'TVF_TryCastDate'),(N'TVF_TryCastDateTime2'),(N'TVF_TryCastBit'),(N'TVF_TryCastUniqueIdentifier');
IF (SELECT COUNT(*) FROM @Slots s JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_conversion.'+QUOTENAME(s.Name)) JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.type='IF' AND m.is_schema_bound=1)<>6
 THROW 51594,N'Safe Cast six schemabound IF witness failed.',1;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51594,N'Safe Cast neutral session witness failed.',4;
'@
    foreach($test in $ledger.RuntimeTests){
     Assert-SafeCastPins;$stage='API_'+$mode+'_'+$test;Write-Output ('RUNNING: '+$stage)
     Invoke-SafeCastBatches $connection (Read-SafeCastSql (Join-Path $module ('Tests/Runtime/'+$test)) $variables)
    }
    $stage='CLIENT_'+$mode
    & (Join-Path $module 'Tests/Runtime/Metadata.Tests.ps1') -Connection $connection -CommandTimeoutProvider $timeoutProvider -ReadBudgetProvider $readBudgetProvider | Out-Null
    foreach($abort in @('OFF','ON')){foreach($doomed in @($false,$true)){
     $stage='CALLER_'+$mode+'_'+$abort+'_'+$doomed
     Assert-SafeCastCallerPrepared $connection $deploy $uninstall $abort $doomed
     $ledger.LifecycleCasesPassed+=2;Save-SafeCastJournal
    }}
    $stage='LOCK_'+$mode;Assert-SafeCastLockPrepared $target $database $connection $deploy $uninstall
    $ledger.LifecycleCasesPassed+=2;Save-SafeCastJournal
    $stage='ROLLBACK_'+$mode;Assert-SafeCastRollbackPrepared $connection $deploy $uninstall
    $ledger.LifecycleCasesPassed+=4;Save-SafeCastJournal
    $stage='MARKER_'+$mode;Assert-SafeCastTypedMarkerPrepared $connection $deploy $uninstall $mode
    $ledger.LifecycleCasesPassed+=2;Save-SafeCastJournal
    if($mode-ceq'central'){
     $stage='CONSUMER';$caller=New-SafeCastDatabase $control $target 'caller' 'Latin1_General_100_CI_AS_SC_UTF8'
     $consumer=Open-SafeCastConnection $target $caller
     try{
      $consumerVariables=$variables.Clone();$consumerVariables.ToolbeltDatabase=$database
      Invoke-SafeCastBatches $consumer (Read-SafeCastSql (Join-Path $module 'Tests/Runtime/Contract.Tests.sql') $consumerVariables)
      & (Join-Path $module 'Tests/Runtime/Metadata.Tests.ps1') -Connection $consumer -ToolbeltDatabase $database -CommandTimeoutProvider $timeoutProvider -ReadBudgetProvider $readBudgetProvider | Out-Null
     }finally{$consumer.Dispose()}
     $unconfirmed=$variables.Clone();$unconfirmed.ConfirmNoExternalConsumers=0
     $stage='CONFIRM0';Assert-SafeCastConfirmPrepared $connection (Read-SafeCastSql (Join-Path $module 'Deployment/Uninstall.sql') $unconfirmed)
     $ledger.LifecycleCasesPassed+=2;Save-SafeCastJournal
    }
    $stage='UNINSTALL_'+$mode;Invoke-SafeCastBatches $connection $uninstall
    Invoke-SafeCastSql $connection @'
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version')
 OR EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_conversion') AND name IN(N'TVF_TryCastBigInt',N'TVF_TryCastDecimal',N'TVF_TryCastDate',N'TVF_TryCastDateTime2',N'TVF_TryCastBit',N'TVF_TryCastUniqueIdentifier'))
 THROW 51594,N'Safe Cast uninstall witness failed.',5;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51594,N'Safe Cast uninstall session not neutral.',6;
'@
    $stage='FOREIGN_SLOT_'+$mode;Assert-SafeCastForeignSlotPrepared $connection $deploy $uninstall $mode
    $ledger.LifecycleCasesPassed+=2;Save-SafeCastJournal
    $stage='UNINSTALL_REPEAT_'+$mode;Invoke-SafeCastBatches $connection $uninstall
    $ledger.CompletedModes+=@($mode);Save-SafeCastJournal
   }finally{if($connection){$connection.Dispose()}}
  }
  Assert-SafeCastPins
 }catch{$failed=$true;$ledger.OriginalFailure=Get-SafeCastFailure $_.Exception}
 finally{
  $script:cleanupPhase=$true
  try{
   if(-not$script:journalHealthy){throw 'SAFE_CAST_JOURNAL_UNHEALTHY'}
   $ledger.State='CLEANING';Save-SafeCastJournal
   if($control-and$control.State-eq[Data.ConnectionState]::Open){
    $stage='DATABASE_CLEANUP';foreach($entry in $ledger.Databases){Remove-SafeCastOwnedDatabase $control $entry}
    if(@($ledger.Databases|Where-Object State -ne 'DROPPED').Count){throw 'SAFE_CAST_DATABASE_CLEANUP_INCOMPLETE'}
    $stage='DISPOSITION';Assert-SafeCastDisposition $control;$ledger.DispositionVerified=$true
   }elseif($ledger.Databases.Count){throw 'SAFE_CAST_CLEANUP_CONNECTION_UNAVAILABLE'}
   Assert-SafeCastPins;[void](Get-SafeCastCommandTimeout)
   if(-not$failed-and-not$ledger.DispositionVerified){throw 'SAFE_CAST_DISPOSITION_REQUIRED'}
   $ledger.State=$(if($failed){'FAILED_CLEANED'}else{'COMPLETE'});Save-SafeCastJournal
  }catch{$cleanupBlocked=$true;$ledger.State='CLEANUP_BLOCKED';$ledger.CleanupFailure=Get-SafeCastFailure $_.Exception;try{Save-SafeCastJournal}catch{}}
  finally{if($control){try{$control.Dispose()}catch{$cleanupBlocked=$true;$ledger.State='CLEANUP_BLOCKED';try{Save-SafeCastJournal}catch{}}}}
 }
 if($cleanupBlocked){Write-Output 'FAILED: SAFE_CAST_CLEANUP_BLOCKED';exit 1}
 if($failed){Write-Output ('FAILED: SAFE_CAST_'+$ledger.OriginalFailure.Stage+'_SQL'+$ledger.OriginalFailure.SqlNumber+'_STATE'+$ledger.OriginalFailure.SqlState+'_'+$ledger.OriginalFailure.Reason);exit 1}
 $confirmEvidence=if($ledger.CompletedModes-contains'central'){'/Confirm0'}else{''}
 Write-Output ('PASS: SAFE_CAST '+$Platform+'/'+$Version+'/'+$ledger.Patch+' CL'+$CompatibilityLevel+' modes='+($ledger.CompletedModes-join',')+' fixed-API/client/clean/repeat/uninstall; lifecycle-cases='+$ledger.LifecycleCasesPassed+' caller/lock/rollback/typed-marker/foreign-slot'+$confirmEvidence+'; owned-cleanup. Further physical targets/MinimalRights/heap NOT_EXECUTED.')
}
