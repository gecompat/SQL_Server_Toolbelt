[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('2019','2022','2025')][string]$Version,
 [string]$Patch='base',
 [Parameter(Mandatory)][ValidateSet('local','central')][string]$Mode,
 [Parameter(Mandatory)][ValidateSet(150,160,170)][int]$CompatibilityLevel,
 [Parameter(Mandatory)][string]$JournalDirectory,
 [Parameter(Mandatory)][string]$ExpectedTargetKey,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedContractSha256,
 [Parameter(Mandatory)][string]$SsisReleaseDirectory,
 [Parameter(Mandatory)][string]$ParserReleaseDirectory,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$CasesExpectedSha256,
 [Parameter(Mandatory)][string]$InputManifestPath,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedInputManifestSha256,
 [ValidateSet('Latin1_General_100_BIN2','Latin1_General_100_CS_AS','Latin1_General_100_CI_AS_SC_UTF8')][string]$DatabaseCollation='Latin1_General_100_BIN2',
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -ne 7){throw 'SSIS_CURRENT_SNAPSHOT_POWERSHELL_7_REQUIRED'}
if($Version -cne '2025' -or $Patch -cne 'CU8' -or $CompatibilityLevel -ne 170){throw 'SSIS_CURRENT_SNAPSHOT_FIXED_TARGET_SCOPE'}
$helper=Join-Path $PSScriptRoot 'CurrentSnapshotHelpers.ps1'
. $helper
Invoke-SnapshotOfflineChecks
$original=Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'
$cases=Join-Path $PSScriptRoot 'Invoke-CurrentSnapshotCases.ps1'
$fixture=Join-Path $PSScriptRoot '../Fixtures/components-v2-rowcount.dtsx'
$helper=Join-Path $PSScriptRoot 'CurrentSnapshotHelpers.ps1'
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
if(-not (Test-SnapshotNoReparsePath $InputManifestPath $repository)){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_MANIFEST_PATH'}
$manifestInfo=Get-Item -LiteralPath $InputManifestPath -Force
if($manifestInfo.Length -lt 1 -or $manifestInfo.Length -gt 1048576){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_MANIFEST_SIZE'}
$manifestBytes=[IO.File]::ReadAllBytes($InputManifestPath)
$manifestHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($manifestBytes))
if($manifestHash -cne $ExpectedInputManifestSha256){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_MANIFEST_CHANGED'}
$manifestText=[Text.UTF8Encoding]::new($false,$true).GetString($manifestBytes)
$inputManifest=$manifestText|ConvertFrom-Json -Depth 16
if($inputManifest.schemaVersion -ne 1 -or $inputManifest.profile -cne 'ssis-debug-current-snapshot' -or @($inputManifest.files).Count -lt 1 -or @($inputManifest.files).Count -gt 128){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_MANIFEST_SCHEMA'}
$moduleRoot=[IO.Path]::GetFullPath((Join-Path $repository 'Modules/toolbelt.tsql.ssis-debug'))
$parserModuleRoot=[IO.Path]::GetFullPath((Join-Path $repository 'Modules/toolbelt.tsql.script-parser'))
$ssisRelease=[IO.Path]::GetFullPath($SsisReleaseDirectory);$parserRelease=[IO.Path]::GetFullPath($ParserReleaseDirectory)
if(-not (Test-SnapshotNoReparsePath $ssisRelease $repository) -or -not (Test-SnapshotNoReparsePath $parserRelease $repository)){throw 'SSIS_CURRENT_SNAPSHOT_RELEASE_DIRECTORY'}
$currentQualificationPath=Join-Path $moduleRoot 'Tests/Qualification/Current.Windows.CL.20261029.json'
$reuseProvenancePath=Join-Path $repository '.runtime/r38-qualified-reuse.private.json'
$priorInputManifestPath=Join-Path $repository '.runtime/r29-inputs-product-2.private.json'
$ssisTrustPath=Join-Path $ssisRelease 'Toolbelt.Tsql.SsisDebug.trust-manifest.json'
$parserTrustPath=Join-Path $parserRelease 'Toolbelt.Tsql.ScriptParser.trust-manifest.json'
foreach($p in @($currentQualificationPath,$reuseProvenancePath,$priorInputManifestPath,$ssisTrustPath,$parserTrustPath)){if(-not (Test-SnapshotNoReparsePath $p $repository)){throw 'SSIS_CURRENT_SNAPSHOT_PROVENANCE_FILE'}}
$ssisTrust=Get-Content -LiteralPath $ssisTrustPath -Raw|ConvertFrom-Json -Depth 12
$parserTrust=Get-Content -LiteralPath $parserTrustPath -Raw|ConvertFrom-Json -Depth 12
$qualification=Get-Content -LiteralPath $currentQualificationPath -Raw|ConvertFrom-Json -Depth 16
$reuseProvenance=Get-Content -LiteralPath $reuseProvenancePath -Raw|ConvertFrom-Json -Depth 12
$priorInputManifest=Get-Content -LiteralPath $priorInputManifestPath -Raw|ConvertFrom-Json -Depth 12
function Resolve-SnapshotManifestPath([string]$Value){if([IO.Path]::IsPathRooted($Value)){return [IO.Path]::GetFullPath($Value)};return [IO.Path]::GetFullPath((Join-Path $repository $Value))}
$priorInputManifestSha=(Get-FileHash -LiteralPath $priorInputManifestPath -Algorithm SHA256).Hash
$qualificationSha=(Get-FileHash -LiteralPath $currentQualificationPath -Algorithm SHA256).Hash
$ssisDllPath=Join-Path $ssisRelease 'Toolbelt.Tsql.SsisDebug.dll';$ssisDeployPath=Join-Path $ssisRelease 'Deploy.WithAssembly.sql';$ssisUninstallPath=Join-Path $ssisRelease 'Uninstall.Expanded.sql'
$parserDllPath=Join-Path $parserRelease 'Toolbelt.Tsql.ScriptParser.dll';$scriptDomPath=Join-Path $parserRelease 'Microsoft.SqlServer.TransactSql.ScriptDom.dll';$parserDeployPath=Join-Path $parserRelease 'Deploy.WithAssembly.sql'
if($qualification.schema_version -cne '1.0' -or $qualification.profile -cne 'ssis-debug-current' -or $qualification.result -cne 'PASS' -or $qualification.publication_authorized -ne $false -or
   $reuseProvenance.status -cne 'EXACT_QUALIFIED_BYTES_VERIFIED' -or $reuseProvenance.qualification_sha256 -cne $qualificationSha -or
   (Resolve-SnapshotManifestPath ([string]$reuseProvenance.qualification_path)) -cne [IO.Path]::GetFullPath($currentQualificationPath) -or
   (Resolve-SnapshotManifestPath ([string]$reuseProvenance.ssis_release_directory)) -cne $ssisRelease -or (Resolve-SnapshotManifestPath ([string]$reuseProvenance.parser_release_directory)) -cne $parserRelease -or
   [string]$reuseProvenance.qualified_provider_sha512 -cne $QualifiedProviderSha512 -or [string]$reuseProvenance.prior_execution_input_manifest_sha256.ToUpperInvariant() -cne $priorInputManifestSha.ToUpperInvariant() -or
   (Resolve-SnapshotManifestPath ([string]$reuseProvenance.prior_execution_input_manifest)) -cne [IO.Path]::GetFullPath($priorInputManifestPath) -or
   $priorInputManifest.schemaVersion -ne 1 -or $priorInputManifest.profile -cne 'ssis-debug-current' -or
   $qualification.product_source_commit -cne $reuseProvenance.product_source_commit -or
   (Get-FileHash -LiteralPath $ssisDllPath -Algorithm SHA512).Hash -cne $QualifiedProviderSha512 -or
   (Get-FileHash -LiteralPath $ssisDllPath -Algorithm SHA256).Hash -cne ([string]$qualification.qualified_assembly_sha256).ToUpperInvariant() -or
   (Get-FileHash -LiteralPath $ssisDeployPath -Algorithm SHA256).Hash -cne ([string]$qualification.qualified_deploy_sql_sha256).ToUpperInvariant() -or
   (Get-FileHash -LiteralPath $ssisUninstallPath -Algorithm SHA256).Hash -cne ([string]$qualification.qualified_uninstall_sql_sha256).ToUpperInvariant() -or
   (Get-FileHash -LiteralPath $ssisTrustPath -Algorithm SHA256).Hash -cne ([string]$qualification.qualified_trust_manifest_sha256).ToUpperInvariant() -or
   $ssisTrust.sha512 -cne $QualifiedProviderSha512 -or ([string]$ssisTrust.deploymentArtifactSha256).ToUpperInvariant() -cne ([string]$qualification.qualified_deploy_sql_sha256).ToUpperInvariant()){throw 'SSIS_CURRENT_SNAPSHOT_QUALIFICATION_BINDING'}
if(@($reuseProvenance.parser_pins).Count -ne 4){throw 'SSIS_CURRENT_SNAPSHOT_PARSER_PROVENANCE_SHAPE'}
foreach($pin in $reuseProvenance.parser_pins){$pinPath=Resolve-SnapshotManifestPath ([string]$pin.path);if(-not $pinPath.StartsWith($parserRelease+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or (Get-FileHash -LiteralPath $pinPath -Algorithm SHA256).Hash -cne ([string]$pin.sha256).ToUpperInvariant()){throw 'SSIS_CURRENT_SNAPSHOT_PARSER_PROVENANCE_BINDING'}}
$requiredEntries=[Collections.Generic.List[object]]::new()
$requiredEntryByPath=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
function Add-SnapshotRequiredPath([string]$Path,[string]$ExpectedSha256){
 $full=[IO.Path]::GetFullPath($Path)
 if(-not $full.StartsWith($repository+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or -not (Test-SnapshotNoReparsePath $full $repository) -or $ExpectedSha256 -cnotmatch '^[0-9A-Fa-f]{64}$' -or (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash -cne $ExpectedSha256.ToUpperInvariant()){throw 'SSIS_CURRENT_SNAPSHOT_REQUIRED_SOURCE_BINDING'}
 $relative=[IO.Path]::GetRelativePath($repository,$full).Replace('\','/')
 $normalizedHash=$ExpectedSha256.ToUpperInvariant()
 if($requiredEntryByPath.ContainsKey($relative)){if($requiredEntryByPath[$relative] -cne $normalizedHash){throw 'SSIS_CURRENT_SNAPSHOT_REQUIRED_SOURCE_DUPLICATE_DRIFT'};return}
 $requiredEntryByPath.Add($relative,$normalizedHash)
 $requiredEntries.Add([pscustomobject]@{path=$relative;sha256=$normalizedHash})
}
function Add-SnapshotTrustSources($Trust,[string]$SourceRoot){
 $files=@($Trust.sourceFiles)
 if($Trust.PSObject.Properties.Name -contains 'deploymentFiles'){$files+=@($Trust.deploymentFiles)}
 elseif($Trust.PSObject.Properties.Name -contains 'deploymentSourceFiles'){$files+=@($Trust.deploymentSourceFiles)}
 else{throw 'SSIS_CURRENT_SNAPSHOT_TRUST_SOURCE_SCHEMA'}
 foreach($entry in $files){
  if([string]::IsNullOrWhiteSpace([string]$entry)){continue};$parts=([string]$entry).Split(':',2);if($parts.Count -ne 2){throw 'SSIS_CURRENT_SNAPSHOT_TRUST_SOURCE_FORMAT'}
  Add-SnapshotRequiredPath (Join-Path $SourceRoot $parts[0]) $parts[1]
 }
}
Add-SnapshotTrustSources $ssisTrust $moduleRoot
$fixedRequired=@(
 $PSCommandPath,$original,$cases,$fixture,$helper,
 (Join-Path $repository 'Tests/CI/LabQualifiedContract.ps1'),(Join-Path $repository 'Tests/CI/run-lab-local.ps1'),
 (Join-Path $moduleRoot 'Tests/Runtime/Invoke-ApiCases.ps1'),(Join-Path $moduleRoot 'Contracts/Api.json'),(Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'),
 (Join-Path $moduleRoot 'Tests/Runtime/Invoke-ComponentsV2Audit.ps1'),$currentQualificationPath,$reuseProvenancePath,$priorInputManifestPath,
 (Join-Path $repository 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql'),(Join-Path $repository 'Modules/toolbelt.core.result-table/Deployment/Uninstall.sql'),
 (Join-Path $repository 'Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql'),(Join-Path $repository 'Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql'),
 $ssisDllPath,$ssisDeployPath,$ssisUninstallPath,$ssisTrustPath,$parserDeployPath,$scriptDomPath,$parserDllPath,$parserTrustPath
)
foreach($path in $fixedRequired){Add-SnapshotRequiredPath $path (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
if(-not (Test-SnapshotManifestClosure $inputManifest.files $requiredEntries.ToArray())){throw 'SSIS_CURRENT_SNAPSHOT_REQUIRED_INPUT_CLOSURE'}
$externalByRole=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
foreach($entry in @($inputManifest.externalFiles)){
 if($null -eq $entry -or [string]$entry.role -cnotin @('labContract','labSchema','labPrompt') -or $entry.sha256 -cnotmatch '^[0-9A-F]{64}$' -or $externalByRole.ContainsKey([string]$entry.role)){throw 'SSIS_CURRENT_SNAPSHOT_EXTERNAL_BINDING_SHAPE'}
 $full=[IO.Path]::GetFullPath([string]$entry.path);$root=[IO.Path]::GetPathRoot($full)
 if(-not (Test-SnapshotNoReparsePath $full $root) -or (Get-Item -LiteralPath $full -Force).PSIsContainer -or (Get-Item -LiteralPath $full -Force).Length -gt 4194304 -or (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash -cne [string]$entry.sha256){throw 'SSIS_CURRENT_SNAPSHOT_EXTERNAL_BINDING_CHANGED'}
 $externalByRole.Add([string]$entry.role,[pscustomobject]@{path=$full;sha256=[string]$entry.sha256})
}
if(-not $externalByRole.ContainsKey('labContract') -or -not $externalByRole.ContainsKey('labSchema') -or $externalByRole['labContract'].sha256 -cne $ExpectedContractSha256){throw 'SSIS_CURRENT_SNAPSHOT_EXTERNAL_CONTRACT_REQUIRED'}
. (Join-Path $repository 'Tests/CI/LabQualifiedContract.ps1')
$labDiscoveryPath=Join-Path $repository 'Tests/CI/run-lab-local.ps1'
$labParseErrors=$null
$labAst=[Management.Automation.Language.Parser]::ParseFile($labDiscoveryPath,[ref]$null,[ref]$labParseErrors)
if($labParseErrors.Count){throw 'SSIS_CURRENT_SNAPSHOT_LAB_DISCOVERY_SYNTAX'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString','Invoke-LabPreflight')){$definitions=@($labAst.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name},$true));if($definitions.Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_LAB_DISCOVERY_BINDING'};. ([scriptblock]::Create($definitions[0].Extent.Text))}
$liveLab=Resolve-LabContract -TestPurpose Functional
if([IO.Path]::GetFullPath($liveLab.Path) -cne $externalByRole['labContract'].path -or [IO.Path]::GetFullPath($liveLab.SchemaPath) -cne $externalByRole['labSchema'].path -or (Get-FileHash -LiteralPath $liveLab.Path -Algorithm SHA256).Hash -cne $externalByRole['labContract'].sha256 -or (Get-FileHash -LiteralPath $liveLab.SchemaPath -Algorithm SHA256).Hash -cne $externalByRole['labSchema'].sha256){throw 'SSIS_CURRENT_SNAPSHOT_LAB_CONTRACT_BINDING'}
$promptPath=Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
if(-not [string]::IsNullOrWhiteSpace($promptPath)){if(-not $externalByRole.ContainsKey('labPrompt') -or [IO.Path]::GetFullPath($promptPath) -cne $externalByRole['labPrompt'].path){throw 'SSIS_CURRENT_SNAPSHOT_LAB_PROMPT_BINDING'}}elseif($externalByRole.ContainsKey('labPrompt')){throw 'SSIS_CURRENT_SNAPSHOT_UNEXPECTED_LAB_PROMPT'}
$selectedTargets=@(Get-LabTargetsForSelector -Contract $liveLab.Contract -Selector ([pscustomobject]@{Platform='windows';Version='2025';Patch='CU8'}))
if($selectedTargets.Count -ne 1 -or [string]$selectedTargets[0].key -cne $ExpectedTargetKey){throw 'SSIS_CURRENT_SNAPSHOT_LAB_TARGET_BINDING'}
$script:snapshotInputManifestPath=[IO.Path]::GetFullPath($InputManifestPath);$script:snapshotInputManifestHash=$ExpectedInputManifestSha256;$script:snapshotRepository=$repository
$script:snapshotInputEntries=@($inputManifest.files);$script:snapshotExternalEntries=@($inputManifest.externalFiles)
$snapshotInputBinding=[pscustomobject]@{manifestPath=$script:snapshotInputManifestPath;sha256=$script:snapshotInputManifestHash;repositoryRoot=$script:snapshotRepository;files=$script:snapshotInputEntries;externalFiles=$script:snapshotExternalEntries}
Assert-SnapshotCurrentInputs $snapshotInputBinding
$parseErrors=$null
[void][Management.Automation.Language.Parser]::ParseFile($cases,[ref]$null,[ref]$parseErrors)
if($parseErrors.Count){throw 'SSIS_CURRENT_SNAPSHOT_CASES_SYNTAX'}
function Bind-SnapshotScriptRoot([string]$Text,[string]$Root){
 $errors=$null;$tree=[Management.Automation.Language.Parser]::ParseInput($Text,[ref]$null,[ref]$errors)
 if($errors.Count){throw 'SSIS_CURRENT_SNAPSHOT_ROOT_BIND_SYNTAX'}
 $variables=@($tree.FindAll({param($node)$node -is [Management.Automation.Language.VariableExpressionAst] -and $node.VariablePath.UserPath -ceq 'PSScriptRoot'},$true)|Sort-Object {$_.Extent.StartOffset} -Descending)
 if(-not $variables.Count){throw 'SSIS_CURRENT_SNAPSHOT_ROOT_BIND_MISSING'}
 $literal="'"+$Root.Replace("'","''")+"'"
 foreach($variable in $variables){$Text=$Text.Substring(0,$variable.Extent.StartOffset)+$literal+$Text.Substring($variable.Extent.EndOffset)}
 return $Text
}
$text=[IO.File]::ReadAllText($original)
$anchor="    `$phase=`$mode+'-api'; & (Join-Path `$PSScriptRoot 'Invoke-ApiCases.ps1') -Connection `$connection"
if(([regex]::Matches($text,[regex]::Escape($anchor))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_CASE_HOOK_NOT_UNIQUE'}
$insertion=$anchor+"`n    `$phase=`$mode+'-snapshot-coherence'; & (Join-Path `$PSScriptRoot 'Invoke-CurrentSnapshotCases.ps1') -Connection `$connection -FixtureModuleRoot `$moduleRoot -OwnershipJournal `$journal -InputBinding `$SnapshotInputBinding -NewConnection {`$freshBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new(`$builder.ConnectionString);`$freshBuilder['Initial Catalog']=`$connection.Database;`$freshBuilder.Pooling=`$false;`$freshBuilder.Enlist=`$false;`$freshBuilder.ConnectRetryCount=0;`$freshConnection=[Data.SqlClient.SqlConnection]::new(`$freshBuilder.ConnectionString);try{`$freshConnection.Open();`$freshConnection}catch{`$freshConnection.Dispose();throw}}"
$adapted=$text.Replace($anchor,$insertion)
foreach($line in @($text -split "`n"|Where-Object {$_ -match 'Invoke-(CoreContract|ApiCases|ReleaseRightsCases|LifecycleCases)\.ps1'})){
 if(([regex]::Matches($adapted,[regex]::Escape($line))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_CASE_REMOVAL_NOT_UNIQUE'}
 $adapted=$adapted.Replace($line,'')
}
# The old harness has an unconditional database-name DROP in finally. Bind each
# created database to its captured ID, creation timestamp and private owner
# marker, then verify all three immediately before any own-database DROP.
$initAnchor='$ownedDatabases=[Collections.Generic.List[string]]::new();$ownedTrust=[Collections.Generic.List[string]]::new()'
if(([regex]::Matches($adapted,[regex]::Escape($initAnchor))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_OWNERSHIP_INIT_NOT_UNIQUE'}
$adapted=$adapted.Replace($initAnchor,'$ownedDatabases=[Collections.Generic.List[string]]::new();$ownedDatabaseIdentity=@{};$droppedOwnedDatabases=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase);$ownedTrust=[Collections.Generic.List[string]]::new()')
$createAnchor="function NonQuery([Data.SqlClient.SqlConnection]`$Connection,[string]`$Text){`n `$cmd=`$Connection.CreateCommand();`$cmd.CommandText=`$Text;`$cmd.CommandTimeout=Get-SsisNativeTimeout 45`n try{[void]`$cmd.ExecuteNonQuery()}finally{`$cmd.Dispose()}`n}"
if(([regex]::Matches($adapted,[regex]::Escape($createAnchor))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_OWNERSHIP_HELPER_ANCHOR'}
$register=@'
function Register-SnapshotOwnedDatabase([string]$Name){
 $rows=Query $master ("SELECT database_id,CONVERT(varchar(33),create_date,126) AS Created FROM sys.databases WITH (NOLOCK) WHERE name=N'"+$Name.Replace("'","''")+"';")
 if($rows.Rows.Count -ne 1 -or [int]$rows.Rows[0].database_id -le 0){throw 'SSIS_CURRENT_SNAPSHOT_DATABASE_IDENTITY_UNAVAILABLE'}
 $escaped=$Name.Replace(']',']]')
 try{
  NonQuery $master ("USE ["+$escaped+"]; EXEC sys.sp_addextendedproperty @name=N'Toolbelt.NativeOwnerRunId',@value=N'"+$runId+"';")
  $marker=Query $master ("USE ["+$escaped+"]; SELECT CONVERT(nvarchar(64),value) AS OwnerRunId FROM sys.extended_properties WITH (NOLOCK) WHERE class=0 AND name=N'Toolbelt.NativeOwnerRunId';")
  if($marker.Rows.Count -ne 1 -or [string]$marker.Rows[0].OwnerRunId -cne $runId){throw 'SSIS_CURRENT_SNAPSHOT_DATABASE_OWNER_MARKER_FAILED'}
 }finally{NonQuery $master 'USE [master];'}
 $identity=[pscustomobject]@{name=$Name;databaseId=[int]$rows.Rows[0].database_id;created=[string]$rows.Rows[0].Created;ownerRunId=$runId}
 $prior=if($journal.Contains('databaseOwnership')){@($journal['databaseOwnership'])}else{@()}
 $journal['databaseOwnership']=@($prior)+$identity
 return $identity
}
'@
$guardedCreateAnchor=$createAnchor.Replace("`n `$cmd=","`n Assert-SnapshotInputsBound`n `$cmd=")
if($guardedCreateAnchor -ceq $createAnchor){throw 'SSIS_CURRENT_SNAPSHOT_MUTATION_PIN_GUARD_BINDING'}
$adapted=$adapted.Replace($createAnchor,$guardedCreateAnchor+"`n"+$register)
$dbAddAnchor='$ownedDatabases.Add($database);$uncertainDatabase=$null;$journal.databases=@($ownedDatabases);SaveJournal'
if(([regex]::Matches($adapted,[regex]::Escape($dbAddAnchor))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_PRIMARY_DB_REGISTRATION_NOT_UNIQUE'}
$adapted=$adapted.Replace($dbAddAnchor,'$ownedDatabaseIdentity[$database]=Register-SnapshotOwnedDatabase $database;'+$dbAddAnchor)
$clientAddAnchor='$ownedDatabases.Add($clientDatabase);$uncertainDatabase=$null;$journal.databases=@($ownedDatabases);SaveJournal'
if(([regex]::Matches($adapted,[regex]::Escape($clientAddAnchor))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_CLIENT_DB_REGISTRATION_NOT_UNIQUE'}
$adapted=$adapted.Replace($clientAddAnchor,'$ownedDatabaseIdentity[$clientDatabase]=Register-SnapshotOwnedDatabase $clientDatabase;'+$clientAddAnchor)
$dropAnchor="foreach(`$database in `$ownedDatabases){try{NonQuery `$master ('IF DB_ID(N'''+`$database+''') IS NOT NULL DROP DATABASE ['+`$database+'];')}catch{`$cleanupOk=`$false}}"
if(([regex]::Matches($adapted,[regex]::Escape($dropAnchor))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_DROP_GUARD_ANCHOR_NOT_UNIQUE'}
$guardDrop=@'
foreach($database in $ownedDatabases){try{
 $expected=$ownedDatabaseIdentity[$database]
 if($null -eq $expected){throw 'SSIS_CURRENT_SNAPSHOT_DATABASE_IDENTITY_MISSING'}
 $escapedName=$database.Replace("'","''")
 $actual=Query $master ("SELECT database_id,CONVERT(varchar(33),create_date,126) AS Created FROM sys.databases WITH (NOLOCK) WHERE name=N'"+$escapedName+"';")
 if($actual.Rows.Count -ne 1 -or [int]$actual.Rows[0].database_id -ne $expected.databaseId -or [string]$actual.Rows[0].Created -cne $expected.created){throw 'SSIS_CURRENT_SNAPSHOT_DATABASE_IDENTITY_DRIFT'}
 $escapedDatabase=$database.Replace(']',']]')
 try{$marker=Query $master ("USE ["+$escapedDatabase+"]; SELECT CONVERT(nvarchar(64),value) AS OwnerRunId FROM sys.extended_properties WITH (NOLOCK) WHERE class=0 AND name=N'Toolbelt.NativeOwnerRunId';")}
 finally{NonQuery $master 'USE [master];'}
 $cleanupBlocked=($journal.Contains('snapshotCleanupBlocked') -and [bool]$journal['snapshotCleanupBlocked'])
 $observed=[pscustomobject]@{databaseId=[int]$actual.Rows[0].database_id;created=[string]$actual.Rows[0].Created}
 if($marker.Rows.Count -ne 1 -or -not (Test-SnapshotOwnedDatabaseState $expected $observed ([string]$marker.Rows[0].OwnerRunId) $cleanupBlocked)){throw 'SSIS_CURRENT_SNAPSHOT_DATABASE_OWNER_OR_CLEANUP_DRIFT'}
 NonQuery $master ("DROP DATABASE ["+$escapedDatabase+"]; ")
 if(-not (Mark-SnapshotDatabaseDropped $ownedDatabases $droppedOwnedDatabases $database)){throw 'SSIS_CURRENT_SNAPSHOT_DATABASE_DROP_TRACKING_FAILED'}
 [void]$ownedDatabaseIdentity.Remove($database);$journal.droppedDatabases=@($droppedOwnedDatabases|Sort-Object);SaveJournal
}catch{$cleanupOk=$false}}
'@
$adapted=$adapted.Replace($dropAnchor,$guardDrop.Trim())
$configAnchor='  if($configChanged){'
if(([regex]::Matches($adapted,[regex]::Escape($configAnchor))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_CONFIG_GUARD_ANCHOR'}
$adapted=$adapted.Replace($configAnchor,"  if(`$configChanged){`n   if(-not `$cleanupOk -or -not (Test-SnapshotAllDatabasesDropped `$ownedDatabases `$droppedOwnedDatabases)){`$cleanupOk=`$false;`$journal.configurationRestored=`$false}`n   else{")
$configEnd='   }catch{$cleanupOk=$false;$journal.configurationRestored=$false}'
if(([regex]::Matches($adapted,[regex]::Escape($configEnd))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_CONFIG_END_ANCHOR'}
$adapted=$adapted.Replace($configEnd,$configEnd+"`n   }")
$paramAnchor=" [ValidateSet('Latin1_General_100_BIN2','Latin1_General_100_CS_AS','Latin1_General_100_CI_AS_SC_UTF8')][string]`$DatabaseCollation='Latin1_General_100_BIN2'`n)"
if(([regex]::Matches($adapted,[regex]::Escape($paramAnchor))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_PARAMETER_ANCHOR'}
$adapted=$adapted.Replace($paramAnchor," [ValidateSet('Latin1_General_100_BIN2','Latin1_General_100_CS_AS','Latin1_General_100_CI_AS_SC_UTF8')][string]`$DatabaseCollation='Latin1_General_100_BIN2',`n [Parameter(Mandatory)][pscustomobject]`$SnapshotInputBinding`n)")
$errorPreferenceAnchor='$ErrorActionPreference=''Stop'''
if(([regex]::Matches($adapted,[regex]::Escape($errorPreferenceAnchor))).Count -ne 1){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_GUARD_ANCHOR'}
$adapted=$adapted.Replace($errorPreferenceAnchor,$errorPreferenceAnchor+"`nfunction Assert-SnapshotInputsBound{Assert-SnapshotCurrentInputs `$SnapshotInputBinding}")
$adapted=Bind-SnapshotScriptRoot -Text $adapted -Root $PSScriptRoot
$errors=$null
[void][Management.Automation.Language.Parser]::ParseInput($adapted,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_CURRENT_SNAPSHOT_ADAPTED_HARNESS_SYNTAX'}
if($ValidateOnly){'SSIS_CURRENT_SNAPSHOT_LAB_ADAPTER_VALIDATED; no SQL';return}
$invoke=@{Version=$Version;Patch=$Patch;Modes=@($Mode);CompatibilityLevel=$CompatibilityLevel;Full=$true;ReleaseRights=$true;JournalDirectory=$JournalDirectory;ExpectedTargetKey=$ExpectedTargetKey;ExpectedContractSha256=$ExpectedContractSha256;SsisReleaseDirectory=$SsisReleaseDirectory;ParserReleaseDirectory=$ParserReleaseDirectory;QualifiedProviderSha512=$QualifiedProviderSha512;DatabaseCollation=$DatabaseCollation;SnapshotInputBinding=$snapshotInputBinding}
& ([scriptblock]::Create($adapted)) @invoke
