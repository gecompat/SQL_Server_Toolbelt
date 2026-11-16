# Echte Scope-/Originalbyte-Guards ohne SQL oder Labzugriff pruefen.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $PSScriptRoot 'Xlsx.CellApi.Workload.ps1')
$temporary=Join-Path $repo ('.runtime/xlsx-cell-counter-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temporary)
$runset=[pscustomobject]@{qualification_scope='cell-api-rest';workbooks=@();pins=@()}
foreach($name in @('Types.Contract.sql','Types.Safety.sql','Display.Contract.sql','Display.Safety.sql')){
    $source=Join-Path $repo ('Modules/toolbelt.file.xlsx-memory/Tests/Runtime/'+$name)
    $copy=Join-Path $temporary $name
    [IO.File]::WriteAllBytes($copy,[IO.File]::ReadAllBytes($source))
    $runset.workbooks+=@([pscustomobject]@{name=$name;path=$copy;expected_error='NONE';sha256=(Get-FileHash $source -Algorithm SHA256).Hash.ToLowerInvariant()})
    foreach($path in @($source,$copy)){$runset.pins+=@([pscustomobject]@{path=$path;sha256=(Get-FileHash $path -Algorithm SHA256).Hash})}
}
foreach($path in @((Join-Path $PSScriptRoot 'Xlsx.CellApi.Workload.ps1'),(Join-Path $PSScriptRoot 'Prepare-XlsxCellApiRunset.ps1'))){
    $runset.pins+=@([pscustomobject]@{path=$path;sha256=(Get-FileHash $path -Algorithm SHA256).Hash})
}
Assert-XlsxCellApiWorkload $runset 1 $repo
$display=$runset|ConvertTo-Json -Depth 8|ConvertFrom-Json
$display.qualification_scope='cell-display-rest'
$display.workbooks=@($display.workbooks[2],$display.workbooks[3])
Assert-XlsxCellApiWorkload $display 11 $repo
$caught=$false
try{Assert-XlsxCellApiWorkload $display 1 $repo}catch{$caught=$true}
if(-not $caught){throw 'XLSX_CELL_DISPLAY_REPLAY_ACCEPTED'}
$original=$runset|ConvertTo-Json -Depth 8
$count=0
foreach($mode in @('old-context','missing-fixture','reordered','forged-hash','missing-source-pin','missing-helper-pin','wrong-error')){
    $probe=$original|ConvertFrom-Json
    $index=1
    switch($mode){
        'old-context' {$index=0}
        'missing-fixture' {$probe.workbooks=@($probe.workbooks|Select-Object -First 3)}
        'reordered' {$probe.workbooks=@($probe.workbooks[1],$probe.workbooks[0],$probe.workbooks[2],$probe.workbooks[3])}
        'forged-hash' {$probe.workbooks[0].sha256='0'*64}
        'missing-source-pin' {$probe.pins=@($probe.pins|Select-Object -Skip 1)}
        'missing-helper-pin' {$probe.pins=@($probe.pins|Where-Object {$_.path -notlike '*Xlsx.CellApi.Workload.ps1'})}
        'wrong-error' {$probe.workbooks[0].expected_error='ANY'}
    }
    $caught=$false
    try{Assert-XlsxCellApiWorkload $probe $index $repo}catch{$caught=$true}
    if(-not $caught){throw ('XLSX_CELL_COUNTEREXAMPLE_ACCEPTED_'+$mode)}
    $count++
}
$copy=$runset.workbooks[0].path
[IO.File]::WriteAllText($copy,'-- changed private copy')
$caught=$false
try{Assert-XlsxCellApiWorkload $runset 1 $repo}catch{$caught=$true}
if(-not $caught){throw 'XLSX_CELL_CHANGED_COPY_ACCEPTED'}
foreach($name in @('Invoke-XlsxFullSizeLab.ps1','Invoke-XlsxFullSizeMatrix.ps1','Prepare-XlsxCellApiRunset.ps1','Xlsx.CellApi.Workload.ps1')){
    $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $name),[ref]$null,[ref]$errors)
    if($errors.Count){throw ('XLSX_CELL_PARSER_'+$name)}
}
'PASS XLSX_CELL_API two admissions plus 9 negative counterexamples; four adapter parses; no SQL'

# Die tatsächlich eingesetzten Selektorausdrücke aus dem Adapter ausführen:
# keine kopierte Implementierung und kein geladener SQL-Einstieg.
$client=[pscustomobject]@{qualification_scope='cell-client-rest';workbooks=@();pins=@()}
foreach($name in @('Types.Metadata.ps1','Display.Metadata.ps1')){
    $source=Join-Path $repo ('Modules/toolbelt.file.xlsx-memory/Tests/Runtime/'+$name)
    $copy=Join-Path $temporary $name
    [IO.File]::WriteAllBytes($copy,[IO.File]::ReadAllBytes($source))
    $client.workbooks+=@([pscustomobject]@{name=$name;path=$copy;expected_error='NONE';sha256=(Get-FileHash $source -Algorithm SHA256).Hash.ToLowerInvariant()})
    foreach($path in @($source,$copy)){$client.pins+=@([pscustomobject]@{path=$path;sha256=(Get-FileHash $path -Algorithm SHA256).Hash})}
}
foreach($path in @((Join-Path $PSScriptRoot 'Xlsx.CellApi.Workload.ps1'),(Join-Path $PSScriptRoot 'Prepare-XlsxCellApiRunset.ps1'))){
    $client.pins+=@([pscustomobject]@{path=$path;sha256=(Get-FileHash $path -Algorithm SHA256).Hash})
}
Assert-XlsxCellApiWorkload $client 1 $repo
$caught=$false
try{Assert-XlsxCellApiWorkload $client 0 $repo}catch{$caught=$true}
if(-not $caught){throw 'XLSX_CLIENT_ALREADY_QUALIFIED_PAIR_ACCEPTED'}
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'),[ref]$null,[ref]$errors)
foreach($index in @(1,9,11)){
    $script:runset=$client;$CaseIndex=$index;$cellApi=$true
    foreach($variable in @('modes','caseWorkbooks')){
        $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and
          $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq $variable},$true))
        if($nodes.Count -ne 1){throw 'XLSX_CLIENT_SELECTOR_AMBIGUOUS'}
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    $expectedModes=if($index -eq 11){'central'}else{'local|central'}
    $expectedNames=if($index -ge 9){'Display.Metadata.ps1'}else{'Types.Metadata.ps1|Display.Metadata.ps1'}
    if(($modes -join '|') -cne $expectedModes -or ($caseWorkbooks.name -join '|') -cne $expectedNames){throw 'XLSX_CLIENT_GREEN_REPLAY_OR_MISSING_FIXTURE'}
}
'PASS XLSX_CELL_CLIENT pinned original helpers and 3 live selector contexts; no SQL'
