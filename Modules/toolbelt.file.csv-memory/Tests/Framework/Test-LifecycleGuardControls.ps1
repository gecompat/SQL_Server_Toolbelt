# Offline-Negativkontrollen für das Abweisungsorakel; kein SQL/Labzugriff.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../Runtime/OwnershipGuards.Tests.ps1')
. (Join-Path $PSScriptRoot '../Runtime/ForeignGuards.Tests.ps1')
. (Join-Path $PSScriptRoot '../Runtime/MarkerAbsence.Tests.ps1')
. (Join-Path $PSScriptRoot '../Runtime/ForeignKinds.Tests.ps1')
. (Join-Path $PSScriptRoot '../Runtime/BindingDrift.Tests.ps1')
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
foreach($value in @('default','ownership-markers','foreign-slots','marker-absence','foreign-kinds','foreign-aliases','binding-drift','binding-defaults')){Check ((& $validateScope -TestScope $value) -ceq $value)}
foreach($value in @('DEFAULT','OWNERSHIP-MARKERS','FOREIGN-SLOTS','MARKER-ABSENCE','FOREIGN-KINDS','FOREIGN-ALIASES','BINDING-DRIFT','BINDING-DEFAULTS')){
 $caught=$false;try{& $validateScope -TestScope $value|Out-Null}catch{$caught=$true};Check $caught
}
$modeParameters=@($driverTree.ParamBlock.Parameters|Where-Object {$_.Name.VariablePath.UserPath -ceq 'DeploymentModes'})
if($modeParameters.Count -ne 1){throw 'CSV_GUARD_MODE_PARAMETER_IDENTITY'}
$validateModes=[scriptblock]::Create('param('+$modeParameters[0].Extent.Text+') $DeploymentModes -join '',''')
Check ((& $validateModes -DeploymentModes @('local')) -ceq 'local')
Check ((& $validateModes -DeploymentModes @('central')) -ceq 'central')
Check ((& $validateModes -DeploymentModes @('local','central')) -ceq 'local,central')
$caught=$false;try{& $validateModes -DeploymentModes @()|Out-Null}catch{$caught=$true};Check $caught
$caught=$false;try{& $validateModes -DeploymentModes $null|Out-Null}catch{$caught=$true};Check $caught
$caught=$false;try{& $validateModes -DeploymentModes @('local','central','local')|Out-Null}catch{$caught=$true};Check $caught
$caught=$false;try{& $validateModes -DeploymentModes @('unknown')|Out-Null}catch{$caught=$true};Check $caught
$slots=@(Get-CsvForeignSlotNames)
$kindCases=@(Get-CsvForeignKindCases)
$aliasCases=@(Get-CsvForeignKindCases 'synonym-function')
Check ($aliasCases.Count -eq 10)
Check (@($aliasCases|ForEach-Object {$_.Name+'|'+$_.Type}|Sort-Object -Unique).Count -eq 10)
foreach($case in @($aliasCases)+@((Get-CsvAliasTargetCase))){$caught=$false;try{Assert-CsvForeignKindCase $case}catch{$caught=$true};Check (-not $caught)}
$caught=$false;try{Get-CsvForeignKindCases 'SYNONYM-FUNCTION'|Out-Null}catch{$caught=$true};Check $caught
foreach($field in @('Name','Type','Kind','Sql','Read')){
 $case=$aliasCases[0].PSObject.Copy();$case.$field='invalid'
 $caught=$false;try{Assert-CsvForeignKindCase $case}catch{$caught=$true};Check $caught
}
$targetBytes=[Text.Encoding]::Unicode.GetBytes('[toolbelt_file].[CsvGuardAliasTarget]')
Check (Test-CsvAliasTarget @([pscustomobject]@{TargetBytes=$targetBytes}))
Check (-not (Test-CsvAliasTarget @()))
Check (-not (Test-CsvAliasTarget @([pscustomobject]@{TargetBytes=$targetBytes},[pscustomobject]@{TargetBytes=$targetBytes})))
Check (-not (Test-CsvAliasTarget @([pscustomobject]@{TargetBytes=[Text.Encoding]::Unicode.GetBytes('toolbelt_file.Other')})))
Check (-not (Test-CsvAliasTarget @([pscustomobject]@{TargetBytes=[Text.Encoding]::Unicode.GetBytes('toolbelt_file.CsvGuardAliasTarget')})))
Check (-not (Test-CsvAliasTarget @([pscustomobject]@{TargetBytes=[Text.Encoding]::Unicode.GetBytes('toolbelt_file.CsvGuardAliasTarget ')})))
Check (-not (Test-CsvAliasTarget @([pscustomobject]@{TargetBytes=[Convert]::ToHexString($targetBytes)})))
Check (-not (Test-CsvAliasTarget @([pscustomobject]@{TargetBytes=[DBNull]::Value})))
Check (-not (Test-CsvAliasTarget @([pscustomobject]@{TargetBytes=$targetBytes;Extra=1})))
Check ($kindCases.Count -eq 10)
Check (@($kindCases|ForEach-Object {$_.Name+'|'+$_.Type}|Sort-Object -Unique).Count -eq 10)
foreach($case in $kindCases){$caught=$false;try{Assert-CsvForeignKindCase $case}catch{$caught=$true};Check (-not $caught)}
foreach($field in @('Name','Type','Kind','Sql','Read')){
 $case=$kindCases[0].PSObject.Copy();$case.$field='invalid'
 $caught=$false;try{Assert-CsvForeignKindCase $case}catch{$caught=$true};Check $caught
}
$good=[pscustomobject][ordered]@{Marker=[int]73;Payload='guard '}
Check (Test-CsvForeignKindResult @($good))
Check (-not (Test-CsvForeignKindResult @()))
Check (-not (Test-CsvForeignKindResult @($good,$good)))
Check (-not (Test-CsvForeignKindResult @([pscustomobject]@{Marker=73;Payload='guard ';Extra=1})))
Check (-not (Test-CsvForeignKindResult @([pscustomobject]@{Marker='73';Payload='guard '})))
Check (-not (Test-CsvForeignKindResult @([pscustomobject]@{Marker=73;Payload='guard'})))
Check (-not (Test-CsvForeignKindResult @([pscustomobject]@{Marker=73;Payload='GUARD '})))
Check (-not (Test-CsvForeignKindResult @([pscustomobject]@{Marker=73;Payload=[DBNull]::Value})))
Check (-not (Test-CsvForeignKindResult @([pscustomobject]@{Marker=73})))
Check (-not (Test-CsvForeignKindResult @([pscustomobject][ordered]@{Payload='guard ';Marker=73})))
Check (-not (Test-CsvForeignKindResult @([pscustomobject]@{Marker=74;Payload='guard '})))
Check (-not (Test-CsvForeignKindResult @($null)))
Check (-not (Test-CsvForeignKindResult $null))
foreach($mode in @('local','central')){
 $absenceCases=@(Get-CsvMarkerAbsenceCases $mode)
 Check ($absenceCases.Count -eq 27)
 Check (@($absenceCases|ForEach-Object {$_.Scope+'|'+$_.Object+'|'+$_.Property}|Sort-Object -Unique).Count -eq 27)
 foreach($case in $absenceCases){$caught=$false;try{$location=Get-CsvMarkerAbsenceLocation $case}catch{$caught=$true};Check (-not $caught)}
}
foreach($field in @('Scope','Object','Property','Original','State')){
 $case=(Get-CsvMarkerAbsenceCases 'local'|Select-Object -First 1).PSObject.Copy()
 $case.$field=if($field -ceq 'State'){9}else{'invalid'}
 $caught=$false;try{Get-CsvMarkerAbsenceLocation $case|Out-Null}catch{$caught=$true};Check $caught
}
Check ($slots.Count -eq 5)
Check (@($slots|Sort-Object -Unique).Count -eq 5)
foreach($case in @(@('TABLE','USP_ParseCsv'),@('PROCEDURE','USP_CsvGuardSqlConsumer'),@('FUNCTION','SVF_CsvGuardClrConsumer'))){
 $caught=$false;try{Assert-CsvGuardFixtureName $case[0] $case[1]}catch{$caught=$true};Check (-not $caught)
}
foreach($case in @(@('TABLE','Unknown'),@('PROCEDURE','USP_ParseCsv'),@('FUNCTION','USP_CsvGuardSqlConsumer'))){
 $caught=$false;try{Assert-CsvGuardFixtureName $case[0] $case[1]}catch{$caught=$true};Check $caught
}
$hash='A'*64
Check (Test-CsvForeignWitness $hash $hash)
Check (-not (Test-CsvForeignWitness $hash ('B'*64)))
Check (-not (Test-CsvForeignWitness $hash ('a'*64)))
Check (-not (Test-CsvForeignWitness '' ''))
Check (-not (Test-CsvForeignWitness ('-'*64) ('-'*64)))
Check (-not (Test-CsvForeignWitness $null $hash))
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
$bindingCases=@(Get-CsvBindingDriftCases)
$defaultCases=@(Get-CsvBindingDriftCases 'defaults')
$moduleRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Check ($bindingCases.Count -eq 8 -and @($bindingCases.Id|Sort-Object -Unique).Count -eq 8)
Check ($defaultCases.Count -eq 5 -and @($defaultCases.Id|Sort-Object -Unique).Count -eq 5)
$caught=$false;try{Get-CsvBindingDriftCases 'DEFAULTS'|Out-Null}catch{$caught=$true};Check $caught
foreach($case in @($bindingCases)+@($defaultCases)){
 $source=[IO.File]::ReadAllText((Join-Path $moduleRoot ('Source/'+$case.Name+'.sql')))
 $mutate=New-CsvBindingDriftSql $source $case
 $restore=New-CsvBindingDriftSql $source $case -Restore
 Check ($mutate -cne $restore -and $mutate.StartsWith('ALTER FUNCTION ') -and $restore.StartsWith('ALTER FUNCTION '))
}
foreach($field in @('Id','Name','Method','Kind','Needle','Replacement','State','Probe')){
 foreach($original in @($bindingCases[0],$defaultCases[0])){
  $case=$original.PSObject.Copy();$case.$field=if($field -ceq 'State'){9}else{'invalid'}
  $caught=$false;try{New-CsvBindingDriftSql 'synthetic' $case|Out-Null}catch{$caught=$_.Exception.Message -ceq 'CSV_BINDING_CASE_INVALID'};Check $caught
 }
}
$case=$bindingCases[0]
$source=[IO.File]::ReadAllText((Join-Path $moduleRoot ('Source/'+$case.Name+'.sql')))
foreach($invalidSource in @($source.Replace($case.Needle,'invalid'),($source+$source),$source.Replace($case.Name,'Unknown'))){
 $caught=$false;try{New-CsvBindingDriftSql $invalidSource $case|Out-Null}catch{$caught=$true};Check $caught
}
$witness=[pscustomobject]@{Witness=[int]1}
Check (Test-CsvBindingDriftWitness @($witness))
foreach($rows in @(@(),@($witness,$witness),@([pscustomobject]@{Other=1}),@([pscustomobject]@{Witness=1;Extra=1}),@([pscustomobject]@{Witness='1'}),@([pscustomobject]@{Witness=0}),@([pscustomobject]@{Witness=[DBNull]::Value}),@($null))){Check (-not (Test-CsvBindingDriftWitness $rows))}
Check (-not (Test-CsvBindingDriftWitness $null))
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
function Set-CsvMarkerPresence($Connection,$Case,$Action){$script:presenceSets++}
foreach($scenario in @('pass','restore-drift','restore-mismatch','unobserved')){
 $script:scenario=$scenario;$script:snapshots=0;$script:presenceSets=0;$script:rejections=0;$caught=$false;$count=0
 try{$count=Invoke-CsvMarkerAbsenceGuards $null 'synthetic-deploy' 'synthetic-uninstall' 'local'}catch{$caught=$true}
 Check ($caught -eq ($scenario -ne 'pass'))
 if($scenario -eq 'pass'){Check ($count -eq 54 -and $script:presenceSets -eq 54 -and $script:rejections -eq 54)}
 if($scenario -eq 'restore-drift'){Check ($script:presenceSets -eq 1)}
}
# Echte Dropfunktion: Identitätsdrift muss vor jedem SQL-Batch abbrechen.
function Invoke-CsvSql($Connection,$Sql){$script:kindSql++}
function Get-CsvForeignKindIdentity($Connection,$Case){[pscustomobject]@{Id=20;Created=('A'*18)}}
foreach($identity in @([pscustomobject]@{Id=19;Created=('A'*18)},[pscustomobject]@{Id=20;Created=('B'*18)})){
 $script:kindSql=0;$caught=$false
 try{Remove-CsvForeignKind $null $kindCases[0] $identity}catch{$caught=$true}
 Check ($caught -and $script:kindSql -eq 0)
}
function Invoke-CsvBatches($Connection,$Sql){}
function Add-CsvForeignKindOwner($Connection,$Case){[pscustomobject]@{Id=20;Created=('A'*18)}}
function Remove-CsvForeignKind($Connection,$Case,$Identity){$script:kindDrops++}
function Assert-CsvForeignKindWitness($Connection,$Case){
 $script:kindWitnesses++
 if($script:scenario -ceq 'witness-drift' -and $script:kindWitnesses -gt 1){throw 'SYNTHETIC_KIND_WITNESS_CHANGED'}
}
function Get-CsvSnapshot($Connection){
 $script:snapshots++
 if($script:snapshots -eq 1){return 'clean'}
 $step=($script:snapshots-2)%4
 if($script:scenario -ceq 'drop-drift' -and $step -eq 2){return 'foreign'}
 if($script:scenario -ceq 'restore-mismatch' -and $step -eq 3){return 'different'}
 if($script:scenario -ceq 'unobserved' -and $step -eq 1){return 'clean'}
 if($step -in @(0,3)){return 'clean'};return 'mutated'
}
foreach($scenario in @('pass','drop-drift','restore-mismatch','unobserved','witness-drift')){
 $script:scenario=$scenario;$script:snapshots=0;$script:kindDrops=0;$script:kindWitnesses=0;$script:rejections=0;$caught=$false;$count=0
 try{$count=Invoke-CsvForeignKindGuards $null 'synthetic-deploy' 'synthetic-uninstall' 'local'}catch{$caught=$true}
 Check ($caught -eq ($scenario -cne 'pass'))
 if($scenario -ceq 'pass'){Check ($count -eq 20 -and $script:kindDrops -eq 10 -and $script:rejections -eq 20)}
 if($scenario -cin @('drop-drift','witness-drift')){Check ($script:kindDrops -eq 0)}
}
# Ein gescheiterter Alias-Witness muss seine Diagnose bis zum OwnDB-Cleanup
# behalten; ein weiterer Target-Cleanup würde hier gezielt anders scheitern.
function Get-CsvSnapshot($Connection){
 $script:aliasSnapshots++
 switch($script:aliasSnapshots){1{'outer'};2{'clean-target'};3{'clean-target'};4{'fixture'};5{'fixture'};default{throw 'SYNTHETIC_ALIAS_MASKED'}}
}
function Assert-CsvForeignKindWitness($Connection,$Case){if($Case.Name -cne 'CsvGuardAliasTarget'){throw 'SYNTHETIC_ALIAS_ORIGINAL'}}
$script:aliasSnapshots=0;$script:kindDrops=0;$caught=$false
try{Invoke-CsvForeignKindGuards $null 'synthetic-deploy' 'synthetic-uninstall' 'local' -Family 'synonym-function'|Out-Null}catch{$caught=$_.Exception.Message -ceq 'SYNTHETIC_ALIAS_ORIGINAL'}
Check ($caught -and $script:kindDrops -eq 0 -and $script:aliasSnapshots -eq 5)
# Tatsächliche Restaurierungssteuerung mit synthetischen SQL-/Kataloggrenzen.
# Fremde Snapshots und ausgetauschte Objektidentitäten erlauben kein ALTER.
function Invoke-CsvSql($Connection,$Sql){$script:bindingSql++}
function Get-CsvBindingDriftIdentity($Connection,$Case){
 $script:bindingIdentities++
 [pscustomobject]@{Id=$(if($script:scenario -ceq 'identity-drift' -and $script:bindingIdentities -gt 1){74}else{73});Created=('A'*18)}
}
function Assert-CsvBindingDriftWitness($Connection,$Case){
 $script:bindingWitnesses++
 if($script:scenario -ceq 'witness-drift' -and $script:bindingWitnesses -gt 1){throw 'SYNTHETIC_BINDING_WITNESS_DRIFT'}
}
function Get-CsvSnapshot($Connection){
 $script:snapshots++;$step=($script:snapshots-1)%4
 if($script:scenario -ceq 'restore-drift' -and $step -eq 2){return 'foreign'}
 if($script:scenario -ceq 'restore-mismatch' -and $step -eq 3){return 'different'}
 if($script:scenario -ceq 'unobserved'){return 'baseline'}
 if($step -in @(0,3)){return 'baseline'};return 'mutated'
}
foreach($scenario in @('pass','restore-drift','restore-mismatch','unobserved','identity-drift','witness-drift')){
 $script:scenario=$scenario;$script:snapshots=0;$script:bindingSql=0;$script:bindingIdentities=0;$script:bindingWitnesses=0;$script:rejections=0;$caught=$false;$count=0
 try{$count=Invoke-CsvBindingDriftGuards $null 'synthetic-deploy' 'synthetic-uninstall' $moduleRoot 'local'}catch{$caught=$true}
 Check ($caught -eq ($scenario -cne 'pass'))
 if($scenario -ceq 'pass'){Check ($count -eq 16 -and $script:bindingSql -eq 16 -and $script:rejections -eq 16 -and $script:bindingWitnesses -eq 32)}
 if($scenario -cin @('restore-drift','unobserved','identity-drift','witness-drift')){Check ($script:bindingSql -eq 1)}
}
$script:scenario='pass';$script:snapshots=0;$script:bindingSql=0;$script:bindingIdentities=0;$script:bindingWitnesses=0;$script:rejections=0
$count=Invoke-CsvBindingDriftGuards $null 'synthetic-deploy' 'synthetic-uninstall' $moduleRoot 'local' -Family 'defaults'
Check ($count -eq 10 -and $script:bindingSql -eq 10 -and $script:rejections -eq 10 -and $script:bindingWitnesses -eq 20)
Write-Output ('PASS CSV_GUARD_ORACLE_CONTROLS CHECKS='+$checks+' SYNTHETIC_ONLY')
