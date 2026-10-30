[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$paths = @(
    (Join-Path $PSScriptRoot 'Prepare-JsonSchemaAppLockRunset.ps1'),
    (Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1')
)
foreach ($path in $paths) {
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errors)
    if ($errors.Count) { throw 'JSON_APPLOCK_POWERSHELL_PARSE' }
}
$path = Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1'
$errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errors)
if ($errors.Count) { throw 'JSON_APPLOCK_POWERSHELL_PARSE' }
$scalarCallSites = @($ast.FindAll({param($node)$node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -ceq 'Read-Scalar'},$true))
if ($scalarCallSites.Count -ne 4) { throw 'JSON_APPLOCK_SCALAR_CALLSITE_COUNT' }
foreach ($callSite in $scalarCallSites) {
    $queries = @($callSite.CommandElements | Where-Object { $_ -is [Management.Automation.Language.StringConstantExpressionAst] -and $_.Value -match '^\s*SELECT\b' })
    if ($queries.Count -ne 1 -or $queries[0].Value -notmatch '(?i)\bAS\s+ScalarValue\s*;?\s*$') {
        throw 'JSON_APPLOCK_SCALAR_SQL_ALIAS_REQUIRED'
    }
}
$acquireNodes = @($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Acquire-HolderLock'},$true))
if ($acquireNodes.Count -ne 1) { throw 'JSON_APPLOCK_HOLDER_HELPER_AMBIGUOUS' }
$sqlCalls = @($acquireNodes[0].Body.FindAll({param($node)$node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -ceq 'Sql'},$true))
$beginCalls = @($sqlCalls | Where-Object { $_.Extent.Text -match '(?s)^Sql\s+\$Connection\s+''BEGIN TRANSACTION;''' })
$rpcCalls = @($sqlCalls | Where-Object { $_.Extent.Text -match 'sp_getapplock' })
$rollbackCalls = @($sqlCalls | Where-Object { $_.Extent.Text -match '(?s)^Sql\s+\$Connection\s+''IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;''' })
if ($beginCalls.Count -ne 1 -or $rpcCalls.Count -ne 1 -or $rollbackCalls.Count -ne 1 -or
    -not ($beginCalls[0].Extent.StartOffset -lt $rpcCalls[0].Extent.StartOffset -and $rpcCalls[0].Extent.StartOffset -lt $rollbackCalls[0].Extent.StartOffset)) {
    throw 'JSON_APPLOCK_HOLDER_TRANSACTION_PROTOCOL'
}
$rpcText = $rpcCalls[0].Extent.Text
if ($rpcText -notmatch '@Resource=@Resource' -or $rpcText -notmatch '''@Resource''\s*=\s*\$Resource' -or
    $rpcText -match '(?i)\b(?:BEGIN|ROLLBACK)\s+TRANSACTION\b') {
    throw 'JSON_APPLOCK_HOLDER_PARAMETER_BATCH_INVALID'
}
$nodes = @($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Read-Scalar'},$true))
if ($nodes.Count -ne 1) { throw 'JSON_APPLOCK_SCALAR_HELPER_AMBIGUOUS' }
$script:scalarShape = 'single'
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows) {
    if ($script:scalarShape -ceq 'single') { return @([pscustomobject]@{SyntheticScalar=17}) }
    return @([pscustomobject]@{First=1;Second=2})
}
. ([scriptblock]::Create($nodes[0].Extent.Text))
if ([int](Read-Scalar $null 'synthetic offline scalar') -ne 17) { throw 'JSON_APPLOCK_SCALAR_VALUE' }
$script:scalarShape = 'multiple'
$rejected = $false
try { [void](Read-Scalar $null 'synthetic invalid scalar shape') }
catch { if ($_.Exception.Message -ceq 'JSON_APPLOCK_QUERY_SHAPE') { $rejected = $true } else { throw } }
if (-not $rejected) { throw 'JSON_APPLOCK_SCALAR_SHAPE_ACCEPTED' }
$stateFunctionNames = @('Get-ExternalSessionState','Get-ContenderStateSamples','Test-ExternalSessionIdle','New-ContenderStateSummary','New-ContenderStateDiagnostic')
$stateFunctions = @{}
foreach ($name in $stateFunctionNames) {
    $found = @($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
    if ($found.Count -ne 1) { throw 'JSON_APPLOCK_STATE_HELPER_AMBIGUOUS' }
    $stateFunctions[$name] = $found[0]
}
$samplingText = $stateFunctions['Get-ContenderStateSamples'].Extent.Text
$externalCall = $samplingText.IndexOf('Get-ExternalSessionState',[StringComparison]::Ordinal)
$combinedCall = $samplingText.IndexOf("'SELECT @@SPID Spid,@@TRANCOUNT TranCount,XACT_STATE() XactState;'",[StringComparison]::Ordinal)
$isolatedCall = $samplingText.IndexOf("'DECLARE @ObservedTranCount int=@@TRANCOUNT,@ObservedXactState smallint=XACT_STATE();",[StringComparison]::Ordinal)
$sessionCall = $samplingText.IndexOf("'SELECT @@SPID AS ScalarValue;'",[StringComparison]::Ordinal)
if ($externalCall -lt 0 -or $combinedCall -lt 0 -or $isolatedCall -lt 0 -or $sessionCall -lt 0 -or
    -not ($externalCall -lt $combinedCall -and $combinedCall -lt $isolatedCall -and $isolatedCall -lt $sessionCall)) {
    throw 'JSON_APPLOCK_EXTERNAL_OBSERVER_ORDER'
}
. ([scriptblock]::Create($stateFunctions['Test-ExternalSessionIdle'].Extent.Text))
$idleRows = @([pscustomobject]@{SessionId=51;OpenTransactionCount=0;UserTransactionCount=0;ApplicationLockCount=0})
$busyRows = @([pscustomobject]@{SessionId=51;OpenTransactionCount=1;UserTransactionCount=1;ApplicationLockCount=1})
if (-not (Test-ExternalSessionIdle $idleRows 51) -or (Test-ExternalSessionIdle $busyRows 51) -or
    (Test-ExternalSessionIdle $idleRows 52) -or (Test-ExternalSessionIdle @() 51)) { throw 'JSON_APPLOCK_EXTERNAL_IDLE_ORACLE' }
$sampleOrder = [Collections.Generic.List[string]]::new()
$script:externalSample = [pscustomobject]@{SessionId=51;OpenTransactionCount=0;UserTransactionCount=0;ApplicationLockCount=0}
$script:combinedSample = [pscustomobject]@{Spid=51;TranCount=0;XactState=1}
$script:isolatedSample = [pscustomobject]@{TranCount=0;XactState=0}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows) {
    if ($Connection -ceq 'observer') { $sampleOrder.Add('external'); return @($script:externalSample) }
    if ($Text -match 'SELECT @@SPID Spid') { $sampleOrder.Add('combined'); return @($script:combinedSample) }
    if ($Text -match 'DECLARE @ObservedTranCount') { $sampleOrder.Add('isolated'); return @($script:isolatedSample) }
    if ($Text -match 'SELECT @@SPID AS ScalarValue') { $sampleOrder.Add('session'); return @([pscustomobject]@{ScalarValue=51}) }
    throw 'JSON_APPLOCK_SYNTHETIC_SQL_UNEXPECTED'
}
. ([scriptblock]::Create($nodes[0].Extent.Text))
. ([scriptblock]::Create($stateFunctions['Get-ExternalSessionState'].Extent.Text))
. ([scriptblock]::Create($stateFunctions['Get-ContenderStateSamples'].Extent.Text))
$syntheticSamples = Get-ContenderStateSamples 'observer' 'contender' 51
if (($sampleOrder -join '|') -cne 'external|combined|isolated|session' -or
    $syntheticSamples.external_rows.Count -ne 1 -or $syntheticSamples.combined_rows.Count -ne 1 -or
    $syntheticSamples.isolated_rows.Count -ne 1 -or $syntheticSamples.session_rows.Count -ne 1 -or
    $syntheticSamples.errors.external -or $syntheticSamples.errors.combined -or $syntheticSamples.errors.isolated -or $syntheticSamples.errors.session) {
    throw 'JSON_APPLOCK_SYNTHETIC_MEASUREMENT_SHAPE'
}
. ([scriptblock]::Create($stateFunctions['New-ContenderStateSummary'].Extent.Text))
. ([scriptblock]::Create($stateFunctions['New-ContenderStateDiagnostic'].Extent.Text))
$syntheticSummary = New-ContenderStateSummary $syntheticSamples
$syntheticState = New-ContenderStateDiagnostic $syntheticSamples ([Data.ConnectionState]::Open) 51 $null $null
if ($syntheticSummary.combined.Count -ne 1 -or $syntheticSummary.combined[0].xact_state -ne 1 -or
    $syntheticSummary.isolated.Count -ne 1 -or $syntheticSummary.isolated[0].xact_state -ne 0 -or
    $syntheticSummary.external[0].open_transactions -ne 0 -or $syntheticState.xact_state -ne 0 -or
    -not $syntheticState.session_same -or $syntheticState.external_application_lock_count -ne 0) {
    throw 'JSON_APPLOCK_SYNTHETIC_MEASUREMENT_VALUES'
}
$diagnosticNodes = @($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'New-ContenderStateDiagnostic'},$true))
$auditNodes = @($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Assert-AuditJournalCases'},$true))
if ($auditNodes.Count -ne 1) { throw 'JSON_APPLOCK_AUDIT_HELPER_AMBIGUOUS' }
. ([scriptblock]::Create($auditNodes[0].Extent.Text))
$expectedResources = @('toolbelt.deploy.json.shared-core','toolbelt.deploy.toolbelt.json.schema')
function New-SyntheticAuditJournal([string]$State,[int]$ResultCount) {
    $results = [Collections.Generic.List[object]]::new()
    for ($index=0; $index -lt $ResultCount; $index++) {
        $resource = if ($index -lt $expectedResources.Count) { $expectedResources[$index] } else { 'unexpected-resource' }
        $results.Add([ordered]@{resource=$resource;blocked=$true;positive_control=$true;snapshot_unchanged=$true})
    }
    return [pscustomobject]@{state=$State;owner='0123456789abcdef0123456789abcdef';
        target=[pscustomobject]@{platform='windows';version='2025';patch='CU8';compatibility_level=170};results=$results.ToArray()}
}
foreach ($entry in @(@('COMPLETE',2),@('FAILED_CLEANED',0),@('FAILED_CLEANED',1),@('FAILED_CLEANED',2))) {
    Assert-AuditJournalCases (New-SyntheticAuditJournal $entry[0] $entry[1])
}
foreach ($record in @(
        (New-SyntheticAuditJournal 'COMPLETE' 1),
        (New-SyntheticAuditJournal 'FAILED_CLEANED' 3))) {
    $rejected = $false
    try { Assert-AuditJournalCases $record }
    catch { if ($_.Exception.Message -ceq 'JSON_APPLOCK_AUDIT_JOURNAL_INVALID') { $rejected=$true } else { throw } }
    if (-not $rejected) { throw 'JSON_APPLOCK_AUDIT_BAD_PREFIX_ACCEPTED' }
}
$wrongOrder = New-SyntheticAuditJournal 'FAILED_CLEANED' 1
$wrongOrder.results[0].resource = 'toolbelt.deploy.toolbelt.json.schema'
$rejected = $false
try { Assert-AuditJournalCases $wrongOrder }
catch { if ($_.Exception.Message -ceq 'JSON_APPLOCK_AUDIT_JOURNAL_INVALID') { $rejected=$true } else { throw } }
if (-not $rejected) { throw 'JSON_APPLOCK_AUDIT_WRONG_RESOURCE_ACCEPTED' }
$snapshotNode = @($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Get-ModuleState'},$true))
if ($snapshotNode.Count -ne 1 -or $snapshotNode[0].Extent.Text -notmatch 'FROM\s+sys\.database_permissions\s+dp\s+ORDER\s+BY' -or
    $snapshotNode[0].Extent.Text -notmatch 'FROM\s+sys\.database_role_members\s+ORDER\s+BY') {
    throw 'JSON_APPLOCK_SNAPSHOT_RIGHTS_COVERAGE'
}
$resultAssignments = @($ast.FindAll({param($node)$node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -match '\.results$'},$true))
if ($resultAssignments.Count -ne 1 -or $resultAssignments[0].Right.Extent.Text -match '(?:blocked|positive_control|snapshot_unchanged)\s*=\s*true\b') {
    throw 'JSON_APPLOCK_RESULT_BOOL_SOURCE'
}
$script:scenario = [ordered]@{resource='synthetic-resource'}
$script:ledger = [ordered]@{results=@()}
. ([scriptblock]::Create('$script:ledger.results += '+$resultAssignments[0].Right.Extent.Text))
if ($script:ledger.results.Count -ne 1 -or $script:ledger.results[0].blocked -isnot [bool] -or
    $script:ledger.results[0].positive_control -isnot [bool] -or $script:ledger.results[0].snapshot_unchanged -isnot [bool] -or
    -not $script:ledger.results[0].blocked -or -not $script:ledger.results[0].positive_control -or -not $script:ledger.results[0].snapshot_unchanged) {
    throw 'JSON_APPLOCK_RESULT_BOOL_RUNTIME'
}
Write-Output 'PASS JSON_SCHEMA_APPLOCK offline PowerShell/scalar/snapshot guards; no SQL executed'
