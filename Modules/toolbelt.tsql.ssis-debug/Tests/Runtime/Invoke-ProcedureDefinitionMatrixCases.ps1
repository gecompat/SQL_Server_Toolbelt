#Requires -Version 7.5
[CmdletBinding()]
param(
 [Data.SqlClient.SqlConnection]$Connection,
 [Data.SqlClient.SqlConnection]$Master,
 [string]$AdminConnectionString,
 [string]$RunId,
 [string]$IdentityJournal,
 [ValidateSet(150,160,170)][int]$CompatibilityLevel=150,
 [ValidateSet('local','central')][string]$DeploymentMode='local',
 [string]$GeneratorDatabase,
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$original=Join-Path $PSScriptRoot 'Invoke-ProcedureDefinitionCases.ps1'
if((Get-FileHash -LiteralPath $original).Hash -cne 'E3FBBDF106FBB15EEF6609C68E6DBB1E797044A914A5B13882066FD586A60464'){throw 'SSIS_PROCEDURE_MATRIX_ORACLE_CHANGED'}
$text=[IO.File]::ReadAllText($original)
function Replace-MatrixOnce([string]$Anchor,[string]$Replacement){
 if($script:text.Split($Anchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_PROCEDURE_MATRIX_CASE_ANCHOR'}
 $script:text=$script:text.Replace($Anchor,$Replacement)
}
$anchor="  `$cmd.Parameters.Add('@Operation',[Data.SqlDbType]::VarChar,32).Value=`$Operation"
Replace-MatrixOnce $anchor ($anchor+"`n  `$cmd.Parameters.Add('@TSqlVersion',[Data.SqlDbType]::SmallInt).Value=[int16]$CompatibilityLevel")
if($DeploymentMode -eq 'central'){
 if($GeneratorDatabase -cnotmatch '^ToolbeltSsis_[0-9a-f]{16}_central$'){throw 'SSIS_PROCEDURE_MATRIX_GENERATOR_DATABASE'}
 Replace-MatrixOnce " `$cmd.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow'" (" `$cmd.CommandText='["+$GeneratorDatabase+"].toolbelt_tsql.USP_ExplainSsisDataFlow'")
}
$binder=Join-Path $PSScriptRoot 'Invoke-CurrentQualificationLab.ps1'
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($binder,[ref]$null,[ref]$errors)
$method=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Bind-CurrentScriptRoot'},$true))
if($errors.Count -or $method.Count -ne 1){throw 'SSIS_PROCEDURE_MATRIX_BINDER'}
. ([scriptblock]::Create($method[0].Extent.Text))
$bound=[scriptblock]::Create((Bind-CurrentScriptRoot -Text $text -Root $PSScriptRoot))
if($ValidateOnly){'SSIS_PROCEDURE_MATRIX_CASES_VALIDATED; no SQL';return}
if(-not ($Connection -and $Master -and $AdminConnectionString -and $RunId -and $IdentityJournal)){throw 'SSIS_PROCEDURE_MATRIX_CONNECTION_REQUIRED'}
$level=Query $Connection 'SELECT compatibility_level AS C FROM sys.databases WHERE database_id=DB_ID();'
if($level.Rows[0].C -ne $CompatibilityLevel){throw 'SSIS_PROCEDURE_MATRIX_CONSUMER_CL'}
if($DeploymentMode -eq 'central'){
 if($GeneratorDatabase -ceq $Connection.Database){throw 'SSIS_PROCEDURE_MATRIX_REQUIRES_CONSUMER'}
 $context=Query $Connection "SELECT OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow') AS LocalApi;"
 if(-not $context.Rows[0].IsNull('LocalApi')){throw 'SSIS_PROCEDURE_MATRIX_LOCAL_GENERATOR_PRESENT'}
 'SSIS_PROCEDURE_CENTRAL_CONSUMER_PASS'
}
& $bound -Connection $Connection -Master $Master -AdminConnectionString $AdminConnectionString -RunId $RunId -IdentityJournal $IdentityJournal
