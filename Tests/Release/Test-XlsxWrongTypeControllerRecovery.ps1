# Synthetische Dateibindungen, keine SQL-Aufrufe und keine behauptete Hostunterbrechungsqualifikation.
param([Parameter(Mandatory)][string]$RunsetPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Xlsx.WrongType.Workload.ps1')
$out=Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($RunsetPath))) ('synthetic-controller-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($out)
$copy=Join-Path $out 'runset.json';Copy-Item $RunsetPath $copy
$dispatches=@(foreach($i in 0..8){@{id=('synthetic'+$i);phase='SYNTHETIC_PRIOR';state='AUDIT_PASS'}})
$run=@{id=('6'*32);index=4;phase='RUN';state='DISPATCHED';runset_sha256=(Get-FileHash $RunsetPath).Hash;exit_code=$null}
$reserved=@{id=('7'*32);index=4;phase='AUDIT';state='RESERVED'}
$source=Join-Path $out 'source-budget.json'
@{native_started='2026-01-01T00:00:00Z';dispatches=($dispatches+@($run,$reserved))}|ConvertTo-Json -Depth 12|Set-Content $source -Encoding utf8
$prior=@{state='COMPLETE';case=@{index=4};completedModes=@('local','central');databases=@(@{suffix='l';state='DROPPED'},@{suffix='c';state='DROPPED'});
    wrongTypes=@(foreach($mode in @('local','central')){@{mode=$mode;fixture='WrongType';status='PASS';deployRejections=1;uninstallRejections=1;foreignWitnesses=3}});
    lifecycle=@(@{action='InstallAndRepeat'},@{action='InstallAndRepeat'})}
$journal=Join-Path $out 'source-journal.json';$prior|ConvertTo-Json -Depth 12|Set-Content $journal -Encoding utf8
Copy-Item $journal (Join-Path $out 'case-4.json')
$nativeOut=Join-Path $out 'synthetic-native-no-sql.stdout.txt';$empty=Join-Path $out 'synthetic-no-sql.stderr.txt'
$auditOut=Join-Path $out 'synthetic-audit-no-sql.stdout.txt'
[IO.File]::WriteAllText($nativeOut,'PASS XLSX_CELL_API selected original fixtures; separate audit required')
[IO.File]::WriteAllText($auditOut,'PASS XLSX_FULL_SIZE independent database/trust/configuration audit')
[IO.File]::WriteAllText($empty,'')
$budget=Get-Content $source -Raw|ConvertFrom-Json
$audit=$budget.dispatches[10];$audit.state='AUDIT_PASS'
foreach($pair in @(@{name='exit_code';value=0},@{name='stderr_empty';value=$true},@{name='capture_complete';value=$true},
 @{name='runset_sha256';value=(Get-FileHash $copy).Hash},@{name='final_journal_sha256';value=(Get-FileHash $journal).Hash},
 @{name='stdout_path';value=$auditOut},@{name='stderr_path';value=$empty})){$audit|Add-Member $pair.name $pair.value}
$budget|Add-Member controller_recoveries @(@{source_budget_path=$source;source_budget_sha256=(Get-FileHash $source).Hash;
    source_runset_path=[IO.Path]::GetFullPath($RunsetPath);source_journal_path=$journal;source_stdout_path=$nativeOut;
    source_stdout_sha256=(Get-FileHash $nativeOut).Hash;source_stderr_path=$empty})
if((Assert-XlsxWrongTypeControllerContinuation $budget $copy) -cne $run.id -or $budget.dispatches[9].state -cne 'DISPATCHED' -or
   $null -ne $budget.dispatches[9].exit_code){throw 'SYNTHETIC_CONTROLLER_UNKNOWN_RETURN_UPGRADED'}
foreach($kind in @('history','clock','audit','capture','journal')){
    $probe=$budget|ConvertTo-Json -Depth 14|ConvertFrom-Json
    switch($kind){
        'history'{$probe.dispatches[9].state='COMPLETE'}
        'clock'{$probe.native_started=[DateTime]::Parse('2026-01-01T00:01:00Z')}
        'audit'{$probe.dispatches[10].state='RESERVED'}
        'capture'{$probe.dispatches[10].capture_complete=$false}
        'journal'{$probe.dispatches[10].final_journal_sha256='0'*64}
    }
    $caught=$false;try{[void](Assert-XlsxWrongTypeControllerContinuation $probe $copy)}catch{$caught=$true}
    if(-not $caught){throw 'SYNTHETIC_CONTROLLER_BAD_BINDING_ACCEPTED'}
}
'PASS XLSX_WRONGTYPE_CONTROLLER synthetic exact journal/final-output/fresh-audit binding; unknown return remains unknown;5 negative history/clock/audit/capture/journal controls; no SQL'
