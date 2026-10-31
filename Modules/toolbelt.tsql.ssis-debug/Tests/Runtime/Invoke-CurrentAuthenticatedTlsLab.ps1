[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$LabModuleFile,
 [Parameter(Mandatory)][string]$LabTlsStateRoot,
 [Parameter(Mandatory)][string]$LabTlsRunId,
 [Parameter(Mandatory)][string]$LabTlsInstanceId,
 [Parameter(Mandatory)][string]$ExportPath,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedExportSha256,
 [Parameter(Mandatory)][string]$InputManifestPath,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedInputManifestSha256,
 [Parameter(Mandatory)][string]$SsisReleaseDirectory,
 [Parameter(Mandatory)][string]$ParserReleaseDirectory,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
 [Parameter(Mandatory)][string]$JournalDirectory,
 [string]$AuditJournalPath,
 [ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedAuditJournalSha256,
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not $IsWindows -or $PSVersionTable.PSVersion -lt [version]'7.5'){throw 'SSIS_TLS_WINDOWS_POWERSHELL_7_5_REQUIRED'}
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$labRoot=Split-Path -Parent ([IO.Path]::GetFullPath($LabModuleFile))
if((Split-Path -Leaf $LabModuleFile) -cne 'SqlServerLab.psd1'){throw 'SSIS_TLS_EXPLICIT_LAB_MODULE_REQUIRED'}
$privateRoot=Join-Path $repository '.runtime'
foreach($path in @($InputManifestPath,$JournalDirectory,$ExportPath)){
 if(-not [IO.Path]::IsPathRooted($path)){throw 'SSIS_TLS_EXPLICIT_PATH_REQUIRED'}
}
if(-not ([IO.Path]::GetFullPath($JournalDirectory)).StartsWith($privateRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_TLS_PRIVATE_JOURNAL_REQUIRED'}
if((Get-FileHash -LiteralPath $InputManifestPath).Hash -cne $ExpectedInputManifestSha256){throw 'SSIS_TLS_MANIFEST_CHANGED'}
$inputs=Get-Content -LiteralPath $InputManifestPath -Raw|ConvertFrom-Json -DateKind String
if($inputs.schemaVersion -ne 1 -or $inputs.profile -cne 'ssis-current-authenticated-tls'){throw 'SSIS_TLS_MANIFEST_SCHEMA'}
function Assert-SsisTlsInputs {
 $seen=@{}
 foreach($entry in $inputs.files){
  $root=switch -CaseSensitive ($entry.repository){'toolbelt'{$repository};'lab'{$labRoot};default{throw 'SSIS_TLS_INPUT_REPOSITORY'}}
  $file=[IO.Path]::GetFullPath((Join-Path $root $entry.path));$key=$entry.repository+':'+$file
  if(-not $file.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or $seen.ContainsKey($key) -or
     $entry.sha256 -cnotmatch '^[0-9A-F]{64}$' -or (Get-FileHash -LiteralPath $file).Hash -cne $entry.sha256){throw 'SSIS_TLS_EXECUTION_INPUT_CHANGED'}
  $seen[$key]=$true
 }
 # Der gesamte importierbare Labcode und beide gemeinsamen Consumerdateien
 # müssen enthalten sein; eine handverlesene unvollständige Importliste genügt nicht.
 $required=@(Get-ChildItem -LiteralPath (Join-Path $labRoot 'Private'),(Join-Path $labRoot 'Public'),(Join-Path $labRoot 'Providers'),(Join-Path $labRoot 'Catalogs'),(Join-Path $labRoot 'Schemas') -Recurse -File|Where-Object Extension -In @('.ps1','.psm1','.json'))
 $required+=@(Get-Item -LiteralPath $LabModuleFile,(Join-Path $labRoot 'SqlServerLab.psm1'),(Join-Path $labRoot 'Schemas/test-environment-authenticated.schema.json'))
 foreach($file in $required){if(-not $seen.ContainsKey('lab:'+$file.FullName)){throw 'SSIS_TLS_LAB_DEPENDENCY_MISSING'}}
 foreach($dir in @('Runtime','Fixtures','../Contracts')){
  $path=if($dir -ceq '../Contracts'){Join-Path $PSScriptRoot '../../Contracts'}else{Join-Path $PSScriptRoot ('../'+$dir)}
  foreach($file in @(Get-ChildItem -LiteralPath $path -Recurse -File|Where-Object {$_.FullName -notmatch '__pycache__'})){
   if(-not $seen.ContainsKey('toolbelt:'+$file.FullName)){throw 'SSIS_TLS_TEST_CLOSURE_MISSING'}
  }
 }
 foreach($name in @('Invoke-CurrentAuthenticatedTlsLab.ps1','Invoke-LabContract.ps1','Invoke-ComponentsV2Audit.ps1','Invoke-CurrentCases.ps1','Invoke-CurrentQualificationLab.ps1')){
  if(-not $seen.ContainsKey('toolbelt:'+(Join-Path $PSScriptRoot $name))){throw 'SSIS_TLS_TEST_DEPENDENCY_MISSING'}
 }
 foreach($name in @('Tests/CI/LabQualifiedContract.ps1','Tests/CI/run-lab-local.ps1')){if(-not $seen.ContainsKey('toolbelt:'+(Join-Path $repository $name).Replace('/','\'))){throw 'SSIS_TLS_CONSUMER_DEPENDENCY_MISSING'}}
}
Assert-SsisTlsInputs
. (Join-Path $repository 'Tests/CI/LabQualifiedContract.ps1')
$tlsContext=[pscustomobject]@{ModuleFile=$LabModuleFile;StateRoot=$LabTlsStateRoot;RunId=$LabTlsRunId;InstanceId=$LabTlsInstanceId}
$tlsBytes=[IO.File]::ReadAllBytes($ExportPath)
if((Get-LabContractByteHash $tlsBytes).ToUpperInvariant() -cne $ExpectedExportSha256){throw 'SSIS_TLS_EXPORT_CHANGED'}
function Read-SsisTlsSnapshot {
 Assert-SsisTlsInputs
 $snapshot=Read-LabQualifiedSnapshot $tlsBytes $tlsContext
 Assert-LabQualifiedConnectWindow $snapshot
 $entry=$snapshot.Contract.environments[0]
 if($entry.platform -cne 'windows' -or $entry.provider -cne 'hyperv' -or $entry.sqlVersion -cne '2025' -or $entry.patch -cne 'base' -or
    $entry.resolvedVersion -cne '17.0.1000.7' -or $entry.runId -cne $LabTlsRunId -or $entry.instanceId -cne $LabTlsInstanceId){throw 'SSIS_TLS_EXACT_WINDOWS_TARGET_REQUIRED'}
 return $snapshot
}
$tlsOpens=0
function Test-SsisTlsImplicitConfigurationValue([object]$Row){
 # SQL dokumentiert diese Defaultdarstellungen ausdrücklich als erwartete
 # Abweichung, nicht als ausstehende Änderung. Weiter exakt beobachten und
 # prüfen, aber bei der Wiederherstellung keinen Speicherparameter schreiben.
 # https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-configurations-transact-sql
 return $Row.Configured -eq 0 -and (
  ($Row.name -ceq 'min server memory (MB)' -and $Row.Running -in @(8,16)) -or
  ($Row.name -ceq 'max server memory (MB)' -and $Row.Running -eq 2147483647))
}
function Open-SsisTlsConnection([Data.SqlClient.SqlConnection]$Channel){
 $snapshot=Read-SsisTlsSnapshot;$entry=$snapshot.Contract.environments[0]
 $settings=[Data.SqlClient.SqlConnectionStringBuilder]::new($Channel.ConnectionString)
 try{
  if(-not $settings.Encrypt -or $settings.TrustServerCertificate -or $settings.Pooling -or $settings.ConnectRetryCount -ne 0 -or
     $settings.DataSource -cne ('tcp:'+$entry.host+','+$entry.port) -or $settings.UserID -cne $entry.username -or $settings.Password -cne $entry.password){throw 'SSIS_TLS_CONNECTION_DRIFT'}
 }finally{$settings.Clear()}
 Assert-LabQualifiedConnectWindow $snapshot
 $Channel.Open()
 $command=$Channel.CreateCommand();$command.CommandTimeout=15
 try{
  $command.CommandText="SELECT CONVERT(varchar(32),SERVERPROPERTY('ProductVersion')),encrypt_option FROM sys.dm_exec_connections WHERE session_id=@@SPID;"
  $reader=$command.ExecuteReader()
  try{if(-not $reader.Read() -or $reader.GetString(0) -cne '17.0.1000.7' -or $reader.GetString(1) -cne 'TRUE' -or $reader.Read()){throw 'SSIS_TLS_TRANSPORT_WITNESS'}}finally{$reader.Dispose()}
 }catch{$Channel.Dispose();throw}finally{$command.Dispose()}
 $script:tlsOpens++
}
$binder=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-CurrentQualificationLab.ps1'),[ref]$null,[ref]$null)
$definition=@($binder.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Bind-CurrentScriptRoot'},$true))
if($definition.Count -ne 1){throw 'SSIS_TLS_ROOT_BINDER'}
. ([scriptblock]::Create($definition[0].Extent.Text))
function Replace-SsisTlsOnce([string]$Text,[string]$Old,[string]$New){
 if(($Text.Split($Old).Count-1) -ne 1){throw 'SSIS_TLS_ADAPTER_ANCHOR'}
 return $Text.Replace($Old,$New)
}
if($AuditJournalPath){
 if(-not $ExpectedAuditJournalSha256){throw 'SSIS_TLS_AUDIT_JOURNAL_HASH_REQUIRED'}
 $text=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Invoke-ComponentsV2Audit.ps1'))
 $start=$text.IndexOf('$lab=Resolve-LabContract');$end=$text.IndexOf('if($ValidateOnly)', $start)
 if($start -lt 0 -or $end -le $start){throw 'SSIS_TLS_AUDIT_SELECTION_ANCHOR'}
 $text=$text.Substring(0,$start)+'$snapshot=Read-SsisTlsSnapshot;$targets=@($snapshot.Contract.environments[0]);'+"`n"+$text.Substring($end)
 $text=$text.Replace("-TestPurpose Functional",'-TestPurpose AuthenticatedTls').Replace("'Functional'","'AuthenticatedTls'")
 $text=$text.Replace("`$builder['Pooling']=`$false","`$builder['Pooling']=`$false;`$builder['ConnectRetryCount']=0")
 $text=Replace-SsisTlsOnce $text '$connection.Open()' 'Open-SsisTlsConnection $connection'
 $text=$text.Replace('Functional; authenticated TLS not executed','AuthenticatedTls; same signed V2 bytes freshly checked before login')
 $text=Bind-CurrentScriptRoot $text $PSScriptRoot
 & ([scriptblock]::Create($text)) -Version 2025 -Patch base -ExpectedTargetKey 'WINDOWS_SQL2025_BASE_TLS' -ExpectedContractSha256 $ExpectedExportSha256 -JournalPath $AuditJournalPath -ExpectedJournalSha256 $ExpectedAuditJournalSha256 -ValidateOnly:$ValidateOnly
}else{
 $original=Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'
 if((Get-FileHash $original).Hash -cne '4411A966484EAF55FB05778B5E26829D7AFED94D6028CB6F77323F92C5C7E570'){throw 'SSIS_TLS_ORIGINAL_HARNESS_CHANGED'}
 $text=[IO.File]::ReadAllText($original)
 foreach($line in @($text -split "`n"|Where-Object {$_ -match 'Invoke-(CoreContract|ApiCases|ReleaseRightsCases|LifecycleCases)\.ps1'})){$text=Replace-SsisTlsOnce $text $line ''}
 $anchor="    `$phase=`$mode+'-repeat';Batches `$connection ([IO.File]::ReadAllText((Join-Path `$ssisRelease 'Deploy.WithAssembly.sql'))) `$mode"
 $call="`n    `$phase=`$mode+'-current-tls'; & (Join-Path `$PSScriptRoot 'Invoke-CurrentCases.ps1') -Connection `$connection -CrossDatabase `$clientDatabase"
 $text=Replace-SsisTlsOnce $text $anchor ($anchor+$call)
 $start=$text.IndexOf('$lab=Resolve-LabContract');$end=$text.IndexOf('$journalRoot=', $start)
 if($start -lt 0 -or $end -le $start){throw 'SSIS_TLS_SELECTION_ANCHOR'}
 $text=$text.Substring(0,$start)+'$snapshot=Read-SsisTlsSnapshot;$targets=@($snapshot.Contract.environments[0]);'+"`n"+$text.Substring($end)
 $preflight='$targetOrdinal++;[void](Invoke-LabPreflight -Entry $target -TestPurpose Functional)'
 $text=Replace-SsisTlsOnce $text $preflight '$targetOrdinal++'
 $text=$text.Replace('-TestPurpose Functional','-TestPurpose AuthenticatedTls').Replace("purpose='Functional';authenticatedTls='not executed'","purpose='AuthenticatedTls';authenticatedTls='strict same-byte V2; per-open native validation'")
 $text=$text.Replace("`$builder['Pooling']=`$false","`$builder['Pooling']=`$false;`$builder['ConnectRetryCount']=0")
 foreach($name in @('master','connection','probe')){$text=Replace-SsisTlsOnce $text ('$'+$name+'.Open()') ('Open-SsisTlsConnection $'+$name)}
 $text=Replace-SsisTlsOnce $text '$ssisNativeBoundedInvocation=$Modes.Count -eq 1' '$ssisNativeBoundedInvocation=$true'
 # Den unveränderten historischen Harness komponieren; dessen Originalpins
 # bleiben gültig. Implizite Speicherdefaults bleiben im Vor-/Nachzustand und
 # im unabhängigen Audit, werden aber von beiden Schreibschleifen ausgenommen.
 $text=Replace-SsisTlsOnce $text 'foreach($old in $configBefore|Where-Object{$_.name -ne ''show advanced options''})' 'foreach($old in $configBefore|Where-Object{$_.name -ne ''show advanced options'' -and -not (Test-SsisTlsImplicitConfigurationValue $_)})'
 $text=Replace-SsisTlsOnce $text 'foreach($old in $configBefore){if($old.configured -ne $old.running){' 'foreach($old in $configBefore){if($old.configured -ne $old.running -and -not (Test-SsisTlsImplicitConfigurationValue $old)){'
 $text=$text.Replace("scope='SSIS V1 native local/central'","scope='SSIS current authenticated TLS native local/central'")
 $text=$text.Replace('Functional; authenticated TLS not executed','AuthenticatedTls; same signed V2 bytes freshly checked before login').Replace('$mode Functional','$mode AuthenticatedTls')
 $text=Bind-CurrentScriptRoot $text $PSScriptRoot
 $errors=$null;[void][Management.Automation.Language.Parser]::ParseInput($text,[ref]$null,[ref]$errors)
 if($errors.Count){throw 'SSIS_TLS_ADAPTER_SYNTAX'}
 if($ValidateOnly){'SSIS_CURRENT_TLS_ADAPTER_VALIDATED; no SQL';return}
 & ([scriptblock]::Create($text)) -Version 2025 -Patch base -Modes @('local','central') -CompatibilityLevel 170 -Full -JournalDirectory $JournalDirectory -SsisReleaseDirectory $SsisReleaseDirectory -ParserReleaseDirectory $ParserReleaseDirectory -QualifiedProviderSha512 $QualifiedProviderSha512
}
Assert-SsisTlsInputs
"SSIS_CURRENT_AUTHENTICATED_TLS_PASS; strict SqlClient; actual Windows SQL2025 RTM; $tlsOpens fresh guarded connections; no fallback"
