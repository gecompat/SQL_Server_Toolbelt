# Echte private Prototyp-Pins prÃ¼fen, keine SQL-Funktion importieren/aufrufen.
param([Parameter(Mandatory)][string]$RunsetPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $PSScriptRoot 'Xlsx.Genuine11.Workload.ps1')
$runset=Get-Content $RunsetPath -Raw|ConvertFrom-Json
Assert-XlsxGenuine11Inputs $runset $repo
$json=$runset|ConvertTo-Json -Depth 12
foreach($kind in @('wrong-version-hash','current-binary','missing-source-pin','missing-preparation-pin')){
    $probe=$json|ConvertFrom-Json
    switch($kind){
        'wrong-version-hash' {$probe.legacy.artifact.sha512='0'*128}
        'current-binary' {$probe.legacy.artifact.path=($probe.artifacts|Where-Object module_id -CEQ 'toolbelt.file.xlsx-memory').path}
        'missing-source-pin' {$source=Join-Path $probe.legacy.module 'Clr/Workbook.cs';$probe.pins=@($probe.pins|Where-Object path -CNE $source)}
        'missing-preparation-pin' {$source=Join-Path $PSScriptRoot 'Prepare-XlsxGenuine11Runset.ps1';$probe.pins=@($probe.pins|Where-Object path -CNE $source)}
    }
    $caught=$false
    try{Assert-XlsxGenuine11Inputs $probe $repo}catch{$caught=$true}
    if(-not $caught){throw ('XLSX_GENUINE11_BAD_INPUT_ACCEPTED_'+$kind)}
}
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'XLSX_GENUINE11_DRIVER_PARSE'}
$indices=@(0,1,11)
foreach($index in $indices){
    $cellApi=$true;$CaseIndex=$index;$script:runset=$runset
    foreach($variable in @('modes','caseWorkbooks')){
        $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and
          $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq $variable},$true))
        if($nodes.Count -ne 1){throw 'XLSX_GENUINE11_SELECTOR'}
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    $expected='local|central'
    if(($modes -join '|') -cne $expected -or ($caseWorkbooks.name -join '|') -cne 'Types.Metadata.ps1|Display.Metadata.ps1'){throw 'XLSX_GENUINE11_GREEN_REPLAY'}
}
'PASS XLSX_GENUINE11 original-source admission; 4 negative provenance/pin cases and 3 actual mode selectors; no SQL'
