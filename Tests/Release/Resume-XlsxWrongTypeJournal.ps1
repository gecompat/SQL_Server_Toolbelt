# Beendeten Controller nach atomarem Journal-I/O-Fehler fortsetzen; Run4 nie wiederholen.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,[Parameter(Mandatory)][string]$SourceRunsetPath,
      [Parameter(Mandatory)][string]$BudgetPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),[ref]$null,[ref]$null)
foreach($name in @('Save-ReleaseJournal','Assert-ReleasePrivatePath')){
    $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
    if($nodes.Count -ne 1){throw 'WRONGTYPE_JOURNAL_HELPER'}
    . ([scriptblock]::Create($nodes[0].Extent.Text))
}
. (Join-Path $repo 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1')
. (Join-Path $PSScriptRoot 'Xlsx.WrongType.Workload.ps1')
$RunsetPath=Assert-ReleasePrivatePath $RunsetPath;$SourceRunsetPath=Assert-ReleasePrivatePath $SourceRunsetPath
$script:journal=Assert-ReleasePrivatePath $BudgetPath
$script:ledger=Get-Content $BudgetPath -Raw|ConvertFrom-Json
if($script:ledger.PSObject.Properties['controller_recoveries'] -or $script:ledger.dispatches.Count -ne 11 -or
   $script:ledger.changed_adapter_cases -ne 1 -or $script:ledger.native_dispatch_max -ne 28 -or
   $script:ledger.database_max -ne 28 -or $script:ledger.database_reserved -ne 10 -or
   $script:ledger.dispatches[9].index -ne 4 -or $script:ledger.dispatches[9].state -cne 'DISPATCHED' -or
   $script:ledger.dispatches[10].state -cne 'RESERVED'){throw 'WRONGTYPE_JOURNAL_NOT_ADMITTED'}
$start=[DateTime]$script:ledger.native_started
if($script:ledger.native_started -isnot [DateTime]){$start=[DateTimeOffset]::Parse([string]$script:ledger.native_started).UtcDateTime}
if(($start.ToUniversalTime().AddMinutes(60)-[DateTime]::UtcNow).TotalSeconds -lt 900){throw 'WRONGTYPE_JOURNAL_ORIGINAL_DEADLINE'}
$before=Get-Content $SourceRunsetPath -Raw|ConvertFrom-Json;$after=Get-Content $RunsetPath -Raw|ConvertFrom-Json
if($before.qualification_scope -cne 'wrongtype-rest' -or $after.qualification_scope -cne 'wrongtype-rest' -or
   $before.contract_sha256 -cne $after.contract_sha256 -or
   ($before.cases|ConvertTo-Json -Depth 8 -Compress) -cne ($after.cases|ConvertTo-Json -Depth 8 -Compress) -or
   (Get-FileHash $SourceRunsetPath).Hash -cne $script:ledger.dispatches[9].runset_sha256){throw 'WRONGTYPE_JOURNAL_TARGET_DRIFT'}
foreach($mode in @('local','central')){foreach($action in @('Install','Repeat','Uninstall')){
    if((Get-FileHash $before.exports.$mode.$action).Hash -cne (Get-FileHash $after.exports.$mode.$action).Hash){throw 'WRONGTYPE_JOURNAL_PACKAGE_DRIFT'}
}}
foreach($pin in $after.pins){if((Get-FileHash $pin.path).Hash -cne $pin.sha256){throw 'WRONGTYPE_JOURNAL_INPUT_DRIFT'}}
$out=Split-Path -Parent $BudgetPath;$sourceRoot=Split-Path -Parent $SourceRunsetPath
$snapshot=Join-Path $out 'controller-io-source-budget.private.json'
if(Test-Path $snapshot){throw 'WRONGTYPE_JOURNAL_ALREADY_RESERVED'}
$sourceJournal=Join-Path $sourceRoot 'case-4.json'
$prior=Get-Content $sourceJournal -Raw|ConvertFrom-Json
if($prior.state -cne 'COMPLETE' -or @($prior.databases|Where-Object state -CNE 'DROPPED').Count){throw 'WRONGTYPE_JOURNAL_NATIVE_NOT_COMPLETE'}
Assert-XlsxWrongTypeJournal $prior
$native=$script:ledger.dispatches[9]
$sourceStdout=Join-Path $out ($native.id+'.stdout.private.txt');$sourceStderr=Join-Path $out ($native.id+'.stderr.private.txt')
if([IO.File]::ReadAllText($sourceStdout).Trim() -cne 'PASS XLSX_CELL_API selected original fixtures; separate audit required' -or
   (Get-Item $sourceStderr).Length -ne 0){throw 'WRONGTYPE_JOURNAL_NATIVE_FINAL_OUTPUT_MISSING'}
foreach($index in 0..4){
    $copy=Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$index+'.json')
    if(Test-Path $copy){throw 'WRONGTYPE_JOURNAL_CASE_ALREADY_PRESENT'}
    Copy-Item -LiteralPath (Join-Path $sourceRoot ('case-'+$index+'.json')) -Destination $copy
}
Copy-Item -LiteralPath $BudgetPath -Destination $snapshot
$script:ledger.audit_recoveries[0]|Add-Member recovered_runset_path $SourceRunsetPath
$script:ledger|Add-Member controller_recoveries @(@{source_budget_path=$snapshot;source_budget_sha256=(Get-FileHash $snapshot).Hash;
    source_runset_path=$SourceRunsetPath;source_journal_path=$sourceJournal;source_stdout_path=$sourceStdout;
    source_stdout_sha256=(Get-FileHash $sourceStdout).Hash;source_stderr_path=$sourceStderr;
    original_controller_error='ATOMIC_JOURNAL_REPLACE_ACCESS_DENIED';controller_return_status='NOT_PRESERVED'})
