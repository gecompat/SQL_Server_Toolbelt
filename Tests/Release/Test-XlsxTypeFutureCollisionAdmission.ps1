# Echte Pins prüfen; danach originale vier Fixtures ausschließlich mit Testdoubles.
param([Parameter(Mandatory)][string]$RunsetPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $PSScriptRoot 'Xlsx.TypeFutureCollision.Workload.ps1')
$runset=Get-Content $RunsetPath -Raw|ConvertFrom-Json
Assert-XlsxTypeFutureCollisionInputs $runset $repo
foreach($kind in @('missing-collision-source','missing-legacy-helper','wrong-fixture')){
    $probe=$runset|ConvertTo-Json -Depth 12|ConvertFrom-Json
    if($kind -ceq 'wrong-fixture'){$probe.workbooks[0].name='Other.sql'}else{
        $path=Join-Path $repo $(if($kind -ceq 'missing-collision-source'){'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.CollisionFixture.sql'}else{'Tests/Release/Xlsx.Genuine10.Workload.ps1'})
        $probe.pins=@($probe.pins|Where-Object path -CNE $path)
    }
    $caught=$false;try{Assert-XlsxTypeFutureCollisionInputs $probe $repo}catch{$caught=$true}
    if(-not $caught){throw 'XLSX_FUTURE_BAD_INPUT_ACCEPTED'}
}

$script:runset=$runset;$script:case=$runset.cases[0]
$script:baseline=[ordered]@{Version='1.0.0';Mode='local';Slots=5;Bindings=2;Hash=$runset.legacy.artifact.sha512;Permission='SAFE_ACCESS'}
$script:fixtures=[Collections.Generic.List[string]]::new()
$script:rejections=0;$script:baselineCalls=0;$script:foreignReads=0;$script:foreignDrift=$false
function Invoke-ReleaseSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    if(-not $Rows){return}
    if($Sql.Contains('SELECT CONVERT(nvarchar(64),e.value) Version')){
        $script:baselineCalls++;return [pscustomobject]$script:baseline
    }
    if($Sql.Contains('DECLARE @Case nvarchar(64)=')){
        $match=[regex]::Match($Sql,"DECLARE @Case nvarchar\(64\)=N'([^']+)'")
        if(-not $match.Success){throw 'XLSX_FUTURE_MOCK_FIXTURE_SELECTOR'}
        $script:fixtures.Add($match.Groups[1].Value)
        return [pscustomobject]@{ExpectedError=51534;RestoreSql='SELECT 1; -- Contoso restore testdouble'}
    }
    if($Sql.Contains(' AS Snapshot;')){return [pscustomobject]@{Snapshot='ContosoStableSnapshot'}}
    if($Sql.Contains(' Present;')){
        $script:foreignReads++
        $hash=if($script:foreignDrift -and $script:foreignReads%2 -eq 0){'ContosoChangedForeign'}else{'ContosoStableForeign'}
        return [pscustomobject]@{Present=1;Hash=$hash}
    }
    if($Sql.Contains('SELECT COUNT(*) Count FROM sys.assemblies')){return [pscustomobject]@{Count=0}}
    throw 'XLSX_FUTURE_UNEXPECTED_MOCK_QUERY'
}
function Save-ReleaseJournal {}
function Assert-XlsxFullSizeNeutral($Connection) {}
function Open-ReleaseConnection([string]$Database){
    # Konstruktion einer geschlossenen Verbindung; niemals Open/Authentifizierung.
    return [Data.SqlClient.SqlConnection]::new('Data Source=localhost;Initial Catalog=ContosoOwned;Integrated Security=True;Encrypt=True;TrustServerCertificate=True')
}
function Assert-XlsxRejected($Connection,[string]$Sql,[int]$Number){
    if($Number -ne 51534){throw 'XLSX_FUTURE_WRONG_REJECTION_CODE'}
    $script:rejections++
}

