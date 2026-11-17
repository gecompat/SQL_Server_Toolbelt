# Vorbereiteter einmaliger Case4-Observer; ohne explizite neue Autorisierung kein SQL.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$WaveRoot,[switch]$Execute)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$WaveRoot=[IO.Path]::GetFullPath($WaveRoot)
if(-not $WaveRoot.StartsWith((Join-Path $repo '.runtime')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'ONECASE_PRIVATE_WAVE_REQUIRED'}
$budgetPath=Join-Path $WaveRoot 'budget.private.json'
$b=Get-Content $budgetPath -Raw|ConvertFrom-Json
if(-not $Execute){'PREPARED_NOT_EXECUTED: fixed Linux2025/CL160 case4;2calls/2DBs/45min; no retries';return}
if($b.status -cne 'AUTHORIZED' -or $b.case_index -ne 4 -or $b.native_calls_max -ne 2 -or $b.database_max -ne 2 -or
   $b.minutes_max -ne 45 -or $b.retry_max -ne 0 -or $b.native_started -or $b.calls.Count){throw 'ONECASE_NEW_EXPLICIT_AUTHORITY_REQUIRED'}
if((git -C $repo rev-parse HEAD) -cne $b.expected_source_commit -or $b.integration_main_ci_conclusion -cne 'SUCCESS'){throw 'ONECASE_GREEN_MAIN_REQUIRED'}
git -C $repo merge-base --is-ancestor $b.integration_base_commit HEAD
if($LASTEXITCODE -ne 0){throw 'ONECASE_INTEGRATION_BASE_REQUIRED'}
$report=Join-Path $repo 'Releases/1.0.0/XLSX-WRONGTYPE-REST-QUALIFICATION.json'
$r=Get-Content $report -Raw|ConvertFrom-Json
if($r.status -cne 'PARTIAL' -or $r.cases[4].process_result -cne 'NOT_PRESERVED'){throw 'ONECASE_NO_MATCHING_GAP'}
$runsetPath=[IO.Path]::GetFullPath($b.runset_path)
$rs=Get-Content $runsetPath -Raw|ConvertFrom-Json
if($rs.qualification_scope -cne 'wrongtype-rest' -or $rs.cases[4].Platform -cne 'linux' -or
   $rs.cases[4].Version -cne '2025' -or $rs.cases[4].Patch -cne 'latest' -or $rs.cases[4].CL -ne 160){throw 'ONECASE_TARGET_DRIFT'}
foreach($pin in $rs.pins){if((Get-FileHash $pin.path).Hash -cne $pin.sha256){throw 'ONECASE_INPUT_DRIFT'}}
$caseJournal=Join-Path (Split-Path -Parent $runsetPath) 'case-4.json'
if(Test-Path $caseJournal){throw 'ONECASE_FRESH_RUNSET_REQUIRED'}
. (Join-Path $repo 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1')
function Write-OnceJson([string]$Path,$Value){
 $bytes=[Text.UTF8Encoding]::new($false,$true).GetBytes(($Value|ConvertTo-Json -Depth 12))
 $s=[IO.FileStream]::new($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None,4096,[IO.FileOptions]::WriteThrough)
 try{$s.Write($bytes,0,$bytes.Length);$s.Flush($true)}finally{$s.Dispose()}
}
Write-OnceJson (Join-Path $WaveRoot 'attempt.private.json') @{case_index=4;authorized_budget_sha256=(Get-FileHash $budgetPath).Hash;started=[DateTime]::UtcNow.ToString('o')}
$start=[DateTime]::UtcNow;$failed=$false
$boundRunsetHash=(Get-FileHash $runsetPath).Hash
$boundScriptHash=(Get-FileHash (Join-Path $repo 'Tests/Release/Invoke-XlsxFullSizeLab.ps1')).Hash
foreach($phase in @('RUN','AUDIT')){
 if(($start.AddMinutes(45)-[DateTime]::UtcNow).TotalSeconds -lt 1){throw 'ONECASE_ORIGINAL_DEADLINE'}
 $out=Join-Path $WaveRoot ($phase+'.stdout.private.txt');$err=Join-Path $WaveRoot ($phase+'.stderr.private.txt')
 $args=@('-NoProfile','-NonInteractive','-File',(Join-Path $repo 'Tests/Release/Invoke-XlsxFullSizeLab.ps1'),'-RunsetPath',$runsetPath,'-CaseIndex','4')
 if($phase -ceq 'AUDIT'){$args+='-AuditOnly'}
 $limit=[int][Math]::Min(390000,[Math]::Floor(($start.AddMinutes(45)-[DateTime]::UtcNow).TotalMilliseconds))
 $result=Invoke-OwnedProcess -FileName $rs.tools.powershell.path -Arguments $args -TimeoutMilliseconds $limit -BinaryOutputPath $out
 # Numerischen Rückgabewert zuerst sichern, noch vor anderen Datei-/Journalreads.
 Write-OnceJson (Join-Path $WaveRoot ($phase+'.numeric-return.private.json')) @{phase=$phase;case_index=4;exit_code=$result.ExitCode;capture_complete=$result.CaptureComplete;stderr_empty=[string]::IsNullOrEmpty($result.Stderr);runset_sha256=$boundRunsetHash;native_script_sha256=$boundScriptHash;observed_utc=[DateTime]::UtcNow.ToString('o')}
 [IO.File]::WriteAllText($err,$result.Stderr)
 $j=Get-Content $caseJournal -Raw|ConvertFrom-Json
 $receipt=@{schema_version='wrongtype-case4-process-receipt/v1';phase=$phase;case_index=4;observed_utc=[DateTime]::UtcNow.ToString('o');
   exit_code=$result.ExitCode;capture_complete=$result.CaptureComplete;stderr_empty=[string]::IsNullOrEmpty($result.Stderr);
   runset_sha256=(Get-FileHash $runsetPath).Hash;final_journal_sha256=(Get-FileHash $caseJournal).Hash;
   numeric_return_receipt_sha256=(Get-FileHash (Join-Path $WaveRoot ($phase+'.numeric-return.private.json'))).Hash;
   stdout_sha256=(Get-FileHash $out).Hash;stderr_sha256=(Get-FileHash $err).Hash;native_state=$j.state}
 # Primärreceipt zuerst dauerhaft schreiben; kein unbekannter Wert wird aus späteren Metadaten abgeleitet.
 Write-OnceJson (Join-Path $WaveRoot ($phase+'.process-receipt.private.json')) $receipt
 $expected=if($phase -ceq 'RUN'){'PASS XLSX_CELL_API selected original fixtures; separate audit required'}else{'PASS XLSX_FULL_SIZE independent database/trust/configuration audit'}
 if($result.ExitCode -ne 0 -or -not $result.CaptureComplete -or $result.Stderr -or [IO.File]::ReadAllText($out).Trim() -cne $expected -or $j.state -cne 'COMPLETE'){$failed=$true}
}
if($failed){throw 'ONECASE_FAILED_RETAIN_RECEIPTS_NO_RETRY'}
'PASS ONECASE4 exact process receipts and fresh audit retained; historical PARTIAL report unchanged'
