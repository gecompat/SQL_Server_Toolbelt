[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
      [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedRunsetSHA256,
      [switch]$ValidateOnly,[switch]$AuditOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$repo=$script:repo;$script:RunsetPath=$RunsetPath;$script:ExpectedRunsetSHA256=$ExpectedRunsetSHA256
$script:connections=[Collections.Generic.List[object]]::new();$script:failure=$null;$script:stage='PREPARE';$script:ledger=$null
$control=$null;$db=$null

$errors=$null
$apiAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'JSON_CALLER_TX_HELPER_PARSE'}
$nodes=@($apiAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'JSON_CALLER_TX_HELPER_DISCOVERY'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $script:repo 'Tests/Release/Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql','Open-ReleaseConnection',
 'Assert-ReleaseInputs','Assert-ReleaseOwnIdentity') @{'function Invoke-ReleaseSql('='function Invoke-ReleaseSqlCore('}){. $block}
. (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')
. (Join-Path $script:repo 'Tests/CI/LabQualifiedContract.ps1')
foreach($block in Import-ClrFunctions (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1') @(
 'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}

# Reuse only reviewed helpers from the immutable r33/r34 adapters.
$r34Path=Join-Path $PSScriptRoot 'Invoke-JsonSchemaUninstallAppLockLab.ps1'
$r33Path=Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1'
foreach($sourcePath in @($r34Path,$r33Path)){
 $sourceErrors=$null;$sourceAst=[Management.Automation.Language.Parser]::ParseFile($sourcePath,[ref]$null,[ref]$sourceErrors)
 if($sourceErrors.Count){throw 'JSON_CALLER_TX_SOURCE_PARSE'}
 $names=if($sourcePath -ceq $r34Path){@('Get-LabSelectorTarget','Save-Journal','Read-CoreProjection','Assert-SchemaAssemblyClosure','Assert-SchemaSlots','Assert-SchemaInstalled','Assert-RunsetStable')}
        else{@('Read-Scalar','Get-ModuleState','Assert-CoreOnly','Assert-SchemaAbsent','Assert-SchemaModuleAbsent','Get-ExternalSessionState','Test-ExternalSessionIdle')}
 foreach($name in $names){
  $found=@($sourceAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
  if($found.Count-ne1){throw 'JSON_CALLER_TX_SOURCE_FUNCTION'}
  . ([scriptblock]::Create($found[0].Extent.Text))
 }
}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){
 Assert-RunsetStable;Assert-ReleaseInputs
 Invoke-ReleaseSqlCore $Connection $Text $Parameters -Rows:$Rows
}

function Assert-Runset {
 $script:RunsetPath=Assert-ReleasePrivatePath $script:RunsetPath
 if((Get-FileHash -LiteralPath $script:RunsetPath -Algorithm SHA256).Hash -cne $script:ExpectedRunsetSHA256.ToUpperInvariant()){throw 'JSON_CALLER_TX_RUNSET_PIN_DRIFT'}
 $script:runset=Get-Content -LiteralPath $script:RunsetPath -Raw -Encoding UTF8|ConvertFrom-Json
 if($script:runset.schema_version -cne 'json-schema-caller-transaction-probe/v1' -or
    $script:runset.operation -cne 'json-schema-caller-transaction' -or
    $script:runset.target.platform -cne 'windows' -or $script:runset.target.version -cne '2025' -or
    $script:runset.target.patch -cne 'CU8' -or ($script:runset.target.compatibility_level -isnot[int] -and $script:runset.target.compatibility_level -isnot[long]) -or
    $script:runset.target.compatibility_level -ne170 -or $script:runset.target.test_purpose -cne 'Functional' -or
    $script:runset.scope.deployment_mode -cne 'local' -or ($script:runset.scope.expected_error -isnot[int] -and $script:runset.scope.expected_error -isnot[long]) -or
    $script:runset.scope.expected_error -ne50000 -or ($script:runset.scope.expected_state -isnot[int] -and $script:runset.scope.expected_state -isnot[long]) -or
    $script:runset.scope.expected_state -ne1 -or $script:runset.scope.witness.table -cne 'dbo.JsonSchemaCallerTransactionWitness' -or
    ($script:runset.scope.witness.baseline -isnot[int] -and $script:runset.scope.witness.baseline -isnot[long]) -or $script:runset.scope.witness.baseline -ne100 -or
    ($script:runset.scope.witness.first -isnot[int] -and $script:runset.scope.witness.first -isnot[long]) -or $script:runset.scope.witness.first -ne200 -or
    ($script:runset.scope.witness.after_savepoint -isnot[int] -and $script:runset.scope.witness.after_savepoint -isnot[long]) -or $script:runset.scope.witness.after_savepoint -ne300 -or
    $script:runset.scope.session_profile.quoted_identifier-isnot[bool] -or -not$script:runset.scope.session_profile.quoted_identifier -or
    $script:runset.scope.session_profile.xact_abort-isnot[bool] -or $script:runset.scope.session_profile.xact_abort -or
    $script:runset.scope.session_profile.nocount-isnot[bool] -or $script:runset.scope.session_profile.nocount -or
    $script:runset.scope.witness.savepoint -cne 'CallerSavepoint'){throw 'JSON_CALLER_TX_RUNSET_INVALID'}
 Assert-CallerCaseShape @($script:runset.scope.cases)
 if($script:runset.artifacts.Count-ne2 -or $script:runset.baseline.modules.Count-ne2 -or
    $script:runset.baseline.modules[0]-cne'toolbelt.core.result-table' -or $script:runset.baseline.modules[1]-cne'toolbelt.json.core' -or
    $script:runset.schema_deploy.module-cne'toolbelt.json.schema' -or $script:runset.schema_uninstall.module-cne'toolbelt.json.schema'){
   throw 'JSON_CALLER_TX_ARTIFACT_SCOPE'
 }
 $required=@($script:PSCommandPath,(Join-Path $PSScriptRoot 'Prepare-JsonSchemaCallerTransactionRunset.ps1'),
  (Join-Path $PSScriptRoot 'Prepare-JsonSchemaUninstallAppLockRunset.ps1'),(Join-Path $PSScriptRoot 'Prepare-JsonSchemaAppLockRunset.ps1'),
  (Join-Path $PSScriptRoot 'Test-JsonSchemaCallerTransactionOffline.ps1'),
  (Join-Path $PSScriptRoot 'Test-JsonSchemaUninstallAppLockOffline.ps1'),$r34Path,$r33Path,
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),
  (Join-Path $script:repo 'Tests/Release/Invoke-StablePackageLab.ps1'),(Join-Path $script:repo 'Tests/Release/ClrCaller.Environment.ps1'),
  (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $script:repo 'Tests/CI/LabQualifiedContract.ps1'))
 foreach($path in $required){if(@($script:runset.pins|Where-Object{$_.path-ceq$path}).Count-ne1){throw 'JSON_CALLER_TX_REQUIRED_PIN_MISSING'}}
 $pinSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($pin in $script:runset.pins){if(-not$pinSet.Add([IO.Path]::GetFullPath([string]$pin.path))){throw 'JSON_CALLER_TX_DUPLICATE_PIN'};Assert-ReleasePin $pin.path $pin.sha256}
 Assert-ReleaseInputs
 if((Get-FileHash -LiteralPath $script:runset.base_runset.path -Algorithm SHA256).Hash -cne $script:runset.base_runset.sha256.ToUpperInvariant()){throw 'JSON_CALLER_TX_BASE_RUNSET_DRIFT'}
 $base=Get-Content -LiteralPath $script:runset.base_runset.path -Raw -Encoding UTF8|ConvertFrom-Json
 if($base.schema_version -cne 'json-schema-uninstall-applock-probe/v1' -or $base.target.patch -cne 'CU8' -or
    $base.target.compatibility_level -ne170 -or $base.artifacts.Count-ne2 -or
    $base.schema_deploy.sha256-cne$script:runset.schema_deploy.sha256 -or $base.schema_uninstall.sha256-cne$script:runset.schema_uninstall.sha256){throw 'JSON_CALLER_TX_BASE_RUNSET_INVALID'}
 foreach($artifact in $script:runset.artifacts){if($artifact.module_id-cnotin@('toolbelt.json.core','toolbelt.json.schema') -or
  (Get-FileHash -LiteralPath $artifact.path -Algorithm SHA256).Hash.ToLowerInvariant()-cne$artifact.sha256 -or
  (Get-FileHash -LiteralPath $artifact.path -Algorithm SHA512).Hash.ToLowerInvariant()-cne$artifact.sha512){throw 'JSON_CALLER_TX_ARTIFACT_DRIFT'}}
 foreach($export in @($script:runset.baseline,$script:runset.schema_deploy,$script:runset.schema_uninstall)){
  if((Get-FileHash -LiteralPath $export.path -Algorithm SHA256).Hash.ToLowerInvariant()-cne$export.sha256){throw 'JSON_CALLER_TX_EXPORT_DRIFT'}
 }
}

function Assert-CallerCaseShape($Cases){
 $expected=@(
  [ordered]@{ordinal=0;operation='deploy';initial_schema='absent';expected_message='JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.'},
  [ordered]@{ordinal=1;operation='uninstall';initial_schema='installed';expected_message='JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.'})
 if(@($Cases).Count-ne2){throw 'JSON_CALLER_TX_CASES_INVALID'}
 for($i=0;$i-lt2;$i++){
  $actual=$Cases[$i]
  if(($actual.ordinal-isnot[int]-and$actual.ordinal-isnot[long]) -or $actual.ordinal-ne$expected[$i].ordinal -or
     $actual.operation-cne$expected[$i].operation -or $actual.initial_schema-cne$expected[$i].initial_schema -or
     $actual.expected_message-cne$expected[$i].expected_message){throw 'JSON_CALLER_TX_CASES_INVALID'}
 }
}

function Invoke-PinnedLifecycle([string]$Operation){
 $entry=if($Operation-ceq'deploy'){$script:runset.schema_deploy}else{$script:runset.schema_uninstall}
 Invoke-PinnedSqlBatches $db ([string]$entry.path) ([string]$entry.sha256)
}
function Get-WitnessValue($Connection){[int](Read-Scalar $Connection 'SELECT WitnessValue AS ScalarValue FROM dbo.JsonSchemaCallerTransactionWitness WHERE WitnessId=1;')}
function Get-LocalTransactionState($Connection){
 $rows=@(Sql $Connection 'DECLARE @ObservedTranCount int=@@TRANCOUNT,@ObservedXactState smallint=XACT_STATE(); SELECT @ObservedTranCount TranCount,@ObservedXactState XactState;' -Rows)
 if($rows.Count-ne1){throw 'JSON_CALLER_TX_STATE_SHAPE'}
 $rows[0]
}
function Set-GuardSessionProfile($Connection){
 Sql $Connection 'SET QUOTED_IDENTIFIER ON;'
 Sql $Connection 'SET XACT_ABORT OFF;'
 Sql $Connection 'SET NOCOUNT OFF;'
 $options=[int](Read-Scalar $Connection 'SELECT @@OPTIONS AS ScalarValue;')
 if(($options-band256)-eq0 -or ($options-band16384)-ne0 -or ($options-band512)-ne0){throw 'JSON_CALLER_TX_SESSION_PROFILE_INVALID'}
 return $options
}
function Assert-ExternalActiveTransaction($Observer,[int]$SessionId){
 $rows=@(Get-ExternalSessionState $Observer $SessionId)
 if($rows.Count-ne1 -or [int]$rows[0].SessionId-ne$SessionId -or [int]$rows[0].OpenTransactionCount-lt1 -or
    [int]$rows[0].UserTransactionCount-lt1 -or [int]$rows[0].ApplicationLockCount-ne0){throw 'JSON_CALLER_TX_EXTERNAL_ACTIVE_WITNESS_INVALID'}
}
function Invoke-BlockedTransactionCase($Connection,$Observer,$Case,[string]$BeforeModule,[int]$OriginalOptions){
 $spid=[int](Read-Scalar $Connection 'SELECT @@SPID AS ScalarValue;')
 if($Connection.State-ne[Data.ConnectionState]::Open){throw 'JSON_CALLER_TX_CONNECTION_NOT_OPEN'}
 $options=[int](Read-Scalar $Connection 'SELECT @@OPTIONS AS ScalarValue;')
 if($options-ne$OriginalOptions){throw 'JSON_CALLER_TX_OPTIONS_BASELINE_DRIFT'}
 $idleState=Get-LocalTransactionState $Connection
 if([int]$idleState.TranCount-ne0 -or [int]$idleState.XactState-ne0 -or
    -not(Test-ExternalSessionIdle (Get-ExternalSessionState $Observer $spid) $spid)){throw 'JSON_CALLER_TX_NOT_IDLE_BEFORE_BEGIN'}
 if((Get-WitnessValue $Connection)-ne100){throw 'JSON_CALLER_TX_WITNESS_COMMITTED_BASELINE_DRIFT'}
 Sql $Connection 'BEGIN TRANSACTION;'
 Sql $Connection 'UPDATE dbo.JsonSchemaCallerTransactionWitness SET WitnessValue=200 WHERE WitnessId=1;'
 if((Get-WitnessValue $Connection)-ne200){throw 'JSON_CALLER_TX_WITNESS_FIRST_UPDATE_DRIFT'}
 Sql $Connection 'SAVE TRANSACTION CallerSavepoint;'
 Sql $Connection 'UPDATE dbo.JsonSchemaCallerTransactionWitness SET WitnessValue=300 WHERE WitnessId=1;'
 $beforeState=Get-LocalTransactionState $Connection
 if([int]$beforeState.TranCount-ne1 -or [int]$beforeState.XactState-ne1 -or (Get-WitnessValue $Connection)-ne300){throw 'JSON_CALLER_TX_SETUP_ORACLE'}
 Assert-ExternalActiveTransaction $Observer $spid
 $beforeOptions=[int](Read-Scalar $Connection 'SELECT @@OPTIONS AS ScalarValue;')
 if($beforeOptions-ne$OriginalOptions){throw 'JSON_CALLER_TX_OPTIONS_PRE_GUARD_DRIFT'}
 $caught=$null
 try{Invoke-PinnedLifecycle ([string]$Case.operation)}catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}
 if($caught-isnot[Data.SqlClient.SqlException] -or $caught.Number-ne50000 -or $caught.State-ne1 -or
    @($caught.Errors|Where-Object{$_.Number-eq50000 -and $_.State-eq1 -and $_.Message-ceq[string]$Case.expected_message}).Count-ne1){throw 'JSON_CALLER_TX_EXPECTED_ERROR_MISMATCH'}
 if($Connection.State-ne[Data.ConnectionState]::Open -or [int](Read-Scalar $Connection 'SELECT @@SPID AS ScalarValue;')-ne$spid){throw 'JSON_CALLER_TX_SESSION_CHANGED'}
 $afterState=Get-LocalTransactionState $Connection
 $afterOptions=[int](Read-Scalar $Connection 'SELECT @@OPTIONS AS ScalarValue;')
 if([int]$afterState.TranCount-ne1 -or [int]$afterState.XactState-ne1 -or $afterOptions-ne$OriginalOptions -or
    (Get-WitnessValue $Connection)-ne300 -or (Get-ModuleState $Connection)-cne$BeforeModule){throw 'JSON_CALLER_TX_GUARD_MUTATED_STATE'}
 Assert-ExternalActiveTransaction $Observer $spid
 Sql $Connection 'ROLLBACK TRANSACTION CallerSavepoint;'
 $savepointState=Get-LocalTransactionState $Connection
 if([int]$savepointState.TranCount-ne1 -or [int]$savepointState.XactState-ne1 -or
    [int](Read-Scalar $Connection 'SELECT @@OPTIONS AS ScalarValue;')-ne$OriginalOptions -or (Get-WitnessValue $Connection)-ne200 -or
    (Get-ModuleState $Connection)-cne$BeforeModule){throw 'JSON_CALLER_TX_SAVEPOINT_ORACLE'}
 Sql $Connection 'ROLLBACK TRANSACTION;'
 $rollbackState=Get-LocalTransactionState $Connection
 if([int]$rollbackState.TranCount-ne0 -or [int]$rollbackState.XactState-ne0 -or (Get-WitnessValue $Connection)-ne100 -or
    [int](Read-Scalar $Connection 'SELECT @@OPTIONS AS ScalarValue;')-ne$OriginalOptions -or
    -not(Test-ExternalSessionIdle (Get-ExternalSessionState $Observer $spid) $spid)){throw 'JSON_CALLER_TX_FULL_ROLLBACK_ORACLE'}
 $script:ledger.results+=@([ordered]@{ordinal=[int]$Case.ordinal;operation=[string]$Case.operation;blocked=$true;exact_error=$true;
  transaction_preserved=$true;session_preserved=$true;options_preserved=$true;module_snapshot_preserved=$true;witness_preserved=$true;application_locks_absent=$true;
  witness_values=[ordered]@{committed_before=100;first_update=200;guard_before=300;guard_after=300;savepoint_rollback=200;full_rollback=100}})
 Save-Journal
}
function Assert-CoreStable($Connection,[string]$BeforeCore){if((Read-CoreProjection $Connection)-cne$BeforeCore){throw 'JSON_CALLER_TX_CORE_CHANGED'}}
function Invoke-PinnedSqlBatches($Connection,[string]$Path,[string]$ExpectedSHA256){
 Assert-RunsetStable;Assert-ReleasePin $Path $ExpectedSHA256
 $text=[IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8)
 $text=[regex]::Replace($text,'(?im)^\s*:ON\s+ERROR\s+EXIT\s*$','')
 if($text-match'(?m)^\s*:' -or $text.Contains('$(')){throw 'JSON_CALLER_TX_UNRESOLVED_SQLCMD'}
 foreach($batch in [regex]::Split($text,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
  if(-not[string]::IsNullOrWhiteSpace($batch)){Sql $Connection $batch}
 }
}

try{
 Assert-Runset;Get-LabSelectorTarget
 if($ValidateOnly){Assert-RunsetStable;& (Join-Path $PSScriptRoot 'Test-JsonSchemaCallerTransactionOffline.ps1') | Out-Null;Assert-RunsetStable;Write-Output 'PASS JSON_SCHEMA_CALLER_TRANSACTION runset validated; no SQL executed';return}
 $script:journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $script:RunsetPath) 'case.json')
 if($AuditOnly){
  $prior=Get-Content -LiteralPath $script:journal -Raw -Encoding UTF8|ConvertFrom-Json
  if($prior.state-cne'COMPLETE' -or $prior.owner-cnotmatch'^[a-f0-9]{32}$' -or @($prior.databases).Count-ne1 -or
     @($prior.results).Count-ne2 -or @($prior.positive_controls).Count-ne2){throw 'JSON_CALLER_TX_AUDIT_JOURNAL_INVALID'}
  for($i=0;$i-lt2;$i++){
   $result=$prior.results[$i];$controlRecord=$prior.positive_controls[$i]
   $expectedOperation=@('deploy','uninstall')[$i]
   $resultFlags=@('blocked','exact_error','transaction_preserved','session_preserved','options_preserved','module_snapshot_preserved','witness_preserved','application_locks_absent')
   $controlFlags=@('succeeded','module_state_correct','core_unchanged')
   $witnessNames=@('committed_before','first_update','guard_before','guard_after','savepoint_rollback','full_rollback')
   if($result.ordinal-ne$i -or $result.operation-cne$expectedOperation -or
      $controlRecord.ordinal-ne$i -or $controlRecord.operation-cne$expectedOperation -or
      @($result.witness_values.PSObject.Properties).Count-ne$witnessNames.Count){throw 'JSON_CALLER_TX_AUDIT_RESULT_INVALID'}
   foreach($flag in $resultFlags){if($result.$flag-isnot[bool]-or-not[bool]$result.$flag){throw 'JSON_CALLER_TX_AUDIT_RESULT_INVALID'}}
   foreach($flag in $controlFlags){if($controlRecord.$flag-isnot[bool]-or-not[bool]$controlRecord.$flag){throw 'JSON_CALLER_TX_AUDIT_RESULT_INVALID'}}
   $expectedWitness=[ordered]@{committed_before=100;first_update=200;guard_before=300;guard_after=300;savepoint_rollback=200;full_rollback=100}
   foreach($name in $witnessNames){$value=$result.witness_values.$name;if(($value-isnot[int]-and$value-isnot[long]) -or $value-ne$expectedWitness[$name]){throw 'JSON_CALLER_TX_AUDIT_RESULT_INVALID'}}
  }
  $dbRecord=$prior.databases[0]
  if($dbRecord.name-cne('Toolbelt_Release_'+$prior.owner+'_u') -or $dbRecord.state-cne'DROPPED'){throw 'JSON_CALLER_TX_AUDIT_OWNER_INVALID'}
  Assert-ReleaseInputs;$control=Open-ReleaseConnection 'master'
  $found=@(Sql $control 'SELECT DB_ID(@Name) Id;' @{ '@Name'=$dbRecord.name } -Rows)
  if($found.Count-ne1 -or ($null-ne$found[0].Id -and $found[0].Id-isnot[DBNull])){throw 'JSON_CALLER_TX_AUDIT_DATABASE_PRESENT'}
  if(@($prior.trust).Count-ne$script:runset.artifacts.Count){throw 'JSON_CALLER_TX_AUDIT_TRUST_SHAPE'}
  foreach($artifact in $script:runset.artifacts){
   $entry=@($prior.trust|Where-Object{$_.hash-ceq$artifact.sha512});if($entry.Count-ne1 -or $entry[0].preexisting-isnot[bool]){throw 'JSON_CALLER_TX_AUDIT_TRUST_SHAPE'}
   $actual=Get-ClrCallerTrust $control ([Convert]::FromHexString($entry[0].hash))
   if(($entry[0].preexisting -and ($null-eq$actual -or $actual.Fingerprint-cne$entry[0].fingerprint)) -or
      (-not$entry[0].preexisting -and ($null-ne$actual -or $entry[0].state-cne'REMOVED'))){throw 'JSON_CALLER_TX_AUDIT_TRUST_DRIFT'}
  }
  $configRows=@($prior.configuration.before|Where-Object{$_.Name-ceq'clr enabled'})
  if($prior.configuration.changed-isnot[bool] -or $prior.configuration.state-cnotin@('PREEXISTING','RESTORED') -or $configRows.Count-ne1){throw 'JSON_CALLER_TX_AUDIT_CONFIGURATION_SHAPE'}
  Assert-ClrCallerConfiguration $control $prior.configuration;Assert-ReleaseInputs
 }else{
  if(Test-Path -LiteralPath $script:journal){throw 'JSON_CALLER_TX_ALREADY_ATTEMPTED'}
  $script:ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();trust=@();target=[ordered]@{platform='windows';version='2025';patch='CU8';compatibility_level=170};
   configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()};results=@();positive_controls=@();witness=[ordered]@{table='dbo.JsonSchemaCallerTransactionWitness';baseline=100};failure=$null}
  Save-Journal;$control=Open-ReleaseConnection 'master'
  $actual=@(Sql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count-ne1 -or [int]$actual[0].Major-ne17 -or $actual[0].Platform-ine'windows' -or [int]$actual[0].Admin-ne1){throw 'JSON_CALLER_TX_ACTUAL_TARGET_MISMATCH'}
  $script:stage='CONFIGURATION';Start-ClrCallerConfiguration $control
  $script:stage='TRUST'
  foreach($artifact in $script:runset.artifacts){
   $hash=[Convert]::FromHexString($artifact.sha512);$before=Get-ClrCallerTrust $control $hash
   $entry=[ordered]@{hash=$artifact.sha512;preexisting=($null-ne$before);fingerprint=$null;state='PREEXISTING';description=$null}
   if($before){$entry.fingerprint=$before.Fingerprint};$script:ledger.trust+=@($entry);Save-Journal
   if(-not$before){Assert-ClrCallerTrustCleanupScope $control $hash;$entry.state='ADDING';$entry.description='Contoso JSON Schema Caller Transaction '+$script:ledger.owner;Save-Journal
    Sql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{ '@Hash'=$hash;'@Description'=$entry.description }
    $after=Get-ClrCallerTrust $control $hash;if($null-eq$after-or$after.description-cne$entry.description){throw 'JSON_CALLER_TX_TRUST_OWNERSHIP_UNKNOWN'}
    $entry.fingerprint=$after.Fingerprint;$entry.state='OWNED';Save-Journal
   }
  }
  $name='Toolbelt_Release_'+$script:ledger.owner+'_u';$entry=[ordered]@{name=$name;suffix='u';id=$null;created=$null;state='CREATING'};$script:ledger.databases+=@($entry);Save-Journal
  Sql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Synthetic collision.',1; CREATE DATABASE [$name] COLLATE Latin1_General_100_BIN2;"
  $identity=@(Sql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{ '@Name'=$name } -Rows)
  if($identity.Count-ne1){throw 'JSON_CALLER_TX_DATABASE_IDENTITY'};$entry.id=[int]$identity[0].Id;$entry.created=[string]$identity[0].Created;$entry.state='CREATED';Save-Journal
  $db=Open-ReleaseConnection $name;Sql $db 'DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Test.Release.Owner'',@value=@O;' @{ '@Owner'=$script:ledger.owner }
  $entry.state='OWNED';Save-Journal;Sql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=170;"
  $script:stage='BASELINE';[void](Set-GuardSessionProfile $db);Invoke-PinnedSqlBatches $db $script:runset.baseline.path $script:runset.baseline.sha256
  Assert-CoreOnly $db;Assert-SchemaAbsent $db
  Sql $db 'CREATE TABLE dbo.JsonSchemaCallerTransactionWitness(WitnessId int NOT NULL PRIMARY KEY,WitnessValue int NOT NULL); INSERT dbo.JsonSchemaCallerTransactionWitness(WitnessId,WitnessValue) VALUES(1,100);'
  $script:stage='SESSION_PROFILE'
  $case0Options=Set-GuardSessionProfile $db
  $coreBefore=Read-CoreProjection $db
  $absentState=Get-ModuleState $db
  $script:stage='CASE_0'
  if((Get-WitnessValue $db)-ne100 -or (Get-ModuleState $db)-cne$absentState){throw 'JSON_CALLER_TX_ABSENT_BASELINE_DRIFT'}
  Invoke-BlockedTransactionCase $db $control $script:runset.scope.cases[0] $absentState $case0Options
  Invoke-PinnedLifecycle 'deploy';Assert-SchemaInstalled $db;Assert-CoreStable $db $coreBefore
  $script:ledger.positive_controls+=@([ordered]@{ordinal=0;operation='deploy';succeeded=$true;module_state_correct=$true;core_unchanged=$true});Save-Journal
  $script:stage='SESSION_PROFILE_1';$case1Options=Set-GuardSessionProfile $db
  $script:stage='CASE_1';$installedState=Get-ModuleState $db
  Invoke-BlockedTransactionCase $db $control $script:runset.scope.cases[1] $installedState $case1Options
  Invoke-PinnedLifecycle 'uninstall';Assert-SchemaModuleAbsent $db;Assert-CoreOnly $db;Assert-CoreStable $db $coreBefore
  $script:ledger.positive_controls+=@([ordered]@{ordinal=1;operation='uninstall';succeeded=$true;module_state_correct=$true;core_unchanged=$true});Save-Journal
  $script:ledger.state='COMPLETE';Save-Journal;Assert-ReleaseInputs
 }
}catch{$script:failure=$_.Exception;if($ValidateOnly){throw};if($script:ledger -and -not$AuditOnly){$script:ledger.failure=[ordered]@{stage=$script:stage;privateDiagnostic=$script:failure.Message};Save-Journal}}
finally{
 foreach($connection in $script:connections){try{$connection.Dispose()}catch{}};[Data.SqlClient.SqlConnection]::ClearAllPools()
 if($script:ledger -and -not$AuditOnly){try{
  $control=Open-ReleaseConnection 'master'
  foreach($database in $script:ledger.databases){Assert-RunsetStable;Assert-ReleaseOwnIdentity $control $database;$database.state='DROPPED';Save-Journal}
  foreach($trust in $script:ledger.trust){$hash=[Convert]::FromHexString($trust.hash);$actual=Get-ClrCallerTrust $control $hash
   if($trust.preexisting){if($null-eq$actual-or$actual.Fingerprint-cne$trust.fingerprint){throw 'JSON_CALLER_TX_PREEXISTING_TRUST_DRIFT'};continue}
   if($trust.state-cne'OWNED'-or$null-eq$actual-or$actual.Fingerprint-cne$trust.fingerprint-or$actual.description-cne$trust.description){throw 'JSON_CALLER_TX_TRUST_CLEANUP_IDENTITY'}
   Assert-ClrCallerTrustCleanupScope $control $hash;Sql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{ '@Hash'=$hash }
   if($null-ne(Get-ClrCallerTrust $control $hash)){throw 'JSON_CALLER_TX_TRUST_NOT_REMOVED'};$trust.state='REMOVED';Save-Journal
  }
  Restore-ClrCallerConfiguration $control;$script:ledger.state=if($script:failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-Journal
 }catch{$script:ledger.state='CLEANUP_BLOCKED';$script:ledger.privateCleanupDiagnostic=$_.Exception.Message;Save-Journal;$script:failure=$_.Exception}finally{if($control){$control.Dispose()}}}
}
if($script:failure){Write-Output 'FAIL JSON_SCHEMA_CALLER_TRANSACTION; inspect private journal';exit 1}
if($AuditOnly){Write-Output 'PASS JSON_SCHEMA_CALLER_TRANSACTION independent cleanup audit'}else{Write-Output 'PASS JSON_SCHEMA_CALLER_TRANSACTION two rejection and lifecycle controls; audit required'}
