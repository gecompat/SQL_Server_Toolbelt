[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$driver=Join-Path $PSScriptRoot 'Invoke-JsonSchemaUninstallConfirmationLab.ps1'
$preparer=Join-Path $PSScriptRoot 'Prepare-JsonSchemaUninstallConfirmationRunset.ps1'
$source=Join-Path $repo 'Modules/toolbelt.json.schema/Deployment/Uninstall.sql'
foreach($path in @($driver,$preparer,$source)){
    if($path.EndsWith('.ps1')){$errors=$null;[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errors)|Out-Null;if($errors.Count){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_PARSE'}}
}
$astErrors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($driver,[ref]$null,[ref]$astErrors)
$shape=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Assert-UninstallCaseShape'},$true))
if($shape.Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_CASE_GUARD_MISSING'}
. ([scriptblock]::Create($shape[0].Extent.Text))
$valid=@(
    [pscustomobject]@{ordinal=0;confirmation='01';path='synthetic-01.sql';sha256=('A'*64);expected_error=55635;expected_state=1;expected_message='JSON Schema lifecycle: ungültige Consumer-Bestätigung.'},
    [pscustomobject]@{ordinal=1;confirmation='0';path='synthetic-0.sql';sha256=('B'*64);expected_error=55635;expected_state=1;expected_message='JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.'})
Assert-UninstallCaseShape $valid
foreach($bad in @(
    @($valid[1],$valid[0]),
    @($valid[0],[pscustomobject]@{ordinal=1;confirmation='00';path='synthetic-0.sql';sha256=('B'*64);expected_error=55635;expected_state=1;expected_message='JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.'}),
    @($valid[0],[pscustomobject]@{ordinal=1;confirmation='0';path='synthetic-0.sql';sha256=('B'*64);expected_error=55637;expected_state=1;expected_message='JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.'}),
    @($valid[0],[pscustomobject]@{ordinal=1;confirmation='0';path='synthetic-0.sql';sha256=('B'*64);expected_error=55635;expected_state=2;expected_message='JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.'}),
    @($valid[0],[pscustomobject]@{ordinal=1;confirmation='0';path='synthetic-0.sql';sha256=('B'*64);expected_error=55635;expected_state=1;expected_message='wrong message.'}),
    @($valid[0],[pscustomobject]@{ordinal=1;confirmation='0';path='synthetic-0.sql';sha256='not-a-hash';expected_error=55635;expected_state=1;expected_message='JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.'}),
    @($valid[0]))) {
    $rejected=$false
    try{Assert-UninstallCaseShape $bad}catch{$rejected=$_.Exception.Message -ceq 'JSON_UNINSTALL_CONFIRMATION_CASES_INVALID'}
    if(-not$rejected){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_NEGATIVE_CASE_ACCEPTED'}
}
$prepErrors=$null;$prepAst=[Management.Automation.Language.Parser]::ParseFile($preparer,[ref]$null,[ref]$prepErrors)
$replace=@($prepAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Replace-Exact'},$true))
if($replace.Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_TRANSFORM_GUARD_MISSING'}
. ([scriptblock]::Create($replace[0].Extent.Text))
$coreMode=Replace-Exact "DECLARE @Mode nvarchar(max)=N'local'," "DECLARE @Mode nvarchar(max)=N'local'," "DECLARE @Mode nvarchar(max)=N'central'," 'OFFLINE_MODE'
if($coreMode-cne"DECLARE @Mode nvarchar(max)=N'central',"){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_CENTRAL_TRANSFORM'}
$duplicateRejected=$false
try{Replace-Exact "N'local' N'local'" "N'local'" "N'central'" 'OFFLINE_MODE'}catch{$duplicateRejected=$_.Exception.Message -ceq 'OFFLINE_MODE'}
if(-not$duplicateRejected){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_DUPLICATE_TRANSFORM_ACCEPTED'}
$confirmation=Replace-Exact "DECLARE @Confirmation nvarchar(max)=N'1'" "DECLARE @Confirmation nvarchar(max)=N'1'" "DECLARE @Confirmation nvarchar(max)=N'{CONFIRMATION}'" 'OFFLINE_CONFIRMATION'
if($confirmation.Replace('{CONFIRMATION}','01')-cne"DECLARE @Confirmation nvarchar(max)=N'01'" -or
   $confirmation.Replace('{CONFIRMATION}','0')-cne"DECLARE @Confirmation nvarchar(max)=N'0'"){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_CONFIRMATION_TRANSFORM'}
$sql=[IO.File]::ReadAllText($source,[Text.Encoding]::UTF8)
foreach($required in @(
    "IF CONVERT(varbinary(max),@Confirmation) NOT IN(CONVERT(varbinary(max),N'0'),CONVERT(varbinary(max),N'1'))",
    "THROW 55635,N'JSON Schema lifecycle: ungültige Consumer-Bestätigung.',1;",
    "IF CONVERT(varbinary(max),@Mode)=CONVERT(varbinary(max),N'central') AND @Confirmation=N'0'",
    "THROW 55635,N'JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.',1;")){
    if(-not$sql.Contains($required,[StringComparison]::Ordinal)){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_SQL_CONTRACT_DRIFT'}
}
$closure=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Assert-ArtifactClosure'},$true))
$errorHelper=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Test-ExactSqlErrorSet'},$true))
$requiredPins=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Assert-RequiredPins'},$true))
if($closure.Count-ne1-or$errorHelper.Count-ne1-or$requiredPins.Count-ne1){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_BINDING_GUARD_MISSING'}
. ([scriptblock]::Create($closure[0].Extent.Text));. ([scriptblock]::Create($errorHelper[0].Extent.Text));. ([scriptblock]::Create($requiredPins[0].Extent.Text))
$validError=[pscustomobject]@{Number=55635;State=1;Class=16;Message='synthetic exact error'}
$singleOracle=Test-ExactSqlErrorSet @($validError) 55635 1 16 'synthetic exact error'
$emptyOracle=Test-ExactSqlErrorSet @() 55635 1 16 'synthetic exact error'
$multipleOracle=Test-ExactSqlErrorSet @($validError,$validError) 55635 1 16 'synthetic exact error'
$wrongOracle=Test-ExactSqlErrorSet @([pscustomobject]@{Number=55635;State=2;Class=16;Message='synthetic exact error'}) 55635 1 16 'synthetic exact error'
if($singleOracle.Count-ne1-or-not$singleOracle.Exact-or$emptyOracle.Count-ne0-or$emptyOracle.Exact-or
   $multipleOracle.Count-ne2-or$multipleOracle.Exact-or$wrongOracle.Count-ne1-or$wrongOracle.Exact){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_SQL_ERROR_SET_ORACLE'}
$runtimeRoot=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))
if(-not(Test-Path -LiteralPath $runtimeRoot -PathType Container)){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_RUNTIME_ROOT_MISSING'}
$tempRoot=[IO.Path]::GetFullPath((Join-Path $runtimeRoot ('json-schema-uninstall-confirmation-offline-'+[guid]::NewGuid().ToString('N'))))
if(-not$tempRoot.StartsWith($runtimeRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_TEMP_BOUNDARY'}
[void][IO.Directory]::CreateDirectory($tempRoot)
$corePath=Join-Path $tempRoot 'core.synthetic.bin';$schemaPath=Join-Path $tempRoot 'schema.synthetic.bin'
try{
    [IO.File]::WriteAllBytes($corePath,[byte[]](0x43,0x4F,0x52,0x45));[IO.File]::WriteAllBytes($schemaPath,[byte[]](0x53,0x43,0x48,0x45,0x4D,0x41))
    $baseArtifacts=@(
        [pscustomobject]@{module_id='toolbelt.json.core';path=$corePath;sql_name='Toolbelt_JsonCore';sha256=(Get-FileHash $corePath -Algorithm SHA256).Hash.ToLowerInvariant();sha512=(Get-FileHash $corePath -Algorithm SHA512).Hash.ToLowerInvariant()},
        [pscustomobject]@{module_id='toolbelt.json.schema';path=$schemaPath;sql_name='Toolbelt_JsonSchema';sha256=(Get-FileHash $schemaPath -Algorithm SHA256).Hash.ToLowerInvariant();sha512=(Get-FileHash $schemaPath -Algorithm SHA512).Hash.ToLowerInvariant()})
    $pinMap=@{};foreach($item in $baseArtifacts){$pinMap[[IO.Path]::GetFullPath($item.path)]=$item.sha256}
    Assert-ArtifactClosure $baseArtifacts $baseArtifacts $pinMap
    foreach($mutated in @(
        @([pscustomobject]@{module_id='toolbelt.json.core';path=$corePath;sql_name='WrongCore';sha256=$baseArtifacts[0].sha256;sha512=$baseArtifacts[0].sha512},$baseArtifacts[1]),
        @($baseArtifacts[0]),
        @([pscustomobject]@{module_id='toolbelt.json.core';path=$corePath;sql_name='Toolbelt_JsonCore';sha256=('0'*64);sha512=$baseArtifacts[0].sha512},$baseArtifacts[1]))) {
        $rejected=$false;try{Assert-ArtifactClosure $baseArtifacts $mutated $pinMap}catch{$rejected=$true};if(-not$rejected){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_BAD_ARTIFACT_ACCEPTED'}
    }
    $required=@((Join-Path $repo 'driver.ps1'),(Join-Path $repo 'helper.ps1'))
    $complete=@{};foreach($path in $required){$complete[[IO.Path]::GetFullPath($path)]='A'*64}
    Assert-RequiredPins $complete $required
    $incomplete=@{};$firstPath=[IO.Path]::GetFullPath($required[0]);$incomplete[$firstPath]='A'*64
    $missingRejected=$false;try{Assert-RequiredPins $incomplete $required}catch{$missingRejected=$_.Exception.Message -ceq 'JSON_UNINSTALL_CONFIRMATION_REQUIRED_PIN_MISSING'}
    if(-not$missingRejected){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_MISSING_HELPER_ACCEPTED'}
}finally{
    $resolvedRoot=[IO.Path]::GetFullPath($runtimeRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar
    $resolvedTemp=[IO.Path]::GetFullPath($tempRoot)
    if(-not$resolvedTemp.StartsWith($resolvedRoot,[StringComparison]::OrdinalIgnoreCase)-or
       (([IO.DirectoryInfo]::new($resolvedTemp).Attributes -band [IO.FileAttributes]::ReparsePoint)-ne0)){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_CLEANUP_BOUNDARY'}
    foreach($file in @($corePath,$schemaPath)){if(Test-Path -LiteralPath $file){[IO.File]::Delete($file)}}
    if(@(Get-ChildItem -LiteralPath $resolvedTemp -Force).Count-ne0){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_TEMP_NOT_EMPTY'}
    [IO.Directory]::Delete($resolvedTemp,$false)
}
$driverText=[IO.File]::ReadAllText($driver)
foreach($required in @('Read-CoreProjection','Read-JsonSchemaNamespace','Assert-CoreModeCentral','Assert-SchemaInstalled','Assert-SchemaModuleAbsent','Assert-CoreOnly','Assert-ConfirmationSql','Get-ContenderStateSamples','Test-ExternalSessionIdle','Assert-ReleaseOwnIdentity','Assert-ArtifactClosure','Assert-RequiredPins','expectedOwnDbState','OWNED_DATABASE_STATE_DRIFT','QUOTED_IDENTIFIER ON','IMPLICIT_TRANSACTIONS OFF','@@OPTIONS','caught.Errors','Message-ceq')){
    if(-not$driverText.Contains($required,[StringComparison]::Ordinal)){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_DRIVER_GUARD_MISSING'}
}
if($driverText-match'(?m)Assert-HolderLock|Acquire-HolderLock|toolbelt\.deploy\.json\.shared-core'){throw 'JSON_UNINSTALL_CONFIRMATION_OFFLINE_UNEXPECTED_APPLOCK_CASE'}
Write-Output 'PASS JSON_SCHEMA_UNINSTALL_CONFIRMATION offline case, artifact/helper-pin guards, central transforms, fixed session profile and source errors; no SQL executed'
