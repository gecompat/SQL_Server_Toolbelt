[CmdletBinding()]
param(
 [ValidateSet('linux','windows')][string]$Platform='linux',
 [ValidateSet('2019','2022','2025')][string]$Version='2019',
 [string]$Patch='latest',
 [ValidateSet(150,160,170)][int]$CompatibilityLevel=150,
 [Parameter(Mandatory)][string]$ReleaseDirectory,
 [Parameter(Mandatory)][string]$JournalManifestPath,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedPromptSHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedDriverSHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{128}$')][string]$ExpectedAssemblySHA512,
 [ValidateSet('local','central')][string[]]$DeploymentModes=@('local','central'),
 [switch]$OptInExactTrust
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$stage='PREPARATION';$batchIndex=0
$script:scopeClock=$null;$script:cleanupPhase=$false
$script:workMilliseconds=960000L;$script:totalMilliseconds=1200000L
# Infrastrukturmuster aus dem qualifizierten XLSX-Adapter: ausschließlich eigener
# CSV-Ressourcenscope, keine fachliche Parser-/Writerlogik oder fremde Journale.

function Get-CsvCommandTimeout {
 param([ValidateRange(1,60)][int]$Maximum=60)
 if($null -eq $script:scopeClock){throw 'CSV_SCOPE_CLOCK_REQUIRED'}
 $limit=if($script:cleanupPhase){$script:totalMilliseconds}else{$script:workMilliseconds}
 $remaining=$limit-$script:scopeClock.ElapsedMilliseconds
 if($remaining -lt 1000){throw 'CSV_SCOPE_DEADLINE'}
 return [int][Math]::Min($Maximum,[Math]::Floor($remaining/1000))
}

function Assert-CsvReadBudget($Command){
 try{[void](Get-CsvCommandTimeout)}catch{try{$Command.Cancel()}catch{};throw}
}

function Invoke-CsvOwnSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
 # Nur administrative OwnScope-Batches; Original-Produkt-DDL bleibt direkt.
 $prefix="IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',5;"+[Environment]::NewLine
 Invoke-CsvSql $Connection ($prefix+$Sql) $Parameters -Rows:$Rows
}

function Get-CsvFailure($Exception){
 $sql=$null;$cursor=$Exception;$reason='UNCLASSIFIED'
 while($null -ne $cursor){
  if($cursor -is [Data.SqlClient.SqlException]){$sql=$cursor}
  if($cursor.Message -cmatch '^CSV_[A-Z0-9_]+$'){$reason=$cursor.Message}
  $cursor=$cursor.InnerException
 }
 [ordered]@{Stage=$script:stage;Batch=$script:batchIndex;SqlNumber=$(if($sql){$sql.Number}else{0});SqlState=$(if($sql){$sql.State}else{0});Reason=$reason}
}

function Invoke-CsvSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
 $timeout=Get-CsvCommandTimeout
 $command=$Connection.CreateCommand();$command.CommandTimeout=$timeout;$command.CommandText=$Sql
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
   $result=[Collections.Generic.List[object]]::new()
   do{Assert-CsvReadBudget $command;while($reader.Read()){
    Assert-CsvReadBudget $command
    if($Rows){$record=[ordered]@{};for($index=0;$index -lt $reader.FieldCount;$index++){$record[$reader.GetName($index)]=$reader.GetValue($index)};$result.Add([pscustomobject]$record)}
    else{for($index=0;$index -lt $reader.FieldCount;$index++){[void]$reader.GetValue($index)}}
   };Assert-CsvReadBudget $command}while($reader.NextResult())
   if($Rows){return $result.ToArray()}
  }finally{$reader.Dispose()}
 }finally{$command.Dispose()}
}

function Read-CsvSql([string]$Path,[hashtable]$Variables){
 $text=[IO.File]::ReadAllText($Path)
 $text=[regex]::Replace($text,'(?im)^\s*:r\s+([^\r\n]+)\s*$',{param($match)
  Read-CsvSql (Join-Path (Split-Path -Parent $Path) $match.Groups[1].Value.Trim()) $Variables
 })
 $text=[regex]::Replace($text,'(?im)^\s*:On\s+Error\s+exit\s*$','')
 foreach($key in $Variables.Keys){$text=$text.Replace('$('+ $key +')',[string]$Variables[$key])}
 if($text -match '(?m)^\s*:' -or $text -match '\$\('){throw 'CSV_SQL_TEMPLATE_UNRESOLVED'}
 return $text
}

function Invoke-CsvBatches($Connection,[string]$Sql){
 $script:batchIndex=0
 foreach($batch in [regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
  if(-not [string]::IsNullOrWhiteSpace($batch)){$script:batchIndex++;Invoke-CsvSql $Connection $batch}
 }
}

function Open-CsvConnection($Target,[string]$Database){
 $builder=$null;$connection=$null
 try{
  $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString $Target))
  $builder['Initial Catalog']=$Database;$builder['Pooling']=$false;$builder['Enlist']=$false
  $builder['ConnectRetryCount']=0;$builder['Connect Timeout']=Get-CsvCommandTimeout 15
  $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
  $connection.Open();return $connection
 }catch{if($connection){try{$connection.Dispose()}catch{}};throw}
 finally{if($builder){try{$builder.Clear()}catch{}}}
}

