[CmdletBinding()]
param([Parameter(Mandatory)][string]$EvidenceDirectory,[switch]$ValidateOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$sourcePath=Join-Path $PSScriptRoot 'Prepare-CurrentStandaloneTsqlInstallerRunset.ps1'
$sourceHash='9A046C902F37962EE37C8573CB9E8ECB24BEE8E6AAF1D365AD2165711E2193A0'
if((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -cne $sourceHash){throw 'SSIS_CURRENT_MATRIX_PREPARER_SOURCE_CHANGED'}
if($ValidateOnly){
    $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($sourcePath,[ref]$null,[ref]$errors)
    if($errors.Count){throw 'SSIS_CURRENT_MATRIX_PREPARER_SYNTAX'}
    'PASS SSIS_CURRENT_MATRIX_PREPARER_VALIDATED; no SQL';return
}
$helperPath=Join-Path $repo 'Tests/CI/run-lab-local.ps1'
function Import-MatrixPrepFunction([string]$Path,[string]$Name){
    $errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$null,[ref]$errors)
    if($errors.Count){throw 'SSIS_CURRENT_MATRIX_LAB_HELPER_PARSE'}
    $nodes=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $Name},$true))
    if($nodes.Count -ne 1){throw 'SSIS_CURRENT_MATRIX_LAB_HELPER_AMBIGUOUS'}
    [scriptblock]::Create($nodes[0].Extent.Text)
}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector')){
    . (Import-MatrixPrepFunction $helperPath $name)
}
. (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
$lab=Resolve-LabContract -TestPurpose Functional
$matrixCases=@(
    [pscustomobject]@{platform='windows';version='2022';patch='base';cl=150},
    [pscustomobject]@{platform='windows';version='2022';patch='base';cl=160},
    [pscustomobject]@{platform='windows';version='2025';patch='base';cl=150},
    [pscustomobject]@{platform='windows';version='2025';patch='base';cl=160}
)
foreach($case in $matrixCases){
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
    if($targets.Count -ne 1){throw 'SSIS_CURRENT_MATRIX_EXACT_READY_TARGET_REQUIRED'}
}
& $sourcePath -EvidenceDirectory $EvidenceDirectory
$runtime=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))+[IO.Path]::DirectorySeparatorChar
$output=[IO.Path]::GetFullPath($EvidenceDirectory)
if(-not $output.StartsWith($runtime,[StringComparison]::OrdinalIgnoreCase) -or
   -not (Test-Path -LiteralPath $output -PathType Container) -or
   ((Get-Item -LiteralPath $output -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
    throw 'SSIS_CURRENT_MATRIX_PRIVATE_OUTPUT_REQUIRED'
}
$runsetPath=Join-Path $output 'runset.json'
if(-not (Test-Path -LiteralPath $runsetPath -PathType Leaf) -or
   ((Get-Item -LiteralPath $runsetPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
    throw 'SSIS_CURRENT_MATRIX_RUNSET_MISSING'
}
$runset=Get-Content -LiteralPath $runsetPath -Raw|ConvertFrom-Json
$keys=@($runset.PSObject.Properties.Name|Sort-Object)
if(($keys -join '|') -cne 'cases|contractSha256|native|package|pins|promptSha256|schemaSha256|schemaVersion' -or
   $runset.schemaVersion -cne '1.0' -or $runset.package -cne 'Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-Current-Install-Windows.zip' -or
   $runset.cases.Count -ne 2 -or $runset.native.caseInvocations -ne 2 -or
   $runset.native.auditInvocations -ne 2 -or $runset.native.maximumAttempts -ne 4){
    throw 'SSIS_CURRENT_MATRIX_BASE_RUNSET_INVALID'
}
$expectedPins=@{
    'Invoke-CurrentStandaloneTsqlInstallerLab.ps1'='DEC3EDF708ADA65ECDB76F170486B9952E593662DF58514E200CE615726E845C'
    'Prepare-CurrentStandaloneTsqlInstallerRunset.ps1'=$sourceHash
}
$matrixPaths=@{
    'Invoke-CurrentStandaloneTsqlInstallerLab.ps1'=(Join-Path $PSScriptRoot 'Invoke-CurrentStandaloneTsqlInstallerMatrixLab.ps1')
    'Prepare-CurrentStandaloneTsqlInstallerRunset.ps1'=$PSCommandPath
}
foreach($name in $expectedPins.Keys){
    $matches=@($runset.pins|Where-Object {$_.path -ceq (Join-Path $PSScriptRoot $name)})
    if($matches.Count -ne 1 -or $matches[0].sha256 -cne $expectedPins[$name]){throw 'SSIS_CURRENT_MATRIX_BASE_PIN_MISMATCH'}
    $matches[0].path=[IO.Path]::GetFullPath($matrixPaths[$name])
    $matches[0].sha256=(Get-FileHash -LiteralPath $matrixPaths[$name] -Algorithm SHA256).Hash
}
$runset.cases=@(
    [pscustomobject]@{platform='windows';version='2022';patch='base';cl=150},
    [pscustomobject]@{platform='windows';version='2022';patch='base';cl=160},
    [pscustomobject]@{platform='windows';version='2025';patch='base';cl=150},
    [pscustomobject]@{platform='windows';version='2025';patch='base';cl=160}
)
$runset.native.caseInvocations=4
$runset.native.auditInvocations=4
$runset.native.maximumAttempts=8
$runset.native.scope='Windows 2022 CL150/160 + Windows 2025 CL150/160; local and central databases per target'
[IO.File]::WriteAllText($runsetPath,($runset|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
$hash=(Get-FileHash -LiteralPath $runsetPath -Algorithm SHA256).Hash
Write-Output "PASS SSIS_CURRENT_MATRIX_RUNSET cases=4 pins=$($runset.pins.Count) sha256=$hash"
