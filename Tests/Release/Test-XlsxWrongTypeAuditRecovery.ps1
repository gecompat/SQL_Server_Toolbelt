# Vollständig synthetische Recoveryreceipts; keine SQL-Ausführung oder Native-PASS-Behauptung.
param([Parameter(Mandatory)][string]$RunsetPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Xlsx.WrongType.Workload.ps1')
$out=Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($RunsetPath))) ('synthetic-recovery-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($out)
$copy=Join-Path $out 'runset.json';Copy-Item -LiteralPath $RunsetPath -Destination $copy
$native=@{id=('3'*32);phase='RUN';index=0;key='linux/2019/150';state='COMPLETE';dispatched=$true;exit_code=0;stderr_empty=$true;runset_sha256=(Get-FileHash $RunsetPath).Hash}
$failed=@{id=('4'*32);phase='AUDIT';index=0;key='linux/2019/150';state='AUDIT_FAILED';dispatched=$true;exit_code=1;stderr_empty=$true;runset_sha256=$native.runset_sha256}
$original=Join-Path $out 'original-budget.json'
@{native_started='2026-01-01T00:00:00Z';native_dispatch_max=28;database_max=28;native_ceiling_minutes=60;dispatches=@($native,$failed)}|
    ConvertTo-Json -Depth 12|Set-Content $original -Encoding utf8
$prior=@{state='COMPLETE';completedModes=@('local','central');databases=@(@{suffix='l'},@{suffix='c'});
    wrongTypes=@(foreach($mode in @('local','central')){@{mode=$mode;fixture='WrongType';status='PASS';deployRejections=1;uninstallRejections=1;foreignWitnesses=3}});
    lifecycle=@(@{action='InstallAndRepeat'},@{action='InstallAndRepeat'})}
$journal=Join-Path $out 'original-journal.json';$prior|ConvertTo-Json -Depth 12|Set-Content $journal -Encoding utf8
Copy-Item -LiteralPath $journal -Destination (Join-Path $out 'case-0.json')
$stdout=Join-Path $out 'synthetic-no-sql.stdout.txt';$stderr=Join-Path $out 'synthetic-no-sql.stderr.txt'
[IO.File]::WriteAllText($stdout,'PASS XLSX_FULL_SIZE independent database/trust/configuration audit')
[IO.File]::WriteAllText($stderr,'')
$audit=@{id=('5'*32);phase='AUDIT_RECOVERY';index=0;key='linux/2019/150';state='AUDIT_PASS';dispatched=$true;exit_code=0;
    stderr_empty=$true;capture_complete=$true;runset_sha256=(Get-FileHash $copy).Hash;final_journal_sha256=(Get-FileHash $journal).Hash;
    stdout_path=$stdout;stdout_sha256=(Get-FileHash $stdout).Hash;stderr_path=$stderr}
$budget=Get-Content $original -Raw|ConvertFrom-Json
$budget.dispatches+=@($audit)
$budget|Add-Member audit_recoveries @(@{original_budget_path=$original;original_budget_sha256=(Get-FileHash $original).Hash;
    original_runset_path=[IO.Path]::GetFullPath($RunsetPath);original_journal_path=$journal;recovery_id=$audit.id})
if((Assert-XlsxWrongTypeAuditRecovery $budget $copy) -cne $failed.id){throw 'SYNTHETIC_RECOVERY_ROUTING'}
foreach($kind in @('history','clock','not-pass','capture','journal')){
    $probe=$budget|ConvertTo-Json -Depth 14|ConvertFrom-Json
    switch($kind){
        'history'{$probe.dispatches[1].state='AUDIT_PASS'}
        'clock'{$probe.native_started=[DateTime]::Parse('2026-01-01T00:01:00Z')}
        'not-pass'{$probe.dispatches[2].state='DISPATCHED'}
        'capture'{$probe.dispatches[2].capture_complete=$false}
        'journal'{$probe.dispatches[2].final_journal_sha256='0'*64}
    }
    $caught=$false;try{[void](Assert-XlsxWrongTypeAuditRecovery $probe $copy)}catch{$caught=$true}
    if(-not $caught){throw 'SYNTHETIC_RECOVERY_BAD_RECEIPT_ACCEPTED'}
}
'PASS XLSX_WRONGTYPE_AUDIT_RECOVERY synthetic positive and5 history/clock/status/capture/journal negatives; no SQL or native audit'
