[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,[string]$CrossDatabase,[string]$FixtureModuleRoot,[Parameter(Mandatory)][string]$Mode,
 [ValidateSet('Full','ApiRightsLifecycle')][string]$QualificationPhase='Full')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Replace-QualificationAnchor([string]$Source,[string]$Old,[string]$New){
 if(([regex]::Matches($Source,[regex]::Escape($Old))).Count -ne 1){throw 'SSIS_CURRENT_QUALIFICATION_DERIVATION_ANCHOR'}
 return $Source.Replace($Old,$New)
}
if($QualificationPhase -ceq 'Full'){
Write-Output 'SSIS_CURRENT_QUALIFICATION_PHASE_CURRENT'
& (Join-Path $PSScriptRoot 'Invoke-CurrentCases.ps1') -Connection $Connection -CrossDatabase $CrossDatabase -FixtureModuleRoot $FixtureModuleRoot
Write-Output 'SSIS_CURRENT_QUALIFICATION_PHASE_SEMANTICS'
$long=([int](Query $Connection 'SELECT compatibility_level AS C FROM sys.databases WHERE database_id=DB_ID();').Rows[0].C -eq 170)
& (Join-Path $PSScriptRoot 'Invoke-CurrentQualificationCases.ps1') -Connection $Connection -CrossDatabase $CrossDatabase -LongPlan:$long
}

# Die Clientmetadaten-Orakel sind unverändert; Parameterzahl und bigint-
# Speicherbreite folgen dem heutigen 38-Parameter-Vertrag statt dem alten 14er.
Write-Output 'SSIS_CURRENT_QUALIFICATION_PHASE_API'
$api=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Invoke-ApiCases.ps1'))
$api=Replace-QualificationAnchor $api '($table.Rows.Count -eq 14)' '($table.Rows.Count -eq $api.parameters.Count)'
$api=Replace-QualificationAnchor $api "'int'{4};default" "'int'{4};'bigint'{8};default"
$api=Bind-CurrentScriptRoot -Text $api -Root $PSScriptRoot
. ([scriptblock]::Create($api)) -Connection $Connection

# Die historischen Rechteorakel verwenden weiterhin denselben isolierten
# loginlosen Principal. Der alte 16-MiB-Fall wird ausdrücklich über den heutigen
# SQL-Limitparameter eingestellt. Quell-SELECT wird im tatsächlichen heutigen
# Plan geprüft; eine vorgeschaltete Plan-State-Abweisung wäre kein Rechtebeleg.
Write-Output 'SSIS_CURRENT_QUALIFICATION_PHASE_RIGHTS'
$rights=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Invoke-ReleaseRightsCases.ps1'))
$fixtureAnchor='$package=[IO.File]::ReadAllBytes((Join-Path $moduleRoot ''Tests/Fixtures/synthetic-8.dtsx''))'
$fixtureReplacement=@'
$package=[IO.File]::ReadAllBytes((Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
[xml]$ports=[Text.Encoding]::UTF8.GetString($package)
foreach($component in $ports.SelectNodes('//component[@name="Derived" or @name="Split"]')){
 $input=$component.SelectSingleNode('inputs/input').GetAttribute('refId')
 foreach($port in $component.SelectNodes('outputs/output')){$port.SetAttribute('synchronousInputId',$input)}
}
$package=[Text.Encoding]::UTF8.GetBytes($ports.OuterXml)
'@
$rights=Replace-QualificationAnchor $rights $fixtureAnchor $fixtureReplacement
$rights=Replace-QualificationAnchor $rights ' return $c' " [void]`$c.Parameters.Add('@MaxPackageBytes',[Data.SqlDbType]::BigInt);`$c.Parameters['@MaxPackageBytes'].Value=[long]16777216`n return `$c"
$old='foreach($sourceStage in $stage){Denied {Sql ([string]$sourceStage.Content)} 229 ''''}'
$new=@'
foreach($sourceStage in $stage){
 $detail=([string]$sourceStage.DetailsJson)|ConvertFrom-Json -Depth 32
 $units=@($result.Rows|Where-Object {$_.ArtifactKind -ceq 'PlanUnitSql' -and (([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).planHash -ceq $detail.planHash)}|Sort-Object {([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).ordinal})
 $cleanup=@($result.Rows|Where-Object {$_.ArtifactKind -ceq 'CleanupSql' -and (([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).planHash -ceq $detail.planHash)}|Sort-Object {([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).cleanupOrdinal})
 Check ($units.Count -gt 0 -and $cleanup.Count -gt 0) 'CURRENT_SOURCE_PLAN_PRESENT'
 try{Denied {foreach($unit in $units){[void](Sql ([string]$unit.Content))}} 229 ''}
 finally{foreach($row in $cleanup){[void](Sql ([string]$row.Content))}}
}
'@
$rights=Replace-QualificationAnchor $rights $old $new
$rights=Bind-CurrentScriptRoot -Text $rights -Root $PSScriptRoot
& ([scriptblock]::Create($rights)) -Connection $Connection
Write-Output 'SSIS_CURRENT_QUALIFICATION_PHASE_LIFECYCLE'
& (Join-Path $PSScriptRoot 'Invoke-LifecycleCases.ps1') -Connection $Connection -Mode $Mode
if($QualificationPhase -ceq 'Full'){Write-Output 'SSIS_CURRENT_QUALIFICATION_ALL_PASS; no legacy API execution'}
else{Write-Output 'SSIS_CURRENT_QUALIFICATION_FOCUSED_PASS; API/rights/lifecycle only; not full qualification'}