$script:ledger.changed_adapter_cases=2
$audit=$script:ledger.dispatches[10]
$audit|Add-Member planned_runset_sha256 $audit.runset_sha256
$audit.runset_sha256=(Get-FileHash $RunsetPath).Hash;$audit.final_journal_sha256=(Get-FileHash $sourceJournal).Hash
$audit|Add-Member capture_complete $false
$audit|Add-Member stdout_path (Join-Path $out 'controller-recovery-audit.stdout.private.txt')
$audit|Add-Member stderr_path (Join-Path $out 'controller-recovery-audit.stderr.private.txt')
$audit.state='DISPATCHED';$audit.dispatched=$true;Save-ReleaseJournal
$args=@('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'),'-RunsetPath',$RunsetPath,'-CaseIndex','4','-AuditOnly')
try{$result=Invoke-OwnedProcess -FileName $after.tools.powershell.path -Arguments $args -TimeoutMilliseconds 390000 -BinaryOutputPath $audit.stdout_path}
catch{$audit.state='DISPOSITION_UNKNOWN';Save-ReleaseJournal;throw}
[IO.File]::WriteAllText($audit.stderr_path,$result.Stderr)
$audit.exit_code=$result.ExitCode;$audit.stderr_empty=[string]::IsNullOrEmpty($result.Stderr);$audit.capture_complete=$result.CaptureComplete
if($result.ExitCode -ne 0 -or $result.Stderr -or -not $result.CaptureComplete -or
   [IO.File]::ReadAllText($audit.stdout_path).Trim() -cne 'PASS XLSX_FULL_SIZE independent database/trust/configuration audit'){
    $audit.state='AUDIT_FAILED';Save-ReleaseJournal;throw 'WRONGTYPE_JOURNAL_FRESH_AUDIT_FAILED'
}
$audit.state='AUDIT_PASS';Save-ReleaseJournal
[void](Assert-XlsxWrongTypeAuditRecovery $script:ledger $RunsetPath)
[void](Assert-XlsxWrongTypeControllerContinuation $script:ledger $RunsetPath)
$script:ledger.completed_keys+=@($audit.key);Save-ReleaseJournal
'PASS XLSX_WRONGTYPE case4 COMPLETE journal/final output preserved; controller return remains unknown; reserved fresh audit PASS; no native replay'
& (Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeMatrix.ps1') -RunsetPath $RunsetPath -BudgetPath $BudgetPath -CaseIndex (5..11)
