# Historische Eingaben bleiben unverändert; eigener SQLCMD-Qualifikationspfad.
$prior=Join-Path $PSScriptRoot 'VisibleSsmsHook.ps1'
if((Get-FileHash $prior).Hash-cne '6CDD4B56AE3712F12E450EED029D1BE821CCD748783E6D98C98635B7EFB6DC1C'){throw 'SQLCMD_SSMS_PRIOR_HOOK_CHANGED'}
. $prior
function Get-SsmsSqlcmdPreflightSql([string]$Witness,[string]$ObservationId){
 if($ObservationId-cnotmatch '^[a-f0-9]{32}$'){throw 'SSMS_PREFLIGHT_OBSERVATION_ID_INVALID'}
 Replace-SsmsHookOnce (Get-SsmsPreflightSql $Witness) ' AS Patch;' (" AS Patch,N'"+$ObservationId+"' AS ObservationId;")
}
$preflight=(Get-Command Invoke-SsmsTargetPreflight).Definition
$preflight=Replace-SsmsHookOnce $preflight '[datetimeoffset]::UtcNow.AddSeconds(600)' '[datetimeoffset]::UtcNow.AddSeconds(1200)'
$preflight=Replace-SsmsHookOnce $preflight "throw 'SSMS_TARGET_PREFLIGHT_NOT_COMPLETED'" "throw 'SSIS_SSMS_TARGET_PREFLIGHT_TIMEOUT'"
$preflight=Replace-SsmsHookOnce $preflight ' $witness=[string](Query-Client' @'
 $readyPath=$JournalPath+'.preflight-ready.json'
 $visualPath=$JournalPath+'.preflight-visual.json'
 foreach($handoffPath in @($readyPath,$visualPath,($JournalPath+'.00-Lab-Login.sql'))){
  if(Test-Path -LiteralPath $handoffPath){throw 'SSMS_PREFLIGHT_HANDOFF_COLLISION'}
 }
 $witness=[string](Query-Client
'@
$preflight=Replace-SsmsHookOnce $preflight ' $sql=Get-SsmsPreflightSql $witness' @'
 $observationId=[guid]::NewGuid().ToString('N')
 $sql=Get-SsmsSqlcmdPreflightSql $witness $observationId
'@
$readyLine=@($preflight.Split("`n")|Where-Object{$_.StartsWith(" Save-ClientPrivate (`$JournalPath+'.preflight-ready.json') ",[StringComparison]::Ordinal)})
if($readyLine.Count-ne 1){throw 'SSMS_PREFLIGHT_READY_ANCHOR'}
$preflight=Replace-SsmsHookOnce $preflight $readyLine[0] ''
$preflight=Replace-SsmsHookOnce $preflight ' while([datetimeoffset]::UtcNow-lt $limit){' @'
 if([datetimeoffset]::UtcNow-ge $limit){throw 'SSIS_SSMS_TARGET_PREFLIGHT_TIMEOUT'}
 $ready=@{
  contract='ssis-ssms-preflight-ready/1';state='SSMS_TARGET_PREFLIGHT'
  ssmsPid=$script:ssmsTargetApp.Id;ssmsStartedUtc=$script:ssmsTargetStarted
  sqlPath=$path;querySha256=(Get-ClientHash $path);visualPath=$visualPath
  displayName='Microsoft SQL Server Management Studio';database='master';databaseNotCreated=$true
  targetDataSource=$builder.DataSource;encrypt='Mandatory';trustServerCertificate=[bool]$builder.TrustServerCertificate
  manualConnectionRequired=$true;connectionArgumentsPassed=$false;expectedPatch='CU8'
  observationId=$observationId;deadlineUtc=$limit.ToString('o')
 }
 $readyTemp=$readyPath+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
 try{
  Save-ClientPrivate $readyTemp $ready
  $readySha256=Get-ClientHash $readyTemp
  [IO.File]::Move($readyTemp,$readyPath)
 }finally{[IO.File]::Delete($readyTemp)}
 while([datetimeoffset]::UtcNow-lt $limit){
'@
$preflight=Replace-SsmsHookOnce $preflight @'
   $v=Get-Content ($JournalPath+'.preflight-visual.json') -Raw|ConvertFrom-Json -DateKind String
   Check ($v.result-ceq 'PASS' -and $v.querySha256-ceq (Get-ClientHash $path) -and $v.targetMatched-is [bool] -and $v.targetMatched -and $v.windowsAuth-is [bool] -and $v.windowsAuth -and $v.encrypted-is [bool] -and $v.encrypted) 'VISIBLE_SSMS_TARGET_PREFLIGHT'
   $journal.preflight=@{targetMatched=$true;windowsAuthentication=$true;encrypted=$true;sameOwnedSsmsInstance=$true};Save
'@ @'
   $v=& (Join-Path $PSScriptRoot 'Write-SsmsPreflightObservation.ps1') -ReadyPath $readyPath -ExpectedReadySha256 $readySha256 -Verify
   Check ($v.result-ceq 'PASS' -and [datetimeoffset]::UtcNow-lt $limit -and -not $script:ssmsTargetApp.HasExited) 'VISIBLE_SSMS_TARGET_PREFLIGHT'
   $journal.preflight=@{targetMatched=$true;windowsAuthentication=$true;encrypted=$true;sameOwnedSsmsInstance=$true;authScheme=$v.authScheme;patch=$v.patch};Save
'@
$preflight=Replace-SsmsHookOnce $preflight '  if($script:ssmsTargetApp.HasExited)' @'
  if(Test-Path ($JournalPath+'.operator-abort.json')){throw 'SSIS_SQLCMD_OPERATOR_ABORT'}
  if($script:ssmsTargetApp.HasExited)
'@
$preflight=$preflight.Replace('$PSScriptRoot',("'"+$PSScriptRoot.Replace("'","''")+"'"))
. ([scriptblock]::Create('function Invoke-SsmsTargetPreflight {'+$preflight+'}'))
$gui=(Get-Command Invoke-ClientGui).Definition
$gui=Replace-SsmsHookOnce $gui "'New-SsmsExecutionEnvelope.ps1'" "'New-SsmsSqlcmdEnvelope.ps1'"
$gui=Replace-SsmsHookOnce $gui ' $clock=[Diagnostics.Stopwatch]::StartNew();$produced=$false;$passed=$false' @'
 $negativePath=$JournalPath+'.07-Sqlcmd-Negative.sql'
 $negative=":ON ERROR EXIT`nUSE ["+$db+"];`n"+$guard+"GO`nTHROW 51001,N'SSIS_SQLCMD_EXPECTED_STOP',1;`nGO`nUPDATE dbo."+$receipt+" SET Phase=99 WHERE Token='"+$token+"';`nSELECT N'SSIS_SQLCMD_UNEXPECTED_CONTINUATION';`nGO`n"
 [IO.File]::WriteAllText($negativePath,$negative,[Text.UTF8Encoding]::new($true))
 $negativeSha256=(Get-FileHash $negativePath).Hash
 Save-ClientPrivate ($JournalPath+'.sqlcmd-ready.json') @{negativePath=$negativePath;negativeSha256=$negativeSha256;sqlcmdModeRequired=$true;expectedError='SSIS_SQLCMD_EXPECTED_STOP';expectedNumber=51001}
 $clock=[Diagnostics.Stopwatch]::StartNew();$produced=$false;$passed=$false;$negativePassed=$false
'@
$gui=Replace-SsmsHookOnce $gui '  $r=Query-Client $connection' @'
  if(Test-Path ($JournalPath+'.operator-abort.json')){throw 'SSIS_SQLCMD_OPERATOR_ABORT'}
  $r=Query-Client $connection
'@
$gui=Replace-SsmsHookOnce $gui '  if($r.Rows[0].Phase-eq 2 -and $app.HasExited' @'
  if(-not $negativePassed -and (Test-Path ($JournalPath+'.sqlcmd-negative.visual.json'))){
   $n=Get-Content ($JournalPath+'.sqlcmd-negative.visual.json') -Raw|ConvertFrom-Json -DateKind String
   Check ($r.Rows[0].Phase-eq 1 -and $n.result-ceq 'PASS' -and $n.sqlcmdMode-is [bool] -and $n.sqlcmdMode -and $n.expectedErrorObserved-is [bool] -and $n.expectedErrorObserved -and $n.unexpectedErrors-eq 0 -and $n.unexpectedContinuationObserved-is [bool] -and -not $n.unexpectedContinuationObserved -and $n.querySha256-ceq $negativeSha256 -and (Get-FileHash $negativePath).Hash-ceq $negativeSha256 -and (Test-Path ($JournalPath+'.08-ExecutedNegative.sql')) -and [IO.File]::ReadAllText($JournalPath+'.08-ExecutedNegative.sql').Replace("`r`n","`n")-ceq $negative) 'SQLCMD_ERROR_STOPS_BEFORE_LATER_SENTINEL'
   $negativePassed=$true
   Save-ClientPrivate ($JournalPath+'.sqlcmd-negative.pass.json') @{result='PASS';receiptPhaseUnchanged=1;expectedError=51001;laterSentinelNotExecuted=$true;executedTextMatched=$true;querySha256=$negativeSha256}
  }
  if($r.Rows[0].Phase-eq 2 -and $app.HasExited
'@
$gui=Replace-SsmsHookOnce $gui "   Check (`$visual.result-ceq 'PASS'" @'
   Check ($negativePassed -and $visual.sqlcmdMode-is [bool] -and $visual.sqlcmdMode) 'SQLCMD_MODE_AND_NEGATIVE_STOP_OBSERVED'
   Check ($visual.result-ceq 'PASS'
'@
. ([scriptblock]::Create('function Invoke-ClientGui {'+$gui+'}'))
