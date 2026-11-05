#Requires -Version 7.5
[CmdletBinding()]
param(
 [ValidateSet('Run','Audit','Describe')][string]$Mode='Describe',
 [string]$PlanPath,[string]$ExpectedPlanSha256,[string]$BudgetPath,
 [string]$ExpectedJournalSha256,[switch]$ValidateOnly
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repoRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$canonical=Join-Path $PSScriptRoot 'run-script-parser-lab.ps1'
if((Get-FileHash $canonical).Hash -cne 'B9E6FD0417B695D163BE2F8E36B14A720AB0EB27C23F099876E0F787AE0305E8'){throw 'PARSER_CURRENT_METHOD_CHANGED'}
$text=[IO.File]::ReadAllText($canonical)
function Replace-CurrentParserOnce([string]$Old,[string]$New){
 if($script:text.Split($Old,[StringSplitOptions]::None).Count -ne 2){throw 'PARSER_CURRENT_COMPOSITION_ANCHOR'}
 $script:text=$script:text.Replace($Old,$New)
}
if($text.Split('$command.CommandTimeout = 90',[StringSplitOptions]::None).Count -ne 3){throw 'PARSER_CURRENT_TIMEOUT_ANCHOR'}
$text=$text.Replace('$command.CommandTimeout = 90','$command.CommandTimeout = Get-CurrentParserTimeout')
Replace-CurrentParserOnce '        $master.Open()' @'
        [void](Get-CurrentParserTimeout)
        $master.Open()
        $script:parserCurrentJournal.baseline=Get-CurrentParserSnapshot $master @($manifest.sqlServerHexLiteral,$manifest.scriptDomSqlServerHexLiteral)
        Save-CurrentParserPrivate $script:parserCurrentJournalPath $script:parserCurrentJournal
'@
Replace-CurrentParserOnce '    } finally {
        if ($callerConnection)' @'
    } finally {
        $script:parserCurrentCleanup=$true
        $script:parserCurrentCleanupEnd=[datetimeoffset]::UtcNow.AddSeconds(120)
        if ($callerConnection)
'@
Replace-CurrentParserOnce "            foreach (`$level in `$levels) {" @'
            foreach ($level in $levels) {
                [void](Get-CurrentParserTimeout)
'@
Replace-CurrentParserOnce "                    Invoke-ParserBatches `$consumer (Read-ParserScript" @'
                    $script:parserCurrentJournal.startedSuites+=@{mode=$mode;level=$level;name=$name}
                    Save-CurrentParserPrivate $script:parserCurrentJournalPath $script:parserCurrentJournal
                    Invoke-ParserBatches $consumer (Read-ParserScript
'@
$parserCurrentSourceDirectory=$PSScriptRoot
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($text,[ref]$null,[ref]$errors)
if($errors.Count){throw 'PARSER_CURRENT_COMPOSED_SYNTAX'}
# Avoid assigning canonical deployment modes to this adapter's validated Mode parameter.
foreach($variable in @($ast.FindAll({param($n)$n -is [Management.Automation.Language.VariableExpressionAst] -and $n.VariablePath.UserPath -cin @('PSScriptRoot','mode')},$true)|Sort-Object {$_.Extent.StartOffset} -Descending)){
 $replacement=if($variable.VariablePath.UserPath -ieq 'mode'){'$parserCurrentDeploymentMode'}else{'$parserCurrentSourceDirectory'}
 $text=$text.Substring(0,$variable.Extent.StartOffset)+$replacement+$text.Substring($variable.Extent.EndOffset)
}
if($Mode -ceq 'Describe'){$text;return}
$planHandle=[IO.File]::Open($PlanPath,'Open','Read','Read')
try{
 if($planHandle.Length -gt 4194304){throw 'PARSER_CURRENT_PLAN_LIMIT'}
 $planBytes=[byte[]]::new([int]$planHandle.Length);$planHandle.ReadExactly($planBytes)
 if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($planBytes)) -cne $ExpectedPlanSha256){throw 'PARSER_CURRENT_PLAN_CHANGED'}
 $plan=[Text.Encoding]::UTF8.GetString($planBytes).TrimStart([char]0xFEFF)|ConvertFrom-Json -AsHashtable -DateKind String
}finally{$planHandle.Dispose()}
if($plan.schema -cne 'parser-current-lab/v1' -or $plan.version -cnotin @('2019','2022','2025') -or $plan.patch -cnotmatch '^CU[0-9]+$'){throw 'PARSER_CURRENT_SELECTED_SCOPE'}
$requiredSources=@('Tests/CI/Invoke-ScriptParserCurrentLab.ps1','Tests/CI/ParserCurrentSnapshot.ps1','Tests/CI/run-script-parser-lab.ps1','Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1',
 'Modules/toolbelt.tsql.script-parser/Artifacts/Toolbelt.Tsql.ScriptParser.trust-manifest.json')
foreach($directory in @('Clr','Source','Deployment','Tests/Runtime','Tests/Framework')){
 $requiredSources+=@(Get-ChildItem (Join-Path $repoRoot ('Modules/toolbelt.tsql.script-parser/'+$directory)) -File -Recurse|
  Where-Object {$_.Extension -cin @('.cs','.csproj','.sql','.ps1') -and $_.FullName -notmatch '[\\/](bin|obj)[\\/]'}|ForEach-Object {[IO.Path]::GetRelativePath($repoRoot,$_.FullName).Replace([char]92,[char]47)})
}
if(@(Compare-Object @($requiredSources|Sort-Object -Unique) @($plan.sourceHashes.Keys|Sort-Object)).Count){throw 'PARSER_CURRENT_SOURCE_CLOSURE'}
$requiredArtifacts=@('Toolbelt.Tsql.ScriptParser.dll','Microsoft.SqlServer.TransactSql.ScriptDom.dll','Deploy.WithAssembly.sql','Toolbelt.Tsql.ScriptParser.trust-manifest.json')
if(@(Compare-Object $requiredArtifacts @($plan.artifactHashes.Keys)).Count){throw 'PARSER_CURRENT_ARTIFACT_CLOSURE'}
if(-not $IsWindows){throw 'PARSER_CURRENT_WINDOWS_HOST_REQUIRED'}
$privateRoot=[IO.Path]::GetFullPath($plan.privateRoot)
if([IO.Path]::GetDirectoryName($privateRoot) -cne [IO.Path]::GetTempPath().TrimEnd([char[]]@([char]92,[char]47)) -or
   [IO.Path]::GetFileName($privateRoot) -cnotmatch '^ToolbeltParserCurrent_[a-f0-9]{32}$' -or
   ((Get-Item $privateRoot -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'PARSER_CURRENT_PRIVATE_ROOT'}
$script:parserCurrentJournalPath=Join-Path $privateRoot 'run.private.json'
$ledgerRoot=Join-Path $privateRoot 'canonical'
$leases=[Collections.Generic.List[IDisposable]]::new()
try{
 if([IO.Path]::GetFullPath($BudgetPath) -cne (Join-Path $privateRoot 'budget.private.json')){throw 'PARSER_CURRENT_BUDGET_PATH'}
 $leases.Add([IO.File]::Open(($BudgetPath+'.lock'),'OpenOrCreate','ReadWrite','None'))
 foreach($pair in $plan.sourceHashes.GetEnumerator()){
  $path=[IO.Path]::GetFullPath((Join-Path $repoRoot $pair.Key))
  if(-not $path.StartsWith($repoRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'PARSER_CURRENT_SOURCE_PATH'}
  $lease=[IO.File]::Open($path,'Open','Read','Read');$leases.Add($lease)
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($lease)) -cne $pair.Value){throw 'PARSER_CURRENT_SOURCE_CHANGED'}
 }
 foreach($pair in $plan.artifactHashes.GetEnumerator()){
  $path=Join-Path $plan.releaseDirectory $pair.Key
  $lease=[IO.File]::Open($path,'Open','Read','Read');$leases.Add($lease)
  if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($lease)) -cne $pair.Value){throw 'PARSER_CURRENT_ARTIFACT_CHANGED'}
 }
 . (Join-Path $PSScriptRoot 'ParserCurrentSnapshot.ps1')
 $contractLease=[IO.File]::Open($plan.contractPath,'Open','Read','Read');$leases.Add($contractLease)
 if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($contractLease)) -cne $plan.contractSha256){throw 'PARSER_CURRENT_LAB_CHANGED'}
 # Load only the canonical discovery definitions, before its framework/native body.
 $prefix=$text.Substring(0,$text.IndexOf('function Invoke-ParserSql',[StringComparison]::Ordinal))
 . ([scriptblock]::Create($prefix)) -Version $plan.version -Patch $plan.patch -ReleaseDirectory $plan.releaseDirectory -PrivateJournalDirectory $ledgerRoot
 $lab=Resolve-LabContract
 if([IO.Path]::GetFullPath($lab.Path) -cne [IO.Path]::GetFullPath($plan.contractPath)){throw 'PARSER_CURRENT_LAB_PATH_CHANGED'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform='windows';Version=$plan.version;Patch=$plan.patch}))
 if($targets.Count -ne 1 -or $targets[0].key -cne $plan.targetKey){throw 'PARSER_CURRENT_TARGET_CHANGED'}
 $budget=Get-Content $BudgetPath -Raw|ConvertFrom-Json -AsHashtable -DateKind String
 if($budget.scope -cne 'parser-current-qualification' -or $budget.version -cne $plan.version -or $budget.patch -cne $plan.patch -or
    $budget.waveId -cne [IO.Path]::GetFileName($privateRoot).Substring('ToolbeltParserCurrent_'.Length) -or
    $budget.maximumNative -ne 2 -or $budget.maximumDatabases -ne 3 -or
    [datetimeoffset]::UtcNow -ge [datetimeoffset]::Parse($budget.ceilingUtc)){throw 'PARSER_CURRENT_BUDGET'}
 $script:parserCurrentCleanup=$false
 $script:parserCurrentRunEnd=[datetimeoffset]::UtcNow.AddMinutes($(if($Mode -ceq 'Run'){25}else{5}))
 if($script:parserCurrentRunEnd -gt [datetimeoffset]::Parse($budget.ceilingUtc)){throw 'PARSER_CURRENT_REMAINING_WINDOW'}
 if($Mode -ceq 'Run'){
  if($budget.nativeUsed -ne 0 -or (Test-Path $script:parserCurrentJournalPath)){throw 'PARSER_CURRENT_RUN_ALREADY_RESERVED'}
  if($ValidateOnly){'PARSER_CURRENT_INPUTS_PASS; no SQL, credentials or GUI';return}
  $budget.nativeUsed=1;Save-CurrentParserPrivate $BudgetPath $budget
  $script:parserCurrentJournal=@{state='ACTIVE';planSha256=$ExpectedPlanSha256;startedSuites=@();baseline=$null}
  Save-CurrentParserPrivate $script:parserCurrentJournalPath $script:parserCurrentJournal
  $failure=$null
  try{
   $result=[Collections.Generic.List[object]]::new()
   . ([scriptblock]::Create($text)) -Version $plan.version -Patch $plan.patch -ReleaseDirectory $plan.releaseDirectory -OptInExactTrust -PrivateJournalDirectory $ledgerRoot|ForEach-Object {
    if($_ -is [pscustomobject] -and $_.PSObject.Properties['Status']){$result.Add($_)}
    if($_ -is [string] -and $_.StartsWith('{',[StringComparison]::Ordinal)){
     $receipt=$_|ConvertFrom-Json -AsHashtable -DateKind String
     if($receipt.ContainsKey('qualificationProfile') -and $receipt.qualificationProfile -ceq 'Full'){
      Save-CurrentParserPrivate ($script:parserCurrentJournalPath+'.framework.json') $receipt
     }
    }
   }
   if($result.Count -ne 1 -or $result[0].Status -cne 'PASS' -or $result[0].TrustCleanup -cne 'PASS' -or $result[0].DatabaseCleanup -cne 'PASS'){throw 'PARSER_CURRENT_NATIVE_RESULT'}
   $ledgers=@(Get-ChildItem $ledgerRoot -File -Filter '*.json')
   if($ledgers.Count -ne 1){throw 'PARSER_CURRENT_LEDGER_COUNT'}
   $ledger=Get-Content $ledgers[0].FullName -Raw|ConvertFrom-Json -DateKind String
   Assert-CurrentParserLedger $ledger
   $script:parserCurrentJournal.state='PASS_CLEANED'
  }catch{$failure=$_;$script:parserCurrentJournal.state='FAILED_REQUIRES_AUDIT';$script:parserCurrentJournal.failureCode='PARSER_CURRENT_NATIVE_FAILED'}
  finally{
   if(Test-Path $ledgerRoot){
    $finalLedgers=@(Get-ChildItem $ledgerRoot -File -Filter '*.json')
    if($finalLedgers.Count -eq 1){
     $script:parserCurrentJournal.ledgerPath=$finalLedgers[0].FullName
     $script:parserCurrentJournal.ledgerSha256=(Get-FileHash $finalLedgers[0].FullName).Hash
    }
   }
   Save-CurrentParserPrivate $script:parserCurrentJournalPath $script:parserCurrentJournal
  }
  if($failure){throw $failure}
   'PARSER_CURRENT_NATIVE_PASS; selected Windows local/central; limited declared suites'
 }else{
  if($budget.nativeUsed -ne 1 -or (Get-FileHash $script:parserCurrentJournalPath).Hash -cne $ExpectedJournalSha256){throw 'PARSER_CURRENT_AUDIT_BINDING'}
  $budget.nativeUsed=2;Save-CurrentParserPrivate $BudgetPath $budget
  $journal=Get-Content $script:parserCurrentJournalPath -Raw|ConvertFrom-Json -AsHashtable -DateKind String
  if($null -eq $journal.baseline){throw 'PARSER_CURRENT_BASELINE_MISSING'}
  if($journal.ContainsKey('ledgerPath')){
   if([IO.Path]::GetDirectoryName($journal.ledgerPath) -cne $ledgerRoot -or (Get-FileHash $journal.ledgerPath).Hash -cne $journal.ledgerSha256){throw 'PARSER_CURRENT_LEDGER_CHANGED'}
   Assert-CurrentParserLedger (Get-Content $journal.ledgerPath -Raw|ConvertFrom-Json -DateKind String)
  }elseif(Test-Path $ledgerRoot){throw 'PARSER_CURRENT_LEDGER_UNCERTAIN'}
  $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $targets[0]));$builder['Initial Catalog']='master';$builder['Pooling']=$false
  $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
  try{
   $connection.Open();$manifest=Get-Content (Join-Path $plan.releaseDirectory 'Toolbelt.Tsql.ScriptParser.trust-manifest.json') -Raw|ConvertFrom-Json
   $now=Get-CurrentParserSnapshot $connection @($manifest.sqlServerHexLiteral,$manifest.scriptDomSqlServerHexLiteral)
   foreach($key in @('identity','configuration','trust','databases','consumers')){if($now[$key] -cne $journal.baseline[$key]){throw 'PARSER_CURRENT_FRESH_AUDIT_DRIFT'}}
   Save-CurrentParserPrivate ($script:parserCurrentJournalPath+'.audit.json') @{result='PASS';journalSha256=$ExpectedJournalSha256;configurationRestored=$true;trustRestored=$true;databasesRestored=$true;consumersUnchanged=$true}
   'PARSER_CURRENT_INDEPENDENT_AUDIT_PASS'
  }finally{$connection.Dispose()}
 }
}finally{foreach($lease in $leases){$lease.Dispose()}}
