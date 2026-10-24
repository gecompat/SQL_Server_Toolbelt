# API-/Grenzqualifikation des unveränderten vollständigen Releasepakets.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,[Parameter(Mandatory)][ValidateRange(0,999)][int]$CaseIndex,[switch]$AuditOnly,[switch]$PreflightOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew(); $cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$casePins=$null
# Nur die geprüften Funktionsdefinitionen importieren; kein fremder Teststart.
function Import-ClrFunctions([string]$Path,[string[]]$Names,[hashtable]$Replace=@{}) {
 $errors=$null; $ast=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$null,[ref]$errors)
 if($errors.Count){throw 'RELEASE_HELPER_PARSE'}
 foreach($name in $Names){
  $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
  if($nodes.Count -ne 1){throw 'RELEASE_HELPER_AMBIGUOUS'}
  $text=$nodes[0].Extent.Text
  foreach($key in $Replace.Keys){$text=$text.Replace($key,$Replace[$key])}
  # Definitionen in den Aufruferscope zurückgeben, ohne sie auszuführen.
  [scriptblock]::Create($text)
 }
}
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Invoke-ReleaseSql','Open-ReleaseConnection',
 'Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseOwnIdentity','Invoke-ReleaseSmoke')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1') @('Get-CsvTrust','Assert-CsvTrustCleanupScope') @{
 'Get-CsvTrust'='Get-ClrTrust';'Assert-CsvTrustCleanupScope'='Assert-ClrTrustCleanupScope';
 'Invoke-CsvOwnSql'='Invoke-ReleaseSql';'Invoke-CsvSql'='Invoke-ReleaseSql'}){. $block}

