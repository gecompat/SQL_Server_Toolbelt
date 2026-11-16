# Wiederverwendung der unveränderten Paket-/Labzulassung, ohne SQL-Verbindung.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunRoot,
      [Parameter(Mandatory)][string]$FixtureOutput,
      [Parameter(Mandatory)][string]$PythonPath,
      [Parameter(Mandatory)][string]$PackagePath,
      [Parameter(Mandatory)][string]$QualifiedFixtureDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
& (Join-Path $PSScriptRoot 'Prepare-XlsxFullSizeRunset.ps1') @PSBoundParameters
if(-not $?){throw 'XLSX_CELL_PREPARATION_FAILED'}
$runsetPath=Join-Path $RunRoot 'runset.json'
$runset=Get-Content -LiteralPath $runsetPath -Raw|ConvertFrom-Json
$runset|Add-Member -NotePropertyName qualification_scope -NotePropertyValue 'cell-api-rest'
$workloads=@()
$paths=@('Tests/Release/Xlsx.CellApi.Workload.ps1','Tests/Release/Prepare-XlsxCellApiRunset.ps1')
foreach($name in @('Types.Contract.sql','Types.Safety.sql','Display.Contract.sql','Display.Safety.sql')){
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
Assert-XlsxCellApiWorkload $runset 1 $repo
[IO.File]::WriteAllText($runsetPath,($runset|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
'PASS XLSX_CELL_API private runset prepared; no SQL connection opened'