Assert-XlsxGenuine10Baseline $null 'local'
foreach($property in @('Version','Mode','Slots','Bindings','Hash','Permission')){
    $before=$script:baseline[$property];$script:baseline[$property]=switch($property){
        'Version' {'1.2.0'} 'Mode' {'central'} 'Slots' {9} 'Bindings' {4} 'Hash' {'0'*128} 'Permission' {'UNSAFE_ACCESS'}
    }
    $caught=$false;try{Assert-XlsxGenuine10Baseline $null 'local'}catch{$caught=$true}
    $script:baseline[$property]=$before
    if(-not $caught){throw 'XLSX_FUTURE_FAKE_GENUINE_WITNESS_ACCEPTED'}
}
$script:ledger=@{databases=@(@{name='ContosoOwned';state='OWNED'});genuine=@(@{mode='local';status='PASS_GENUINE_1_0'});typeFutureCollisions=@()}
$script:baselineCalls=0
$connection=Open-ReleaseConnection 'ContosoOwned'
$next=Invoke-XlsxTypeFutureCollision $connection 'local'
$entry=$script:ledger.typeFutureCollisions[0]
if($next -isnot [Data.SqlClient.SqlConnection] -or $entry.status -cne 'PASS' -or $entry.legacyWitnesses -ne 5 -or
   ($entry.completedFaults -join '|') -cne 'FuturePublic|ImitatedFuturePublic|FutureInternal|ImitatedFutureInternal' -or
   ($script:fixtures -join '|') -cne ($entry.completedFaults -join '|') -or
   $script:rejections -ne 4 -or $script:foreignReads -ne 8 -or $script:baselineCalls -ne 4 -or $script:typeFutureEntry){
    throw 'XLSX_FUTURE_COMPLETE_ADAPTER_OR_ORIGINAL_CASES'
}
$next.Dispose()

# Tatsächlicher Holder-/Restoreadapter lehnt nicht eigene DBs vor dem Öffnen ab.
$script:typeFutureEntry=@{status='RUNNING';legacyWitnesses=1;completedFaults=@()};$script:typeFutureMode='local'
$caught=$false;try{Open-XlsxConnection $null 'Other'}catch{$caught=$true}
$script:typeFutureEntry=$null;$script:typeFutureMode=$null
if(-not $caught){throw 'XLSX_FUTURE_UNOWNED_RESTORE_ACCEPTED'}

# Verlorener Fremdslot darf weder als PASS zählen noch einen Restore bezeugen.
$script:ledger.typeFutureCollisions=@();$script:foreignDrift=$true;$script:foreignReads=0
$connection=Open-ReleaseConnection 'ContosoOwned';$caught=$false
try{Invoke-XlsxTypeFutureCollision $connection 'local'}catch{$caught=$true}
$entry=$script:ledger.typeFutureCollisions[0]
if(-not $caught -or $entry.status -cne 'FAILED' -or $entry.legacyWitnesses -ne 1 -or $entry.completedFaults.Count -ne 0 -or $script:typeFutureEntry){
    throw 'XLSX_FUTURE_FOREIGN_LOSS_BECAME_PASS'
}

$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'XLSX_FUTURE_DRIVER_PARSE'}
$scopeGuards=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.IfStatementAst] -and
    $n.Clauses[0].Item1.Extent.Text.Contains('qualification_scope -cnotin')},$true))
if($scopeGuards.Count -ne 1 -or (. ([scriptblock]::Create($scopeGuards[0].Clauses[0].Item1.Extent.Text)))){
    throw 'XLSX_FUTURE_ACTUAL_SCOPE_GUARD_REJECTS_PROFILE'
}
foreach($index in @(0,1,11)){
    $cellApi=$true;$CaseIndex=$index;$script:runset=$runset
    foreach($variable in @('modes','caseWorkbooks','expectedWorkbooks')){
        $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and
            $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq $variable},$true))
        if($nodes.Count -ne 1){throw 'XLSX_FUTURE_SELECTOR'}
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    if(($modes -join '|') -cne 'local|central' -or $expectedWorkbooks -ne 1 -or ($caseWorkbooks.name -join '|') -cne 'Display.Lifecycle.sql'){
        throw 'XLSX_FUTURE_SELECTOR_SCOPE'
    }
}
'PASS XLSX_TYPE_FUTURE_COLLISION 3 admission/6 genuine negatives; original4fixture/8preservation reads/4restores with exact complete counters; foreign-loss/unowned-db controls;actual scope guard/3 live selectors; no SQL'
