[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$Database,
 [Parameter(Mandatory)][ValidateSet('local','central',IgnoreCase=$false)][string]$Mode,
 [Parameter(Mandatory)][string]$Owner32Hex,
 [Parameter(Mandatory)][ValidateRange(5,2147483647)][int]$ExpectedDatabaseId,
 [Parameter(Mandatory)][string]$ExpectedCreationHex,
 [Parameter(Mandatory)][string]$JournalPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# Ausschließlich die von Bash bereits angelegte eigene Loopback-CI-Datenbank.
# Der unveränderte Helper enthält die kanonischen Fälle; kein Labzugriff,
# keine Produktkopie und keine Trust-, Rechte- oder Konfigurationsänderung.
# Kooperativ: 120 s Arbeit + 30 s Restore; der äußere Prozesswatchdog bleibt
# erforderlich. Ein harter Prozessabbruch beweist keine Wiederherstellung.
$script:scopeClock=[Diagnostics.Stopwatch]::StartNew()
$script:cleanupPhase=$false;$script:deadlineFailed=$false
$script:stage='PREPARATION';$script:connection=$null;$script:ledger=$null
$script:journalHealthy=$false;$script:journalHash=$null
$script:pins=@{};$script:texts=@{}
$script:invokedDriverText=$MyInvocation.MyCommand.ScriptBlock.ToString().TrimStart([char]0xFEFF)
$script:restoreSql=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$script:foreignSetupSql=$null
$script:failureException=$null;$script:failureStage='PREPARATION'

function Get-SafeCastFailureCategory($Exception){
 # Nur exakte feste Throw-Literale aus den tatsächlich geladenen Quellen.
 # Weder Exceptiontext, SQL-Payload noch Pfad/Endpoint wird ausgegeben.
 $known=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
 foreach($text in @($script:invokedDriverText)+@($script:texts.Values)){
  $tokens=$null;$errors=$null
  $ast=[Management.Automation.Language.Parser]::ParseInput($text,[ref]$tokens,[ref]$errors)
  if($errors.Count){continue}
  foreach($node in $ast.FindAll({param($item)$item -is [Management.Automation.Language.StringConstantExpressionAst]},$true)){
   if($node.Value -cmatch '\ASAFE_CAST_[A-Z_]+\z'){[void]$known.Add($node.Value)}
  }
 }
 $cursor=$Exception
 while($null -ne $cursor){
  if($known.Contains($cursor.Message)){return $cursor.Message}
  $cursor=$cursor.InnerException
 }
 return 'UNCLASSIFIED'
}

function Get-SafeCastCommandTimeout {
 param([ValidateRange(1,60)][int]$Maximum=60)
 $limit=if($script:cleanupPhase){150000L}else{120000L}
 $remaining=$limit-$script:scopeClock.ElapsedMilliseconds
 if($remaining -lt 1000){
  if(-not $script:cleanupPhase){$script:cleanupPhase=$true;$script:deadlineFailed=$true}
  throw 'SAFE_CAST_SCOPE_DEADLINE'
 }
 return [int][Math]::Min($Maximum,[Math]::Floor($remaining/1000))
}

function Assert-SafeCastWorkBudget {
 if($script:cleanupPhase -or $script:deadlineFailed){throw 'SAFE_CAST_SCOPE_DEADLINE'}
 [void](Get-SafeCastCommandTimeout)
}

function Assert-SafeCastReadBudget($Command){
 try{[void](Get-SafeCastCommandTimeout)}catch{try{$Command.Cancel()}catch{};throw}
}

function Get-SafeCastFailure($Exception){
 $sql=$null;$cursor=$Exception
 while($null -ne $cursor){
  if($cursor -is [Data.SqlClient.SqlException]){$sql=$cursor}
  $cursor=$cursor.InnerException
 }
 [pscustomobject]@{SqlNumber=$(if($sql){$sql.Number}else{0});SqlState=$(if($sql){$sql.State}else{0})}
}

function Assert-SafeCastPins {
 foreach($path in $script:pins.Keys){
  if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $script:pins[$path]){
   throw 'SAFE_CAST_CI_SOURCE_CHANGED'
  }
 }
}

