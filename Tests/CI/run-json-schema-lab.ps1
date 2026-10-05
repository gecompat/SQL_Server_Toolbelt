[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('linux','windows')][string]$Platform,
 [Parameter(Mandatory)][ValidateSet('2019','2025')][string]$Version,
 [Parameter(Mandatory)][string]$Patch,[ValidateSet(150,160,170)][int]$CompatibilityLevel=150,
 [ValidateSet('core-schema','constructors','migration')][string]$QualificationScope='core-schema',
 [ValidateSet('local','central')][string[]]$DeploymentModes=@('local','central'),
 [ValidateSet('JsonAggregates.Contract.sql','JsonConstructors.Contract.sql','JsonGroups.Contract.sql','InstalledMetadata.Contract.sql')]
 [string[]]$ConstructorTests=@('JsonAggregates.Contract.sql','JsonConstructors.Contract.sql','JsonGroups.Contract.sql','InstalledMetadata.Contract.sql'),
 [Parameter(Mandatory)][string]$QualifiedDirectory,[Parameter(Mandatory)][string]$OutputDirectory,
 [Parameter(Mandatory)][string[]]$ApprovedTrustHashes,
 [string]$HistoricalDirectory,[string]$ApprovedHistoricalTrustHash,
 [Parameter(Mandatory)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedPromptSHA256)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)-or(Test-Path -LiteralPath $output)){throw 'JSON_SCHEMA_OUTPUT_SCOPE'}
& git -C $repo check-ignore --quiet -- $output
if($LASTEXITCODE-ne0){throw 'JSON_SCHEMA_OUTPUT_NOT_IGNORED'}
if(($Platform-ceq'linux'-and($Version-cne'2019'-or$Patch-cne'latest'-or$CompatibilityLevel-ne150))-or
 ($Platform-ceq'windows'-and($Version-cne'2025'-or$Patch-cne'CU8'))){throw 'JSON_SCHEMA_APPROVED_TARGET_SCOPE'}
if($DeploymentModes.Count-lt1-or@($DeploymentModes|Sort-Object -Unique).Count-ne$DeploymentModes.Count-or
 $ConstructorTests.Count-lt1-or@($ConstructorTests|Sort-Object -Unique).Count-ne$ConstructorTests.Count){throw 'JSON_SCHEMA_DUPLICATE_OR_EMPTY_SCOPE'}
