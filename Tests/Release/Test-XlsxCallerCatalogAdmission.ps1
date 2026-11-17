# SQL-freie Admission, originale Reader-/Doom-Orakel und neuer Adapter.
param([Parameter(Mandatory)][string]$RunsetPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $PSScriptRoot 'Xlsx.CallerCatalog.Workload.ps1')
$runset=Get-Content $RunsetPath -Raw|ConvertFrom-Json
Assert-XlsxCallerCatalogInputs $runset $repo
foreach($kind in @('source-pin','scope','fixture')){
    $probe=$runset|ConvertTo-Json -Depth 12|ConvertFrom-Json
    switch($kind){
        'source-pin'{$probe.pins=@($probe.pins|Where-Object {$_.path -cne (Join-Path $repo 'Tests/CI/run-xlsx-types-lab.ps1')})}
        'scope'{$probe.qualification_scope='lifecycle-negative-rest'}
        'fixture'{$probe.workbooks[0].name='Other.sql'}
    }
    $caught=$false;try{Assert-XlsxCallerCatalogInputs $probe $repo}catch{$caught=$true}
    if(-not $caught){throw 'XLSX_CALLER_CATALOG_BAD_ADMISSION'}
}

# Originaler Doomed-Helper: unveränderte Erstbatches und beide Witnesszeilen.
$script:doomCalls=@();$script:missingWitness=$false
function Invoke-XlsxSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    $script:doomCalls+=@(@{text=$Sql;parameters=$Parameters})
    if(-not $script:missingWitness){[pscustomobject]@{Witness=1;InstallerIndex=$Parameters['@XlsxIndex']}}
}
$deploy=[IO.File]::ReadAllText($runset.caller_catalog.install.local)
$uninstall=[IO.File]::ReadAllText($runset.caller_catalog.uninstall)
Assert-XlsxCallerPrepared $null $deploy $uninstall 'OFF' $true
if($script:doomCalls.Count -ne 2 -or $script:doomCalls[0].parameters['@XlsxIndex'] -ne 0 -or
   $script:doomCalls[1].parameters['@XlsxIndex'] -ne 1){throw 'XLSX_CALLER_CATALOG_DOOM_ORIGINAL_SEQUENCE'}
