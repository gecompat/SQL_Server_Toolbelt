# Begrenzter genuiner V1-Lifecycle ohne Rechte-/CLR-/Serveränderung.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='ADMISSION'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'CLONE_GENUINE_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'CLONE_GENUINE_HELPER_AMBIGUOUS'};. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
function Get-CloneGenuineServerSnapshot($Control){
 $sql="SELECT configuration_id,name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations ORDER BY configuration_id; SELECT CONVERT(varchar(128),hash,2) Hash,description,create_date,created_by FROM sys.trusted_assemblies ORDER BY hash;"
 return (@(Invoke-ReleaseSql $Control $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Get-CloneGenuineProfiles([string]$Mode){
 $all=@('clean-current-rollback','genuine-install','current-uninstall-genuine','genuine-reinstall','genuine-upgrade-rollback','genuine-upgrade','same-version-repeat','current-reinstall-rollback','current-uninstall','uninstall-repeat')
 if($script:carryActive-and$Mode-ceq'local'){return $all[4..9]}
 return $all
}
function Assert-CloneGenuineCarry {
 $script:carryActive=$false;$script:carryJournal=$null
 if(-not$runset.PSObject.Properties['carry']){return}
 $c=$runset.carry
 if($c.schema_version-cne'genuine-v1-prefix/v1'-or$c.caseIndex-ne0-or$c.mode-cne'local'-or$c.profileCount-ne4){throw 'CLONE_GENUINE_CARRY_SCOPE'}
 foreach($kind in @('journal','audit','runset')){
  $path=Assert-ReleasePrivatePath $c.$kind.path
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_GENUINE_CARRY_REQUIRED_PIN'}
  Assert-ReleasePin $path $c.$kind.sha256
 }
 $j=Get-Content -LiteralPath $c.journal.path -Raw|ConvertFrom-Json -DateKind String
 $a=Get-Content -LiteralPath $c.audit.path -Raw|ConvertFrom-Json -DateKind String
 $old=Get-Content -LiteralPath $c.runset.path -Raw|ConvertFrom-Json -DateKind String
 if($j.state-cne'FAILED_CLEANED'-or$j.failure.stage-cne'CLONE_GENUINE_local_genuine-upgrade-rollback'-or$j.owner-cnotmatch'^[a-f0-9]{32}$'-or
  $a.state-cne'COMPLETE'-or$a.readOnly-ne$true-or$a.originalRunPassed-ne$false-or$a.databaseAbsence-ne$true-or$a.postPins-ne$true-or$a.serverConfigurationAndTrustUnchanged-ne$true-or
  $a.originalJournalSHA256-cne$c.journal.sha256-or$j.completedModes.Count-ne0-or$j.lifecycleProfiles.Count-ne4-or$j.databases.Count-ne1-or$j.databases[0].state-cne'DROPPED'){
  throw 'CLONE_GENUINE_CARRY_ORIGINAL_NOT_VERIFIED'
 }
 if($old.schema_version-cne$runset.schema_version-or$old.started_utc-cne$runset.started_utc-or$old.deadline_utc-cne$runset.deadline_utc-or
  $old.contract_sha256-cne$runset.contract_sha256-or$old.legacyRoot-cne$runset.legacyRoot-or
  ($old.cases|ConvertTo-Json -Depth 5 -Compress)-cne($runset.cases|ConvertTo-Json -Depth 5 -Compress)-or
  ($old.lifecycleTexts|ConvertTo-Json -Depth 5 -Compress)-cne($runset.lifecycleTexts|ConvertTo-Json -Depth 5 -Compress)-or
  ($old.exports|ConvertTo-Json -Depth 5 -Compress)-cne($runset.exports|ConvertTo-Json -Depth 5 -Compress)){
  throw 'CLONE_GENUINE_CARRY_INPUT_DRIFT'
 }
 foreach($pin in $old.pins){
  if((Get-FileHash -LiteralPath $pin.path).Hash-cne$pin.sha256){
   $caps=@($old.source_capsules|Where-Object{$_.originalPath-ceq$pin.path-and$_.sha256-ceq$pin.sha256})
   if($caps.Count-ne1){throw 'CLONE_GENUINE_CARRY_OLD_SOURCE_MISSING'}
   Assert-ReleasePin $caps[0].snapshotPath $pin.sha256
  }
  if($pin.path.StartsWith((Join-Path $repo 'Modules/'),[StringComparison]::OrdinalIgnoreCase)-or$pin.path-ceq(Join-Path $repo 'Deployment/Deploy-All.ps1')){
   Assert-ReleasePin $pin.path $pin.sha256
  }
 }
 $prefix=@('clean-current-rollback','genuine-install','current-uninstall-genuine','genuine-reinstall')
 for($i=0;$i-lt4;$i++){
  $p=$j.lifecycleProfiles[$i]
  if($p.mode-cne'local'-or$p.profile-cne$prefix[$i]-or$p.passed-ne$true){throw 'CLONE_GENUINE_CARRY_PREFIX'}
  $kind=if($i-eq0){'Deploy'}elseif($i-eq2){'Uninstall'}else{'Legacy'}
  $path=$runset.lifecycleTexts.local.$kind
  if($p.canonicalSHA256-cne(Get-FileHash -LiteralPath $path).Hash){throw 'CLONE_GENUINE_CARRY_CANONICAL_HASH'}
  $text=[IO.File]::ReadAllText($path);if($i-eq0){$text=New-CloneGenuineFaultText $text}
  if($p.executedSHA256-cne[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($text)))){throw 'CLONE_GENUINE_CARRY_EXECUTED_HASH'}
 }
 if($CaseIndex-eq0){$script:carryActive=$true;$script:carryJournal=$j}
}

function Assert-CloneGenuineTreePins($Node){
 if(@($runset.pins|Where-Object path -CEQ $Node.Path).Count-ne1){throw 'CLONE_GENUINE_SOURCE_TREE_PIN'}
 foreach($child in $Node.Children){Assert-CloneGenuineTreePins $child}
}
function Assert-CloneGenuineInputs {
 $legacy=Assert-ReleasePrivatePath $runset.legacyRoot
 # Diese fünf Hashes bezeichnen ausschließlich öffentliche Originalquellen.
 $expected=[ordered]@{
  'Deployment/Deploy.sql'='EE33357B00633E9C9DB129B8EF834C4D3659081C229BFE56E839BC9301C35EDF'
  'Deployment/Uninstall.sql'='EF5CD459E1F4AF19AE49120A68F33BA0D0727700C95243965A10EEA5A6196441'
  'Source/USP_ScriptTableCloneInternal.sql'='3FFDCD726EA175E27ABCAC4F6E9475C044F9292D57FE6C9D131DA95AD6D68072'
  'Source/USP_ScriptTableClone.sql'='40D00DE831961BAD2E43E5C2ADBAEA47D38A72F0C63109BB0F3FC3FF2C0DD838'
  'module.yaml'='19CC4EE909318C666F7FCA9D2FF7A490E1E1E4375BF8D52E2984193AED105374'
 }
 $provenance=Assert-ReleasePrivatePath (Join-Path $legacy 'provenance.json')
 $p=Get-Content -LiteralPath $provenance -Raw|ConvertFrom-Json
 if($p.publicCommit-cne'fdafa8038e4d5240dd727096f144c8d5fd884117'-or$p.version-cne'1.0.0'-or$p.moduleId-cne'toolbelt.metadata.table-clone'-or$p.files.Count-ne5){throw 'CLONE_GENUINE_ORIGINAL_PROVENANCE'}
 foreach($key in $expected.Keys){
  $path=Assert-ReleasePrivatePath (Join-Path $legacy $key)
  if((Get-FileHash -LiteralPath $path).Hash-cne$expected[$key]-or@($p.files|Where-Object{$_.path-ceq$key-and$_.sha256-ceq$expected[$key]}).Count-ne1){throw 'CLONE_GENUINE_ORIGINAL_BYTES'}
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_GENUINE_ORIGINAL_PIN'}
 }
 if(@($runset.pins|Where-Object path -CEQ $provenance).Count-ne1){throw 'CLONE_GENUINE_PROVENANCE_PIN'}
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Deployment/Deploy-All.ps1') @('Get-SqlcmdScriptTree','ConvertTo-StandaloneSql')){. $block}
 foreach($mode in @('local','central')){foreach($kind in @('Deploy','Uninstall','Legacy')){
  $source=if($kind-ceq'Legacy'){Join-Path $legacy 'Deployment/Deploy.sql'}else{Join-Path $repo ('Modules/toolbelt.metadata.table-clone/Deployment/'+$kind+'.sql')}
  $boundary=if($kind-ceq'Legacy'){$legacy}else{Join-Path $repo 'Modules'}
  $node=Get-SqlcmdScriptTree -Path $source -Cache @{}
  Assert-CloneGenuineTreePins $node
  $text=ConvertTo-StandaloneSql -Node $node -Values @{DeploymentMode=$mode;ConfirmNoExternalConsumers='1'} -ModulesRoot $boundary
  if($kind-ceq'Deploy'){[void](New-CloneGenuineFaultText $text)}
  $path=Assert-ReleasePrivatePath $runset.lifecycleTexts.$mode.$kind
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1-or[IO.File]::ReadAllText($path)-cne$text){throw 'CLONE_GENUINE_CANONICAL_TEXT'}
 }}
}
function Get-CloneGenuineDependencySnapshot($Connection){
 $sql=@'
SELECT schema_id,principal_id FROM sys.schemas WHERE name=N'toolbelt_core';
SELECT o.object_id,o.type,o.principal_id,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash
FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
WHERE s.name=N'toolbelt_core' ORDER BY o.object_id;
SELECT class,major_id,minor_id,name,CONVERT(varchar(max),CONVERT(varbinary(max),value),2) ValueBytes
FROM sys.extended_properties WHERE (class=0 AND name LIKE N'Toolbelt.Module.toolbelt.core.result-table.%')
 OR (class=1 AND major_id IN(SELECT o.object_id FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE s.name=N'toolbelt_core'))
 OR (class=3 AND major_id=SCHEMA_ID(N'toolbelt_core'))
ORDER BY class,major_id,minor_id,name;
'@
 return (@(Invoke-ReleaseSql $Connection $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Get-CloneGenuineModuleSnapshot($Connection){
 $sql=@'
SELECT schema_id,principal_id FROM sys.schemas WHERE name=N'toolbelt_metadata';
SELECT o.object_id,o.type,o.principal_id,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash
FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
WHERE s.name=N'toolbelt_metadata' ORDER BY o.object_id;
SELECT class,major_id,minor_id,name,CONVERT(varchar(max),CONVERT(varbinary(max),value),2) ValueBytes
FROM sys.extended_properties WHERE (class=0 AND name LIKE N'Toolbelt.Module.toolbelt.metadata.table-clone.%')
 OR (class=1 AND major_id IN(SELECT o.object_id FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE s.name=N'toolbelt_metadata'))
 OR (class=3 AND major_id=SCHEMA_ID(N'toolbelt_metadata'))
ORDER BY class,major_id,minor_id,name;
'@
 return (@(Invoke-ReleaseSql $Connection $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Assert-CloneGenuineInventory($Connection,[string]$Version,[string]$Mode){
 $rows=@(Invoke-ReleaseSql $Connection "SELECT CONVERT(nvarchar(128),value) Value,name FROM sys.extended_properties WHERE class=0 AND name IN(N'Toolbelt.Module.toolbelt.metadata.table-clone.Version',N'Toolbelt.Module.toolbelt.metadata.table-clone.DeploymentMode');" -Rows)
 $objects=@(Invoke-ReleaseSql $Connection "SELECT o.name,CONVERT(varchar(2),RTRIM(o.type)) TypeCode,(SELECT COUNT(*) FROM sys.parameters p WHERE p.object_id=o.object_id) Parameters FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE s.name=N'toolbelt_metadata' ORDER BY o.name;" -Rows)
 if($Version-ceq'ABSENT'){
  if($rows.Count-ne0-or$objects.Count-ne0){throw 'CLONE_GENUINE_UNINSTALL_REMAINS'}
  return
 }
 if($rows.Count-ne2-or@($rows|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.metadata.table-clone.Version'-and$_.Value-ceq$Version}).Count-ne1-or@($rows|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.metadata.table-clone.DeploymentMode'-and$_.Value-ceq$Mode}).Count-ne1){throw 'CLONE_GENUINE_MODULE_MARKERS'}
 $expected=if($Version-ceq'1.0.0'){@{'USP_ScriptTableClone'=9;'USP_ScriptTableCloneInternal'=9}}else{@{'USP_ScriptTableClone'=13;'USP_ScriptTableCloneInternal'=14;'USP_ExecuteTableClone'=14;'USP_CopyTableCloneData'=9}}
 if($objects.Count-ne$expected.Count){throw 'CLONE_GENUINE_OBJECT_COUNT'}
 foreach($name in $expected.Keys){if(@($objects|Where-Object{$_.name-ceq$name-and$_.TypeCode-ceq'P'-and$_.Parameters-eq$expected[$name]}).Count-ne1){throw 'CLONE_GENUINE_SIGNATURES'}}
}
function Invoke-CloneGenuineLegacySession($Observer,[string]$Mode){
 $legacy=$null
 try{
  # Der echte V1-Installer behält benannte lokale Temps bis zum Sitzungsende.
  # Ausschließlich diese eigene Sitzung schließen; keine fremden Temps löschen.
  $legacy=Open-ReleaseConnection $Observer.Database
  Invoke-CloneGenuineSqlBatches $legacy ([IO.File]::ReadAllText($runset.lifecycleTexts.$Mode.Legacy))
  $neutral=@(Invoke-ReleaseSql $legacy 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
  if($neutral.Count-ne1-or$neutral[0].TranCount-ne0-or$neutral[0].XactState-ne0){throw 'CLONE_GENUINE_LEGACY_SESSION_NOT_NEUTRAL'}
 }finally{if($legacy){$legacy.Dispose()}}
}
function Invoke-CloneGenuineLifecycle($Connection,[string]$Mode){
 $dependency=Get-CloneGenuineDependencySnapshot $Connection
 $profiles=@(Get-CloneGenuineProfiles $Mode)
 $before=$null
 foreach($profile in $profiles){
  $script:stage='CLONE_GENUINE_'+$Mode+'_'+$profile
  if($profile.EndsWith('-rollback',[StringComparison]::Ordinal)){
   $snapshot=Get-CloneGenuineModuleSnapshot $Connection
   $text=[IO.File]::ReadAllText($runset.lifecycleTexts.$Mode.Deploy)
   $text=New-CloneGenuineFaultText $text
   $probe=$null;$caught=$false
   try{
    # Eigene separate Sitzung: keine Installer-Temps im fortgesetzten Caller.
    $probe=Open-ReleaseConnection $Connection.Database
    try{Invoke-CloneGenuineSqlBatches $probe $text}catch{
     $e=$_.Exception;while($e.InnerException-and$e-isnot[Data.SqlClient.SqlException]){$e=$e.InnerException}
     if($e-isnot[Data.SqlClient.SqlException]-or$e.Number-ne54932-or$e.State-ne1){$ledger.sqlFaults+=@(@{mode=$Mode;profile=$profile;type=$e.GetType().FullName;privateMessage=$e.Message;number=$(if($e-is[Data.SqlClient.SqlException]){$e.Number}else{$null});state=$(if($e-is[Data.SqlClient.SqlException]){$e.State}else{$null})});Save-ReleaseJournal;throw [InvalidOperationException]::new('CLONE_GENUINE_ROLLBACK_CATEGORY',$e)}
     $caught=$true
    }
    $neutral=@(Invoke-ReleaseSql $probe 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
    if(-not$caught-or$neutral.Count-ne1-or$neutral[0].TranCount-ne0-or$neutral[0].XactState-ne0-or(Get-CloneGenuineModuleSnapshot $Connection)-cne$snapshot){throw 'CLONE_GENUINE_ROLLBACK_CHANGED'}
   }finally{if($probe){$probe.Dispose()}}
   if((Get-CloneGenuineDependencySnapshot $Connection)-cne$dependency){throw 'CLONE_GENUINE_DEPENDENCY_CHANGED'}
   $ledger.lifecycleProfiles+=@(@{mode=$Mode;profile=$profile;passed=$true;canonicalSHA256=(Get-FileHash -LiteralPath $runset.lifecycleTexts.$Mode.Deploy).Hash;executedSHA256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($text)))});Save-ReleaseJournal
   continue
  }
  $kind=switch -CaseSensitive ($profile){
   'genuine-install'{'Legacy'} 'current-uninstall-genuine'{'Uninstall'} 'genuine-reinstall'{'Legacy'}
   'genuine-upgrade'{'Deploy'} 'same-version-repeat'{'Deploy'} 'current-uninstall'{'Uninstall'} 'uninstall-repeat'{'Uninstall'}
  }
  if($kind-ceq'Legacy'){Invoke-CloneGenuineLegacySession $Connection $Mode}else{Invoke-CloneGenuineSqlBatches $Connection ([IO.File]::ReadAllText($runset.lifecycleTexts.$Mode.$kind))}
  $version=switch -CaseSensitive ($profile){'genuine-install'{'1.0.0'} 'genuine-reinstall'{'1.0.0'} 'genuine-upgrade'{'4.1.1'} 'same-version-repeat'{'4.1.1'} default{'ABSENT'}}
  Assert-CloneGenuineInventory $Connection $version $Mode
  $after=Get-CloneGenuineModuleSnapshot $Connection
  if($profile-in@('same-version-repeat','uninstall-repeat')-and$after-cne$before){throw 'CLONE_GENUINE_REPEAT_CHANGED'}
  if((Get-CloneGenuineDependencySnapshot $Connection)-cne$dependency){throw 'CLONE_GENUINE_DEPENDENCY_CHANGED'}
  $neutral=@(Invoke-ReleaseSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
  if($neutral.Count-ne1-or$neutral[0].TranCount-ne0-or$neutral[0].XactState-ne0){throw 'CLONE_GENUINE_SESSION_NOT_NEUTRAL'}
  $ledger.lifecycleProfiles+=@(@{mode=$Mode;profile=$profile;passed=$true;canonicalSHA256=(Get-FileHash -LiteralPath $runset.lifecycleTexts.$Mode.$kind).Hash;executedSHA256=(Get-FileHash -LiteralPath $runset.lifecycleTexts.$Mode.$kind).Hash})
  Save-ReleaseJournal
  $before=$after
 }
 return $profiles
}

function New-CloneGenuineFaultText([string]$Text){
 $anchor='    DROP TABLE #tbx_TableCloneReleaseObjects;'
 if(([regex]::Matches($Text,[regex]::Escape($anchor))).Count-ne1){throw 'CLONE_GENUINE_ROLLBACK_ANCHOR'}
 return $Text.Replace($anchor,"    THROW 54932,N'CLONE_SYNTHETIC_FINALINSTALL',1;`n"+$anchor)
}

function Get-CloneGenuineSqlBatches([string]$Text){
 $Text=[regex]::Replace($Text,'(?im)^[\t ]*:ON[\t ]+ERROR[\t ]+EXIT[\t ]*\r?$','')
 if($Text-match'(?m)^[\t ]*:'-or$Text.Contains('$(')){throw 'CLONE_GENUINE_UNRESOLVED_SQLCMD'}
 # Nur horizontale Leerzeichen: der Kommentar der Folgezeile gehört zum SQL.
 return @([regex]::Split($Text,'(?im)^[\t ]*GO[\t ]*(?:--[^\r\n]*)?\r?$')|Where-Object{-not[string]::IsNullOrWhiteSpace($_)})
}
function Invoke-CloneGenuineSqlBatches($Connection,[string]$Text){
 foreach($batch in Get-CloneGenuineSqlBatches $Text){Invoke-ReleaseSql $Connection $batch}
}
try{
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version-cne'table-clone-genuine/v1'-or$runset.cases.Count-ne12-or
  $runset.explicit_qualification_approved-isnot[bool]-or$runset.explicit_qualification_approved-ne$true){throw 'CLONE_GENUINE_RUNSET_SCOPE'}
 $started=[DateTimeOffset]::Parse($runset.started_utc);$deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 if($deadline-ne$started.AddMinutes(60)-or$started-gt[DateTimeOffset]::UtcNow-or
  (-not$AuditOnly-and[DateTimeOffset]::UtcNow.AddMinutes(15)-ge$deadline)){throw 'CLONE_GENUINE_ADMISSION_CLOSED'}
 $expected=@('windows/2019/CU32/150','windows/2022/CU26/150','windows/2022/CU26/160',
  'windows/2025/CU8/150','windows/2025/CU8/160','windows/2025/CU8/170',
  'linux/2019/latest/150','linux/2022/latest/150','linux/2022/latest/160',
  'linux/2025/latest/150','linux/2025/latest/160','linux/2025/latest/170')
 for($i=0;$i-lt12;$i++){
  $c=$runset.cases[$i];$tuple=[string]$c.Platform+'/'+$c.Version+'/'+$c.Patch+'/'+$c.CL
  $modes='local,central'
  if($tuple-cne$expected[$i]-or(@($c.modes)-join',')-cne$modes){throw 'CLONE_GENUINE_CONTEXT_SCOPE'}
 }
 $case=$runset.cases[$CaseIndex];Assert-ReleaseInputs
 $fixtureNames=@('clean-current-rollback','genuine-install','current-uninstall-genuine','genuine-reinstall','genuine-upgrade-rollback','genuine-upgrade','same-version-repeat','current-reinstall-rollback','current-uninstall','uninstall-repeat')
 foreach($path in @($PSCommandPath,$runset.exports.local,$runset.exports.central)+@(
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),
  (Join-Path $repo 'Deployment/Deploy-All.ps1'),(Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Deployment/New-LegacyTestArtifacts.ps1'),
  (Join-Path $repo 'Tests/CI/Set-SqlClientTlsPolicy.ps1'),(Join-Path $repo 'Tests/CI/Assert-LabQualifiedTlsBinding.ps1'),
  (Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Deployment/Deploy.sql'),(Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Deployment/Uninstall.sql'),
  (Join-Path $repo 'Modules/toolbelt.metadata.table-clone/module.yaml'))){
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_GENUINE_REQUIRED_PIN_MISSING'}
 }
 foreach($mode in @('local','central')){
  $export=[IO.File]::ReadAllText($runset.exports.$mode)
  $modules=@([regex]::Matches($export,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)\r?$')|ForEach-Object{$_.Groups[1].Value})
  if(($modules-join',')-cne'toolbelt.core.result-table'){throw 'CLONE_GENUINE_DEPENDENCY_ONLY_EXPORT_REQUIRED'}
 }
 Assert-CloneGenuineInputs
 Assert-CloneGenuineCarry
 if($ValidateOnly){'PASS CLONE_GENUINE_OFFLINE_ADMISSION; no Lab import or SQL';return}
 if(-not$IsWindows){throw 'CLONE_GENUINE_WINDOWS_HOST_REQUIRED'}
 if(@('TBX_LAB_QUALIFIED_CONTEXT_FILE','TBX_LAB_QUALIFIED_CONTEXT_SHA256','TBX_LAB_QUALIFIED_PWSH')|Where-Object{-not[string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($_,'Process'))}){throw 'CLONE_GENUINE_UNEXPECTED_QUALIFIED_CONTEXT'}
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash-cne$runset.contract_sha256){throw 'CLONE_GENUINE_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count-ne1){throw 'CLONE_GENUINE_EXACT_TARGET_REQUIRED'};$target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $hash=(Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -DateKind String
  if($prior.state-cnotin@('COMPLETE','FAILED_CLEANED')-or$prior.owner-cnotmatch'^[a-f0-9]{32}$'){throw 'CLONE_GENUINE_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $now=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform;" -Rows)
  if($now.Count-ne1-or$now[0].Major-ne$prior.observedTarget.Major-or$now[0].Version-cne$prior.observedTarget.Version-or$now[0].Platform-cne$prior.observedTarget.Platform){throw 'CLONE_GENUINE_AUDIT_TARGET_DRIFT'}
  foreach($entry in $prior.databases){
   if($entry.name-cne('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix)-or$entry.state-cne'DROPPED'){throw 'CLONE_GENUINE_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count-ne1-or$rows[0].Id-isnot[DBNull]){throw 'CLONE_GENUINE_AUDIT_DATABASE_PRESENT'}
  }
  if($prior.serverSnapshot-and(Get-CloneGenuineServerSnapshot $control)-cne$prior.serverSnapshot){throw 'CLONE_GENUINE_FOREIGN_SERVER_DRIFT'}
  Assert-ReleaseInputs
  if((Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash-cne$hash){throw 'CLONE_GENUINE_AUDIT_JOURNAL_DRIFT'}
  $expectedFlat=@(foreach($m in @('local','central')){foreach($f in @(Get-CloneGenuineProfiles $m)){$m+'/'+$f}})
  $actualFlat=@($prior.lifecycleProfiles|ForEach-Object{$_.mode+'/'+$_.profile})
  [IO.File]::WriteAllText(($journal+'.audit.json'),([ordered]@{state='COMPLETE';readOnly=$true;
   originalJournalSHA256=$hash;coverageScope=$prior.coverageScope;originalRunPassed=($prior.coverageScope-ceq'WHOLE_CASE'-and$prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and$prior.lifecycleProfiles.Count-eq$expectedFlat.Count-and($actualFlat-join'|')-ceq($expectedFlat-join'|')-and@($prior.lifecycleProfiles|Where-Object passed -NE $true).Count-eq0-and
   (@($prior.completedModes)-join',')-ceq(@($case.modes)-join',')-and$prior.witnesses.Count-eq2-and
   @($prior.witnesses|Where-Object{(@($_.fixtures)-join',')-cne(@(Get-CloneGenuineProfiles $_.mode)-join',')-or$_.compatibilityLevel-ne$case.CL-or$_.transactionNeutral-ne$true-or$_.repeatUnchanged-ne$true-or$_.dependencyUnchanged-ne$true}).Count-eq0);declaredRunPassed=($prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and$prior.lifecycleProfiles.Count-eq$expectedFlat.Count-and($actualFlat-join'|')-ceq($expectedFlat-join'|')-and@($prior.lifecycleProfiles|Where-Object passed -NE $true).Count-eq0-and
   (@($prior.completedModes)-join',')-ceq(@($case.modes)-join',')-and$prior.witnesses.Count-eq2-and
   @($prior.witnesses|Where-Object{(@($_.fixtures)-join',')-cne(@(Get-CloneGenuineProfiles $_.mode)-join',')-or$_.compatibilityLevel-ne$case.CL-or$_.transactionNeutral-ne$true-or$_.repeatUnchanged-ne$true-or$_.dependencyUnchanged-ne$true}).Count-eq0);databaseAbsence=$true;
   serverConfigurationAndTrustUnchanged=$true;postPins=$true}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 }else{
  if(Test-Path -LiteralPath $journal){throw 'CLONE_GENUINE_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();witnesses=@();lifecycleProfiles=@();sqlFaults=@();coverageScope=$(if($carryActive){'BOUND_REMAINDER'}else{'WHOLE_CASE'});serverSnapshot=$null;observedTarget=$null;failure=$null};Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count-ne1-or$actual[0].Major-ne@{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version]-or$actual[0].Platform-ine$case.Platform-or$actual[0].Admin-ne1){throw 'CLONE_GENUINE_ACTUAL_TARGET_MISMATCH'}
  if($carryActive-and($actual[0].Major-ne$carryJournal.observedTarget.Major-or$actual[0].Version-cne$carryJournal.observedTarget.Version-or$actual[0].Platform-cne$carryJournal.observedTarget.Platform)){throw 'CLONE_GENUINE_CARRY_TARGET_DRIFT'}
  $ledger.observedTarget=$actual[0];$ledger.serverSnapshot=Get-CloneGenuineServerSnapshot $control;Save-ReleaseJournal
  foreach($mode in $case.modes){
   $stage='CREATE_'+$mode;$suffix=if($mode-ceq'local'){'l'}else{'c'};$name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'};$ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($identity.Count-ne1){throw 'CLONE_GENUINE_DATABASE_IDENTITY'};$entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal;Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $actualCl=@(Invoke-ReleaseSql $db 'SELECT compatibility_level CL FROM sys.databases WHERE database_id=DB_ID();' -Rows)
   if($actualCl.Count-ne1-or$actualCl[0].CL-ne$case.CL){throw 'CLONE_GENUINE_ACTUAL_CL'}
   $stage='INSTALL_'+$mode;Invoke-CloneGenuineSqlBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   if($markers.Count-ne1-or$markers[0].name-cne'Toolbelt.Module.toolbelt.core.result-table.Version'-or$markers[0].Value-cne'1.0.0'){throw 'CLONE_GENUINE_DEPENDENCY_CLOSURE'}
   $modeMarkers=@(Invoke-ReleaseSql $db "SELECT CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode';" -Rows)
   if($modeMarkers.Count-ne1-or$modeMarkers[0].Value-cne$mode){throw 'CLONE_GENUINE_DEPENDENCY_MODE'}
   if([int](@(Invoke-ReleaseSql $db 'SELECT COUNT(*) N FROM sys.assemblies WHERE is_user_defined=1;' -Rows)[0].N)-ne0){throw 'CLONE_GENUINE_UNEXPECTED_CLR'}
   if($carryActive-and$mode-ceq'local'){
    $dep=Get-CloneGenuineDependencySnapshot $db;Invoke-CloneGenuineLegacySession $db 'local';Assert-CloneGenuineInventory $db '1.0.0' 'local';if((Get-CloneGenuineDependencySnapshot $db)-cne$dep){throw 'CLONE_GENUINE_CARRY_SETUP_DEPENDENCY'}
    $ledger['carrySetup']=@{qualificationProfile=$false;originalJournalSHA256=$runset.carry.journal.sha256;originalAuditSHA256=$runset.carry.audit.sha256;reusedProfiles=4;canonicalSHA256=(Get-FileHash -LiteralPath $runset.lifecycleTexts.local.Legacy).Hash};Save-ReleaseJournal
   }
   $profiles=@(Invoke-CloneGenuineLifecycle $db $mode)
   if(($profiles-join',')-cne(@(Get-CloneGenuineProfiles $mode)-join',')){throw 'CLONE_GENUINE_INCOMPLETE_PROFILES'}
   $ledger.witnesses+=@(@{mode=$mode;fixtures=$profiles;compatibilityLevel=$actualCl[0].CL;transactionNeutral=$true;repeatUnchanged=$true;dependencyUnchanged=$true})
   $ledger.completedModes+=@($mode);Save-ReleaseJournal;$db.Dispose()
  }
  Assert-ReleaseInputs
 }
}catch{$failure=$_.Exception;if($ledger-and-not$AuditOnly){$ledger.failure=@{stage=$stage;privateDiagnostic=$failure.Message;privatePosition=$_.ScriptStackTrace};Save-ReleaseJournal}}
finally{
 foreach($connection in $connections){try{$connection.Dispose()}catch{}};[Data.SqlClient.SqlConnection]::ClearAllPools()
 if($ledger-and-not$AuditOnly){
  $cleanup=$true
  try{
   $control=Open-ReleaseConnection 'master'
   foreach($entry in $ledger.databases){Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal}
   if($ledger.serverSnapshot-and(Get-CloneGenuineServerSnapshot $control)-cne$ledger.serverSnapshot){throw 'CLONE_GENUINE_FOREIGN_SERVER_DRIFT'}
   Assert-ReleaseInputs;$ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally{if($control){$control.Dispose()}}
 }
}
if($failure){if($ValidateOnly){throw $failure};'FAIL CLONE_GENUINE_TARGETS; inspect private journal; no automatic replay';exit 1}
if($AuditOnly){'PASS CLONE_GENUINE_TARGETS fresh independent final journal/absence audit'}else{'PASS CLONE_GENUINE_TARGETS selected genuine V1 lifecycle profiles; independent audit required'}