function Save-CsvJournal{
 try{
  $temporary=$script:journal+'.writing'
  [IO.File]::WriteAllText($temporary,($script:ledger|ConvertTo-Json -Depth 9),[Text.UTF8Encoding]::new($false))
  [IO.File]::Move($temporary,$script:journal,$true)
 }catch{$script:journalHealthy=$false;throw 'CSV_PRIVATE_JOURNAL_FAILED'}
}

function Get-CsvTrust($Connection,[byte[]]$Hash){
 # Vollständige datetime2(7)-Bytes: binary(8) wäre eine Trunkierung.
 $rows=@(Invoke-CsvOwnSql $Connection @'
SELECT description,CONVERT(varchar(64),HASHBYTES('SHA2_256',
 hash+CONVERT(binary(4),ISNULL(DATALENGTH(description),-1))+ISNULL(CONVERT(varbinary(max),description),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(CONVERT(varbinary(max),create_date)),-1))+ISNULL(CONVERT(varbinary(max),create_date),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(created_by),-1))+ISNULL(CONVERT(varbinary(max),created_by),0x)),2) Fingerprint
FROM sys.trusted_assemblies WHERE hash=@Hash;
'@ @{'@Hash'=$Hash} -Rows)
 if($rows.Count -gt 1){throw 'CSV_TRUST_MULTIPLE'}
 if($rows.Count){if($rows[0].Fingerprint -is [DBNull] -or $rows[0].Fingerprint -notmatch '^[A-F0-9]{64}$'){throw 'CSV_TRUST_FINGERPRINT_INVALID'};return $rows[0]}
 return $null
}

function Register-CsvTrust($Control,$Artifact){
 $hash=[Convert]::FromHexString($Artifact.Hash);$existing=Get-CsvTrust $Control $hash
 $entry=[ordered]@{Hash=$Artifact.Hash;State='PREEXISTING';Preexisting=$true;Description=$null;Fingerprint=$null}
 $script:ledger.Trust+=@($entry);Save-CsvJournal
 if($existing){
  $entry.Description=if($existing.description -is [DBNull]){$null}else{[string]$existing.description}
  $entry.Fingerprint=[string]$existing.Fingerprint;Save-CsvJournal;return
 }
 if(-not $OptInExactTrust){throw 'CSV_EXACT_TRUST_REQUIRED'}
 Assert-CsvTrustCleanupScope $Control $hash
 $entry.Preexisting=$false;$entry.State='ADDING';$entry.Description='Toolbelt synthetic CSV types '+$script:ledger.RunId+' '+$Artifact.Label
 Save-CsvJournal
 Invoke-CsvOwnSql $Control @'
IF @Hash IS NULL OR DATALENGTH(@Hash)<>64 OR @Description IS NULL OR DATALENGTH(@Description)>8000
 THROW 51591,N'Typed trust arguments invalid.',11;
DECLARE @TrustHash varbinary(64)=@Hash,@TrustDescription nvarchar(4000)=@Description;
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash)
 EXEC sys.sp_add_trusted_assembly @hash=@TrustHash,@description=@TrustDescription;
'@ @{'@Hash'=$hash;'@Description'=$entry.Description}
 $actual=Get-CsvTrust $Control $hash
 if($null -eq $actual -or $actual.description -is [DBNull] -or [string]$actual.description -cne $entry.Description){$entry.State='IDENTITY_UNKNOWN';Save-CsvJournal;throw 'CSV_TRUST_IDENTITY_UNKNOWN'}
 $entry.Fingerprint=$actual.Fingerprint;$entry.State='OWNED';Save-CsvJournal
}

