param([Parameter(Mandatory)][string]$RunsetPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $PSScriptRoot 'Xlsx.OwnedDatabase.ps1')
. (Join-Path $PSScriptRoot 'Xlsx.CompositionConsumer.Workload.ps1')
$runset=Get-Content $RunsetPath -Raw|ConvertFrom-Json
$sourceRunset=$runset
Assert-XlsxCompositionConsumerInputs $runset $repo
foreach($kind in @('source-pin','scope','helper-route')){
    $probe=$runset|ConvertTo-Json -Depth 12|ConvertFrom-Json
    switch($kind){
        'source-pin'{$probe.pins=@($probe.pins|Where-Object {$_.path -cne (Join-Path $repo 'Tests/CI/run-xlsx-types-lab.ps1')})}
        'scope'{$probe.qualification_scope='marker-collision-rest'}
        'helper-route'{$probe.composition_consumer.helpers.'Types.Metadata.ps1'='Other.ps1'}
    }
    $caught=$false;try{Assert-XlsxCompositionConsumerInputs $probe $repo}catch{$caught=$true}
    if(-not $caught){throw 'XLSX_COMPOSITION_BAD_ADMISSION'}
}

# Tatsächliche gemeinsame DB-Sequenz mit synthetischem DAL, kein SQL.
$script:runset=$sourceRunset;$script:case=$runset.cases[0]
$script:ledger=@{owner=('1'*32);databases=@()};$script:sql=@();$script:states=@();$script:failOwner=$false
$script:fakeDb=[pscustomobject]@{Database='';Disposed=0}
$script:fakeDb|Add-Member ScriptMethod Dispose {$this.Disposed++}
function Save-ReleaseJournal {$script:states+=@(($script:ledger.databases.state -join '|'))}
function Open-ReleaseConnection([string]$Database){$script:fakeDb.Database=$Database;return $script:fakeDb}
function Invoke-ReleaseSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    $script:sql+=@($Sql)
    if($script:failOwner -and $Sql.Contains('sp_addextendedproperty')){throw 'Synthetic marker failure'}
    if($Rows){[pscustomobject]@{Id=7;Created='0000000000000001'}}
}
$db=New-XlsxFullSizeOwnedDatabase $null 'u' 'Latin1_General_100_CS_AS' 150
if($db.Database -cne ('Toolbelt_Release_'+('1'*32)+'_u') -or $script:sql.Count -ne 4 -or
   ($script:states -join ',') -cne 'CREATING,CREATED,OWNED' -or $script:ledger.databases[0].id -ne 7){throw 'XLSX_COMPOSITION_DB_SEQUENCE'}
foreach($kind in @('duplicate','unsafe-owner','old-scope','wrong-collation','full')){
    $script:runset=$sourceRunset;$script:ledger=@{owner=('1'*32);databases=@()};$suffix='u';$collation='Latin1_General_100_CS_AS'
    switch($kind){
        'duplicate'{$script:ledger.databases=@(@{suffix='u'})}
        'unsafe-owner'{$script:ledger.owner='not-an-owner'}
        'old-scope'{$script:runset=[pscustomobject]@{qualification_scope='marker-collision-rest'}}
        'wrong-collation'{$collation='Latin1_General_100_CI_AS_SC'}
        'full'{$script:ledger.databases=@(@{suffix='l'},@{suffix='c'},@{suffix='u'})}
    }
    $before=$script:sql.Count;$caught=$false
    try{[void](New-XlsxFullSizeOwnedDatabase $null $suffix $collation 150)}catch{$caught=$true}
    if(-not $caught -or $script:sql.Count -ne $before){throw 'XLSX_COMPOSITION_DB_ADMISSION_AFTER_SQL'}
}
$script:runset=[pscustomobject]@{};$script:ledger=@{owner=('1'*32);databases=@()}
[void](New-XlsxFullSizeOwnedDatabase $null 'l' 'Latin1_General_100_CI_AS_SC' 150)
[void](New-XlsxFullSizeOwnedDatabase $null 'c' 'Latin1_General_100_CI_AS_SC' 150)
if(($script:ledger.databases.suffix -join '|') -cne 'l|c'){throw 'XLSX_COMPOSITION_OLD_SCOPE_DB_ROUTING'}
$script:runset=$sourceRunset;$script:ledger=@{owner=('1'*32);databases=@()};$script:failOwner=$true;$caught=$false
try{[void](New-XlsxFullSizeOwnedDatabase $null 'u' 'Latin1_General_100_CS_AS' 150)}catch{$caught=$true}
if(-not $caught -or $script:fakeDb.Disposed -ne 1 -or $script:ledger.databases[0].state -cne 'CREATED'){
    throw 'XLSX_COMPOSITION_UNOWNED_FAILURE_OR_DISPOSAL'
}

