[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$driver=Join-Path $PSScriptRoot 'Invoke-JsonSchemaCallerTransactionLab.ps1'
$preparer=Join-Path $PSScriptRoot 'Prepare-JsonSchemaCallerTransactionRunset.ps1'
$r33=Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1'
$r34=Join-Path $PSScriptRoot 'Invoke-JsonSchemaUninstallAppLockLab.ps1'
$stable=Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'
$api=Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'
$environment=Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'
foreach($path in @($driver,$preparer,$r33,$r34,$stable,$api,$environment)){
 $errors=$null;[void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errors)
 if($errors.Count){throw 'JSON_CALLER_TX_OFFLINE_PARSE'}
}
$driverText=[IO.File]::ReadAllText($driver,[Text.Encoding]::UTF8)
$astErrors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($driver,[ref]$null,[ref]$astErrors)
$caseGuard=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Assert-CallerCaseShape'},$true))
if($caseGuard.Count-ne1){throw 'JSON_CALLER_TX_OFFLINE_CASE_GUARD_MISSING'}
. ([scriptblock]::Create($caseGuard[0].Extent.Text))
$valid=@(
 [pscustomobject]@{ordinal=0;operation='deploy';initial_schema='absent';expected_message='JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.'},
 [pscustomobject]@{ordinal=1;operation='uninstall';initial_schema='installed';expected_message='JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.'})
Assert-CallerCaseShape $valid
foreach($invalid in @(
 @($valid[1],$valid[0]),
 @([pscustomobject]@{ordinal='0';operation='deploy';initial_schema='absent';expected_message=$valid[0].expected_message},$valid[1]),
 @($valid[0],[pscustomobject]@{ordinal=1;operation='uninstall';initial_schema='absent';expected_message=$valid[1].expected_message}),
 @($valid[0],[pscustomobject]@{ordinal=1;operation='uninstall';initial_schema='installed';expected_message='other'}),
 @($valid[0]))) {
 $rejected=$false
 try{Assert-CallerCaseShape $invalid}catch{$rejected=$_.Exception.Message-ceq'JSON_CALLER_TX_CASES_INVALID'}
 if(-not$rejected){throw 'JSON_CALLER_TX_OFFLINE_BAD_CASE_ACCEPTED'}
}
foreach($path in @((Join-Path $PSScriptRoot '../../Modules/toolbelt.json.schema/Deployment/Deploy.sql'),
                   (Join-Path $PSScriptRoot '../../Modules/toolbelt.json.schema/Deployment/Uninstall.sql'))){
 $sql=[IO.File]::ReadAllText([IO.Path]::GetFullPath($path),[Text.Encoding]::UTF8)
 if($sql-notmatch'(?is)^\s*:On\s+Error\s+exit\s*IF\s+@@TRANCOUNT\s*>\s*0\s*BEGIN\s*RAISERROR\(N''JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen\.'',16,1\);\s*RETURN;\s*END;'){
  throw 'JSON_CALLER_TX_OFFLINE_SOURCE_GUARD_DRIFT'
 }
}
$caseFunction=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Invoke-BlockedTransactionCase'},$true))
if($caseFunction.Count-ne1){throw 'JSON_CALLER_TX_OFFLINE_ORACLE_FUNCTION_MISSING'}
$caseText=$caseFunction[0].Extent.Text
$ordered=@(
 "Sql `$Connection 'BEGIN TRANSACTION;'",
 'WitnessValue=200',
 "Sql `$Connection 'SAVE TRANSACTION CallerSavepoint;'",
 'WitnessValue=300',
 'expected_message',
 'Get-ModuleState $Connection',
 "Sql `$Connection 'ROLLBACK TRANSACTION CallerSavepoint;'",
 "Sql `$Connection 'ROLLBACK TRANSACTION;'",
 'Test-ExternalSessionIdle')
$offset=-1
foreach($needle in $ordered){$next=if($needle-ceq'Test-ExternalSessionIdle'){$caseText.LastIndexOf($needle,[StringComparison]::Ordinal)}else{$caseText.IndexOf($needle,[StringComparison]::Ordinal)};if($next-le$offset){throw 'JSON_CALLER_TX_OFFLINE_ORACLE_ORDER'};$offset=$next}
$beginCalls=@($caseFunction[0].Body.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName()-ceq'Sql' -and $n.Extent.Text-match"^Sql \`$Connection 'BEGIN TRANSACTION;'$"},$true))
if($beginCalls.Count-ne1 -or $beginCalls[0].CommandElements.Count-ne3){throw 'JSON_CALLER_TX_OFFLINE_BEGIN_MUST_BE_UNPARAMETERIZED'}
if($driverText-match'\[Data\.SqlClient\.SqlTransaction\]|\.BeginTransaction\(' -or
   $driverText-notmatch'QUOTED_IDENTIFIER ON' -or $driverText-notmatch'XACT_ABORT OFF' -or $driverText-notmatch'NOCOUNT OFF' -or
   $driverText-notmatch'SELECT @@OPTIONS AS ScalarValue' -or $driverText-notmatch'Test-ExternalSessionIdle' -or
   $driverText-notmatch'\$ledger=\$script:ledger'){
 throw 'JSON_CALLER_TX_OFFLINE_DRIVER_PROTOCOL_DRIFT'
}
if($driverText-notmatch'\$caught\.Class-ne16' -or $driverText-notmatch'\$_.Class-eq16' -or
   $driverText-notmatch'Assert-AuditPrefix'){throw 'JSON_CALLER_TX_OFFLINE_SQL_ERROR_CLASS_OR_AUDIT_GUARD_MISSING'}