function Invoke-SafeCastBoundSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
 $command=$Connection.CreateCommand()
 $command.CommandTimeout=Get-SafeCastCommandTimeout;$command.CommandText=$Sql
 try{
  foreach($name in $Parameters.Keys){
   $value=$Parameters[$name]
   if($value -is [byte[]]){$parameter=$command.Parameters.Add($name,[Data.SqlDbType]::VarBinary,-1)}
   elseif($value -is [int]){$parameter=$command.Parameters.Add($name,[Data.SqlDbType]::Int)}
   else{$parameter=$command.Parameters.Add($name,[Data.SqlDbType]::NVarChar,-1)}
   $parameter.Value=$value
  }
  $reader=$command.ExecuteReader()
  try{
   $result=[Collections.Generic.List[object]]::new();$rowCount=0;$resultCount=0
   do{
    Assert-SafeCastReadBudget $command;$resultCount++
    if($resultCount -gt 64){throw 'SAFE_CAST_CI_RESULT_BUDGET'}
    while($reader.Read()){
     Assert-SafeCastReadBudget $command;$rowCount++
     if($rowCount -gt 4096 -or $reader.FieldCount -gt 64){throw 'SAFE_CAST_CI_RESULT_BUDGET'}
     if($Rows){
      $record=[ordered]@{}
      for($index=0;$index -lt $reader.FieldCount;$index++){$record[$reader.GetName($index)]=$reader.GetValue($index)}
      $result.Add([pscustomobject]$record)
     }else{for($index=0;$index -lt $reader.FieldCount;$index++){[void]$reader.GetValue($index)}}
    }
    Assert-SafeCastReadBudget $command
   }while($reader.NextResult())
   if($Rows){return $result.ToArray()}
  }finally{$reader.Dispose()}
 }catch{
  # Eine abgelaufene Arbeitsfrist lässt nur die Helper-finally-Restores zu.
  if(-not $script:cleanupPhase -and $script:scopeClock.ElapsedMilliseconds -ge 120000){
   $script:cleanupPhase=$true;$script:deadlineFailed=$true
  }
  throw
 }finally{$command.Dispose()}
}

function Assert-SafeCastOwner($Connection){
 # Nur lesend, auch in einer gesunden oder doomed Caller-Transaktion; keine
 # SET-/Transaktionsänderung und kein Übernehmen eines neu gelesenen Baselines.
 $rows=@(Invoke-SafeCastBoundSql $Connection @'
SELECT CONVERT(int,1) Witness
FROM sys.databases d
WHERE d.database_id=DB_ID() AND d.database_id=@Id AND d.database_id>4
 AND CONVERT(varbinary(max),DB_NAME())=CONVERT(varbinary(max),@Name)
 AND CONVERT(varbinary(max),d.name)=CONVERT(varbinary(max),@Name)
 AND CONVERT(binary(8),d.create_date)=@Created AND d.compatibility_level=@CL
 AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Test.SafeCast.Owner'
  AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar'
  AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner))
 AND NOT EXISTS(SELECT 1 FROM sys.extended_properties
  WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.DeploymentMode'
  AND (SQL_VARIANT_PROPERTY(value,N'BaseType')<>N'nvarchar'
   OR TRY_CONVERT(nvarchar(max),value) IS NULL
   OR CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))<>CONVERT(varbinary(max),@Mode)));
'@ @{'@Id'=$ExpectedDatabaseId;'@Name'=$Database;'@Created'=$script:creationBytes;'@CL'=$script:compatibilityLevel;'@Owner'=$Owner32Hex;'@Mode'=$Mode} -Rows)
 if($rows.Count -ne 1 -or $rows[0].Witness -ne 1){throw 'SAFE_CAST_CI_OWNER_TUPLE_CHANGED'}
}

function Invoke-SafeCastSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
 # Nur exakte Cleanup-Literale aus dem gepinnten Helper erhalten die Reserve.
 # Der anschließende Add-SafeCastCases-Gate schaltet zurück auf die Arbeitsfrist.
 if($script:restoreSql.Contains($Sql)){$script:cleanupPhase=$true}
 Assert-SafeCastPins
 Assert-SafeCastOwner $Connection
 if($Sql -ceq $script:foreignSetupSql){
  # Vor dem möglichen COMMIT erfassen: fällt dessen Resulttransport oder das
  # nächste Helper-Journaling aus, ist Restoration ausdrücklich unbekannt.
  $script:ledger.ForeignSetupPending=$true;Save-SafeCastJournal
 }
 Invoke-SafeCastBoundSql $Connection $Sql $Parameters -Rows:$Rows
}

