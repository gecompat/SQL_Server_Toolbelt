# Serieller Dispatcher mit gemeinsamen Grenzen; keine Rechte-/Infrastrukturverwaltung.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
      [Parameter(Mandatory)][string]$BudgetPath,
      [ValidateRange(0,11)][int[]]$CaseIndex=@(0,1,2,3,4,5,6,7,8,9,10,11),
      [switch]$DiagnosticOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
$cellApi=($null -ne $runset.PSObject.Properties['qualification_scope'])
$maximum=if($cellApi){switch($runset.qualification_scope){'cell-display-rest'{6};'cell-client-rest'{24};'genuine10-rest'{28};'genuine10-central-rest'{28};'genuine11-rest'{24};'lifecycle-negative-rest'{28};'future-collision-rest'{28};'type-future-collision-rest'{28};'caller-catalog-rest'{28};'marker-collision-rest'{28};'composition-consumer-rest'{28};'wrongtype-rest'{28};default{20}}}else{30}
$databaseMaximum=if($cellApi -and $runset.qualification_scope -ceq 'composition-consumer-rest'){42}else{$maximum}
$perCaseDatabases=if($cellApi -and $runset.qualification_scope -ceq 'composition-consumer-rest'){3}else{2}
$allowed=if($cellApi -and $runset.qualification_scope -ceq 'genuine11-rest'){@(0,1,2,3,4,5,6,7,8,9,10,11)}elseif($cellApi -and $runset.qualification_scope -cin @('lifecycle-negative-rest','future-collision-rest','type-future-collision-rest','caller-catalog-rest','marker-collision-rest','composition-consumer-rest','wrongtype-rest')){@(0,1,2,3,4,5,6,7,8,9,10,11)}elseif($cellApi -and $runset.qualification_scope -ceq 'genuine10-central-rest'){@(0)}elseif($cellApi -and $runset.qualification_scope -ceq 'genuine10-rest'){@(0,1,2,3,4,5,6,7,8,9,10,11)}elseif($cellApi -and $runset.qualification_scope -ceq 'cell-display-rest'){@(9,10,11)}elseif($cellApi -and $runset.qualification_scope -ceq 'cell-client-rest'){@(1,2,3,4,5,6,7,8,9,10,11)}else{@(1,2,3,4,5,6,7,8)}
$correctionMax=if($cellApi -and $runset.qualification_scope -ceq 'genuine11-rest'){0}elseif($cellApi -and $runset.qualification_scope -ceq 'cell-client-rest'){1}else{2}
if($cellApi -and ($runset.qualification_scope -cnotin @('cell-api-rest','cell-display-rest','cell-client-rest','genuine10-rest','genuine10-central-rest','genuine11-rest','lifecycle-negative-rest','future-collision-rest','type-future-collision-rest','caller-catalog-rest','marker-collision-rest','composition-consumer-rest','wrongtype-rest') -or $DiagnosticOnly -or
   @($CaseIndex|Where-Object {$_ -notin $allowed}).Count)){throw 'XLSX_CELL_MATRIX_SCOPE'}
