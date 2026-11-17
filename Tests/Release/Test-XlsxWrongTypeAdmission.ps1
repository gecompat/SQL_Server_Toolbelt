param([Parameter(Mandatory)][string]$RunsetPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $PSScriptRoot 'Xlsx.WrongType.Workload.ps1')
$sourceRunset=Get-Content $RunsetPath -Raw|ConvertFrom-Json
Assert-XlsxWrongTypeInputs $sourceRunset $repo
foreach($kind in @('source-pin','scope','fixture')){
    $probe=$sourceRunset|ConvertTo-Json -Depth 12|ConvertFrom-Json
    switch($kind){
        'source-pin'{$probe.pins=@($probe.pins|Where-Object {$_.path -cne (Join-Path $repo 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.CollisionFixture.sql')})}
        'scope'{$probe.qualification_scope='marker-collision-rest'}
        'fixture'{$probe.workbooks[0].name='Other.sql'}
    }
    $caught=$false;try{Assert-XlsxWrongTypeInputs $probe $repo}catch{$caught=$true}
    if(-not $caught){throw 'XLSX_WRONGTYPE_BAD_ADMISSION'}
}
# Originales Fixture-SQL und der echte Witness-Adapter, synthetisches DAL.
$script:runset=$sourceRunset;$script:ledger=@{wrongTypes=@()};$script:bad='NONE';$script:denied=$false;$script:denials=@()
function Save-ReleaseJournal {}
function Assert-XlsxFullSizeNeutral($Connection){}
function Invoke-ReleaseSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    if(-not $Rows){throw 'Unexpected non-row SQL'}
    if($Sql.Contains('SELECT @Expected ExpectedError,@RestoreSql RestoreSql;')){
        if(-not $Sql.Contains("@Case nvarchar(64)=N'WrongType'") -or $Sql -match '\$\('){throw 'Wrong original fixture rendering'}
        return [pscustomobject]@{ExpectedError=51534;RestoreSql=$(if($script:bad -ceq 'restore'){'RESTORE'}else{''})}
    }
    [pscustomobject]@{
        Id=$(if($script:bad -ceq 'id'){0}else{7})
        Kind=$(if($script:bad -ceq 'type'){'P'}else{'FN'})
        DefinitionHash=$(if($script:bad -ceq 'hash'){'invalid'}else{'A'*64})
        ModuleMarkers=$(if($script:bad -ceq 'markers'){1}else{0})
        SyntheticValue=$(if($script:bad -ceq 'value'){74}else{73})
    }
}
function Get-XlsxSnapshot($Connection){if($script:bad -ceq 'mutation' -and $script:denied){'Changed'}else{'Stable'}}
function Assert-XlsxRejected($Connection,[string]$Sql,[int]$Number){
    if($Number -ne 51534){throw 'Wrong expected error'}
    $script:denials+=@($Sql);$script:denied=$true
    if($script:bad -ceq 'denial'){throw 'Synthetic child failure'}
}
if((Get-XlsxWrongTypeWitness $null) -cne ('7|'+('A'*64))){throw 'XLSX_WRONGTYPE_WITNESS_FORMAT'}
foreach($kind in @('id','type','hash','markers','value')){
    $script:bad=$kind;$caught=$false;try{[void](Get-XlsxWrongTypeWitness $null)}catch{$caught=$true}
    if(-not $caught){throw 'XLSX_WRONGTYPE_BAD_WITNESS'}
}
$script:bad='NONE'
Invoke-XlsxWrongType $null 'local'
Invoke-XlsxWrongType $null 'central'
$prior=@{completedModes=@('local','central');databases=@(@{suffix='l'},@{suffix='c'});
    wrongTypes=$script:ledger.wrongTypes;lifecycle=@(@{action='InstallAndRepeat'},@{action='InstallAndRepeat'})}
Assert-XlsxWrongTypeJournal $prior
$paths=@($sourceRunset.wrongtype.install.local,$sourceRunset.wrongtype.uninstall,$sourceRunset.wrongtype.install.central,$sourceRunset.wrongtype.uninstall)
if($script:denials.Count -ne 4){throw 'XLSX_WRONGTYPE_DENIAL_COUNT'}
for($i=0;$i -lt 4;$i++){if($script:denials[$i] -cne [IO.File]::ReadAllText($paths[$i])){throw 'XLSX_WRONGTYPE_DENIAL_ROUTING'}}
foreach($kind in @('restore','mutation','denial')){
    $script:bad=$kind;$script:denied=$false;$script:ledger.wrongTypes=@();$caught=$false
    try{Invoke-XlsxWrongType $null 'local'}catch{$caught=$true}
    if(-not $caught -or $script:ledger.wrongTypes[0].status -cne 'RUNNING'){
        throw 'XLSX_WRONGTYPE_FAILURE_BECAME_PASS'
    }
}
foreach($kind in @('witness','mode','uninstall-claim')){
    $probe=$prior|ConvertTo-Json -Depth 12|ConvertFrom-Json
    switch($kind){
        'witness'{$probe.wrongTypes[1].foreignWitnesses=2}
        'mode'{$probe.completedModes=@('local')}
        'uninstall-claim'{$probe.lifecycle+=@([pscustomobject]@{action='Uninstall'})}
    }
    $caught=$false;try{Assert-XlsxWrongTypeJournal $probe}catch{$caught=$true}
    if(-not $caught){throw 'XLSX_WRONGTYPE_BAD_AUDIT'}
}
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'),[ref]$null,[ref]$null)
foreach($scope in @('wrongtype-rest','marker-collision-rest')){
    $cellApi=$true;$CaseIndex=0;$script:runset=$sourceRunset|ConvertTo-Json -Depth 12|ConvertFrom-Json
    $script:runset.qualification_scope=$scope
    foreach($variable in @('modes','caseWorkbooks','expectedWorkbooks','uninstallActions')){
        $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and
          $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq $variable},$true))
        if($nodes.Count -ne 1){throw 'XLSX_WRONGTYPE_SELECTOR'}
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    if(($modes -join '|') -cne 'local|central' -or $expectedWorkbooks -ne 1 -or
       ($caseWorkbooks.name -join '|') -cne 'Display.Lifecycle.sql' -or
       @($uninstallActions).Count -ne $(if($scope -ceq 'wrongtype-rest'){0}else{2})){throw 'XLSX_WRONGTYPE_SELECTOR_SCOPE'}
    $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and
      $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq 'definitions'},$true))
    if($nodes.Count -ne 2){throw 'XLSX_WRONGTYPE_DEFINITION_ORACLE'}
    . ([scriptblock]::Create($nodes[0].Extent.Text))
    . ([scriptblock]::Create($nodes[1].Parent.Parent.Extent.Text))
    $excluded=$definitions.Contains("AND NOT(o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.name=N'USP_ListXlsxWorksheets')")
    if($excluded -ne ($scope -ceq 'wrongtype-rest') -or -not $definitions.Contains('LEFT JOIN sys.assembly_modules')){
        throw 'XLSX_WRONGTYPE_OTHER_OBJECT_GUARD'
    }
}
'PASS XLSX_WRONGTYPE 3 admission negatives; original fixture/oracle routing;5 bad foreign witnesses; restore/mutation/child failures non-PASS; audit negatives; actual uninstall/other-object scope selectors; no SQL'
