[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$driver=Join-Path $PSScriptRoot 'Invoke-JsonSchemaDeployCollisionLab.ps1'
$preparer=Join-Path $PSScriptRoot 'Prepare-JsonSchemaDeployCollisionRunset.ps1'
$r33=Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1'
$r34=Join-Path $PSScriptRoot 'Invoke-JsonSchemaUninstallAppLockLab.ps1'
$r35=Join-Path $PSScriptRoot 'Invoke-JsonSchemaCallerTransactionLab.ps1'
$api=Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'
$stable=Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'
foreach($path in @($driver,$preparer,$r33,$r34,$r35,$api,$stable)){
 $parseErrors=$null;[void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$parseErrors)
 if($parseErrors.Count){throw 'JSON_DEPLOY_COLLISION_OFFLINE_PARSE'}
}
$driverText=[IO.File]::ReadAllText($driver,[Text.Encoding]::UTF8)
$astErrors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($driver,[ref]$null,[ref]$astErrors)
foreach($name in @('Assert-CaseShape','Assert-AuditPrefix','Assert-CleanupFixtureOwnership')){
 $found=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
 if($found.Count-ne1){throw 'JSON_DEPLOY_COLLISION_OFFLINE_GUARD_MISSING'}
 . ([scriptblock]::Create($found[0].Extent.Text))
}
$valid=@(
 [pscustomobject]@{ordinal=0;kind='reserved_temp';object_name='#tbx_JsonSchema_DeployState';expected_error=55633;expected_state=1;expected_message='JSON Schema lifecycle: reservierter Callerzustand belegt.'},
 [pscustomobject]@{ordinal=1;kind='public_slot';object_name='USP_ValidateJsonSchema';fixture_type='U';fixture_value=701;expected_error=55634;expected_state=1;expected_message='JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'},
 [pscustomobject]@{ordinal=2;kind='internal_slot';object_name='FT_ValidateJsonSchemaInternal';fixture_type='U';fixture_value=702;expected_error=55634;expected_state=1;expected_message='JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'},
 [pscustomobject]@{ordinal=3;kind='orphan_mode';property_name='Toolbelt.Module.toolbelt.json.schema.DeploymentMode';property_value='local';expected_error=55634;expected_state=1;expected_message='JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'})
Assert-CaseShape $valid
foreach($bad in @(
 @($valid[1],$valid[0],$valid[2],$valid[3]),
 @($valid[0],$valid[1],$valid[1],$valid[3]),
 @($valid[0],$valid[1],$valid[2],[pscustomobject]@{ordinal=3;kind='orphan_mode';property_name='Toolbelt.Module.toolbelt.json.schema.DeploymentMode';property_value='central';expected_error=55634;expected_state=1;expected_message=$valid[3].expected_message}),
 @($valid[0],$valid[1],$valid[2]))) {
 $rejected=$false;try{Assert-CaseShape $bad}catch{$rejected=$_.Exception.Message-ceq'JSON_DEPLOY_COLLISION_CASES_INVALID'}
 if(-not$rejected){throw 'JSON_DEPLOY_COLLISION_OFFLINE_INVALID_CASE_ACCEPTED'}
}
function New-Result([int]$Ordinal){[pscustomobject]@{ordinal=$Ordinal;kind=@('reserved_temp','public_slot','internal_slot','orphan_mode')[$Ordinal];expected_error=@(55633,55634,55634,55634)[$Ordinal];exact_error=$true;blocked_before_mutation=$true;module_snapshot_unchanged=$true;fixture_preserved=$true;fixture_removed=$true;core_unchanged=$true;contender_session_unchanged=$true;transaction_absent=$true;application_locks_absent=$true}}
$empty=[pscustomobject]@{state='FAILED_CLEANED';owner=('a'*32);results=@();positive_controls=@()}
if((Assert-AuditPrefix $empty).result_count-ne0){throw 'JSON_DEPLOY_COLLISION_OFFLINE_EMPTY_AUDIT'}
$prefix=[pscustomobject]@{state='FAILED_CLEANED';owner=('b'*32);results=@((New-Result 0),(New-Result 1));positive_controls=@()}
if((Assert-AuditPrefix $prefix).result_count-ne2){throw 'JSON_DEPLOY_COLLISION_OFFLINE_PREFIX_AUDIT'}
$complete=[pscustomobject]@{state='COMPLETE';owner=('c'*32);results=@((New-Result 0),(New-Result 1),(New-Result 2),(New-Result 3));positive_controls=@([pscustomobject]@{deploy_succeeded=$true;schema_installed=$true;core_unchanged=$true})}
if((Assert-AuditPrefix $complete).control_count-ne1){throw 'JSON_DEPLOY_COLLISION_OFFLINE_COMPLETE_AUDIT'}
$invalid=[pscustomobject]@{state='COMPLETE';owner=('d'*32);results=@((New-Result 0));positive_controls=@()}
$rejected=$false;try{[void](Assert-AuditPrefix $invalid)}catch{$rejected=$_.Exception.Message-ceq'JSON_DEPLOY_COLLISION_AUDIT_JOURNAL_INVALID'}
if(-not$rejected){throw 'JSON_DEPLOY_COLLISION_OFFLINE_BAD_AUDIT_ACCEPTED'}
$badResult=New-Result 0;$badResult.fixture_preserved=$false
$invalid=[pscustomobject]@{state='FAILED_CLEANED';owner=('e'*32);results=@($badResult);positive_controls=@()}
$rejected=$false;try{[void](Assert-AuditPrefix $invalid)}catch{$rejected=$_.Exception.Message-ceq'JSON_DEPLOY_COLLISION_AUDIT_RESULT_INVALID'}
if(-not$rejected){throw 'JSON_DEPLOY_COLLISION_OFFLINE_BAD_FLAG_ACCEPTED'}

# Exercise the exact final-drop ownership guard with deterministic stubs; no SQL connection is opened.
$script:ledger=[ordered]@{active_fixture=[ordered]@{ordinal=1;state='OWNED';snapshot='fixture-owned';module_snapshot='module-with-fixture'};expected_database_snapshot='baseline'}
$script:runset=[pscustomobject]@{scope=[pscustomobject]@{cases=$valid}}
$script:db=[pscustomobject]@{State=[Data.ConnectionState]::Open};$script:mockModule='module-with-fixture';$script:mockFixture='fixture-owned';$script:removed=0
function Get-ModuleState($Connection){$script:mockModule}
function Get-FixtureSnapshot($Connection,$Case){$script:mockFixture}
function Assert-FixtureSnapshot($Connection,$Case,[string]$Expected){if($script:mockFixture-cne$Expected){throw 'JSON_DEPLOY_COLLISION_FIXTURE_DRIFT'}}
function Remove-OwnedFixture($Connection,$Case,[string]$Expected){$script:removed++;$script:mockFixture='{"exists":false}';$script:mockModule='baseline';$script:ledger.active_fixture=$null}
Assert-CleanupFixtureOwnership
if($script:removed-ne1-or$null-ne$script:ledger.active_fixture-or$script:mockModule-cne'baseline'){throw 'JSON_DEPLOY_COLLISION_OFFLINE_OWNED_CLEANUP_FAILED'}
$script:ledger.active_fixture=[ordered]@{ordinal=2;state='OWNED';snapshot='fixture-owned';module_snapshot='module-with-fixture'};$script:ledger.expected_database_snapshot='baseline';$script:mockModule='module-with-fixture';$script:mockFixture='foreign-drift';$script:removed=0
$rejected=$false;try{Assert-CleanupFixtureOwnership}catch{$rejected=$_.Exception.Message-ceq'JSON_DEPLOY_COLLISION_FIXTURE_DRIFT'}
if(-not$rejected-or$script:removed-ne0){throw 'JSON_DEPLOY_COLLISION_OFFLINE_FIXTURE_DRIFT_NOT_BLOCKED'}
$script:ledger.active_fixture=[ordered]@{ordinal=2;state='CREATING';snapshot=$null;module_snapshot=$null};$script:mockFixture='fixture-owned';$script:mockModule='module-with-fixture';$script:removed=0
$rejected=$false;try{Assert-CleanupFixtureOwnership}catch{$rejected=$_.Exception.Message-ceq'JSON_DEPLOY_COLLISION_CLEANUP_FIXTURE_OWNERSHIP_UNKNOWN'}
if(-not$rejected-or$script:removed-ne0){throw 'JSON_DEPLOY_COLLISION_OFFLINE_UNOWNED_FIXTURE_CLEANUP_NOT_BLOCKED'}
$script:ledger.active_fixture=[ordered]@{ordinal=2;state='OWNED';snapshot='fixture-owned';module_snapshot='module-with-fixture'};$script:mockFixture='fixture-owned';$script:mockModule='module-drift';$script:removed=0
$rejected=$false;try{Assert-CleanupFixtureOwnership}catch{$rejected=$_.Exception.Message-ceq'JSON_DEPLOY_COLLISION_CLEANUP_MODULE_DRIFT'}
if(-not$rejected-or$script:removed-ne0){throw 'JSON_DEPLOY_COLLISION_OFFLINE_MODULE_DRIFT_NOT_BLOCKED'}

# Ensure fixture and baseline checks happen before the only database-drop path.
$main=@($ast.EndBlock.Statements|Where-Object{$_-is[Management.Automation.Language.TryStatementAst]})
if($main.Count-ne1){throw 'JSON_DEPLOY_COLLISION_OFFLINE_FINALLY_MISSING'}
$finallyText=$main[0].Finally.Extent.Text
$fixtureCheck=$finallyText.IndexOf('Assert-CleanupFixtureOwnership',[StringComparison]::Ordinal)
$snapshotCheck=$finallyText.IndexOf('JSON_DEPLOY_COLLISION_CLEANUP_DATABASE_DRIFT',[StringComparison]::Ordinal)
$dispose=$finallyText.IndexOf('$connection.Dispose()',[StringComparison]::Ordinal)
$drop=$finallyText.IndexOf('Assert-ReleaseOwnIdentity',[StringComparison]::Ordinal)
if($fixtureCheck-lt0-or$snapshotCheck-le$fixtureCheck-or$dispose-le$snapshotCheck-or$drop-le$dispose){throw 'JSON_DEPLOY_COLLISION_OFFLINE_CLEANUP_ORDER'}
if($driverText-match'\[Data\.SqlClient\.SqlTransaction\]|\.BeginTransaction\(' -or
   $driverText-notmatch'Assert-ReleaseInputs' -or $driverText-notmatch'Assert-RunsetStable' -or
   $driverText-notmatch'Assert-ReleaseOwnIdentity' -or $driverText-notmatch'Assert-ClrCallerTrustCleanupScope'){throw 'JSON_DEPLOY_COLLISION_OFFLINE_PROTECTION_MISSING'}
Write-Output 'PASS JSON_SCHEMA_DEPLOY_COLLISION offline guards, audit prefixes, and drift-blocking cleanup; no SQL executed'
