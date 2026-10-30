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
if ($scalarCallSites.Count -ne 3) { throw 'JSON_APPLOCK_SCALAR_CALLSITE_COUNT' }
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
$diagnosticNodes = @($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'New-ContenderStateDiagnostic'},$true))
if ($diagnosticNodes.Count -ne 1) { throw 'JSON_APPLOCK_DIAGNOSTIC_HELPER_AMBIGUOUS' }
. ([scriptblock]::Create($diagnosticNodes[0].Extent.Text))
$syntheticState = @(New-ContenderStateDiagnostic @([pscustomobject]@{Spid=51;TranCount=1;XactState=1}) ([Data.ConnectionState]::Open) 51 $null $null)
if ($syntheticState.Count -ne 1 -or $syntheticState[0].row_count -ne 1 -or -not $syntheticState[0].session_same -or
    $syntheticState[0].expected_spid -ne 51 -or $syntheticState[0].observed_spid -ne 51 -or
    $syntheticState[0].trancount -ne 1 -or $syntheticState[0].xact_state -ne 1 -or
    $syntheticState[0].connection_state -cne 'Open' -or $syntheticState[0].PSObject.Properties.Name -contains 'sql') {
    throw 'JSON_APPLOCK_DIAGNOSTIC_VALUES'
}
$syntheticMissing = @(New-ContenderStateDiagnostic @() ([Data.ConnectionState]::Closed) 51 $null ([InvalidOperationException]::new('synthetic query failure')))
if ($syntheticMissing.Count -ne 1 -or $syntheticMissing[0].row_count -ne 0 -or $syntheticMissing[0].session_same -or
    $null -ne $syntheticMissing[0].observed_spid -or $syntheticMissing[0].state_query_error_type -cne 'System.InvalidOperationException') {
    throw 'JSON_APPLOCK_DIAGNOSTIC_MISSING_STATE'
}
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
