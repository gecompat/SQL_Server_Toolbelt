[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,[Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,[switch]$AuditOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew(); $cleanup=$false
$connections=[Collections.Generic.List[object]]::new()
# Nur die geprüften Funktionsdefinitionen importieren; kein fremder Teststart.
function Import-ClrFunctions([string]$Path,[string[]]$Names,[hashtable]$Replace=@{}) {
 $errors=$null; $ast=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$null,[ref]$errors)
 if($errors.Count){throw 'RELEASE_HELPER_PARSE'}
 foreach($name in $Names){
  $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
  if($nodes.Count -ne 1){throw 'RELEASE_HELPER_AMBIGUOUS'}
  $text=$nodes[0].Extent.Text
  foreach($key in $Replace.Keys){$text=$text.Replace($key,$Replace[$key])}
  # Definitionen in den Aufruferscope zurückgeben, ohne sie auszuführen.
  [scriptblock]::Create($text)
 }
}
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql','Open-ReleaseConnection',
 'Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1') @('Get-CsvTrust','Assert-CsvTrustCleanupScope') @{
 'Get-CsvTrust'='Get-ClrTrust';'Assert-CsvTrustCleanupScope'='Assert-ClrTrustCleanupScope';
 'Invoke-CsvOwnSql'='Invoke-ReleaseSql';'Invoke-CsvSql'='Invoke-ReleaseSql'}){. $block}

