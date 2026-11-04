#Requires -Version 7.5
[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('Run','Audit')][string]$Mode,
 [Parameter(Mandatory)][ValidateSet('2019','2022','2025')][string]$Version,
 [Parameter(Mandatory)][ValidatePattern('^CU[0-9]+$')][string]$Patch,
 [Parameter(Mandatory)][ValidateSet(150,160,170)][int]$CompatibilityLevel,
 [Parameter(Mandatory)][ValidateSet('local','central')][string]$DeploymentMode,
 [Parameter(Mandatory)][string]$ExpectedTargetKey,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedContractSha256,
 [Parameter(Mandatory)][string]$JournalDirectory,
 [Parameter(Mandatory)][string]$InstallationPackageRoot,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedPackageManifestSha256,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
 [Parameter(Mandatory)][hashtable]$CaseInputSha256,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$MatrixCasesExpectedSha256,
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($CompatibilityLevel -gt (@{'2019'=150;'2022'=160;'2025'=170}[$Version])){throw 'SSIS_PROCEDURE_MATRIX_UNSUPPORTED_CL'}
$original=Join-Path $PSScriptRoot 'Invoke-ProcedureDefinitionLab.ps1'
if((Get-FileHash -LiteralPath $original).Hash -cne 'D6B432B267D9557FB4452747AF11D745E105EEE09C71C90B91FB6DC17761C2ED'){throw 'SSIS_PROCEDURE_MATRIX_LAB_CHANGED'}
$caseFile=Join-Path $PSScriptRoot 'Invoke-ProcedureDefinitionMatrixCases.ps1'
if((Get-FileHash -LiteralPath $caseFile).Hash -cne $MatrixCasesExpectedSha256){throw 'SSIS_PROCEDURE_MATRIX_CASES_CHANGED'}
& $caseFile -CompatibilityLevel $CompatibilityLevel -DeploymentMode $DeploymentMode -GeneratorDatabase 'ToolbeltSsis_0000000000000000_central' -ValidateOnly | Out-Null
$text=[IO.File]::ReadAllText($original)
function Replace-MatrixOnce([string]$Anchor,[string]$Replacement){
 if($script:text.Split($Anchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_PROCEDURE_MATRIX_LAB_ANCHOR'}
 $script:text=$script:text.Replace($Anchor,$Replacement)
}
Replace-MatrixOnce "Version='2025';Patch='CU8'" ("Version='"+$Version+"';Patch='"+$Patch+"'")
Replace-MatrixOnce "`$target.Modes=@('local')" ("`$target.Modes=@('"+$DeploymentMode+"')")
Replace-MatrixOnce "`$target.CompatibilityLevel=150" ("`$target.CompatibilityLevel="+$CompatibilityLevel)
if($DeploymentMode -eq 'central'){
 Replace-MatrixOnce ' $target.JournalDirectory=$journal' ' $target.Full=$true; $target.JournalDirectory=$journal'
}
$anchor="    & (Join-Path `$PSScriptRoot 'Invoke-ProcedureDefinitionCases.ps1') -Connection `$connection -Master `$master -AdminConnectionString `$builder.ConnectionString -RunId `$runId -IdentityJournal (Join-Path `$journalRoot 'identity.private.json')"
$replacement=@'
    try{
        if($clientDatabase){
            $connection.ChangeDatabase($clientDatabase)
            Batches $connection (Expand (Join-Path $repoRoot 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql')) 'local'
        }
        & (Join-Path $PSScriptRoot 'Invoke-ProcedureDefinitionMatrixCases.ps1') -Connection $connection -Master $master -AdminConnectionString $builder.ConnectionString -RunId $runId -IdentityJournal (Join-Path $journalRoot 'identity.private.json') -CompatibilityLevel @CL@ -DeploymentMode '@MODE@' -GeneratorDatabase $database
    }finally{if($clientDatabase){$connection.ChangeDatabase($database)}}
'@
Replace-MatrixOnce $anchor ($replacement.Replace('@CL@',[string]$CompatibilityLevel).Replace('@MODE@',$DeploymentMode))
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-CurrentQualificationLab.ps1'),[ref]$null,[ref]$errors)
$method=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Bind-CurrentScriptRoot'},$true))
if($errors.Count -or $method.Count -ne 1){throw 'SSIS_PROCEDURE_MATRIX_BINDER'}
. ([scriptblock]::Create($method[0].Extent.Text))
$bound=[scriptblock]::Create((Bind-CurrentScriptRoot -Text $text -Root $PSScriptRoot))
$arguments=@{Mode=$Mode;ExpectedTargetKey=$ExpectedTargetKey;ExpectedContractSha256=$ExpectedContractSha256;
 JournalDirectory=$JournalDirectory;InstallationPackageRoot=$InstallationPackageRoot;ExpectedPackageManifestSha256=$ExpectedPackageManifestSha256;
 QualifiedProviderSha512=$QualifiedProviderSha512;CaseInputSha256=$CaseInputSha256;ValidateOnly=$ValidateOnly}
& $bound @arguments
