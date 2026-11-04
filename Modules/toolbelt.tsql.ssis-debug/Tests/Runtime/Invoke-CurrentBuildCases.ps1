[CmdletBinding()]
param([Data.SqlClient.SqlConnection]$Connection,
 [Data.SqlClient.SqlConnection]$Master,
 [string]$AdminConnectionString,
 [string]$RunId,[string]$IdentityJournal,
 [ValidateSet(150,160,170)][int]$CompatibilityLevel,
 [ValidateSet('local','central')][string]$DeploymentMode,
 [string]$CrossDatabase,[string]$FixtureModuleRoot,[string]$GeneratorDatabase,
 [ValidateSet('Full','Functional','ProcedureBoundary')][string]$QualificationPhase='Full',[switch]$ValidateOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$original=Join-Path $PSScriptRoot 'Invoke-ProcedureDefinitionCases.ps1'
if((Get-FileHash -LiteralPath $original).Hash -cne 'E3FBBDF106FBB15EEF6609C68E6DBB1E797044A914A5B13882066FD586A60464'){throw 'SSIS_BUILD_PROCEDURE_ORACLE_CHANGED'}
$text=[IO.File]::ReadAllText($original)
function Replace-BuildOnce([string]$Old,[string]$New){
 if($script:text.Split($Old,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_BUILD_CASE_ANCHOR'}
 $script:text=$script:text.Replace($Old,$New)
}
Replace-BuildOnce 'function Generate-ProcedureArtifact([string]$Operation,[string]$Bindings){' 'function Generate-ProcedureArtifact([string]$Operation,[string]$Bindings,[string]$Name="USP_Synthetic"){'
Replace-BuildOnce ".Value='USP_Synthetic'" '.Value=$Name'
$anchor="  `$cmd.Parameters.Add('@Operation',[Data.SqlDbType]::VarChar,32).Value=`$Operation"
Replace-BuildOnce $anchor ($anchor+"`n  `$cmd.Parameters.Add('@TSqlVersion',[Data.SqlDbType]::SmallInt).Value=[int16]$CompatibilityLevel")
if($DeploymentMode -ceq 'central'){
 if($GeneratorDatabase -cnotmatch '^ToolbeltSsis_[0-9a-f]{16}_central$'){throw 'SSIS_BUILD_GENERATOR_SCOPE'}
 Replace-BuildOnce " `$cmd.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow'" (" `$cmd.CommandText='["+$GeneratorDatabase+"].toolbelt_tsql.USP_ExplainSsisDataFlow'")
}
$anchor=' $temp=[regex]::Match($definition,'
Replace-BuildOnce $anchor (" . (Join-Path `$PSScriptRoot 'Invoke-ProcedureBoundaryCases.ps1')`n"+$anchor)
$bound=Bind-CurrentScriptRoot -Text $text -Root $PSScriptRoot
$errors=$null
[void][Management.Automation.Language.Parser]::ParseInput($bound,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_BUILD_PROCEDURE_SYNTAX'}
if($ValidateOnly){'SSIS_CURRENT_BUILD_CASES_PASS; no SQL';return}
if(-not ($Connection -and $Master -and $AdminConnectionString -and $RunId -and $IdentityJournal)){throw 'SSIS_BUILD_CONNECTION_REQUIRED'}
if($QualificationPhase -cne 'ProcedureBoundary'){
 & (Join-Path $PSScriptRoot 'Invoke-CurrentQualificationAllCases.ps1') -Connection $Connection -CrossDatabase $CrossDatabase -FixtureModuleRoot $FixtureModuleRoot -Mode $DeploymentMode
}
if($QualificationPhase -ceq 'Functional'){'SSIS_CURRENT_BUILD_FUNCTIONAL_PASS';return}
try{
 if($DeploymentMode -ceq 'central'){
  $Connection.ChangeDatabase($CrossDatabase)
  Batches $Connection (Expand (Join-Path $FixtureModuleRoot '../toolbelt.core.result-table/Deployment/Deploy.sql')) 'local'
 }
 try{
  & ([scriptblock]::Create($bound)) -Connection $Connection -Master $Master -AdminConnectionString $AdminConnectionString -RunId $RunId -IdentityJournal $IdentityJournal
 }catch{
  [IO.File]::WriteAllText((Join-Path (Split-Path -Parent $IdentityJournal) 'procedure-error.private.txt'),($_.ScriptStackTrace+"`n"+$_.Exception.ToString()))
  throw
 }
}finally{if($DeploymentMode -ceq 'central'){$Connection.ChangeDatabase($GeneratorDatabase)}}
'SSIS_CURRENT_BUILD_ALL_PASS'
