# SQL-freie Zulassung und Ausführung der originalen Helper mit synthetischem DAL.
param([Parameter(Mandatory)][string]$RunsetPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $PSScriptRoot 'Xlsx.LifecycleNegative.Workload.ps1')
$runset=Get-Content $RunsetPath -Raw|ConvertFrom-Json
Assert-XlsxLifecycleNegativeInputs $runset $repo
$deploy=[IO.File]::ReadAllText($runset.lifecycle_negative.install.local)
$uninstall=[IO.File]::ReadAllText($runset.lifecycle_negative.uninstall)
foreach($kind in @('missing-helper-pin','wrong-fixture')){
    $probe=$runset|ConvertTo-Json -Depth 12|ConvertFrom-Json
    if($kind -ceq 'missing-helper-pin'){
        $helper=Join-Path $repo 'Tests/CI/run-xlsx-types-lab.ps1'
        $probe.pins=@($probe.pins|Where-Object path -CNE $helper)
    }else{$probe.workbooks[0].name='Other.sql'}
    $caught=$false;try{Assert-XlsxLifecycleNegativeInputs $probe $repo}catch{$caught=$true}
    if(-not $caught){throw 'XLSX_LIFECYCLE_BAD_ADMISSION_ACCEPTED'}
}
foreach($kind in @('drop','commit','visibility','macro')){
    $text=switch($kind){
        'drop' {$deploy+"`n DROP FUNCTION IF EXISTS toolbelt_file.TVF_InterpretXlsxCell;"}
        'commit' {$deploy+"`n COMMIT TRANSACTION;"}
        'visibility' {$deploy+"`n HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION')"}
        'macro' {$deploy+'$(Unbound)'}
    }
    $caught=$false;try{Assert-XlsxLifecycleNegativeSeams $text $uninstall}catch{$caught=$true}
    if(-not $caught){throw 'XLSX_LIFECYCLE_BAD_SEAM_ACCEPTED'}
}

# Echter neuer Holder-Adapter: nur die eigene aktive DB, derselbe Runset-Client.
$script:ledger=@{databases=@(@{name='ContosoOwned';state='OWNED'})}
function Open-ReleaseConnection([string]$Database){return $Database}
if((Open-XlsxConnection $null 'ContosoOwned') -cne 'ContosoOwned'){throw 'XLSX_LIFECYCLE_HOLDER_ROUTING'}
$caught=$false;try{Open-XlsxConnection $null 'Other'}catch{$caught=$true}
if(-not $caught){throw 'XLSX_LIFECYCLE_UNOWNED_HOLDER_ACCEPTED'}

# Ab hier ausschließlich kontrollierte Testdoubles; kein SQL-/Providerzugriff.
$script:negativeCalls=[Collections.Generic.List[object]]::new()
$script:sqlCalls=[Collections.Generic.List[string]]::new()
function Get-XlsxSnapshot($Connection){return 'ContosoStableSnapshot'}
function Invoke-XlsxSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    $script:sqlCalls.Add($Sql)
    if($Rows){return [pscustomobject]@{TranCount=0;TranState=0}}
}
function Assert-XlsxRejected($Connection,[string]$Sql,[int]$Number){
    $script:negativeCalls.Add(@{text=$Sql;number=$Number})
}
Assert-XlsxRollbackPrepared $null $deploy $uninstall
if($script:negativeCalls.Count -ne 4 -or @($script:negativeCalls|Where-Object number -NE 51592).Count -or
   @($script:negativeCalls|Where-Object {$_.text.Contains('Synthetic postDROP fault.')}).Count -ne 2 -or
   @($script:negativeCalls|Where-Object {$_.text.Contains('Synthetic preCOMMIT fault.')}).Count -ne 2){
    throw 'XLSX_LIFECYCLE_ORIGINAL_ROLLBACK_SET'
}
$script:holder=[pscustomobject]@{State=[Data.ConnectionState]::Open;DisposeCount=0}
$script:holder|Add-Member -MemberType ScriptMethod -Name Dispose -Value {
    $this.DisposeCount++;$this.State=[Data.ConnectionState]::Closed
}
function Open-XlsxConnection($Target,[string]$Database){return $script:holder}
$script:negativeCalls.Clear();$script:sqlCalls.Clear()
Assert-XlsxLockPrepared $null 'ContosoOwned' $null $deploy $uninstall
if($script:negativeCalls.Count -ne 2 -or @($script:negativeCalls|Where-Object number -NE 51533).Count -or
   $script:holder.DisposeCount -ne 1 -or @($script:sqlCalls|Where-Object {$_ -ceq 'IF @@TRANCOUNT>0 ROLLBACK;'}).Count -ne 1){
    throw 'XLSX_LIFECYCLE_ORIGINAL_LOCK_SET_OR_CLEANUP'
}
# Fehler während des Locks muss trotzdem Rollback und Dispose erreichen.
$script:holder.State=[Data.ConnectionState]::Open;$script:sqlCalls.Clear()
function Assert-XlsxRejected($Connection,[string]$Sql,[int]$Number){throw 'Synthetic mock refusal'}
$caught=$false;try{Assert-XlsxLockPrepared $null 'ContosoOwned' $null $deploy $uninstall}catch{$caught=$true}
if(-not $caught -or $script:holder.DisposeCount -ne 2 -or
   @($script:sqlCalls|Where-Object {$_ -ceq 'IF @@TRANCOUNT>0 ROLLBACK;'}).Count -ne 1){throw 'XLSX_LIFECYCLE_HOLDER_FAILURE_CLEANUP'}