foreach($pair in @(@{source=$deploy;call=$script:doomCalls[0]},@{source=$uninstall;call=$script:doomCalls[1]})){
    $first=([regex]::Split($pair.source,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$'))[0]
    if(-not $pair.call.text.Contains($first) -or $pair.call.parameters['@XlsxAbort'] -cne 'OFF'){
        throw 'XLSX_CALLER_CATALOG_DOOM_BATCH_CHANGED'
    }
}
$script:missingWitness=$true;$caught=$false
try{Assert-XlsxCallerPrepared $null $deploy $uninstall 'ON' $true}catch{$caught=$true}
if(-not $caught){throw 'XLSX_CALLER_CATALOG_MISSING_WITNESS_ACCEPTED'}

# Originale Nullabilityprüfung mit echtem DataTableReader, ohne Verbindung.
$script:table=[Data.DataTable]::new()
for($i=0;$i -lt 14;$i++){[void]$script:table.Columns.Add(('Column'+$i),[int])}
[void]$script:table.Rows.Add([object[]](0..13))
$script:badCatalog=$false;$script:reader=$null
function Invoke-XlsxSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    foreach($internal in @(0,1)){for($i=0;$i -lt 14;$i++){
        [pscustomobject]@{Ordinal=$i;name=('Column'+$i);is_nullable=(-not ($script:badCatalog -and $i -eq 0));Internal=$internal}
    }}
}
$script:expired=$false
function Get-ReleaseTimeout {if($script:expired){throw 'SYNTHETIC_DEADLINE'};45}
$cmd=[pscustomobject]@{CommandTimeout=0;CommandText='';Disposed=0;Cancelled=0}
$cmd|Add-Member ScriptMethod ExecuteReader {$script:reader=$script:table.CreateDataReader();return ,$script:reader}
$cmd|Add-Member ScriptMethod Dispose {$this.Disposed++}
$cmd|Add-Member ScriptMethod Cancel {$this.Cancelled++}
$conn=[pscustomobject]@{Database='ContosoOwn';Command=$cmd}
$conn|Add-Member ScriptMethod CreateCommand {return $this.Command}
Assert-XlsxNativeNullablePrepared $conn 'ContosoOwn'
if($cmd.Disposed -ne 1 -or -not $script:reader.IsClosed){throw 'XLSX_CALLER_CATALOG_READER_DISPOSAL'}
$script:badCatalog=$true;$caught=$false
try{Assert-XlsxNativeNullablePrepared $conn 'ContosoOwn'}catch{$caught=$true}
if(-not $caught){throw 'XLSX_CALLER_CATALOG_BAD_NULLABILITY_ACCEPTED'}
$script:expired=$true;$caught=$false
try{Assert-XlsxReadBudget $cmd}catch{$caught=$true}
if(-not $caught -or $cmd.Cancelled -ne 1){throw 'XLSX_CALLER_CATALOG_DEADLINE_CANCEL'}

# Neuer vollständiger Adapter, Kindfehler dürfen nie zu PASS werden.
$script:runset=$runset;$script:ledger=@{callerCatalog=@()};$script:profiles=@();$script:fail=$false
function Save-ReleaseJournal {}
function Get-XlsxSnapshot($Connection){'ContosoSnapshot'}
function Assert-XlsxFullSizeNeutral($Connection){}
function Assert-XlsxCallerPrepared($Connection,$Deploy,$Uninstall,$Abort,$Doomed){
    if($script:fail){throw 'SYNTHETIC_CHILD_FAILURE'}
    $script:profiles+=@($Abort+'/'+$Doomed)
}
function Assert-XlsxNativeNullablePrepared($Connection,$Database){if($script:fail){throw 'SYNTHETIC_CHILD_FAILURE'}}
Invoke-XlsxCallerCatalog $conn 'local'
$e=$script:ledger.callerCatalog[0]
if($e.status -cne 'PASS' -or $e.callerRejections -ne 8 -or $e.nullability -ne 1 -or
 ($e.profiles -join '|') -cne 'OFF/intact|OFF/doomed|ON/intact|ON/doomed' -or
 ($script:profiles -join '|') -cne 'OFF/False|OFF/True|ON/False|ON/True'){throw 'XLSX_CALLER_CATALOG_COUNTERS'}
$script:fail=$true;$caught=$false
try{Invoke-XlsxCallerCatalog $conn 'central'}catch{$caught=$true}
if(-not $caught -or $script:ledger.callerCatalog[1].status -cne 'RUNNING' -or
 $script:ledger.callerCatalog[1].callerRejections -ne 0){throw 'XLSX_CALLER_CATALOG_FAILURE_BECAME_PASS'}

$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'),[ref]$null,[ref]$null)
foreach($index in @(0,1,11)){
    $cellApi=$true;$CaseIndex=$index;$script:runset=$runset
    foreach($variable in @('modes','caseWorkbooks','expectedWorkbooks')){
        $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and
          $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq $variable},$true))
        if($nodes.Count -ne 1){throw 'XLSX_CALLER_CATALOG_SELECTOR'}
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    if(($modes -join '|') -cne 'local|central' -or $expectedWorkbooks -ne 1 -or
       ($caseWorkbooks.name -join '|') -cne 'Display.Lifecycle.sql'){throw 'XLSX_CALLER_CATALOG_SELECTOR_SCOPE'}
}
'PASS XLSX_CALLER_CATALOG 3 admission negatives; original doomed witness/batch checks; real synthetic reader/catalog mismatch and disposal; deadline cancellation; adapter counters/failure; actual selectors; no SQL'

