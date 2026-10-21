# Offline-Negativkontrollen für das Abweisungsorakel; kein SQL/Labzugriff.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../Runtime/OwnershipGuards.Tests.ps1')
. (Join-Path $PSScriptRoot '../Runtime/ForeignGuards.Tests.ps1')
. (Join-Path $PSScriptRoot '../Runtime/MarkerAbsence.Tests.ps1')
. (Join-Path $PSScriptRoot '../Runtime/ForeignKinds.Tests.ps1')
. (Join-Path $PSScriptRoot '../Runtime/BindingDrift.Tests.ps1')
. (Join-Path $PSScriptRoot '../Runtime/NamedConsumers.Tests.ps1')
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
foreach($value in @('default','ownership-markers','foreign-slots','marker-absence','foreign-kinds','foreign-aliases','foreign-table-functions','binding-drift','binding-defaults','named-consumers','marker-values','binding-execution')){Check ((& $validateScope -TestScope $value) -ceq $value)}
foreach($value in @('DEFAULT','OWNERSHIP-MARKERS','FOREIGN-SLOTS','MARKER-ABSENCE','FOREIGN-KINDS','FOREIGN-ALIASES','FOREIGN-TABLE-FUNCTIONS','BINDING-DRIFT','BINDING-DEFAULTS','NAMED-CONSUMERS','MARKER-VALUES','BINDING-EXECUTION')){
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
$tableCases=@(Get-CsvForeignKindCases 'table-functions')
Check ($tableCases.Count -eq 10)
Check (@($tableCases|ForEach-Object {$_.Name+'|'+$_.Kind}|Sort-Object -Unique).Count -eq 10)
Check (@($tableCases|Where-Object Kind -CEQ 'IF').Count -eq 5)
Check (@($tableCases|Where-Object Kind -CEQ 'TF').Count -eq 5)
foreach($case in $tableCases){$caught=$false;try{Assert-CsvForeignKindCase $case}catch{$caught=$true};Check (-not $caught)}
$caught=$false;try{Get-CsvForeignKindCases 'TABLE-FUNCTIONS'|Out-Null}catch{$caught=$true};Check $caught
foreach($original in $tableCases[0..1]){
 foreach($field in @('Name','Type','Kind','Sql','Read')){
  $case=$original.PSObject.Copy();$case.$field='invalid'
  $caught=$false;try{Assert-CsvForeignKindCase $case}catch{$caught=$true};Check $caught
 }
}
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
 $valueCases=@(Get-CsvMarkerGuardCases $mode 'values')
 Check ($valueCases.Count -eq 25 -and @($valueCases|ForEach-Object {$_.Scope+'|'+$_.Object+'|'+$_.Property}|Sort-Object -Unique).Count -eq 25)
 foreach($case in $valueCases){$caught=$false;try{Assert-CsvMarkerGuardCase $case}catch{$caught=$true};Check (-not $caught)}
}
$caught=$false;try{Get-CsvMarkerGuardCases 'local' 'VALUES'|Out-Null}catch{$caught=$true};Check $caught
foreach($field in @('Scope','Object','Property','Original','Mutated','State')){
 $case=$valueCases[0].PSObject.Copy();$case.$field=if($field -ceq 'State'){'5'}else{'invalid'}
 $caught=$false;try{Assert-CsvMarkerGuardCase $case}catch{$caught=$true};Check $caught
}
function Invoke-CsvSql($Connection,$Sql,$Parameters){$script:markerTransitionSql++}
$script:markerTransitionSql=0;$case=$valueCases[0]
Set-CsvGuardMarker $null $case $case.Original $case.Mutated
Set-CsvGuardMarker $null $case $case.Mutated $case.Original
Check ($script:markerTransitionSql -eq 2)
foreach($transition in @(@($case.Original,$case.Original),@('invalid',$case.Mutated),@($case.Original,'invalid'))){
 $caught=$false;try{Set-CsvGuardMarker $null $case $transition[0] $transition[1]}catch{$caught=$true};Check ($caught -and $script:markerTransitionSql -eq 2)
}
$bindingCases=@(Get-CsvBindingDriftCases)
$defaultCases=@(Get-CsvBindingDriftCases 'defaults')
$executionCases=@(Get-CsvBindingDriftCases 'execution')
$moduleRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Check ($bindingCases.Count -eq 8 -and @($bindingCases.Id|Sort-Object -Unique).Count -eq 8)
Check ($defaultCases.Count -eq 5 -and @($defaultCases.Id|Sort-Object -Unique).Count -eq 5)
$caught=$false;try{Get-CsvBindingDriftCases 'DEFAULTS'|Out-Null}catch{$caught=$true};Check $caught
Check ($executionCases.Count -eq 3 -and @($executionCases.Id|Sort-Object -Unique).Count -eq 3)
$caught=$false;try{Get-CsvBindingDriftCases 'EXECUTION'|Out-Null}catch{$caught=$true};Check $caught
foreach($case in @($bindingCases)+@($defaultCases)+@($executionCases)){
 $source=[IO.File]::ReadAllText((Join-Path $moduleRoot ('Source/'+$case.Name+'.sql')))
 $mutate=New-CsvBindingDriftSql $source $case
 $restore=New-CsvBindingDriftSql $source $case -Restore
 Check ($mutate -cne $restore -and $mutate.StartsWith('ALTER FUNCTION ') -and $restore.StartsWith('ALTER FUNCTION '))
}
foreach($field in @('Id','Name','Method','Kind','Needle','Replacement','State','Probe')){
 foreach($original in @($bindingCases[0],$defaultCases[0],$executionCases[0])){
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
$namedCases=@(Get-CsvNamedConsumerCases);$namedDatabase='Toolbelt_CsvTypes_'+('a'*32)
Check ($namedCases.Count -eq 5 -and @($namedCases.Name|Sort-Object -Unique).Count -eq 5)
foreach($case in $namedCases){Check ((New-CsvNamedConsumerSql $namedDatabase $case).StartsWith('CREATE PROCEDURE toolbelt_file.USP_CsvGuardSqlConsumer AS '))}
foreach($field in @('Name','Reference')){
 $case=$namedCases[0].PSObject.Copy();$case.$field='invalid';$caught=$false
 try{New-CsvNamedConsumerSql $namedDatabase $case|Out-Null}catch{$caught=$_.Exception.Message -ceq 'CSV_NAMED_CASE_INVALID'};Check $caught
}
foreach($database in @('AdventureWorks',($namedDatabase+' '),($namedDatabase+'];DROP TABLE x;--'),$namedDatabase.ToUpperInvariant())){
 $caught=$false;try{New-CsvNamedConsumerSql $database $namedCases[0]|Out-Null}catch{$caught=$true};Check $caught
}
Check (Test-CsvNamedWitness @([pscustomobject]@{Witness=[int]1}))
foreach($rows in @(@(),@($witness,$witness),@([pscustomobject]@{Other=1}),@([pscustomobject]@{Witness=1;Extra=1}),@([pscustomobject]@{Witness='1'}),@([pscustomobject]@{Witness=0}),@([pscustomobject]@{Witness=[DBNull]::Value}),@($null))){Check (-not (Test-CsvNamedWitness $rows))}
Check (-not (Test-CsvNamedWitness $null))
$namedEntry=[pscustomobject]@{Name=$namedDatabase;State='OWNED';Marker=$true;Id=[int]73;Creation=('A'*18)}
$namedConnection=[pscustomobject]@{Database=$namedDatabase}
$script:ledger=[pscustomobject]@{RunId=('a'*32);Databases=@($namedEntry)}
Check ((Get-CsvNamedDatabaseEntry $namedConnection $namedDatabase).Id -eq 73)
foreach($field in @('State','Marker','Id','Creation')){
 $entry=$namedEntry.PSObject.Copy();$entry.$field=if($field -ceq 'Marker'){'true'}else{'invalid'}
 $script:ledger.Databases=@($entry);$caught=$false
 try{Get-CsvNamedDatabaseEntry $namedConnection $namedDatabase|Out-Null}catch{$caught=$true};Check $caught
}
foreach($entries in @(@(),@($namedEntry,$namedEntry))){
 $script:ledger.Databases=$entries;$caught=$false;try{Get-CsvNamedDatabaseEntry $namedConnection $namedDatabase|Out-Null}catch{$caught=$true};Check $caught
}
$script:ledger.Databases=@($namedEntry);$caught=$false
try{Get-CsvNamedDatabaseEntry ([pscustomobject]@{Database='AdventureWorks'}) $namedDatabase|Out-Null}catch{$caught=$true};Check $caught
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
$script:scenario='pass';$script:snapshots=0;$script:markerSets=0;$script:rejections=0
$count=Invoke-CsvMarkerGuards $null 'synthetic-deploy' 'synthetic-uninstall' 'local' -Family 'values'
Check ($count -eq 50 -and $script:markerSets -eq 50 -and $script:rejections -eq 50)
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
 if($script:scenario -ceq 'before-second' -and $script:kindWitnesses -ge 4){throw 'SYNTHETIC_KIND_PRE_SECOND_CHANGED'}
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
foreach($family in @('view-procedure','table-functions')){
foreach($scenario in @('pass','drop-drift','restore-mismatch','unobserved','witness-drift','before-second')){
 $script:scenario=$scenario;$script:snapshots=0;$script:kindDrops=0;$script:kindWitnesses=0;$script:rejections=0;$caught=$false;$count=0
 try{$count=Invoke-CsvForeignKindGuards $null 'synthetic-deploy' 'synthetic-uninstall' 'local' -Family $family}catch{$caught=$true}
 Check ($caught -eq ($scenario -cne 'pass'))
 if($scenario -ceq 'pass'){Check ($count -eq 20 -and $script:kindDrops -eq 10 -and $script:rejections -eq 20 -and $script:kindWitnesses -eq 60)}
 if($scenario -cin @('drop-drift','witness-drift')){Check ($script:kindDrops -eq 0)}
 if($scenario -ceq 'before-second'){Check ($script:rejections -eq 1 -and $script:kindDrops -eq 0)}
}
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
 if($script:scenario -ceq 'binding-pre-second-drift' -and $script:bindingWitnesses -ge 4){throw 'SYNTHETIC_BINDING_PRE_SECOND_DRIFT'}
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
 if($scenario -ceq 'pass'){Check ($count -eq 16 -and $script:bindingSql -eq 16 -and $script:rejections -eq 16 -and $script:bindingWitnesses -eq 48)}
 if($scenario -cin @('restore-drift','unobserved','identity-drift','witness-drift')){Check ($script:bindingSql -eq 1)}
}
$script:scenario='pass';$script:snapshots=0;$script:bindingSql=0;$script:bindingIdentities=0;$script:bindingWitnesses=0;$script:rejections=0
$count=Invoke-CsvBindingDriftGuards $null 'synthetic-deploy' 'synthetic-uninstall' $moduleRoot 'local' -Family 'defaults'
Check ($count -eq 10 -and $script:bindingSql -eq 10 -and $script:rejections -eq 10 -and $script:bindingWitnesses -eq 30)
$script:scenario='pass';$script:snapshots=0;$script:bindingSql=0;$script:bindingIdentities=0;$script:bindingWitnesses=0;$script:rejections=0
$count=Invoke-CsvBindingDriftGuards $null 'synthetic-deploy' 'synthetic-uninstall' $moduleRoot 'local' -Family 'execution'
Check ($count -eq 6 -and $script:bindingSql -eq 6 -and $script:rejections -eq 6 -and $script:bindingWitnesses -eq 18)
$script:scenario='binding-pre-second-drift';$script:snapshots=0;$script:bindingSql=0;$script:bindingIdentities=0;$script:bindingWitnesses=0;$script:rejections=0;$caught=$false
try{Invoke-CsvBindingDriftGuards $null 'synthetic-deploy' 'synthetic-uninstall' $moduleRoot 'local' -Family 'defaults'|Out-Null}catch{$caught=$true}
Check ($caught -and $script:rejections -eq 1 -and $script:bindingSql -eq 1)
# Der tatsächliche Dependency- und Dropablauf muss bei Katalog-/Identitätsdrift
# abbrechen. Die SQL-Grenze liefert ausschließlich synthetische Resultate.
function Assert-CsvNamedDatabase($Connection,$Database){}
function Get-CsvGuardFixtureIdentity($Connection,$Type,$Name){
 $script:namedIdentities++
 [pscustomobject]@{Id=$(if($script:scenario -ceq 'named-identity-drift' -and $script:namedIdentities -gt 1){21}else{20});Created=('A'*18)}
}
function Add-CsvGuardFixtureOwner($Connection,$Type,$Name){[pscustomobject]@{Id=20;Created=('A'*18)}}
function Invoke-CsvSql($Connection,$Sql,$Parameters,[switch]$Rows){
 if($Sql -ceq (Get-CsvNamedDependencyWitnessSql)){
  $script:namedWitnesses++
  if($script:scenario -ceq 'named-dependency-drift' -and $script:namedWitnesses -gt 1){return [pscustomobject]@{Witness=('B'*64)}}
  if($script:scenario -ceq 'named-pre-second-drift' -and $script:namedWitnesses -ge 4){return [pscustomobject]@{Witness=('B'*64)}}
  return [pscustomobject]@{Witness=('A'*64)}
 }
 if($Sql.StartsWith('CREATE PROCEDURE ')){$script:namedCreates++}
 if($Sql.Contains('DROP PROCEDURE toolbelt_file.[')){$script:namedDrops++}
}
function Get-CsvSnapshot($Connection){
 $script:snapshots++;if($script:snapshots -eq 1){return 'baseline'}
 $step=($script:snapshots-2)%4
 if($script:scenario -ceq 'named-drop-drift' -and $step -eq 2){return 'foreign'}
 if($script:scenario -ceq 'named-restore-mismatch' -and $step -eq 3){return 'different'}
 if($script:scenario -ceq 'named-unobserved'){return 'baseline'}
 if($step -in @(0,3)){return 'baseline'};return 'mutated'
}
foreach($scenario in @('pass','named-drop-drift','named-restore-mismatch','named-unobserved','named-dependency-drift','named-identity-drift','named-pre-second-drift')){
 $script:scenario=$scenario;$script:snapshots=0;$script:namedIdentities=0;$script:namedWitnesses=0;$script:namedCreates=0;$script:namedDrops=0;$script:rejections=0;$caught=$false;$count=0
 try{$count=Invoke-CsvNamedConsumerGuards $namedConnection 'synthetic-deploy' 'synthetic-uninstall' $namedDatabase 'local'}catch{$caught=$true}
 Check ($caught -eq ($scenario -cne 'pass'))
 if($scenario -ceq 'pass'){Check ($count -eq 10 -and $script:rejections -eq 10 -and $script:namedCreates -eq 5 -and $script:namedDrops -eq 5 -and $script:namedWitnesses -eq 30)}
 if($scenario -cin @('named-drop-drift','named-unobserved','named-dependency-drift','named-identity-drift','named-pre-second-drift')){Check ($script:namedDrops -eq 0)}
 if($scenario -ceq 'named-pre-second-drift'){Check ($script:rejections -eq 1)}
}
Write-Output ('PASS CSV_GUARD_ORACLE_CONTROLS CHECKS='+$checks+' SYNTHETIC_ONLY')
