[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedRunsetSHA256,
 [switch]$ValidateOnly,[switch]$AuditOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$script:RunsetPath=$RunsetPath;$script:ExpectedRunsetSHA256=$ExpectedRunsetSHA256
$script:connections=[Collections.Generic.List[object]]::new();$script:clock=[Diagnostics.Stopwatch]::StartNew();$script:cleanup=$false
$script:ledger=$null;$script:failure=$null;$script:stage='PREPARE';$script:cleanupBlocked=$false;$ledger=$null;$control=$null;$db=$null

$apiErrors=$null;$apiAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$apiErrors)
if($apiErrors.Count){throw 'JSON_DEPLOY_COLLISION_HELPER_PARSE'}
$apiImports=@($apiAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($apiImports.Count-ne1){throw 'JSON_DEPLOY_COLLISION_IMPORTER_MISSING'}
. ([scriptblock]::Create($apiImports[0].Extent.Text))
$stablePath=Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'
foreach($block in Import-ClrFunctions $stablePath @('Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
    'Open-ReleaseConnection','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity') @{'function Invoke-ReleaseSql('='function Invoke-ReleaseSqlCore('}){. $block}
. (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')
. (Join-Path $script:repo 'Tests/CI/LabQualifiedContract.ps1')
foreach($block in Import-ClrFunctions (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1') @(
    'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}

# Geschützte JSON-Schema-/SQL-Helper werden exakt aus den bereits geprüften
# Adaptern importiert; ihre Dateien und ursprünglichen Pins bleiben unverändert.
$r33Path=Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1'
$r34Path=Join-Path $PSScriptRoot 'Invoke-JsonSchemaUninstallAppLockLab.ps1'
$r35Path=Join-Path $PSScriptRoot 'Invoke-JsonSchemaCallerTransactionLab.ps1'
foreach($source in @(
 [pscustomobject]@{path=$r33Path;names=@('Sql','Read-Scalar','Get-ModuleState','Assert-CoreOnly','Assert-SchemaAbsent','Assert-SchemaModuleAbsent','Get-ExternalSessionState','Test-ExternalSessionIdle')},
 [pscustomobject]@{path=$r34Path;names=@('Get-LabSelectorTarget','Save-Journal','Read-CoreProjection','Assert-SchemaAssemblyClosure','Assert-SchemaSlots','Assert-SchemaInstalled','Assert-RunsetStable','Invoke-ReleaseSql')},
 [pscustomobject]@{path=$r35Path;names=@('Get-LocalTransactionState','Invoke-PinnedSqlBatches')}
)){
 $sourceErrors=$null;$sourceAst=[Management.Automation.Language.Parser]::ParseFile($source.path,[ref]$null,[ref]$sourceErrors)
 if($sourceErrors.Count){throw 'JSON_DEPLOY_COLLISION_SOURCE_PARSE'}
 foreach($name in $source.names){$found=@($sourceAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true));if($found.Count-ne1){throw 'JSON_DEPLOY_COLLISION_SOURCE_FUNCTION'};. ([scriptblock]::Create($found[0].Extent.Text))}
}

function Assert-CaseShape($Cases){
 $expected=@(
  [pscustomobject]@{ordinal=0;kind='reserved_temp';object_name='#tbx_JsonSchema_DeployState';expected_error=55633;expected_state=1;expected_message='JSON Schema lifecycle: reservierter Callerzustand belegt.'},
  [pscustomobject]@{ordinal=1;kind='public_slot';object_name='USP_ValidateJsonSchema';fixture_type='U';fixture_value=701;expected_error=55634;expected_state=1;expected_message='JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'},
  [pscustomobject]@{ordinal=2;kind='internal_slot';object_name='FT_ValidateJsonSchemaInternal';fixture_type='U';fixture_value=702;expected_error=55634;expected_state=1;expected_message='JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'},
  [pscustomobject]@{ordinal=3;kind='orphan_mode';property_name='Toolbelt.Module.toolbelt.json.schema.DeploymentMode';property_value='local';expected_error=55634;expected_state=1;expected_message='JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'})
 if(@($Cases).Count-ne$expected.Count){throw 'JSON_DEPLOY_COLLISION_CASES_INVALID'}
 for($i=0;$i-lt$expected.Count;$i++){
  $actual=$Cases[$i];$wanted=$expected[$i]
  if(($actual.ordinal-isnot[int]-and$actual.ordinal-isnot[long])-or$actual.ordinal-ne$i-or$actual.kind-cne$wanted.kind-or
     ($i-lt3-and$actual.object_name-cne$wanted.object_name)-or($actual.expected_error-isnot[int]-and$actual.expected_error-isnot[long])-or$actual.expected_error-ne$wanted.expected_error-or
     ($actual.expected_state-isnot[int]-and$actual.expected_state-isnot[long])-or$actual.expected_state-ne1-or$actual.expected_message-cne$wanted.expected_message){throw 'JSON_DEPLOY_COLLISION_CASES_INVALID'}
  if($i-in@(1,2)-and($actual.fixture_type-cne'U'-or($actual.fixture_value-isnot[int]-and$actual.fixture_value-isnot[long])-or$actual.fixture_value-ne$wanted.fixture_value)){throw 'JSON_DEPLOY_COLLISION_CASES_INVALID'}
  if($i-eq3-and($actual.property_name-cne$wanted.property_name-or$actual.property_value-cne$wanted.property_value)){throw 'JSON_DEPLOY_COLLISION_CASES_INVALID'}
 }
}
function Assert-Runset {
 $script:RunsetPath=Assert-ReleasePrivatePath $script:RunsetPath
 if((Get-FileHash -LiteralPath $script:RunsetPath -Algorithm SHA256).Hash-cne$script:ExpectedRunsetSHA256.ToUpperInvariant()){throw 'JSON_DEPLOY_COLLISION_RUNSET_PIN_DRIFT'}
 $script:runset=Get-Content -LiteralPath $script:RunsetPath -Raw -Encoding UTF8|ConvertFrom-Json
 if($script:runset.schema_version-cne'json-schema-deploy-collision-probe/v1'-or$script:runset.operation-cne'json-schema-deploy-collision'-or
    $script:runset.target.platform-cne'windows'-or$script:runset.target.version-cne'2025'-or$script:runset.target.patch-cne'CU8'-or
    ($script:runset.target.compatibility_level-isnot[int]-and$script:runset.target.compatibility_level-isnot[long])-or$script:runset.target.compatibility_level-ne170-or$script:runset.target.test_purpose-cne'Functional'-or
    $script:runset.scope.deployment_mode-cne'local'-or$script:runset.scope.namespace_owner-cne'same_as_core'-or
    ($script:runset.scope.case_count-isnot[int]-and$script:runset.scope.case_count-isnot[long])-or$script:runset.scope.case_count-ne4-or
    $script:runset.scope.positive_control-cne'one same-input Deploy after all owned fixtures are removed'-or
    @($script:runset.artifacts).Count-ne2-or @($script:runset.baseline.modules).Count-ne2-or
    $script:runset.baseline.modules[0]-cne'toolbelt.core.result-table'-or$script:runset.baseline.modules[1]-cne'toolbelt.json.core'-or
    $script:runset.schema_deploy.module-cne'toolbelt.json.schema'){throw 'JSON_DEPLOY_COLLISION_RUNSET_INVALID'}
 Assert-CaseShape @($script:runset.scope.cases)
 if(@($script:runset.pins).Count-lt8){throw 'JSON_DEPLOY_COLLISION_RUNSET_PINS_INVALID'}
 $pinPaths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($pin in $script:runset.pins){if($pin.path-isnot[string]-or$pin.sha256-isnot[string]-or$pin.sha256-cnotmatch'^[A-Fa-f0-9]{64}$'-or-not$pinPaths.Add([IO.Path]::GetFullPath($pin.path))){throw 'JSON_DEPLOY_COLLISION_RUNSET_PINS_INVALID'};Assert-ReleasePin $pin.path $pin.sha256}
 foreach($path in @($script:runset.schema_deploy.path,$script:runset.baseline.path,$script:runset.base_runset.path)){
  if($path-isnot[string]-or-not$pinPaths.Contains([IO.Path]::GetFullPath($path))){throw 'JSON_DEPLOY_COLLISION_RUNSET_BINDING_INVALID'}
 }
 if($script:runset.base_runset.sha256-isnot[string]-or$script:runset.base_runset.sha256-cnotmatch'^[A-Fa-f0-9]{64}$'){throw 'JSON_DEPLOY_COLLISION_RUNSET_BINDING_INVALID'}
 Assert-ReleasePin $script:runset.base_runset.path $script:runset.base_runset.sha256
}
function Assert-RunsetStable {
 if((Get-FileHash -LiteralPath $script:RunsetPath -Algorithm SHA256).Hash-cne$script:ExpectedRunsetSHA256.ToUpperInvariant()){throw 'JSON_DEPLOY_COLLISION_RUNSET_PIN_DRIFT'}
 Assert-ReleaseInputs
}
function Assert-FixtureSnapshot($Connection,$Case,$Expected){
 $actual=Get-FixtureSnapshot $Connection $Case
 if($actual-cne$Expected){throw 'JSON_DEPLOY_COLLISION_FIXTURE_DRIFT'}
}
function Get-FixtureSnapshot($Connection,$Case){
 switch([string]$Case.kind){
  'reserved_temp' {
   $objectId=Read-Scalar $Connection "SELECT OBJECT_ID(N'tempdb..#tbx_JsonSchema_DeployState',N'U') AS ScalarValue;"
   if($null-eq$objectId-or$objectId-is[DBNull]){return '{"exists":false}'}
   $rows=@(Sql $Connection @'
SELECT OBJECT_ID(N'tempdb..#tbx_JsonSchema_DeployState',N'U') ObjectId,
 (SELECT c.column_id,c.name,TYPE_NAME(c.user_type_id) TypeName,c.max_length,c.is_nullable
  FROM tempdb.sys.columns c WHERE c.object_id=OBJECT_ID(N'tempdb..#tbx_JsonSchema_DeployState',N'U') ORDER BY c.column_id FOR JSON PATH) Columns,
 (SELECT COUNT(*) FROM tempdb..#tbx_JsonSchema_DeployState) RowCount,
 (SELECT MIN(Sentinel) FROM tempdb..#tbx_JsonSchema_DeployState) Sentinel;
'@ -Rows)
   if($rows.Count-ne1){throw 'JSON_DEPLOY_COLLISION_TEMP_SNAPSHOT_SHAPE'}
   return ($rows[0]|ConvertTo-Json -Depth 4 -Compress)
  }
  'public_slot' {$name='USP_ValidateJsonSchema'}
  'internal_slot' {$name='FT_ValidateJsonSchemaInternal'}
  'orphan_mode' {
   $rows=@(Sql $Connection @'
SELECT ep.class,ep.major_id,ep.minor_id,ep.name,SQL_VARIANT_PROPERTY(ep.value,N'BaseType') BaseType,
 DATALENGTH(ep.value) DataLength,CONVERT(nvarchar(128),ep.value) Value
FROM sys.extended_properties ep WHERE ep.class=0 AND ep.name=@Name;
'@ @{ '@Name'=[string]$Case.property_name } -Rows)
   if($rows.Count-eq0){return '{"exists":false}'}
   if($rows.Count-ne1){throw 'JSON_DEPLOY_COLLISION_MARKER_SNAPSHOT_SHAPE'}
   return ($rows|ConvertTo-Json -Depth 4 -Compress)
  }
  default {throw 'JSON_DEPLOY_COLLISION_CASE_KIND_INVALID'}
 }
 $objectId=Read-Scalar $Connection 'SELECT OBJECT_ID(N''toolbelt_json.''+QUOTENAME(@Name)) AS ScalarValue;' @{ '@Name'=[string]$name }
 if($null-eq$objectId-or$objectId-is[DBNull]){return '{"exists":false}'}
 $rows=@(Sql $Connection @'
DECLARE @ObjectId int=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(@Name));
DECLARE @Data TABLE(RowCount bigint,Sentinel int NULL);
DECLARE @DataSql nvarchar(max)=N'SELECT COUNT_BIG(*) RowCount,MIN(Sentinel) Sentinel FROM [toolbelt_json].'+QUOTENAME(@Name)+N';';
INSERT @Data EXEC sys.sp_executesql @DataSql;
SELECT @ObjectId ObjectId,
 (SELECT o.name,RTRIM(o.type) TypeName,o.principal_id,sm.definition
  FROM sys.objects o LEFT JOIN sys.sql_modules sm ON sm.object_id=o.object_id WHERE o.object_id=@ObjectId FOR JSON PATH) ObjectShape,
 (SELECT c.column_id,c.name,TYPE_NAME(c.user_type_id) TypeName,c.max_length,c.is_nullable
  FROM sys.columns c WHERE c.object_id=@ObjectId ORDER BY c.column_id FOR JSON PATH) Columns,
 (SELECT RowCount FROM @Data) RowCount,(SELECT Sentinel FROM @Data) Sentinel;
'@ @{ '@Name'=[string]$name } -Rows)
 if($rows.Count-ne1){throw 'JSON_DEPLOY_COLLISION_SLOT_SNAPSHOT_SHAPE'}
 return ($rows[0]|ConvertTo-Json -Depth 4 -Compress)
}
function New-Fixture($Connection,$Case){
 Assert-RunsetStable
 switch([string]$Case.kind){
  'reserved_temp' {
   if((Read-Scalar $Connection "SELECT CASE WHEN OBJECT_ID(N'tempdb..#tbx_JsonSchema_DeployState',N'U') IS NULL THEN 1 ELSE 0 END AS ScalarValue;")-ne1){throw 'JSON_DEPLOY_COLLISION_TEMP_ALREADY_EXISTS'}
   $script:ledger.active_fixture=[ordered]@{ordinal=[int]$Case.ordinal;kind=[string]$Case.kind;state='CREATING';snapshot=$null;module_snapshot=$null}
   Save-Journal
   Sql $Connection 'CREATE TABLE #tbx_JsonSchema_DeployState(Sentinel int NOT NULL); INSERT #tbx_JsonSchema_DeployState(Sentinel) VALUES(700);'
  }
  {$_-in'public_slot','internal_slot'} {
   $objectName=[string]$Case.object_name
   $exists=@(Sql $Connection 'SELECT OBJECT_ID(N''toolbelt_json.''+QUOTENAME(@Name)) ObjectId;' @{ '@Name'=$objectName } -Rows)
   if($exists.Count-ne1-or$null-ne$exists[0].ObjectId){throw 'JSON_DEPLOY_COLLISION_SLOT_ALREADY_EXISTS'}
   $script:ledger.active_fixture=[ordered]@{ordinal=[int]$Case.ordinal;kind=[string]$Case.kind;state='CREATING';snapshot=$null;module_snapshot=$null}
   Save-Journal
   Sql $Connection "DECLARE @Sql nvarchar(max)=N'CREATE TABLE [toolbelt_json].'+QUOTENAME(@Name)+N' (Sentinel int NOT NULL); INSERT [toolbelt_json].'+QUOTENAME(@Name)+N' (Sentinel) VALUES(@Value);'; EXEC sys.sp_executesql @Sql,N'@Value int',@Value=@Value;" @{ '@Name'=$objectName;'@Value'=[int]$Case.fixture_value }
  }
  'orphan_mode' {
   $exists=@(Sql $Connection 'SELECT COUNT(*) Count FROM sys.extended_properties WHERE class=0 AND name=@Name;' @{ '@Name'=[string]$Case.property_name } -Rows)
   if($exists.Count-ne1-or[int]$exists[0].Count-ne0){throw 'JSON_DEPLOY_COLLISION_MARKER_ALREADY_EXISTS'}
   $script:ledger.active_fixture=[ordered]@{ordinal=[int]$Case.ordinal;kind=[string]$Case.kind;state='CREATING';snapshot=$null;module_snapshot=$null}
   Save-Journal
   Sql $Connection 'EXEC sys.sp_addextendedproperty @name=@Name,@value=@Value;' @{ '@Name'=[string]$Case.property_name;'@Value'=[string]$Case.property_value }
  }
  default {throw 'JSON_DEPLOY_COLLISION_CASE_KIND_INVALID'}
 }
 $fixture=Get-FixtureSnapshot $Connection $Case
 if($fixture-cne'{"exists":false}'){
  $script:ledger.active_fixture.state='OWNED';$script:ledger.active_fixture.snapshot=$fixture;$script:ledger.active_fixture.module_snapshot=Get-ModuleState $Connection;Save-Journal
 }else{throw 'JSON_DEPLOY_COLLISION_FIXTURE_CREATE_FAILED'}
 return $fixture
}
function Remove-OwnedFixture($Connection,$Case,[string]$Expected){
 Assert-RunsetStable
 Assert-FixtureSnapshot $Connection $Case $Expected
 switch([string]$Case.kind){
  'reserved_temp' {Sql $Connection 'DROP TABLE #tbx_JsonSchema_DeployState;'}
  {$_-in'public_slot','internal_slot'} {Sql $Connection @'
DECLARE @Sql nvarchar(max)=N'DROP TABLE [toolbelt_json].'+QUOTENAME(@Name)+N';';
EXEC sys.sp_executesql @Sql;
'@ @{ '@Name'=[string]$Case.object_name }}
  'orphan_mode' {Sql $Connection 'EXEC sys.sp_dropextendedproperty @name=@Name;' @{ '@Name'=[string]$Case.property_name }}
  default {throw 'JSON_DEPLOY_COLLISION_CASE_KIND_INVALID'}
 }
 $after=Get-FixtureSnapshot $Connection $Case
 if($after-cne'{"exists":false}'){throw 'JSON_DEPLOY_COLLISION_FIXTURE_NOT_REMOVED'}
 $script:ledger.active_fixture=$null;Save-Journal
}
function Assert-CleanupFixtureOwnership {
 if($null-eq$script:ledger.active_fixture){return}
 $active=$script:ledger.active_fixture
 if($active.state-cne'OWNED'-or$active.ordinal-isnot[int]-or$active.snapshot-isnot[string]-or
    $active.module_snapshot-isnot[string]-or$null-eq$db-or$db.State-ne[Data.ConnectionState]::Open){throw 'JSON_DEPLOY_COLLISION_CLEANUP_FIXTURE_OWNERSHIP_UNKNOWN'}
 if((Get-ModuleState $db)-cne$active.module_snapshot){throw 'JSON_DEPLOY_COLLISION_CLEANUP_MODULE_DRIFT'}
 $case=$script:runset.scope.cases[[int]$active.ordinal]
 Assert-FixtureSnapshot $db $case ([string]$active.snapshot)
 Remove-OwnedFixture $db $case ([string]$active.snapshot)
 if($null-eq$script:ledger.expected_database_snapshot-or(Get-ModuleState $db)-cne[string]$script:ledger.expected_database_snapshot){throw 'JSON_DEPLOY_COLLISION_CLEANUP_BASELINE_DRIFT'}
}
function Assert-TargetIdle($Connection,$Observer,[int]$Spid){
 if($Connection.State-ne[Data.ConnectionState]::Open-or[int](Read-Scalar $Connection 'SELECT @@SPID AS ScalarValue;')-ne$Spid){throw 'JSON_DEPLOY_COLLISION_SESSION_CHANGED'}
 $state=Get-LocalTransactionState $Connection
 if([int]$state.TranCount-ne0-or[int]$state.XactState-ne0){throw 'JSON_DEPLOY_COLLISION_TRANSACTION_REMAINS'}
 $external=@(Get-ExternalSessionState $Observer $Spid)
 if(-not(Test-ExternalSessionIdle $external $Spid)){throw 'JSON_DEPLOY_COLLISION_EXTERNAL_STATE_REMAINS'}
}
function Invoke-DeployCollisionCase($Connection,$Observer,$Case,[string]$BaselineState,[string]$CoreBefore){
 $spid=[int](Read-Scalar $Connection 'SELECT @@SPID AS ScalarValue;')
 Assert-TargetIdle $Connection $Observer $spid
 if((Get-ModuleState $Connection)-cne$BaselineState){throw 'JSON_DEPLOY_COLLISION_BASELINE_DRIFT'}
 $fixtureBefore=New-Fixture $Connection $Case
 $fixtureState=Get-ModuleState $Connection
 if($script:ledger.active_fixture){$script:ledger.active_fixture.module_snapshot=$fixtureState;Save-Journal}
 $tempBefore=if($Case.kind-ceq'reserved_temp'){$fixtureBefore}else{$null}
 $caught=$null
 try{Invoke-PinnedSqlBatches $Connection ([string]$script:runset.schema_deploy.path) ([string]$script:runset.schema_deploy.sha256)}catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}
 if($caught-isnot[Data.SqlClient.SqlException]-or$caught.Number-ne[int]$Case.expected_error-or$caught.State-ne[int]$Case.expected_state-or$caught.Class-ne16-or
    @($caught.Errors|Where-Object{$_.Number-eq[int]$Case.expected_error-and$_.State-eq[int]$Case.expected_state-and$_.Class-eq16-and$_.Message-ceq[string]$Case.expected_message}).Count-ne1){throw 'JSON_DEPLOY_COLLISION_EXPECTED_ERROR_MISMATCH'}
 Assert-TargetIdle $Connection $Observer $spid
 if((Get-ModuleState $Connection)-cne$fixtureState){throw 'JSON_DEPLOY_COLLISION_MODULE_STATE_CHANGED'}
 Assert-FixtureSnapshot $Connection $Case $fixtureBefore
 if($Case.kind-ceq'reserved_temp'-and$fixtureBefore-cne$tempBefore){throw 'JSON_DEPLOY_COLLISION_TEMP_PRESERVATION_FAILED'}
 if((Read-CoreProjection $Connection)-cne$CoreBefore){throw 'JSON_DEPLOY_COLLISION_CORE_CHANGED'}
 Remove-OwnedFixture $Connection $Case $fixtureBefore
 if((Get-ModuleState $Connection)-cne$BaselineState){throw 'JSON_DEPLOY_COLLISION_SNAPSHOT_NOT_RESTORED'}
 Assert-TargetIdle $Connection $Observer $spid
  $script:ledger.results+=@([ordered]@{ordinal=[int]$Case.ordinal;kind=[string]$Case.kind;expected_error=[int]$Case.expected_error;expected_state=[int]$Case.expected_state;expected_message=[string]$Case.expected_message;
  exact_error=$true;blocked_before_mutation=$true;module_snapshot_unchanged=$true;fixture_preserved=$true;fixture_removed=$true;core_unchanged=$true;
  contender_session_unchanged=$true;transaction_absent=$true;application_locks_absent=$true})
 Save-Journal
}
function Assert-AuditPrefix($Prior){
 $count=@($Prior.results).Count;$controls=@($Prior.positive_controls).Count
 if(($Prior.state-cne'COMPLETE'-and$Prior.state-cne'FAILED_CLEANED')-or$Prior.owner-cnotmatch'^[a-f0-9]{32}$'-or
    ($Prior.state-ceq'COMPLETE'-and$count-ne4)-or($Prior.state-ceq'FAILED_CLEANED'-and$count-gt4)-or
    ($Prior.state-ceq'COMPLETE'-and$controls-ne1)-or$controls-gt1-or$controls-gt$count){throw 'JSON_DEPLOY_COLLISION_AUDIT_JOURNAL_INVALID'}
 $kinds=@('reserved_temp','public_slot','internal_slot','orphan_mode');$expectedErrors=@(55633,55634,55634,55634);$expectedMessages=@(
  'JSON Schema lifecycle: reservierter Callerzustand belegt.',
  'JSON Schema lifecycle: unregistrierter oder fremder Zielslot.',
  'JSON Schema lifecycle: unregistrierter oder fremder Zielslot.',
  'JSON Schema lifecycle: unregistrierter oder fremder Zielslot.')
 for($i=0;$i-lt$count;$i++){$item=$Prior.results[$i];if(($item.ordinal-isnot[int]-and$item.ordinal-isnot[long])-or$item.ordinal-ne$i-or$item.kind-cne$kinds[$i]-or
    ($item.expected_error-isnot[int]-and$item.expected_error-isnot[long])-or$item.expected_error-ne$expectedErrors[$i]-or
    ($item.expected_state-isnot[int]-and$item.expected_state-isnot[long])-or$item.expected_state-ne1-or$item.expected_message-cne$expectedMessages[$i]){throw 'JSON_DEPLOY_COLLISION_AUDIT_RESULT_INVALID'}
   foreach($flag in @('exact_error','blocked_before_mutation','module_snapshot_unchanged','fixture_preserved','fixture_removed','core_unchanged','contender_session_unchanged','transaction_absent','application_locks_absent')){if($item.$flag-isnot[bool]-or-not[bool]$item.$flag){throw 'JSON_DEPLOY_COLLISION_AUDIT_RESULT_INVALID'}}
 }
 if($controls-eq1){$control=$Prior.positive_controls[0];foreach($flag in @('deploy_succeeded','schema_installed','core_unchanged')){if($control.$flag-isnot[bool]-or-not[bool]$control.$flag){throw 'JSON_DEPLOY_COLLISION_AUDIT_CONTROL_INVALID'}}}
 return [pscustomobject]@{result_count=$count;control_count=$controls}
}

try{
 Assert-Runset;Get-LabSelectorTarget
 if($ValidateOnly){Assert-RunsetStable;& (Join-Path $PSScriptRoot 'Test-JsonSchemaDeployCollisionOffline.ps1')|Out-Null;Assert-RunsetStable;Write-Output 'PASS JSON_SCHEMA_DEPLOY_COLLISION runset validated; no SQL executed';return}
 $script:journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $script:RunsetPath) 'case.json')
 if($AuditOnly){
  $prior=Get-Content -LiteralPath $script:journal -Raw -Encoding UTF8|ConvertFrom-Json;$prefix=Assert-AuditPrefix $prior
  if(@($prior.databases).Count-ne1){throw 'JSON_DEPLOY_COLLISION_AUDIT_DATABASE_SHAPE'}
  $entry=$prior.databases[0]
  if($entry.name-cne('Toolbelt_Release_'+$prior.owner+'_c')-or$entry.state-cne'DROPPED'){throw 'JSON_DEPLOY_COLLISION_AUDIT_OWNER_INVALID'}
  Assert-ReleaseInputs;$control=Open-ReleaseConnection 'master'
  $found=@(Sql $control 'SELECT DB_ID(@Name) Id;' @{ '@Name'=[string]$entry.name } -Rows)
  if($found.Count-ne1-or($null-ne$found[0].Id-and$found[0].Id-isnot[DBNull])){throw 'JSON_DEPLOY_COLLISION_AUDIT_DATABASE_PRESENT'}
  if(@($prior.trust).Count-ne$script:runset.artifacts.Count){throw 'JSON_DEPLOY_COLLISION_AUDIT_TRUST_SHAPE'}
  foreach($artifact in $script:runset.artifacts){$trust=@($prior.trust|Where-Object{$_.hash-ceq$artifact.sha512});if($trust.Count-ne1-or$trust[0].preexisting-isnot[bool]){throw 'JSON_DEPLOY_COLLISION_AUDIT_TRUST_SHAPE'}
   $actual=Get-ClrCallerTrust $control ([Convert]::FromHexString($trust[0].hash))
   if(($trust[0].preexisting-and($null-eq$actual-or$actual.Fingerprint-cne$trust[0].fingerprint))-or(-not$trust[0].preexisting-and($null-ne$actual-or$trust[0].state-cne'REMOVED'))){throw 'JSON_DEPLOY_COLLISION_AUDIT_TRUST_DRIFT'}}
  $configRows=@($prior.configuration.before|Where-Object{$_.Name-ceq'clr enabled'})
  if($prior.configuration.changed-isnot[bool]-or$prior.configuration.state-cnotin@('PREEXISTING','RESTORED')-or$configRows.Count-ne1){throw 'JSON_DEPLOY_COLLISION_AUDIT_CONFIGURATION_SHAPE'}
  Assert-ClrCallerConfiguration $control $prior.configuration;Assert-ReleaseInputs
 }else{
  if(Test-Path -LiteralPath $script:journal){throw 'JSON_DEPLOY_COLLISION_ALREADY_ATTEMPTED'}
  $script:ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();trust=@();target=[ordered]@{platform='windows';version='2025';patch='CU8';compatibility_level=170};configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()};results=@();positive_controls=@();failure=$null}
  $ledger=$script:ledger;Save-Journal;Assert-ReleaseInputs;$control=Open-ReleaseConnection 'master'
  $actual=@(Sql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count-ne1-or[int]$actual[0].Major-ne17-or$actual[0].Platform-ine'windows'-or[int]$actual[0].Admin-ne1){throw 'JSON_DEPLOY_COLLISION_ACTUAL_TARGET_MISMATCH'}
  $script:stage='CONFIGURATION';Start-ClrCallerConfiguration $control;$script:stage='TRUST'
  foreach($artifact in $script:runset.artifacts){$hash=[Convert]::FromHexString($artifact.sha512);$before=Get-ClrCallerTrust $control $hash
   $entry=[ordered]@{hash=$artifact.sha512;preexisting=($null-ne$before);fingerprint=$null;state='PREEXISTING';description=$null};if($before){$entry.fingerprint=$before.Fingerprint};$script:ledger.trust+=@($entry);Save-Journal
   if(-not$before){Assert-ClrCallerTrustCleanupScope $control $hash;$entry.state='ADDING';$entry.description='Contoso JSON Schema Deploy Collision '+$script:ledger.owner;Save-Journal
    Sql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{ '@Hash'=$hash;'@Description'=$entry.description }
    $after=Get-ClrCallerTrust $control $hash;if($null-eq$after-or$after.description-cne$entry.description){throw 'JSON_DEPLOY_COLLISION_TRUST_OWNERSHIP_UNKNOWN'};$entry.fingerprint=$after.Fingerprint;$entry.state='OWNED';Save-Journal
   }
  }
  $name='Toolbelt_Release_'+$script:ledger.owner+'_c';$dbEntry=[ordered]@{name=$name;suffix='c';id=$null;created=$null;state='CREATING'};$script:ledger.databases+=@($dbEntry);Save-Journal
  Sql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Synthetic collision.',1; CREATE DATABASE [$name] COLLATE Latin1_General_100_BIN2;"
  $identity=@(Sql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{ '@Name'=$name } -Rows)
  if($identity.Count-ne1){throw 'JSON_DEPLOY_COLLISION_DATABASE_IDENTITY'};$dbEntry.id=[int]$identity[0].Id;$dbEntry.created=[string]$identity[0].Created;$dbEntry.state='CREATED';Save-Journal
  $db=Open-ReleaseConnection $name;Sql $db 'DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Test.Release.Owner'',@value=@O;' @{ '@Owner'=$script:ledger.owner }
  $dbEntry.state='OWNED';Save-Journal;Sql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=170;"
  $script:stage='BASELINE';Sql $db 'SET QUOTED_IDENTIFIER ON;';Invoke-PinnedSqlBatches $db ([string]$script:runset.baseline.path) ([string]$script:runset.baseline.sha256)
  Assert-CoreOnly $db;Assert-SchemaAbsent $db
  Sql $db @'
IF SCHEMA_ID(N'toolbelt_json') IS NOT NULL THROW 52096,N'Synthetic namespace already exists.',1;
DECLARE @Owner sysname=(SELECT USER_NAME(principal_id) FROM sys.schemas WHERE name=N'toolbelt_core');
IF @Owner IS NULL THROW 52096,N'Core owner unavailable.',1;
DECLARE @Sql nvarchar(max)=N'CREATE SCHEMA [toolbelt_json] AUTHORIZATION '+QUOTENAME(@Owner)+N';';
EXEC sys.sp_executesql @Sql;
'@
  Assert-SchemaModuleAbsent $db;Assert-CoreOnly $db
  $script:stage='BASELINE_SNAPSHOT';$baseState=Get-ModuleState $db;$coreBefore=Read-CoreProjection $db
  $spid=[int](Read-Scalar $db 'SELECT @@SPID AS ScalarValue;');Assert-TargetIdle $db $control $spid
  $script:ledger.expected_database_snapshot=$baseState;Save-Journal
  for($i=0;$i-lt4;$i++){$script:stage='CASE_'+$i;Invoke-DeployCollisionCase $db $control $script:runset.scope.cases[$i] $baseState $coreBefore}
  $script:stage='POSITIVE_DEPLOY';Assert-RunsetStable;Invoke-PinnedSqlBatches $db ([string]$script:runset.schema_deploy.path) ([string]$script:runset.schema_deploy.sha256)
  Assert-SchemaInstalled $db;if((Read-CoreProjection $db)-cne$coreBefore){throw 'JSON_DEPLOY_COLLISION_POSITIVE_CORE_CHANGED'}
  Assert-TargetIdle $db $control $spid
  $script:ledger.positive_controls+=@([ordered]@{deploy_succeeded=$true;schema_installed=$true;core_unchanged=$true});$script:ledger.expected_database_snapshot=Get-ModuleState $db;Save-Journal
  $script:ledger.state='COMPLETE';Save-Journal;Assert-ReleaseInputs
 }
}catch{$script:failure=$_.Exception;if($ValidateOnly){throw};if($script:ledger-and-not$AuditOnly){$script:ledger.failure=[ordered]@{stage=$script:stage;privateDiagnostic=$script:failure.Message};Save-Journal}}
finally{
 if($script:ledger-and-not$AuditOnly){try{
  $script:cleanup=$true
  # Bevor die eigene Datenbank gelöscht wird, aktive synthetische Fixtures
  # nochmals gegen ihre protokollierte Identität und den vollständigen
  # Modulsnapshot prüfen. Drift blockiert den gesamten Abbau.
  Assert-CleanupFixtureOwnership
  if($null-ne$script:ledger.expected_database_snapshot-and$db-and$db.State-eq[Data.ConnectionState]::Open-and
     (Get-ModuleState $db)-cne[string]$script:ledger.expected_database_snapshot){throw 'JSON_DEPLOY_COLLISION_CLEANUP_DATABASE_DRIFT'}
  foreach($connection in $script:connections){try{$connection.Dispose()}catch{}};[Data.SqlClient.SqlConnection]::ClearAllPools()
  $control=Open-ReleaseConnection 'master'
  foreach($entry in $script:ledger.databases){Assert-RunsetStable;Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-Journal}
  foreach($trust in $script:ledger.trust){$hash=[Convert]::FromHexString($trust.hash);$actual=Get-ClrCallerTrust $control $hash
   if($trust.preexisting){if($null-eq$actual-or$actual.Fingerprint-cne$trust.fingerprint){throw 'JSON_DEPLOY_COLLISION_PREEXISTING_TRUST_DRIFT'};continue}
   if($trust.state-cne'OWNED'-or$null-eq$actual-or$actual.Fingerprint-cne$trust.fingerprint-or$actual.description-cne$trust.description){throw 'JSON_DEPLOY_COLLISION_TRUST_CLEANUP_IDENTITY'}
   Assert-ClrCallerTrustCleanupScope $control $hash;Sql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{ '@Hash'=$hash }
   if($null-ne(Get-ClrCallerTrust $control $hash)){throw 'JSON_DEPLOY_COLLISION_TRUST_NOT_REMOVED'};$trust.state='REMOVED';Save-Journal
  }
  Restore-ClrCallerConfiguration $control;$script:ledger.state=if($script:failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-Journal
 }catch{$script:ledger.state='CLEANUP_BLOCKED';$script:ledger.privateCleanupDiagnostic=$_.Exception.Message;Save-Journal;$script:failure=$_.Exception}finally{foreach($connection in $script:connections){try{$connection.Dispose()}catch{}};[Data.SqlClient.SqlConnection]::ClearAllPools();if($control){$control.Dispose()}}}
}
if($script:failure){Write-Output 'FAIL JSON_SCHEMA_DEPLOY_COLLISION; inspect private journal';exit 1}
if($AuditOnly){Write-Output 'PASS JSON_SCHEMA_DEPLOY_COLLISION independent cleanup audit'}else{Write-Output 'PASS JSON_SCHEMA_DEPLOY_COLLISION four rejection cases and one Deploy control; audit required'}
