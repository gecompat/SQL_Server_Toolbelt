[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
      [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedRunsetSHA256,
      [switch]$ValidateOnly,[switch]$AuditOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$repo=$script:repo
$script:RunsetPath=$RunsetPath
$script:ExpectedRunsetSHA256=$ExpectedRunsetSHA256
$script:connections=[Collections.Generic.List[object]]::new()
$script:clock=[Diagnostics.Stopwatch]::StartNew()
$script:cleanup=$false
$script:failure=$null;$script:stage='PREPARE';$script:ledger=$null;$ledger=$null
$control=$null;$db=$null;$script:expectedOwnDbState=$null;$script:expectedOwnCore=$null

$astErrors=$null
$apiAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$astErrors)
if($astErrors.Count){throw 'JSON_UNINSTALL_CONFIRMATION_HELPER_PARSE'}
$nodes=@($apiAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_HELPER_DISCOVERY'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $script:repo 'Tests/Release/Invoke-StablePackageLab.ps1') @(
    'Assert-ReleasePin','Assert-ReleasePrivatePath','Get-ReleaseTimeout','Invoke-ReleaseSql','Open-ReleaseConnection',
    'Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity') @{
        'function Invoke-ReleaseSql('='function Invoke-ReleaseSqlCore('}){. $block}
