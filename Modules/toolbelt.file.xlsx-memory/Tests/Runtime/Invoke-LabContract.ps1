[CmdletBinding()]
param([ValidateSet('linux','windows')][string]$Platform='linux',
 [ValidateSet('2019','2022','2025')][string]$Version='2019',[string]$Patch='latest',
 [string]$LegacyRoot='.runtime/xlsx-zip13-legacy')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$errors=$null;$tokens=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'Tests/CI/run-lab-local.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Kanonische Labdiscovery hat Syntaxfehler.'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
 $f=$ast.FindAll({param($x)$x -is [Management.Automation.Language.FunctionDefinitionAst] -and $x.Name -eq $name},$true)
 if($f.Count-ne1){throw 'Labfunktion ist nicht eindeutig.'}
 . ([scriptblock]::Create($f[0].Extent.Text))
}
$lab=Resolve-LabContract
$promptPath=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
if($promptPath){$prompt=Get-Content -LiteralPath $promptPath -Raw;if([string]::IsNullOrWhiteSpace($prompt)){throw 'Zusatzprompt fehlt.'}}
$targets=@(Get-LabTargetsForSelector $lab.Contract ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
if(-not $targets.Count){throw 'Kein ausdrücklich ausgewähltes READY-Ziel.'}
$framework=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
$base64=& $framework -NoProfile -File (Join-Path $repoRoot 'Spikes/XlsxMemory/Test-Framework.ps1') -FixtureOnly
if($LASTEXITCODE -or @($base64).Count-ne1){throw 'Synthetischer Fixturegenerator fehlgeschlagen.'}
$fixture=[Convert]::FromBase64String($base64)
$repeatedBase64=& $framework -NoProfile -File (Join-Path $repoRoot 'Spikes/XlsxMemory/Test-Framework.ps1') -RepeatedStringFixtureOnly
if($LASTEXITCODE -or @($repeatedBase64).Count-ne1){throw 'Synthetischer Outputexpansionsfixturegenerator fehlgeschlagen.'}
$repeatedFixture=[Convert]::FromBase64String($repeatedBase64)
$zipRoot=Join-Path $repoRoot 'Modules/toolbelt.archive.zip-memory'
$xlsxRoot=Join-Path $repoRoot 'Modules/toolbelt.file.xlsx-memory'
$binaries=@(@{Name='Toolbelt_Archive_ZipMemory';Path=(Join-Path $zipRoot 'Clr/bin/Release/Toolbelt.Archive.ZipMemory.dll')},
 @{Name='Toolbelt_File_XlsxMemory';Path=(Join-Path $xlsxRoot 'Clr/bin/Release/Toolbelt.File.XlsxMemory.dll')})
$legacyDirectory=Join-Path $repoRoot $LegacyRoot
$legacyManifest=Get-Content -LiteralPath (Join-Path $legacyDirectory 'artifacts/Toolbelt.Archive.ZipMemory.trust-manifest.json') -Raw|ConvertFrom-Json
$legacyBinary=Join-Path $legacyDirectory 'artifacts/Toolbelt.Archive.ZipMemory.dll'
if($legacyManifest.moduleVersion-cne'1.3.0' -or (Get-FileHash -LiteralPath $legacyBinary -Algorithm SHA512).Hash-cne$legacyManifest.sha512){throw 'Gepinnte ZIP-1.3-Fixture ist nicht hashkonsistent.'}
$binaries+=@{Name='LegacyZip13';Path=$legacyBinary}
. (Join-Path $PSScriptRoot 'Xlsx.Metadata.ps1')
function Expand-SqlFile([string]$Path,[hashtable]$Variables){
 $builder=[Text.StringBuilder]::new()
 foreach($line in Get-Content -LiteralPath $Path){
  if($line -match '^\s*:r\s+(.+?)\s*$'){
   [void]$builder.AppendLine((Expand-SqlFile (Join-Path (Split-Path $Path -Parent) $Matches[1].Trim('"')) $Variables))
  }elseif($line -notmatch '^\s*:(On Error|setvar)'){
   $value=$line
   foreach($key in $Variables.Keys){
    $placeholder='$('+ $key +')'
    # Große synthetische Fixturewerte nur bei tatsächlichem Vorkommen binden.
    if($value.Contains($placeholder)){$value=$value.Replace($placeholder,[string]$Variables[$key])}
   }
   [void]$builder.AppendLine($value)
  }
 }
 return $builder.ToString()
}
foreach($target in $targets){
 $connection=[Data.SqlClient.SqlConnection]::new((New-LabConnectionString $target))
 $created=[Collections.Generic.List[string]]::new();$added=[Collections.Generic.List[byte[]]]::new()
 $phase='login'
 function Scalar([string]$sql){
  $cmd=$connection.CreateCommand();$cmd.CommandText=$sql;$cmd.CommandTimeout=60
  try{return $cmd.ExecuteScalar()}finally{$cmd.Dispose()}
 }
 function Run-Script([string]$path,[hashtable]$variables){
  $source=Expand-SqlFile $path $variables
  foreach($batch in [regex]::Split($source,'(?im)^\s*GO\s*$')){
   if([string]::IsNullOrWhiteSpace($batch)){continue}
   $cmd=$connection.CreateCommand();$cmd.CommandText=$batch;$cmd.CommandTimeout=60
   try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
  }
 }
 function Test-LifecycleCallerTransaction([string]$path,[hashtable]$variables){
  $zipLifecycle=$path.Contains('toolbelt.archive.zip-memory')
  $errorPrefix=if($zipLifecycle){'TBX_ZIP_LIFECYCLE_CALLER_TRANSACTION:'}else{'TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION:'}
  $moduleId=if($zipLifecycle){'toolbelt.archive.zip-memory'}else{'toolbelt.file.xlsx-memory'}
  $schemaName=if($zipLifecycle){'toolbelt_archive'}else{'toolbelt_file'}
  foreach($abort in @('OFF','ON')){
   [void](Scalar "SET XACT_ABORT $abort;CREATE TABLE #XlsxLifecycleCaller(Value int NOT NULL);BEGIN TRANSACTION;INSERT #XlsxLifecycleCaller VALUES(37);")
   $beforeMarker=Scalar "SELECT CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.$moduleId.Version';"
   $beforeObjects=Scalar "SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'$schemaName');"
   $caught=$false
   try{Run-Script $path $variables}
   catch{
    $cause=$_.Exception
    while($cause -and $cause -isnot [Data.SqlClient.SqlException]){$cause=$cause.InnerException}
    if(-not $cause -or $cause.Number-ne50000 -or -not $cause.Message.StartsWith($errorPrefix)){throw 'Lifecycle-Callerfehlerkategorie falsch.'}
    $caught=$true
   }
   if(-not $caught -or (Scalar 'SELECT @@TRANCOUNT;')-ne1 -or (Scalar 'SELECT XACT_STATE();')-ne1){throw 'Lifecycle-Callertransaktion verändert.'}
   if((Scalar 'SELECT COUNT(*) FROM #XlsxLifecycleCaller WHERE Value=37;')-ne1 -or
      (Scalar "SELECT CASE WHEN (@@OPTIONS & 16384)<>0 THEN 1 ELSE 0 END;")-ne $(if($abort-eq'ON'){1}else{0})){throw 'Lifecycle-Callerarbeit oder XACT_ABORT verändert.'}
   $afterMarker=Scalar "SELECT CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.$moduleId.Version';"
   $afterObjects=Scalar "SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'$schemaName');"
   if($afterMarker-cne$beforeMarker -or $afterObjects-ne$beforeObjects){throw 'Lifecycle-Callerablehnung verändert Releasebestand.'}
   [void](Scalar 'ROLLBACK TRANSACTION;DROP TABLE #XlsxLifecycleCaller;SET XACT_ABORT OFF;')
  }
 }
 function Test-LifecycleSqlcmd([string]$script,[string]$prefix){
  # SqlConnection entfernt nach Open bei PersistSecurityInfo=false das Passwort.
  # Daher ausschließlich den frisch validierten Vertrag im Prozess verwenden.
  $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString $target))
  $info=[Diagnostics.ProcessStartInfo]::new((Get-Command sqlcmd -ErrorAction Stop).Source)
  $info.UseShellExecute=$false;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true;$info.CreateNoWindow=$true
  $info.WorkingDirectory=$PSScriptRoot
  foreach($arg in @('-S',$builder.DataSource,'-d',$builder.InitialCatalog,'-U',$builder.UserID,'-C','-b','-r','1','-l','15','-t','30','-i',$script,'-v','DeploymentMode=local','AssemblyBits=0x00','ConfirmNoExternalConsumers=1')){[void]$info.ArgumentList.Add($arg)}
  $info.Environment['SQLCMDPASSWORD']=$builder.Password
  $process=[Diagnostics.Process]::new();$process.StartInfo=$info
  try{
   [void]$process.Start();$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
   if(-not$process.WaitForExit(60000)){$process.Kill();throw 'SQLCMD-Lifecycleprobe überschritt das Testbudget.'}
   $output=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
   if($process.ExitCode-eq0-or$output-notmatch'Msg 50000,'-or-not$output.Contains($prefix)){throw 'SQLCMD-Lifecycle muss mit Guardfehler und Nonzeroexit abbrechen.'}
  }finally{$process.Dispose();$info.Environment.Remove('SQLCMDPASSWORD')|Out-Null}
 }
 try{
  $connection.Open()
  $phase='preflight'
  [void](Scalar 'SELECT @@VERSION;')
  if((Scalar "SELECT value_in_use FROM sys.configurations WHERE name=N'clr enabled';")-ne1 -or
     (Scalar "SELECT value_in_use FROM sys.configurations WHERE name=N'clr strict security';")-ne1){throw 'SAFE-Voraussetzung fehlt.'}
  if((Scalar "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion'));")-ne @{ '2019'=15;'2022'=16;'2025'=17}[$Version]){throw 'Versionsvertrag fehlt.'}
  $bits=@{};$binaryHashes=@{}
  foreach($binary in $binaries){
   $bytes=[IO.File]::ReadAllBytes($binary.Path);$sha=[Security.Cryptography.SHA512]::Create()
   try{$hash=$sha.ComputeHash($bytes)}finally{$sha.Dispose()}
   $hexHash='0x'+[BitConverter]::ToString($hash).Replace('-','')
   $binaryHashes[$binary.Name]=$hexHash
   if((Scalar "SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash=$hexHash;")-eq0){
    [void](Scalar "EXEC sys.sp_add_trusted_assembly @hash=$hexHash,@description=N'Toolbelt synthetic XLSX public contract';")
    $added.Add($hash)
   }
   $bits[$binary.Name]='0x'+[BitConverter]::ToString($bytes).Replace('-','')
  }
  foreach($mode in @('local','central')){
   $phase=$mode+'-create'
   $db='Toolbelt_XlsxContract_'+[Guid]::NewGuid().ToString('N')
   [void](Scalar "CREATE DATABASE [$db];");$created.Add($db);$connection.ChangeDatabase($db)
   $vars=@{DeploymentMode=$mode;AssemblyBits=$bits.Toolbelt_Archive_ZipMemory;ConfirmNoExternalConsumers='1'}
   $phase=$mode+'-result-table'
   Run-Script (Join-Path $repoRoot 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql') $vars
   if($mode-eq'local'){
    $phase='actual-zip-13-install'
    $vars.AssemblyBits=$bits.LegacyZip13
    Run-Script (Join-Path $legacyDirectory 'source/Modules/toolbelt.archive.zip-memory/Deployment/Deploy.sql') $vars
    $legacyHash=$legacyManifest.sqlServerHexLiteral
    if((Scalar "SELECT COUNT(*) FROM sys.assembly_files f JOIN sys.assemblies a ON a.assembly_id=f.assembly_id WHERE a.name=N'Toolbelt_Archive_ZipMemory' AND f.file_id=1 AND HASHBYTES('SHA2_512',f.content)=$legacyHash;")-ne1){throw 'Tatsächlich installierter Legacyhash weicht ab.'}
    $vars.AssemblyBits=$bits.Toolbelt_Archive_ZipMemory
   }
   $phase=$mode+'-zip-deploy'
   Run-Script (Join-Path $zipRoot 'Deployment/Deploy.sql') $vars
   if((Scalar "SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.archive.zip-memory.Version' AND CONVERT(nvarchar(64),value)=N'1.4.0';")-ne1){throw 'ZIP-Upgradeversionsmarker falsch.'}
   $newZipHash=$binaryHashes.Toolbelt_Archive_ZipMemory
   if((Scalar "SELECT COUNT(*) FROM sys.assembly_files f JOIN sys.assemblies a ON a.assembly_id=f.assembly_id WHERE a.name=N'Toolbelt_Archive_ZipMemory' AND f.file_id=1 AND HASHBYTES('SHA2_512',f.content)=$newZipHash;")-ne1){throw 'Tatsächlicher ZIP-Upgradehash falsch.'}
   if($mode-eq'local'){
    $phase='upgraded-zip-writer-regression'
    $vars.ToolbeltDatabase=$db
    Run-Script (Join-Path $zipRoot 'Tests/Runtime/Writer.Contract.sql') $vars
   }
   $vars.AssemblyBits=$bits.Toolbelt_File_XlsxMemory
   $phase=$mode+'-xlsx-deploy'
   Run-Script (Join-Path $xlsxRoot 'Deployment/Deploy.sql') $vars
   $phase=$mode+'-xlsx-redeploy'
   Run-Script (Join-Path $xlsxRoot 'Deployment/Deploy.sql') $vars
   $phase=$mode+'-public-contract'
   $vars.XlsxFixture='0x'+[BitConverter]::ToString($fixture).Replace('-','')
   $vars.XlsxRepeatedFixture='0x'+[BitConverter]::ToString($repeatedFixture).Replace('-','')
   Run-Script (Join-Path $xlsxRoot 'Tests/Runtime/Xlsx.Contract.sql') $vars
   $phase=$mode+'-client-metadata'
   Test-XlsxMetadata -Connection $connection -Fixture $fixture
   if($mode-eq'central'){
    $phase='central-cross-database-client'
    $caller='Toolbelt_XlsxCaller_'+[Guid]::NewGuid().ToString('N')
    [void](Scalar "CREATE DATABASE [$caller];");$created.Add($caller);$connection.ChangeDatabase($caller)
    Test-XlsxMetadata -Connection $connection -Fixture $fixture -ToolbeltDatabase $db
    $cross=$connection.CreateCommand();$cross.CommandTimeout=60
    $cross.CommandText="CREATE TABLE #CrossCells(Dummy int); EXEC [$db].toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Binary,@SheetOrdinal=1,@ResultTable=N'#CrossCells'; IF (SELECT COUNT(*) FROM #CrossCells)<>9 THROW 51590,N'Central caller ResultTable count failed.',1; IF NOT EXISTS(SELECT 1 FROM #CrossCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND TextValue=N'tail ä😀') THROW 51590,N'Central caller text failed.',1; DROP TABLE #CrossCells;"
    [void]$cross.Parameters.Add('@Binary',[Data.SqlDbType]::VarBinary,-1);$cross.Parameters['@Binary'].Value=$fixture
    try{[void]$cross.ExecuteNonQuery()}finally{$cross.Dispose()}
    $connection.ChangeDatabase($db)
   }
   $phase=$mode+'-safe-catalog'
   if((Scalar "SELECT COUNT(*) FROM sys.assemblies WHERE name IN(N'Toolbelt_Archive_ZipMemory',N'Toolbelt_File_XlsxMemory') AND permission_set=1;")-ne2){throw 'SAFE-Katalogvertrag fehlt.'}
   $phase=$mode+'-lifecycle-caller-guard'
   $phase=$mode+'-xlsx-deploy-caller';Test-LifecycleCallerTransaction (Join-Path $xlsxRoot 'Deployment/Deploy.sql') $vars
   $phase=$mode+'-xlsx-uninstall-caller';Test-LifecycleCallerTransaction (Join-Path $xlsxRoot 'Deployment/Uninstall.sql') $vars
   $phase=$mode+'-zip-deploy-caller';Test-LifecycleCallerTransaction (Join-Path $zipRoot 'Deployment/Deploy.sql') $vars
   $phase=$mode+'-zip-uninstall-caller';Test-LifecycleCallerTransaction (Join-Path $zipRoot 'Deployment/Uninstall.sql') $vars
   $phase=$mode+'-sqlcmd-deploy-caller'
   Test-LifecycleSqlcmd 'Lifecycle.CallerTransaction.Deploy.sql' 'TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION:'
   $phase=$mode+'-sqlcmd-uninstall-caller'
   Test-LifecycleSqlcmd 'Lifecycle.CallerTransaction.Uninstall.sql' 'TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION:'
   $phase=$mode+'-xlsx-uninstall'
   Run-Script (Join-Path $xlsxRoot 'Deployment/Uninstall.sql') $vars
   if((Scalar "SELECT COUNT(*) FROM sys.assemblies WHERE name=N'Toolbelt_File_XlsxMemory';")-ne0){throw 'XLSX-Uninstall unvollständig.'}
   $phase=$mode+'-zip-uninstall'
   Run-Script (Join-Path $zipRoot 'Deployment/Uninstall.sql') $vars
   "PASS: XLSX public SQL $Version/$Platform/$Patch $mode; synthetic contract, dependencies, redeploy, SAFE catalog and own uninstall."
  }
 }catch{
  $type=$_.Exception.GetType().Name;$number=0;$cause=$_.Exception
  while($cause){if($cause -is [Data.SqlClient.SqlException]){$number=$cause.Number};$cause=$cause.InnerException}
  throw "XLSX public qualification failed ($type,phase=$phase,SQL=$number); inspect only ephemeral diagnostics."
 }finally{
  if($connection.State-eq[Data.ConnectionState]::Open){
   # Ausschließlich die eigene Disposable-Verbindung: ein abgebrochener
   # Deployment-/Contractbatch kann seinen Testtransaktionsscope offenlassen.
   [void](Scalar 'IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;')
   $connection.ChangeDatabase('master')
   foreach($db in $created){[void](Scalar "ALTER DATABASE [$db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE [$db];")}
   foreach($hash in $added){$hex='0x'+[BitConverter]::ToString($hash).Replace('-','');[void](Scalar "EXEC sys.sp_drop_trusted_assembly @hash=$hex;")}
  }
  $connection.Dispose()
 }
}