# Vollständiger Consumer-Adapter und echtes Providerfrei-Orakel mit Testdoubles.
$provider=[pscustomobject]@{Database='ContosoProvider'}
$consumer=[pscustomobject]@{Database='ContosoConsumer';Disposed=0}
$consumer|Add-Member ScriptMethod Dispose {$this.Disposed++}
$script:consumer=$consumer;$script:helperCalls=@();$script:denials=@();$script:badFootprint=$false;$script:failHelper=$false
$script:ledger=@{databases=@(@{name='ContosoConsumer';suffix='u';state='OWNED'});compositions=@()}
function Save-ReleaseJournal {}
function New-XlsxFullSizeOwnedDatabase($Control,$Suffix,$Collation,$Level){
    if($Suffix -cne 'u' -or $Collation -cne 'Latin1_General_100_CS_AS' -or $Level -ne 150){throw 'Wrong consumer creation context'}
    return $script:consumer
}
function Get-XlsxSnapshot($Connection){'Stable'}
function Assert-XlsxFullSizeNeutral($Connection){}
function Invoke-ReleaseSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    if(-not $Rows -or $Connection.Database -cne 'ContosoConsumer'){throw 'Wrong consumer read context'}
    [pscustomobject]@{DbName='ContosoConsumer';Collation='Latin1_General_100_CS_AS';CL=150;Objects=$(if($script:badFootprint){1}else{0});Assemblies=0;Schemas=0;Modules=0}
}
function Invoke-XlsxCompositionOriginalHelper($Connection,$Database,$Name){
    if($script:failHelper -and $Name -ceq 'Display.Metadata.ps1'){throw 'Synthetic child failure'}
    $script:helperCalls+=@($Connection.Database+'/'+$Database+'/'+$Name)
}
function Assert-XlsxNativeNullablePrepared($Connection,$Database,$CatalogConnection){
    if($Connection.Database -cne 'ContosoConsumer' -or $Database -cne 'ContosoProvider' -or
       $CatalogConnection.Database -cne 'ContosoProvider'){throw 'Wrong crossDB catalog oracle'}
}
function Assert-XlsxRejected($Connection,[string]$Sql,[int]$Number){
    if($Connection.Database -cne 'ContosoProvider' -or $Number -ne 51536 -or
       $Sql -cne [IO.File]::ReadAllText($script:runset.composition_consumer.unconfirmed)){throw 'Wrong confirm0 oracle'}
    $script:denials+=@($Number)
}
Invoke-XlsxCompositionConsumer $provider 'local' $null
Invoke-XlsxCompositionConsumer $provider 'central' $null
$prior=@{completedModes=@('local','central');databases=@(@{suffix='l'},@{suffix='c'},@{suffix='u'});compositions=$script:ledger.compositions}
Assert-XlsxCompositionConsumerJournal $prior
if($script:helperCalls.Count -ne 8 -or $consumer.Disposed -ne 1 -or $script:denials.Count -ne 1 -or
 @($script:helperCalls|Where-Object {$_ -like 'ContosoConsumer/ContosoProvider/*'}).Count -ne 4){throw 'XLSX_COMPOSITION_COMPLETE_ADAPTER_ROUTING'}
foreach($kind in @('missing-consumer','missing-witness','missing-nullability','missing-helper','missing-confirm0')){
    $probe=$prior|ConvertTo-Json -Depth 12|ConvertFrom-Json
    switch($kind){
        'missing-consumer'{$probe.databases=@($probe.databases|Where-Object suffix -CNE 'u')}
        'missing-witness'{$probe.compositions[1].providerFreeWitnesses=1}
        'missing-nullability'{$probe.compositions[1].nullability=0}
        'missing-helper'{$probe.compositions[1].consumerHelpers=@('Types.Metadata.ps1')}
        'missing-confirm0'{$probe.compositions[1].confirm0=0}
    }
    $caught=$false;try{Assert-XlsxCompositionConsumerJournal $probe}catch{$caught=$true}
    if(-not $caught){throw 'XLSX_COMPOSITION_BAD_AUDIT'}
}
foreach($kind in @('footprint','child')){
    $script:badFootprint=$kind -ceq 'footprint';$script:failHelper=$kind -ceq 'child'
    $script:ledger.compositions=@();$before=$consumer.Disposed;$caught=$false
    try{Invoke-XlsxCompositionConsumer $provider 'central' $null}catch{$caught=$true}
    if(-not $caught -or $consumer.Disposed -ne $before+1 -or $script:ledger.compositions[0].status -cne 'RUNNING'){
        throw 'XLSX_COMPOSITION_FAILURE_BECAME_PASS_OR_LEAKED'
    }
}

# Tatsächliche Scope-/Fixture- und Budgetselektion, keine kopierten Bedingungen.
$driver=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'),[ref]$null,[ref]$null)
foreach($index in @(0,1,11)){
    $cellApi=$true;$CaseIndex=$index;$script:runset=$sourceRunset
    foreach($variable in @('modes','caseWorkbooks','expectedWorkbooks')){
        $nodes=@($driver.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and
          $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq $variable},$true))
        if($nodes.Count -ne 1){throw 'XLSX_COMPOSITION_SELECTOR'}
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    if(($modes -join '|') -cne 'local|central' -or $expectedWorkbooks -ne 1 -or
       ($caseWorkbooks.name -join '|') -cne 'Display.Lifecycle.sql'){throw 'XLSX_COMPOSITION_SELECTOR_SCOPE'}
}
$matrix=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeMatrix.ps1'),[ref]$null,[ref]$null)
foreach($scope in @('composition-consumer-rest','marker-collision-rest')){
    $cellApi=$true;$runset=[pscustomobject]@{qualification_scope=$scope}
    foreach($variable in @('maximum','databaseMaximum','perCaseDatabases')){
        $nodes=@($matrix.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and
          $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq $variable},$true))
        if($nodes.Count -ne 1){throw 'XLSX_COMPOSITION_BUDGET_SELECTOR'}
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    if($maximum -ne 28 -or $databaseMaximum -ne $(if($scope -ceq 'composition-consumer-rest'){42}else{28}) -or
       $perCaseDatabases -ne $(if($scope -ceq 'composition-consumer-rest'){3}else{2})){throw 'XLSX_COMPOSITION_BUDGET_SCOPE'}
}
'PASS XLSX_COMPOSITION_CONSUMER admission/DB ownership and failure disposal; original helper byte oracles; crossDB routing/empty CS consumer/catalog/Confirm0; audit negatives and failure non-PASS; actual selectors/3-DB budgets; no SQL'
