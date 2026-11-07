# Direkte aktuelle Lifecycle-Pfade aus fünf echten öffentlichen Vorgängerständen.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,[switch]$AuditOnly,[switch]$ValidateOnly)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$stage='ADMISSION'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'CLONE_KNOWN_HELPER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'CLONE_KNOWN_HELPER_AMBIGUOUS'};. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
 'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql',
 'Open-ReleaseConnection','Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
function Get-CloneKnownServerSnapshot($Control){
 $sql="SELECT configuration_id,name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations ORDER BY configuration_id; SELECT CONVERT(varchar(128),hash,2) Hash,description,create_date,created_by FROM sys.trusted_assemblies ORDER BY hash;"
 return (@(Invoke-ReleaseSql $Control $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
$script:knownExpected=ConvertFrom-Json -AsHashtable @'
{"2.0.0":{"publicCommit":"8c04f0ee80921012bd53ca363fb1aa809a0708a1","files":{"Deployment/Deploy.sql":"1A033F8EF22B67890D4270CA94C54FA52B17538DC6CC160465B954D2D6D90332","Deployment/Uninstall.sql":"E803DC70999A53EB57FD7C4BEE4E4AE1D1CEBE3AB8E9D9B324306D54981FD9DA","module.yaml":"96DB4F5B1377B29E9B3F1CDFBC63372C79B08D00382C4D94FFF978286F0469DD","Source/USP_ScriptTableClone.sql":"7F1B9A6C9937E215E0820DE1FE3966FF03F84084B599F8C657ADB5DD15291271","Source/USP_ScriptTableCloneInternal.sql":"4DB933EE0E24087110154F0BB1CA96B961B744641EC81D0785CA66886CAFF452"},"parameters":{"USP_ScriptTableClone":10,"USP_ScriptTableCloneInternal":10}},"3.0.0":{"publicCommit":"2e1daeb60375b145360a15f173985ba921338976","files":{"Deployment/Deploy.sql":"2C7BBA0DA9399FD9A09E26153C51C697A943FB8895250368C5F54495A1E0F74E","Deployment/Uninstall.sql":"DAD7A3381D5B1EF7E753068AD6E4C51EC64DAB024175D7544C07B2D804122AF8","module.yaml":"90422EAF748EB9B58F9BD46DD4A5F9156FBAD486E8889AB6D714A22886A9FA7D","Source/USP_ScriptTableClone.sql":"6DAB20B3B74F127AB0591F0B064F75869EBA6AB76B06AC0135A30E8914FF8A90","Source/USP_ScriptTableCloneInternal.sql":"D5FCCBBE227D69F4C5CCC4FF82BD5BC7947D6C08D41BD49C8AE1D21786D82075"},"parameters":{"USP_ScriptTableClone":12,"USP_ScriptTableCloneInternal":12}},"3.1.0":{"publicCommit":"7c4b32fe23d8527cf2966e5dff2f6a5a0bc1de6c","files":{"Deployment/Deploy.sql":"FB47D42B0116F688F70827FB5E3C8C27F96CF63D03A8D4CE2FA0CC2981B972DE","Deployment/Uninstall.sql":"8A0D98DD620550FD45C13FE81E2265955EAB783CA9439BE2EDA486C2E057B769","module.yaml":"54775919DA590D30BCA5F149D35CB20FFDAADD2408078DFC194A7DC0E5094736","Source/USP_ExecuteTableClone.sql":"930E3731D5748758B135434348F479E9F90389D4A6E1B5E1CEDFA5F7F2550E09","Source/USP_ScriptTableClone.sql":"6DAB20B3B74F127AB0591F0B064F75869EBA6AB76B06AC0135A30E8914FF8A90","Source/USP_ScriptTableCloneInternal.sql":"D5FCCBBE227D69F4C5CCC4FF82BD5BC7947D6C08D41BD49C8AE1D21786D82075"},"parameters":{"USP_ExecuteTableClone":14,"USP_ScriptTableClone":12,"USP_ScriptTableCloneInternal":12}},"4.0.0":{"publicCommit":"7a240210850b859cf1cf2c016ff0fbeb4da99059","files":{"Deployment/Deploy.sql":"E27F3CF42411BD36681CAD96E70AC7CF6FF475F56E468C11184B611110E82163","Deployment/Uninstall.sql":"6B3A9613312648771025082D002AE8F84888CAB744BF75EB53A9D2EAF538EBDE","module.yaml":"5D4098195E3F7CBA608B9A7BDC89B44D8A56DABD3FD45127072C0E80A1D4C220","Source/USP_ExecuteTableClone.sql":"331315FD3C869AE76C335962B3AF44D12D298447D150F616027FF35AA866E186","Source/USP_ScriptTableClone.sql":"83F71CB371F5C09F730A7A2C5B6B2C1C5A56055FB8DD80C70536AC48479966DF","Source/USP_ScriptTableCloneInternal.sql":"077BED966B1EFBC299231338A1F4A4E66A87839FC48A1EE4E4E9DB27D1E9924E"},"parameters":{"USP_ExecuteTableClone":14,"USP_ScriptTableClone":13,"USP_ScriptTableCloneInternal":13}},"4.1.0":{"publicCommit":"86f4b53e9de0ecac22818892dcf0cb802b050bb6","files":{"Deployment/Deploy.sql":"FB59EF3DD9773C5E98705FF950FEE3343DF39DBE0C64B291CFC061616CA371E3","Deployment/Uninstall.sql":"D95B867BE80B2CE91A00AD70A15312095DE3FAD58B2B26D0333100658404BC91","module.yaml":"2D0F45D15C6B39FAF29FFC4B3113D433C79EAD4E459F462C504945A0DB4D8D14","Source/USP_CopyTableCloneData.sql":"48FCC2C3BE0CD795151EBE153D2BF7BD0261F0364E7A045EDA6503DB8A2E92A9","Source/USP_ExecuteTableClone.sql":"D3D410E0326A5D82E90BC99AE48A3D380D4E20B54919410AA95AA49660609CA4","Source/USP_ScriptTableClone.sql":"89ECDB0A3368F62BB17FBFE80B0B7BC2161833B80F62AEE99BAF6841D4808E49","Source/USP_ScriptTableCloneInternal.sql":"D45097DAB219367C8798ED4EEC10BA77D41F5AA57EC47A137181F4D7B74FF3FD"},"parameters":{"USP_CopyTableCloneData":9,"USP_ExecuteTableClone":14,"USP_ScriptTableClone":13,"USP_ScriptTableCloneInternal":14}}}
'@
function Assert-CloneKnownTreePins($Node){
 if(@($runset.pins|Where-Object path -CEQ $Node.Path).Count-ne1){throw 'CLONE_KNOWN_SOURCE_TREE_PIN'}
 foreach($child in $Node.Children){Assert-CloneKnownTreePins $child}
}
function Assert-CloneKnownInputs {
 $versions=@('2.0.0','3.0.0','3.1.0','4.0.0','4.1.0')
 if($runset.predecessors.Count-ne5){throw 'CLONE_KNOWN_PREDECESSOR_SET'}
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Deployment/Deploy-All.ps1') @('Get-SqlcmdScriptTree','ConvertTo-StandaloneSql')){. $block}
 for($i=0;$i-lt5;$i++){
  $row=$runset.predecessors[$i];$version=$versions[$i]
  if($row.version-cne$version){throw 'CLONE_KNOWN_VERSION_ORDER'}
  $root=Assert-ReleasePrivatePath $row.root;$expected=$script:knownExpected[$version]
  $provenance=Assert-ReleasePrivatePath (Join-Path $root 'provenance.json')
  $p=Get-Content -LiteralPath $provenance -Raw|ConvertFrom-Json
  if($p.version-cne$version-or$p.publicCommit-cne$expected.publicCommit-or$p.files.Count-ne$expected.files.Count){throw 'CLONE_KNOWN_PUBLIC_PROVENANCE'}
  foreach($name in $expected.files.Keys){
   $path=Assert-ReleasePrivatePath (Join-Path $root $name)
   if((Get-FileHash -LiteralPath $path).Hash-cne$expected.files[$name]-or@($p.files|Where-Object{$_.path-ceq$name-and$_.sha256-ceq$expected.files[$name]}).Count-ne1){throw 'CLONE_KNOWN_ORIGINAL_BYTES'}
   if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_KNOWN_ORIGINAL_PIN'}
  }
  if(@($runset.pins|Where-Object path -CEQ $provenance).Count-ne1){throw 'CLONE_KNOWN_PROVENANCE_PIN'}
  foreach($mode in @('local','central')){
   $node=Get-SqlcmdScriptTree -Path (Join-Path $root 'Deployment/Deploy.sql') -Cache @{}
   Assert-CloneKnownTreePins $node
   $text=ConvertTo-StandaloneSql -Node $node -Values @{DeploymentMode=$mode;ConfirmNoExternalConsumers='1'} -ModulesRoot $root
   $path=Assert-ReleasePrivatePath $row.texts.$mode
   if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1-or[IO.File]::ReadAllText($path)-cne$text){throw 'CLONE_KNOWN_ORIGINAL_RENDER'}
  }
 }
 foreach($mode in @('local','central')){foreach($kind in @('Deploy','Uninstall')){
  $node=Get-SqlcmdScriptTree -Path (Join-Path $repo ('Modules/toolbelt.metadata.table-clone/Deployment/'+$kind+'.sql')) -Cache @{}
  Assert-CloneKnownTreePins $node
  $text=ConvertTo-StandaloneSql -Node $node -Values @{DeploymentMode=$mode;ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules')
  if($kind-ceq'Deploy'){[void](New-CloneKnownFaultText $text)}
  $path=Assert-ReleasePrivatePath $runset.currentTexts.$mode.$kind
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1-or[IO.File]::ReadAllText($path)-cne$text){throw 'CLONE_KNOWN_CURRENT_RENDER'}
 }}
}
function Assert-CloneKnownInventory($Connection,[string]$Version,[string]$Mode){
 $rows=@(Invoke-ReleaseSql $Connection "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name IN(N'Toolbelt.Module.toolbelt.metadata.table-clone.Version',N'Toolbelt.Module.toolbelt.metadata.table-clone.DeploymentMode');" -Rows)
 $objects=@(Invoke-ReleaseSql $Connection "SELECT o.name,CONVERT(varchar(2),RTRIM(o.type)) TypeCode,(SELECT COUNT(*) FROM sys.parameters p WHERE p.object_id=o.object_id) Parameters FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE s.name=N'toolbelt_metadata' ORDER BY o.name;" -Rows)
 if($Version-ceq'ABSENT'){if($rows.Count-ne0-or$objects.Count-ne0){throw 'CLONE_KNOWN_UNINSTALL_REMAINS'};return}
 if($rows.Count-ne2-or@($rows|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.metadata.table-clone.Version'-and$_.Value-ceq$Version}).Count-ne1-or@($rows|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.metadata.table-clone.DeploymentMode'-and$_.Value-ceq$Mode}).Count-ne1){throw 'CLONE_KNOWN_MARKERS'}
 $expected=if($Version-ceq'4.1.1'){@{'USP_ScriptTableClone'=13;'USP_ScriptTableCloneInternal'=14;'USP_ExecuteTableClone'=14;'USP_CopyTableCloneData'=9}}else{$script:knownExpected[$Version].parameters}
 if($objects.Count-ne$expected.Count){throw 'CLONE_KNOWN_SLOT_COUNT'}
 foreach($name in $expected.Keys){if(@($objects|Where-Object{$_.name-ceq$name-and$_.TypeCode-ceq'P'-and$_.Parameters-eq$expected[$name]}).Count-ne1){throw 'CLONE_KNOWN_SIGNATURE'}}
}
function Invoke-CloneKnownOriginalSession($Observer,$Row,[string]$Mode){
 $legacy=$null
 try{
  # Nur die eigene Originalinstallationssitzung schließen; keine fremden Temps löschen.
  $legacy=Open-ReleaseConnection $Observer.Database
  Invoke-CloneKnownSqlBatches $legacy ([IO.File]::ReadAllText($Row.texts.$Mode))
  $state=@(Invoke-ReleaseSql $legacy 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
  if($state.Count-ne1-or$state[0].TranCount-ne0-or$state[0].XactState-ne0){throw 'CLONE_KNOWN_ORIGINAL_TX'}
 }finally{if($legacy){$legacy.Dispose()}}
 Assert-CloneKnownInventory $Observer $Row.version $Mode
}
function Invoke-CloneKnownProfiles($Connection,[string]$Mode){
 $dependency=Get-CloneKnownDependencySnapshot $Connection
 $completed=@()
 foreach($row in $runset.predecessors){
  $version=$row.version
  $script:stage='CLONE_KNOWN_'+$Mode+'_'+$version+'_SETUP_ORIGINAL'
  Invoke-CloneKnownOriginalSession $Connection $row $Mode
  foreach($profile in @('current-uninstall-original','upgrade-rollback','direct-upgrade')){
   $script:stage='CLONE_KNOWN_'+$Mode+'_'+$version+'_'+$profile
   $kind=if($profile-ceq'current-uninstall-original'){'Uninstall'}else{'Deploy'}
   $path=$runset.currentTexts.$Mode.$kind;$text=[IO.File]::ReadAllText($path)
   if($profile-ceq'upgrade-rollback'){
    $snapshot=Get-CloneKnownModuleSnapshot $Connection;$text=New-CloneKnownFaultText $text
    $probe=$null;$caught=$false
    try{
     $probe=Open-ReleaseConnection $Connection.Database
     try{Invoke-CloneKnownSqlBatches $probe $text}catch{
      $e=$_.Exception;while($e.InnerException-and$e-isnot[Data.SqlClient.SqlException]){$e=$e.InnerException}
      if($e-isnot[Data.SqlClient.SqlException]-or$e.Number-ne54932-or$e.State-ne1){$ledger.sqlFaults+=@(@{mode=$Mode;version=$version;profile=$profile;type=$e.GetType().FullName;privateMessage=$e.Message;number=$(if($e-is[Data.SqlClient.SqlException]){$e.Number}else{$null});state=$(if($e-is[Data.SqlClient.SqlException]){$e.State}else{$null})});Save-ReleaseJournal;throw [InvalidOperationException]::new('CLONE_KNOWN_ROLLBACK_CATEGORY',$e)}
      $caught=$true
     }
     $state=@(Invoke-ReleaseSql $probe 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
     if(-not$caught-or$state.Count-ne1-or$state[0].TranCount-ne0-or$state[0].XactState-ne0-or(Get-CloneKnownModuleSnapshot $Connection)-cne$snapshot){throw 'CLONE_KNOWN_ROLLBACK_CHANGED'}
    }finally{if($probe){$probe.Dispose()}}
    Assert-CloneKnownInventory $Connection $version $Mode
   }else{
    Invoke-CloneKnownSqlBatches $Connection $text
    Assert-CloneKnownInventory $Connection $(if($kind-ceq'Uninstall'){'ABSENT'}else{'4.1.1'}) $Mode
   }
   if((Get-CloneKnownDependencySnapshot $Connection)-cne$dependency){throw 'CLONE_KNOWN_DEPENDENCY_CHANGED'}
   $state=@(Invoke-ReleaseSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
   if($state.Count-ne1-or$state[0].TranCount-ne0-or$state[0].XactState-ne0){throw 'CLONE_KNOWN_OBSERVER_TX'}
   $ledger.lifecycleProfiles+=@(@{mode=$Mode;version=$version;profile=$profile;passed=$true;canonicalSHA256=(Get-FileHash -LiteralPath $path).Hash;executedSHA256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($text)))})
   $completed+=@($version+'/'+$profile);Save-ReleaseJournal
   if($profile-ceq'current-uninstall-original'){
    $script:stage='CLONE_KNOWN_'+$Mode+'_'+$version+'_SETUP_RESEED'
    Invoke-CloneKnownOriginalSession $Connection $row $Mode
   }
  }
  # Bereits qualifizierte aktuelle Deinstallation dient hier ausschließlich der Fixturebereinigung.
  $script:stage='CLONE_KNOWN_'+$Mode+'_'+$version+'_CLEANUP_CURRENT'
  Invoke-CloneKnownSqlBatches $Connection ([IO.File]::ReadAllText($runset.currentTexts.$Mode.Uninstall))
  Assert-CloneKnownInventory $Connection 'ABSENT' $Mode
  if((Get-CloneKnownDependencySnapshot $Connection)-cne$dependency){throw 'CLONE_KNOWN_CLEANUP_DEPENDENCY'}
 }
 return $completed
}

function Get-CloneKnownDependencySnapshot($Connection){
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
function Get-CloneKnownModuleSnapshot($Connection){
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
function New-CloneKnownFaultText([string]$Text){
 $anchor='    DROP TABLE #tbx_TableCloneReleaseObjects;'
 if(([regex]::Matches($Text,[regex]::Escape($anchor))).Count-ne1){throw 'CLONE_KNOWN_ROLLBACK_ANCHOR'}
 return $Text.Replace($anchor,"    THROW 54932,N'CLONE_SYNTHETIC_FINALINSTALL',1;`n"+$anchor)
}
function Get-CloneKnownSqlBatches([string]$Text){
 $Text=[regex]::Replace($Text,'(?im)^[\t ]*:ON[\t ]+ERROR[\t ]+EXIT[\t ]*\r?$','')
 if($Text-match'(?m)^[\t ]*:'-or$Text.Contains('$(')){throw 'CLONE_KNOWN_UNRESOLVED_SQLCMD'}
 # Nur horizontale Leerzeichen: der Kommentar der Folgezeile gehört zum SQL.
 return @([regex]::Split($Text,'(?im)^[\t ]*GO[\t ]*(?:--[^\r\n]*)?\r?$')|Where-Object{-not[string]::IsNullOrWhiteSpace($_)})
}
function Invoke-CloneKnownSqlBatches($Connection,[string]$Text){
 foreach($batch in Get-CloneKnownSqlBatches $Text){Invoke-ReleaseSql $Connection $batch}
}
try{
 $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
 $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json -DateKind String
 if($runset.schema_version-cne'table-clone-known-predecessors/v1'-or$runset.cases.Count-ne12-or
  $runset.explicit_qualification_approved-isnot[bool]-or$runset.explicit_qualification_approved-ne$true){throw 'CLONE_KNOWN_RUNSET_SCOPE'}
 $started=[DateTimeOffset]::Parse($runset.started_utc);$deadline=[DateTimeOffset]::Parse($runset.deadline_utc)
 if($deadline-ne$started.AddMinutes(60)-or$started-gt[DateTimeOffset]::UtcNow-or
  (-not$AuditOnly-and[DateTimeOffset]::UtcNow.AddMinutes(15)-ge$deadline)){throw 'CLONE_KNOWN_ADMISSION_CLOSED'}
 $expected=@('windows/2019/CU32/150','windows/2022/CU26/150','windows/2022/CU26/160',
  'windows/2025/CU8/150','windows/2025/CU8/160','windows/2025/CU8/170',
  'linux/2019/latest/150','linux/2022/latest/150','linux/2022/latest/160',
  'linux/2025/latest/150','linux/2025/latest/160','linux/2025/latest/170')
 for($i=0;$i-lt12;$i++){
  $c=$runset.cases[$i];$tuple=[string]$c.Platform+'/'+$c.Version+'/'+$c.Patch+'/'+$c.CL
  $modes='local,central'
  if($tuple-cne$expected[$i]-or(@($c.modes)-join',')-cne$modes){throw 'CLONE_KNOWN_CONTEXT_SCOPE'}
 }
 $case=$runset.cases[$CaseIndex];Assert-ReleaseInputs
 $fixtureNames=@(foreach($v in @('2.0.0','3.0.0','3.1.0','4.0.0','4.1.0')){foreach($p in @('current-uninstall-original','upgrade-rollback','direct-upgrade')){$v+'/'+$p}})
 foreach($path in @($PSCommandPath,$runset.exports.local,$runset.exports.central)+@(
  (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
  (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),
  (Join-Path $repo 'Tests/CI/Set-SqlClientTlsPolicy.ps1'),(Join-Path $repo 'Tests/CI/Assert-LabQualifiedTlsBinding.ps1'),
  (Join-Path $repo 'Deployment/Deploy-All.ps1'),(Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Deployment/Deploy.sql'),
  (Join-Path $repo 'Modules/toolbelt.metadata.table-clone/Deployment/Uninstall.sql'))){
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'CLONE_KNOWN_REQUIRED_PIN_MISSING'}
 }
 foreach($mode in @('local','central')){
  $export=[IO.File]::ReadAllText($runset.exports.$mode)
  $modules=@([regex]::Matches($export,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)\r?$')|ForEach-Object{$_.Groups[1].Value})
  if(($modules-join',')-cne'toolbelt.core.result-table'){throw 'CLONE_KNOWN_DEPENDENCY_ONLY_EXPORT'}
 }
 Assert-CloneKnownInputs
 if($ValidateOnly){'PASS CLONE_KNOWN_OFFLINE_ADMISSION; no Lab import or SQL';return}
 if(-not$IsWindows){throw 'CLONE_KNOWN_WINDOWS_CLIENT_REQUIRED'}
 if(@('TBX_LAB_QUALIFIED_CONTEXT_FILE','TBX_LAB_QUALIFIED_CONTEXT_SHA256','TBX_LAB_QUALIFIED_PWSH')|Where-Object{-not[string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($_,'Process'))}){throw 'CLONE_KNOWN_UNEXPECTED_QUALIFIED_CONTEXT'}
 . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
 foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
  'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
 $lab=Resolve-LabContract -TestPurpose Functional
 if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash-cne$runset.contract_sha256){throw 'CLONE_KNOWN_CONTRACT_DRIFT'}
 $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
 if($targets.Count-ne1){throw 'CLONE_KNOWN_EXACT_TARGET_REQUIRED'};$target=$targets[0]
 $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
 if($AuditOnly){
  $hash=(Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash
  $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -DateKind String
  if($prior.state-cnotin@('COMPLETE','FAILED_CLEANED')-or$prior.owner-cnotmatch'^[a-f0-9]{32}$'){throw 'CLONE_KNOWN_AUDIT_STATE'}
  $control=Open-ReleaseConnection 'master'
  $now=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform;" -Rows)
  if($now.Count-ne1-or$now[0].Major-ne$prior.observedTarget.Major-or$now[0].Version-cne$prior.observedTarget.Version-or$now[0].Platform-cne$prior.observedTarget.Platform){throw 'CLONE_KNOWN_AUDIT_TARGET_DRIFT'}
  foreach($entry in $prior.databases){
   if($entry.name-cne('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix)-or$entry.state-cne'DROPPED'){throw 'CLONE_KNOWN_AUDIT_IDENTITY'}
   $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
   if($rows.Count-ne1-or$rows[0].Id-isnot[DBNull]){throw 'CLONE_KNOWN_AUDIT_DATABASE_PRESENT'}
  }
  if($prior.serverSnapshot-and(Get-CloneKnownServerSnapshot $control)-cne$prior.serverSnapshot){throw 'CLONE_KNOWN_FOREIGN_SERVER_DRIFT'}
  Assert-ReleaseInputs
  if((Get-FileHash -LiteralPath $journal -Algorithm SHA256).Hash-cne$hash){throw 'CLONE_KNOWN_AUDIT_JOURNAL_DRIFT'}
  [IO.File]::WriteAllText(($journal+'.audit.json'),([ordered]@{state='COMPLETE';readOnly=$true;
   originalJournalSHA256=$hash;originalRunPassed=($prior.state-ceq'COMPLETE'-and$null-eq$prior.failure-and$prior.lifecycleProfiles.Count-eq30-and
   (@($prior.completedModes)-join',')-ceq(@($case.modes)-join',')-and$prior.witnesses.Count-eq2-and
   @($prior.witnesses|Where-Object{(@($_.fixtures)-join',')-cne($fixtureNames-join',')-or$_.compatibilityLevel-ne$case.CL-or$_.transactionNeutral-ne$true-or$_.dependencyUnchanged-ne$true}).Count-eq0);databaseAbsence=$true;
   serverConfigurationAndTrustUnchanged=$true;postPins=$true}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 }else{
  if(Test-Path -LiteralPath $journal){throw 'CLONE_KNOWN_CASE_ALREADY_ATTEMPTED'}
  $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();completedModes=@();witnesses=@();lifecycleProfiles=@();sqlFaults=@();serverSnapshot=$null;observedTarget=$null;failure=$null};Save-ReleaseJournal
  $control=Open-ReleaseConnection 'master'
  $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) Version,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
  if($actual.Count-ne1-or$actual[0].Major-ne@{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version]-or$actual[0].Platform-ine$case.Platform-or$actual[0].Admin-ne1){throw 'CLONE_KNOWN_ACTUAL_TARGET_MISMATCH'}
  $ledger.observedTarget=$actual[0];$ledger.serverSnapshot=Get-CloneKnownServerSnapshot $control;Save-ReleaseJournal
  foreach($mode in $case.modes){
   $stage='CREATE_'+$mode;$suffix=if($mode-ceq'local'){'l'}else{'c'};$name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
   $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'};$ledger.databases+=@($entry);Save-ReleaseJournal
   Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
   $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
   if($identity.Count-ne1){throw 'CLONE_KNOWN_DATABASE_IDENTITY'};$entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
   $db=Open-ReleaseConnection $name
   Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
   $entry.state='OWNED';Save-ReleaseJournal;Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
   $actualCl=@(Invoke-ReleaseSql $db 'SELECT compatibility_level CL FROM sys.databases WHERE database_id=DB_ID();' -Rows)
   if($actualCl.Count-ne1-or$actualCl[0].CL-ne$case.CL){throw 'CLONE_KNOWN_ACTUAL_CL'}
   $stage='INSTALL_'+$mode;Invoke-CloneKnownSqlBatches $db ([IO.File]::ReadAllText($runset.exports.$mode))
   $markers=@(Invoke-ReleaseSql $db "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.%.Version';" -Rows)
   if($markers.Count-ne1-or$markers[0].name-cne'Toolbelt.Module.toolbelt.core.result-table.Version'-or$markers[0].Value-cne'1.0.0'){throw 'CLONE_KNOWN_DEPENDENCY_CLOSURE'}
   $modes=@(Invoke-ReleaseSql $db "SELECT CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode';" -Rows)
   if($modes.Count-ne1-or$modes[0].Value-cne$mode){throw 'CLONE_KNOWN_DEPENDENCY_MODE'}
   if([int](@(Invoke-ReleaseSql $db 'SELECT COUNT(*) N FROM sys.assemblies WHERE is_user_defined=1;' -Rows)[0].N)-ne0){throw 'CLONE_KNOWN_UNEXPECTED_CLR'}
   $completed=@(Invoke-CloneKnownProfiles $db $mode)
   if(($completed-join'|')-cne($fixtureNames-join'|')){throw 'CLONE_KNOWN_INCOMPLETE_PROFILES'}
   $ledger.witnesses+=@(@{mode=$mode;fixtures=$completed;compatibilityLevel=$actualCl[0].CL;transactionNeutral=$true;dependencyUnchanged=$true})
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
   if($ledger.serverSnapshot-and(Get-CloneKnownServerSnapshot $control)-cne$ledger.serverSnapshot){throw 'CLONE_KNOWN_FOREIGN_SERVER_DRIFT'}
   Assert-ReleaseInputs;$ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
  }catch{$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
  finally{if($control){$control.Dispose()}}
 }
}
if($failure){if($ValidateOnly){throw $failure};'FAIL CLONE_KNOWN_TARGETS; inspect private journal; no automatic replay';exit 1}
if($AuditOnly){'PASS CLONE_KNOWN_TARGETS fresh independent final journal/absence audit'}else{'PASS CLONE_KNOWN_TARGETS selected five-predecessor direct current lifecycle profiles; independent audit required'}