$helper=Join-Path $PSScriptRoot 'run-lab-local.ps1';$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseFile($helper,[ref]$null,[ref]$errors)
if($errors.Count){throw 'JSON_SCHEMA_HELPER_PARSE'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
 $definitions=@($tree.FindAll({param($node)$node-is[Management.Automation.Language.FunctionDefinitionAst]-and$node.Name-ceq$name},$true))
 if($definitions.Count-ne1){throw 'JSON_SCHEMA_HELPER_DISCOVERY'}
 . ([scriptblock]::Create($definitions[0].Extent.Text))
}
$prompt=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
if(-not$prompt-or(Get-FileHash -LiteralPath $prompt -Algorithm SHA256).Hash-cne$ExpectedPromptSHA256.ToUpperInvariant()){throw 'JSON_SCHEMA_REVIEWED_PROMPT_PIN'}
$lab=Resolve-LabContract
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
if($targets.Count-ne1){throw 'JSON_SCHEMA_EXACT_SINGLE_TARGET_REQUIRED'}
$target=$targets[0]
$registryPath=Join-Path $repo 'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'
$registry=Get-Content -LiteralPath $registryPath -Raw|ConvertFrom-Json
$expected=@($registry.artifacts|ForEach-Object{$_.Fields.binarySha512.ToLowerInvariant()}|Sort-Object -CaseSensitive)
$approved=@($ApprovedTrustHashes|ForEach-Object{$_.ToLowerInvariant()}|Sort-Object -CaseSensitive)
if($approved.Count-ne3-or($approved-join'|')-cne($expected-join'|')){throw 'JSON_SCHEMA_EXACT_TRUST_OPT_IN_REQUIRED'}
if($QualificationScope-ceq'migration'){
 $historical=[IO.Path]::GetFullPath($HistoricalDirectory)
 if(-not$historical.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'JSON_SCHEMA_HISTORICAL_SCOPE'}
 $historicalReceipt=Get-Content -LiteralPath (Join-Path $historical 'Receipt.private.json') -Raw|ConvertFrom-Json
 $historicalRow=(Get-Content -LiteralPath (Join-Path $repo 'Modules/toolbelt.json.constructors/Documentation/KNOWN_CLR_ARTIFACTS.json') -Raw|ConvertFrom-Json).artifacts[0]
 if($historicalReceipt.status-cne'COMPLETE'-or$historicalReceipt.scope-cne'GENUINE_KNOWN_CONSTRUCTOR12_ONLY'-or
  $historicalReceipt.revision-cne'46b2f078662a3203a8da67bfe331b33607962082'-or
  $historicalReceipt.artifactId-cne$historicalRow.ArtifactId-or
  $ApprovedHistoricalTrustHash.ToLowerInvariant()-cne$historicalRow.Fields.binarySha512){throw 'JSON_SCHEMA_HISTORICAL_QUALIFICATION'}
 $historicalDll=Join-Path $historical 'genuine-source/Clr/bin/Release/Toolbelt.JsonConstructors.dll'
 if((Get-FileHash -LiteralPath $historicalDll -Algorithm SHA512).Hash.ToLowerInvariant()-cne$historicalRow.Fields.binarySha512){throw 'JSON_SCHEMA_HISTORICAL_BINARY'}
 $expected+=@($historicalRow.Fields.binarySha512)
}
[void][IO.Directory]::CreateDirectory($output)
$pinPaths=@($PSCommandPath,$helper,$prompt,$lab.Path,$lab.SchemaPath)
foreach($module in @('toolbelt.json.core','toolbelt.json.schema','toolbelt.json.constructors','toolbelt.core.result-table')){
 $pinPaths+=@(Get-ChildItem -LiteralPath (Join-Path $repo ('Modules/'+$module)) -Recurse -File|Where-Object{$_.FullName-notmatch '[\\/](bin|obj|__pycache__)[\\/]'}|ForEach-Object FullName)
}
$pins=@($pinPaths|Sort-Object -Unique|ForEach-Object{[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
if($QualificationScope-ceq'migration'){
 foreach($pin in $historicalReceipt.sourcePins){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash.ToLowerInvariant()-cne$pin.sha256){throw 'JSON_SCHEMA_HISTORICAL_SOURCE_DRIFT'}}
 $historicalInputs=@($historicalReceipt.sourcePins|ForEach-Object path)+@($historicalDll,(Join-Path $historical 'Receipt.private.json'))
 $pins+=@($historicalInputs|ForEach-Object{[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
}
function Assert-Pins {foreach($pin in $pins){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash-cne$pin.sha256){throw 'JSON_SCHEMA_INPUT_DRIFT'}}}
$packages=@{}
foreach($module in @('core','constructors','schema')){
 $managed=switch($module){'core'{'Core'};'constructors'{'Constructors'};'schema'{'Schema'}}
 $destination=Join-Path $output ('packages/'+$module)
 & (Join-Path $repo 'Modules/toolbelt.json.core/Scripts/New-JsonClosureRelease.ps1') -ModuleId ('toolbelt.json.'+$module) -AssemblyPath (Join-Path $QualifiedDirectory ('Toolbelt.Json'+$managed+'.dll')) -CoreAssemblyPath (Join-Path $QualifiedDirectory 'Toolbelt.JsonCore.dll') -OutputDirectory $destination | Out-Null
 $packages[$module]=$destination
}
if($QualificationScope-ceq'migration'){
 $packages['historical12']=Join-Path $output 'packages/historical12'
 & (Join-Path $historical 'genuine-source/Scripts/New-ClrReleaseArtifacts.ps1') -AssemblyPath $historicalDll -OutputDirectory $packages['historical12'] | Out-Null
}
$packagePinPaths=@(Get-ChildItem -LiteralPath (Join-Path $output 'packages') -Recurse -File|ForEach-Object FullName)
$pins+=@($packagePinPaths|ForEach-Object{[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
$repositoryPrefix=[IO.Path]::GetFullPath($repo)+[IO.Path]::DirectorySeparatorChar
$frozenInputs=@(foreach($pin in $pins){
 if($pin.path.StartsWith($repositoryPrefix,[StringComparison]::OrdinalIgnoreCase)){
  [ordered]@{Role='RepositoryOrOwnPackage';Path=$pin.path.Substring($repositoryPrefix.Length).Replace('\','/');SHA256=$pin.sha256}
 }else{
  $role=if($pin.path-ceq$prompt){'Prompt'}elseif($pin.path-ceq$lab.Path){'Contract'}elseif($pin.path-ceq$lab.SchemaPath){'Schema'}else{throw 'JSON_SCHEMA_EXTERNAL_PIN_ROLE'}
  [ordered]@{Role=$role;SHA256=$pin.sha256}
 }
})
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false;$stage='PREPARATION'
$ledger=[ordered]@{Scope=$QualificationScope;State='PREPARED';RunId=[guid]::NewGuid().ToString('N');
 Platform=$Platform;Version=$Version;Patch=$Patch;CompatibilityLevel=$CompatibilityLevel;
 Databases=@();Trust=@();ConfigurationChanges=0;RightsChanges=0;CompletedModes=@();CompletedFixtures=@();
 OriginalFailure=$null;CleanupFailure=$null;PostPins=$false;DispositionVerified=$false;FrozenInputs=$frozenInputs;LastFixtureWitness=$null}
function Save-Journal {
 $temporary=Join-Path $output 'Journal.private.writing';$final=Join-Path $output 'Journal.private.json'
 [IO.File]::WriteAllText($temporary,($ledger|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
 [IO.File]::Move($temporary,$final,$true)
}
function Timeout {
 # Große unveränderte Constructor-Fixtures umfassen 16 MiB und 100000 Einträge.
 # Endliche Gesamt-/Commandbudgets lassen zusätzlich einen eigenen Cleanup-Scope.
 $remaining=$(if($cleanup){if($QualificationScope-in@('constructors','migration')){660000L}else{110000L}}elseif($QualificationScope-in@('constructors','migration')){600000L}else{60000L})-$clock.ElapsedMilliseconds
 if($remaining-lt1000){throw 'JSON_SCHEMA_SCOPE_DEADLINE'}
 $commandLimit=if(-not$cleanup-and$QualificationScope-in@('constructors','migration')){300}else{60}
 return [int][Math]::Min($commandLimit,[Math]::Floor($remaining/1000))
}
function Open-Connection([string]$Database){
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $target))
 try{
  $builder['Initial Catalog']=$Database;$builder['Pooling']=$false;$builder['Enlist']=$false;$builder['ConnectRetryCount']=0;$builder['Connect Timeout']=Timeout
  $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
  try{$connection.Open();return $connection}catch{$connection.Dispose();throw}
 }finally{$builder.Clear()}
}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){
 $command=$Connection.CreateCommand();$command.CommandTimeout=Timeout;$command.CommandText=$Text;$reader=$null
 try{
  foreach($name in $Parameters.Keys){
   $value=$Parameters[$name]
   $type=if($value-is[byte[]]){[Data.SqlDbType]::VarBinary}elseif($value-is[int]){[Data.SqlDbType]::Int}else{[Data.SqlDbType]::NVarChar}
   $parameter=$command.Parameters.Add($name,$type,$(if($type-eq[Data.SqlDbType]::Int){4}else{-1}));$parameter.Value=$value
  }
  $reader=$command.ExecuteReader();$answer=[Collections.Generic.List[object]]::new()
  do{
   while($reader.Read()){
    [void](Timeout)
    if($Rows){$row=[ordered]@{};for($column=0;$column-lt$reader.FieldCount;$column++){$row[$reader.GetName($column)]=$reader.GetValue($column)};$answer.Add([pscustomobject]$row)}
   }
  }while($reader.NextResult())
  if($Rows){return $answer.ToArray()}
 }finally{if($reader){$reader.Dispose()};$command.Dispose()}
}
function Batches($Connection,[string]$Text){
 foreach($batch in [regex]::Split($Text,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){if(-not[string]::IsNullOrWhiteSpace($batch)){Sql $Connection $batch}}
}
function Read-Template([string]$Path,[string]$Mode,[int]$Depth=0){
 if($Depth-gt8){throw 'JSON_SCHEMA_TEMPLATE_DEPTH'}
 $full=[IO.Path]::GetFullPath($Path)
 if($full-cnotin$pinPaths){throw 'JSON_SCHEMA_TEMPLATE_SOURCE'}
 $text=[IO.File]::ReadAllText($full)
 $text=[regex]::Replace($text,'(?m)^:r (.+)\r?$',{param($match) Read-Template (Join-Path (Split-Path -Parent $full) $match.Groups[1].Value.Trim()) $Mode ($Depth+1)})
 return [regex]::Replace($text.Replace('$(DeploymentMode)',$Mode),'(?m)^:On Error exit\r?$','')
}
function Product-Sql([string]$Module,[string]$Action,[string]$Mode){
 $file=if($Action-ceq'Deploy'){'Deploy.WithAssembly.sql'}else{'Uninstall.Expanded.sql'}
 $text=[IO.File]::ReadAllText((Join-Path $packages[$Module] $file)).Replace('$(DeploymentMode)',$Mode).Replace('$(ConfirmNoExternalConsumers)','1')
 $text=[regex]::Replace($text,'(?m)^:On Error exit\r?$','')
 if($text-match'(?m)^:|\$\('){throw 'JSON_SCHEMA_PACKAGE_DIRECTIVE'}
 return $text
}
function Reject($Connection,[string]$Text,[int]$Expected){
 $rejected=$false
 try{Batches $Connection $Text}catch{
  $error=$_.Exception;while($error.InnerException){$error=$error.InnerException}
  if($error-isnot[Data.SqlClient.SqlException]-or$error.Number-ne$Expected-or$error.State-ne1){throw}
  $rejected=$true
 }
 if(-not$rejected){throw 'JSON_SCHEMA_EXPECTED_REJECTION'}
}
$control=$null;$failed=$false
try{
 Save-Journal;Assert-Pins;$stage='PREFLIGHT';$control=Open-Connection 'master'
 Sql $control 'SELECT @@VERSION; SELECT name,state_desc FROM sys.databases ORDER BY database_id;'
 Sql $control @'
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1
 OR NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
 OR NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
 THROW 55692,N'Existing CLR configuration/rights required.',1;
'@
 $stage='EXACT_TRUST'
 foreach($hash in $expected){
  $bytes=[Convert]::FromHexString($hash);$description='Toolbelt.JsonClosure.Test.'+$ledger.RunId+'.'+$hash.Substring(0,12)
  $before=@(Sql $control 'SELECT CONVERT(varchar(32),CONVERT(varbinary(max),create_date),2) Creation,created_by Creator,description Description FROM sys.trusted_assemblies WHERE hash=@Hash;' @{'@Hash'=$bytes} -Rows)
  $entry=[ordered]@{Hash=$hash;Preexisting=($before.Count-eq1);State='UNCHANGED';Description=$description;Creation=$null;Creator=$null;
   Original=$(if($before.Count-eq1){[ordered]@{Description=[string]$before[0].Description;Creation=[string]$before[0].Creation;Creator=[string]$before[0].Creator}}else{$null})}
  $ledger.Trust+=@($entry);Save-Journal
  if($before.Count-gt1){throw 'JSON_SCHEMA_TRUST_DUPLICATE'}
  if($before.Count-eq0){
   $entry.State='ADDING';Save-Journal
   Sql $control 'IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash) THROW 55692,N''Trust changed before addition.'',2; DECLARE @ExactHash varbinary(64)=@Hash,@ExactDescription nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@ExactHash,@description=@ExactDescription;' @{'@Hash'=$bytes;'@Description'=$description}
   $after=@(Sql $control 'SELECT CONVERT(varchar(32),CONVERT(varbinary(max),create_date),2) Creation,created_by Creator,description Description FROM sys.trusted_assemblies WHERE hash=@Hash;' @{'@Hash'=$bytes} -Rows)
   if($after.Count-ne1-or$after[0].Description-cne$description){throw 'JSON_SCHEMA_TRUST_IDENTITY'}
   $entry.Creation=[string]$after[0].Creation;$entry.Creator=[string]$after[0].Creator;$entry.State='OWNED';Save-Journal
  }
 }
 foreach($mode in $DeploymentModes){
  $stage='DATABASE_'+$mode;$name='Toolbelt_JsonSchema_'+[guid]::NewGuid().ToString('N')
  $entry=[ordered]@{Name=$name;State='CREATING';Id=$null;Creation=$null;Marker=$false};$ledger.Databases+=@($entry);Save-Journal
  Sql $control ("IF DB_ID(N'$name') IS NOT NULL THROW 55692,N'Synthetic collision.',3; CREATE DATABASE [$name] COLLATE Latin1_General_100_BIN2;")
  $connection=Open-Connection $name
  $capturedLedger=$ledger
  $witnessHandler={param($sender,$eventArgs)
   if($eventArgs.Message-cmatch'^JSON_CONSTRUCTOR_PHASE_[A-Z0-9_]+$'){$capturedLedger.LastFixtureWitness=$eventArgs.Message}
  }.GetNewClosure()
  $connection.add_InfoMessage($witnessHandler)
  try{
   Sql $connection 'DECLARE @Value nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Test.JsonSchema.Owner'',@value=@Value; SELECT DB_ID() Id,CONVERT(varchar(32),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)),2) Creation FROM sys.databases WHERE database_id=DB_ID();' @{'@Owner'=$ledger.RunId}
   $identity=@(Sql $connection 'SELECT DB_ID() Id,CONVERT(varchar(32),CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)),2) Creation FROM sys.databases WHERE database_id=DB_ID();' -Rows)
   if($identity.Count-ne1){throw 'JSON_SCHEMA_DATABASE_IDENTITY'}
   $entry.Id=[int]$identity[0].Id;$entry.Creation=[string]$identity[0].Creation;$entry.Marker=$true;$entry.State='OWNED';Save-Journal
   Sql $control ("ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$CompatibilityLevel;")
   $stage='RESULTTABLE_'+$mode
   Batches $connection (Read-Template (Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql') $mode)
   $stage='CORE_'+$mode;Batches $connection (Product-Sql 'core' 'Deploy' $mode)
   Batches $connection (Product-Sql 'core' 'Deploy' $mode)
   if($QualificationScope-in@('constructors','migration')){
    if($QualificationScope-ceq'migration'){
     $stage='HISTORICAL12_'+$mode
     Batches $connection (Product-Sql 'historical12' 'Deploy' $mode)
     Sql $connection 'IF (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N''toolbelt_json'') AND type IN(''P'',''AF'',''FT''))<>8 OR EXISTS(SELECT 1 FROM sys.assembly_references WHERE assembly_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N''Toolbelt_JsonConstructors'') AND referenced_assembly_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N''Toolbelt_JsonCore'')) THROW 55692,N''Genuine historical starting state missing.'',13;'
     foreach($fixture in @('JsonAggregates.Contract.sql','JsonGroups.Contract.sql')){
      Batches $connection ([IO.File]::ReadAllText((Join-Path $repo ('Modules/toolbelt.json.constructors/Tests/Runtime/'+$fixture))))
      $ledger.CompletedFixtures+=@($mode+'/historical12/'+$fixture)
     }
     Reject $connection (Product-Sql 'schema' 'Deploy' $mode) 55633
     # Die vollständigen Identitäts-/Berechtigungstupel bleiben nur im Speicher.
     # Auch ein leerer Grantbestand wird exakt geprüft; dies ist kein Lowpriv-Nachweis.
     $identitySql=@'
SELECT N'procedure' Kind,object_id Id,ISNULL(principal_id,-1) Owner,name Name FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json') AND type='P'
UNION ALL SELECT N'clr-owner',0,COALESCE(o.principal_id,s.principal_id),o.name FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE s.name=N'toolbelt_json' AND o.type IN('AF','FT')
UNION ALL SELECT N'assembly-owner',0,principal_id,name FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors'
ORDER BY Kind,Name;
SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions
WHERE (class=1 AND major_id IN(SELECT object_id FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json')))
 OR (class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors')) ORDER BY class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state;
'@
     $beforeMigration=@(Sql $connection $identitySql -Rows)|ConvertTo-Json -Compress -Depth 4
     $rollbackStateSql=@'
SELECT N'object' Kind,object_id Id,ISNULL(principal_id,-1) Owner,name Name FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json') AND type IN('P','AF','FT') ORDER BY name;
SELECT a.assembly_id,a.principal_id,CONVERT(varchar(128),HASHBYTES(N'SHA2_512',f.content),2) Hash FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_JsonConstructors';
SELECT class,major_id,minor_id,name,CONVERT(varchar(8000),CONVERT(varbinary(8000),value),2) ValueBytes FROM sys.extended_properties WHERE
 (class=0 AND name LIKE N'Toolbelt.Module.toolbelt.json.constructors.%') OR
 (class=1 AND major_id IN(SELECT object_id FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json'))) OR
 (class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors')) ORDER BY class,major_id,minor_id,name;
'@
     $beforeRollback=@(Sql $connection $rollbackStateSql -Rows)|ConvertTo-Json -Compress -Depth 4
     $faultSql=Product-Sql 'constructors' 'Deploy' $mode
     $needle='  SET @AssemblyId=NULL;'
     if(([regex]::Matches($faultSql,[regex]::Escape($needle))).Count-ne1){throw 'JSON_SCHEMA_MIGRATION_FAULT_ANCHOR'}
     $faultSql=$faultSql.Replace($needle,"  THROW 53691,N'Synthetic migration rollback after own DROP.',1;"+[Environment]::NewLine+$needle)
     Reject $connection $faultSql 53691
     $afterRollback=@(Sql $connection $rollbackStateSql -Rows)|ConvertTo-Json -Compress -Depth 4
     if($beforeRollback-cne$afterRollback){throw 'JSON_SCHEMA_MIGRATION_ROLLBACK_CHANGED_START'}
     $ledger.CompletedFixtures+=@($mode+'/post-drop-rollback-exact-start')
     # Zusätzliche fremde Annotation muss vor dem ersten Austausch abweisen.
     Sql $connection 'EXEC sys.sp_addextendedproperty @name=N''Synthetic.Migration.Sentinel'',@value=N''unchanged'',@level0type=N''ASSEMBLY'',@level0name=N''Toolbelt_JsonConstructors'';'
     $beforeDrift=@(Sql $connection $rollbackStateSql -Rows)|ConvertTo-Json -Compress -Depth 4
     Reject $connection (Product-Sql 'constructors' 'Deploy' $mode) 53622
     $afterDrift=@(Sql $connection $rollbackStateSql -Rows)|ConvertTo-Json -Compress -Depth 4
     if($beforeDrift-cne$afterDrift){throw 'JSON_SCHEMA_MIGRATION_ANNOTATION_MUTATED'}
     Sql $connection 'EXEC sys.sp_dropextendedproperty @name=N''Synthetic.Migration.Sentinel'',@level0type=N''ASSEMBLY'',@level0name=N''Toolbelt_JsonConstructors'';'
     $ledger.CompletedFixtures+=@($mode+'/additional-assembly-metadata-preserved-reject')
    }
    $stage='CONSTRUCTORS_'+$mode
    Batches $connection (Product-Sql 'constructors' 'Deploy' $mode)
    if($QualificationScope-ceq'migration'){
     $connection.Dispose();$connection=Open-Connection $name
     $connection.add_InfoMessage($witnessHandler)
     $afterMigration=@(Sql $connection $identitySql -Rows)|ConvertTo-Json -Compress -Depth 4
     if($beforeMigration-cne$afterMigration){throw 'JSON_SCHEMA_MIGRATION_CHANGED_PROCEDURES_OWNERS_OR_PERMISSIONS'}
     Sql $connection 'IF NOT EXISTS(SELECT 1 FROM sys.assembly_references WHERE assembly_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N''Toolbelt_JsonConstructors'') AND referenced_assembly_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N''Toolbelt_JsonCore'')) THROW 55692,N''Migrated core reference missing.'',14;'
     $ledger.CompletedFixtures+=@($mode+'/genuine12-13-procedure-identities-owners-permissions')
     $stage='MIGRATED_SCHEMA_'+$mode
     Batches $connection (Product-Sql 'schema' 'Deploy' $mode)
     Batches $connection ([IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.json.schema/Tests/Runtime/Contract.Tests.sql')))
     Batches $connection (Product-Sql 'schema' 'Uninstall' $mode)
     $ledger.CompletedFixtures+=@($mode+'/migrated-schema-26-cases')
    }
    Batches $connection (Product-Sql 'constructors' 'Deploy' $mode)
    foreach($fixture in $ConstructorTests){
     $stage='CONSTRUCTORS_'+$mode+'_'+$fixture
     Batches $connection ([IO.File]::ReadAllText((Join-Path $repo ('Modules/toolbelt.json.constructors/Tests/Runtime/'+$fixture))))
     $ledger.CompletedFixtures+=@($mode+'/'+$fixture);Save-Journal
    }
    $stage='CONSTRUCTORS_UNINSTALL_'+$mode
    Reject $connection (Product-Sql 'core' 'Uninstall' $mode) 55626
    $coreBefore=@(Sql $connection 'SELECT assembly_id Id FROM sys.assemblies WHERE name=N''Toolbelt_JsonCore'';' -Rows)
    Batches $connection (Product-Sql 'constructors' 'Uninstall' $mode)
    Batches $connection (Product-Sql 'constructors' 'Uninstall' $mode)
    $coreAfter=@(Sql $connection 'SELECT assembly_id Id FROM sys.assemblies WHERE name=N''Toolbelt_JsonCore'';' -Rows)
    if($coreBefore.Count-ne1-or$coreAfter.Count-ne1-or$coreBefore[0].Id-ne$coreAfter[0].Id){throw 'JSON_SCHEMA_CONSTRUCTOR_UNINSTALL_CHANGED_CORE'}
    Batches $connection (Product-Sql 'core' 'Uninstall' $mode)
    Batches $connection (Product-Sql 'core' 'Uninstall' $mode)
    $ledger.CompletedModes+=@($mode);Save-Journal
    continue
   }
   $stage='SCHEMA_'+$mode;Batches $connection (Product-Sql 'schema' 'Deploy' $mode)
   Batches $connection (Product-Sql 'schema' 'Deploy' $mode)
   $stage='API_'+$mode
   foreach($fixture in @('Contract.Tests.sql','Safety.Tests.sql')){
    $stage='API_'+$mode+'_'+$fixture
    Batches $connection ([IO.File]::ReadAllText((Join-Path $repo ('Modules/toolbelt.json.schema/Tests/Runtime/'+$fixture))))
    $ledger.CompletedFixtures+=@($mode+'/'+$fixture);Save-Journal
   }
   $stage='METADATA_'+$mode
   & (Join-Path $repo 'Modules/toolbelt.json.schema/Tests/Runtime/Metadata.Tests.ps1') -Connection $connection | Out-Null
   $stage='LIFECYCLE_'+$mode;Reject $connection (Product-Sql 'core' 'Uninstall' $mode) 55626
   Sql $connection 'CREATE PROCEDURE dbo.SchemaConsumer AS EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;'
   Reject $connection (Product-Sql 'schema' 'Uninstall' $mode) 55636
   Sql $connection 'DROP PROCEDURE dbo.SchemaConsumer;'
   $coreBefore=@(Sql $connection 'SELECT a.assembly_id Id,CONVERT(varchar(128),HASHBYTES(N''SHA2_512'',f.content),2) Hash FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N''Toolbelt_JsonCore'';' -Rows)
   Batches $connection (Product-Sql 'schema' 'Uninstall' $mode)
   $coreAfter=@(Sql $connection 'SELECT a.assembly_id Id,CONVERT(varchar(128),HASHBYTES(N''SHA2_512'',f.content),2) Hash FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N''Toolbelt_JsonCore'';' -Rows)
   if($coreBefore.Count-ne1-or$coreAfter.Count-ne1-or$coreBefore[0].Id-ne$coreAfter[0].Id-or$coreBefore[0].Hash-cne$coreAfter[0].Hash){throw 'JSON_SCHEMA_UNINSTALL_CHANGED_CORE'}
   Batches $connection (Product-Sql 'schema' 'Uninstall' $mode)
   Batches $connection (Product-Sql 'core' 'Uninstall' $mode)
   Batches $connection (Product-Sql 'core' 'Uninstall' $mode)
   Sql $connection 'IF EXISTS(SELECT 1 FROM sys.assemblies WHERE name IN(N''Toolbelt_JsonCore'',N''Toolbelt_JsonSchema'')) OR OBJECT_ID(N''toolbelt_json.USP_ValidateJsonSchema'') IS NOT NULL THROW 55692,N''Own lifecycle disposition failed.'',4;'
   $ledger.CompletedModes+=@($mode);Save-Journal
  }finally{if($connection){$connection.Dispose()}}
 }
 $ledger.State='TESTS_COMPLETE';Save-Journal
}catch{
 $failed=$true;$error=$_.Exception;$sqlNumber=0;$sqlState=0;$reason='LOCAL_FAILURE'
 while($error){
  if($error-is[Data.SqlClient.SqlException]){
   $sqlNumber=$error.Number;$sqlState=$error.State
   if($sqlNumber-in@(6552,515,213,55623)){[IO.File]::WriteAllText((Join-Path $output 'BindingFailure.private.txt'),$error.Message)}
  }
  if($error.Message-cmatch'^JSON_SCHEMA_[A-Z0-9_]+$'){$reason=$error.Message};$error=$error.InnerException
 }
 $ledger.OriginalFailure=[ordered]@{Stage=$stage;SqlNumber=$sqlNumber;SqlState=$sqlState;Reason=$reason};Save-Journal
}finally{
 $cleanup=$true
 try{
  if(-not$control){$control=Open-Connection 'master'}
  foreach($entry in $ledger.Databases){
   if(-not$entry.Marker-or$entry.State-cne'OWNED'-or$entry.Name-notmatch'^Toolbelt_JsonSchema_[a-f0-9]{32}$'){throw 'JSON_SCHEMA_CLEANUP_UNKNOWN_DATABASE'}
   $name=$entry.Name
   Sql $control @"
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 55692,N'Cleanup visibility required.',5;
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=@Id AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),@Name) AND CONVERT(varbinary(max),CONVERT(datetime2(7),create_date))=@Creation) THROW 55692,N'Own database identity changed.',6;
DECLARE @Count int;
EXEC [$name].sys.sp_executesql N'SELECT @Count=COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N''Test.JsonSchema.Owner'' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner);',N'@Owner nvarchar(32),@Count int OUTPUT',@Owner,@Count OUTPUT;
IF ISNULL(@Count,0)<>1 THROW 55692,N'Own marker changed.',7;
DROP DATABASE [$name];
IF DB_ID(@Name) IS NOT NULL THROW 55692,N'Own removal failed.',8;
"@ @{'@Id'=[int]$entry.Id;'@Name'=$name;'@Creation'=[Convert]::FromHexString($entry.Creation);'@Owner'=$ledger.RunId}
   $entry.State='DROPPED';Save-Journal
  }
  foreach($entry in $ledger.Trust){
   if($entry.Preexisting){
    Sql $control 'IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash AND CONVERT(varbinary(max),description)=CONVERT(varbinary(max),@Description) AND CONVERT(varbinary(max),create_date)=@Creation AND CONVERT(varbinary(max),created_by)=CONVERT(varbinary(max),@Creator)) THROW 55692,N''Preexisting trust disposition changed.'',12;' @{'@Hash'=[Convert]::FromHexString($entry.Hash);'@Description'=$entry.Original.Description;'@Creation'=[Convert]::FromHexString($entry.Original.Creation);'@Creator'=$entry.Original.Creator}
    continue
   }
   if($entry.State-ceq'ADDING'){
    $present=@(Sql $control 'SELECT COUNT(*) Present FROM sys.trusted_assemblies WHERE hash=@Hash;' @{'@Hash'=[Convert]::FromHexString($entry.Hash)} -Rows)
    if($present.Count-eq1-and$present[0].Present-eq0){$entry.State='RESTORED';Save-Journal;continue}
   }
   if($entry.State-cne'OWNED'){throw 'JSON_SCHEMA_CLEANUP_UNKNOWN_TRUST'}
   Sql $control @'
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash AND CONVERT(varbinary(max),description)=CONVERT(varbinary(max),@Description) AND CONVERT(varbinary(max),create_date)=@Creation AND CONVERT(varbinary(max),created_by)=CONVERT(varbinary(max),@Creator)) THROW 55692,N'Own trust identity changed.',9;
DECLARE @ExactHash varbinary(64)=@Hash;
EXEC sys.sp_drop_trusted_assembly @hash=@ExactHash;
IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash) THROW 55692,N'Own trust removal not verified.',10;
'@ @{'@Hash'=[Convert]::FromHexString($entry.Hash);'@Description'=$entry.Description;'@Creation'=[Convert]::FromHexString($entry.Creation);'@Creator'=$entry.Creator}
   $entry.State='RESTORED';Save-Journal
  }
  foreach($entry in $ledger.Databases){Sql $control 'IF DB_ID(@Name) IS NOT NULL THROW 55692,N''Fresh own database absence failed.'',11;' @{'@Name'=$entry.Name}}
  Assert-Pins;$ledger.PostPins=$true;$ledger.DispositionVerified=$true;$ledger.State=if($failed){'FAILED_CLEANED'}else{'COMPLETE'};Save-Journal
 }catch{$failed=$true;$ledger.CleanupFailure='JSON_SCHEMA_CLEANUP_REQUIRES_REVIEW';$ledger.State='CLEANUP_BLOCKED';Save-Journal}
 if($control){$control.Dispose()};$target=$null;$targets=$null;$lab=$null
}
if($failed){Write-Output ('FAILED JSON_SCHEMA '+($ledger.OriginalFailure|ConvertTo-Json -Compress));exit 1}
'PASS JSON_SCHEMA_NATIVE '+$QualificationScope+' '+$Platform+' SQL'+$Version+' '+$Patch+' CL'+$CompatibilityLevel+' MODES '+$DeploymentModes.Count+' CLEANUP_COMPLETE'
