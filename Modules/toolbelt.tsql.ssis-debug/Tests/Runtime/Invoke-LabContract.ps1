[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('2019','2022','2025')][string]$Version,
 [string]$Patch='base',
 [ValidateSet('local','central')][string[]]$Modes=@('local','central'),
 [switch]$Full,
 [switch]$ApiOnly,
 [string]$PredecessorRoot,
 [string]$SsisPredecessorReleaseDirectory,
 [string]$SsisIntermediateReleaseDirectory,
 [string]$InstallationPackageRoot,
 [string]$JournalDirectory,
 [string]$ExpectedTargetKey,
 [ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedContractSha256,
 [string]$SsisReleaseDirectory,
 [string]$ParserReleaseDirectory,
 [ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512='84BA992E7482B644B5EE8B4EBBC1AFF537CD690A9D3D4366A0B037FE10E5BD3AD40352DC16C7D643B5180185D011E83AD7411EF359CB3FFC3F75E046B46E66FC',
 [ValidateSet('Latin1_General_100_BIN2','Latin1_General_100_CS_AS','Latin1_General_100_CI_AS_SC_UTF8')][string]$DatabaseCollation='Latin1_General_100_BIN2'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$repoRoot=Split-Path -Parent (Split-Path -Parent $moduleRoot)
. (Join-Path $repoRoot 'Tests/CI/LabQualifiedContract.ps1')
$astErrors=$null;$astTokens=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'Tests/CI/run-lab-local.ps1'),[ref]$astTokens,[ref]$astErrors)
if($astErrors.Count){throw 'LAB_DISCOVERY_SYNTAX_INVALID'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString','Invoke-LabPreflight')){
 $definition=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name},$true))
 if($definition.Count -ne 1){throw 'LAB_DISCOVERY_NOT_UNIQUE'};. ([scriptblock]::Create($definition[0].Extent.Text))
}
if($InstallationPackageRoot){
 $repoRoot=[IO.Path]::GetFullPath($InstallationPackageRoot)
 $package=Get-Content -LiteralPath (Join-Path $repoRoot 'PACKAGE-MANIFEST.json') -Raw|ConvertFrom-Json
 if($package.packageName -cne 'SSIS-Debug-1.0.0-Install-Windows' -or $PredecessorRoot){throw 'SSIS_PACKAGE_SCOPE_INVALID'}
 foreach($file in $package.files){
  $path=[IO.Path]::GetFullPath((Join-Path $repoRoot $file.path))
  if(-not $path.StartsWith($repoRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or
     (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $file.sha256){throw 'SSIS_PACKAGE_INPUT_CHANGED'}
 }
 $moduleRoot=Join-Path $repoRoot 'Modules/toolbelt.tsql.ssis-debug'
 if($SsisReleaseDirectory -or $ParserReleaseDirectory){throw 'SSIS_PACKAGE_EXTERNAL_RELEASE_NOT_ALLOWED'}
}
$ssisNativeScopeClock=[Diagnostics.Stopwatch]::new();$ssisNativeCleanupPhase=$false
$ssisNativeBoundedInvocation=$Modes.Count -eq 1
function Get-SsisNativeTimeout([int]$Maximum=45){
 # Bestehende Mehrfachmodus-Aufrufe behalten ihre bisherigen Einzelkommandogrenzen.
 # Die neue Qualifikation ruft jeden Modus als eigenen begrenzten Fall auf.
 if(-not $ssisNativeBoundedInvocation){return $Maximum}
 $deadline=if($ssisNativeCleanupPhase){360}else{300}
 $left=[Math]::Floor($deadline-$ssisNativeScopeClock.Elapsed.TotalSeconds)
 if($left -lt 1){throw 'SSIS_NATIVE_SCOPE_DEADLINE'}
 return [int][Math]::Min($Maximum,$left)
}
function Query([Data.SqlClient.SqlConnection]$Connection,[string]$Text){
 $cmd=$Connection.CreateCommand();$cmd.CommandText=$Text;$cmd.CommandTimeout=Get-SsisNativeTimeout 45
 try{$table=[Data.DataTable]::new();$reader=$cmd.ExecuteReader();try{if($reader.FieldCount -gt 0){$table.Load($reader)}}finally{$reader.Dispose()};return ,$table}finally{$cmd.Dispose()}
}
function NonQuery([Data.SqlClient.SqlConnection]$Connection,[string]$Text){
 $cmd=$Connection.CreateCommand();$cmd.CommandText=$Text;$cmd.CommandTimeout=Get-SsisNativeTimeout 45
 try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
}
function ReconfigureProtected([Data.SqlClient.SqlConnection]$Connection){
 # Auch vorgemerkte Änderungen dürfen die ausdrückliche Strict-Security-
 # Grenze niemals aufheben. Derselbe Guard gilt bei der Wiederherstellung.
 $safe=Query $Connection "SELECT COUNT_BIG(*) AS N FROM sys.configurations WITH (NOLOCK) WHERE name=N'clr strict security' AND CONVERT(int,value)=1 AND CONVERT(int,value_in_use)=1;"
 if($safe.Rows[0].N -ne 1){throw 'SSIS_LAB_PROTECTED_CONFIGURATION_PENDING_OR_DRIFT'}
 NonQuery $Connection 'RECONFIGURE;'
 $safe=Query $Connection "SELECT COUNT_BIG(*) AS N FROM sys.configurations WITH (NOLOCK) WHERE name=N'clr strict security' AND CONVERT(int,value)=1 AND CONVERT(int,value_in_use)=1;"
 if($safe.Rows[0].N -ne 1){throw 'SSIS_LAB_PROTECTED_CONFIGURATION_DRIFT'}
}
function Expand([string]$Path){
 $text=[IO.File]::ReadAllText($Path)
 [regex]::Replace($text,'(?m)^:r\s+([^\r\n]+)\s*$',{param($m)
  $child=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $Path) $m.Groups[1].Value.Trim().Trim('"')))
  if(-not $child.StartsWith($repoRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'LAB_INCLUDE_OUTSIDE_REPOSITORY'}
  Expand $child
 })
}
function Batches([Data.SqlClient.SqlConnection]$Connection,[string]$Text,[string]$Mode){
 $sql=[regex]::Replace($Text.Replace('$(DeploymentMode)',$Mode),'(?im)^:On Error exit\s*$','')
 if($sql -match '(?m)^:' -or $sql -match '\$\('){throw 'LAB_UNRESOLVED_SQLCMD'}
 foreach($batch in [regex]::Split($sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?\r?$')){if(-not [string]::IsNullOrWhiteSpace($batch)){NonQuery $Connection $batch}}
}
function VerifyFiles($Manifest,[string]$Root){
 foreach($key in @('sourceFiles','deploymentFiles')){
  foreach($entry in $Manifest.$key){$parts=$entry.Split(':',2);$path=[IO.Path]::GetFullPath((Join-Path $Root $parts[0]));if(-not $path.StartsWith($repoRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $parts[1]){throw 'SSIS_LAB_SOURCE_BINDING_MISMATCH'}}
 }
}
$ssisRelease=if($SsisReleaseDirectory){[IO.Path]::GetFullPath($SsisReleaseDirectory)}else{Join-Path $moduleRoot 'Artifacts'}
$parserRelease=if($ParserReleaseDirectory){[IO.Path]::GetFullPath($ParserReleaseDirectory)}else{Join-Path $repoRoot 'Modules/toolbelt.tsql.script-parser/Artifacts'}
$manifest=Get-Content -LiteralPath (Join-Path $ssisRelease 'Toolbelt.Tsql.SsisDebug.trust-manifest.json') -Raw|ConvertFrom-Json
VerifyFiles $manifest $moduleRoot
 # Qualifizierter Kandidat mit geprüftem Kern und gezielten nativen
 # Integrationskorrekturen. Kein Freigeben beliebiger Binaries.
$qualifiedProvider=$QualifiedProviderSha512
if($manifest.sha512 -cne $qualifiedProvider -or (Get-FileHash (Join-Path $ssisRelease 'Toolbelt.Tsql.SsisDebug.dll') -Algorithm SHA512).Hash -cne $qualifiedProvider -or
 (Get-FileHash (Join-Path $ssisRelease 'Deploy.WithAssembly.sql') -Algorithm SHA256).Hash -cne $manifest.deploymentArtifactSha256){throw 'SSIS_LAB_QUALIFIED_RELEASE_MISMATCH'}
$trustInputs=@(@{File=(Join-Path $parserRelease 'Microsoft.SqlServer.TransactSql.ScriptDom.dll');Hash=$manifest.scriptDomSha512},@{File=(Join-Path $parserRelease 'Toolbelt.Tsql.ScriptParser.dll');Hash=$manifest.parserSha512},@{File=(Join-Path $ssisRelease 'Toolbelt.Tsql.SsisDebug.dll');Hash=$manifest.sha512})
if($SsisPredecessorReleaseDirectory){
 $SsisPredecessorReleaseDirectory=[IO.Path]::GetFullPath($SsisPredecessorReleaseDirectory)
 $ssisOldManifest=Get-Content -LiteralPath (Join-Path $SsisPredecessorReleaseDirectory 'Toolbelt.Tsql.SsisDebug.trust-manifest.json') -Raw|ConvertFrom-Json
 # Tatsächlich ausgelieferter qualifizierter V1-Satz, keine erfundene Vorgängerversion.
 $oldQualified='84BA992E7482B644B5EE8B4EBBC1AFF537CD690A9D3D4366A0B037FE10E5BD3AD40352DC16C7D643B5180185D011E83AD7411EF359CB3FFC3F75E046B46E66FC'
 if($ssisOldManifest.moduleId -cne 'toolbelt.tsql.ssis-debug' -or $ssisOldManifest.moduleVersion -cne '1.0.0' -or $ssisOldManifest.sha512 -cne $oldQualified -or
    (Get-FileHash -LiteralPath (Join-Path $SsisPredecessorReleaseDirectory 'Toolbelt.Tsql.SsisDebug.dll') -Algorithm SHA512).Hash -cne $oldQualified -or
    (Get-FileHash -LiteralPath (Join-Path $SsisPredecessorReleaseDirectory 'Deploy.WithAssembly.sql') -Algorithm SHA256).Hash -cne $ssisOldManifest.deploymentArtifactSha256 -or
    $ssisOldManifest.parserSha512 -cne $manifest.parserSha512 -or $ssisOldManifest.scriptDomSha512 -cne $manifest.scriptDomSha512 -or $oldQualified -ceq $qualifiedProvider){throw 'SSIS_GENUINE_BUILD_PREDECESSOR_INVALID'}
 $trustInputs+=@{File=(Join-Path $SsisPredecessorReleaseDirectory 'Toolbelt.Tsql.SsisDebug.dll');Hash=$oldQualified}
}
if($SsisIntermediateReleaseDirectory){
 if(-not $SsisPredecessorReleaseDirectory){throw 'SSIS_INTERMEDIATE_REQUIRES_GENUINE_PREDECESSOR'}
 $SsisIntermediateReleaseDirectory=[IO.Path]::GetFullPath($SsisIntermediateReleaseDirectory)
 $intermediate=Get-Content -LiteralPath (Join-Path $SsisIntermediateReleaseDirectory 'Toolbelt.Tsql.SsisDebug.trust-manifest.json') -Raw|ConvertFrom-Json
 $record=Get-Content -LiteralPath (Join-Path $moduleRoot 'Tests/Qualification/Windows2019-2022.20261025.json') -Raw|ConvertFrom-Json
 $intermediateHash=(Get-FileHash -LiteralPath (Join-Path $SsisIntermediateReleaseDirectory 'Toolbelt.Tsql.SsisDebug.dll') -Algorithm SHA512).Hash
 $intermediateDeploy=(Get-FileHash -LiteralPath (Join-Path $SsisIntermediateReleaseDirectory 'Deploy.WithAssembly.sql') -Algorithm SHA256).Hash
 if($record.result -cne 'PASS' -or $record.product_source_commit -cne 'e718accba206153c7af6aece1bf180cb23a16203' -or
    $intermediate.moduleId -cne 'toolbelt.tsql.ssis-debug' -or $intermediate.moduleVersion -cne '1.0.0' -or
    $intermediate.sha512 -cne $intermediateHash -or $intermediateHash -ceq $oldQualified -or $intermediateHash -ceq $qualifiedProvider -or
    (Get-FileHash -LiteralPath (Join-Path $SsisIntermediateReleaseDirectory 'Toolbelt.Tsql.SsisDebug.dll') -Algorithm SHA256).Hash.ToLowerInvariant() -cne $record.qualified_assembly_sha256 -or
    $intermediateDeploy -cne $intermediate.deploymentArtifactSha256 -or $intermediateDeploy.ToLowerInvariant() -cne $record.qualified_deploy_sql_sha256 -or
    $intermediate.parserSha512 -cne $manifest.parserSha512 -or $intermediate.scriptDomSha512 -cne $manifest.scriptDomSha512){throw 'SSIS_QUALIFIED_INTERMEDIATE_INVALID'}
 $trustInputs+=@{File=(Join-Path $SsisIntermediateReleaseDirectory 'Toolbelt.Tsql.SsisDebug.dll');Hash=$intermediateHash}
}
if($PredecessorRoot){
 $PredecessorRoot=[IO.Path]::GetFullPath($PredecessorRoot)
 $oldRoot=Join-Path $PredecessorRoot 'Modules/toolbelt.tsql.script-parser'
 $oldManifest=Get-Content (Join-Path $oldRoot 'Artifacts/Toolbelt.Tsql.ScriptParser.trust-manifest.json') -Raw|ConvertFrom-Json
 if($oldManifest.moduleId -cne 'toolbelt.tsql.script-parser' -or $oldManifest.moduleVersion -cne '2.0.0'){throw 'SSIS_PREDECESSOR_VERSION_INVALID'}
 foreach($entry in @($oldManifest.sourceFiles)+@($oldManifest.deploymentSourceFiles)){
  $parts=$entry.Split(':',2);$file=[IO.Path]::GetFullPath((Join-Path $oldRoot $parts[0]))
  if(-not $file.StartsWith($oldRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -cne $parts[1]){throw 'SSIS_PREDECESSOR_SOURCE_BINDING_INVALID'}
 }
 if((Get-FileHash (Join-Path $oldRoot 'Artifacts/Deploy.WithAssembly.sql') -Algorithm SHA256).Hash -cne $oldManifest.deploymentArtifactSha256){throw 'SSIS_PREDECESSOR_DEPLOYMENT_BINDING_INVALID'}
 $oldConsumer=[IO.File]::ReadAllText((Join-Path $PredecessorRoot 'Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableCloneInternal.sql'))
 if(-not $oldConsumer.Contains($oldManifest.sha512)){throw 'SSIS_PREDECESSOR_CONSUMER_PIN_MISMATCH'}
 $trustInputs+=@{File=(Join-Path $oldRoot 'Artifacts/Toolbelt.Tsql.ScriptParser.dll');Hash=$oldManifest.sha512}
}
foreach($input in $trustInputs){if((Get-FileHash -LiteralPath $input.File -Algorithm SHA512).Hash -cne $input.Hash){throw 'SSIS_LAB_BINARY_PIN_MISMATCH'}}
$lab=Resolve-LabContract
if($ExpectedContractSha256 -and (Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $ExpectedContractSha256){throw 'SSIS_LAB_FROZEN_CONTRACT_CHANGED'}
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform='windows';Version=$Version;Patch=$Patch}))
if(-not $targets.Count){throw 'SSIS_LAB_NO_READY_TARGET'}
if($ExpectedTargetKey -and ($targets.Count -ne 1 -or [string]$targets[0].key -cne $ExpectedTargetKey)){throw 'SSIS_LAB_FROZEN_TARGET_CHANGED'}
$journalRoot=if($JournalDirectory){[IO.Path]::GetFullPath($JournalDirectory)}else{Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltSsisNative-'+[guid]::NewGuid().ToString('N'))}
if(Test-Path -LiteralPath $journalRoot){throw 'SSIS_LAB_JOURNAL_COLLISION'}
New-Item -ItemType Directory -Path $journalRoot|Out-Null
$targetOrdinal=0
foreach($target in $targets){
 $ssisNativeScopeClock.Restart();$ssisNativeCleanupPhase=$false
 $targetOrdinal++;[void](Invoke-LabPreflight -Entry $target -TestPurpose Functional)
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $target -TestPurpose Functional));$builder['Initial Catalog']='master';$builder['Pooling']=$false
 $master=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$master.Open()
 $runId=[guid]::NewGuid().ToString('N');$ownedDatabases=[Collections.Generic.List[string]]::new();$ownedTrust=[Collections.Generic.List[string]]::new();$configBefore=@();$configAfter=@();$configChanged=$false
 $journalPath=Join-Path $journalRoot ('target-'+$targetOrdinal+'.json')
 $journal=[ordered]@{schemaVersion=1;purpose='Functional';authenticatedTls='not executed';runId=$runId;state='ACTIVE';databases=@();trust=@();configurationBefore=@();configurationAfter=@();scope='SSIS V1 native local/central';phase='preflight'}
 function SaveJournal{$journal|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $journalPath -Encoding utf8}
 SaveJournal
 $failed=$null;$phase='preflight';$uncertainDatabase=$null
 try{
  $lock=Query $master "DECLARE @r int;EXEC @r=sys.sp_getapplock @Resource=N'toolbelt.lab.clr.configuration',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0;SELECT @r AS R;"
  if([int]$lock.Rows[0].R -lt 0){throw 'SSIS_LAB_CONFIGURATION_LEASE_BUSY'}
  $permissions=Query $master "SELECT IS_SRVROLEMEMBER(N'sysadmin') AS A,(SELECT CONVERT(int,value_in_use) FROM sys.configurations WITH (NOLOCK) WHERE name=N'clr strict security') AS S,(SELECT CONVERT(int,value) FROM sys.configurations WITH (NOLOCK) WHERE name=N'clr strict security') AS C;"
  if($permissions.Rows[0].A -ne 1 -or $permissions.Rows[0].S -ne 1 -or $permissions.Rows[0].C -ne 1){throw 'SSIS_LAB_EXISTING_ADMIN_OR_STRICT_SECURITY_MISSING'}
  $allConfig=Query $master 'SELECT name,CONVERT(int,value) AS Configured,CONVERT(int,value_in_use) AS Running,is_dynamic FROM sys.configurations WITH (NOLOCK);'
  if(($allConfig.Select("name='clr enabled'"))[0].Running -ne 1){
   $configBefore=@($allConfig.Rows|Where-Object{$_.Configured -ne $_.Running -or $_.name -in @('clr enabled','show advanced options')}|ForEach-Object{[pscustomobject]@{name=[string]$_.name;configured=[int]$_.Configured;running=[int]$_.Running;dynamic=[bool]$_.is_dynamic}})
   $journal.configurationBefore=$configBefore;SaveJournal;$configChanged=$true
   NonQuery $master "EXEC sys.sp_configure N'clr enabled',1;";ReconfigureProtected $master
   $after=Query $master 'SELECT name,CONVERT(int,value) AS Configured,CONVERT(int,value_in_use) AS Running FROM sys.configurations WITH (NOLOCK);'
   $configAfter=@(foreach($old in $configBefore){$row=@($after.Rows|Where-Object{$_.name -eq $old.name})[0];[pscustomobject]@{name=$old.name;configured=[int]$row.Configured;running=[int]$row.Running}})
   $journal.configurationAfter=$configAfter;SaveJournal
   if(($after.Select("name='clr enabled'"))[0].Running -ne 1){throw 'SSIS_LAB_CLR_ACTIVATION_FAILED'}
  }
  $phase='exact-trust';$description='SQL Toolbelt SSIS native '+$runId
  foreach($input in $trustInputs){
   $existing=Query $master ('SELECT description FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x'+$input.Hash+';')
   if($existing.Rows.Count -eq 0){$ownedTrust.Add($input.Hash);$journal.trust=@($ownedTrust);SaveJournal;NonQuery $master ("EXEC sys.sp_add_trusted_assembly @hash=0x"+$input.Hash+",@description=N'"+$description+"';")}
  }
  foreach($mode in $Modes){
   $database='ToolbeltSsis_'+$runId.Substring(0,16)+'_'+$mode
   $exists=Query $master ("SELECT COUNT_BIG(*) AS N FROM sys.databases WITH (NOLOCK) WHERE name=N'"+$database+"';")
   if($exists.Rows[0].N -ne 0){throw 'SSIS_LAB_DATABASE_COLLISION'}
   $journal.intendedDatabase=$database;SaveJournal;$uncertainDatabase=$database
   $phase=$mode+'-create';NonQuery $master ('CREATE DATABASE ['+$database+'] COLLATE '+$DatabaseCollation+';')
   $ownedDatabases.Add($database);$uncertainDatabase=$null;$journal.databases=@($ownedDatabases);SaveJournal
   $clientDatabase=$null
   if($Full){
    $clientDatabase=$database+'_client';$journal.intendedDatabase=$clientDatabase;SaveJournal;$uncertainDatabase=$clientDatabase
    NonQuery $master ('CREATE DATABASE ['+$clientDatabase+'] COLLATE Latin1_General_100_CI_AS;')
    $ownedDatabases.Add($clientDatabase);$uncertainDatabase=$null;$journal.databases=@($ownedDatabases);SaveJournal
   }
   $builder['Initial Catalog']=$database;$connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$connection.Open()
   try{
    $phase=$mode+'-result-table';Batches $connection (Expand (Join-Path $repoRoot 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql')) $mode
    if($PredecessorRoot){
     $phase=$mode+'-predecessors';Batches $connection ([IO.File]::ReadAllText((Join-Path $oldRoot 'Artifacts/Deploy.WithAssembly.sql'))) $mode
     # Nur Includes aus dem separat exportierten Vorgängerbaum auflösen.
     $oldClone=Join-Path $PredecessorRoot 'Modules/toolbelt.metadata.table-clone/Deployment/Deploy.sql'
     $oldCloneSql=[regex]::Replace([IO.File]::ReadAllText($oldClone),'(?m)^:r\s+([^\r\n]+)\s*$',{param($m)
      $file=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $oldClone) $m.Groups[1].Value.Trim()))
      if(-not $file.StartsWith($PredecessorRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_PREDECESSOR_INCLUDE_INVALID'}
      [IO.File]::ReadAllText($file)
     })
     Batches $connection $oldCloneSql $mode
     $versions=Query $connection "SELECT COUNT_BIG(*) AS N FROM sys.extended_properties WITH(NOLOCK) WHERE class=0 AND ((name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version' AND CONVERT(nvarchar(64),value)=N'2.0.0') OR (name=N'Toolbelt.Module.toolbelt.metadata.table-clone.Version' AND CONVERT(nvarchar(64),value)=N'4.1.0'));"
     if($versions.Rows[0].N -ne 2){throw 'SSIS_GENUINE_PREDECESSOR_INSTALLATION_MISSING'}
     Batches $connection ([IO.File]::ReadAllText((Join-Path $PredecessorRoot 'Modules/toolbelt.metadata.table-clone/Tests/Runtime/Trigger.Contract.sql'))) $mode
     NonQuery $connection 'DROP TABLE #TriggerMap,#TriggerPlan;'
    }
    $phase=$mode+'-parser';Batches $connection ([IO.File]::ReadAllText((Join-Path $parserRelease 'Deploy.WithAssembly.sql'))) $mode
    if($PredecessorRoot){
     $phase=$mode+'-consumer-upgrade';Batches $connection (Expand (Join-Path $repoRoot 'Modules/toolbelt.metadata.table-clone/Deployment/Deploy.sql')) $mode
     Batches $connection (Expand (Join-Path $repoRoot 'Modules/toolbelt.metadata.table-clone/Deployment/Deploy.sql')) $mode
     $versions=Query $connection "SELECT COUNT_BIG(*) AS N FROM sys.extended_properties WITH(NOLOCK) WHERE class=0 AND ((name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version' AND CONVERT(nvarchar(64),value)=N'2.0.1') OR (name=N'Toolbelt.Module.toolbelt.metadata.table-clone.Version' AND CONVERT(nvarchar(64),value)=N'4.1.1'));"
     if($versions.Rows[0].N -ne 2){throw 'SSIS_COUPLED_UPGRADE_INCOMPLETE'}
     Batches $connection ([IO.File]::ReadAllText((Join-Path $repoRoot 'Modules/toolbelt.metadata.table-clone/Tests/Runtime/Trigger.Contract.sql'))) $mode
     NonQuery $connection 'DROP TABLE #TriggerMap,#TriggerPlan;'
     "SSIS_GENUINE_UPGRADE_TRIGGER_PASS Windows $Version $mode"
    }
    $phase=$mode+'-ssis'
    if($InstallationPackageRoot){
     $phase=$mode+'-package-fresh-install'
     & (Join-Path $PSScriptRoot 'Invoke-PackageInstallCases.ps1') -Connection $connection -Mode $mode -Release $ssisRelease -ExpectedHash $qualifiedProvider -Fixture (Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx')
     $journal['packageFreshInstall']='PASS';SaveJournal
    }
    if($SsisPredecessorReleaseDirectory){
     $phase=$mode+'-ssis-build-upgrade'
     $upgradeArguments=@{Connection=$connection;Mode=$mode;PreviousRelease=$SsisPredecessorReleaseDirectory;CurrentRelease=$ssisRelease;ExpectedOldHash=$oldQualified;ExpectedNewHash=$qualifiedProvider}
     if($SsisIntermediateReleaseDirectory){$upgradeArguments.IntermediateRelease=$SsisIntermediateReleaseDirectory;$upgradeArguments.ExpectedIntermediateHash=$intermediateHash}
     & (Join-Path $PSScriptRoot 'Invoke-SsisBuildUpgradeCases.ps1') @upgradeArguments
     $journal['ssisBuildUpgrade']='PASS';SaveJournal
    }else{Batches $connection ([IO.File]::ReadAllText((Join-Path $ssisRelease 'Deploy.WithAssembly.sql'))) $mode}
    $phase=$mode+'-repeat';Batches $connection ([IO.File]::ReadAllText((Join-Path $ssisRelease 'Deploy.WithAssembly.sql'))) $mode
    if(-not $ApiOnly){$phase=$mode+'-core'; & (Join-Path $PSScriptRoot 'Invoke-CoreContract.ps1') -Connection $connection -Full:$Full -CrossDatabase $clientDatabase}
    $phase=$mode+'-api'; & (Join-Path $PSScriptRoot 'Invoke-ApiCases.ps1') -Connection $connection
    if($Full){$phase=$mode+'-lifecycle'; & (Join-Path $PSScriptRoot 'Invoke-LifecycleCases.ps1') -Connection $connection -Mode $mode}
    $phase=$mode+'-uninstall';Batches $connection ([IO.File]::ReadAllText((Join-Path $ssisRelease 'Uninstall.Expanded.sql'))) $mode;Batches $connection ([IO.File]::ReadAllText((Join-Path $ssisRelease 'Uninstall.Expanded.sql'))) $mode
    $remaining=Query $connection "SELECT COUNT_BIG(*) AS N FROM sys.objects WITH (NOLOCK) WHERE schema_id=SCHEMA_ID(N'toolbelt_tsql') AND name IN(N'USP_ExplainSsisDataFlow',N'USP_ExplainSsisDataFlowInternal');"
    if($remaining.Rows[0].N -ne 0){throw 'SSIS_LAB_UNINSTALL_INCOMPLETE'}
    "SSIS_LAB_MODE_PASS Windows $Version $mode Functional"
   }finally{$connection.Dispose()}
  }
 }catch{
  $leaf=$_.Exception;while($leaf.InnerException){$leaf=$leaf.InnerException}
  if($phase -like '*-core' -and $leaf -is [Data.SqlClient.SqlException] -and $leaf.Message.Contains('6522')){
   # Nur das eigene synthetische Template direkt am internen CLR-Einstieg
   # prüfen, damit ein maskierter Host-/Frameworkfehler eingegrenzt wird.
   $probe=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
   try{
    $probe.Open();$cmd=$probe.CreateCommand();$cmd.CommandTimeout=40;$cmd.CommandType='StoredProcedure';$cmd.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlowInternal'
    [void]$cmd.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1);$cmd.Parameters['@PackageBytes'].Value=[IO.File]::ReadAllBytes((Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
    foreach($name in @('ProjectContext','Bindings','CatalogBindings','LookupPolicies')){[void]$cmd.Parameters.Add('@'+$name,[Data.SqlDbType]::NVarChar,-1);$cmd.Parameters['@'+$name].Value=[DBNull]::Value}
    [void]$cmd.Parameters.Add('@Operation',[Data.SqlDbType]::NVarChar,32);$cmd.Parameters['@Operation'].Value='bindings-template'
    $reader=$cmd.ExecuteReader();$reader.Dispose()
    # Ein erfolgreicher Templatepfad lokalisiert keine späteren Hostfehler.
    # Derselbe feste Explain-Aufruf prüft auch den ResultTable-Adapter.
    $cmd.Parameters['@Operation'].Value='explain'
    $cmd.Parameters['@CatalogBindings'].Value=(@{schemaVersion=1;defaultDatabase=$database;databases=@($database);connections=@{'Package.ConnectionManagers[Synthetic]'=$database}}|ConvertTo-Json -Depth 4 -Compress)
    $reader=$cmd.ExecuteReader();$reader.Dispose()
    NonQuery $probe 'CREATE TABLE #SsisProbe(Dummy bit NULL);'
    [void]$cmd.Parameters.Add('@ResultTable',[Data.SqlDbType]::NVarChar,128);$cmd.Parameters['@ResultTable'].Value='#SsisProbe'
    $reader=$cmd.ExecuteReader();$reader.Dispose()
   }catch{$inner=$_.Exception;while($inner.InnerException){$inner=$inner.InnerException};$leaf=$inner}finally{$probe.Dispose()}
  }
  $failed=if($leaf -is [Data.SqlClient.SqlException]){'SQL_'+$leaf.Number+'_LINE_'+$leaf.LineNumber}else{'ADAPTER_'+$leaf.GetType().Name}
  $journal.state='FAILED';$journal.phase=$phase;$journal.failure=$failed;SaveJournal
  # Fehlermeldungen nur mit redigierten Verbindungs-/DB-Bezeichnern im Chat.
  $detail=$leaf.Message
  foreach($secret in @([string]$target.host,[string]$target.username,[string]$target.password)+@($ownedDatabases)){if($secret){$detail=$detail.Replace($secret,'<redacted>')}}
  if($detail.Length -gt 3000){$detail=$detail.Substring(0,3000)}
  Write-Output ('SSIS_LAB_FAILURE '+$phase+' '+$failed+' '+$detail)
 }finally{
  $ssisNativeCleanupPhase=$true
  $cleanupOk=$true
  if($uncertainDatabase){$unknown=Query $master ("SELECT COUNT_BIG(*) AS N FROM sys.databases WITH (NOLOCK) WHERE name=N'"+$uncertainDatabase+"';");if($unknown.Rows[0].N -ne 0){$cleanupOk=$false}}
  foreach($database in $ownedDatabases){try{NonQuery $master ('IF DB_ID(N'''+$database+''') IS NOT NULL DROP DATABASE ['+$database+'];')}catch{$cleanupOk=$false}}
  foreach($hash in $ownedTrust){
   try{
    $used=$false;$dbs=Query $master "SELECT name,state_desc,HAS_DBACCESS(name) AS A FROM sys.databases WITH (NOLOCK);"
    foreach($db in $dbs.Rows){if($db.state_desc -ne 'ONLINE' -or $db.A -ne 1){$used=$true;break};$dbName=([string]$db.name).Replace(']',']]');$references=Query $master ('SELECT COUNT_BIG(*) AS N FROM ['+$dbName+'].sys.assembly_files AS f WITH (NOLOCK) WHERE f.file_id=1 AND HASHBYTES(''SHA2_512'',f.content)=0x'+$hash+';');if($references.Rows[0].N -gt 0){$used=$true;break}}
    if(-not $used){
     $entry=Query $master ('SELECT description FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x'+$hash+';')
     if($entry.Rows.Count -gt 0){
      if([string]$entry.Rows[0].description -cne $description){throw 'SSIS_LAB_TRUST_OWNERSHIP_DRIFT'}
      NonQuery $master ("IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x"+$hash+" AND description COLLATE Latin1_General_100_BIN2=N'"+$description+"') EXEC sys.sp_drop_trusted_assembly @hash=0x"+$hash+';')
      $entry=Query $master ('SELECT COUNT_BIG(*) AS N FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=0x'+$hash+';');if($entry.Rows[0].N -ne 0){throw 'SSIS_LAB_TRUST_OWNERSHIP_DRIFT'}
     }
    }else{$cleanupOk=$false}
   }catch{$cleanupOk=$false}
  }
  if($configChanged){
   try{
    if($configAfter.Count -eq 0 -or $configAfter.Count -ne $configBefore.Count){throw 'SSIS_LAB_CONFIGURATION_AFTER_STATE_UNCONFIRMED'}
    $current=Query $master 'SELECT name,CONVERT(int,value) AS Configured,CONVERT(int,value_in_use) AS Running FROM sys.configurations WITH (NOLOCK);'
    foreach($expected in $configAfter){$row=@($current.Rows|Where-Object{$_.name -eq $expected.name})[0];if($row.Configured -ne $expected.configured -or $row.Running -ne $expected.running){throw 'CONFIGURATION_DRIFT'}}
    if(@($current.Rows|Where-Object{$_.Configured -ne $_.Running -and $_.name -notin $configBefore.name}).Count){throw 'FOREIGN_PENDING_CONFIGURATION'}
    NonQuery $master "EXEC sys.sp_configure N'show advanced options',1;";ReconfigureProtected $master
    foreach($old in $configBefore|Where-Object{$_.name -ne 'show advanced options'}){NonQuery $master ("EXEC sys.sp_configure @configname=N'"+$old.name.Replace("'","''")+"',@configvalue="+$old.running+';')}
    ReconfigureProtected $master
    $advanced=@($configBefore|Where-Object{$_.name -eq 'show advanced options'})[0];NonQuery $master ("EXEC sys.sp_configure N'show advanced options',"+$advanced.running+';');ReconfigureProtected $master
    foreach($old in $configBefore){if($old.configured -ne $old.running){NonQuery $master ("EXEC sys.sp_configure @configname=N'"+$old.name.Replace("'","''")+"',@configvalue="+$old.configured+';')}}
    $restored=Query $master 'SELECT name,CONVERT(int,value) AS Configured,CONVERT(int,value_in_use) AS Running FROM sys.configurations WITH (NOLOCK);'
    foreach($old in $configBefore){$row=@($restored.Rows|Where-Object{$_.name -eq $old.name})[0];if($row.Configured -ne $old.configured -or $row.Running -ne $old.running){throw 'CONFIGURATION_RESTORE_VERIFICATION_FAILED'}}
    $journal.configurationRestored=$true
   }catch{$cleanupOk=$false;$journal.configurationRestored=$false}
  }
  $journal.state=if($cleanupOk){if($failed){'FAILED_CLEANED'}else{'PASS_CLEANED'}}else{'RECOVERY_REQUIRED'};SaveJournal;$master.Dispose()
  if(-not $cleanupOk){throw 'SSIS_LAB_CLEANUP_REQUIRES_OWNERSHIP_AUDIT'}
 }
 if($failed){throw ('SSIS_LAB_TEST_FAILED_'+$phase+'_'+$failed)}
 "SSIS_LAB_TARGET_PASS Windows $Version Functional; authenticated TLS not executed"
}