function Assert-ClrInstalled($Connection,[string]$Profile) {
 $expected=@($script:metadata.profiles.$Profile)
 $rows=@(Invoke-ReleaseSql $Connection "SELECT name,CONVERT(nvarchar(128),value) value FROM sys.extended_properties WITH (NOLOCK) WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
 if($rows.Count -ne @($script:metadata.complete_profiles.$Profile).Count){throw 'RELEASE_CLR_MODULE_COUNT'}
 foreach($mid in @($script:metadata.complete_profiles.$Profile)){
  if(@($rows|Where-Object {$_.name -ceq ('Toolbelt.Module.'+$mid+'.Version') -and $_.value -ceq $script:metadata.versions.$mid}).Count -ne 1){throw 'RELEASE_CLR_MODULE_MARKER'}
 }
 $assemblies=@(Invoke-ReleaseSql $Connection "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash FROM sys.assemblies a WITH (NOLOCK) JOIN sys.assembly_files f WITH (NOLOCK) ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1 ORDER BY a.name;" -Rows)
 $wanted=@($script:metadata.artifacts|Where-Object {$_.module_id -in $expected -or ($Profile.StartsWith('Windows-') -and -not $_.module_id)})
 if($assemblies.Count -ne $wanted.Count){throw 'RELEASE_CLR_ASSEMBLY_COUNT'}
 foreach($a in $wanted){if(@($assemblies|Where-Object {$_.name -ceq $a.sql_name -and $_.Hash -ceq $a.sha512.ToUpperInvariant()}).Count -ne 1){throw 'RELEASE_CLR_ASSEMBLY_HASH'}}
 $definitions=@(Invoke-ReleaseSql $Connection "SELECT s.name SchemaName,o.name ObjectName,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash FROM sys.objects o WITH (NOLOCK) JOIN sys.schemas s WITH (NOLOCK) ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m WITH (NOLOCK) ON m.object_id=o.object_id WHERE o.is_ms_shipped=0 AND s.name LIKE N'toolbelt[_]%' ORDER BY s.name,o.name;" -Rows)
 return (@{assemblies=$assemblies;definitions=$definitions}|ConvertTo-Json -Depth 5 -Compress)
}
function Assert-ReleaseInputs([switch]$All) {
 $pins=if($All -or $null -eq $script:casePins){$script:runset.pins}else{$script:casePins}
 foreach($pin in $pins){Assert-ReleasePin $pin.path $pin.sha256}
}
function Get-ApiCasePins($Runset,$Case) {
 $spec=Get-Content -LiteralPath $Runset.spec -Raw|ConvertFrom-Json
 $tests=@($spec.tests|Where-Object group -ceq $Case.group)
 if(-not $tests.Count){throw 'RELEASE_API_EMPTY_PIN_SCOPE'}
 $modules=@($tests.module_id|Select-Object -Unique)
 $prefix=$Runset.sourceRoot.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
 foreach($pin in $Runset.pins){
  if(-not $pin.path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){$pin;continue}
  $relative=[IO.Path]::GetRelativePath($Runset.sourceRoot,$pin.path).Replace('\','/')
  if($relative.StartsWith('Tests/CI/') -or $relative -cin @($tests.source)){$pin;continue}
  foreach($mid in $modules){if($relative.StartsWith('Modules/'+$mid+'/')){$pin;break}}
 }
}
function Get-ReleaseTimeout {
 $limit=if($script:cleanup){$script:case.cleanupSeconds}else{$script:case.workSeconds}
 $remaining=1000*$limit-$script:clock.ElapsedMilliseconds
 if($remaining -lt 1000){throw 'RELEASE_API_DEADLINE'}
 $commandCap=if($script:case.group -ceq 'formats' -and -not $script:cleanup){1200}else{300}
 return [int][Math]::Min($commandCap,[Math]::Floor($remaining/1000))
}
function Test-ApiSelected($Test) {
 if($Test.group -cne $script:case.group){return $false}
 if($Test.PSObject.Properties['only_additional_cl'] -and $Test.only_additional_cl){
  return (($script:case.Version -ceq '2022' -and $script:case.CL -eq 150) -or
          ($script:case.Version -ceq '2025' -and $script:case.CL -lt 170))
 }
 if($Test.PSObject.Properties['only_missing_boundary_targets'] -and $Test.only_missing_boundary_targets){
  return -not (($script:case.Platform -ceq 'linux' -and $script:case.Version -ceq '2019') -or
   ($script:case.Platform -ceq 'windows' -and $script:case.Version -ceq '2025' -and $script:case.CL -eq 170))
 }
 return $true
}
function Assert-ApiProduct($Connection,[string]$Profile,[string]$Original) {
 $now=(Assert-ClrInstalled $Connection $Profile)|ConvertFrom-Json
 $before=$Original|ConvertFrom-Json
 if(($now.assemblies|ConvertTo-Json -Depth 5 -Compress) -cne ($before.assemblies|ConvertTo-Json -Depth 5 -Compress)){throw 'RELEASE_API_ASSEMBLY_DRIFT'}
 foreach($old in $before.definitions){
  $matches=@($now.definitions|Where-Object {$_.SchemaName -ceq $old.SchemaName -and $_.ObjectName -ceq $old.ObjectName})
  if($matches.Count -ne 1 -or ($matches[0]|ConvertTo-Json -Compress) -cne ($old|ConvertTo-Json -Compress)){throw 'RELEASE_API_PRODUCT_DRIFT'}
 }
 # Leserechte/Produktidentität werden nicht aus unmarkierten Testhilfsobjekten abgeleitet.
}
function Invoke-ApiEnvironment([string]$Path,[string]$Database,[string]$ToolbeltDatabase) {
 $keys=@('TBX_SQL_HOST','TBX_SQL_PORT','TBX_SQL_USER','TBX_SQL_PASSWORD','TBX_SQL_TARGET','TBX_SQL_TEST_PURPOSE','TBX_SQL_ENCRYPT','TBX_SQL_TRUST_SERVER_CERTIFICATE')
 $previous=@{};foreach($key in $keys){$previous[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $script:target -TestPurpose Functional))
 try{
  if($builder.IntegratedSecurity -or $builder.DataSource -cnotmatch '^tcp:(.+),(\d+)$'){throw 'RELEASE_API_EXPLICIT_SQL_IDENTITY_REQUIRED'}
  $hostValue=$Matches[1];$portValue=$Matches[2]
  $values=@($hostValue,$portValue,$builder.UserID,$builder.Password,'lab','Functional','True',$builder.TrustServerCertificate.ToString())
  for($i=0;$i -lt $keys.Count;$i++){[Environment]::SetEnvironmentVariable($keys[$i],$values[$i],'Process')}
  $arguments=@{Database=$Database}
  if($Path.EndsWith('Relations.Metadata.ps1')){$arguments.ToolbeltDatabase=$ToolbeltDatabase}
  & $Path @arguments | Out-Null
 }finally{
  $builder.Clear();foreach($key in $keys){[Environment]::SetEnvironmentVariable($key,$previous[$key],'Process')}
 }
}
function New-ApiBudgetProviders($Clock,[int]$WorkSeconds) {
 $sourceWatch=$Clock;$workBudget=$WorkSeconds
 $timeoutProvider={
  $left=1000*$workBudget-$sourceWatch.ElapsedMilliseconds
  if($left -lt 1000){throw 'RELEASE_API_DEADLINE'}
  [int][Math]::Min(120,[Math]::Floor($left/1000))
 }.GetNewClosure()
 $readProvider={[void](& $timeoutProvider)}.GetNewClosure()
 return @{Timeout=$timeoutProvider;Read=$readProvider}
}
function Add-ApiCaptureFailureContext([string]$Text) {
 # Nur die Testfixture annotieren, nicht Produkt-SQL oder deren Orakel ändern.
 # Bei Erfolg gibt es keine Zusatznachricht und keinen Timer im Fachaufruf.
 $markers=[ordered]@{
  '-- Binärvergleich erhält Case, Surrogate, NULL und nachgestellte Leerzeichen.'='row-oracle'
  'DECLARE @Replace table'='replace'
  'IF [$(ToolbeltDatabase)].toolbelt_string.SVF_RegexReplace('='defaults'
  'DECLARE @Errors table'='negative'
 }
 if($Text.Contains('@ApiCapturePhase')){throw 'RELEASE_API_CAPTURE_ALREADY_ANNOTATED'}
 foreach($marker in $markers.Keys){
  if(([regex]::Matches($Text,[regex]::Escape($marker))).Count -ne 1){throw 'RELEASE_API_CAPTURE_FIXTURE_DRIFT'}
  $Text=$Text.Replace($marker,"SET @ApiCapturePhase=N'"+$markers[$marker]+"';`n"+$marker)
 }
 return "DECLARE @ApiCapturePhase nvarchar(20)=N'rows';`nBEGIN TRY`n"+$Text+@'

END TRY
BEGIN CATCH
 RAISERROR(N'TBX_REGEX_CAPTURE_CASE|%s|%d',10,1,@ApiCapturePhase,@Case) WITH NOWAIT;
 THROW;
END CATCH;
'@
}
function New-ApiCaptureDiagnostic {
 $state=@{Marker=''}
 $action={param($sender,$eventArgs)
  foreach($item in $eventArgs.Errors){
   if($item.Message -cmatch '^TBX_REGEX_CAPTURE_CASE\|(rows|row-oracle|replace|defaults|negative)\|[0-9]+$'){
    $state.Marker=$item.Message
   }
  }
 }.GetNewClosure()
 return @{State=$state;Action=$action;Handler=[Data.SqlClient.SqlInfoMessageEventHandler]$action}
}
function Invoke-ApiFixture($Test,[string]$Database,[string]$Central='') {
 $path=Join-Path $script:runset.sourceRoot $Test.source
 if($Test.kind -ceq 'ssis-core'){
  if(-not $script:runset.PSObject.Properties['ssisFunctionalRoot']){throw 'RELEASE_API_SSIS_FUNCTIONAL_FIXTURE_REQUIRED'}
  $path=Join-Path $script:runset.ssisFunctionalRoot 'Tests/Runtime/Invoke-CoreContract.ps1'
 }
 $script:activeFixtureCase=''
 $captureDiagnostic=$null
 $db=Open-ReleaseConnection $Database
 try{
  [void](Get-ReleaseTimeout)
  if($Test.kind -ceq 'sql'){
   $text=[IO.File]::ReadAllText($path)
   if($Test.id -ceq 'toolbelt.string.regex:Captures.Contract.sql'){
    $text=Add-ApiCaptureFailureContext $text
    $captureDiagnostic=New-ApiCaptureDiagnostic
    $db.add_InfoMessage($captureDiagnostic.Handler)
   }
   $toolbelt=if($Central){$Central}else{$Database}
   foreach($pair in @(@('ToolbeltDatabase',$toolbelt),@('CentralDb',$toolbelt),@('CompatibilityLevel',[string]$script:case.CL))){$text=$text.Replace('$('+$pair[0]+')',$pair[1])}
   foreach($pair in @(@('XlsxFixture','standard'),@('XlsxRepeatedFixture','repeated'))){
    if($text.Contains('$('+$pair[0]+')')){$text=$text.Replace('$('+$pair[0]+')','0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes((Join-Path $script:runset.inputDirectory ('fixture-'+$pair[1]+'.xlsx')))))}
   }
   if($Test.id -cin @('toolbelt.file.csv-memory:DirectSelectCeilings.Tests.sql','toolbelt.file.csv-memory:DirectSelectUnicodeNull.Tests.sql')){
    $helper=Join-Path $script:runset.sourceRoot 'Modules/toolbelt.file.csv-memory/Tests/Framework/CsvDirectSelect.Helpers.ps1'
    foreach($block in Import-ClrFunctions $helper @('Get-CsvDirectSelectCase','Assert-CsvDirectSelectRows','Invoke-CsvDirectSelectPhase') @{
      'Get-CsvCommandTimeout -Maximum 300'='Get-ReleaseTimeout';'Assert-CsvReadBudget $command'='[void](Get-ReleaseTimeout)'}){. $block}
    $scope=if($Test.id.EndsWith('DirectSelectCeilings.Tests.sql')){'select-output-ceilings'}else{'select-unicode-null'}
    $batches=@([regex]::Split($text,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')|Where-Object {-not [string]::IsNullOrWhiteSpace($_)})
    if($batches.Count -ne 8){throw 'RELEASE_API_CSV_DIRECT_PHASES'}
    for($phase=0;$phase -lt 8;$phase++){
     $passed=Invoke-CsvDirectSelectPhase $db $batches[$phase] $phase -Scope $scope
     if($passed -isnot [int] -or $passed -ne 1){throw 'RELEASE_API_CSV_DIRECT_ORACLE'}
    }
   }elseif($script:case.group -ceq 'translate-large'){
    $batchIndex=0
    foreach($batch in [regex]::Split($text,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
     if(-not [string]::IsNullOrWhiteSpace($batch)){
      $script:ledger['activeBatch']=$batchIndex;Save-ReleaseJournal
      Invoke-ReleaseSql $db $batch;$batchIndex++
     }
    }
    $script:ledger['completedLargeBatches']=$batchIndex;Save-ReleaseJournal
   }else{Invoke-ReleaseBatches $db $text}
  }else{
   $arguments=@{Connection=$db}
   # Delegierte Scriptblöcke behalten nur ihre gebundenen Werte. $script:
   # würde im ScriptScope des Metadatenhelfers statt im Adapter gesucht.
   $providers=New-ApiBudgetProviders $script:clock ([int]$script:case.workSeconds)
   $timeoutProvider=$providers.Timeout;$readProvider=$providers.Read
   switch -CaseSensitive ($Test.kind){
    'environment-script' {Invoke-ApiEnvironment $path $Database $(if($Central){$Central}else{$Database});break}
    'xlsx-metadata' {
     . $path
     $args2=@{Connection=$db;Fixture=[IO.File]::ReadAllBytes((Join-Path $script:runset.inputDirectory 'fixture-standard.xlsx'))}
     if($Central){$args2.ToolbeltDatabase=$Central}
     Test-XlsxMetadata @args2 | Out-Null;break
    }
    'connection-script' {
     if(-not $path.EndsWith('Metadata.Tests.ps1')){$arguments.CommandTimeoutProvider=$timeoutProvider;$arguments.ReadBudgetProvider=$readProvider;if($Central){$arguments.ToolbeltDatabase=$Central}}
     & $path @arguments | Out-Null;break
    }
    'composition-script' {$arguments.ToolbeltDatabase=$(if($Central){$Central}else{$Database});$arguments.CommandTimeoutProvider=$timeoutProvider;$arguments.ReadBudgetProvider=$readProvider;& $path @arguments | Out-Null;break}
    'captures-metadata' {$arguments.Database=$Database;$arguments.ToolbeltDatabase=$(if($Central){$Central}else{$Database});$arguments.IncludeLargeBoundary=$true;& $path @arguments | Out-Null;break}
    'ssis-core' {$arguments.Full=$true;if($script:mode -ceq 'central'){$arguments.CrossDatabase=$script:names.consumer};& $path @arguments | Out-Null;break}
    'ssis-api' {& $path @arguments | Out-Null;break}
    default {throw 'RELEASE_API_UNKNOWN_ADAPTER'}
   }
  }
  Invoke-ReleaseSql $db "IF @@TRANCOUNT<>0 THROW 51594,N'API fixture left a transaction.',1;"
  [void](Get-ReleaseTimeout)
 }finally{
  if($captureDiagnostic){
   $db.remove_InfoMessage($captureDiagnostic.Handler)
   $script:activeFixtureCase=$captureDiagnostic.State.Marker
   if($script:activeFixtureCase){$script:ledger['privateFixtureCase']=$script:activeFixtureCase;Save-ReleaseJournal}
  }
  $db.Dispose()
 }
 $script:ledger.completedFixtures+=@([ordered]@{id=$Test.id;context=$(if($Central){'consumer'}else{$script:mode});result='PASS'})
 Save-ReleaseJournal
}

function Get-ApiSqlFailure($ErrorRecord) {
 $errorDetail=$ErrorRecord.Exception;$found=$null
 while($true){if($errorDetail -is [Data.SqlClient.SqlException]){$found=$errorDetail};if(-not $errorDetail.InnerException){break};$errorDetail=$errorDetail.InnerException}
 return $found
}
function Get-ApiFixtureBinding($Test) {
 $record=[ordered]@{}
 foreach($name in @($Test.PSObject.Properties.Name|Sort-Object -CaseSensitive)){$record[$name]=$Test.$name}
 return ($record|ConvertTo-Json -Depth 8 -Compress)
}
function Read-ApiCarry($Control) {
 $script:carried=@();$script:carriedBlocked=@()
 if(-not $script:runset.PSObject.Properties['carryForward']){return}
 foreach($item in @($script:runset.carryForward|Where-Object key -ceq $script:case.key)){
  $old=Get-Content -LiteralPath $item.journal -Raw|ConvertFrom-Json
  $prior=Get-Content -LiteralPath $item.runset -Raw|ConvertFrom-Json
  $oldCase=$prior.cases[$item.index]
  $regexBlock=$oldCase.group -ceq 'text' -and $old.failure.sqlNumber -eq 6522 -and $old.privateDiagnostic -cmatch 'TBX_REGEX_TIMEOUT'
  $formatDeadline=$oldCase.group -ceq 'formats' -and $old.failure.sqlNumber -eq -2 -and $script:case.workSeconds -gt $oldCase.workSeconds
  $callbackScope=$oldCase.group -ceq 'formats' -and $old.failure.sqlNumber -eq 0 -and $old.privateDiagnostic.Contains('$script:cleanup')
  $csvClientAdapter=$oldCase.group -ceq 'csv' -and $old.failure.sqlNumber -eq 55303 -and $old.failure.stage -ceq 'local:toolbelt.file.csv-memory:DirectSelectCeilings.Tests.sql'
  $csvDeadline=$oldCase.group -ceq 'csv' -and $old.failure.sqlNumber -eq -2 -and $script:case.workSeconds -gt $oldCase.workSeconds -and $old.failure.stage -ceq 'central:toolbelt.file.csv-memory:QuotedTempNamePreservation.Tests.sql'
  if($old.state -cne 'FAILED_CLEANED' -or $old.targetIdentity -cne $script:targetIdentity -or $oldCase.key -cne $script:case.key -or -not ($regexBlock -or $formatDeadline -or $callbackScope -or $csvClientAdapter -or $csvDeadline)){
   throw 'RELEASE_API_CARRY_SCOPE'
  }
  $oldPin=@($prior.pins|Where-Object path -ceq $prior.package)
  $newPin=@($script:runset.pins|Where-Object path -ceq $script:runset.package)
  if($oldPin.Count -ne 1 -or $newPin.Count -ne 1 -or $oldPin[0].sha256 -cne $newPin[0].sha256){throw 'RELEASE_API_CARRY_PRODUCT_DRIFT'}
  if([IO.File]::ReadAllText($item.audit) -cnotmatch '^PASS RELEASE_CLR_INDEPENDENT_CLEANUP_AND_PINS'){throw 'RELEASE_API_CARRY_AUDIT'}
  foreach($entry in $old.databases){
   $rows=@(Invoke-ReleaseSql $Control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($entry.state -cne 'DROPPED' -or $rows[0].Id -isnot [DBNull]){throw 'RELEASE_API_CARRY_DB_PRESENT'}
  }
  foreach($entry in $old.trust){
   $now=Get-ClrTrust $Control ([Convert]::FromHexString($entry.hash))
   if(($entry.preexisting -and ($null -eq $now -or $now.Fingerprint -cne $entry.fingerprint)) -or (-not $entry.preexisting -and $null -ne $now)){throw 'RELEASE_API_CARRY_TRUST_DRIFT'}
  }
  $spec=Get-Content -LiteralPath $script:runset.spec -Raw|ConvertFrom-Json
  $priorSpec=Get-Content -LiteralPath $prior.spec -Raw|ConvertFrom-Json
  $failureContext=if($csvDeadline){'central'}else{'local'}
  $blockedId=$old.failure.stage.Substring(($failureContext+':').Length)
  $expectedId=if($regexBlock){'toolbelt.string.regex:Transformations.Contract.sql'}elseif($callbackScope){'toolbelt.file.xlsx-memory:Types.Metadata.ps1'}elseif($csvClientAdapter){'toolbelt.file.csv-memory:DirectSelectCeilings.Tests.sql'}elseif($csvDeadline){'toolbelt.file.csv-memory:QuotedTempNamePreservation.Tests.sql'}else{'toolbelt.json.constructors:JsonGroups.Boundaries.sql'}
  if($old.failure.stage -cne ($failureContext+':'+ $blockedId) -or $blockedId -cne $expectedId){throw 'RELEASE_API_CARRY_ERROR_SCOPE'}
  $priorPass=@($old.completedFixtures)+@($old.reusedFixtures)
  $records=$priorPass+@([pscustomobject]@{id=$blockedId;context=$failureContext})
  foreach($record in $records){
   if($record.context -cnotin $(if($csvDeadline){@('local','central')}else{@('local')})){throw 'RELEASE_API_CARRY_CONTEXT'}
   $currentTest=@($spec.tests|Where-Object id -ceq $record.id);$oldTest=@($priorSpec.tests|Where-Object id -ceq $record.id)
   if($currentTest.Count -ne 1 -or $oldTest.Count -ne 1 -or (Get-ApiFixtureBinding $currentTest[0]) -cne (Get-ApiFixtureBinding $oldTest[0])){throw 'RELEASE_API_CARRY_FIXTURE_SCOPE'}
   $source=Join-Path $prior.sourceRoot $oldTest[0].source
   $pin=@($prior.pins|Where-Object path -ceq $source)
   if($pin.Count -ne 1){throw 'RELEASE_API_CARRY_FIXTURE_PIN'}
   Assert-ReleasePin (Join-Path $script:runset.sourceRoot $currentTest[0].source) $pin[0].sha256
  }
  $script:carried=$priorPass
  if($regexBlock){$script:carriedBlocked=@([ordered]@{id=$blockedId;context='local';reason='TBX_REGEX_TIMEOUT';source='previous_failed_cleaned_attempt'})}
 }
}
function Invoke-ApiChecked($Test,[string]$Database,[string]$Central,[string]$Profile,[string]$Original) {
 $context=if($Central){'consumer'}else{$script:mode}
 if(@($script:carried|Where-Object {$_.id -ceq $Test.id -and $_.context -ceq $context}).Count){
  $script:ledger.reusedFixtures+=@([ordered]@{id=$Test.id;context=$context;result='PASS_PREVIOUS_AUDITED_INPUTS'});Save-ReleaseJournal;return
 }
 if(@($script:carriedBlocked|Where-Object {$_.id -ceq $Test.id -and $_.context -ceq $context}).Count){
  $script:ledger.blockedFixtures+=@([ordered]@{id=$Test.id;context=$context;reason='TBX_REGEX_TIMEOUT';source='previous_failed_cleaned_attempt'});Save-ReleaseJournal;return
 }
 try{Invoke-ApiFixture $Test $Database $Central}catch{
  $sql=Get-ApiSqlFailure $_
  if($Test.module_id -cne 'toolbelt.string.regex' -or $null -eq $sql -or $sql.Number -ne 6522 -or $sql.Message -cnotmatch 'TBX_REGEX_TIMEOUT'){throw}
  # Ein tatsächlich aufgetretener Budgetfehler bleibt ein offener positiver
  # Grenznachweis. Keine Friständerung, kein PASS und kein unveränderter Retry.
  $verify=Open-ReleaseConnection $Database
  try{Invoke-ReleaseSql $verify "IF @@TRANCOUNT<>0 THROW 51594,N'Blocked fixture left a transaction.',1;";if(-not $Central){Assert-ApiProduct $verify $Profile $Original}}finally{$verify.Dispose()}
  # Rohdiagnose ausschließlich im bereits privat geschützten Casejournal.
  # Der bisher verlorene CLR-Stack/Fehlertext und der synthetische Unterfall
  # bleiben erhalten; ein Timeout bleibt unverändert PARTIAL statt PASS.
  $script:ledger.blockedFixtures+=@([ordered]@{id=$Test.id;context=$context;reason='TBX_REGEX_TIMEOUT';source='current_attempt';privateDiagnostic=$sql.Message;privateFixtureCase=$script:activeFixtureCase});Save-ReleaseJournal
 }
}

$control=$null;$ledger=$null;$journal=$null;$failure=$null;$stage='PREPARE'
try {
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
 if($runset.qualificationScope -cne 'api-boundaries'){throw 'RELEASE_COMPLETE_SCOPE'}
 if($CaseIndex -ge $runset.cases.Count){throw 'RELEASE_API_RUNSET'}
 $case=$runset.cases[$CaseIndex]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 Assert-ReleaseInputs -All
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $casePins=@(Get-ApiCasePins $runset $case)
 $lab=Resolve-LabContract -TestPurpose Functional
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count -ne 1){throw 'RELEASE_CLR_TARGET_AMBIGUOUS'}
 $target=$targets[0]
 $targetIdentity=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$target.key)))
 $control=Open-ReleaseConnection 'master'
 if($AuditOnly){
  $ledger=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json
  if($ledger.targetIdentity -cne $targetIdentity -or $ledger.state -cnotin @('COMPLETE','PARTIAL','FAILED_CLEANED')){throw 'RELEASE_CLR_AUDIT_STATE'}
  foreach($entry in $ledger.databases){
   $r=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($entry.state -cne 'DROPPED' -or $r.Count -ne 1 -or $r[0].Id -isnot [DBNull]){throw 'RELEASE_CLR_AUDIT_DB_PRESENT'}
  }
  foreach($entry in $ledger.trust){
   $actual=Get-ClrTrust $control ([Convert]::FromHexString($entry.hash))
   if(($entry.preexisting -and ($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint)) -or
      (-not $entry.preexisting -and $null -ne $actual)){throw 'RELEASE_CLR_AUDIT_TRUST_DRIFT'}
  }
  Assert-ReleaseInputs -All
  'PASS RELEASE_CLR_INDEPENDENT_CLEANUP_AND_PINS';exit 0
 }
 if(Test-Path -LiteralPath $journal){throw 'RELEASE_CLR_CASE_ALREADY_ATTEMPTED'}
 $stage='PREFLIGHT'
 $pre=@(Invoke-ReleaseSql $control "SELECT @@VERSION Version,CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info WITH (NOLOCK)) Platform,IS_SRVROLEMEMBER(N'sysadmin') IsAdmin,(SELECT value_in_use FROM sys.configurations WITH (NOLOCK) WHERE name='clr enabled') ClrReady; SELECT name,state_desc FROM sys.databases WITH (NOLOCK) ORDER BY database_id;" -Rows)
 if($pre[0].IsAdmin -ne 1 -or $pre[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[$case.Version] -or $pre[0].Platform -ine $case.Platform){throw 'RELEASE_CLR_PREFLIGHT'}
 if($pre[0].ClrReady -ne 1){throw 'RELEASE_CLR_DISABLED_NO_MUTATION'}
 Read-ApiCarry $control
 if($PreflightOnly){'PASS RELEASE_API_PREFLIGHT_ONLY actual target and carried cleanup/input bindings; no mutation';exit 0}
 $archive=[IO.Compression.ZipFile]::OpenRead($runset.package)
 $files=@{}
 try{foreach($e in $archive.Entries){
  $relative=$e.FullName.Substring('Toolbelt-Complete-Qualification/'.Length)
  if($relative.StartsWith('SQL/') -or $relative.StartsWith('Fixtures/') -or $relative -ceq 'CLR-PACKAGE.json'){
   $reader=[IO.StreamReader]::new($e.Open(),[Text.Encoding]::UTF8)
   try{$files[$relative]=$reader.ReadToEnd()}finally{$reader.Dispose()}
  }
 }}finally{$archive.Dispose()}
 $metadata=$files['CLR-PACKAGE.json']|ConvertFrom-Json
 $platformProfile=if($case.Platform -ceq 'windows'){'Windows'}else{'Portable'}
 $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');targetIdentity=$targetIdentity;qualificationScope=$runset.qualificationScope;state='PREPARED';databases=@();trust=@();completedModes=@();completedFixtures=@();reusedFixtures=@();blockedFixtures=@();failure=$null}
 Save-ReleaseJournal
 $stage='TRUST'
 $wanted=@($metadata.artifacts|Where-Object {$_.module_id -in @($metadata.profiles."$platformProfile-local") -or ($platformProfile -ceq 'Windows' -and -not $_.module_id)})
 foreach($a in $wanted){
  $hash=[Convert]::FromHexString($a.sha512);$before=Get-ClrTrust $control $hash
  $entry=[ordered]@{hash=$a.sha512;preexisting=($null -ne $before);fingerprint=$null;state='PREEXISTING';description=$null}
  if($before){$entry.fingerprint=$before.Fingerprint}
  $ledger.trust+=@($entry);Save-ReleaseJournal
  if(-not $before){
   Assert-ClrTrustCleanupScope $control $hash
   $entry.state='ADDING';$entry.description='Toolbelt synthetic CLR package '+$ledger.owner+' '+$a.file;Save-ReleaseJournal
   Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$hash;'@Description'=$entry.description}
   $actual=Get-ClrTrust $control $hash
   if($null -eq $actual -or $actual.description -cne $entry.description){throw 'RELEASE_CLR_TRUST_OWNERSHIP_UNKNOWN'}
   $entry.fingerprint=$actual.Fingerprint;$entry.state='OWNED';Save-ReleaseJournal
  }
 }
 Invoke-ReleaseBatches $control $files["SQL/Trust-$platformProfile-local.sql"]
 $names=@{}
 foreach($label in @('local','central','consumer')){
  $stage='CREATE_'+$label;$suffix=@{local='l';central='c';consumer='u'}[$label]
  $name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
  $entry=[ordered]@{name=$name;id=$null;created=$null;state='CREATING'}
  $ledger.databases+=@($entry);Save-ReleaseJournal
  Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 51591,N'Database collision.',4; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
  $id=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WITH (NOLOCK) WHERE name=@Name;' @{'@Name'=$name} -Rows)
  if($id.Count -ne 1){throw 'RELEASE_CLR_DB_IDENTITY'}
  $entry.id=$id[0].Id;$entry.created=$id[0].Created;$entry.state='CREATED';Save-ReleaseJournal
  $db=Open-ReleaseConnection $name
  Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
  $entry.state='OWNED';Save-ReleaseJournal;$db.Dispose()
  Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
  $names[$label]=$name
 }
 $spec=Get-Content -LiteralPath $runset.spec -Raw|ConvertFrom-Json
 $selected=@($spec.tests|Where-Object {Test-ApiSelected $_})
 if(-not $selected.Count){throw 'RELEASE_API_NO_FIXTURES'}
 foreach($mode in @('local','central')){
  $profile="$platformProfile-$mode";$stage='INSTALL_'+$mode
  $db=Open-ReleaseConnection $names[$mode]
  Invoke-ReleaseBatches $db $files["SQL/Install-$profile.sql"]
  # Dieselbe explizite dbo-Testpolicy wie in den kanonischen alten Fachtests.
  # Ausschließlich eigene disposable DB, keine Rechte-/Loginvergabe und kein
  # Minimalrechtenachweis. Echte Security-Negativtests gehören nicht hierher.
  if($case.group -ceq 'core'){
   Invoke-ReleaseBatches $db ([IO.File]::ReadAllText((Join-Path $runset.sourceRoot 'Tests/CI/WorkTypeAuthorization.Fixture.sql')))
  }
  $first=Assert-ClrInstalled $db $profile;$db.Dispose()
  foreach($test in @($selected|Where-Object context -ceq 'installed')){
   if($test.PSObject.Properties['deployment_modes'] -and $mode -cnotin $test.deployment_modes){continue}
   $stage=$mode+':'+$test.id
   Invoke-ApiChecked $test $names[$mode] '' $profile $first
  }
  if($mode -ceq 'central'){
   foreach($test in @($selected|Where-Object context -ceq 'consumer')){
    $stage='consumer:'+$test.id;Invoke-ApiChecked $test $names.consumer $names.central $profile $first
   }
  }
  $stage='INTEGRITY_'+$mode;$db=Open-ReleaseConnection $names[$mode]
  Assert-ApiProduct $db $profile $first;$db.Dispose()
  $ledger.completedModes+=@($mode);Save-ReleaseJournal
 }
 Assert-ReleaseInputs -All
}catch{
 $errorDetail=$_.Exception;$sqlFailure=$null
 while($true){if($errorDetail -is [Data.SqlClient.SqlException]){$sqlFailure=$errorDetail};if(-not $errorDetail.InnerException){break};$errorDetail=$errorDetail.InnerException}
 $failure=[ordered]@{stage=$stage;sqlNumber=$(if($sqlFailure){$sqlFailure.Number}else{0});reason=$(if($errorDetail.Message -cmatch '^RELEASE_[A-Z0-9_]+$'){$errorDetail.Message}else{'RELEASE_API_UNCLASSIFIED'})}
 if($ledger -and -not $AuditOnly){$ledger.failure=$failure;$ledger['privateDiagnostic']=$errorDetail.Message;$ledger['privateSourcePosition']=$_.ScriptStackTrace;Save-ReleaseJournal}
}finally{
 foreach($connection in $connections){try{$connection.Dispose()}catch{}}
 # Nur Pools dieses eigenen Testprozesses; Metadatenhelfer können eigene
 # SqlClient-Verbindungen anlegen. Vor dem DROP dürfen keine Idle-Pools bleiben.
 [Data.SqlClient.SqlConnection]::ClearAllPools()
 if($ledger -and -not $AuditOnly){
  $cleanup=$true
  try{
   $control=Open-ReleaseConnection 'master'
   foreach($entry in $ledger.databases){Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal}
   foreach($entry in $ledger.trust){
    $hash=[Convert]::FromHexString($entry.hash);$actual=Get-ClrTrust $control $hash
    if($entry.preexisting){if($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint){throw 'RELEASE_CLR_PREEXISTING_TRUST_DRIFT'};continue}
    if($entry.state -cne 'OWNED' -or $null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint -or $actual.description -cne $entry.description){throw 'RELEASE_CLR_TRUST_CLEANUP_IDENTITY'}
    Assert-ClrTrustCleanupScope $control $hash
    Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
    if($null -ne (Get-ClrTrust $control $hash)){throw 'RELEASE_CLR_TRUST_NOT_REMOVED'}
    $entry.state='REMOVED';Save-ReleaseJournal
   }
   $ledger.state=if($failure){'FAILED_CLEANED'}elseif($ledger.blockedFixtures.Count){'PARTIAL'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=@{stage='CLEANUP';sqlNumber=0;reason='RELEASE_CLR_CLEANUP_BLOCKED'}}
  finally{if($control){$control.Dispose()}}
 }
}
if($failure){Write-Output ('FAIL '+($failure|ConvertTo-Json -Compress));exit 1}
$result=if($ledger.blockedFixtures.Count){'PARTIAL'}else{'PASS'}
"$result RELEASE_API_PACKAGE group=$($case.group) fixtures=$($ledger.completedFixtures.Count) reused=$($ledger.reusedFixtures.Count) blocked=$($ledger.blockedFixtures.Count); independent audit required"