foreach($witnessCheck in @('WitnessValue $Connection)-ne100','WitnessValue $Connection)-ne200','WitnessValue $Connection)-ne300')){
 if(-not$caseText.Contains($witnessCheck,[StringComparison]::Ordinal)){throw 'JSON_CALLER_TX_OFFLINE_WITNESS_ASSERTION_MISSING'}
}
$beginOffset=$caseText.IndexOf("Sql `$Connection 'BEGIN TRANSACTION;'",[StringComparison]::Ordinal)
$saveOffset=$caseText.IndexOf("Sql `$Connection 'SAVE TRANSACTION CallerSavepoint;'",[StringComparison]::Ordinal)
$guardOffset=$caseText.IndexOf('$caught=$null',[StringComparison]::Ordinal)
$saveRollbackOffset=$caseText.IndexOf("Sql `$Connection 'ROLLBACK TRANSACTION CallerSavepoint;'",[StringComparison]::Ordinal)
$fullRollbackOffset=$caseText.IndexOf("Sql `$Connection 'ROLLBACK TRANSACTION;'",$saveRollbackOffset,[StringComparison]::Ordinal)
$checks100=[regex]::Matches($caseText,'WitnessValue \$Connection\)-ne100')
$checks200=[regex]::Matches($caseText,'WitnessValue \$Connection\)-ne200')
$checks300=[regex]::Matches($caseText,'WitnessValue \$Connection\)-ne300')
if($checks100.Count-ne2 -or $checks100[0].Index-ge$beginOffset -or $checks100[1].Index-le$fullRollbackOffset -or
   $checks200.Count-ne2 -or $checks200[0].Index-ge$saveOffset -or $checks200[1].Index-le$saveRollbackOffset -or
   $checks300.Count-ne2 -or $checks300[0].Index-ge$guardOffset -or $checks300[1].Index-le$guardOffset){throw 'JSON_CALLER_TX_OFFLINE_WITNESS_ORDER'}
$pinRequired=@('Assert-ReleaseInputs','Assert-RunsetStable','Assert-ReleaseOwnIdentity','Assert-ClrCallerTrustCleanupScope','Restore-ClrCallerConfiguration')
foreach($token in $pinRequired){if(-not$driverText.Contains($token,[StringComparison]::Ordinal)){throw 'JSON_CALLER_TX_OFFLINE_PROTECTION_MISSING'}}

