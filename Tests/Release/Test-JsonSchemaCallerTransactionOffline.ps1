[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$driver=Join-Path $PSScriptRoot 'Invoke-JsonSchemaCallerTransactionLab.ps1'
$preparer=Join-Path $PSScriptRoot 'Prepare-JsonSchemaCallerTransactionRunset.ps1'
$r33=Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1'
$r34=Join-Path $PSScriptRoot 'Invoke-JsonSchemaUninstallAppLockLab.ps1'
foreach($path in @($driver,$preparer,$r33,$r34)){
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
   $driverText-notmatch'SELECT @@OPTIONS AS ScalarValue' -or $driverText-notmatch'Test-ExternalSessionIdle'){
 throw 'JSON_CALLER_TX_OFFLINE_DRIVER_PROTOCOL_DRIFT'
}
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
Write-Output 'PASS JSON_SCHEMA_CALLER_TRANSACTION offline case, guard, witness/savepoint ordering, and reuse checks; no SQL executed'
