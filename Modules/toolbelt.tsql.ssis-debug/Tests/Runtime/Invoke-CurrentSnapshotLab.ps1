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
if((Get-FileHash -LiteralPath $original -Algorithm SHA256).Hash -cne '4411A966484EAF55FB05778B5E26829D7AFED94D6028CB6F77323F92C5C7E570'){
 throw 'SSIS_CURRENT_SNAPSHOT_ORIGINAL_HARNESS_CHANGED'
}
if((Get-FileHash -LiteralPath $cases -Algorithm SHA256).Hash -cne $CasesExpectedSha256){throw 'SSIS_CURRENT_SNAPSHOT_CASES_CHANGED'}
if((Get-FileHash -LiteralPath $InputManifestPath -Algorithm SHA256).Hash -cne $ExpectedInputManifestSha256){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_MANIFEST_CHANGED'}
$inputManifest=Get-Content -LiteralPath $InputManifestPath -Raw|ConvertFrom-Json -Depth 16
if($inputManifest.schemaVersion -ne 1 -or $inputManifest.profile -cne 'ssis-debug-current-snapshot' -or -not $inputManifest.files.Count){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_MANIFEST_SCHEMA'}
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($entry in $inputManifest.files){
 if([string]$entry.sha256 -cnotmatch '^[0-9A-F]{64}$'){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_HASH_FORMAT'}
 $file=[IO.Path]::GetFullPath((Join-Path $repository ([string]$entry.path)))
 if(-not $file.StartsWith($repository+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($file)){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_PATH'}
 if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -cne [string]$entry.sha256){throw 'SSIS_CURRENT_SNAPSHOT_INPUT_CHANGED'}
}
foreach($required in @($PSCommandPath,$original,$cases,$fixture,$helper)){
 if(-not $seen.Contains([IO.Path]::GetFullPath($required))){throw 'SSIS_CURRENT_SNAPSHOT_REQUIRED_INPUT_MISSING'}
}
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
$insertion=$anchor+"`n    `$phase=`$mode+'-snapshot-coherence'; & (Join-Path `$PSScriptRoot 'Invoke-CurrentSnapshotCases.ps1') -Connection `$connection -FixtureModuleRoot `$moduleRoot -OwnershipJournal `$journal"
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
$adapted=$adapted.Replace($createAnchor,$createAnchor+"`n"+$register)
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
$adapted=Bind-SnapshotScriptRoot -Text $adapted -Root $PSScriptRoot
$errors=$null
[void][Management.Automation.Language.Parser]::ParseInput($adapted,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_CURRENT_SNAPSHOT_ADAPTED_HARNESS_SYNTAX'}
if($ValidateOnly){'SSIS_CURRENT_SNAPSHOT_LAB_ADAPTER_VALIDATED; no SQL';return}
$invoke=@{Version=$Version;Patch=$Patch;Modes=@($Mode);CompatibilityLevel=$CompatibilityLevel;Full=$true;ReleaseRights=$true;JournalDirectory=$JournalDirectory;ExpectedTargetKey=$ExpectedTargetKey;ExpectedContractSha256=$ExpectedContractSha256;SsisReleaseDirectory=$SsisReleaseDirectory;ParserReleaseDirectory=$ParserReleaseDirectory;QualifiedProviderSha512=$QualifiedProviderSha512;DatabaseCollation=$DatabaseCollation}
& ([scriptblock]::Create($adapted)) @invoke