function Assert-ClrInstalled($Connection,[string]$Profile) {
 $expected=@($script:metadata.profiles.$Profile)
 $rows=@(Invoke-ReleaseSql $Connection "SELECT name,CONVERT(nvarchar(128),value) value FROM sys.extended_properties WITH (NOLOCK) WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
 if($rows.Count -ne ($expected.Count+1)){throw 'RELEASE_CLR_MODULE_COUNT'}
 foreach($mid in @($expected)+@('toolbelt.core.result-table')){
  if(@($rows|Where-Object {$_.name -ceq ('Toolbelt.Module.'+$mid+'.Version')}).Count -ne 1){throw 'RELEASE_CLR_MODULE_MARKER'}
 }
 $assemblies=@(Invoke-ReleaseSql $Connection "SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash FROM sys.assemblies a WITH (NOLOCK) JOIN sys.assembly_files f WITH (NOLOCK) ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1 ORDER BY a.name;" -Rows)
 $wanted=@($script:metadata.artifacts|Where-Object {$_.module_id -in $expected -or ($Profile.StartsWith('Windows-') -and -not $_.module_id)})
 if($assemblies.Count -ne $wanted.Count){throw 'RELEASE_CLR_ASSEMBLY_COUNT'}
 foreach($a in $wanted){if(@($assemblies|Where-Object {$_.name -ceq $a.sql_name -and $_.Hash -ceq $a.sha512.ToUpperInvariant()}).Count -ne 1){throw 'RELEASE_CLR_ASSEMBLY_HASH'}}
 return ($assemblies|ConvertTo-Json -Compress)
}
function Invoke-ClrSmoke($Connection,[string]$Prefix='') {
 # Bewusst kleine feste Oracles; keine neue vollständige APIqualifikation.
 Invoke-ReleaseSql $Connection @"
IF NOT EXISTS(SELECT 1 FROM ${Prefix}toolbelt_string.TVF_ColognePhonetic(N'M') WHERE PhoneticCode='6' AND ErrorCode=0)
 THROW 51594,N'Phonetic package oracle failed.',1;
EXEC ${Prefix}toolbelt_json.USP_JsonArray @Hilfe=1;
EXEC ${Prefix}toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;
"@
}

$control=$null;$ledger=$null;$journal=$null;$failure=$null;$stage='PREPARE'
try {
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
 if($runset.cases.Count -ne 12){throw 'RELEASE_CLR_RUNSET'}
 $case=$runset.cases[$CaseIndex]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 Assert-ReleaseInputs
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count -ne 1){throw 'RELEASE_CLR_TARGET_AMBIGUOUS'}
 $target=$targets[0]
 $targetIdentity=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$target.key)))
 $control=Open-ReleaseConnection 'master'
 if($AuditOnly){
  $ledger=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json
  if($ledger.targetIdentity -cne $targetIdentity -or $ledger.state -cne 'COMPLETE'){throw 'RELEASE_CLR_AUDIT_STATE'}
  foreach($entry in $ledger.databases){
   $r=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($entry.state -cne 'DROPPED' -or $r.Count -ne 1 -or $r[0].Id -isnot [DBNull]){throw 'RELEASE_CLR_AUDIT_DB_PRESENT'}
  }
  foreach($entry in $ledger.trust){
   $actual=Get-ClrTrust $control ([Convert]::FromHexString($entry.hash))
   if(($entry.preexisting -and ($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint)) -or
      (-not $entry.preexisting -and $null -ne $actual)){throw 'RELEASE_CLR_AUDIT_TRUST_DRIFT'}
  }
  Assert-ReleaseInputs
  'PASS RELEASE_CLR_INDEPENDENT_CLEANUP_AND_PINS';exit 0
 }
 if(Test-Path -LiteralPath $journal){throw 'RELEASE_CLR_CASE_ALREADY_ATTEMPTED'}
 $stage='PREFLIGHT'
 $pre=@(Invoke-ReleaseSql $control "SELECT @@VERSION Version,CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info WITH (NOLOCK)) Platform,IS_SRVROLEMEMBER(N'sysadmin') IsAdmin,(SELECT value_in_use FROM sys.configurations WITH (NOLOCK) WHERE name='clr enabled') ClrReady; SELECT name,state_desc FROM sys.databases WITH (NOLOCK) ORDER BY database_id;" -Rows)
 if($pre[0].IsAdmin -ne 1 -or $pre[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[$case.Version] -or $pre[0].Platform -ine $case.Platform){throw 'RELEASE_CLR_PREFLIGHT'}
 if($pre[0].ClrReady -ne 1){throw 'RELEASE_CLR_DISABLED_NO_MUTATION'}
 $archive=[IO.Compression.ZipFile]::OpenRead($runset.package)
 $files=@{}
 try{foreach($e in $archive.Entries){
  $relative=$e.FullName.Substring('SQL-Server-Toolbelt-1.0.0-CLR-Install/'.Length)
  if($relative.StartsWith('SQL/') -or $relative -ceq 'CLR-PACKAGE.json'){
   $reader=[IO.StreamReader]::new($e.Open(),[Text.Encoding]::UTF8)
   try{$files[$relative]=$reader.ReadToEnd()}finally{$reader.Dispose()}
  }
 }}finally{$archive.Dispose()}
 $metadata=$files['CLR-PACKAGE.json']|ConvertFrom-Json
 $platformProfile=if($case.Platform -ceq 'windows'){'Windows'}else{'Portable'}
 $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');targetIdentity=$targetIdentity;state='PREPARED';databases=@();trust=@();completedModes=@();failure=$null}
 Save-ReleaseJournal
 $stage='TRUST'
 $wanted=@($metadata.artifacts|Where-Object {$_.module_id -in @($metadata.profiles."$platformProfile-local") -or ($platformProfile -ceq 'Windows' -and -not $_.module_id)})
 foreach($a in $wanted){
  $hash=[Convert]::FromHexString($a.sha512);$before=Get-ClrTrust $control $hash
  $entry=[ordered]@{hash=$a.sha512;preexisting=($null -ne $before);fingerprint=$null;state='PREEXISTING';description=$null}
  if($before){$entry.fingerprint=$before.Fingerprint}
  $ledger.trust+=@($entry);Save-ReleaseJournal
  if(-not $before){
   Assert-ClrTrustCleanupScope $control $hash
   $entry.state='ADDING';$entry.description='Toolbelt synthetic CLR package '+$ledger.owner+' '+$a.file;Save-ReleaseJournal
   Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$hash;'@Description'=$entry.description}
   $actual=Get-ClrTrust $control $hash
   if($null -eq $actual -or $actual.description -cne $entry.description){throw 'RELEASE_CLR_TRUST_OWNERSHIP_UNKNOWN'}
   $entry.fingerprint=$actual.Fingerprint;$entry.state='OWNED';Save-ReleaseJournal
  }
 }
 Invoke-ReleaseBatches $control $files["SQL/Trust-$platformProfile-local.sql"]
 Invoke-ReleaseBatches $control $files["SQL/Trust-$platformProfile-local.sql"]
 $names=@{}
 foreach($label in @('local','central','consumer')){
  $stage='CREATE_'+$label;$suffix=@{local='l';central='c';consumer='u'}[$label]
  $name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
  $entry=[ordered]@{name=$name;id=$null;created=$null;state='CREATING'}
  $ledger.databases+=@($entry);Save-ReleaseJournal
  Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 51591,N'Database collision.',4; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
  $id=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WITH (NOLOCK) WHERE name=@Name;' @{'@Name'=$name} -Rows)
  if($id.Count -ne 1){throw 'RELEASE_CLR_DB_IDENTITY'}
  $entry.id=$id[0].Id;$entry.created=$id[0].Created;$entry.state='CREATED';Save-ReleaseJournal
  $db=Open-ReleaseConnection $name
  Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
  $entry.state='OWNED';Save-ReleaseJournal;$db.Dispose()
  Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
  $names[$label]=$name
 }
 foreach($mode in @('local','central')){
  $profile="$platformProfile-$mode";$stage='INSTALL_'+$mode
  $db=Open-ReleaseConnection $names[$mode]
  Invoke-ReleaseBatches $db $files["SQL/Install-$profile.sql"]
  $first=Assert-ClrInstalled $db $profile;Invoke-ClrSmoke $db;$db.Dispose()
  $stage='REPEAT_'+$mode;$db=Open-ReleaseConnection $names[$mode]
  Invoke-ReleaseBatches $db $files["SQL/Repeat-$profile.sql"]
  if((Assert-ClrInstalled $db $profile) -cne $first){throw 'RELEASE_CLR_REPEAT_DRIFT'}
  Invoke-ClrSmoke $db;$db.Dispose()
  if($mode -ceq 'central'){$db=Open-ReleaseConnection $names.consumer;Invoke-ClrSmoke $db ('['+$names.central+'].');$db.Dispose()}
  $stage='UNINSTALL_'+$mode
  foreach($repeat in 1..2){$db=Open-ReleaseConnection $names[$mode];Invoke-ReleaseBatches $db $files["SQL/Uninstall-$profile.sql"];$db.Dispose()}
  $db=Open-ReleaseConnection $names[$mode]
  $left=@(Invoke-ReleaseSql $db "SELECT (SELECT COUNT(*) FROM sys.assemblies WITH (NOLOCK) WHERE is_user_defined=1) Assemblies,(SELECT COUNT(*) FROM sys.extended_properties WITH (NOLOCK) WHERE class=0 AND name LIKE N'Toolbelt.Module.%') Markers;" -Rows)
  if($left.Count -ne 1 -or $left[0].Assemblies -ne 0 -or $left[0].Markers -ne 0){throw 'RELEASE_CLR_UNINSTALL_RESIDUE'}
  $db.Dispose();$ledger.completedModes+=@($mode);Save-ReleaseJournal
 }
 Assert-ReleaseInputs
}catch{
 $errorDetail=$_.Exception;while($errorDetail.InnerException){$errorDetail=$errorDetail.InnerException}
 $failure=[ordered]@{stage=$stage;sqlNumber=$(if($errorDetail -is [Data.SqlClient.SqlException]){$errorDetail.Number}else{0});reason=$(if($errorDetail.Message -cmatch '^RELEASE_[A-Z0-9_]+$'){$errorDetail.Message}else{'RELEASE_CLR_UNCLASSIFIED'})}
 if($ledger -and -not $AuditOnly){$ledger.failure=$failure;$ledger['privateDiagnostic']=$errorDetail.Message;Save-ReleaseJournal}
}finally{
 foreach($connection in $connections){try{$connection.Dispose()}catch{}}
 if($ledger -and -not $AuditOnly){
  $cleanup=$true
  try{
   $control=Open-ReleaseConnection 'master'
   foreach($entry in $ledger.databases){Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal}
   foreach($entry in $ledger.trust){
    $hash=[Convert]::FromHexString($entry.hash);$actual=Get-ClrTrust $control $hash
    if($entry.preexisting){if($null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint){throw 'RELEASE_CLR_PREEXISTING_TRUST_DRIFT'};continue}
    if($entry.state -cne 'OWNED' -or $null -eq $actual -or $actual.Fingerprint -cne $entry.fingerprint -or $actual.description -cne $entry.description){throw 'RELEASE_CLR_TRUST_CLEANUP_IDENTITY'}
    Assert-ClrTrustCleanupScope $control $hash
    Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
    if($null -ne (Get-ClrTrust $control $hash)){throw 'RELEASE_CLR_TRUST_NOT_REMOVED'}
    $entry.state='REMOVED';Save-ReleaseJournal
   }
   $ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=@{stage='CLEANUP';sqlNumber=0;reason='RELEASE_CLR_CLEANUP_BLOCKED'}}
  finally{if($control){$control.Dispose()}}
 }
}
if($failure){Write-Output ('FAIL '+($failure|ConvertTo-Json -Compress));exit 1}
'PASS RELEASE_CLR_PACKAGE_INSTALL_REPEAT_CONSUMER_UNINSTALL'
