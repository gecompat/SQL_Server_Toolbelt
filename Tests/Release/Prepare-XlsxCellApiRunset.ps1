# Wiederverwendung der unveränderten Paket-/Labzulassung, ohne SQL-Verbindung.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunRoot,
      [Parameter(Mandatory)][string]$FixtureOutput,
      [Parameter(Mandatory)][string]$PythonPath,
      [Parameter(Mandatory)][string]$PackagePath,
      [Parameter(Mandatory)][string]$QualifiedFixtureDirectory,
      [ValidateSet('cell-api-rest','cell-display-rest','cell-client-rest')][string]$QualificationScope='cell-api-rest')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$baseParameters=@{}+ $PSBoundParameters
[void]$baseParameters.Remove('QualificationScope')
& (Join-Path $PSScriptRoot 'Prepare-XlsxFullSizeRunset.ps1') @baseParameters
if(-not $?){throw 'XLSX_CELL_PREPARATION_FAILED'}
$runsetPath=Join-Path $RunRoot 'runset.json'
$runset=Get-Content -LiteralPath $runsetPath -Raw|ConvertFrom-Json
$runset|Add-Member -NotePropertyName qualification_scope -NotePropertyValue $QualificationScope
$workloads=@()
$paths=@('Tests/Release/Xlsx.CellApi.Workload.ps1','Tests/Release/Prepare-XlsxCellApiRunset.ps1')
$names=switch($QualificationScope){
    'cell-api-rest' {@('Types.Contract.sql','Types.Safety.sql','Display.Contract.sql','Display.Safety.sql')}
    'cell-display-rest' {@('Display.Contract.sql','Display.Safety.sql')}
    'cell-client-rest' {@('Types.Metadata.ps1','Display.Metadata.ps1')}
}
foreach($name in $names){
    $relative='Modules/toolbelt.file.xlsx-memory/Tests/Runtime/'+$name
    $source=Join-Path $repo $relative
    $destination=Join-Path $FixtureOutput $name
    if(Test-Path -LiteralPath $destination){throw 'XLSX_CELL_FRESH_FIXTURE_REQUIRED'}
    [IO.File]::WriteAllBytes($destination,[IO.File]::ReadAllBytes($source))
    $sha=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    $workloads+=@{name=$name;path=$destination;sha256=$sha.ToLowerInvariant();expected_error='NONE'}
    $paths+=@($relative,$destination)
}
$runset.workbooks=$workloads
foreach($path in $paths){
    $full=if([IO.Path]::IsPathRooted($path)){$path}else{Join-Path $repo $path}
    if(@($runset.pins|Where-Object path -CEQ $full).Count){throw 'XLSX_CELL_DUPLICATE_PIN'}
    $runset.pins+=@([pscustomobject]@{path=$full;sha256=(Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash})
}
. (Join-Path $PSScriptRoot 'Xlsx.CellApi.Workload.ps1')
$firstIndex=if($QualificationScope -ceq 'cell-display-rest'){9}else{1}
Assert-XlsxCellApiWorkload $runset $firstIndex $repo
[IO.File]::WriteAllText($runsetPath,($runset|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
'PASS XLSX_CELL_API private runset prepared; no SQL connection opened'
