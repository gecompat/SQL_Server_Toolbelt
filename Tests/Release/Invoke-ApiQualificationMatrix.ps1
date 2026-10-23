[CmdletBinding()]
param([string]$InputDirectory,[string]$EvidenceDirectory,[switch]$PlanOnly,[switch]$FreezeOnly,
 [string]$FrozenRunset,[string]$SharedBudgetFile,[string]$ChangedInputReason)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$driver=Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($driver,[ref]$null,[ref]$errors)
if($errors.Count){throw 'RELEASE_API_DRIVER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($b in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @('Assert-ReleasePrivatePath','Assert-ReleasePin')){. $b}
. (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
$helper=Join-Path $repo 'Tests/CI/run-lab-local.ps1'
foreach($b in Import-ClrFunctions $helper @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector')){. $b}
$lab=Resolve-LabContract -TestPurpose Functional
$prompt=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
if(-not $prompt -or -not (Test-Path -LiteralPath $prompt)){throw 'RELEASE_REVIEWED_LAB_PROMPT_REQUIRED'}
function Save-ApiJson($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))}
if($FrozenRunset){
 $runsetPath=Assert-ReleasePrivatePath $FrozenRunset
 $runset=Get-Content -LiteralPath $runsetPath -Raw|ConvertFrom-Json
 $evidence=Split-Path -Parent $runsetPath
 $SharedBudgetFile=$runset.sharedBudget
}else{
 $inputPath=Assert-ReleasePrivatePath (Join-Path $InputDirectory 'input.json')
 $input=Get-Content -LiteralPath $inputPath -Raw|ConvertFrom-Json
 if((Get-FileHash -LiteralPath $input.complete_input -Algorithm SHA256).Hash -ine $input.complete_input_sha256){throw 'RELEASE_API_STAGED_PACKAGE_DRIFT'}
 $spec=Get-Content -LiteralPath $input.spec -Raw|ConvertFrom-Json
 $cases=@()
 foreach($group in $spec.groups){
  foreach($platform in @('linux','windows')){
   if($group -ceq 'windows' -and $platform -cne 'windows'){continue}
   foreach($version in @('2019','2022','2025')){
    if($group -ceq 'translate-large' -and (($platform -ceq 'linux' -and $version -ceq '2019') -or ($platform -ceq 'windows' -and $version -ceq '2025'))){continue}
    $patch=if($platform -ceq 'windows'){'base'}else{'latest'}
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$platform;Version=$version;Patch=$patch}))
    if(-not $targets.Count){throw 'RELEASE_API_TARGET_NOT_READY'}
    foreach($target in $targets){
     foreach($cl in @(150,160,170)|Where-Object {$_ -le @{'2019'=150;'2022'=160;'2025'=170}[$version]}){
      $csv=$group -ceq 'csv';$large=$group -ceq 'translate-large';$core=$group -ceq 'core'
      $cases+=@([ordered]@{Platform=$platform;Version=$version;Patch=[string]$target.patch;CL=$cl;group=$group;
       key="$group/$platform/$version/$($target.patch)/$cl";
       workSeconds=$(if($large){$spec.budget.translate_work_seconds}elseif($core){$spec.budget.core_work_seconds}elseif($csv){$spec.budget.csv_work_seconds}else{$spec.budget.ordinary_work_seconds});
       cleanupSeconds=$(if($large){$spec.budget.translate_cleanup_deadline_seconds}elseif($core){$spec.budget.core_cleanup_deadline_seconds}elseif($csv){$spec.budget.csv_cleanup_deadline_seconds}else{$spec.budget.ordinary_cleanup_deadline_seconds});
       outerSeconds=$(if($large){$spec.budget.translate_outer_seconds}elseif($core){$spec.budget.core_outer_seconds}elseif($csv){$spec.budget.csv_outer_seconds}else{$spec.budget.ordinary_outer_seconds})})
     }
    }
   }
  }
 }
 if($cases.Count -ne 74 -or $spec.tests.Count -ne 165){throw 'RELEASE_API_FINITE_SCOPE_CHANGED'}
 if($PlanOnly){'PASS RELEASE_API_PLAN 74 cases, 165 canonical fixture definitions; no SQL connection';return}
 $evidence=Assert-ReleasePrivatePath $EvidenceDirectory
 if(Test-Path -LiteralPath $evidence){throw 'RELEASE_API_NEW_EVIDENCE_REQUIRED'}
 [void][IO.Directory]::CreateDirectory($evidence)
 if(-not $SharedBudgetFile){$SharedBudgetFile=Join-Path $evidence 'wave-budget.json'}
 $SharedBudgetFile=Assert-ReleasePrivatePath $SharedBudgetFile
 if(Test-Path -LiteralPath $SharedBudgetFile){
  if([string]::IsNullOrWhiteSpace($ChangedInputReason)){throw 'RELEASE_API_REPAIR_INPUT_REASON_REQUIRED'}
 }else{
  Save-ApiJson $SharedBudgetFile @{startedUtc=[DateTime]::UtcNow.ToString('o');attempts=0;limit=90;seconds=36000;completed=@();history=@()}
 }
 $paths=@($driver,$PSCommandPath,(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-CompletePackageLab.ps1'),
  (Join-Path $PSScriptRoot 'prepare_api_qualification.py'),(Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),
  (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),$helper,$lab.Path,$lab.SchemaPath,$prompt,$inputPath,$input.spec,$input.complete_input)
 # Vollständige, kanonisch gestagte Modultests mitsamt relativen Hilfen und Fixtures.
 $paths+=@(Get-ChildItem -LiteralPath $input.source_root -Recurse -File|Where-Object {$_.FullName -match '[\\/]Tests[\\/]|[\\/]Contracts[\\/]|[\\/]Fixtures[\\/]|[\\/]Tests[\\/]CI[\\/]'}|Select-Object -ExpandProperty FullName)
 $paths+=@(Get-ChildItem -LiteralPath $InputDirectory -File|Select-Object -ExpandProperty FullName)
 $pins=@($paths|Sort-Object -Unique|ForEach-Object {@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
 $runset=[ordered]@{schemaVersion='1.0';qualificationScope='api-boundaries';productCommit=$input.product_commit;
  package=$input.complete_input;sourceRoot=$input.source_root;inputDirectory=[IO.Path]::GetFullPath($InputDirectory);spec=$input.spec;
  pins=$pins;cases=$cases;sharedBudget=$SharedBudgetFile;changedInputReason=$ChangedInputReason;publicationAuthorized=$false}
 $runsetPath=Join-Path $evidence 'runset.json';Save-ApiJson $runsetPath $runset
}
if($runset.qualificationScope -cne 'api-boundaries' -or $runset.publicationAuthorized -ne $false){throw 'RELEASE_API_SCOPE'}
$runsetHash=(Get-FileHash -LiteralPath $runsetPath -Algorithm SHA256).Hash
if($FreezeOnly){'PASS RELEASE_API_FROZEN; finite inputs, ownership method and shared budget; no SQL connection';return}
$budgetPath=Assert-ReleasePrivatePath $SharedBudgetFile
$budget=Get-Content -LiteralPath $budgetPath -Raw|ConvertFrom-Json -AsHashtable
if($budget.limit -ne 90 -or $budget.seconds -ne 36000){throw 'RELEASE_API_BUDGET_CONTRACT'}
$keys=@($runset.cases.key)
if(@($budget.completed|Select-Object -Unique).Count -ne $budget.completed.Count -or @($budget.completed|Where-Object {$_ -cnotin $keys}).Count){throw 'RELEASE_API_INVALID_HISTORY'}
function Assert-ApiAllowance([int]$Reserve){
 $elapsed=([DateTime]::UtcNow-([DateTime]$budget.startedUtc).ToUniversalTime()).TotalSeconds
 if($elapsed+$Reserve -gt $budget.seconds){throw 'RELEASE_API_WAVE_BUDGET_EXHAUSTED'}
}
for($index=0;$index -lt $runset.cases.Count;$index++){
 $case=$runset.cases[$index]
 if($case.key -cin $budget.completed){continue}
 Assert-ApiAllowance ($case.outerSeconds+90)
 if($budget.attempts -ge $budget.limit){throw 'RELEASE_API_ATTEMPTS_EXHAUSTED'}
 Assert-ReleasePin $runsetPath $runsetHash
 foreach($pin in $runset.pins){Assert-ReleasePin $pin.path $pin.sha256}
 if(Test-Path -LiteralPath (Join-Path $evidence "case-$index.json")){throw 'RELEASE_API_ATTEMPT_EXISTS_NEW_INPUT_RUNSET_REQUIRED'}
 $budget.attempts++;$record=@{key=$case.key;runsetSha256=$runsetHash;result='STARTED'};$budget.history+=@($record);Save-ApiJson $budgetPath $budget
 $workOk=$false;$auditOk=$false
 foreach($audit in @($false,$true)){
  $allowance=if($audit){90}else{$case.outerSeconds}
  Assert-ApiAllowance $allowance
  $start=[Diagnostics.ProcessStartInfo]::new((Get-Command pwsh -ErrorAction Stop).Source)
  $start.UseShellExecute=$false;$start.CreateNoWindow=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
  foreach($arg in @('-NoProfile','-NonInteractive','-File',$driver,'-RunsetPath',$runsetPath,'-CaseIndex',[string]$index)){$start.ArgumentList.Add($arg)}
  if($audit){$start.ArgumentList.Add('-AuditOnly')}
  $child=[Diagnostics.Process]::new();$child.StartInfo=$start
  try{
   [void]$child.Start();$stdout=$child.StandardOutput.ReadToEndAsync();$stderr=$child.StandardError.ReadToEndAsync()
   if(-not $child.WaitForExit(1000*$allowance)){
    $child.Kill($true);$child.WaitForExit();$record.result='CLEANUP_UNKNOWN';Save-ApiJson $budgetPath $budget
    throw 'RELEASE_API_OUTER_WATCHDOG_RECONCILE_REQUIRED'
   }
   $out=$stdout.GetAwaiter().GetResult();$err=$stderr.GetAwaiter().GetResult()
   $label=if($audit){'audit'}else{'run'}
   [IO.File]::WriteAllText((Join-Path $evidence "case-$index-$label.stdout.txt"),$out)
   [IO.File]::WriteAllText((Join-Path $evidence "case-$index-$label.stderr.txt"),$err)
   $ok=$child.ExitCode -eq 0 -and $err.Length -eq 0 -and $out -cmatch '^PASS RELEASE_'
   if($audit){$auditOk=$ok}else{$workOk=$ok}
  }finally{$child.Dispose()}
 }
 $record.result=if($workOk -and $auditOk){'PASS'}elseif($auditOk){'FAILED_CLEANED'}else{'CLEANUP_UNKNOWN'}
 if($workOk -and $auditOk){$budget.completed+=@($case.key)}
 Save-ApiJson $budgetPath $budget
 if(-not ($workOk -and $auditOk)){throw ('RELEASE_API_CASE_STOP_'+$index+'_'+$record.result)}
 Write-Output "PASS RELEASE_API_CASE $index group=$($case.group); independent cleanup and pins"
}
'PASS RELEASE_API_MATRIX 74 target/CL/group cases; no publication'