function Assert-CsvTrustCleanupScope($Control,[byte[]]$Hash){
 # Vor eigenem ADD prüfen, ob alle später benötigten Verbraucherprüfungen
 # tatsächlich lesbar sind. Vorbestehende Trustzeilen bleiben unberührt.
 Invoke-CsvSql $Control @'
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',5;
IF EXISTS(SELECT 1 FROM sys.databases WHERE state<>0) THROW 51591,N'Consumer inspection uncertain.',6;
DECLARE @Databases TABLE(Id int PRIMARY KEY,Name sysname,Created varbinary(16));
INSERT @Databases SELECT database_id,name,CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases;
DECLARE @Name sysname,@Sql nvarchar(max),@Count int;
DECLARE Consumers CURSOR LOCAL FAST_FORWARD FOR SELECT Name FROM @Databases;
OPEN Consumers;FETCH NEXT FROM Consumers INTO @Name;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Count=NULL;
 SET @Sql=N'SELECT @Count=COUNT(*) FROM '+QUOTENAME(@Name)+N'.sys.assembly_files WHERE file_id=1 AND HASHBYTES(''SHA2_512'',content)=@Hash;';
 EXEC sys.sp_executesql @Sql,N'@Hash varbinary(64),@Count int OUTPUT',@Hash,@Count OUTPUT;
 IF @Count IS NULL OR @Count<>0 THROW 51591,N'Hash consumer remains or inspection uncertain.',7;
 FETCH NEXT FROM Consumers INTO @Name;
END;
CLOSE Consumers;DEALLOCATE Consumers;
IF EXISTS(SELECT database_id,CONVERT(varbinary(max),name),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases
 EXCEPT SELECT Id,CONVERT(varbinary(max),Name),Created FROM @Databases)
 OR EXISTS(SELECT Id,CONVERT(varbinary(max),Name),Created FROM @Databases
 EXCEPT SELECT database_id,CONVERT(varbinary(max),name),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases)
 THROW 51591,N'Consumer inspection changed.',8;
'@ @{'@Hash'=$Hash}
}

function New-CsvDatabase($Control,$Target,[string]$Label,[string]$Collation){
 $name='Toolbelt_CsvTypes_'+[guid]::NewGuid().ToString('N')
 $entry=[ordered]@{Name=$name;Label=$Label;State='CREATING';Id=$null;Creation=$null;Marker=$false}
 $script:ledger.Databases+=@($entry);Save-CsvJournal
 Invoke-CsvOwnSql $Control ("IF DB_ID(N'$name') IS NOT NULL THROW 51591,N'Synthetic database collision.',1; CREATE DATABASE [$name] COLLATE $Collation;")
 $connection=Open-CsvConnection $Target $name
 try{
  Invoke-CsvOwnSql $connection 'DECLARE @MarkerOwner nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Toolbelt.Test.CsvTypes.Owner'',@value=@MarkerOwner;' @{'@Owner'=$script:ledger.RunId}
  $identity=@(Invoke-CsvOwnSql $connection @'
SELECT DB_ID() Id,CONVERT(varchar(32),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)),2) Creation,
 (SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Test.CsvTypes.Owner'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner)) MarkerCount
FROM sys.databases WHERE database_id=DB_ID();
'@ @{'@Owner'=$script:ledger.RunId} -Rows)
  if($identity.Count -ne 1 -or $identity[0].MarkerCount -ne 1 -or $identity[0].Creation -notmatch '^[A-F0-9]{18}$'){throw 'CSV_DATABASE_IDENTITY_UNKNOWN'}
  $entry.Id=[int]$identity[0].Id;$entry.Creation=$identity[0].Creation;$entry.Marker=$true;$entry.State='OWNED';Save-CsvJournal
 }finally{$connection.Dispose()}
 return $name
}

function Remove-CsvOwnedDatabase($Control,$Entry){
 if($Entry.State -eq 'DROPPED'){return}
 if(-not $Entry.Marker -or $null -eq $Entry.Id -or $null -eq $Entry.Creation){throw 'CSV_DATABASE_CLEANUP_IDENTITY_UNKNOWN'}
 $name=$Entry.Name
 if($name -notmatch '^Toolbelt_CsvTypes_[a-f0-9]{32}$'){throw 'CSV_DATABASE_CLEANUP_NAME_INVALID'}
 Invoke-CsvOwnSql $Control @"
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),@Name)
 AND CONVERT(varbinary(max),CONVERT(datetime2(7),create_date))=@Created)
 THROW 51591,N'Owned database identity changed.',2;
DECLARE @MarkerCount int;
EXEC [$name].sys.sp_executesql N'SELECT @Count=COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N''Toolbelt.Test.CsvTypes.Owner'' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner);',
 N'@Owner nvarchar(32),@Count int OUTPUT',@Owner,@MarkerCount OUTPUT;
IF @MarkerCount IS NULL OR @MarkerCount<>1 THROW 51591,N'Owned database marker changed.',3;
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',5;
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),@Name)
 AND CONVERT(varbinary(max),CONVERT(datetime2(7),create_date))=@Created)
 THROW 51591,N'Owned database identity changed before removal.',2;
DROP DATABASE [$name];
IF DB_ID(@Name) IS NOT NULL THROW 51591,N'Owned database removal not verified.',4;
"@ @{'@Id'=[int]$Entry.Id;'@Name'=$name;'@Created'=[Convert]::FromHexString($Entry.Creation);'@Owner'=$script:ledger.RunId}
 $Entry.State='DROPPED';Save-CsvJournal
}