. (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1')
. (Join-Path $script:repo 'Tests/CI/LabQualifiedContract.ps1')
foreach($block in Import-ClrFunctions (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1') @(
    'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}

# Reuse the already-qualified AppLock protocol and full-state reader as exact AST functions.
$sourcePath=Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1'
$sourceErrors=$null;$sourceAst=[Management.Automation.Language.Parser]::ParseFile($sourcePath,[ref]$null,[ref]$sourceErrors)
if($sourceErrors.Count){throw 'JSON_UNINSTALL_CONFIRMATION_SOURCE_PARSE'}
$reuse=@('Sql','Invoke-ReleaseBatches','Read-Scalar','Get-ModuleState','Assert-CoreOnly','Assert-SchemaAbsent','Assert-SchemaModuleAbsent',
    'New-ContenderStateDiagnostic','New-ContenderStateSummary','Get-ExternalSessionState',
    'Get-ContenderStateSamples','Test-ExternalSessionIdle','Test-ContenderStateIdle')
foreach($name in $reuse){
    $found=@($sourceAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
    if($found.Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_REUSE_FUNCTION'}
    . ([scriptblock]::Create($found[0].Extent.Text))
}

function Assert-Runset {
    if(-not(Get-Command Invoke-ReleaseSqlCore -CommandType Function -ErrorAction SilentlyContinue)){throw 'JSON_UNINSTALL_CONFIRMATION_SQL_HELPER_MISSING'}
    $script:RunsetPath=Assert-ReleasePrivatePath $script:RunsetPath
    if((Get-FileHash -LiteralPath $script:RunsetPath -Algorithm SHA256).Hash -cne $script:ExpectedRunsetSHA256.ToUpperInvariant()){throw 'JSON_UNINSTALL_CONFIRMATION_RUNSET_PIN_DRIFT'}
    $script:runset=Get-Content -LiteralPath $script:RunsetPath -Raw -Encoding UTF8|ConvertFrom-Json
    if($script:runset.schema_version -cne 'json-schema-uninstall-confirmation-probe/v1' -or $script:runset.operation -cne 'schema-uninstall-confirmation' -or
       $script:runset.target.platform -cne 'windows' -or $script:runset.target.version -cne '2025' -or $script:runset.target.patch -cne 'CU8' -or
       ($script:runset.target.compatibility_level -isnot [int] -and $script:runset.target.compatibility_level -isnot [long]) -or $script:runset.target.compatibility_level -ne 170 -or
       $script:runset.target.test_purpose -cne 'Functional' -or $script:runset.scope.deployment_mode -cne 'central' -or
       (($script:runset.scope.expected_error -isnot [int] -and $script:runset.scope.expected_error -isnot [long]) -or $script:runset.scope.expected_error -ne 55635) -or
       (($script:runset.scope.expected_state -isnot [int] -and $script:runset.scope.expected_state -isnot [long]) -or $script:runset.scope.expected_state -ne 1)){throw 'JSON_UNINSTALL_CONFIRMATION_RUNSET_INVALID'}
    $profile=$script:runset.scope.initial_session_profile
    if($profile.quoted_identifier-cne'ON' -or $profile.nocount-cne'ON' -or $profile.xact_abort-cne'ON' -or
       $profile.implicit_transactions-cne'OFF' -or ($profile.transaction_count-isnot[int]-and$profile.transaction_count-isnot[long]) -or $profile.transaction_count-ne0 -or
       $profile.options_unchanged_across_rejection-isnot[bool] -or -not$profile.options_unchanged_across_rejection){throw 'JSON_UNINSTALL_CONFIRMATION_SESSION_PROFILE_INVALID'}
    Assert-UninstallCaseShape @($script:runset.scope.cases)
    $artifactModules=@($script:runset.artifacts.module_id|Sort-Object -CaseSensitive)
    if($script:runset.artifacts.Count-ne2 -or ($artifactModules-join'|')-cne'toolbelt.json.core|toolbelt.json.schema' -or
       $script:runset.baseline.modules.Count-ne2 -or
       $script:runset.baseline.modules[0]-cne'toolbelt.core.result-table' -or $script:runset.baseline.modules[1]-cne'toolbelt.json.core' -or
       $script:runset.schema_deploy.module-cne'toolbelt.json.schema' -or $script:runset.schema_uninstall.module-cne'toolbelt.json.schema'){
       throw 'JSON_UNINSTALL_CONFIRMATION_ARTIFACT_SCOPE'}
    $required=@($PSCommandPath,(Join-Path $script:repo 'Tests/Release/Prepare-JsonSchemaUninstallConfirmationRunset.ps1'),
      (Join-Path $script:repo 'Tests/Release/Test-JsonSchemaUninstallConfirmationOffline.ps1'),
      $sourcePath,
      (Join-Path $script:repo 'Tests/Release/Invoke-StablePackageLab.ps1'),(Join-Path $script:repo 'Tests/Release/ClrCaller.Environment.ps1'),
      (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $script:repo 'Tests/CI/LabQualifiedContract.ps1'))
    foreach($path in $required){if(@($script:runset.pins|Where-Object{$_.path-ceq$path}).Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_REQUIRED_PIN_MISSING'}}
    foreach($export in @($script:runset.baseline,$script:runset.schema_deploy,$script:runset.schema_uninstall)+@($script:runset.scope.cases)){
        $export.path=Assert-ReleasePrivatePath ([string]$export.path)
        if(@($script:runset.pins|Where-Object{$_.path-ceq$export.path -and $_.sha256-ceq$export.sha256}).Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_EXPORT_PIN_MISSING'}
    }
    $baselineText=[IO.File]::ReadAllText([string]$script:runset.baseline.path,[Text.Encoding]::UTF8)
    $schemaDeployText=[IO.File]::ReadAllText([string]$script:runset.schema_deploy.path,[Text.Encoding]::UTF8)
    if(-not$baselineText.Contains("@DeploymentMode       nvarchar(16)  = LOWER(N'central')",[StringComparison]::Ordinal) -or
       -not$baselineText.Contains("DECLARE @Mode nvarchar(max)=N'central',",[StringComparison]::Ordinal) -or
       -not$schemaDeployText.Contains("DECLARE @Mode nvarchar(max)=N'central',",[StringComparison]::Ordinal)){throw 'JSON_UNINSTALL_CONFIRMATION_CENTRAL_SQL_BINDING_INVALID'}
    Assert-ConfirmationSql ([IO.File]::ReadAllText([string]$script:runset.schema_uninstall.path,[Text.Encoding]::UTF8)) '1'
    foreach($case in $script:runset.scope.cases){Assert-ConfirmationSql ([IO.File]::ReadAllText([string]$case.path,[Text.Encoding]::UTF8)) ([string]$case.confirmation)}
    $script:runset.base_runset.path=Assert-ReleasePrivatePath ([string]$script:runset.base_runset.path)
    $pinSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($pin in $script:runset.pins){
       if(-not$pinSet.Add([IO.Path]::GetFullPath([string]$pin.path))){throw 'JSON_UNINSTALL_CONFIRMATION_DUPLICATE_PIN'}
       Assert-ReleasePin $pin.path $pin.sha256
    }
    $pinMap=@{};foreach($pin in $script:runset.pins){$pinMap[[IO.Path]::GetFullPath([string]$pin.path)]=[string]$pin.sha256}
    Assert-ReleaseInputs
    if((Get-FileHash -LiteralPath $script:runset.base_runset.path -Algorithm SHA256).Hash -cne $script:runset.base_runset.sha256.ToUpperInvariant()){
        throw 'JSON_UNINSTALL_CONFIRMATION_BASE_RUNSET_DRIFT'
    }
    foreach($artifact in $script:runset.artifacts){
        if($artifact.module_id-cnotin@('toolbelt.json.core','toolbelt.json.schema') -or
           (Get-FileHash -LiteralPath $artifact.path -Algorithm SHA256).Hash.ToLowerInvariant()-cne$artifact.sha256 -or
           (Get-FileHash -LiteralPath $artifact.path -Algorithm SHA512).Hash.ToLowerInvariant()-cne$artifact.sha512){throw 'JSON_UNINSTALL_CONFIRMATION_ARTIFACT_DRIFT'}
    }
    $baseRunset=Get-Content -LiteralPath $script:runset.base_runset.path -Raw -Encoding UTF8|ConvertFrom-Json
    if($baseRunset.schema_version-cne'json-schema-applock-probe/v1' -or
       $baseRunset.scope.expected_error-ne55637 -or $baseRunset.scope.expected_state-ne1 -or
       @($baseRunset.artifacts).Count-ne2 -or @($baseRunset.baseline.modules).Count-ne2 -or
       $baseRunset.baseline.modules[0]-cne'toolbelt.core.result-table' -or $baseRunset.baseline.modules[1]-cne'toolbelt.json.core' -or
       $baseRunset.schema_deploy.module-cne'toolbelt.json.schema' -or $baseRunset.schema_uninstall.module-cne'toolbelt.json.schema'){
        throw 'JSON_UNINSTALL_CONFIRMATION_BASE_RUNSET_INVALID'
    }
    Assert-ArtifactClosure @($baseRunset.artifacts) @($script:runset.artifacts) $pinMap
    $required=@($PSCommandPath,(Join-Path $script:repo 'Tests/Release/Prepare-JsonSchemaUninstallConfirmationRunset.ps1'),
      (Join-Path $script:repo 'Tests/Release/Test-JsonSchemaUninstallConfirmationOffline.ps1'),$sourcePath,
      (Join-Path $script:repo 'Tests/Release/Invoke-StablePackageLab.ps1'),(Join-Path $script:repo 'Tests/Release/ClrCaller.Environment.ps1'),
      (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $script:repo 'Tests/CI/LabQualifiedContract.ps1'),
      (Join-Path $script:repo 'Tests/Release/Invoke-ApiQualificationLab.ps1'),
      (Join-Path $script:repo 'Tests/Release/Prepare-JsonSchemaAppLockRunset.ps1'),
      (Join-Path $script:repo 'Tests/Release/Test-JsonSchemaAppLockOffline.ps1'))
    Assert-RequiredPins $pinMap $required
    foreach($export in @($script:runset.baseline,$script:runset.schema_deploy,$script:runset.schema_uninstall)+@($script:runset.scope.cases)){
       if((Get-FileHash -LiteralPath $export.path -Algorithm SHA256).Hash.ToLowerInvariant()-cne([string]$export.sha256).ToLowerInvariant()){throw 'JSON_UNINSTALL_CONFIRMATION_EXPORT_DRIFT'}
    }
}
function Assert-ConfirmationSql([string]$Sql,[string]$Confirmation){
    $declaration="DECLARE @Confirmation nvarchar(max)=N'"+$Confirmation+"'"
    if([regex]::Matches($Sql,[regex]::Escape($declaration)).Count-ne1 -or $Sql-match'(?m)^:|\$\('){throw 'JSON_UNINSTALL_CONFIRMATION_SQL_INPUT_BINDING_INVALID'}
}
function Assert-RequiredPins($PinMap,$Required){
    foreach($path in $Required){if(-not$PinMap.ContainsKey([IO.Path]::GetFullPath([string]$path))){throw 'JSON_UNINSTALL_CONFIRMATION_REQUIRED_PIN_MISSING'}}
}
function Assert-ArtifactClosure($BaseArtifacts,$Artifacts,$PinMap){
    $expected=@{'toolbelt.json.core'='Toolbelt_JsonCore';'toolbelt.json.schema'='Toolbelt_JsonSchema'}
    if(@($BaseArtifacts).Count-ne2-or@($Artifacts).Count-ne2){throw 'JSON_UNINSTALL_CONFIRMATION_ARTIFACT_CLOSURE_INVALID'}
    foreach($module in @('toolbelt.json.core','toolbelt.json.schema')){
        $base=@($BaseArtifacts|Where-Object{$_.module_id-ceq$module});$current=@($Artifacts|Where-Object{$_.module_id-ceq$module})
        if($base.Count-ne1-or$current.Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_ARTIFACT_CLOSURE_INVALID'}
        $item=$current[0];$source=$base[0]
        if($item.path-isnot[string]-or$item.path-cne$source.path-or$item.sql_name-cne$expected[$module]-or$item.sql_name-cne$source.sql_name-or
           $item.sha256-isnot[string]-or$item.sha256-cnotmatch'^[A-Fa-f0-9]{64}$'-or$item.sha256-ine$source.sha256-or
           $item.sha512-isnot[string]-or$item.sha512-cnotmatch'^[A-Fa-f0-9]{128}$'-or$item.sha512-ine$source.sha512){throw 'JSON_UNINSTALL_CONFIRMATION_ARTIFACT_CLOSURE_INVALID'}
        $full=[IO.Path]::GetFullPath($item.path)
        if(-not$PinMap.ContainsKey($full)-or$PinMap[$full]-ine$item.sha256){throw 'JSON_UNINSTALL_CONFIRMATION_ARTIFACT_PIN_INVALID'}
        if((Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash-cne$item.sha256.ToUpperInvariant() -or
           (Get-FileHash -LiteralPath $full -Algorithm SHA512).Hash-cne$item.sha512.ToUpperInvariant()){throw 'JSON_UNINSTALL_CONFIRMATION_ARTIFACT_DIGEST_DRIFT'}
    }
}
function Assert-UninstallCaseShape($Cases){
    $expected=@(
      [ordered]@{ordinal=0;confirmation='01';expected_error=55635;expected_state=1;expected_message='JSON Schema lifecycle: ungültige Consumer-Bestätigung.'},
      [ordered]@{ordinal=1;confirmation='0';expected_error=55635;expected_state=1;expected_message='JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.'})
    if(@($Cases).Count-ne2){throw 'JSON_UNINSTALL_CONFIRMATION_CASES_INVALID'}
    for($i=0;$i-lt2;$i++){
        $actual=$Cases[$i]
        if(($actual.ordinal-isnot[int]-and$actual.ordinal-isnot[long]) -or $actual.ordinal-ne$expected[$i].ordinal -or
           $actual.confirmation-cne$expected[$i].confirmation -or $actual.path-isnot[string] -or
           $actual.sha256-isnot[string] -or $actual.sha256-cnotmatch'^[A-F0-9]{64}$' -or
           ($actual.expected_error-isnot[int]-and$actual.expected_error-isnot[long]) -or $actual.expected_error-ne$expected[$i].expected_error -or
           ($actual.expected_state-isnot[int]-and$actual.expected_state-isnot[long]) -or $actual.expected_state-ne$expected[$i].expected_state -or
           $actual.expected_message-cne$expected[$i].expected_message){throw 'JSON_UNINSTALL_CONFIRMATION_CASES_INVALID'}
    }
}
function Assert-RunsetStable {
    if((Get-FileHash -LiteralPath $script:RunsetPath -Algorithm SHA256).Hash -cne $script:ExpectedRunsetSHA256.ToUpperInvariant()){throw 'JSON_UNINSTALL_CONFIRMATION_RUNSET_PIN_DRIFT'}
    Assert-ReleaseInputs
}
function Invoke-ReleaseSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    Assert-RunsetStable
    Invoke-ReleaseSqlCore $Connection $Sql $Parameters -Rows:$Rows
}
function Get-LabSelectorTarget {
    $lab=Resolve-LabContract -TestPurpose Functional
    if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash.ToLowerInvariant()-cne$script:runset.lab.contract_sha256 -or
       (Get-FileHash -LiteralPath $lab.SchemaPath -Algorithm SHA256).Hash.ToLowerInvariant()-cne$script:runset.lab.schema_sha256){throw 'JSON_UNINSTALL_CONFIRMATION_LAB_DRIFT'}
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform='windows';Version='2025';Patch='CU8'}))
    if($targets.Count-ne1 -or -not(Test-LabTargetReady -Contract $lab.Contract -Entry $targets[0])){throw 'JSON_UNINSTALL_CONFIRMATION_EXACT_READY_TARGET_REQUIRED'}
    $script:target=$targets[0]
    if($script:target.encrypt-isnot[bool] -or -not$script:target.encrypt -or $script:target.trustServerCertificate-isnot[bool]){throw 'JSON_UNINSTALL_CONFIRMATION_TRANSPORT_INVALID'}
}
function Save-Journal {
    $temporary=$script:journal+'.writing'
    [IO.File]::WriteAllText($temporary,($script:ledger|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
    [IO.File]::Move($temporary,$script:journal,$true)
}
function Read-CoreProjection($Connection){
    $query=@'
SELECT
 (SELECT schema_id,principal_id FROM sys.schemas WHERE name=N'toolbelt_core' FOR JSON PATH) CoreSchema,
 (SELECT a.assembly_id,a.name,a.principal_id,a.permission_set_desc,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) BinaryHash
  FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_JsonCore' FOR JSON PATH) CoreAssembly,
 (SELECT ep.class,ep.major_id,ep.minor_id,ep.name,CONVERT(nvarchar(4000),ep.value) Value FROM sys.extended_properties ep
  WHERE ep.name LIKE N'Toolbelt.%' AND (
   (ep.class=0 AND (ep.name LIKE N'Toolbelt.Module.toolbelt.json.core.%' OR ep.name LIKE N'Toolbelt.Module.toolbelt.core.result-table.%')) OR
   (ep.class=3 AND ep.major_id=SCHEMA_ID(N'toolbelt_core')) OR
   (ep.class=1 AND ep.major_id IN(SELECT object_id FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_core'))) OR
   (ep.class=5 AND ep.major_id IN(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonCore')))
  ORDER BY ep.class,ep.major_id,ep.minor_id,ep.name FOR JSON PATH) Metadata,
 (SELECT o.object_id,o.principal_id,o.name,o.type,sm.definition,am.assembly_id,am.assembly_class,am.assembly_method
  FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules sm ON sm.object_id=o.object_id
  LEFT JOIN sys.assembly_modules am ON am.object_id=o.object_id WHERE s.name=N'toolbelt_core' ORDER BY o.object_id FOR JSON PATH) Objects,
 (SELECT dp.class,dp.major_id,dp.minor_id,dp.grantee_principal_id,dp.grantor_principal_id,dp.type,dp.permission_name,dp.state
  FROM sys.database_permissions dp WHERE dp.class=0
   OR (dp.class=3 AND dp.major_id=SCHEMA_ID(N'toolbelt_core'))
   OR (dp.class=1 AND dp.major_id IN(SELECT object_id FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_core')))
   OR (dp.class=5 AND dp.major_id IN(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonCore'))
  ORDER BY dp.class,dp.major_id,dp.minor_id,dp.grantee_principal_id,dp.permission_name FOR JSON PATH) Permissions,
 (SELECT role_principal_id,member_principal_id FROM sys.database_role_members ORDER BY role_principal_id,member_principal_id FOR JSON PATH) RoleMemberships,
 (SELECT principal_id,name,type,type_desc,default_schema_name,authentication_type_desc,CONVERT(varchar(258),sid,2) Sid
  FROM sys.database_principals ORDER BY principal_id FOR JSON PATH) Principals;
'@
    $rows=@(Sql $Connection $query -Rows);if($rows.Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_CORE_SNAPSHOT_SHAPE'}
    return ($rows[0]|ConvertTo-Json -Depth 5 -Compress)
}
function Assert-ExactBlock($Connection,$Observer,$Case,$Before,[int]$Spid,$Baseline){
    $beforeOptions=[int](Read-Scalar $Connection 'SELECT @@OPTIONS AS ScalarValue;')
    $beforeTran=[int](Read-Scalar $Connection 'SELECT @@TRANCOUNT AS ScalarValue;')
    $beforeXact=[int](Read-Scalar $Connection 'SELECT XACT_STATE() AS ScalarValue;')
    $beforeModule=Get-ModuleState $Connection
    $beforeCore=Read-CoreProjection $Connection
    $caught=$null
    try{Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText([string]$Case.path,[Text.Encoding]::UTF8))}
    catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}
    $sqlErrors=if($caught-is[Data.SqlClient.SqlException]){@($caught.Errors)}else{@()}
    $exactErrors=@($sqlErrors|Where-Object{$_.Number-eq[int]$Case.expected_error -and $_.State-eq[int]$Case.expected_state -and $_.Class-eq16 -and $_.Message-ceq[string]$Case.expected_message})
    if($caught-isnot[Data.SqlClient.SqlException] -or $caught.Number-ne[int]$Case.expected_error -or $caught.State-ne[int]$Case.expected_state -or $caught.Class-ne16 -or
       $sqlErrors.Count-ne1 -or $exactErrors.Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_EXPECTED_ERROR_MISMATCH'}
    $afterOptions=[int](Read-Scalar $Connection 'SELECT @@OPTIONS AS ScalarValue;')
    $afterTran=[int](Read-Scalar $Connection 'SELECT @@TRANCOUNT AS ScalarValue;')
    $afterXact=[int](Read-Scalar $Connection 'SELECT XACT_STATE() AS ScalarValue;')
    $afterSpid=[int](Read-Scalar $Connection 'SELECT @@SPID AS ScalarValue;')
    $external=@(Get-ExternalSessionState $Observer $Spid)
    $sessionUnchanged=$Connection.State-eq[Data.ConnectionState]::Open -and $afterSpid-eq$Spid
    $optionsUnchanged=$beforeOptions-eq$afterOptions
    $transactionUnchanged=$beforeTran-eq0 -and $beforeXact-eq0 -and $afterTran-eq0 -and $afterXact-eq0 -and (Test-ExternalSessionIdle $external $Spid)
    $moduleUnchanged=(Get-ModuleState $Connection)-ceq$beforeModule -and (Get-ModuleState $Connection)-ceq$Before
    $coreUnchanged=(Read-CoreProjection $Connection)-ceq$beforeCore
    if(-not$sessionUnchanged -or -not$optionsUnchanged -or -not$transactionUnchanged -or -not$moduleUnchanged -or -not$coreUnchanged){
        $script:ledger.diagnostics+=@([ordered]@{ordinal=[int]$Case.ordinal;session_unchanged=$sessionUnchanged;options_unchanged=$optionsUnchanged;transaction_unchanged=$transactionUnchanged;module_unchanged=$moduleUnchanged;core_unchanged=$coreUnchanged})
        Save-Journal;throw 'JSON_UNINSTALL_CONFIRMATION_BLOCK_CHANGED_STATE'
    }
    $script:ledger.results+=@([ordered]@{ordinal=[int]$Case.ordinal;confirmation=[string]$Case.confirmation;expected_error_number=[int]$Case.expected_error;expected_error_state=[int]$Case.expected_state;error_class=16;blocked=$true;exact_error=$true;state_unchanged=$true;session_unchanged=$true;options_unchanged=$true;transaction_unchanged=$true;module_unchanged=$true;core_unchanged=$true})
    Save-Journal
}
function Read-JsonSchemaNamespace($Connection){
    $rows=@(Sql $Connection @'
SELECT s.schema_id,s.principal_id,USER_NAME(s.principal_id) EffectiveOwner FROM sys.schemas s WHERE s.name=N'toolbelt_json';
'@ -Rows)
    if($rows.Count-ne1 -or [int]$rows[0].schema_id-le0 -or [int]$rows[0].principal_id-le0 -or [string]::IsNullOrWhiteSpace([string]$rows[0].EffectiveOwner)){
        throw 'JSON_UNINSTALL_CONFIRMATION_NAMESPACE_IDENTITY_INVALID'
    }
    return ($rows[0]|ConvertTo-Json -Compress)
}
function Assert-PositiveUninstall($Connection,$Observer,$BeforeCore,$BeforeNamespace){
    $beforeOptions=[int](Read-Scalar $Connection 'SELECT @@OPTIONS AS ScalarValue;')
    $beforeSpid=[int](Read-Scalar $Connection 'SELECT @@SPID AS ScalarValue;')
    Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText($script:runset.schema_uninstall.path,[Text.Encoding]::UTF8))
    Assert-SchemaModuleAbsent $Connection
    Assert-CoreOnly $Connection
    Assert-CoreModeCentral $Connection
    $external=@(Get-ExternalSessionState $Observer $beforeSpid)
    if((Read-CoreProjection $Connection)-cne$BeforeCore -or (Read-JsonSchemaNamespace $Connection)-cne$BeforeNamespace -or
       [int](Read-Scalar $Connection 'SELECT @@OPTIONS AS ScalarValue;')-ne$beforeOptions -or
       [int](Read-Scalar $Connection 'SELECT @@SPID AS ScalarValue;')-ne$beforeSpid -or [int](Read-Scalar $Connection 'SELECT @@TRANCOUNT AS ScalarValue;')-ne0 -or
       [int](Read-Scalar $Connection 'SELECT XACT_STATE() AS ScalarValue;')-ne0 -or -not(Test-ExternalSessionIdle $external $beforeSpid)){throw 'JSON_UNINSTALL_CONFIRMATION_CORE_OR_SESSION_CHANGED'}
}
function Assert-CoreModeCentral($Connection){
    $rows=@(Sql $Connection @'
SELECT name,CONVERT(nvarchar(16),value) Value FROM sys.extended_properties WHERE class=0 AND
 name IN(N'Toolbelt.Module.toolbelt.json.core.DeploymentMode',N'Toolbelt.Module.toolbelt.core.result-table.DeploymentMode') ORDER BY name;
'@ -Rows)
    if($rows.Count-ne2 -or @($rows|Where-Object{$_.Value-cne'central'}).Count-ne0){throw 'JSON_UNINSTALL_CONFIRMATION_CENTRAL_BASELINE_INVALID'}
}
function Assert-SchemaAssemblyClosure($Rows,$Artifacts){
    $expected=@($Artifacts|Sort-Object module_id -CaseSensitive)
    $actual=@($Rows|Sort-Object name -CaseSensitive)
    if($expected.Count-ne2 -or $actual.Count-ne2){throw 'JSON_UNINSTALL_CONFIRMATION_ASSEMBLY_CLOSURE_INVALID'}
    $wantedNames=@('Toolbelt_JsonCore','Toolbelt_JsonSchema')
    if(($actual.name -join '|')-cne($wantedNames -join '|')){throw 'JSON_UNINSTALL_CONFIRMATION_ASSEMBLY_CLOSURE_INVALID'}
    foreach($artifact in $expected){
        $name=[string]$artifact.sql_name
        $match=@($actual|Where-Object{$_.name-ceq$name})
        if($match.Count-ne1 -or $match[0].permission_set_desc-cne'SAFE_ACCESS' -or
           [string]$match[0].BinaryHash-cne$artifact.sha512.ToUpperInvariant()){
            throw 'JSON_UNINSTALL_CONFIRMATION_ASSEMBLY_CLOSURE_INVALID'
        }
    }
}
function Assert-SchemaSlots($Slots,[int]$SchemaAssemblyId){
    if(@($Slots).Count-ne2){throw 'JSON_UNINSTALL_CONFIRMATION_SCHEMA_SLOTS_INVALID'}
    $procedure=@($Slots|Where-Object{$_.name-ceq'USP_ValidateJsonSchema'})
    $bridge=@($Slots|Where-Object{$_.name-ceq'FT_ValidateJsonSchemaInternal'})
    if($procedure.Count-ne1 -or $procedure[0].type-cne'P' -or
       ($null-ne$procedure[0].assembly_id -and $procedure[0].assembly_id-isnot[DBNull]) -or
       $bridge.Count-ne1 -or $bridge[0].type-cne'FT' -or $bridge[0].assembly_id-is[DBNull] -or
       [int]$bridge[0].assembly_id-ne$SchemaAssemblyId){throw 'JSON_UNINSTALL_CONFIRMATION_SCHEMA_SLOTS_INVALID'}
}
function Assert-SchemaInstalled($Connection){
    $rows=@(Sql $Connection @'
SELECT a.name,a.assembly_id,a.principal_id,a.permission_set_desc,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) BinaryHash
FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1;
'@ -Rows)
    $metadata=@(Sql $Connection @'
SELECT ep.name,CONVERT(nvarchar(128),ep.value) Value FROM sys.extended_properties ep WHERE ep.class=0
AND ep.name IN(N'Toolbelt.Module.toolbelt.json.schema.Version',N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode') ORDER BY ep.name;
'@ -Rows)
    $schema=@(Sql $Connection "SELECT s.schema_id,s.principal_id FROM sys.schemas s WHERE s.name=N'toolbelt_json';" -Rows)
    $slots=@(Sql $Connection @'
SELECT o.name,RTRIM(o.type) type,am.assembly_id FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
LEFT JOIN sys.assembly_modules am ON am.object_id=o.object_id
WHERE s.name=N'toolbelt_json' AND o.name IN(N'USP_ValidateJsonSchema',N'FT_ValidateJsonSchemaInternal') ORDER BY o.name;
'@ -Rows)
    $version=@($metadata|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.json.schema.Version'})
    $mode=@($metadata|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.json.schema.DeploymentMode'})
    Assert-SchemaAssemblyClosure $rows $script:runset.artifacts
    $schemaAssembly=@($rows|Where-Object{$_.name-ceq'Toolbelt_JsonSchema'})
    Assert-SchemaSlots $slots ([int]$schemaAssembly[0].assembly_id)
    if($schema.Count-ne1 -or
       [int]$schema[0].principal_id-ne1 -or $version.Count-ne1 -or $version[0].Value-cne'1.0.1' -or
       $mode.Count-ne1 -or $mode[0].Value-cne'central'){
        throw 'JSON_UNINSTALL_CONFIRMATION_SCHEMA_INSTALL_INVALID'
    }
}

try{
    Assert-Runset;Get-LabSelectorTarget
    if($ValidateOnly){Assert-RunsetStable;Write-Output 'PASS JSON_SCHEMA_UNINSTALL_CONFIRMATION runset validated; no SQL executed';return}
    $script:journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $script:RunsetPath) 'case.json')
    if($AuditOnly){
        $prior=Get-Content -LiteralPath $script:journal -Raw -Encoding UTF8|ConvertFrom-Json
        $priorCount=@($prior.results).Count
        if(($prior.state-cne'COMPLETE' -and $prior.state-cne'FAILED_CLEANED') -or
           ($prior.state-ceq'COMPLETE' -and $priorCount-ne2) -or ($prior.state-ceq'FAILED_CLEANED' -and $priorCount-gt2) -or @($prior.databases).Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_JOURNAL_INVALID'}
        $expectedConfirmations=@('01','0')
        for($i=0;$i-lt$priorCount;$i++){
            $record=$prior.results[$i]
            if(($record.ordinal-isnot[int] -and $record.ordinal-isnot[long]) -or $record.ordinal-ne$i -or $record.confirmation-cne$expectedConfirmations[$i]){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_RESULT_INVALID'}
            foreach($field in @('blocked','exact_error','state_unchanged','session_unchanged','options_unchanged','transaction_unchanged','module_unchanged','core_unchanged')){
                if($record.$field-isnot[bool] -or -not$record.$field){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_RESULT_INVALID'}
            }
        }
        $positiveCount=@($prior.positive_controls).Count
        if(($prior.state-ceq'COMPLETE' -and $positiveCount-ne1) -or $positiveCount-gt1){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_POSITIVE_CONTROL_INVALID'}
        for($i=0;$i-lt$positiveCount;$i++){if($prior.positive_controls[$i].ordinal-ne0 -or $prior.positive_controls[$i].confirmation-cne'1' -or $prior.positive_controls[$i].uninstall_succeeded-isnot[bool] -or -not$prior.positive_controls[$i].uninstall_succeeded -or $prior.positive_controls[$i].module_absent-isnot[bool] -or -not$prior.positive_controls[$i].module_absent -or $prior.positive_controls[$i].namespace_retained-isnot[bool] -or -not$prior.positive_controls[$i].namespace_retained -or $prior.positive_controls[$i].core_unchanged-isnot[bool] -or -not$prior.positive_controls[$i].core_unchanged){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_POSITIVE_CONTROL_INVALID'}}
        Assert-ReleaseInputs;$control=Open-ReleaseConnection 'master'
        if($prior.owner-cnotmatch'^[a-f0-9]{32}$' -or $prior.databases[0].name-cne('Toolbelt_Release_'+$prior.owner+'_u') -or $prior.databases[0].state-cne'DROPPED'){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_DATABASE_OWNER'}
        foreach($database in $prior.databases){$found=@(Sql $control 'SELECT DB_ID(@Name) Id;' @{ '@Name'=$database.name } -Rows);if($found.Count-ne1 -or $null-ne$found[0].Id -and $found[0].Id-isnot[DBNull]){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_DATABASE_PRESENT'}}
        if(@($prior.trust).Count-ne$script:runset.artifacts.Count){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_TRUST_SHAPE'}
        foreach($artifact in $script:runset.artifacts){
            $trust=@($prior.trust|Where-Object{$_.hash-ceq$artifact.sha512})
            if($trust.Count-ne1 -or $trust[0].preexisting-isnot[bool]){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_TRUST_SHAPE'}
            $actual=Get-ClrCallerTrust $control ([Convert]::FromHexString($trust[0].hash))
            if(($trust[0].preexisting -and ($null-eq$actual -or $actual.Fingerprint-cne$trust[0].fingerprint-or$trust[0].state-cne'PREEXISTING')) -or
               (-not$trust[0].preexisting -and ($null-ne$actual-or$trust[0].state-cne'REMOVED'))){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_TRUST_DRIFT'}
        }
        $configRows=@($prior.configuration.before|Where-Object{$_.Name-ceq'clr enabled'})
        if($prior.configuration.changed-isnot[bool] -or $prior.configuration.state-cnotin@('PREEXISTING','RESTORED') -or $configRows.Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_AUDIT_CONFIGURATION_SHAPE'}
        Assert-ClrCallerConfiguration $control $prior.configuration;Assert-ReleaseInputs
    }else{
        if(Test-Path -LiteralPath $script:journal){throw 'JSON_UNINSTALL_CONFIRMATION_ALREADY_ATTEMPTED'}
        $script:ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();trust=@();target=[ordered]@{platform='windows';version='2025';patch='CU8';compatibility_level=170};configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()};results=@();positive_controls=@();diagnostics=@();failure=$null}
        $ledger=$script:ledger
        Save-Journal;$control=Open-ReleaseConnection 'master'
        $actual=@(Sql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
        if($actual.Count-ne1 -or [int]$actual[0].Major-ne17 -or $actual[0].Platform-ine'windows' -or [int]$actual[0].Admin-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_ACTUAL_TARGET_MISMATCH'}
        $script:stage='CONFIGURATION';Assert-RunsetStable;Start-ClrCallerConfiguration $control
        $script:stage='TRUST'
        foreach($artifact in $script:runset.artifacts){$hash=[Convert]::FromHexString($artifact.sha512);$before=Get-ClrCallerTrust $control $hash;$entry=[ordered]@{hash=$artifact.sha512;preexisting=($null-ne$before);fingerprint=$null;state='PREEXISTING';description=$null};if($before){$entry.fingerprint=$before.Fingerprint};$script:ledger.trust+=@($entry);Save-Journal;if(-not$before){Assert-ClrCallerTrustCleanupScope $control $hash;$entry.state='ADDING';$entry.description='Contoso JSON Schema Uninstall AppLock '+$script:ledger.owner;Save-Journal;Assert-RunsetStable;Sql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{ '@Hash'=$hash;'@Description'=$entry.description };$after=Get-ClrCallerTrust $control $hash;if($null-eq$after-or$after.description-cne$entry.description){throw 'JSON_UNINSTALL_CONFIRMATION_TRUST_OWNERSHIP_UNKNOWN'};$entry.fingerprint=$after.Fingerprint;$entry.state='OWNED';Save-Journal}}
        $name='Toolbelt_Release_'+$script:ledger.owner+'_u';$entry=[ordered]@{name=$name;suffix='u';id=$null;created=$null;state='CREATING'};$script:ledger.databases+=@($entry);Save-Journal
        Sql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Synthetic collision.',1; CREATE DATABASE [$name] COLLATE Latin1_General_100_BIN2;"
        $identity=@(Sql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{ '@Name'=$name } -Rows);if($identity.Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_DATABASE_IDENTITY'};$entry.id=[int]$identity[0].Id;$entry.created=[string]$identity[0].Created;$entry.state='CREATED';Save-Journal
        $db=Open-ReleaseConnection $name;Sql $db 'DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Test.Release.Owner'',@value=@O;' @{ '@Owner'=$script:ledger.owner };$entry.state='OWNED';Save-Journal;Sql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=170;"
        $script:expectedOwnDbState=Get-ModuleState $db
        $script:stage='BASELINE';Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($script:runset.baseline.path,[Text.Encoding]::UTF8));Assert-CoreOnly $db;Assert-SchemaAbsent $db;Assert-CoreModeCentral $db
        $script:expectedOwnDbState=Get-ModuleState $db
        $script:expectedOwnCore=Read-CoreProjection $db
        Sql $db 'SET QUOTED_IDENTIFIER ON; SET NOCOUNT ON; SET XACT_ABORT ON; SET IMPLICIT_TRANSACTIONS OFF;'
        $profileRows=@(Sql $db 'SELECT CASE WHEN (@@OPTIONS&256)=256 THEN 1 ELSE 0 END QuotedIdentifier,CASE WHEN (@@OPTIONS&512)=512 THEN 1 ELSE 0 END NoCount,CASE WHEN (@@OPTIONS&16384)=16384 THEN 1 ELSE 0 END XactAbort,CASE WHEN (@@OPTIONS&2)=2 THEN 1 ELSE 0 END ImplicitTransactions,@@OPTIONS Options,@@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows)
        $profileDiagnostic=[ordered]@{stage='SESSION_PROFILE';row_count=$profileRows.Count;quoted_identifier=$null;nocount=$null;xact_abort=$null;implicit_transactions=$null;options=$null;transaction_count=$null;xact_state=$null}
        if($profileRows.Count-eq1){
            foreach($pair in @(@('quoted_identifier','QuotedIdentifier'),@('nocount','NoCount'),@('xact_abort','XactAbort'),@('implicit_transactions','ImplicitTransactions'),@('options','Options'),@('transaction_count','TranCount'),@('xact_state','XactState'))){
                $value=$profileRows[0].PSObject.Properties[$pair[1]].Value
                if($null-ne$value -and $value-isnot[DBNull]){$profileDiagnostic[$pair[0]]=[Convert]::ToString($value,[Globalization.CultureInfo]::InvariantCulture)}
            }
        }
        $script:ledger.diagnostics+=@($profileDiagnostic);Save-Journal
        if($profileRows.Count-ne1 -or [int]$profileRows[0].QuotedIdentifier-ne1 -or [int]$profileRows[0].NoCount-ne1 -or [int]$profileRows[0].XactAbort-ne1 -or [int]$profileRows[0].ImplicitTransactions-ne0 -or [int]$profileRows[0].TranCount-ne0 -or [int]$profileRows[0].XactState-ne0){throw 'JSON_UNINSTALL_CONFIRMATION_SESSION_PROFILE_INVALID'}
        $initialOptions=[int]$profileRows[0].Options
        $coreBefore=Read-CoreProjection $db
        $script:expectedOwnDbState=Get-ModuleState $db;$script:expectedOwnCore=$coreBefore
        Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($script:runset.schema_deploy.path,[Text.Encoding]::UTF8));Assert-SchemaInstalled $db
        Assert-CoreModeCentral $db
        $script:expectedOwnDbState=Get-ModuleState $db
        if((Read-CoreProjection $db)-cne$coreBefore){throw 'JSON_UNINSTALL_CONFIRMATION_CORE_CHANGED_ON_INSTALL'}
        for($i=0;$i-lt2;$i++){
            $case=$script:runset.scope.cases[$i];$script:stage='CASE_'+$i
            $installed=Get-ModuleState $db;$spid=[int](Read-Scalar $db 'SELECT @@SPID AS ScalarValue;');$baseline=Get-ContenderStateSamples $control $db $spid
            if($installed-cne$script:expectedOwnDbState -or (Read-CoreProjection $db)-cne$script:expectedOwnCore){throw 'JSON_UNINSTALL_CONFIRMATION_PRECASE_STATE_DRIFT'}
            if(-not(Test-ContenderStateIdle $baseline $db.State $spid)){throw 'JSON_UNINSTALL_CONFIRMATION_SESSION_NOT_IDLE'}
            Assert-ExactBlock $db $control $case $installed $spid $baseline
        }
        if([int](Read-Scalar $db 'SELECT @@OPTIONS AS ScalarValue;')-ne$initialOptions){throw 'JSON_UNINSTALL_CONFIRMATION_OPTIONS_CHANGED_BEFORE_POSITIVE'}
        $namespaceBefore=Read-JsonSchemaNamespace $db
        $script:stage='POSITIVE';Assert-PositiveUninstall $db $control $coreBefore $namespaceBefore
        $script:expectedOwnDbState=Get-ModuleState $db
        $script:ledger.positive_controls+=@([ordered]@{ordinal=0;confirmation='1';uninstall_succeeded=$true;module_absent=$true;namespace_retained=$true;core_unchanged=$true});Save-Journal
        $script:ledger.state='COMPLETE';Save-Journal;Assert-ReleaseInputs
    }
}catch{$script:failure=$_.Exception;if($ValidateOnly){throw};if($script:ledger -and -not$AuditOnly){$script:ledger.failure=[ordered]@{stage=$script:stage;privateDiagnostic=$script:failure.Message};Save-Journal}}
finally{
    foreach($connection in $script:connections){try{$connection.Dispose()}catch{}};[Data.SqlClient.SqlConnection]::ClearAllPools()
    if($script:ledger -and -not$AuditOnly){try{$script:cleanup=$true;$control=Open-ReleaseConnection 'master';foreach($database in $script:ledger.databases){
      Assert-RunsetStable
      if($null-eq$script:expectedOwnDbState -or $null-eq$script:expectedOwnCore){throw 'JSON_UNINSTALL_CONFIRMATION_OWNED_DATABASE_STATE_UNVERIFIED'}
      $verify=Open-ReleaseConnection $database.name
      try{if((Get-ModuleState $verify)-cne$script:expectedOwnDbState -or (Read-CoreProjection $verify)-cne$script:expectedOwnCore){throw 'JSON_UNINSTALL_CONFIRMATION_OWNED_DATABASE_STATE_DRIFT'}}finally{$verify.Dispose()}
      Assert-ReleaseOwnIdentity $control $database;$database.state='DROPPED';Save-Journal
    };foreach($trust in $script:ledger.trust){$hash=[Convert]::FromHexString($trust.hash);$actual=Get-ClrCallerTrust $control $hash;if($trust.preexisting){if($null-eq$actual-or$actual.Fingerprint-cne$trust.fingerprint){throw 'JSON_UNINSTALL_CONFIRMATION_PREEXISTING_TRUST_DRIFT'};continue};if($trust.state-cne'OWNED'-or$null-eq$actual-or$actual.Fingerprint-cne$trust.fingerprint-or$actual.description-cne$trust.description){throw 'JSON_UNINSTALL_CONFIRMATION_TRUST_CLEANUP_IDENTITY'};Assert-ClrCallerTrustCleanupScope $control $hash;Assert-RunsetStable;Sql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{ '@Hash'=$hash };if($null-ne(Get-ClrCallerTrust $control $hash)){throw 'JSON_UNINSTALL_CONFIRMATION_TRUST_NOT_REMOVED'};$trust.state='REMOVED';Save-Journal};Assert-RunsetStable;Restore-ClrCallerConfiguration $control;$script:ledger.state=if($script:failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-Journal}catch{$script:ledger.state='CLEANUP_BLOCKED';$script:ledger.privateCleanupDiagnostic=$_.Exception.Message;Save-Journal;$script:failure=$_.Exception}finally{if($control){$control.Dispose()}}}
}
if($script:failure){Write-Output 'FAIL JSON_SCHEMA_UNINSTALL_CONFIRMATION; inspect private journal';exit 1}
if($AuditOnly){Write-Output 'PASS JSON_SCHEMA_UNINSTALL_CONFIRMATION independent cleanup audit'}else{Write-Output 'PASS JSON_SCHEMA_UNINSTALL_CONFIRMATION two uninstall conflicts and positive controls; audit required'}
