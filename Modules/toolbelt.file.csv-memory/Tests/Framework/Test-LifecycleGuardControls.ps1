# Offline-Negativkontrollen für das Abweisungsorakel; kein SQL/Labzugriff.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../Runtime/OwnershipGuards.Tests.ps1')
$checks=0
function Check([bool]$Condition){if(-not $Condition){throw 'CSV_GUARD_CONTROL_FAILED'};$script:checks++}
# Nur den tatsächlichen Parameter-AST ausführen, niemals den Labadapterkörper.
$driver=Join-Path $PSScriptRoot '../../../../Tests/CI/run-csv-memory-lab.ps1'
$parseErrors=$null
$driverTree=[Management.Automation.Language.Parser]::ParseFile($driver,[ref]$null,[ref]$parseErrors)
if($parseErrors.Count){throw 'CSV_GUARD_PARAMETER_PARSE'}
$parameters=@($driverTree.ParamBlock.Parameters|Where-Object {$_.Name.VariablePath.UserPath -ceq 'TestScope'})
if($parameters.Count -ne 1){throw 'CSV_GUARD_PARAMETER_IDENTITY'}
$validateScope=[scriptblock]::Create('param('+$parameters[0].Extent.Text+') $TestScope')
foreach($value in @('default','ownership-markers')){Check ((& $validateScope -TestScope $value) -ceq $value)}
foreach($value in @('DEFAULT','OWNERSHIP-MARKERS')){
 $caught=$false;try{& $validateScope -TestScope $value|Out-Null}catch{$caught=$true};Check $caught
}
$expected=[pscustomobject]@{Number=55324;State=5}
Check (Test-CsvGuardErrorIdentities @($expected) 55324 5)
Check (-not (Test-CsvGuardErrorIdentities @() 55324 5))
Check (-not (Test-CsvGuardErrorIdentities @($expected,$expected) 55324 5))
Check (-not (Test-CsvGuardErrorIdentities @([pscustomobject]@{Number=55325;State=5}) 55324 5))
Check (-not (Test-CsvGuardErrorIdentities @([pscustomobject]@{Number=55324;State=4}) 55324 5))
Check (-not (Test-CsvGuardErrorIdentities @([pscustomobject]@{Number='55324';State=5}) 55324 5))
Check (-not (Test-CsvGuardErrorIdentities @([pscustomobject]@{Number=55324;State='5'}) 55324 5))
foreach($mode in @('local','central')){
 $cases=@(Get-CsvMarkerGuardCases $mode)
 Check ($cases.Count -eq 10)
 Check (@($cases|Where-Object {$_.Original -ceq $_.Mutated}).Count -eq 0)
}
# Adapterfunktionen werden für sechs Fehlerwege durch synthetische Doubles ersetzt.
function Get-CsvSnapshot($Connection){$script:snapshots++;if($script:scenario -eq 'metadata' -and $script:snapshots -gt 1){return 'changed'};return 'baseline'}
function Get-CsvGuardErrorIdentities($Exception){if($script:scenario -eq 'wrong-error'){return [pscustomobject]@{Number=55324;State=4}};return [pscustomobject]@{Number=55324;State=5}}
function Invoke-CsvBatches($Connection,$Sql){if($script:scenario -ne 'no-error'){throw 'SYNTHETIC_REJECTION'}}
function Invoke-CsvSql($Connection,$Sql,[switch]$Rows){
 if($Sql -ceq 'SET NOCOUNT ON;SET XACT_ABORT ON;'){return}
 $script:states++
 if($script:scenario -eq 'transaction' -and $script:states -gt 1){throw 'SYNTHETIC_NONNEUTRAL_SESSION'}
 [pscustomobject]@{Options=$(if($script:scenario -eq 'options' -and $script:states -gt 1){2}else{1})}
}
foreach($scenario in @('pass','no-error','wrong-error','metadata','transaction','options')){
 $script:scenario=$scenario;$script:snapshots=0;$script:states=0;$caught=$false
 try{Assert-CsvGuardRejected $null 'synthetic' 55324 5 'baseline'}catch{$caught=$true}
 Check ($caught -eq ($scenario -ne 'pass'))
}
# Restaurierung darf fremde Drift nicht überschreiben; unveränderte eigene
# Mutationen müssen dagegen exakt auf die Baseline zurückkehren.
function Set-CsvGuardMarker($Connection,$Case,$Expected,$Value){$script:markerSets++}
function Assert-CsvGuardRejected($Connection,$Sql,$Number,$State,$Snapshot){$script:rejections++}
function Get-CsvSnapshot($Connection){
 $script:snapshots++
 $step=($script:snapshots-1)%4
 if($script:scenario -eq 'restore-drift' -and $step -eq 2){return 'foreign'}
 if($script:scenario -eq 'restore-mismatch' -and $step -eq 3){return 'different'}
 if($script:scenario -eq 'unobserved'){return 'baseline'}
 if($step -in @(0,3)){return 'baseline'};return 'mutated'
}
foreach($scenario in @('pass','restore-drift','restore-mismatch','unobserved')){
 $script:scenario=$scenario;$script:snapshots=0;$script:markerSets=0;$script:rejections=0;$caught=$false;$count=0
 try{$count=Invoke-CsvMarkerGuards $null 'synthetic-deploy' 'synthetic-uninstall' 'local'}catch{$caught=$true}
 Check ($caught -eq ($scenario -ne 'pass'))
 if($scenario -eq 'pass'){Check ($count -eq 20 -and $script:markerSets -eq 20 -and $script:rejections -eq 20)}
 if($scenario -eq 'restore-drift'){Check ($script:markerSets -eq 1)}
}
Write-Output ('PASS CSV_GUARD_ORACLE_CONTROLS CHECKS='+$checks+' SYNTHETIC_ONLY')
