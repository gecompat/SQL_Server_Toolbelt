[CmdletBinding()]
param([Parameter(Mandatory)][string]$EvidenceDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Import-PrepFunction([string]$Path,[string]$Name){
    $errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$null,[ref]$errors)
    if($errors.Count){throw 'SSIS_TSQL_PREPARE_HELPER_PARSE'}
    $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $Name},$true))
    if($nodes.Count -ne 1){throw 'SSIS_TSQL_PREPARE_HELPER_AMBIGUOUS'}
    [scriptblock]::Create($nodes[0].Extent.Text)
}
foreach($block in @(
    (Import-PrepFunction (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') 'Assert-ReleasePrivatePath'),
    (Import-PrepFunction (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') 'Assert-ReleasePin'),
    (Import-PrepFunction (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1') 'Get-EnvironmentVariableValue'),
    (Import-PrepFunction (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1') 'Resolve-LabContract'),
    (Import-PrepFunction (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1') 'Test-LabTargetReady'),
    (Import-PrepFunction (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1') 'Get-LabTargetsForSelector'))){. $block}

$private=[IO.Path]::GetFullPath((Join-Path $script:repo '.runtime'))+[IO.Path]::DirectorySeparatorChar
$output=Assert-ReleasePrivatePath $EvidenceDirectory
if(-not $output.StartsWith($private,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'SSIS_TSQL_PRIVATE_OUTPUT_REQUIRED'}
$parent=[IO.DirectoryInfo]::new([IO.Path]::GetDirectoryName($output))
while($parent -and $parent.FullName.Length -ge $private.TrimEnd('\','/').Length){
    if(($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'SSIS_TSQL_REPARSE_PATH'}
    $parent=$parent.Parent
}
[void][IO.Directory]::CreateDirectory($output)
. (Join-Path $script:repo 'Tests/CI/LabQualifiedContract.ps1')
$lab=Resolve-LabContract -TestPurpose Functional
$prompt=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
if(-not $prompt -or -not (Test-Path -LiteralPath $prompt)){throw 'SSIS_TSQL_REVIEWED_PROMPT_REQUIRED'}
$cases=@(
    [pscustomobject]@{platform='windows';version='2019';patch='base';cl=150},
    [pscustomobject]@{platform='windows';version='2025';patch='base';cl=170}
)
foreach($case in $cases){
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
    if($targets.Count -ne 1){throw 'SSIS_TSQL_EXACT_READY_TARGET_REQUIRED'}
}
$paths=@(
    (Join-Path $PSScriptRoot 'Invoke-StandaloneTsqlInstallerLab.ps1'),
    (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
    (Join-Path $PSScriptRoot 'Prepare-StandaloneTsqlInstallerRunset.ps1'),
    (Join-Path $script:repo 'Tests/CI/LabQualifiedContract.ps1'),
    (Join-Path $script:repo 'Tests/CI/run-lab-local.ps1'),
    (Join-Path $script:repo 'Tests/CI/run-csv-memory-lab.ps1'),
    (Join-Path $script:repo 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1'),
    (Join-Path $script:repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-ApiCases.ps1'),
    (Join-Path $script:repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-LabContract.ps1'),
    (Join-Path $script:repo 'Modules/toolbelt.tsql.ssis-debug/Contracts/Api.json'),
    (Join-Path $script:repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/synthetic-8.dtsx'),
    (Join-Path $script:repo 'Releases/1.0.0/SSIS-INSTALL-TSQL.sql'),
    (Join-Path $script:repo 'Releases/1.0.0/ssis-standalone-installer.json'),
    (Join-Path $script:repo 'Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-1.0.0-Install-Windows.zip'),
    (Join-Path $script:repo 'Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-1.0.0-Install-Windows.zip.sha256'),
    (Join-Path $script:repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/LookupRoles.InstallPackage.20261025.json'),
    $lab.Path,$lab.SchemaPath,$prompt,(Get-Command pwsh -ErrorAction Stop).Source
)
$pins=@($paths|Sort-Object -Unique|ForEach-Object{
    [ordered]@{path=[IO.Path]::GetFullPath($_);sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}
})
$runset=[ordered]@{
    schemaVersion='1.0'
    package='Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-1.0.0-Install-Windows.zip'
    cases=$cases
    contractSha256=(Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash
    schemaSha256=(Get-FileHash -LiteralPath $lab.SchemaPath -Algorithm SHA256).Hash
    promptSha256=(Get-FileHash -LiteralPath $prompt -Algorithm SHA256).Hash
    pins=$pins
    native=@{caseInvocations=2;auditInvocations=2;maximumAttempts=4;scope='Windows 2019 CL150 + Windows 2025 CL170; local and central databases per target'}
}
$path=Join-Path $output 'runset.json'
[IO.File]::WriteAllText($path,($runset|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
$hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
Write-Output "PASS SSIS_TSQL_RUNSET cases=2 pins=$($pins.Count) sha256=$hash"
