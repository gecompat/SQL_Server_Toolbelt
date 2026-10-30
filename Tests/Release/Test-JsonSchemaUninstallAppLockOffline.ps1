[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$driver=Join-Path $PSScriptRoot 'Invoke-JsonSchemaUninstallAppLockLab.ps1'
$preparer=Join-Path $PSScriptRoot 'Prepare-JsonSchemaUninstallAppLockRunset.ps1'
$source=Join-Path $repo 'Modules/toolbelt.json.schema/Deployment/Uninstall.sql'
foreach($path in @($driver,$preparer,$source)){
    $errors=$null
    if($path.EndsWith('.ps1')){[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errors)|Out-Null
        if($errors.Count){throw 'JSON_UNINSTALL_APPLOCK_OFFLINE_PARSE'}
    }
}
$astErrors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($driver,[ref]$null,[ref]$astErrors)
$shape=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Assert-UninstallCaseShape'},$true))
if($shape.Count-ne1){throw 'JSON_UNINSTALL_APPLOCK_OFFLINE_CASE_GUARD_MISSING'}
. ([scriptblock]::Create($shape[0].Extent.Text))
$valid=@(
    [pscustomobject]@{ordinal=0;resource='toolbelt.deploy.json.shared-core';expected_message='JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar.'},
    [pscustomobject]@{ordinal=1;resource='toolbelt.deploy.toolbelt.json.schema';expected_message='JSON Schema lifecycle: Modul-AppLock nicht verfügbar.'})
Assert-UninstallCaseShape $valid
foreach($bad in @(
    @($valid[1],$valid[0]),
    @($valid[0],[pscustomobject]@{ordinal=1;resource='toolbelt.deploy.other';expected_message='JSON Schema lifecycle: Modul-AppLock nicht verfügbar.'}),
    @($valid[0]))) {
    $rejected=$false
    try{Assert-UninstallCaseShape $bad}catch{$rejected=$_.Exception.Message -ceq 'JSON_UNINSTALL_APPLOCK_CASES_INVALID'}
    if(-not$rejected){throw 'JSON_UNINSTALL_APPLOCK_OFFLINE_NEGATIVE_CASE_ACCEPTED'}
}
$closure=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Assert-SchemaAssemblyClosure'},$true))
if($closure.Count-ne1){throw 'JSON_UNINSTALL_APPLOCK_OFFLINE_CLOSURE_GUARD_MISSING'}
. ([scriptblock]::Create($closure[0].Extent.Text))
$artifacts=@(
    [pscustomobject]@{module_id='toolbelt.json.core';sql_name='Toolbelt_JsonCore';sha512=('A'*128)},
    [pscustomobject]@{module_id='toolbelt.json.schema';sql_name='Toolbelt_JsonSchema';sha512=('B'*128)})
$assemblies=@(
    [pscustomobject]@{name='Toolbelt_JsonCore';permission_set_desc='SAFE_ACCESS';BinaryHash=('A'*128)},
    [pscustomobject]@{name='Toolbelt_JsonSchema';permission_set_desc='SAFE_ACCESS';BinaryHash=('B'*128)})
Assert-SchemaAssemblyClosure $assemblies $artifacts
foreach($badAssemblies in @(
    @($assemblies[0]),
    @($assemblies+@([pscustomobject]@{name='Other';permission_set_desc='SAFE_ACCESS';BinaryHash=('C'*128)})),
    @($assemblies[0],[pscustomobject]@{name='Toolbelt_JsonSchema';permission_set_desc='UNSAFE_ACCESS';BinaryHash=('B'*128)}))) {
    $rejected=$false
    try{Assert-SchemaAssemblyClosure $badAssemblies $artifacts}catch{$rejected=$_.Exception.Message -ceq 'JSON_UNINSTALL_APPLOCK_ASSEMBLY_CLOSURE_INVALID'}
    if(-not$rejected){throw 'JSON_UNINSTALL_APPLOCK_OFFLINE_BAD_CLOSURE_ACCEPTED'}
}
$driverText=[IO.File]::ReadAllText($driver)
$deployLines=@([regex]::Matches($driverText,'(?m)^.*Invoke-ReleaseBatches \$db .*schema_deploy\.path.*$'))
if($deployLines.Count-ne2 -or @($deployLines|Where-Object{$_.Value-notmatch'Assert-SchemaInstalled'-or$_.Value-match'Assert-CoreOnly'}).Count-ne0 -or
   [regex]::Matches($driverText,'(?m)Assert-CoreOnly \$db').Count-ne1){throw 'JSON_UNINSTALL_APPLOCK_OFFLINE_LIFECYCLE_GUARD_ORDER'}
$sql=[IO.File]::ReadAllText($source,[Text.Encoding]::UTF8)
foreach($required in @(
    'toolbelt.deploy.json.shared-core','toolbelt.deploy.toolbelt.json.schema',
    'JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar.','JSON Schema lifecycle: Modul-AppLock nicht verfügbar.')){
    if(-not$sql.Contains($required,[StringComparison]::Ordinal)){throw 'JSON_UNINSTALL_APPLOCK_OFFLINE_SQL_CONTRACT_DRIFT'}
}
foreach($required in @('Read-CoreProjection','CoreAssembly','RoleMemberships','Principals','Assert-SchemaInstalled','Assert-SchemaModuleAbsent','Get-ContenderStateSamples','Test-ExternalSessionIdle','Assert-ReleaseOwnIdentity','dp.class=3 AND dp.major_id=SCHEMA_ID')){
    if(-not$driverText.Contains($required,[StringComparison]::Ordinal)){throw 'JSON_UNINSTALL_APPLOCK_OFFLINE_DRIVER_GUARD_MISSING'}
}
$calls=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -ceq 'Invoke-JsonSchemaAppLockLab.ps1'},$true))
if($calls.Count){throw 'JSON_UNINSTALL_APPLOCK_OFFLINE_NO_DRIVER_REENTRY'}
Write-Output 'PASS JSON_SCHEMA_UNINSTALL_APPLOCK offline syntax, ordered-case guard, source lock contract, and lifecycle safeguards; no SQL executed'