$auditGuard=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Assert-AuditPrefix'},$true))
if($auditGuard.Count-ne1){throw 'JSON_CALLER_TX_OFFLINE_AUDIT_GUARD_MISSING'}
. ([scriptblock]::Create($auditGuard[0].Extent.Text))
function New-SyntheticResult([int]$Ordinal){
 [pscustomobject]@{ordinal=$Ordinal;operation=@('deploy','uninstall')[$Ordinal];blocked=$true;exact_error=$true;transaction_preserved=$true;
  session_preserved=$true;options_preserved=$true;module_snapshot_preserved=$true;witness_preserved=$true;application_locks_absent=$true;
  witness_values=[pscustomobject]@{committed_before=100;first_update=200;guard_before=300;guard_after=300;savepoint_rollback=200;full_rollback=100}}
}
function New-SyntheticControl([int]$Ordinal){[pscustomobject]@{ordinal=$Ordinal;operation=@('deploy','uninstall')[$Ordinal];succeeded=$true;module_state_correct=$true;core_unchanged=$true}}
$failedEmpty=[pscustomobject]@{state='FAILED_CLEANED';owner=('a'*32);results=@();positive_controls=@()}
if((Assert-AuditPrefix $failedEmpty).result_count-ne0){throw 'JSON_CALLER_TX_OFFLINE_EMPTY_FAILURE_AUDIT'}
$failedPrefix=[pscustomobject]@{state='FAILED_CLEANED';owner=('b'*32);results=@((New-SyntheticResult 0));positive_controls=@()}
if((Assert-AuditPrefix $failedPrefix).control_count-ne0){throw 'JSON_CALLER_TX_OFFLINE_PARTIAL_FAILURE_AUDIT'}
$complete=[pscustomobject]@{state='COMPLETE';owner=('c'*32);results=@((New-SyntheticResult 0),(New-SyntheticResult 1));positive_controls=@((New-SyntheticControl 0),(New-SyntheticControl 1))}
if((Assert-AuditPrefix $complete).result_count-ne2){throw 'JSON_CALLER_TX_OFFLINE_COMPLETE_AUDIT'}
$badAudit=[Collections.Generic.List[object]]::new()
$bad=[pscustomobject]@{state='COMPLETE';owner=('d'*32);results=@((New-SyntheticResult 0));positive_controls=@((New-SyntheticControl 0))};$badAudit.Add($bad)
$bad=[pscustomobject]@{state='FAILED_CLEANED';owner=('e'*32);results=@();positive_controls=@((New-SyntheticControl 0))};$badAudit.Add($bad)
$badResult=New-SyntheticResult 0;$badResult.witness_values.full_rollback=101
$bad=[pscustomobject]@{state='FAILED_CLEANED';owner=('f'*32);results=@($badResult);positive_controls=@()};$badAudit.Add($bad)
foreach($bad in $badAudit){$rejected=$false;try{[void](Assert-AuditPrefix $bad)}catch{$rejected=$_.Exception.Message -in @('JSON_CALLER_TX_AUDIT_JOURNAL_INVALID','JSON_CALLER_TX_AUDIT_RESULT_INVALID')};if(-not$rejected){throw 'JSON_CALLER_TX_OFFLINE_INVALID_AUDIT_ACCEPTED'}}