function Remove-CsvOwnedTrust($Control,$Entry){
 if($Entry.Preexisting){
  $actual=Get-CsvTrust $Control ([Convert]::FromHexString($Entry.Hash))
  if($Entry.State -cne 'PREEXISTING' -or $null -eq $Entry.Fingerprint -or $null -eq $actual -or [string]$actual.Fingerprint -cne $Entry.Fingerprint){throw 'CSV_PREEXISTING_TRUST_CHANGED'}
  return
 }
 if($Entry.State -eq 'RESTORED'){return}
 if($Entry.State -cne 'OWNED' -or $null -eq $Entry.Fingerprint){throw 'CSV_TRUST_CLEANUP_IDENTITY_UNKNOWN'}
 # Kein Verbraucher, keine unbekannte/offline Datenbank; unmittelbar derselbe
 # Batch prüft die eigene vollständige Identität vor der administrativen Entfernung.
 Invoke-CsvSql $Control @'
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',5;
IF EXISTS(SELECT 1 FROM sys.databases WHERE state<>0) THROW 51591,N'Consumer inspection uncertain.',6;
DECLARE @Databases TABLE(Id int PRIMARY KEY,Name sysname,Created varbinary(16));
INSERT @Databases SELECT database_id,name,CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases;
DECLARE @Name sysname,@Sql nvarchar(max),@Count int;
DECLARE Consumers CURSOR LOCAL FAST_FORWARD FOR SELECT Name FROM @Databases;
OPEN Consumers;FETCH NEXT FROM Consumers INTO @Name;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Count=NULL;
 SET @Sql=N'SELECT @Count=COUNT(*) FROM '+QUOTENAME(@Name)+N'.sys.assembly_files WHERE file_id=1 AND HASHBYTES(''SHA2_512'',content)=@Hash;';
 EXEC sys.sp_executesql @Sql,N'@Hash varbinary(64),@Count int OUTPUT',@Hash,@Count OUTPUT;
 IF @Count IS NULL OR @Count<>0 THROW 51591,N'Hash consumer remains or inspection uncertain.',7;
 FETCH NEXT FROM Consumers INTO @Name;
END;
CLOSE Consumers;DEALLOCATE Consumers;
IF EXISTS(SELECT database_id,CONVERT(varbinary(max),name),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases
 EXCEPT SELECT Id,CONVERT(varbinary(max),Name),Created FROM @Databases)
 OR EXISTS(SELECT Id,CONVERT(varbinary(max),Name),Created FROM @Databases
 EXCEPT SELECT database_id,CONVERT(varbinary(max),name),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases)
 THROW 51591,N'Consumer inspection changed.',8;
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash
 AND CONVERT(varbinary(max),description)=CONVERT(varbinary(max),@Description)
 AND CONVERT(varchar(64),HASHBYTES('SHA2_256',hash+CONVERT(binary(4),ISNULL(DATALENGTH(description),-1))+ISNULL(CONVERT(varbinary(max),description),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(CONVERT(varbinary(max),create_date)),-1))+ISNULL(CONVERT(varbinary(max),create_date),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(created_by),-1))+ISNULL(CONVERT(varbinary(max),created_by),0x)),2)=@Fingerprint)
 THROW 51591,N'Owned trust identity changed.',9;
IF @Hash IS NULL OR DATALENGTH(@Hash)<>64 THROW 51591,N'Typed trust hash invalid.',12;
DECLARE @TrustHash varbinary(64)=@Hash;
EXEC sys.sp_drop_trusted_assembly @hash=@TrustHash;
IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash) THROW 51591,N'Owned trust removal not verified.',10;
'@ @{'@Hash'=[Convert]::FromHexString($Entry.Hash);'@Description'=$Entry.Description;'@Fingerprint'=$Entry.Fingerprint}
 $Entry.State='RESTORED';Save-CsvJournal
}

function Assert-CsvDisposition($Control){
 foreach($entry in $script:ledger.Databases){
  if($entry.State -cne 'DROPPED' -or $entry.Name -notmatch '^Toolbelt_CsvTypes_[a-f0-9]{32}$'){throw 'CSV_FINAL_DATABASE_STATE'}
  $rows=@(Invoke-CsvOwnSql $Control 'SELECT DB_ID(@Name) Id;' @{'@Name'=[string]$entry.Name} -Rows)
  if($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'CSV_FINAL_DATABASE_PRESENT'}
 }
 foreach($entry in $script:ledger.Trust){
  $actual=Get-CsvTrust $Control ([Convert]::FromHexString($entry.Hash))
  if($entry.Preexisting){
   if($entry.State -cne 'PREEXISTING' -or $null -eq $entry.Fingerprint -or $null -eq $actual -or [string]$actual.Fingerprint -cne $entry.Fingerprint){throw 'CSV_PREEXISTING_TRUST_CHANGED'}
  }elseif($entry.State -cne 'RESTORED' -or $null -ne $actual){throw 'CSV_FINAL_OWN_TRUST_PRESENT'}
 }
}

function Assert-CsvPins {
 foreach($path in $script:freeze.Keys){
  if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $script:freeze[$path]){throw 'CSV_SOURCE_PIN_CHANGED'}
 }
}

