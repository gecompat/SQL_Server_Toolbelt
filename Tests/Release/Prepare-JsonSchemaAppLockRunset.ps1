[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$QualificationDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runtimePrefix = [IO.Path]::GetFullPath((Join-Path $repo '.runtime')) + [IO.Path]::DirectorySeparatorChar
function Resolve-PrivatePath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($runtimePrefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'JSON_APPLOCK_PRIVATE_PATH' }
    $parent = [IO.DirectoryInfo]::new($full)
    if (-not (Test-Path -LiteralPath $full -PathType Container)) { $parent = [IO.DirectoryInfo]::new([IO.Path]::GetDirectoryName($full)) }
    while ($parent -and $parent.FullName.Length -ge $runtimePrefix.TrimEnd('\','/').Length) {
        if (($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'JSON_APPLOCK_REPARSE_PATH' }
        $parent = $parent.Parent
    }
    return $full
}
function Assert-RegularFile([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item -or $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'JSON_APPLOCK_INPUT_NOT_REGULAR'
    }
}
function Get-Hash([string]$Path,[string]$Algorithm='SHA256') {
    return (Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash.ToLowerInvariant()
}
function Write-NewUtf8([string]$Path,[string]$Text) {
    $normalized = [regex]::Replace($Text,"`r`n|`r|`n","`n")
    $bytes = [Text.UTF8Encoding]::new($false,$true).GetBytes($normalized)
    $stream = [IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush() } finally { $stream.Dispose() }
}

$qualification = Resolve-PrivatePath $QualificationDirectory
$output = Resolve-PrivatePath $OutputDirectory
if (Test-Path -LiteralPath $output) { throw 'JSON_APPLOCK_OUTPUT_EXISTS' }
$receiptPath = Join-Path $qualification 'Result.private.json'
$bindingPath = Join-Path $qualification 'Binding.private.json'
$ilPath = Join-Path $qualification 'Toolbelt.JsonSchema.IL.private.json'
$publicReport = Join-Path $repo 'Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json'
$publicPackage = Join-Path $repo 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
foreach ($path in @($receiptPath,$bindingPath,$ilPath,$publicReport,$publicPackage)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'JSON_APPLOCK_QUALIFICATION_INPUT_MISSING' }
    Assert-RegularFile $path
}
$receipt = Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
$binding = Get-Content -LiteralPath $bindingPath -Raw -Encoding UTF8 | ConvertFrom-Json
$il = Get-Content -LiteralPath $ilPath -Raw -Encoding UTF8 | ConvertFrom-Json
$public = Get-Content -LiteralPath $publicReport -Raw -Encoding UTF8 | ConvertFrom-Json
$registry = Get-Content -LiteralPath (Join-Path $repo 'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$coreRow = @($registry.artifacts | Where-Object { $_.Fields.moduleId -ceq 'toolbelt.json.core' })
$schemaRow = @($registry.artifacts | Where-Object { $_.Fields.moduleId -ceq 'toolbelt.json.schema' })
$schemaPublicBinary = $public.binaries.PSObject.Properties['Toolbelt.JsonSchema.dll']
if ($receipt.status -cne 'PASS' -or $receipt.scope -cne 'JSON_SCHEMA_RELEASE_PACKAGE_DIRECT_IL' -or
    $binding.status -cne 'PREPARED' -or $binding.scope -cne $receipt.scope -or
    $binding.source_framework_status -cne 'COMPLETE' -or $binding.source_framework_phases -ne 27 -or
    -not $binding.source_framework_post_pins -or $binding.source_schema_il_status -cne 'PASS' -or
    $il.status -cne 'PASS' -or @($il.unknown).Count -ne 0 -or
    $coreRow.Count -ne 1 -or $schemaRow.Count -ne 1 -or $public.status -cne 'PASS' -or
    $public.scope -cne $receipt.scope -or $public.publication_authorized -ne $false -or
    $public.native_sql -cne 'NOT_EXECUTED' -or $public.package.sha256 -cne '896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287' -or
    $null -eq $schemaPublicBinary -or $schemaPublicBinary.Value.direct_package_il -cne 'PASS' -or
    $receipt.package_sha256 -cne $public.package.sha256 -or $receipt.core_sha256 -cne $coreRow[0].Fields.binarySha256 -or
    $receipt.schema_sha256 -cne $schemaRow[0].Fields.binarySha256 -or
    $public.new_package_schema_il.core_dependency_sha256 -cne $receipt.core_sha256 -or
    $public.new_package_schema_il.schema_sha256 -cne $receipt.schema_sha256 -or
    $receipt.core_sha256 -cne '73517dd6071058aa48cfa10ff9b5a82bd573ccb135f5685d94724753a43ba4cb' -or
    $receipt.schema_sha256 -cne 'ffff3b7e231945336c0ba8a635cf9a9d35ef5db0e526e5f36be90c821adf8241') {
    throw 'JSON_APPLOCK_QUALIFICATION_BINDING_INVALID'
}
$coreBinary = Join-Path (Join-Path $qualification 'package') 'Toolbelt.JsonCore.dll'
$schemaBinary = Join-Path (Join-Path $qualification 'package') 'Toolbelt.JsonSchema.dll'
if ((Get-Hash $coreBinary) -cne $receipt.core_sha256 -or (Get-Hash $schemaBinary) -cne $receipt.schema_sha256 -or
    (Get-Hash $coreBinary 'SHA512') -cne $coreRow[0].Fields.binarySha512.ToLowerInvariant() -or
    (Get-Hash $schemaBinary 'SHA512') -cne $schemaRow[0].Fields.binarySha512.ToLowerInvariant()) {
    throw 'JSON_APPLOCK_QUALIFIED_BINARY_DRIFT'
}
Assert-RegularFile $coreBinary
Assert-RegularFile $schemaBinary

$outputParent = Split-Path -Parent $output
if (-not (Test-Path -LiteralPath $outputParent -PathType Container)) { throw 'JSON_APPLOCK_OUTPUT_PARENT_REQUIRED' }
$corePackage = Join-Path $output 'packages/core'
$schemaPackage = Join-Path $output 'packages/schema'
[void][IO.Directory]::CreateDirectory($output)
& (Join-Path $repo 'Modules/toolbelt.json.core/Scripts/New-JsonClosureRelease.ps1') `
    -ModuleId 'toolbelt.json.core' -AssemblyPath $coreBinary -OutputDirectory $corePackage | Out-Null
& (Join-Path $repo 'Modules/toolbelt.json.core/Scripts/New-JsonClosureRelease.ps1') `
    -ModuleId 'toolbelt.json.schema' -AssemblyPath $schemaBinary -CoreAssemblyPath $coreBinary -OutputDirectory $schemaPackage | Out-Null

$composeSource = Join-Path $repo 'Tests/CI/run-json-schema-lab.ps1'
$parseErrors = $null
$composeAst = [Management.Automation.Language.Parser]::ParseFile($composeSource,[ref]$null,[ref]$parseErrors)
if ($parseErrors.Count) { throw 'JSON_APPLOCK_COMPOSER_PARSE' }
function Get-ExistingFunction([string]$Name) {
    $matches = @($composeAst.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $Name},$true))
    if ($matches.Count -ne 1) { throw 'JSON_APPLOCK_COMPOSER_FUNCTION' }
    return [scriptblock]::Create($matches[0].Extent.Text)
}
$pinPaths = @(
    (Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql'),
    (Join-Path $repo 'Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql'),
    (Join-Path $repo 'Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql')
)
. (Get-ExistingFunction 'Read-Template')
$packages = @{ core = $corePackage; schema = $schemaPackage }
. (Get-ExistingFunction 'Product-Sql')
$resultTable = Read-Template $pinPaths[0] 'local'
$coreDeploy = Product-Sql 'core' 'Deploy' 'local'
$schemaDeploy = Product-Sql 'schema' 'Deploy' 'local'
$schemaUninstall = Product-Sql 'schema' 'Uninstall' 'local'
foreach ($fragment in @($resultTable,$coreDeploy,$schemaDeploy,$schemaUninstall)) {
    if ($fragment -match '(?m)^\s*:|\$\(') { throw 'JSON_APPLOCK_UNRESOLVED_SQLCMD' }
}
if ($schemaDeploy -notmatch "toolbelt\.deploy\.json\.shared-core" -or
    $schemaDeploy -notmatch "toolbelt\.deploy\.toolbelt\.json\.schema" -or
    $schemaDeploy -notmatch 'JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar\.' -or
    $schemaDeploy -notmatch 'JSON Schema lifecycle: Modul-AppLock nicht verfügbar\.') {
    throw 'JSON_APPLOCK_SCHEMA_LOCK_SOURCE_DRIFT'
}
$baseline = $resultTable.TrimEnd() + [Environment]::NewLine + 'GO' + [Environment]::NewLine + $coreDeploy.TrimStart()
$baselinePath = Join-Path $output 'baseline.local.sql'
$schemaSqlPath = Join-Path $output 'schema.local.sql'
$schemaUninstallPath = Join-Path $output 'schema-uninstall.local.sql'
Write-NewUtf8 $baselinePath $baseline
Write-NewUtf8 $schemaSqlPath $schemaDeploy
Write-NewUtf8 $schemaUninstallPath $schemaUninstall

$artifactRows = @(
    [ordered]@{module_id='toolbelt.json.core';path=$coreBinary;sha256=$receipt.core_sha256;sha512=$coreRow[0].Fields.binarySha512.ToLowerInvariant();sql_name='Toolbelt_JsonCore'},
    [ordered]@{module_id='toolbelt.json.schema';path=$schemaBinary;sha256=$receipt.schema_sha256;sha512=$schemaRow[0].Fields.binarySha512.ToLowerInvariant();sql_name='Toolbelt_JsonSchema'}
)
$contractPath = [Environment]::GetEnvironmentVariable('SQL_SERVER_LAB_TEST_ENV_FILE','Process')
if ([string]::IsNullOrWhiteSpace($contractPath)) {
    $dataRoot = [Environment]::GetEnvironmentVariable('SQL_SERVER_LAB_DATA_ROOT','Process')
    if (-not [string]::IsNullOrWhiteSpace($dataRoot)) { $contractPath = Join-Path $dataRoot 'Exports/TestUmgebung.json' }
}
$schemaPath = [Environment]::GetEnvironmentVariable('SQL_SERVER_LAB_TEST_ENV_SCHEMA_FILE','Process')
if ([string]::IsNullOrWhiteSpace($schemaPath) -and -not [string]::IsNullOrWhiteSpace($contractPath)) {
    $schemaPath = Join-Path (Split-Path -Parent $contractPath) 'TestUmgebung.schema.json'
}
$promptPath = [Environment]::GetEnvironmentVariable('SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE','Process')
if ([string]::IsNullOrWhiteSpace($contractPath) -or -not (Test-Path -LiteralPath $contractPath -PathType Leaf) -or
    [string]::IsNullOrWhiteSpace($schemaPath) -or -not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
    throw 'JSON_APPLOCK_LAB_CONTRACT_REQUIRED'
}
foreach ($path in @($contractPath,$schemaPath)) { Assert-RegularFile $path }
if (-not [string]::IsNullOrWhiteSpace($promptPath)) { Assert-RegularFile $promptPath }
$labInputs = [ordered]@{contract_path=[IO.Path]::GetFullPath($contractPath);contract_sha256=(Get-Hash $contractPath);
    schema_path=[IO.Path]::GetFullPath($schemaPath);schema_sha256=(Get-Hash $schemaPath);prompt_path=$null;prompt_sha256=$null}
if (-not [string]::IsNullOrWhiteSpace($promptPath)) {
    $labInputs.prompt_path=[IO.Path]::GetFullPath($promptPath)
    $labInputs.prompt_sha256=Get-Hash $promptPath
}
$pins = [Collections.Generic.List[object]]::new()
$pinSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Add-Pin([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if ($pinSet.Add($full)) { $pins.Add([ordered]@{path=$full;sha256=(Get-Hash $full).ToUpperInvariant()}) }
}
foreach ($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'Invoke-JsonSchemaAppLockLab.ps1'),$composeSource,$publicReport,$publicPackage,
        (Join-Path $PSScriptRoot 'Test-JsonSchemaAppLockOffline.ps1'),
        (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),
        (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
        (Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'),
        (Join-Path $repo 'Tests/CI/run-lab-local.ps1'),
        (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),
        (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),
        $receiptPath,$bindingPath,$ilPath,$(Join-Path $qualification 'package/Toolbelt.JsonCore.dll'),
        $(Join-Path $qualification 'package/Toolbelt.JsonSchema.dll'),
        (Join-Path $repo 'Modules/toolbelt.json.core/Scripts/New-JsonClosureRelease.ps1'),
        (Join-Path $repo 'Modules/toolbelt.json.core/Scripts/Expand-JsonClosureSql.ps1'),
        (Join-Path $repo 'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'),
        (Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql'),
        (Join-Path $repo 'Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql'),
        (Join-Path $repo 'Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql'),
        (Join-Path $repo 'Modules/toolbelt.json.core/Deployment/Deploy.sql'),
        (Join-Path $repo 'Modules/toolbelt.json.schema/Deployment/Deploy.sql'))) {
    Add-Pin $path
}
foreach ($path in @($labInputs.contract_path,$labInputs.schema_path)) {
    Add-Pin $path
}
if ($labInputs.prompt_path) { Add-Pin $labInputs.prompt_path }
foreach ($path in @($baselinePath,$schemaSqlPath,$schemaUninstallPath,
        (Join-Path $corePackage 'Deploy.WithAssembly.sql'),(Join-Path $schemaPackage 'Deploy.WithAssembly.sql'),
        (Join-Path $corePackage 'Uninstall.Expanded.sql'),(Join-Path $schemaPackage 'Uninstall.Expanded.sql'))) {
    Add-Pin $path
}
. (Join-Path $repo 'Modules/toolbelt.json.core/Scripts/Expand-JsonClosureSql.ps1')
foreach ($relative in $script:JsonClosureSqlPaths) { Add-Pin (Join-Path (Join-Path $repo 'Modules') $relative) }
foreach ($row in @($coreRow[0],$schemaRow[0])) {
    $moduleRoot = Join-Path $repo ('Modules/'+$row.Fields.moduleId)
    Add-Pin (Join-Path $moduleRoot ('Clr/'+$row.Fields.managedAssembly+'.csproj'))
    foreach ($property in $row.Fields.PSObject.Properties) {
        if ($property.Name.StartsWith('source/',[StringComparison]::Ordinal)) {
            Add-Pin (Join-Path $moduleRoot ('Clr/'+$property.Name.Substring(7)))
        }
    }
}
$runset = [ordered]@{
    schema_version='json-schema-applock-probe/v1'
    target=[ordered]@{platform='windows';version='2025';patch='CU8';compatibility_level=170;test_purpose='Functional'}
    lab=$labInputs
    qualification=[ordered]@{path=$publicReport.Substring($repo.Length+1).Replace('\','/');sha256=(Get-Hash $publicReport);package_sha256=$receipt.package_sha256;receipt_path=$receiptPath;receipt_sha256=(Get-Hash $receiptPath)}
    artifacts=$artifactRows
    baseline=[ordered]@{path=$baselinePath;sha256=(Get-Hash $baselinePath);modules=@('toolbelt.core.result-table','toolbelt.json.core')}
    schema_deploy=[ordered]@{path=$schemaSqlPath;sha256=(Get-Hash $schemaSqlPath);module='toolbelt.json.schema'}
    schema_uninstall=[ordered]@{path=$schemaUninstallPath;sha256=(Get-Hash $schemaUninstallPath);module='toolbelt.json.schema'}
    pins=$pins.ToArray()
    scope=[ordered]@{lock_resources=@('toolbelt.deploy.json.shared-core','toolbelt.deploy.toolbelt.json.schema');expected_error=55637;expected_state=1;positive_control='same schema Deploy succeeds after holder release'}
}
$runsetPath = Join-Path $output 'runset.json'
Write-NewUtf8 $runsetPath ($runset | ConvertTo-Json -Depth 8)
Write-Output 'PREPARED JSON_SCHEMA_APPLOCK_PRIVATE_RUNSET'
