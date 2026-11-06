# Tatsächliche komprimierte Entry-/Ausgabegrenzen, keine Quotenänderung.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,1)][int]$CaseIndex,[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false;$ledger=$null;$journal=$null;$failure=$null;$control=$null;$stage='ADMISSION'
$connections=[Collections.Generic.List[object]]::new();$locks=[Collections.Generic.List[object]]::new()
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
$nodes=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($errors.Count-or$nodes.Count-ne1){throw 'ZIP_ENTRY_LIMIT_HELPER_PARSE'};. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @('Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql','Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
. (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')
function Read-ZipEntryLimitTrustSnapshot($Control){@(Invoke-ReleaseSql $Control 'SELECT CONVERT(varchar(128),hash,2) Hash,description,CONVERT(varchar(32),CONVERT(varbinary(max),create_date),2) Created,created_by FROM sys.trusted_assemblies ORDER BY hash;' -Rows)|ConvertTo-Json -Depth 4 -Compress}
function Read-ZipEntryLimitObservedTarget($Control){
 $actual=@(Invoke-ReleaseSql $Control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform;" -Rows)
 if($actual.Count-ne1-or$actual[0].Major-ne@{'2019'=15;'2025'=17}[[string]$case.Version]-or$actual[0].Platform-ine$case.Platform){throw 'ZIP_ENTRY_LIMIT_ACTUAL_TARGET'}
 return $actual[0]
}
function Read-ZipEntryLimitProduct($Connection){
 @(Invoke-ReleaseSql $Connection "SELECT o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash,a.assembly_id,a.assembly_class,a.assembly_method FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id LEFT JOIN sys.assembly_modules a ON a.object_id=o.object_id WHERE o.is_ms_shipped=0 ORDER BY o.object_id;SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1 ORDER BY a.name;" -Rows)|ConvertTo-Json -Depth 4 -Compress
}
function Assert-ZipEntryLimitFixtureFiles{
 foreach($key in @('compressed_cap','compressed_overflow','output_cap','output_overflow')){
  $f=$fixtures.fixtures.$key;$path=Assert-ReleasePrivatePath $f.path
  $stream=[IO.File]::Open($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read);$locks.Add($stream)
  $hash=[Security.Cryptography.SHA256]::Create()
  try{$actual=[Convert]::ToHexString($hash.ComputeHash($stream))}finally{$hash.Dispose()}
  if($stream.Length-ne$f.size-or$f.sha256-cnotmatch'^[A-F0-9]{64}$'-or$actual-cne$f.sha256){throw 'ZIP_ENTRY_LIMIT_FIXTURE_DRIFT'}
 }
}
function Invoke-ZipEntryLimitProbe($Connection,[string]$Key){
 $f=$fixtures.fixtures.$Key;$source=[IO.File]::OpenRead($f.path)
 $cmd=$Connection.CreateCommand();$reader=$null;$rows=[Collections.Generic.List[object]]::new()
 try{
  $cmd.CommandTimeout=Get-ReleaseTimeout
  # Public ResultTable route; retain actual payload on SQL and verify its digest.
  $cmd.CommandText=@'
CREATE TABLE #ZipEntryBoundary(EntryName nvarchar(1024) NOT NULL,CompressedBytes bigint NOT NULL,UncompressedBytes bigint NOT NULL,CompressionMethod int NOT NULL,Crc32 int NULL,IsEncrypted bit NOT NULL,EntryPayload varbinary(max) NULL);
DECLARE @Error int=NULL,@State int=NULL,@Message nvarchar(4000)=NULL;
BEGIN TRY
 EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@Input,@EntryName=N'payload.txt',@MaxEntryBytes=67108864,@ResultTable=N'#ZipEntryBoundary';
END TRY
BEGIN CATCH
 SELECT @Error=ERROR_NUMBER(),@State=ERROR_STATE(),@Message=ERROR_MESSAGE();
END CATCH;
SELECT @Error ErrorNumber,@State ErrorState,@Message ErrorMessage,
 (SELECT COUNT_BIG(*) FROM #ZipEntryBoundary) [RowCount],
 (SELECT TOP(1) EntryName FROM #ZipEntryBoundary) EntryName,
 (SELECT TOP(1) CompressedBytes FROM #ZipEntryBoundary) CompressedBytes,
 (SELECT TOP(1) UncompressedBytes FROM #ZipEntryBoundary) UncompressedBytes,
 (SELECT TOP(1) CompressionMethod FROM #ZipEntryBoundary) CompressionMethod,
 (SELECT TOP(1) Crc32 FROM #ZipEntryBoundary) Crc32,
 (SELECT TOP(1) IsEncrypted FROM #ZipEntryBoundary) IsEncrypted,
 (SELECT TOP(1) DATALENGTH(EntryPayload) FROM #ZipEntryBoundary) PayloadBytes,
 (SELECT TOP(1) CONVERT(varchar(64),HASHBYTES('SHA2_256',EntryPayload),2) FROM #ZipEntryBoundary) PayloadHash;
'@
  [void]$cmd.Parameters.Add('@Input',[Data.SqlDbType]::VarBinary,-1);$cmd.Parameters['@Input'].Value=$source
  $reader=$cmd.ExecuteReader()
  do{while($reader.Read()){
   [void](Get-ReleaseTimeout);$row=[ordered]@{}
   for($i=0;$i-lt$reader.FieldCount;$i++){$row[$reader.GetName($i)]=$reader.GetValue($i)}
   $rows.Add([pscustomobject]$row)
  }}while($reader.NextResult())
  if($rows.Count-ne1){throw 'ZIP_ENTRY_LIMIT_RESULT_SHAPE'};$v=$rows[0]
  if($f.overflow){
   $message=if($Key.StartsWith('compressed_')){'*komprimierte ZIP-Entry*134217728*'}else{'*ZIP-Entry überschreitet @MaxEntryBytes*'}
   if($v.ErrorNumber-ne51325-or$v.ErrorState-ne1-or$v.ErrorMessage-notlike$message-or$v.RowCount-ne0){throw 'ZIP_ENTRY_LIMIT_OVERFLOW_ORACLE'}
  }else{
   $crc=if([long]$f.crc32-gt2147483647L){[long]$f.crc32-4294967296L}else{[long]$f.crc32}
   if($v.ErrorNumber-isnot[DBNull]-or$v.RowCount-ne1-or$v.EntryName-cne'payload.txt'-or$v.CompressedBytes-ne$f.compressed_bytes-or$v.UncompressedBytes-ne$f.output_bytes-or$v.CompressionMethod-ne$f.method-or$v.Crc32-ne$crc-or$v.IsEncrypted-ne$false-or$v.PayloadBytes-ne$f.output_bytes-or$v.PayloadHash-cne$f.payload_sha256){throw 'ZIP_ENTRY_LIMIT_POSITIVE_ORACLE'}
  }
  $ledger.witnesses+=@(@{mode=$mode;fixture=$Key;rows=$v.RowCount;error=$(if($f.overflow){51325}else{0});positiveDigestChecked=(-not$f.overflow)});Save-ReleaseJournal
 }finally{if($reader){$reader.Dispose()};$cmd.Dispose();$source.Dispose()}
}
try{
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath;$runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version-cne'zip-entry-hardlimit-lab/v1'-or$runset.cases.Count-ne2-or$runset.explicit_qualification_approved-isnot[bool]-or$runset.explicit_qualification_approved-ne$true){throw 'ZIP_ENTRY_LIMIT_SCOPE'}
 $started=[DateTimeOffset]::Parse($runset.started_utc);$deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 if($deadline-ne$started.AddMinutes(45)-or$started-gt[DateTimeOffset]::UtcNow-or(-not$AuditOnly-and[DateTimeOffset]::UtcNow.AddMinutes(7)-ge$deadline)){throw 'ZIP_ENTRY_LIMIT_ADMISSION_CLOSED'}
 for($i=0;$i-lt2;$i++){
  $c=$runset.cases[$i];$tuple=$c.Platform+'/'+$c.Version+'/'+$c.Patch+'/'+$c.CL
  if($tuple-cne@('windows/2025/CU8/170','linux/2019/latest/150')[$i]){throw 'ZIP_ENTRY_LIMIT_EXACT_CASE_REQUIRED'}
 }
 Assert-ReleaseInputs;$case=$runset.cases[$CaseIndex]
 $manifest=Assert-ReleasePrivatePath $runset.fixture_manifest;$fixtures=Get-Content -LiteralPath $manifest -Raw|ConvertFrom-Json
 if($fixtures.schema_version-cne'zip-entry-hardlimit-fixtures/v1'-or$fixtures.compressed_limit_bytes-ne134217728-or$fixtures.output_limit_bytes-ne67108864-or$fixtures.limits_overridden-isnot[bool]-or$fixtures.limits_overridden-ne$false-or$fixtures.independent_zip_crc_verified-isnot[bool]-or$fixtures.independent_zip_crc_verified-ne$true){throw 'ZIP_ENTRY_LIMIT_FIXED_LIMIT_REQUIRED'}
 if((@($fixtures.fixtures.PSObject.Properties.Name)|Sort-Object)-join','-cne'compressed_cap,compressed_overflow,output_cap,output_overflow'){throw 'ZIP_ENTRY_LIMIT_FIXTURE_ROSTER'}
 foreach($key in @('compressed_cap','compressed_overflow','output_cap','output_overflow')){
  $f=$fixtures.fixtures.$key;$overflow=$key.EndsWith('_overflow');$compressed=$key.StartsWith('compressed_')
  $output=if($compressed){1L+[int]$overflow}else{67108864L+[int]$overflow}
  $packed=if($compressed){134217728L+[int]$overflow}else{$output};$method=if($compressed){8}else{0}
  if($f.compressed_bytes-ne$packed-or$f.output_bytes-ne$output-or$f.size-ne($packed+120)-or$f.method-ne$method-or$f.overflow-isnot[bool]-or$f.overflow-ne$overflow-or$f.payload_sha256-cnotmatch'^[A-F0-9]{64}$'){throw 'ZIP_ENTRY_LIMIT_FIXTURE_METADATA'}
  [void](Assert-ReleasePrivatePath $f.path)
 }
 [void](Assert-ReleasePrivatePath $runset.artifact.path)
 $knownPath=Join-Path $repo 'Releases/1.0.0/zip-entry-count-qualification.json'
 $known=Get-Content -LiteralPath $knownPath -Raw|ConvertFrom-Json
 if($known.result-cne'PASS_FOR_FIXED_ENTRY_COUNT_BOUNDARY'-or$known.binary.module_id-cne'toolbelt.archive.zip-memory'-or$known.binary.sql_assembly_name-cne'Toolbelt_Archive_ZipMemory'-or$runset.artifact.sha256-cne$known.binary.sha256.ToUpperInvariant()){throw 'ZIP_ENTRY_LIMIT_KNOWN_BINARY_REQUIRED'}
 $a=$runset.artifact
 if($a.module_id-cne'toolbelt.archive.zip-memory'-or$a.sql_name-cne'Toolbelt_Archive_ZipMemory'-or(Get-FileHash -LiteralPath $a.path -Algorithm SHA256).Hash-cne$a.sha256-or(Get-FileHash -LiteralPath $a.path -Algorithm SHA512).Hash-cne$a.sha512){throw 'ZIP_ENTRY_LIMIT_ARTIFACT_DRIFT'}
 foreach($required in @($PSCommandPath,$manifest,$knownPath,$runset.exports.local,$runset.exports.central,$runset.artifact.path,
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'),(Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
  if(@($runset.pins|Where-Object path -CEQ $required).Count-ne1){throw 'ZIP_ENTRY_LIMIT_REQUIRED_PIN'}
 }
 if($ValidateOnly){'PASS ZIP_ENTRY_LIMIT_SCOPE_AND_PINS_ONLY; no payload read/Lab import/SQL';return}
 if(-not$IsWindows){throw 'ZIP_ENTRY_LIMIT_WINDOWS_HOST_REQUIRED'}
 Assert-ZipEntryLimitFixtureFiles
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path).Hash-cne$runset.contract_sha256){throw 'ZIP_ENTRY_LIMIT_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case);if($targets.Count-ne1){throw 'ZIP_ENTRY_LIMIT_TARGET_REQUIRED'};$target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $hash=(Get-FileHash -LiteralPath $journal).Hash;$prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -DateKind String
  if($prior.state-cnotin@('COMPLETE','FAILED_CLEANED')-or$prior.owner-cnotmatch'^[a-f0-9]{32}$'){throw 'ZIP_ENTRY_LIMIT_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $observedNow=Read-ZipEntryLimitObservedTarget $control
  if($prior.observedTarget-and($observedNow.Version-cne$prior.observedTarget.Version-or$observedNow.Platform-cne$prior.observedTarget.Platform)){throw 'ZIP_ENTRY_LIMIT_AUDIT_TARGET_DRIFT'}
  foreach($entry in $prior.databases){
   if($entry.state-cne'DROPPED'-or$entry.name-cne('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix)){throw 'ZIP_ENTRY_LIMIT_AUDIT_OWNER'}
   $r=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows);if($r.Count-ne1-or$r[0].Id-isnot[DBNull]){throw 'ZIP_ENTRY_LIMIT_AUDIT_DATABASE_PRESENT'}
  }
  foreach($entry in $prior.trust){$now=Get-ClrCallerTrust $control ([Convert]::FromHexString($entry.hash));if(($entry.preexisting-and($null-eq$now-or$now.Fingerprint-cne$entry.fingerprint))-or(-not$entry.preexisting-and$null-ne$now)){throw 'ZIP_ENTRY_LIMIT_AUDIT_TRUST_DRIFT'}}
  Assert-ClrCallerConfiguration $control $prior.configuration
  if((@($prior.configuration.before).Count-and(@(Get-ClrCallerConfiguration $control)|ConvertTo-Json -Depth 4 -Compress)-cne(@($prior.configuration.before)|ConvertTo-Json -Depth 4 -Compress))-or($prior.trustSnapshotCaptured-and(Read-ZipEntryLimitTrustSnapshot $control)-cne$prior.trustBefore)){throw 'ZIP_ENTRY_LIMIT_AUDIT_SERVER_DRIFT'}
  Assert-ReleaseInputs;if((Get-FileHash -LiteralPath $journal).Hash-cne$hash){throw 'ZIP_ENTRY_LIMIT_AUDIT_JOURNAL_DRIFT'}
  [IO.File]::WriteAllText(($journal+'.audit.json'),(@{state='COMPLETE';readOnly=$true;originalJournalSHA256=$hash;originalRunPassed=($prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and$prior.witnesses.Count-eq8-and$prior.completedModes.Count-eq2);databaseAbsence=$true;configurationAndTrustRestored=$true;postPins=$true}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 }else{
  if(Test-Path -LiteralPath $journal){throw 'ZIP_ENTRY_LIMIT_NO_REPLAY'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';configuration=@{changed=$false;state='NEW';before=@()};trust=@();trustBefore=$null;trustSnapshotCaptured=$false;databases=@();witnesses=@();completedModes=@();observedTarget=$null;failure=$null};Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $ledger.observedTarget=Read-ZipEntryLimitObservedTarget $control;$ledger.trustBefore=Read-ZipEntryLimitTrustSnapshot $control;$ledger.trustSnapshotCaptured=$true;Save-ReleaseJournal
  $stage='CONFIGURATION';Start-ClrCallerConfiguration $control
  $stage='TRUST';$bytes=[Convert]::FromHexString($a.sha512);$before=Get-ClrCallerTrust $control $bytes
  $entry=[ordered]@{hash=$a.sha512;preexisting=($null-ne$before);fingerprint=$(if($before){$before.Fingerprint}else{$null});description=$null;state='PREEXISTING'};$ledger.trust+=@($entry);Save-ReleaseJournal
  if(-not$before){
   Assert-ClrCallerTrustCleanupScope $control $bytes;$entry.state='ADDING';$entry.description='Contoso ZIP entry caps '+$ledger.owner;Save-ReleaseJournal
   Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description;EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$bytes;'@Description'=$entry.description}
   $now=Get-ClrCallerTrust $control $bytes;if($null-eq$now-or$now.description-cne$entry.description){throw 'ZIP_ENTRY_LIMIT_TRUST_OWNER'};$entry.fingerprint=$now.Fingerprint;$entry.state='OWNED';Save-ReleaseJournal
  }
  foreach($mode in @('local','central')){
   $stage='DATABASE_'+$mode;$suffix=if($mode-ceq'local'){'l'}else{'c'};$name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'};$ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12;CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $id=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($id.Count-ne1){throw 'ZIP_ENTRY_LIMIT_DATABASE_ID'};$entry.id=$id[0].Id;$entry.created=$id[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name;Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner};$entry.state='OWNED';Save-ReleaseJournal
   Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);";Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $installed=@(Invoke-ReleaseSql $db "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;" -Rows)
   if($installed.Count-ne1-or$installed[0].name-cne$a.sql_name-or$installed[0].Hash-cne$a.sha512-or$installed[0].Permission-cne'SAFE_ACCESS'){throw 'ZIP_ENTRY_LIMIT_INSTALLED_BINARY'}
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   if($markers.Count-ne2-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.core.result-table.Version'-and$_.Value-ceq'1.0.0'}).Count-ne1-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.archive.zip-memory.Version'-and$_.Value-ceq'1.4.0'}).Count-ne1){throw 'ZIP_ENTRY_LIMIT_MODULE_CLOSURE'}
   $modes=@(Invoke-ReleaseSql $db "SELECT CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name IN(N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode',N'Toolbelt.Module.toolbelt.archive.zip-memory.DeploymentMode');" -Rows)
   if($modes.Count-ne2-or@($modes|Where-Object Value -CNE $mode).Count){throw 'ZIP_ENTRY_LIMIT_DEPLOYMENT_MODE'}
   $beforeProduct=Read-ZipEntryLimitProduct $db
   $stage='PROBES_'+$mode
   foreach($key in @('compressed_cap','compressed_overflow','output_cap','output_overflow')){Invoke-ZipEntryLimitProbe $db $key}
   $neutral=@(Invoke-ReleaseSql $db 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
   if($neutral.Count-ne1-or$neutral[0].TranCount-ne0-or$neutral[0].XactState-ne0){throw 'ZIP_ENTRY_LIMIT_SESSION_STATE'}
   if((Read-ZipEntryLimitProduct $db)-cne$beforeProduct){throw 'ZIP_ENTRY_LIMIT_PRODUCT_DRIFT'}
   $ledger.completedModes+=@($mode);Save-ReleaseJournal;$db.Dispose()
  }
  Assert-ReleaseInputs
 }
}catch{$failure=$_.Exception;if($ledger-and-not$AuditOnly){$ledger.failure=@{stage=$stage;privateDiagnostic=$failure.Message;privateStack=$_.ScriptStackTrace};Save-ReleaseJournal}}
finally{
 foreach($connection in $connections){try{$connection.Dispose()}catch{}};[Data.SqlClient.SqlConnection]::ClearAllPools()
 if($ledger-and-not$AuditOnly){
  $cleanup=$true
  try{
   $control=Open-ReleaseConnection 'master';foreach($entry in $ledger.databases){Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal}
   foreach($entry in $ledger.trust){
    $bytes=[Convert]::FromHexString($entry.hash);$now=Get-ClrCallerTrust $control $bytes
    if($entry.state-ceq'ADDING'-and$null-eq$now){$entry.state='RESTORED';Save-ReleaseJournal;continue}
    if($null-eq$now-or$now.Fingerprint-cne$entry.fingerprint){throw 'ZIP_ENTRY_LIMIT_TRUST_DRIFT'}
    if($entry.preexisting){continue};Assert-ClrCallerTrustCleanupScope $control $bytes
    Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash;EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$bytes}
    if($null-ne(Get-ClrCallerTrust $control $bytes)){throw 'ZIP_ENTRY_LIMIT_TRUST_REMAINS'};$entry.state='RESTORED';Save-ReleaseJournal
   }
   Restore-ClrCallerConfiguration $control;Assert-ReleaseInputs
   if($ledger.trustSnapshotCaptured-and(Read-ZipEntryLimitTrustSnapshot $control)-cne$ledger.trustBefore){throw 'ZIP_ENTRY_LIMIT_FOREIGN_TRUST_DRIFT'}
   $ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally{if($control){$control.Dispose()}}
 }
 foreach($handle in $locks){$handle.Dispose()}
}
if($failure){if($ValidateOnly){throw $failure};'FAIL ZIP_ENTRY_LIMIT_LIMIT; inspect private journal; no automatic replay';exit 1}
if($AuditOnly){'PASS ZIP_ENTRY_LIMIT_LIMIT fresh independent final audit'}else{'PASS ZIP_ENTRY_LIMIT_LIMIT selected modes; fresh independent audit required'}