try{
 $repo=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
 $module=Join-Path $repo 'Modules/toolbelt.file.csv-memory'
 $JournalManifestPath=[IO.Path]::GetFullPath($JournalManifestPath)
 $repositoryPrefix=$repo.TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
 $privatePrefix=Join-Path $repositoryPrefix '.runtime/'
 if($JournalManifestPath.StartsWith($repositoryPrefix,[StringComparison]::OrdinalIgnoreCase) -and
  -not $JournalManifestPath.StartsWith($privatePrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'CSV_PRIVATE_JOURNAL_MANIFEST_REQUIRED'}
 if(-not (Test-Path -LiteralPath $JournalManifestPath -PathType Leaf) -or [IO.File]::ReadAllText($JournalManifestPath).Length -ne 0){throw 'CSV_EMPTY_OWN_JOURNAL_MANIFEST_REQUIRED'}
 if($CompatibilityLevel -gt @{'2019'=150;'2022'=160;'2025'=170}[$Version]){throw 'CSV_SCOPE_COMPATIBILITY_INVALID'}
 if((Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash -cne $ExpectedDriverSHA256.ToUpperInvariant()){throw 'CSV_DRIVER_PIN'}
 $helperPath=Join-Path $PSScriptRoot 'run-lab-local.ps1'
 $helperBytes=[IO.File]::ReadAllBytes($helperPath);$parseErrors=$null
 $tree=[Management.Automation.Language.Parser]::ParseInput([Text.Encoding]::UTF8.GetString($helperBytes).TrimStart([char]0xFEFF),[ref]$null,[ref]$parseErrors)
 if($parseErrors.Count){throw 'CSV_LAB_HELPER_PARSE'}
 foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
  $definitions=@($tree.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
  if($definitions.Count -ne 1){throw 'CSV_LAB_HELPER_AMBIGUOUS'}
  . ([scriptblock]::Create($definitions[0].Extent.Text))
 }
 $lifecyclePath=Join-Path $PSScriptRoot 'CsvLifecycle.Helpers.ps1';$lifecycleErrors=$null
 $lifecycleTree=[Management.Automation.Language.Parser]::ParseFile($lifecyclePath,[ref]$null,[ref]$lifecycleErrors)
 if($lifecycleErrors.Count -or @($lifecycleTree.EndBlock.Statements|Where-Object {$_ -isnot [Management.Automation.Language.FunctionDefinitionAst]}).Count){throw 'CSV_LIFECYCLE_HELPER_EFFECTS'}
 foreach($name in @('Get-CsvCompleteSnapshotSql','Get-CsvSnapshot','Assert-CsvCallerPrepared','Assert-CsvLockPrepared','Assert-CsvRollbackPrepared','Assert-CsvConfirmPrepared')){
  $definitions=@($lifecycleTree.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
  if($definitions.Count -ne 1){throw 'CSV_LIFECYCLE_HELPER_AMBIGUOUS'}
  . ([scriptblock]::Create($definitions[0].Extent.Text))
 }
 $prompt=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
 if(-not $prompt -or (Get-FileHash -LiteralPath $prompt -Algorithm SHA256).Hash -cne $ExpectedPromptSHA256.ToUpperInvariant() -or [string]::IsNullOrWhiteSpace([IO.File]::ReadAllText($prompt))){throw 'CSV_REVIEWED_PROMPT_REQUIRED'}
 $discovery=@(& {Resolve-LabContract} *>&1)
 $contracts=@($discovery|Where-Object {$_ -is [pscustomobject] -and $_.PSObject.Properties.Name -contains 'Contract'})
 if($contracts.Count -ne 1 -or @($discovery|Where-Object {$_ -is [Management.Automation.ErrorRecord]}).Count){throw 'CSV_LAB_SCHEMA_INVALID'}
 $targets=@(Get-LabTargetsForSelector -Contract $contracts[0].Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
 if(-not $targets.Count){throw 'CSV_EXACT_TARGET_NOT_READY'}
 if(@($DeploymentModes|Select-Object -Unique).Count -ne $DeploymentModes.Count){throw 'CSV_DUPLICATE_MODE'}
 $release=(Resolve-Path -LiteralPath $ReleaseDirectory).Path
 $binaryPath=Join-Path $release 'Toolbelt.File.CsvMemory.dll'
 $manifestPath=Join-Path $release 'Toolbelt.File.CsvMemory.trust-manifest.json'
 $binary=[IO.File]::ReadAllBytes($binaryPath);$hash=[Convert]::ToHexString([Security.Cryptography.SHA512]::HashData($binary))
 $manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
 if($hash -cne $ExpectedAssemblySHA512.ToUpperInvariant() -or $manifest.sha512 -cne $hash -or
  $manifest.sha256 -cne [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($binary)) -or
  $manifest.moduleId -cne 'toolbelt.file.csv-memory' -or $manifest.moduleVersion -cne '1.0.0' -or
  $manifest.assemblySqlName -cne 'Toolbelt_File_CsvMemory' -or $manifest.assemblyFileName -cne 'Toolbelt.File.CsvMemory.dll' -or
  $manifest.permissionSet -cne 'SAFE' -or $manifest.sqlServerHexLiteral -cne ('0x'+$hash)){throw 'CSV_ARTIFACT_PIN'}
 $artifact=[pscustomobject]@{Label='current';Hash=$hash;Bits='0x'+[Convert]::ToHexString($binary)}
 $script:freeze=@{}
 foreach($path in @($PSCommandPath,$helperPath,$lifecyclePath,$prompt,$binaryPath,$manifestPath,$contracts[0].Path,$contracts[0].SchemaPath)){$script:freeze[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
 $requiredFiles=@(Get-ChildItem -LiteralPath (Join-Path $module 'Clr') -File -Recurse | Where-Object {$_.Extension -in @('.cs','.csproj') -and $_.FullName -notmatch '[\\/](bin|obj)[\\/]'})
 foreach($directory in @('Source','Deployment')){$requiredFiles+=@(Get-ChildItem -LiteralPath (Join-Path $module $directory) -File -Filter '*.sql')}
 $requiredFiles+=@(Get-ChildItem -LiteralPath (Join-Path $module 'Scripts') -File -Filter '*.ps1')
 $requiredPaths=@($requiredFiles|ForEach-Object {[IO.Path]::GetRelativePath($module,$_.FullName).Replace([IO.Path]::DirectorySeparatorChar,[char]'/')})
 $sourcePaths=@($manifest.sourceFingerprints.path)
 if(@($sourcePaths|Sort-Object -Unique).Count -ne $sourcePaths.Count){throw 'CSV_SOURCE_MANIFEST_DUPLICATE'}
 if((($requiredPaths|Sort-Object -CaseSensitive) -join '|') -cne (($sourcePaths|Sort-Object -CaseSensitive) -join '|')){throw 'CSV_SOURCE_MANIFEST_INCOMPLETE'}
 foreach($entry in $manifest.sourceFingerprints){
  if($entry.path -match '(^[/\\]|\.\.)' -or $entry.sha256 -notmatch '^[A-Fa-f0-9]{64}$'){throw 'CSV_SOURCE_MANIFEST_PATH'}
  $path=Join-Path $module $entry.path
  if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $entry.sha256.ToUpperInvariant()){throw 'CSV_SOURCE_MANIFEST_PIN'}
  $script:freeze[$path]=$entry.sha256.ToUpperInvariant()
 }
 $packageDeploy=Join-Path $release 'Deploy.WithAssembly.sql'
 $packageVariables=@{AssemblyBits=$artifact.Bits;DeploymentMode='local';ConfirmNoExternalConsumers=1}
 if((Read-CsvSql $packageDeploy $packageVariables) -cne (Read-CsvSql (Join-Path $module 'Deployment/Deploy.sql') $packageVariables)){throw 'CSV_PACKAGED_DEPLOY_MISMATCH'}
 $script:freeze[$packageDeploy]=(Get-FileHash -LiteralPath $packageDeploy -Algorithm SHA256).Hash
 foreach($root in @((Join-Path $module 'Tests/Runtime'),(Join-Path $repo 'Modules/toolbelt.core.result-table/Source'),(Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment'))){
  foreach($file in @(Get-ChildItem -LiteralPath $root -File)){$script:freeze[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
 }
 Assert-CsvPins
}catch{$failure=Get-CsvFailure $_.Exception;Write-Output ('FAILED: CSV_PREPARATION_SQL'+$failure.SqlNumber+'_STATE'+$failure.SqlState+'_'+$failure.Reason);exit 1}

foreach($target in $targets){
 $runId=[guid]::NewGuid().ToString('N')
 $script:journal=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltCsvRestore-'+$runId+'.json')
 if((Test-Path -LiteralPath $script:journal) -or (Test-Path -LiteralPath ($script:journal+'.writing'))){throw 'CSV_JOURNAL_COLLISION'}
 $script:scopeClock=[Diagnostics.Stopwatch]::StartNew();$script:cleanupPhase=$false
 $script:ledger=[ordered]@{RunId=$runId;SelectorIdentity=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$target.key)));Platform=$Platform;Version=$Version;Patch=[string]$target.patch;CompatibilityLevel=$CompatibilityLevel;State='PREPARED';Databases=@();Trust=@();ConfigurationChanges=0;RightsChanges=0;OriginalFailure=$null;CleanupFailure=$null;DispositionVerified=$false;RuntimeTests=@('Contract.Tests.sql','Safety.Tests.sql','Lifecycle.Tests.sql');CompletedModes=@();LifecycleCasesPassed=0;DriverSHA256=$ExpectedDriverSHA256.ToUpperInvariant();AssemblySHA512=$hash}
 $script:journalHealthy=$true;$control=$null;$failed=$false;$cleanupBlocked=$false
 $capturedClock=$script:scopeClock;$capturedWork=$script:workMilliseconds
 $timeoutProvider={
  $remaining=$capturedWork-$capturedClock.ElapsedMilliseconds
  if($remaining -lt 1000){throw 'CSV_SCOPE_DEADLINE'}
  [int][Math]::Min(60,[Math]::Floor($remaining/1000))
 }.GetNewClosure()
 $capturedTimeout=$timeoutProvider
 $readBudgetProvider={param($Command)try{[void](& $capturedTimeout)}catch{try{$Command.Cancel()}catch{};throw}}.GetNewClosure()
 try{
  Save-CsvJournal
  # Ausschließlich der erzeugende Prozess meldet seine eigenen Journalpfade;
  # keine Adoption aus Verzeichnisscans oder fremden gleichzeitig laufenden Tests.
  [IO.File]::AppendAllText($JournalManifestPath,$script:journal+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
  Assert-CsvPins
  $stage='PREFLIGHT';$control=Open-CsvConnection $target 'master'
  Invoke-CsvSql $control 'SELECT @@VERSION; SELECT name,state_desc FROM sys.databases ORDER BY database_id;'
  $ready=@(Invoke-CsvSql $control @'
SELECT TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) Major,
 (SELECT CONVERT(int,value_in_use) FROM sys.configurations WHERE name=N'clr enabled') Clr,
 (SELECT CONVERT(int,value_in_use) FROM sys.configurations WHERE name=N'clr strict security') StrictSecurity,
 IS_SRVROLEMEMBER(N'sysadmin') Admin;
'@ -Rows)
  if($ready.Count -ne 1 -or $ready[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[$Version] -or $ready[0].Clr -ne 1 -or $ready[0].StrictSecurity -ne 1 -or $ready[0].Admin -ne 1){throw 'CSV_PREFLIGHT_REQUIRED'}
  $stage='EXACT_TRUST';Register-CsvTrust $control $artifact
  foreach($mode in $DeploymentModes){
   Assert-CsvPins;$stage='CREATE_'+$mode
   $database=New-CsvDatabase $control $target $mode $(if($mode -ceq 'local'){'Latin1_General_100_CS_AS'}else{'Latin1_General_100_BIN2'})
   $connection=$null
   $variables=@{DeploymentMode=$mode;ConfirmNoExternalConsumers=1;ToolbeltDatabase=$database;AssemblyBits=$artifact.Bits}
   try{
    $connection=Open-CsvConnection $target $database
    Invoke-CsvSql $control ("ALTER DATABASE [$database] SET COMPATIBILITY_LEVEL=$CompatibilityLevel;")
    $stage='DEPENDENCY_'+$mode
    Invoke-CsvBatches $connection (Read-CsvSql (Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql') $variables)
    $connection.Dispose();$connection=Open-CsvConnection $target $database
    $deploy=Read-CsvSql (Join-Path $module 'Deployment/Deploy.sql') $variables
    $uninstall=Read-CsvSql (Join-Path $module 'Deployment/Uninstall.sql') $variables
    $stage='INSTALL_'+$mode;Invoke-CsvBatches $connection $deploy
    $connection.Dispose();$connection=Open-CsvConnection $target $database
    $stage='REPEAT_'+$mode;Invoke-CsvBatches $connection $deploy
    $connection.Dispose();$connection=Open-CsvConnection $target $database
    $stage='NATIVE_'+$mode
    Invoke-CsvSql $connection @'
IF (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_file'))<>5
 THROW 51594,N'CSV slot witness failed.',1;
IF (SELECT COUNT(*) FROM sys.assembly_modules WHERE assembly_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_File_CsvMemory'))<>3
 THROW 51594,N'CSV binding witness failed.',2;
IF NOT EXISTS(SELECT 1 FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
 WHERE a.name=N'Toolbelt_File_CsvMemory' AND a.permission_set=1 AND HASHBYTES('SHA2_512',f.content)=@Hash)
 THROW 51594,N'CSV exact binary witness failed.',3;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51594,N'CSV neutral session witness failed.',4;
'@ @{'@Hash'=[Convert]::FromHexString($hash)}
    foreach($test in $ledger.RuntimeTests){
     Assert-CsvPins;$stage='API_'+$mode+'_'+$test;Write-Output ('RUNNING: '+$stage)
     Invoke-CsvBatches $connection (Read-CsvSql (Join-Path $module ('Tests/Runtime/'+$test)) $variables)
    }
    $stage='CLIENT_'+$mode
    & (Join-Path $module 'Tests/Runtime/Metadata.Tests.ps1') -Connection $connection -CommandTimeoutProvider $timeoutProvider -ReadBudgetProvider $readBudgetProvider | Out-Null
    foreach($abort in @('OFF','ON')){foreach($doomed in @($false,$true)){
     $stage='CALLER_'+$mode+'_'+$abort+'_'+$doomed
     Assert-CsvCallerPrepared $connection $deploy $uninstall $abort $doomed
     $ledger.LifecycleCasesPassed+=2;Save-CsvJournal
    }}
    $stage='LOCK_'+$mode;Assert-CsvLockPrepared $target $database $connection $deploy $uninstall
    $ledger.LifecycleCasesPassed+=2;Save-CsvJournal
    $stage='ROLLBACK_'+$mode;Assert-CsvRollbackPrepared $connection $deploy $uninstall
    $ledger.LifecycleCasesPassed+=4;Save-CsvJournal
    if($mode -ceq 'central'){
     $stage='CONSUMER';$caller=New-CsvDatabase $control $target 'caller' 'Latin1_General_100_CI_AS_SC_UTF8'
     $consumer=Open-CsvConnection $target $caller
     try{& (Join-Path $module 'Tests/Runtime/Metadata.Tests.ps1') -Connection $consumer -ToolbeltDatabase $database -CommandTimeoutProvider $timeoutProvider -ReadBudgetProvider $readBudgetProvider | Out-Null}finally{$consumer.Dispose()}
     $unconfirmed=$variables.Clone();$unconfirmed.ConfirmNoExternalConsumers=0
     $stage='CONFIRM0';Assert-CsvConfirmPrepared $connection (Read-CsvSql (Join-Path $module 'Deployment/Uninstall.sql') $unconfirmed)
     $ledger.LifecycleCasesPassed++;Save-CsvJournal
    }
    $stage='UNINSTALL_'+$mode;Invoke-CsvBatches $connection $uninstall
    Invoke-CsvSql $connection "IF EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'Toolbelt_File_CsvMemory') THROW 51594,N'CSV uninstall witness failed.',5;"
    $stage='UNINSTALL_REPEAT_'+$mode;Invoke-CsvBatches $connection $uninstall
    $ledger.CompletedModes+=@($mode);Save-CsvJournal
   }finally{if($connection){$connection.Dispose()}}
  }
  Assert-CsvPins
 }catch{$failed=$true;$ledger.OriginalFailure=Get-CsvFailure $_.Exception}
 finally{
  $script:cleanupPhase=$true
  try{
   if(-not $script:journalHealthy){throw 'CSV_JOURNAL_UNHEALTHY'}
   $ledger.State='CLEANING';Save-CsvJournal
   if($control -and $control.State -eq [Data.ConnectionState]::Open){
    $stage='DATABASE_CLEANUP';foreach($entry in $ledger.Databases){Remove-CsvOwnedDatabase $control $entry}
    if(@($ledger.Databases|Where-Object State -ne 'DROPPED').Count){throw 'CSV_DATABASE_CLEANUP_INCOMPLETE'}
    $stage='TRUST_CLEANUP';foreach($entry in $ledger.Trust){Remove-CsvOwnedTrust $control $entry}
    $stage='DISPOSITION';Assert-CsvDisposition $control;$ledger.DispositionVerified=$true
   }elseif($ledger.Databases.Count -or @($ledger.Trust|Where-Object {-not $_.Preexisting}).Count){throw 'CSV_CLEANUP_CONNECTION_UNAVAILABLE'}
   Assert-CsvPins;[void](Get-CsvCommandTimeout)
   if(-not $failed -and -not $ledger.DispositionVerified){throw 'CSV_DISPOSITION_REQUIRED'}
   $ledger.State=$(if($failed){'FAILED_CLEANED'}else{'COMPLETE'});Save-CsvJournal
  }catch{$cleanupBlocked=$true;$ledger.State='CLEANUP_BLOCKED';$ledger.CleanupFailure=Get-CsvFailure $_.Exception;try{Save-CsvJournal}catch{}}
  finally{if($control){try{$control.Dispose()}catch{$cleanupBlocked=$true;$ledger.State='CLEANUP_BLOCKED';try{Save-CsvJournal}catch{}}}}
 }
 if($cleanupBlocked){Write-Output 'FAILED: CSV_CLEANUP_BLOCKED';exit 1}
 if($failed){Write-Output ('FAILED: CSV_'+$ledger.OriginalFailure.Stage+'_SQL'+$ledger.OriginalFailure.SqlNumber+'_STATE'+$ledger.OriginalFailure.SqlState+'_'+$ledger.OriginalFailure.Reason);exit 1}
 $completed=$ledger.CompletedModes -join ','
 $consumerLabel=if('central' -cin $ledger.CompletedModes){'/consumer/Confirm0'}else{''}
 Write-Output ('PASS: CSV '+$Platform+'/'+$Version+'/'+$ledger.Patch+' CL'+$CompatibilityLevel+' modes='+$completed+$consumerLabel+' contract/safety/client/repeat/uninstall; lifecycle-cases='+$ledger.LifecycleCasesPassed+' caller/lock/rollback; owned-cleanup. Further CL/platform/MinimalRights/full ceilings NOT_EXECUTED.')
}