$script:ledger=Get-Content -LiteralPath $BudgetPath -Raw|ConvertFrom-Json
if($script:ledger.PSObject.Properties['native_closed'] -and $script:ledger.native_closed){throw 'MATRIX_CLOSED_BUDGET'}
$script:journal=[IO.Path]::GetFullPath($BudgetPath)
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),[ref]$null,[ref]$null)
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Save-ReleaseJournal'},$true))
if($nodes.Count -ne 1){throw 'MATRIX_JOURNAL_HELPER'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
. (Join-Path $repo 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1')
if($script:ledger.native_ceiling_minutes -ne 60 -or $script:ledger.native_dispatch_max -ne $maximum -or
   $script:ledger.database_max -ne $databaseMaximum -or $script:ledger.changed_adapter_cases_max -ne $correctionMax -or
   $runset.schema_version -cne 'xlsx-full-size-package/v1' -or $runset.cases.Count -ne 12){throw 'MATRIX_SCOPE_DRIFT'}
if(@($CaseIndex|Sort-Object -Unique).Count -ne $CaseIndex.Count){throw 'MATRIX_DUPLICATE_CASE'}
if(-not $script:ledger.native_started){
    if($script:ledger.dispatches.Count){throw 'MATRIX_START_HISTORY_LOST'}
    $script:ledger.native_started=[DateTime]::UtcNow.ToString('o')
    $script:ledger|Add-Member -NotePropertyName database_reserved -NotePropertyValue 0
    $script:ledger|Add-Member -NotePropertyName completed_keys -NotePropertyValue @()
    Save-ReleaseJournal
}
$started=if($script:ledger.native_started -is [DateTime]){$script:ledger.native_started.ToUniversalTime()}
         elseif($script:ledger.native_started -is [DateTimeOffset]){$script:ledger.native_started.UtcDateTime}
         else{[DateTimeOffset]::Parse([string]$script:ledger.native_started,[Globalization.CultureInfo]::InvariantCulture).UtcDateTime}
$deadline=$started.AddMinutes(60)
foreach($rejected in @($script:ledger.dispatches|Where-Object state -CEQ 'PRE_SQL_REJECTED')){
    $audits=@($script:ledger.dispatches|Where-Object {$_.key -ceq $rejected.key -and $_.phase -ceq 'AUDIT' -and $_.state -ceq 'AUDIT_PASS' -and $_.runset_sha256 -ceq $rejected.runset_sha256})
    if($audits.Count -ne 1 -or (Get-FileHash -LiteralPath $rejected.rejection_receipt_path -Algorithm SHA256).Hash -cne $rejected.rejection_receipt_sha256){throw 'MATRIX_REJECTION_AUDIT_BINDING'}
    $receipt=Get-Content -LiteralPath $rejected.rejection_receipt_path -Raw|ConvertFrom-Json
    if($receipt.status -cne 'PASS_PRE_SQL_REJECTION_AUDIT' -or $receipt.own_mutating_stage_reached -or $receipt.own_resource_ids_allocated -or $receipt.runset_sha256 -cne $rejected.runset_sha256){throw 'MATRIX_REJECTION_SCOPE'}
}
$reconciledAuditIds=@()
if($cellApi -and $runset.qualification_scope -ceq 'wrongtype-rest' -and $script:ledger.PSObject.Properties['audit_recoveries']){
    . (Join-Path $PSScriptRoot 'Xlsx.WrongType.Workload.ps1')
    $reconciledAuditIds=@(Assert-XlsxWrongTypeAuditRecovery $script:ledger $RunsetPath)
}
if(@($script:ledger.dispatches|Where-Object {$_.dispatched -and $_.state -cnotin @('COMPLETE','FAILED_CLEANED','PRE_SQL_REJECTED','AUDIT_PASS') -and
    -not ($_.state -ceq 'AUDIT_FAILED' -and $_.id -cin $reconciledAuditIds)}).Count){throw 'MATRIX_UNRECONCILED_DISPATCH'}
$out=Split-Path -Parent $BudgetPath
foreach($index in $CaseIndex){
    $case=$runset.cases[$index];$key=$case.Platform+'/'+$case.Version+'/'+$case.CL
    if($cellApi -and $runset.qualification_scope -ceq 'genuine10-central-rest'){$key='genuine-central/'+$key}
    if($DiagnosticOnly){
        if($CaseIndex.Count -ne 1 -or $index -ne 0 -or @($script:ledger.dispatches|Where-Object {$_.key -like 'diagnostic/*'}).Count){throw 'MATRIX_DIAGNOSTIC_BOUND'}
        $key='diagnostic/'+$key
    }
    if($key -cin $script:ledger.completed_keys -or @($script:ledger.dispatches|Where-Object {$_.key -ceq $key -and $_.phase -ceq 'RUN' -and ($_.state -ceq 'COMPLETE' -or $_.completed_modes.Count -gt 0)}).Count){throw 'MATRIX_GREEN_REPLAY_REJECTED'}
    if($script:ledger.dispatches.Count+2 -gt $maximum -or $script:ledger.database_reserved+$perCaseDatabases -gt $databaseMaximum -or
       ($deadline-[DateTime]::UtcNow).TotalSeconds -lt 780){throw 'MATRIX_NEXT_PAIR_NOT_WITHIN_SHARED_BOUND'}
    foreach($pin in $runset.pins){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash -cne $pin.sha256){throw 'MATRIX_INPUT_DRIFT'}}
    $run=@{id=[guid]::NewGuid().ToString('N');key=$key;phase='RUN';index=$index;state='RESERVED';dispatched=$false;runset_sha256=(Get-FileHash -LiteralPath $RunsetPath -Algorithm SHA256).Hash;exit_code=$null;stderr_empty=$null;completed_modes=@();diagnostic=$null}
    $audit=@{id=[guid]::NewGuid().ToString('N');key=$key;phase='AUDIT';index=$index;state='RESERVED';dispatched=$false;runset_sha256=$run.runset_sha256;exit_code=$null;stderr_empty=$null;completed_modes=@();diagnostic=$null;final_journal_sha256=$null}
    $script:ledger.dispatches+=@($run,$audit);$script:ledger.database_reserved+=$perCaseDatabases;Save-ReleaseJournal
    foreach($item in @($run,$audit)){
        $item.dispatched=$true;$item.state='DISPATCHED';Save-ReleaseJournal
        $scriptName=if($DiagnosticOnly -and $item.phase -ceq 'RUN'){'Invoke-XlsxFullSizeStateDiagnostic.ps1'}else{'Invoke-XlsxFullSizeLab.ps1'}
        $args=@('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot $scriptName),'-RunsetPath',$RunsetPath,'-CaseIndex',([string]$index))
        if($item.phase -ceq 'AUDIT'){$args+='-AuditOnly'}
        $stdoutPath=Join-Path $out ($item.id+'.stdout.private.txt')
        try{$result=Invoke-OwnedProcess -FileName $runset.tools.powershell.path -Arguments $args -TimeoutMilliseconds 390000 -BinaryOutputPath $stdoutPath}
        catch{$item.state='DISPOSITION_UNKNOWN';$item.diagnostic=$_.Exception.Message;Save-ReleaseJournal;throw}
        [IO.File]::WriteAllText((Join-Path $out ($item.id+'.stderr.private.txt')),$result.Stderr)
        $item.exit_code=$result.ExitCode;$item.stderr_empty=[string]::IsNullOrEmpty($result.Stderr)
        if(-not $result.CaptureComplete){$item.state='CAPTURE_INCOMPLETE';Save-ReleaseJournal;throw 'MATRIX_CAPTURE_INCOMPLETE'}
        $caseJournal=Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$index+'.json')
        if($item.phase -ceq 'RUN'){
            $state=Get-Content -LiteralPath $caseJournal -Raw|ConvertFrom-Json
            $item.state=$state.state
            $item.completed_modes=@($state.completedModes)
            if($state.state -cnotin @('COMPLETE','FAILED_CLEANED')){Save-ReleaseJournal;throw 'MATRIX_CLEANUP_UNRESOLVED'}
            $audit.final_journal_sha256=(Get-FileHash -LiteralPath $caseJournal -Algorithm SHA256).Hash
        }else{
            if($result.ExitCode -ne 0 -or $result.Stderr -or
               [IO.File]::ReadAllText($stdoutPath).Trim() -cne 'PASS XLSX_FULL_SIZE independent database/trust/configuration audit' -or
               (Get-FileHash -LiteralPath $caseJournal -Algorithm SHA256).Hash -cne $audit.final_journal_sha256){
                $item.state='AUDIT_FAILED';Save-ReleaseJournal;throw 'MATRIX_FRESH_AUDIT_FAILED'
            }
            $item.state='AUDIT_PASS'
        }
        Save-ReleaseJournal
    }
    if($DiagnosticOnly){
        $diagnosis=Get-Content -LiteralPath $caseJournal -Raw|ConvertFrom-Json
        if($run.state -cne 'FAILED_CLEANED' -or $diagnosis.failure.privateDiagnostic -cne 'XLSX_FULL_SIZE_DIAGNOSTIC_STOP_AFTER_REPEAT_STATE' -or @($diagnosis.results).Count){throw 'MATRIX_DIAGNOSTIC_INCOMPLETE'}
        Write-Output 'PASS XLSX_FULL_SIZE state captured; intentional stop and fresh audit; no qualification PASS'
        continue
    }
    if($run.state -cne 'COMPLETE' -or $run.exit_code -ne 0 -or -not $run.stderr_empty){throw 'MATRIX_CASE_FAILED_CLEANED_AND_AUDITED'}
    $script:ledger.completed_keys+=@($key);Save-ReleaseJournal
    Write-Output ('PASS XLSX_FULL_SIZE native case '+$index+'; fresh audit PASS')
}
Write-Output 'PASS XLSX_FULL_SIZE requested native matrix complete'
