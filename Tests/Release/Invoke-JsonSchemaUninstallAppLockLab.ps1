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
$control=$null;$db=$null

$astErrors=$null
$apiAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$astErrors)
if($astErrors.Count){throw 'JSON_UNINSTALL_APPLOCK_HELPER_PARSE'}
$nodes=@($apiAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($nodes.Count-ne1){throw 'JSON_UNINSTALL_APPLOCK_HELPER_DISCOVERY'}
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
if($sourceErrors.Count){throw 'JSON_UNINSTALL_APPLOCK_SOURCE_PARSE'}
$reuse=@('Sql','Invoke-ReleaseBatches','Read-Scalar','Get-ModuleState','Assert-CoreOnly','Assert-SchemaAbsent','Assert-SchemaModuleAbsent',
    'Assert-HolderLock','New-ContenderStateDiagnostic','New-ContenderStateSummary','Get-ExternalSessionState',
    'Get-ContenderStateSamples','Test-ExternalSessionIdle','Test-ContenderStateIdle','Assert-ExternalHolderGranted','Acquire-HolderLock')
foreach($name in $reuse){
    $found=@($sourceAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
    if($found.Count-ne1){throw 'JSON_UNINSTALL_APPLOCK_REUSE_FUNCTION'}
    . ([scriptblock]::Create($found[0].Extent.Text))
}

function Assert-Runset {
    if(-not(Get-Command Invoke-ReleaseSqlCore -CommandType Function -ErrorAction SilentlyContinue)){throw 'JSON_UNINSTALL_APPLOCK_SQL_HELPER_MISSING'}
    $script:RunsetPath=Assert-ReleasePrivatePath $script:RunsetPath
    if((Get-FileHash -LiteralPath $script:RunsetPath -Algorithm SHA256).Hash -cne $script:ExpectedRunsetSHA256.ToUpperInvariant()){throw 'JSON_UNINSTALL_APPLOCK_RUNSET_PIN_DRIFT'}
    $script:runset=Get-Content -LiteralPath $script:RunsetPath -Raw -Encoding UTF8|ConvertFrom-Json
    if($script:runset.schema_version -cne 'json-schema-uninstall-applock-probe/v1' -or $script:runset.operation -cne 'schema-uninstall-app-lock' -or
       $script:runset.target.platform -cne 'windows' -or $script:runset.target.version -cne '2025' -or $script:runset.target.patch -cne 'CU8' -or
       ($script:runset.target.compatibility_level -isnot [int] -and $script:runset.target.compatibility_level -isnot [long]) -or $script:runset.target.compatibility_level -ne 170 -or
       $script:runset.target.test_purpose -cne 'Functional' -or $script:runset.scope.deployment_mode -cne 'local' -or
       (($script:runset.scope.expected_error -isnot [int] -and $script:runset.scope.expected_error -isnot [long]) -or $script:runset.scope.expected_error -ne 55637) -or
       (($script:runset.scope.expected_state -isnot [int] -and $script:runset.scope.expected_state -isnot [long]) -or $script:runset.scope.expected_state -ne 1)){throw 'JSON_UNINSTALL_APPLOCK_RUNSET_INVALID'}
    Assert-UninstallCaseShape @($script:runset.scope.cases)
    $artifactModules=@($script:runset.artifacts.module_id|Sort-Object -CaseSensitive)
    if($script:runset.artifacts.Count-ne2 -or ($artifactModules-join'|')-cne'toolbelt.json.core|toolbelt.json.schema' -or
       $script:runset.baseline.modules.Count-ne2 -or
       $script:runset.baseline.modules[0]-cne'toolbelt.core.result-table' -or $script:runset.baseline.modules[1]-cne'toolbelt.json.core' -or
       $script:runset.schema_deploy.module-cne'toolbelt.json.schema' -or $script:runset.schema_uninstall.module-cne'toolbelt.json.schema'){
       throw 'JSON_UNINSTALL_APPLOCK_ARTIFACT_SCOPE'}
    $required=@($PSCommandPath,(Join-Path $script:repo 'Tests/Release/Prepare-JsonSchemaUninstallAppLockRunset.ps1'),
      (Join-Path $script:repo 'Tests/Release/Test-JsonSchemaUninstallAppLockOffline.ps1'),$sourcePath,
      (Join-Path $script:repo 'Tests/Release/Invoke-StablePackageLab.ps1'),(Join-Path $script:repo 'Tests/Release/ClrCaller.Environment.ps1'),
      (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $script:repo 'Tests/CI/LabQualifiedContract.ps1'))
    foreach($path in $required){if(@($script:runset.pins|Where-Object{$_.path-ceq$path}).Count-ne1){throw 'JSON_UNINSTALL_APPLOCK_REQUIRED_PIN_MISSING'}}
    $pinSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($pin in $script:runset.pins){
       if(-not$pinSet.Add([IO.Path]::GetFullPath([string]$pin.path))){throw 'JSON_UNINSTALL_APPLOCK_DUPLICATE_PIN'}
       Assert-ReleasePin $pin.path $pin.sha256
    }
    Assert-ReleaseInputs
    if((Get-FileHash -LiteralPath $script:runset.base_runset.path -Algorithm SHA256).Hash -cne $script:runset.base_runset.sha256.ToUpperInvariant()){
        throw 'JSON_UNINSTALL_APPLOCK_BASE_RUNSET_DRIFT'
    }
    foreach($artifact in $script:runset.artifacts){
        if($artifact.module_id-cnotin@('toolbelt.json.core','toolbelt.json.schema') -or
           (Get-FileHash -LiteralPath $artifact.path -Algorithm SHA256).Hash.ToLowerInvariant()-cne$artifact.sha256 -or
           (Get-FileHash -LiteralPath $artifact.path -Algorithm SHA512).Hash.ToLowerInvariant()-cne$artifact.sha512){throw 'JSON_UNINSTALL_APPLOCK_ARTIFACT_DRIFT'}
    }
    foreach($export in @($script:runset.baseline,$script:runset.schema_deploy,$script:runset.schema_uninstall)){
       if((Get-FileHash -LiteralPath $export.path -Algorithm SHA256).Hash.ToLowerInvariant()-cne$export.sha256){throw 'JSON_UNINSTALL_APPLOCK_EXPORT_DRIFT'}
    }
}
function Assert-UninstallCaseShape($Cases){
    $expected=@(
      [ordered]@{ordinal=0;resource='toolbelt.deploy.json.shared-core';expected_message='JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar.'},
      [ordered]@{ordinal=1;resource='toolbelt.deploy.toolbelt.json.schema';expected_message='JSON Schema lifecycle: Modul-AppLock nicht verfügbar.'})
    if(@($Cases).Count-ne2){throw 'JSON_UNINSTALL_APPLOCK_CASES_INVALID'}
    for($i=0;$i-lt2;$i++){
        $actual=$Cases[$i]
        if(($actual.ordinal-isnot[int]-and$actual.ordinal-isnot[long]) -or $actual.ordinal-ne$expected[$i].ordinal -or
           $actual.resource-cne$expected[$i].resource -or $actual.expected_message-cne$expected[$i].expected_message){throw 'JSON_UNINSTALL_APPLOCK_CASES_INVALID'}
    }
}
function Assert-RunsetStable {
    if((Get-FileHash -LiteralPath $script:RunsetPath -Algorithm SHA256).Hash -cne $script:ExpectedRunsetSHA256.ToUpperInvariant()){throw 'JSON_UNINSTALL_APPLOCK_RUNSET_PIN_DRIFT'}
    Assert-ReleaseInputs
}
function Invoke-ReleaseSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    Assert-RunsetStable
    Invoke-ReleaseSqlCore $Connection $Sql $Parameters -Rows:$Rows
}
function Get-LabSelectorTarget {
    $lab=Resolve-LabContract -TestPurpose Functional
    if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash.ToLowerInvariant()-cne$script:runset.lab.contract_sha256 -or
       (Get-FileHash -LiteralPath $lab.SchemaPath -Algorithm SHA256).Hash.ToLowerInvariant()-cne$script:runset.lab.schema_sha256){throw 'JSON_UNINSTALL_APPLOCK_LAB_DRIFT'}
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform='windows';Version='2025';Patch='CU8'}))
    if($targets.Count-ne1 -or -not(Test-LabTargetReady -Contract $lab.Contract -Entry $targets[0])){throw 'JSON_UNINSTALL_APPLOCK_EXACT_READY_TARGET_REQUIRED'}
    $script:target=$targets[0]
    if($script:target.encrypt-isnot[bool] -or -not$script:target.encrypt -or $script:target.trustServerCertificate-isnot[bool]){throw 'JSON_UNINSTALL_APPLOCK_TRANSPORT_INVALID'}
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
    $rows=@(Sql $Connection $query -Rows);if($rows.Count-ne1){throw 'JSON_UNINSTALL_APPLOCK_CORE_SNAPSHOT_SHAPE'}
    return ($rows[0]|ConvertTo-Json -Depth 5 -Compress)
}
function Assert-ExactBlock($Connection,$Observer,$Case,$Before,[int]$Spid,$Baseline){
    $caught=$null
    try{Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText($script:runset.schema_uninstall.path,[Text.Encoding]::UTF8))}
    catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}
    if($caught-isnot[Data.SqlClient.SqlException] -or $caught.Number-ne55637 -or $caught.State-ne1 -or
       -not$caught.Message.Contains([string]$Case.expected_message,[StringComparison]::Ordinal)){throw 'JSON_UNINSTALL_APPLOCK_EXPECTED_ERROR_MISMATCH'}
    $samples=Get-ContenderStateSamples $Observer $Connection $Spid
    $diag=New-ContenderStateDiagnostic $samples $Connection.State $Spid $caught $Baseline
    $same=(Test-ContenderStateIdle $samples $Connection.State $Spid) -and $diag.session_same -and $diag.row_count-eq1
    if(-not$same -or (Get-ModuleState $Connection)-cne$Before){$script:ledger.diagnostics+=@($diag);Save-Journal;throw 'JSON_UNINSTALL_APPLOCK_BLOCK_CHANGED_STATE'}
    $script:ledger.results+=@([ordered]@{ordinal=[int]$Case.ordinal;resource=[string]$Case.resource;blocked=$true;exact_error=$true;state_unchanged=$true;contender_idle=$true})
    Save-Journal
}
function Assert-PositiveUninstall($Connection,$BeforeCore){
    Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText($script:runset.schema_uninstall.path,[Text.Encoding]::UTF8))
    Assert-SchemaModuleAbsent $Connection
    Assert-CoreOnly $Connection
    if((Read-CoreProjection $Connection)-cne$BeforeCore){throw 'JSON_UNINSTALL_APPLOCK_CORE_CHANGED'}
}
function Assert-SchemaAssemblyClosure($Rows,$Artifacts){
    $expected=@($Artifacts|Sort-Object module_id -CaseSensitive)
    $actual=@($Rows|Sort-Object name -CaseSensitive)
    if($expected.Count-ne2 -or $actual.Count-ne2){throw 'JSON_UNINSTALL_APPLOCK_ASSEMBLY_CLOSURE_INVALID'}
    $wantedNames=@('Toolbelt_JsonCore','Toolbelt_JsonSchema')
    if(($actual.name -join '|')-cne($wantedNames -join '|')){throw 'JSON_UNINSTALL_APPLOCK_ASSEMBLY_CLOSURE_INVALID'}
    foreach($artifact in $expected){
        $name=[string]$artifact.sql_name
        $match=@($actual|Where-Object{$_.name-ceq$name})
        if($match.Count-ne1 -or $match[0].permission_set_desc-cne'SAFE_ACCESS' -or
           [string]$match[0].BinaryHash-cne$artifact.sha512.ToUpperInvariant()){
            throw 'JSON_UNINSTALL_APPLOCK_ASSEMBLY_CLOSURE_INVALID'
        }
    }
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
SELECT o.name,o.type,am.assembly_id FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
LEFT JOIN sys.assembly_modules am ON am.object_id=o.object_id
WHERE s.name=N'toolbelt_json' AND o.name IN(N'USP_ValidateJsonSchema',N'FT_ValidateJsonSchemaInternal') ORDER BY o.name;
'@ -Rows)
    $version=@($metadata|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.json.schema.Version'})
    $mode=@($metadata|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.json.schema.DeploymentMode'})
    Assert-SchemaAssemblyClosure $rows $script:runset.artifacts
    $schemaAssembly=@($rows|Where-Object{$_.name-ceq'Toolbelt_JsonSchema'})
    if($schema.Count-ne1 -or
       [int]$schema[0].principal_id-ne1 -or $version.Count-ne1 -or $version[0].Value-cne'1.0.1' -or
       $mode.Count-ne1 -or $mode[0].Value-cne'local' -or $slots.Count-ne2 -or
       @($slots|Where-Object{$_.assembly_id-ne$schemaAssembly[0].assembly_id}).Count-ne0){
        throw 'JSON_UNINSTALL_APPLOCK_SCHEMA_INSTALL_INVALID'
    }
}

try{
    Assert-Runset;Get-LabSelectorTarget
    if($ValidateOnly){Assert-RunsetStable;Write-Output 'PASS JSON_SCHEMA_UNINSTALL_APPLOCK runset validated; no SQL executed';return}
    $script:journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $script:RunsetPath) 'case.json')
    if($AuditOnly){
        $prior=Get-Content -LiteralPath $script:journal -Raw -Encoding UTF8|ConvertFrom-Json
        $priorCount=@($prior.results).Count
        if(($prior.state-cne'COMPLETE' -and $prior.state-cne'FAILED_CLEANED') -or
           ($prior.state-ceq'COMPLETE' -and $priorCount-ne2) -or ($prior.state-ceq'FAILED_CLEANED' -and $priorCount-gt2) -or @($prior.databases).Count-ne1){throw 'JSON_UNINSTALL_APPLOCK_AUDIT_JOURNAL_INVALID'}
        $expectedResources=@('toolbelt.deploy.json.shared-core','toolbelt.deploy.toolbelt.json.schema')
        for($i=0;$i-lt$priorCount;$i++){if(($prior.results[$i].ordinal-isnot[int] -and $prior.results[$i].ordinal-isnot[long]) -or $prior.results[$i].ordinal-ne$i -or
            $prior.results[$i].resource-cne$expectedResources[$i] -or
            $prior.results[$i].blocked-isnot[bool] -or -not$prior.results[$i].blocked -or $prior.results[$i].exact_error-isnot[bool] -or -not$prior.results[$i].exact_error -or
            $prior.results[$i].state_unchanged-isnot[bool] -or -not$prior.results[$i].state_unchanged -or $prior.results[$i].contender_idle-isnot[bool] -or -not$prior.results[$i].contender_idle){throw 'JSON_UNINSTALL_APPLOCK_AUDIT_RESULT_INVALID'}}
        $positiveCount=@($prior.positive_controls).Count
        if(($prior.state-ceq'COMPLETE' -and $positiveCount-ne2) -or $positiveCount-gt$priorCount){throw 'JSON_UNINSTALL_APPLOCK_AUDIT_POSITIVE_CONTROL_INVALID'}
        for($i=0;$i-lt$positiveCount;$i++){if($prior.positive_controls[$i].ordinal-ne$i -or $prior.positive_controls[$i].uninstall_after_release-isnot[bool] -or -not$prior.positive_controls[$i].uninstall_after_release -or $prior.positive_controls[$i].module_absent-isnot[bool] -or -not$prior.positive_controls[$i].module_absent -or $prior.positive_controls[$i].core_unchanged-isnot[bool] -or -not$prior.positive_controls[$i].core_unchanged){throw 'JSON_UNINSTALL_APPLOCK_AUDIT_POSITIVE_CONTROL_INVALID'}}
        Assert-ReleaseInputs;$control=Open-ReleaseConnection 'master'
        if($prior.owner-cnotmatch'^[a-f0-9]{32}$' -or $prior.databases[0].name-cne('Toolbelt_Release_'+$prior.owner+'_u') -or $prior.databases[0].state-cne'DROPPED'){throw 'JSON_UNINSTALL_APPLOCK_AUDIT_DATABASE_OWNER'}
        foreach($database in $prior.databases){$found=@(Sql $control 'SELECT DB_ID(@Name) Id;' @{ '@Name'=$database.name } -Rows);if($found.Count-ne1 -or $null-ne$found[0].Id -and $found[0].Id-isnot[DBNull]){throw 'JSON_UNINSTALL_APPLOCK_AUDIT_DATABASE_PRESENT'}}
        if(@($prior.trust).Count-ne$script:runset.artifacts.Count){throw 'JSON_UNINSTALL_APPLOCK_AUDIT_TRUST_SHAPE'}
        foreach($artifact in $script:runset.artifacts){
            $trust=@($prior.trust|Where-Object{$_.hash-ceq$artifact.sha512})
            if($trust.Count-ne1 -or $trust[0].preexisting-isnot[bool]){throw 'JSON_UNINSTALL_APPLOCK_AUDIT_TRUST_SHAPE'}
            $actual=Get-ClrCallerTrust $control ([Convert]::FromHexString($trust[0].hash))
            if(($trust[0].preexisting -and ($null-eq$actual -or $actual.Fingerprint-cne$trust[0].fingerprint-or$trust[0].state-cne'PREEXISTING')) -or
               (-not$trust[0].preexisting -and ($null-ne$actual-or$trust[0].state-cne'REMOVED'))){throw 'JSON_UNINSTALL_APPLOCK_AUDIT_TRUST_DRIFT'}
        }
        $configRows=@($prior.configuration.before|Where-Object{$_.Name-ceq'clr enabled'})
        if($prior.configuration.changed-isnot[bool] -or $prior.configuration.state-cnotin@('PREEXISTING','RESTORED') -or $configRows.Count-ne1){throw 'JSON_UNINSTALL_APPLOCK_AUDIT_CONFIGURATION_SHAPE'}
        Assert-ClrCallerConfiguration $control $prior.configuration;Assert-ReleaseInputs
    }else{
        if(Test-Path -LiteralPath $script:journal){throw 'JSON_UNINSTALL_APPLOCK_ALREADY_ATTEMPTED'}
        $script:ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();trust=@();target=[ordered]@{platform='windows';version='2025';patch='CU8';compatibility_level=170};configuration=[ordered]@{changed=$false;state='UNPREPARED';before=@()};results=@();positive_controls=@();diagnostics=@();failure=$null}
        $ledger=$script:ledger
        Save-Journal;$control=Open-ReleaseConnection 'master'
        $actual=@(Sql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
        if($actual.Count-ne1 -or [int]$actual[0].Major-ne17 -or $actual[0].Platform-ine'windows' -or [int]$actual[0].Admin-ne1){throw 'JSON_UNINSTALL_APPLOCK_ACTUAL_TARGET_MISMATCH'}
        $script:stage='CONFIGURATION';Assert-RunsetStable;Start-ClrCallerConfiguration $control
        $script:stage='TRUST'
        foreach($artifact in $script:runset.artifacts){$hash=[Convert]::FromHexString($artifact.sha512);$before=Get-ClrCallerTrust $control $hash;$entry=[ordered]@{hash=$artifact.sha512;preexisting=($null-ne$before);fingerprint=$null;state='PREEXISTING';description=$null};if($before){$entry.fingerprint=$before.Fingerprint};$script:ledger.trust+=@($entry);Save-Journal;if(-not$before){Assert-ClrCallerTrustCleanupScope $control $hash;$entry.state='ADDING';$entry.description='Contoso JSON Schema Uninstall AppLock '+$script:ledger.owner;Save-Journal;Assert-RunsetStable;Sql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{ '@Hash'=$hash;'@Description'=$entry.description };$after=Get-ClrCallerTrust $control $hash;if($null-eq$after-or$after.description-cne$entry.description){throw 'JSON_UNINSTALL_APPLOCK_TRUST_OWNERSHIP_UNKNOWN'};$entry.fingerprint=$after.Fingerprint;$entry.state='OWNED';Save-Journal}}
        $name='Toolbelt_Release_'+$script:ledger.owner+'_u';$entry=[ordered]@{name=$name;suffix='u';id=$null;created=$null;state='CREATING'};$script:ledger.databases+=@($entry);Save-Journal
        Sql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Synthetic collision.',1; CREATE DATABASE [$name] COLLATE Latin1_General_100_BIN2;"
        $identity=@(Sql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{ '@Name'=$name } -Rows);if($identity.Count-ne1){throw 'JSON_UNINSTALL_APPLOCK_DATABASE_IDENTITY'};$entry.id=[int]$identity[0].Id;$entry.created=[string]$identity[0].Created;$entry.state='CREATED';Save-Journal
        $db=Open-ReleaseConnection $name;Sql $db 'DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Test.Release.Owner'',@value=@O;' @{ '@Owner'=$script:ledger.owner };$entry.state='OWNED';Save-Journal;Sql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=170;"
        $script:stage='BASELINE';Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($script:runset.baseline.path,[Text.Encoding]::UTF8));Assert-CoreOnly $db;Assert-SchemaAbsent $db
        $coreBefore=Read-CoreProjection $db
        Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($script:runset.schema_deploy.path,[Text.Encoding]::UTF8));Assert-SchemaInstalled $db
        if((Read-CoreProjection $db)-cne$coreBefore){throw 'JSON_UNINSTALL_APPLOCK_CORE_CHANGED_ON_INSTALL'}
        for($i=0;$i-lt2;$i++){
            if($i-gt0){Assert-SchemaModuleAbsent $db;Invoke-ReleaseBatches $db ([IO.File]::ReadAllText($script:runset.schema_deploy.path,[Text.Encoding]::UTF8));Assert-SchemaInstalled $db;if((Read-CoreProjection $db)-cne$coreBefore){throw 'JSON_UNINSTALL_APPLOCK_CORE_CHANGED_ON_REINSTALL'}}
            $case=$script:runset.scope.cases[$i];$script:stage='CASE_'+$i
            $installed=Get-ModuleState $db;$holder=Open-ReleaseConnection $name;$holderSpid=Acquire-HolderLock $holder $case.resource;Assert-ExternalHolderGranted $control $holderSpid
            $contender=Open-ReleaseConnection $name;$spid=[int](Read-Scalar $contender 'SELECT @@SPID AS ScalarValue;');$baseline=Get-ContenderStateSamples $control $contender $spid
            if(-not(Test-ContenderStateIdle $baseline $contender.State $spid)){throw 'JSON_UNINSTALL_APPLOCK_CONTENDER_BASELINE_NOT_IDLE'}
            Assert-ExactBlock $contender $control $case $installed $spid $baseline;Assert-HolderLock $holder $holderSpid
            $release=@(Sql $holder 'ROLLBACK TRANSACTION; SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;' -Rows);if($release.Count-ne1 -or [int]$release[0].TranCount-ne0 -or [int]$release[0].XactState-ne0){throw 'JSON_UNINSTALL_APPLOCK_HOLDER_RELEASE_FAILED'}
            $external=@(Get-ExternalSessionState $control $holderSpid);if(-not(Test-ExternalSessionIdle $external $holderSpid)){throw 'JSON_UNINSTALL_APPLOCK_HOLDER_REMAINS'}
            $holder.Dispose();$contender.Dispose();$script:stage='POSITIVE_'+$i;Assert-PositiveUninstall $db $coreBefore
            $script:ledger.positive_controls+=@([ordered]@{ordinal=$i;uninstall_after_release=$true;module_absent=$true;core_unchanged=$true});Save-Journal
        }
        $script:ledger.state='COMPLETE';Save-Journal;Assert-ReleaseInputs
    }
}catch{$script:failure=$_.Exception;if($ValidateOnly){throw};if($script:ledger -and -not$AuditOnly){$script:ledger.failure=[ordered]@{stage=$script:stage;privateDiagnostic=$script:failure.Message};Save-Journal}}
finally{
    foreach($connection in $script:connections){try{$connection.Dispose()}catch{}};[Data.SqlClient.SqlConnection]::ClearAllPools()
    if($script:ledger -and -not$AuditOnly){try{$script:cleanup=$true;$control=Open-ReleaseConnection 'master';foreach($database in $script:ledger.databases){Assert-RunsetStable;Assert-ReleaseOwnIdentity $control $database;$database.state='DROPPED';Save-Journal};foreach($trust in $script:ledger.trust){$hash=[Convert]::FromHexString($trust.hash);$actual=Get-ClrCallerTrust $control $hash;if($trust.preexisting){if($null-eq$actual-or$actual.Fingerprint-cne$trust.fingerprint){throw 'JSON_UNINSTALL_APPLOCK_PREEXISTING_TRUST_DRIFT'};continue};if($trust.state-cne'OWNED'-or$null-eq$actual-or$actual.Fingerprint-cne$trust.fingerprint-or$actual.description-cne$trust.description){throw 'JSON_UNINSTALL_APPLOCK_TRUST_CLEANUP_IDENTITY'};Assert-ClrCallerTrustCleanupScope $control $hash;Assert-RunsetStable;Sql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{ '@Hash'=$hash };if($null-ne(Get-ClrCallerTrust $control $hash)){throw 'JSON_UNINSTALL_APPLOCK_TRUST_NOT_REMOVED'};$trust.state='REMOVED';Save-Journal};Assert-RunsetStable;Restore-ClrCallerConfiguration $control;$script:ledger.state=if($script:failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-Journal}catch{$script:ledger.state='CLEANUP_BLOCKED';$script:ledger.privateCleanupDiagnostic=$_.Exception.Message;Save-Journal;$script:failure=$_.Exception}finally{if($control){$control.Dispose()}}}
}
if($script:failure){Write-Output 'FAIL JSON_SCHEMA_UNINSTALL_APPLOCK; inspect private journal';exit 1}
if($AuditOnly){Write-Output 'PASS JSON_SCHEMA_UNINSTALL_APPLOCK independent cleanup audit'}else{Write-Output 'PASS JSON_SCHEMA_UNINSTALL_APPLOCK two uninstall conflicts and positive controls; audit required'}