$script:visibilityCalls=[Collections.Generic.List[string]]::new();$script:mockState=2
function Invoke-XlsxBatches($Connection,[string]$Sql){$script:visibilityCalls.Add($Sql);throw 'Synthetic mock denial'}
function Get-XlsxFailure($Exception){return @{SqlNumber=51535;SqlState=$script:mockState}}
Assert-XlsxVisibilityPrepared $null $deploy $uninstall
if($script:visibilityCalls.Count -ne 16 -or @($script:visibilityCalls|Sort-Object -Unique).Count -ne 16){
    throw 'XLSX_LIFECYCLE_ORIGINAL_VISIBILITY_SET'
}
$script:mockState=3;$caught=$false
try{Assert-XlsxVisibilityPrepared $null $deploy $uninstall}catch{$caught=$true}
if(-not $caught){throw 'XLSX_LIFECYCLE_WRONG_ERROR_STATE_ACCEPTED'}

# Vollständiger neuer Adapter: Journalmutationen und kein PASS nach Kinderfehler.
$script:runset=$runset;$script:case=$runset.cases[0]
$script:ledger=@{lifecycleNegatives=@()};$script:journalWrites=0;$script:neutralCalls=0
$script:holder.State=[Data.ConnectionState]::Open;$script:mockState=2
$script:negativeCalls.Clear();$script:visibilityCalls.Clear()
function Save-ReleaseJournal {$script:journalWrites++}
function Assert-XlsxFullSizeNeutral($Connection){$script:neutralCalls++}
function Assert-XlsxRejected($Connection,[string]$Sql,[int]$Number){
    $script:negativeCalls.Add(@{text=$Sql;number=$Number})
}
$fakeConnection=[pscustomobject]@{Database='ContosoOwned'}
Invoke-XlsxLifecycleNegative $fakeConnection 'local'
$group=$script:ledger.lifecycleNegatives[0]
if($script:ledger.lifecycleNegatives.Count -ne 1 -or $group.status -cne 'PASS' -or $group.mode -cne 'local' -or
   $group.rollback -ne 4 -or $group.locks -ne 2 -or $group.visibility -ne 16 -or
   $script:negativeCalls.Count -ne 6 -or $script:visibilityCalls.Count -ne 16 -or
   $script:journalWrites -ne 5 -or $script:neutralCalls -ne 1){throw 'XLSX_LIFECYCLE_COMPLETE_ADAPTER_COUNTERS'}
$script:ledger.lifecycleNegatives=@();$script:mutated=$false
function Get-XlsxSnapshot($Connection){if($script:mutated){'ContosoChangedSnapshot'}else{'ContosoStableSnapshot'}}
function Assert-XlsxRejected($Connection,[string]$Sql,[int]$Number){$script:mutated=$true}
$caught=$false;try{Invoke-XlsxLifecycleNegative $fakeConnection 'local'}catch{$caught=$true}
if(-not $caught -or $script:ledger.lifecycleNegatives.Count -ne 1 -or
   $script:ledger.lifecycleNegatives[0].status -cne 'RUNNING' -or $script:ledger.lifecycleNegatives[0].rollback -ne 0){
    throw 'XLSX_LIFECYCLE_CHILD_FAILURE_BECAME_PASS'
}

# Tatsächliche gemeinsame Modus-/Fixtureselektion statt nachgebauter Bedingungen.
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'XLSX_LIFECYCLE_DRIVER_PARSE'}
foreach($index in @(0,1,11)){
    $cellApi=$true;$CaseIndex=$index;$script:runset=$runset
    foreach($variable in @('modes','caseWorkbooks')){
        $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and
            $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq $variable},$true))
        if($nodes.Count -ne 1){throw 'XLSX_LIFECYCLE_SELECTOR'}
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    if(($modes -join '|') -cne 'local|central' -or ($caseWorkbooks.name -join '|') -cne 'Display.Lifecycle.sql'){
        throw 'XLSX_LIFECYCLE_SELECTOR_SCOPE'
    }
}
'PASS XLSX_LIFECYCLE_NEGATIVE 6 admission/seam negatives; own holder; original4rollback/2lock/16visibility and failure cleanup/state controls; complete adapter/counter/failure controls;3 actual selectors; no SQL'
