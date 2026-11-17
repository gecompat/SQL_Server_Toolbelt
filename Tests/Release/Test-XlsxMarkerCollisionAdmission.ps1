# Echte Originalschleife mit synthetischem DAL; kein SQL oder Providerstart.
param([Parameter(Mandatory)][string]$RunsetPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $PSScriptRoot 'Xlsx.MarkerCollision.Workload.ps1')
$runset=Get-Content $RunsetPath -Raw|ConvertFrom-Json
Assert-XlsxMarkerCollisionInputs $runset $repo
foreach($kind in @('source-pin','scope','fixture')){
    $probe=$runset|ConvertTo-Json -Depth 12|ConvertFrom-Json
    switch($kind){
        'source-pin'{$probe.pins=@($probe.pins|Where-Object {$_.path -cne (Join-Path $repo 'Tests/CI/run-xlsx-types-lab.ps1')})}
        'scope'{$probe.qualification_scope='caller-catalog-rest'}
        'fixture'{$probe.workbooks[0].name='Other.sql'}
    }
    $caught=$false;try{Assert-XlsxMarkerCollisionInputs $probe $repo}catch{$caught=$true}
    if(-not $caught){throw 'XLSX_MARKER_COLLISION_BAD_ADMISSION'}
}
$script:runset=$runset;$script:ledger=@{markerCollisions=@()}
$script:fixtures=@();$script:rejections=@();$script:restores=@();$script:faultMode='NONE';$script:changed=$false
function Save-ReleaseJournal {}
function Assert-XlsxFullSizeNeutral($Connection){}
function Read-XlsxSql([string]$Path,[hashtable]$Variables){
    if($Path -cne (Join-Path $repo 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.CollisionFixture.sql')){throw 'Wrong fixture path'}
    return 'FIXTURE:'+ $Variables.FaultCase
}
function Invoke-XlsxSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    if(-not $Rows -or -not $Sql.StartsWith('FIXTURE:')){throw 'Wrong fixture routing'}
    $fault=$Sql.Substring(8);$script:fixtures+=@($fault)
    $restore=if($script:faultMode -ceq 'MISSING_RESTORE'){''}else{'RESTORE:'+ $fault}
    [pscustomobject]@{ExpectedError=$(if($fault -ceq 'Dependency'){51535}else{51534});RestoreSql=$restore}
}
function Get-XlsxSnapshot($Connection){if($script:changed){'Changed'}else{'Stable'}}
function Assert-XlsxRejected($Connection,[string]$Sql,[int]$Number){
    $script:rejections+=@(@{text=$Sql;number=$Number})
    if($script:faultMode -ceq 'MUTATION'){$script:changed=$true}
}
function Invoke-XlsxBatches($Connection,[string]$Sql){
    $script:restores+=@($Sql)
    if($script:faultMode -ceq 'RESTORE_FAILURE'){throw 'Synthetic restore failure'}
}
Invoke-XlsxMarkerCollision $null 'local'
$e=$script:ledger.markerCollisions[0]
$deploy=[IO.File]::ReadAllText($runset.marker_collision.install.local)
$uninstall=[IO.File]::ReadAllText($runset.marker_collision.uninstall)
if($e.status -cne 'PASS' -or $e.deployRejections -ne 5 -or $e.uninstallRejections -ne 1 -or
 ($e.completedFaults -join '|') -cne ($markerFaults -join '|') -or
 ($script:fixtures -join '|') -cne ($markerFaults -join '|') -or $script:restores.Count -ne 6 -or
 $script:rejections.Count -ne 6){throw 'XLSX_MARKER_COLLISION_SEQUENCE_OR_COUNTERS'}
for($i=0;$i -lt 6;$i++){
    $expectedNumber=if($i -eq 5){51535}else{51534};$expectedSql=if($i -eq 5){$uninstall}else{$deploy}
    if($script:rejections[$i].number -ne $expectedNumber -or $script:rejections[$i].text -cne $expectedSql -or
       $script:restores[$i] -cne ('RESTORE:'+$markerFaults[$i])){throw 'XLSX_MARKER_COLLISION_ORIGINAL_ORACLES'}
}
foreach($kind in @('MISSING_RESTORE','MUTATION','RESTORE_FAILURE')){
    $script:faultMode=$kind;$script:changed=$false;$script:ledger.markerCollisions=@();$caught=$false
    try{Invoke-XlsxMarkerCollision $null 'central'}catch{$caught=$true}
    if(-not $caught -or $script:ledger.markerCollisions.Count -ne 1 -or
       $script:ledger.markerCollisions[0].status -cne 'RUNNING' -or
       $script:ledger.markerCollisions[0].completedFaults.Count -ne 0){throw 'XLSX_MARKER_COLLISION_FAILURE_BECAME_PASS'}
}
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'),[ref]$null,[ref]$null)
foreach($index in @(0,1,11)){
    $cellApi=$true;$CaseIndex=$index;$script:runset=$runset
    foreach($variable in @('modes','caseWorkbooks','expectedWorkbooks')){
        $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and
          $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq $variable},$true))
        if($nodes.Count -ne 1){throw 'XLSX_MARKER_COLLISION_SELECTOR'}
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    if(($modes -join '|') -cne 'local|central' -or $expectedWorkbooks -ne 1 -or
       ($caseWorkbooks.name -join '|') -cne 'Display.Lifecycle.sql'){throw 'XLSX_MARKER_COLLISION_SELECTOR_SCOPE'}
}
'PASS XLSX_MARKER_COLLISION 3 admission negatives; actual original six-fixture/5deploy/1uninstall/6restore sequence; missing restore/mutation/restore failure stay non-PASS; actual selectors; no SQL'