function Invoke-SafeCastBatches($Connection,[string]$Sql){
 foreach($batch in [regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
  if(-not [string]::IsNullOrWhiteSpace($batch)){Invoke-SafeCastSql $Connection $batch}
 }
}

function Open-SafeCastConnection($Target,[string]$Name){
 if($null -ne $Target -or $Name -cne $Database){throw 'SAFE_CAST_CI_CONNECTION_SCOPE'}
 Assert-SafeCastPins
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new();$connection=$null
 try{
  $builder['Data Source']='tcp:127.0.0.1,'+$script:port
  $builder['Initial Catalog']=$Database;$builder['User ID']='sa';$builder['Password']=$script:password
  $builder['Encrypt']=$true;$builder['TrustServerCertificate']=$true
  $builder['Pooling']=$false;$builder['Enlist']=$false;$builder['ConnectRetryCount']=0
  $builder['Connect Timeout']=Get-SafeCastCommandTimeout 15
  $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
  $connection.Open();Assert-SafeCastOwner $connection
  return $connection
 }catch{if($connection){try{$connection.Dispose()}catch{}};throw}
 finally{$builder.Clear()}
}

function Read-SafeCastCiSql([string]$Path,[hashtable]$Variables,[string[]]$Ancestors=@()){
 $path=[IO.Path]::GetFullPath($Path)
 if(-not $script:texts.ContainsKey($path) -or $Ancestors -contains $path){throw 'SAFE_CAST_CI_TEMPLATE_SCOPE'}
 $text=$script:texts[$path];$chain=$Ancestors+@($path)
 # Inkludiert ausschließlich die fünf eingefrorenen Deploymentdateien.
 $text=[regex]::Replace($text,'(?im)^\s*:r\s+([^\r\n]+)\s*$',{param($match)
  Read-SafeCastCiSql (Join-Path (Split-Path -Parent $path) $match.Groups[1].Value.Trim()) $Variables $chain
 })
 $text=[regex]::Replace($text,'(?im)^\s*:On\s+Error\s+exit\s*$','')
 foreach($key in $Variables.Keys){$text=$text.Replace('$('+$key+')',[string]$Variables[$key])}
 if($text -match '(?m)^\s*:' -or $text -match '\$\('){throw 'SAFE_CAST_CI_TEMPLATE_UNRESOLVED'}
 return $text
}

function Assert-SafeCastJournalLocation {
 # Die Elternkette darf kein Reparse-/Symlinkziel verdecken. Der Aufrufer
 # stellt den privaten Elternordner bereit; vorhandene Dateien werden abgewiesen.
 $parent=[IO.DirectoryInfo]::new([IO.Path]::GetDirectoryName($script:journal))
 if(-not $parent.Exists){throw 'SAFE_CAST_CI_JOURNAL_PARENT_REQUIRED'}
 if(-not $IsWindows){
  $publicBits=[IO.UnixFileMode]::GroupRead -bor [IO.UnixFileMode]::GroupWrite -bor [IO.UnixFileMode]::GroupExecute -bor
   [IO.UnixFileMode]::OtherRead -bor [IO.UnixFileMode]::OtherWrite -bor [IO.UnixFileMode]::OtherExecute
  if(([IO.File]::GetUnixFileMode($parent.FullName) -band $publicBits) -ne 0){throw 'SAFE_CAST_CI_PRIVATE_JOURNAL_PARENT_REQUIRED'}
 }
 while($null -ne $parent){
  if(($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'SAFE_CAST_CI_JOURNAL_LINK'}
  $parent=$parent.Parent
 }
 if([IO.File]::Exists($script:journal) -and
  (([IO.File]::GetAttributes($script:journal) -band [IO.FileAttributes]::ReparsePoint) -ne 0)){
  throw 'SAFE_CAST_CI_JOURNAL_LINK'
 }
}

function Save-SafeCastJournal {
 $temporary=$script:journal+'.writing.'+$Owner32Hex
 try{
  Assert-SafeCastJournalLocation
  if($script:ledger.ForeignFixtures.Count -eq 1){$script:ledger.ForeignSetupPending=$false}
  if(-not $script:journalHealthy -or -not [IO.File]::Exists($script:journal) -or
   (Get-FileHash -LiteralPath $script:journal -Algorithm SHA256).Hash -cne $script:journalHash){throw 'SAFE_CAST_CI_JOURNAL_CHANGED'}
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($script:ledger|ConvertTo-Json -Depth 9))
  $stream=[IO.FileStream]::new($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
  if(-not $IsWindows){[IO.File]::SetUnixFileMode($temporary,([IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite))}
  # Gleiches Dateisystem, atomarer Austausch; keine Wiederaufnahme eines fremden Ledgers.
  Assert-SafeCastJournalLocation
  if((Get-FileHash -LiteralPath $script:journal -Algorithm SHA256).Hash -cne $script:journalHash){throw 'SAFE_CAST_CI_JOURNAL_CHANGED'}
  [IO.File]::Move($temporary,$script:journal,$true)
  $script:journalHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
 }catch{$script:journalHealthy=$false;throw 'SAFE_CAST_CI_PRIVATE_JOURNAL_FAILED'}
}

function Add-SafeCastCases([int]$Count){
 $script:cleanupPhase=$false
 Assert-SafeCastWorkBudget
 $script:ledger.LifecycleCasesPassed+=$Count;Save-SafeCastJournal
}

function Assert-SafeCastAbsent($Connection){
 $rows=@(Invoke-SafeCastSql $Connection @'
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.toolbelt.conversion.safe-cast.%')
 OR EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_conversion')
  AND name IN(N'TVF_TryCastBigInt',N'TVF_TryCastDecimal',N'TVF_TryCastDate',N'TVF_TryCastDateTime2',N'TVF_TryCastBit',N'TVF_TryCastUniqueIdentifier'))
 THROW 51594,N'Safe Cast uninstall witness failed.',5;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51594,N'Safe Cast uninstall session not neutral.',6;
SELECT CONVERT(int,1) Witness;
'@ -Rows)
 if($rows.Count -ne 1 -or $rows[0].Witness -ne 1){throw 'SAFE_CAST_CI_ABSENCE_WITNESS'}
}

$failed=$false;$completed=$false
try{
 if($Database -cnotmatch '\Atbx_safe_cast_(local|central)_(150|160|170)\z' -or $Matches[1] -cne $Mode){throw 'SAFE_CAST_CI_DATABASE_SCOPE'}
 $script:compatibilityLevel=[int]$Matches[2]
 if($Owner32Hex -cnotmatch '\A[a-f0-9]{32}\z' -or $ExpectedCreationHex -cnotmatch '\A0x[A-F0-9]{16}\z'){
  throw 'SAFE_CAST_CI_OWNER_ARGUMENT'
 }
 $script:creationBytes=[Convert]::FromHexString($ExpectedCreationHex.Substring(2))
 $script:port=[Environment]::GetEnvironmentVariable('TBX_CI_SQL_PORT','Process')
 $script:password=[Environment]::GetEnvironmentVariable('TBX_CI_SQL_PASSWORD','Process')
 if($script:port -cnotmatch '\A[0-9]{1,5}\z' -or [int]$script:port -lt 1 -or [int]$script:port -gt 65535 -or [string]::IsNullOrWhiteSpace($script:password)){
  throw 'SAFE_CAST_CI_ENV_INVALID'
 }
 $repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
 $script:journal=[IO.Path]::GetFullPath($JournalPath)
 $comparison=if($IsWindows){[StringComparison]::OrdinalIgnoreCase}else{[StringComparison]::Ordinal}
 if(-not [IO.Path]::IsPathFullyQualified($JournalPath) -or $script:journal.Equals($repo,$comparison) -or
  $script:journal.StartsWith($repo.TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar,$comparison)){
  throw 'SAFE_CAST_CI_PRIVATE_JOURNAL_REQUIRED'
 }
 Assert-SafeCastJournalLocation
 if(Test-Path -LiteralPath $script:journal){throw 'SAFE_CAST_CI_JOURNAL_EXISTS'}
 $deployment=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../Deployment'))
 $helper=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../Tests/CI/SafeCastLifecycle.Helpers.ps1'))
 $paths=@($PSCommandPath,$helper)+@(foreach($name in @('Deploy.sql','Uninstall.sql','Preflight.sql','CreateObjects.sql','MarkRelease.sql')){Join-Path $deployment $name})
 $utf8=[Text.UTF8Encoding]::new($false,$true)
 foreach($path in $paths){
  $path=[IO.Path]::GetFullPath($path)
  if([IO.FileInfo]::new($path).Length -gt 2097152){throw 'SAFE_CAST_CI_SOURCE_BUDGET'}
  $bytes=[IO.File]::ReadAllBytes($path)
  $script:pins[$path]=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
  $script:texts[$path]=$utf8.GetString($bytes).TrimStart([char]0xFEFF)
 }
 if($script:texts[[IO.Path]::GetFullPath($PSCommandPath)] -cne $script:invokedDriverText){throw 'SAFE_CAST_CI_EXECUTED_DRIVER_PIN'}
 Assert-SafeCastPins
 $parseErrors=$null;$tokens=$null
 $tree=[Management.Automation.Language.Parser]::ParseInput($script:texts[$helper],[ref]$tokens,[ref]$parseErrors)
 if($parseErrors.Count -or $tree.BeginBlock -or $tree.ProcessBlock -or $tree.ParamBlock -or
  @($tree.EndBlock.Statements|Where-Object {$_ -isnot [Management.Automation.Language.FunctionDefinitionAst]}).Count){throw 'SAFE_CAST_CI_HELPER_EFFECTS'}
 $names=@($tree.EndBlock.Statements|ForEach-Object Name)
 $expectedNames=@('Assert-SafeCastForeignSlotPrepared','Assert-SafeCastCallerPrepared','Assert-SafeCastLockPrepared','Get-SafeCastCompleteSnapshotSql','Get-SafeCastSnapshot','Assert-SafeCastRollbackPrepared','Assert-SafeCastConfirmPrepared','Assert-SafeCastTypedMarkerPrepared')
 if(($names -join '|') -cne ($expectedNames -join '|')){throw 'SAFE_CAST_CI_HELPER_FUNCTION_SET'}
 $strings=@($tree.FindAll({param($node)$node -is [Management.Automation.Language.StringConstantExpressionAst]},$true))
 foreach($literal in $strings){
  if($literal.Value.Contains('Marker restore session not neutral.') -or $literal.Value.Contains('Foreign restore session not neutral.') -or
   $literal.Value.StartsWith('IF @@TRANCOUNT>0 ROLLBACK;',[StringComparison]::Ordinal)){
   [void]$script:restoreSql.Add($literal.Value)
  }
  if($literal.Value.Contains('Foreign fixture session not neutral.')){
   if($null -ne $script:foreignSetupSql){throw 'SAFE_CAST_CI_FOREIGN_SETUP_AMBIGUOUS'}
   $script:foreignSetupSql=$literal.Value
  }
 }
 if($script:restoreSql.Count -ne 5 -or $null -eq $script:foreignSetupSql){throw 'SAFE_CAST_CI_RESTORE_LITERAL_SET'}
 foreach($definition in $tree.EndBlock.Statements){. ([scriptblock]::Create($definition.Extent.Text))}
 Assert-SafeCastPins
 $sourcePins=@(foreach($path in $paths){[ordered]@{Path=[IO.Path]::GetRelativePath($repo,$path).Replace('\','/');SHA256=$script:pins[[IO.Path]::GetFullPath($path)]}})
 $script:ledger=[ordered]@{State='PREPARED';Mode=$Mode;RunId=$Owner32Hex;Database=$Database;DatabaseId=$ExpectedDatabaseId;CreationHex=$ExpectedCreationHex;CompatibilityLevel=$script:compatibilityLevel;SourcePins=$sourcePins;LifecycleCasesPassed=0;MarkerFixtures=@();ForeignFixtures=@();ForeignSetupPending=$false;AbsentVerified=$false;NeutralVerified=$false;SourcePinsVerified=$false;FailureStage=$null;RestorationUnverified=$false}
 $stream=[IO.FileStream]::new($script:journal,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Flush($true)}finally{$stream.Dispose()}
 if(-not $IsWindows){[IO.File]::SetUnixFileMode($script:journal,([IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite))}
 $script:journalHash=(Get-FileHash -LiteralPath $script:journal -Algorithm SHA256).Hash;$script:journalHealthy=$true
 Save-SafeCastJournal
 $variables=@{DeploymentMode=$Mode;ConfirmNoExternalConsumers=1}
 $deploy=Read-SafeCastCiSql (Join-Path $deployment 'Deploy.sql') $variables
 $uninstall=Read-SafeCastCiSql (Join-Path $deployment 'Uninstall.sql') $variables
 $script:stage='BASELINE';Assert-SafeCastWorkBudget
 $script:connection=Open-SafeCastConnection $null $Database
 $baseline=@(Invoke-SafeCastSql $script:connection @'
-- Sessiongate in eigenem Statement vor dem Katalogread, wie im Labadapter.
-- Der nachfolgende SELECT darf die Beobachtung nicht in seinen Kontext ziehen.
DECLARE @Neutral int=CASE WHEN @@TRANCOUNT=0 AND XACT_STATE()=0 THEN 1 ELSE 0 END;
SELECT @Neutral Neutral,
 CONVERT(int,CASE WHEN (SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version'
  AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.0.0'))=1 THEN 1 ELSE 0 END) VersionReady,
 CONVERT(int,CASE WHEN (SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.DeploymentMode'
  AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Mode))=1 THEN 1 ELSE 0 END) ModeReady,
 CONVERT(int,CASE WHEN (SELECT COUNT(*) FROM sys.objects o JOIN sys.sql_modules m ON m.object_id=o.object_id
  WHERE o.schema_id=SCHEMA_ID(N'toolbelt_conversion') AND o.type=N'IF' AND m.is_schema_bound=1
  AND o.name IN(N'TVF_TryCastBigInt',N'TVF_TryCastDecimal',N'TVF_TryCastDate',N'TVF_TryCastDateTime2',N'TVF_TryCastBit',N'TVF_TryCastUniqueIdentifier'))=6 THEN 1 ELSE 0 END) ObjectsReady;
'@ @{'@Mode'=$Mode} -Rows)
 if($baseline.Count -ne 1){throw 'SAFE_CAST_CI_INSTALLED_BASELINE_REQUIRED'}
 if($baseline[0].Neutral -ne 1){throw 'SAFE_CAST_CI_BASELINE_SESSION_NOT_NEUTRAL'}
 if($baseline[0].VersionReady -ne 1){throw 'SAFE_CAST_CI_BASELINE_VERSION_MISMATCH'}
 if($baseline[0].ModeReady -ne 1){throw 'SAFE_CAST_CI_BASELINE_MODE_MISMATCH'}
 if($baseline[0].ObjectsReady -ne 1){throw 'SAFE_CAST_CI_BASELINE_OBJECTS_MISMATCH'}
 $script:ledger.State='RUNNING';Save-SafeCastJournal
 foreach($abort in @('OFF','ON')){foreach($doomed in @($false,$true)){
  $script:stage='CALLER';Assert-SafeCastWorkBudget
  Assert-SafeCastCallerPrepared $script:connection $deploy $uninstall $abort $doomed
  Add-SafeCastCases 2
 }}
 $script:stage='LOCK';Assert-SafeCastWorkBudget
 Assert-SafeCastLockPrepared $null $Database $script:connection $deploy $uninstall;Add-SafeCastCases 2
 $script:stage='ROLLBACK';Assert-SafeCastWorkBudget
 Assert-SafeCastRollbackPrepared $script:connection $deploy $uninstall;Add-SafeCastCases 4
 $script:stage='MARKER';Assert-SafeCastWorkBudget
 Assert-SafeCastTypedMarkerPrepared $script:connection $deploy $uninstall $Mode;Add-SafeCastCases 2
 if($Mode -ceq 'central'){
  $script:stage='CONFIRM0';Assert-SafeCastWorkBudget
  $unconfirmed=$variables.Clone();$unconfirmed.ConfirmNoExternalConsumers=0
  Assert-SafeCastConfirmPrepared $script:connection (Read-SafeCastCiSql (Join-Path $deployment 'Uninstall.sql') $unconfirmed)
  Add-SafeCastCases 2
 }
 $script:stage='UNINSTALL';Assert-SafeCastWorkBudget
 Invoke-SafeCastBatches $script:connection $uninstall;Assert-SafeCastAbsent $script:connection
 $script:stage='FOREIGN_SLOT';Assert-SafeCastWorkBudget
 Assert-SafeCastForeignSlotPrepared $script:connection $deploy $uninstall $Mode;Add-SafeCastCases 2
 $script:stage='UNINSTALL_REPEAT';Assert-SafeCastWorkBudget
 Invoke-SafeCastBatches $script:connection $uninstall;Assert-SafeCastAbsent $script:connection
 $expectedCount=if($Mode -ceq 'local'){18}else{20}
 if($script:ledger.LifecycleCasesPassed -ne $expectedCount -or $script:ledger.MarkerFixtures.Count -ne 1 -or $script:ledger.ForeignFixtures.Count -ne 1){throw 'SAFE_CAST_CI_FINAL_COUNTS'}
 foreach($fixture in @($script:ledger.MarkerFixtures)+@($script:ledger.ForeignFixtures)){
  if(-not $fixture.Restored -or $fixture.Rejections -ne 2){throw 'SAFE_CAST_CI_FINAL_RESTORATION'}
 }
 Assert-SafeCastWorkBudget;Assert-SafeCastPins;Assert-SafeCastOwner $script:connection
 $script:ledger.AbsentVerified=$true;$script:ledger.NeutralVerified=$true;$script:ledger.SourcePinsVerified=$true
 $completed=$true
}catch{
 $failed=$true
 $script:failureException=$_.Exception;$script:failureStage=$script:stage
 if($null -ne $script:ledger){$script:ledger.FailureStage=$script:stage}
}finally{
 $script:cleanupPhase=$true
 try{
  if($script:connection){
   if($script:connection.State -eq [Data.ConnectionState]::Open){
    # Nur eigene Session zurückrollen, weiterhin hinter dem exakten Ownergate.
    Invoke-SafeCastSql $script:connection 'IF @@TRANCOUNT>0 ROLLBACK;'
    $neutral=@(Invoke-SafeCastSql $script:connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState;' -Rows)
    if($neutral.Count -ne 1 -or $neutral[0].TranCount -ne 0 -or $neutral[0].TranState -ne 0){throw 'SAFE_CAST_CI_FINAL_SESSION'}
   }elseif($completed){throw 'SAFE_CAST_CI_FINAL_CONNECTION'}
   $script:connection.Dispose();$script:connection=$null
  }
  Assert-SafeCastPins;[void](Get-SafeCastCommandTimeout)
  if($null -ne $script:ledger -and $script:journalHealthy){
   $unrestored=@(@($script:ledger.MarkerFixtures)+@($script:ledger.ForeignFixtures)|Where-Object {-not $_.Restored}).Count
   $script:ledger.RestorationUnverified=($unrestored -ne 0 -or $script:ledger.ForeignSetupPending)
   if($script:ledger.RestorationUnverified){$failed=$true}
   $script:ledger.State=if($completed -and -not $failed){'COMPLETE'}else{'FAILED'}
   Save-SafeCastJournal
  }else{$failed=$true}
 }catch{
  $failed=$true
  if($null -eq $script:failureException){$script:failureException=$_.Exception;$script:failureStage='FINAL_CLEANUP'}
  if($null -ne $script:ledger){
   $script:ledger.State='RESTORATION_UNVERIFIED';$script:ledger.RestorationUnverified=$true
   if($script:journalHealthy){try{Save-SafeCastJournal}catch{}}
  }
 }finally{
  if($script:connection){try{$script:connection.Dispose()}catch{
   $failed=$true
   if($null -eq $script:failureException){$script:failureException=$_.Exception;$script:failureStage='FINAL_CLEANUP'}
  }}
  $script:password=$null
 }
}
if($failed -or -not $completed){
 # Erst nach dem Restore kategorisieren; die Diagnose verbraucht keine Reserve.
 $category='UNCLASSIFIED'
 try{$category=Get-SafeCastFailureCategory $script:failureException}catch{}
 $stages=@('PREPARATION','BASELINE','CALLER','LOCK','ROLLBACK','MARKER','CONFIRM0','UNINSTALL','FOREIGN_SLOT','UNINSTALL_REPEAT','FINAL_CLEANUP')
 $stage=if($stages -ccontains $script:failureStage){$script:failureStage}else{'UNCLASSIFIED'}
 [Console]::Error.WriteLine('SAFE_CAST_CI_LIFECYCLE_FAILED:stage='+$stage+':reason='+$category)
 exit 1
}
Write-Output ('PASS: SAFE_CAST_CI_LIFECYCLE mode='+$Mode+' cases='+$script:ledger.LifecycleCasesPassed+' restored=2 absent=1')