# Exercise the existing timeout/ownership helper bootstrap without opening a connection.
$script:repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$apiErrors=$null;$apiAst=[Management.Automation.Language.Parser]::ParseFile($api,[ref]$null,[ref]$apiErrors)
$import=@($apiAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($apiErrors.Count-or$import.Count-ne1){throw 'JSON_CALLER_TX_OFFLINE_BOOTSTRAP_IMPORTER'}
. ([scriptblock]::Create($import[0].Extent.Text))
foreach($block in Import-ClrFunctions $stable @('Get-ReleaseTimeout','Invoke-ReleaseSql','Save-ReleaseJournal') @{'function Invoke-ReleaseSql('='function Invoke-ReleaseSqlCore('}){. $block}
$r34Errors=$null;$r34Ast=[Management.Automation.Language.Parser]::ParseFile($r34,[ref]$null,[ref]$r34Errors)
$sqlWrapper=@($r34Ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Invoke-ReleaseSql'},$true))
if($r34Errors.Count-or$sqlWrapper.Count-ne1){throw 'JSON_CALLER_TX_OFFLINE_SQL_WRAPPER'}
. ([scriptblock]::Create($sqlWrapper[0].Extent.Text))
$script:clock=[Diagnostics.Stopwatch]::StartNew();$script:cleanup=$false
$timeout=Get-ReleaseTimeout
if($timeout-isnot[int]-or$timeout-le0 -or
   -not(Get-Command Invoke-ReleaseSql -CommandType Function -ErrorAction SilentlyContinue) -or
   -not(Get-Command Save-ReleaseJournal -CommandType Function -ErrorAction SilentlyContinue)){throw 'JSON_CALLER_TX_OFFLINE_BOOTSTRAP_UNRESOLVED'}
$stableErrors=$null;$stableAst=[Management.Automation.Language.Parser]::ParseFile($stable,[ref]$null,[ref]$stableErrors)
$open=@($stableAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Open-ReleaseConnection'},$true))
if($stableErrors.Count-or$open.Count-ne1-or-not$open[0].Extent.Text.Contains('Get-ReleaseTimeout',[StringComparison]::Ordinal)){throw 'JSON_CALLER_TX_OFFLINE_TIMEOUT_DEPENDENCY'}
$mainTry=@($ast.EndBlock.Statements|Where-Object{$_-is[Management.Automation.Language.TryStatementAst]})
if($mainTry.Count-ne1){throw 'JSON_CALLER_TX_OFFLINE_MAIN_TRY_GUARD'}
$finallyText=$mainTry[0].Finally.Extent.Text
$cleanupTimeoutOffset=$finallyText.IndexOf('$script:cleanup=$true',[StringComparison]::Ordinal)
$cleanupConnectOffset=$finallyText.IndexOf("`$control=Open-ReleaseConnection 'master'",[StringComparison]::Ordinal)
if($cleanupTimeoutOffset-lt0 -or $cleanupConnectOffset-lt0 -or $cleanupTimeoutOffset-ge$cleanupConnectOffset){throw 'JSON_CALLER_TX_OFFLINE_CLEANUP_TIMEOUT_ORDER'}
$script:clock=[pscustomobject]@{ElapsedMilliseconds=[long]300001};$script:cleanup=$false
$workRejected=$false
try{[void](Get-ReleaseTimeout)}catch{if($_.Exception.Message-ceq'RELEASE_DEADLINE'){$workRejected=$true}else{throw}}
if(-not$workRejected){throw 'JSON_CALLER_TX_OFFLINE_WORK_TIMEOUT_NOT_ENFORCED'}
$script:cleanup=$true;$cleanupTimeout=Get-ReleaseTimeout
if($cleanupTimeout-isnot[int]-or$cleanupTimeout-le0){throw 'JSON_CALLER_TX_OFFLINE_CLEANUP_RESERVE_EXHAUSTED'}
$script:clock=[Diagnostics.Stopwatch]::StartNew();$script:cleanup=$false
$envErrors=$null;$envAst=[Management.Automation.Language.Parser]::ParseFile($environment,[ref]$null,[ref]$envErrors)
foreach($name in @('Start-ClrCallerConfiguration','Restore-ClrCallerConfiguration')){
 $function=@($envAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
 if($envErrors.Count-or$function.Count-ne1){throw 'JSON_CALLER_TX_OFFLINE_ENVIRONMENT_HELPER'}
 $commands=@($function[0].Body.FindAll({param($n)$n-is[Management.Automation.Language.CommandAst]},$true)|ForEach-Object{$_.GetCommandName()})
 if('Invoke-ReleaseSql'-cnotin$commands-or'Save-ReleaseJournal'-cnotin$commands){throw 'JSON_CALLER_TX_OFFLINE_ENVIRONMENT_HELPER_DEPENDENCY'}
}

# Exercise the exact pinned batch wrapper with the production strict pin helper and a mock SQL sink.
$pinFunction=@($stableAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Assert-ReleasePin'},$true))
$privatePathFunction=@($stableAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Assert-ReleasePrivatePath'},$true))
$batchFunction=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Invoke-PinnedSqlBatches'},$true))
if($pinFunction.Count-ne1-or$privatePathFunction.Count-ne1-or$batchFunction.Count-ne1){throw 'JSON_CALLER_TX_OFFLINE_PIN_PROBE_HELPER'}
. ([scriptblock]::Create($pinFunction[0].Extent.Text))
. ([scriptblock]::Create($privatePathFunction[0].Extent.Text))
. ([scriptblock]::Create($batchFunction[0].Extent.Text))
function Assert-RunsetStable{}
$script:sqlCaptured=[Collections.Generic.List[string]]::new()
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){$script:sqlCaptured.Add($Text)}
$runtime=[IO.Path]::GetFullPath((Join-Path $script:repo '.runtime'))
$runtimePrefix=$runtime+[IO.Path]::DirectorySeparatorChar
$repo=$script:repo
$probeId=[guid]::NewGuid().ToString('N')
$probeDirectory=[IO.Path]::GetFullPath((Join-Path $runtime ('r35-jsonschema-caller-pin-'+$probeId)))
if(-not$probeDirectory.StartsWith($runtimePrefix,[StringComparison]::OrdinalIgnoreCase)-or(Test-Path -LiteralPath $probeDirectory)){throw 'JSON_CALLER_TX_OFFLINE_PROBE_PATH'}
$probeMarker=Join-Path $probeDirectory '.owner'
$probeFile=Join-Path $probeDirectory 'fixture.sql'
$probeCreated=$false
try{
 $null=Assert-ReleasePrivatePath $probeDirectory
 [void][IO.Directory]::CreateDirectory($probeDirectory);$probeCreated=$true
 if(((Get-Item -LiteralPath $probeDirectory -Force).Attributes-band[IO.FileAttributes]::ReparsePoint)-ne0){throw 'JSON_CALLER_TX_OFFLINE_PROBE_REPARSE'}
 [IO.File]::WriteAllText($probeMarker,$probeId,[Text.UTF8Encoding]::new($false))
 [IO.File]::WriteAllText($probeFile,'SELECT 1;'+"`n",[Text.UTF8Encoding]::new($false))
 $null=Assert-ReleasePrivatePath $probeFile
 $lowerHash=(Get-FileHash -LiteralPath $probeFile -Algorithm SHA256).Hash.ToLowerInvariant()
 Invoke-PinnedSqlBatches $null $probeFile $lowerHash
 if($script:sqlCaptured.Count-ne1-or$script:sqlCaptured[0].Trim()-cne'SELECT 1;'){throw 'JSON_CALLER_TX_OFFLINE_PINNED_BATCH_NOT_EXECUTED'}
 $wrongRejected=$false
 try{Invoke-PinnedSqlBatches $null $probeFile ('0'*64)}catch{$wrongRejected=$_.Exception.Message-ceq'RELEASE_INPUT_DRIFT'}
 if(-not$wrongRejected-or$script:sqlCaptured.Count-ne1){throw 'JSON_CALLER_TX_OFFLINE_WRONG_BATCH_HASH_ACCEPTED'}
 [IO.File]::WriteAllText($probeFile,'SELECT 2;'+"`n",[Text.UTF8Encoding]::new($false))
 $changedRejected=$false
 try{Invoke-PinnedSqlBatches $null $probeFile $lowerHash}catch{$changedRejected=$_.Exception.Message-ceq'RELEASE_INPUT_DRIFT'}
 if(-not$changedRejected-or$script:sqlCaptured.Count-ne1){throw 'JSON_CALLER_TX_OFFLINE_CHANGED_BATCH_ACCEPTED'}
}finally{
 if($probeCreated){
  $resolved=[IO.Path]::GetFullPath($probeDirectory)
  $info=Get-Item -LiteralPath $resolved -Force
  if(-not$resolved.StartsWith($runtimePrefix,[StringComparison]::OrdinalIgnoreCase)-or
     ($info.Attributes-band[IO.FileAttributes]::ReparsePoint)-ne0-or
     -not(Test-Path -LiteralPath $probeMarker -PathType Leaf)-or[IO.File]::ReadAllText($probeMarker)-cne$probeId){throw 'JSON_CALLER_TX_OFFLINE_PROBE_OWNERSHIP_LOST'}
  $children=@(Get-ChildItem -LiteralPath $resolved -Force)
  if(@($children|Where-Object{$_.Name-cnotin@('.owner','fixture.sql')-or($_.Attributes-band[IO.FileAttributes]::ReparsePoint)-ne0}).Count-ne0-or$children.Count-ne2){throw 'JSON_CALLER_TX_OFFLINE_PROBE_CONTENT_CHANGED'}
  Remove-Item -LiteralPath $probeFile -Force
  Remove-Item -LiteralPath $probeMarker -Force
  Remove-Item -LiteralPath $resolved -Force
 }
}
Write-Output 'PASS JSON_SCHEMA_CALLER_TRANSACTION offline case, guard, witness/savepoint ordering, and reuse checks; no SQL executed'
