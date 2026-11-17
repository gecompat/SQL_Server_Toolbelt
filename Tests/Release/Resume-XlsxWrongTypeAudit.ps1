# Einmalige lesende Auditkorrektur; keine Wiederholung des vollständigen Falles0.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,[Parameter(Mandatory)][string]$OriginalRunsetPath,
      [Parameter(Mandatory)][string]$BudgetPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),[ref]$null,[ref]$null)
foreach($name in @('Save-ReleaseJournal','Assert-ReleasePrivatePath')){
    $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
    if($nodes.Count -ne 1){throw 'WRONGTYPE_RECOVERY_HELPER'}
    . ([scriptblock]::Create($nodes[0].Extent.Text))
}
. (Join-Path $repo 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1')
. (Join-Path $PSScriptRoot 'Xlsx.WrongType.Workload.ps1')
$RunsetPath=Assert-ReleasePrivatePath $RunsetPath;$OriginalRunsetPath=Assert-ReleasePrivatePath $OriginalRunsetPath
$script:journal=Assert-ReleasePrivatePath $BudgetPath
$script:ledger=Get-Content $BudgetPath -Raw|ConvertFrom-Json
if($script:ledger.PSObject.Properties['audit_recoveries'] -or $script:ledger.dispatches.Count -ne 2 -or
   $script:ledger.native_dispatch_max -ne 28 -or $script:ledger.database_max -ne 28 -or
   $script:ledger.database_reserved -ne 2 -or $script:ledger.native_ceiling_minutes -ne 60 -or
   $script:ledger.dispatches[0].index -ne 0 -or $script:ledger.dispatches[0].state -cne 'COMPLETE' -or
   $script:ledger.dispatches[0].exit_code -ne 0 -or -not $script:ledger.dispatches[0].stderr_empty -or
   $script:ledger.dispatches[1].phase -cne 'AUDIT' -or $script:ledger.dispatches[1].state -cne 'AUDIT_FAILED'){
    throw 'WRONGTYPE_RECOVERY_NOT_ADMITTED'
}
$start=[DateTime]$script:ledger.native_started
if($script:ledger.native_started -isnot [DateTime]){$start=[DateTimeOffset]::Parse([string]$script:ledger.native_started).UtcDateTime}
if(($start.ToUniversalTime().AddMinutes(60)-[DateTime]::UtcNow).TotalSeconds -lt 900){throw 'WRONGTYPE_RECOVERY_ORIGINAL_DEADLINE'}
$before=Get-Content $OriginalRunsetPath -Raw|ConvertFrom-Json;$after=Get-Content $RunsetPath -Raw|ConvertFrom-Json
if($before.qualification_scope -cne 'wrongtype-rest' -or $after.qualification_scope -cne 'wrongtype-rest' -or
   $before.contract_sha256 -cne $after.contract_sha256 -or
   (Get-FileHash $OriginalRunsetPath).Hash -cne $script:ledger.dispatches[0].runset_sha256 -or
   ($before.cases|ConvertTo-Json -Depth 8 -Compress) -cne ($after.cases|ConvertTo-Json -Depth 8 -Compress)){
    throw 'WRONGTYPE_RECOVERY_TARGET_DRIFT'
}
foreach($mode in @('local','central')){foreach($action in @('Install','Repeat','Uninstall')){
    if((Get-FileHash $before.exports.$mode.$action).Hash -cne (Get-FileHash $after.exports.$mode.$action).Hash){throw 'WRONGTYPE_RECOVERY_PACKAGE_DRIFT'}
}}
foreach($pin in $after.pins){if((Get-FileHash -LiteralPath $pin.path).Hash -cne $pin.sha256){throw 'WRONGTYPE_RECOVERY_INPUT_DRIFT'}}
$oldJournal=Join-Path (Split-Path -Parent $OriginalRunsetPath) 'case-0.json'
$newJournal=Join-Path (Split-Path -Parent $RunsetPath) 'case-0.json'
$prior=Get-Content $oldJournal -Raw|ConvertFrom-Json
if($prior.state -cne 'COMPLETE'){throw 'WRONGTYPE_RECOVERY_ORIGINAL_NOT_COMPLETE'}
Assert-XlsxWrongTypeJournal $prior
if(Test-Path -LiteralPath $newJournal){throw 'WRONGTYPE_RECOVERY_CASE_ALREADY_EXISTS'}
$out=Split-Path -Parent $BudgetPath
$snapshot=Join-Path $out 'audit-recovery-source-budget.private.json'
if(Test-Path -LiteralPath $snapshot){throw 'WRONGTYPE_RECOVERY_ALREADY_RESERVED'}
Copy-Item -LiteralPath $BudgetPath -Destination $snapshot
Copy-Item -LiteralPath $oldJournal -Destination $newJournal
$item=[pscustomobject]@{id=[guid]::NewGuid().ToString('N');key=$script:ledger.dispatches[0].key;index=0;phase='AUDIT_RECOVERY';
    state='RESERVED';dispatched=$false;runset_sha256=(Get-FileHash $RunsetPath).Hash;final_journal_sha256=(Get-FileHash $oldJournal).Hash;
    exit_code=$null;stderr_empty=$null;capture_complete=$false;stdout_path=(Join-Path $out 'recovery-audit.stdout.private.txt');
    stdout_sha256=$null;stderr_path=(Join-Path $out 'recovery-audit.stderr.private.txt')}
$script:ledger.dispatches+=@($item)
$script:ledger|Add-Member audit_recoveries @(@{original_budget_path=$snapshot;original_budget_sha256=(Get-FileHash $snapshot).Hash;
    original_runset_path=$OriginalRunsetPath;original_journal_path=$oldJournal;recovery_id=$item.id})
$script:ledger|Add-Member changed_adapter_cases 1
$item.state='DISPATCHED';$item.dispatched=$true;Save-ReleaseJournal
$args=@('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'),'-RunsetPath',$RunsetPath,'-CaseIndex','0','-AuditOnly')
try{$result=Invoke-OwnedProcess -FileName $after.tools.powershell.path -Arguments $args -TimeoutMilliseconds 390000 -BinaryOutputPath $item.stdout_path}
catch{$item.state='DISPOSITION_UNKNOWN';Save-ReleaseJournal;throw}
[IO.File]::WriteAllText($item.stderr_path,$result.Stderr)
$item.exit_code=$result.ExitCode;$item.stderr_empty=[string]::IsNullOrEmpty($result.Stderr);$item.capture_complete=$result.CaptureComplete
$item.stdout_sha256=(Get-FileHash $item.stdout_path).Hash
if($result.ExitCode -ne 0 -or $result.Stderr -or -not $result.CaptureComplete -or
   [IO.File]::ReadAllText($item.stdout_path).Trim() -cne 'PASS XLSX_FULL_SIZE independent database/trust/configuration audit' -or
   (Get-FileHash $oldJournal).Hash -cne $item.final_journal_sha256 -or (Get-FileHash $newJournal).Hash -cne $item.final_journal_sha256){
    $item.state='AUDIT_FAILED';Save-ReleaseJournal;throw 'WRONGTYPE_RECOVERY_FRESH_AUDIT_FAILED'
}
$item.state='AUDIT_PASS';Save-ReleaseJournal
[void](Assert-XlsxWrongTypeAuditRecovery $script:ledger $RunsetPath)
$script:ledger.completed_keys+=@($item.key);Save-ReleaseJournal
'PASS XLSX_WRONGTYPE original COMPLETE case not replayed; fresh corrected audit and exact history/journal binding'
& (Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeMatrix.ps1') -RunsetPath $RunsetPath -BudgetPath $BudgetPath -CaseIndex (1..11)
