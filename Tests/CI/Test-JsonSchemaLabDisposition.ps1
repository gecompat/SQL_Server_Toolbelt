[CmdletBinding()]
param([Parameter(Mandatory)][string]$JournalDirectory,
 [Parameter(Mandatory)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedJournalSHA256,
 [Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Frischer read-only Audit: keine Wiederherstellung, kein SQL-/Trust-/Labmutator.
# Labvertrag/Zugangsdaten bleiben ausschließlich im Speicher. Nur eigene
# synthetische Abwesenheit und bereits protokollierte exakte Trusttupel prüfen.
$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))+[IO.Path]::DirectorySeparatorChar
$directory=[IO.Path]::GetFullPath($JournalDirectory);$output=[IO.Path]::GetFullPath($OutputDirectory)
if(-not$directory.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)-or
 -not$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)-or(Test-Path -LiteralPath $output)){throw 'JSON_DISPOSITION_PRIVATE_SCOPE'}
$journalPath=Join-Path $directory 'Journal.private.json'
if((Get-FileHash -LiteralPath $journalPath -Algorithm SHA256).Hash-cne$ExpectedJournalSHA256.ToUpperInvariant()){throw 'JSON_DISPOSITION_JOURNAL_PIN'}
$journal=Get-Content -LiteralPath $journalPath -Raw|ConvertFrom-Json
if(-not$journal.psobject.Properties['FrozenInputs']){throw 'JSON_DISPOSITION_LEGACY_NO_CONTRACT_PIN'}
if($journal.State-cnotin@('COMPLETE','FAILED_CLEANED')-or-not$journal.PostPins-or-not$journal.DispositionVerified-or
 $journal.ConfigurationChanges-ne0-or$journal.RightsChanges-ne0){throw 'JSON_DISPOSITION_UNFINISHED_SCOPE'}
if(@($journal.Databases).Count-gt2-or@($journal.Trust).Count-gt4){throw 'JSON_DISPOSITION_UNBOUNDED_SCOPE'}
if(($journal.Platform-ceq'linux'-and($journal.Version-cne'2019'-or$journal.Patch-cne'latest'))-or
 ($journal.Platform-ceq'windows'-and($journal.Version-cne'2025'-or$journal.Patch-cne'CU8'))-or
 $journal.Platform-cnotin@('linux','windows')){throw 'JSON_DISPOSITION_TARGET_SCOPE'}
$helper=Join-Path $PSScriptRoot 'run-lab-local.ps1';$errors=$null;$tokens=$null
$tree=[Management.Automation.Language.Parser]::ParseFile($helper,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'JSON_DISPOSITION_HELPER_PARSE'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
 $definitions=@($tree.FindAll({param($node)$node-is[Management.Automation.Language.FunctionDefinitionAst]-and$node.Name-ceq$name},$true))
 if($definitions.Count-ne1){throw 'JSON_DISPOSITION_HELPER_DISCOVERY'}
 . ([scriptblock]::Create($definitions[0].Extent.Text))
}
$lab=Resolve-LabContract
$prompt=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
# Gleiche frische Vertragsbytes, keine scheinbare Abwesenheit auf einem nach
# dem Lauf ausgetauschten Ziel. Externe Pfade stehen nicht im öffentlichen Journal.
foreach($binding in @(@('Contract',$lab.Path),@('Schema',$lab.SchemaPath),@('Prompt',$prompt))){
 $expected=@($journal.FrozenInputs|Where-Object{$_.Role-ceq$binding[0]})
 if($expected.Count-ne1-or-not$binding[1]-or(Get-FileHash -LiteralPath $binding[1] -Algorithm SHA256).Hash-cne$expected[0].SHA256){throw 'JSON_DISPOSITION_ORIGINAL_CONTRACT_PIN'}
}
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$journal.Platform;Version=$journal.Version;Patch=$journal.Patch}))
if($targets.Count-ne1){throw 'JSON_DISPOSITION_EXACT_TARGET'}
$pins=@($journalPath,$helper,$lab.Path,$lab.SchemaPath,$prompt,$PSCommandPath)|ForEach-Object{[pscustomobject]@{Path=$_;Hash=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}}
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $targets[0]))
$connection=$null;$record=[ordered]@{Scope='FRESH_READ_ONLY_OWN_DISPOSITION';State='FAILED';JournalSHA256=$ExpectedJournalSHA256.ToLowerInvariant();Databases=0;Trust=0;PostPins=$false}
function Assert-Sql([string]$Text,[hashtable]$Parameters){
 $command=$connection.CreateCommand();$command.CommandText=$Text;$command.CommandTimeout=15
 try{
  foreach($name in $Parameters.Keys){
   $type=if($Parameters[$name]-is[byte[]]){[Data.SqlDbType]::VarBinary}else{[Data.SqlDbType]::NVarChar}
   $parameter=$command.Parameters.Add($name,$type,-1);$parameter.Value=$Parameters[$name]
  }
  [void]$command.ExecuteNonQuery()
 }finally{$command.Dispose()}
}
try{
 $builder['Initial Catalog']='master';$builder['Pooling']=$false;$builder['Enlist']=$false;$builder['ConnectRetryCount']=0;$builder['Connect Timeout']=15
 $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$connection.Open()
 Assert-Sql 'IF ISNULL(IS_SRVROLEMEMBER(N''sysadmin''),0)<>1 THROW 55693,N''Existing visibility required.'',1;' @{}
 foreach($entry in $journal.Databases){
  if($entry.State-cne'DROPPED'-or$entry.Name-cnotmatch'^Toolbelt_JsonSchema_[a-f0-9]{32}$'){throw 'JSON_DISPOSITION_UNKNOWN_DATABASE'}
  Assert-Sql 'IF DB_ID(@Name) IS NOT NULL THROW 55693,N''Own database still present.'',2;' @{'@Name'=$entry.Name}
  $record.Databases++
 }
 foreach($entry in $journal.Trust){
  if($entry.Hash-cnotmatch'^[a-f0-9]{128}$'){throw 'JSON_DISPOSITION_HASH'}
  if($entry.Preexisting){
   Assert-Sql 'IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash AND CONVERT(varbinary(max),description)=CONVERT(varbinary(max),@Description) AND CONVERT(varbinary(max),create_date)=@Creation AND CONVERT(varbinary(max),created_by)=CONVERT(varbinary(max),@Creator)) THROW 55693,N''Preexisting tuple changed.'',3;' @{'@Hash'=[Convert]::FromHexString($entry.Hash);'@Description'=$entry.Original.Description;'@Creation'=[Convert]::FromHexString($entry.Original.Creation);'@Creator'=$entry.Original.Creator}
  }else{
   if($entry.State-cne'RESTORED'){throw 'JSON_DISPOSITION_UNRESTORED_TRUST'}
   Assert-Sql 'IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash) THROW 55693,N''Own trust still present.'',4;' @{'@Hash'=[Convert]::FromHexString($entry.Hash)}
  }
  $record.Trust++
 }
 foreach($pin in $pins){if((Get-FileHash -LiteralPath $pin.Path -Algorithm SHA256).Hash-cne$pin.Hash){throw 'JSON_DISPOSITION_POST_PIN'}}
 $record.PostPins=$true;$record.State='COMPLETE'
}catch{throw 'JSON_DISPOSITION_READ_ONLY_AUDIT_FAILED'}finally{
 if($connection){$connection.Dispose()};$builder.Clear();$targets=$null;$lab=$null
 [void][IO.Directory]::CreateDirectory($output)
 [IO.File]::WriteAllText((Join-Path $output 'Receipt.private.json'),($record|ConvertTo-Json -Depth 4),[Text.UTF8Encoding]::new($false))
}
'PASS JSON_FRESH_READ_ONLY_DISPOSITION'
