[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunRoot,[Parameter(Mandatory)][string]$FixtureOutput,
      [Parameter(Mandatory)][string]$PythonPath,[Parameter(Mandatory)][string]$PackagePath,
      [Parameter(Mandatory)][string]$QualifiedFixtureDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
& (Join-Path $PSScriptRoot 'Prepare-XlsxCellApiRunset.ps1') @PSBoundParameters -QualificationScope cell-client-rest
if(-not $?){throw 'XLSX_COMPOSITION_BASE_PREPARATION'}
$path=Join-Path $RunRoot 'runset.json';$runset=Get-Content $path -Raw|ConvertFrom-Json
. (Join-Path $PSScriptRoot 'Xlsx.CompositionConsumer.Workload.ps1')
$unconfirmed=Join-Path $FixtureOutput 'Uninstall-Unconfirmed.sql'
[IO.File]::WriteAllText($unconfirmed,(Read-XlsxSql (Join-Path $repo 'Modules/toolbelt.file.xlsx-memory/Deployment/Uninstall.sql') @{ConfirmNoExternalConsumers=0}),[Text.UTF8Encoding]::new($false))
$source=Join-Path $repo 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql'
$fixture=Join-Path $FixtureOutput 'Display.Lifecycle.sql';Copy-Item -LiteralPath $source -Destination $fixture
$runset.workbooks=@([pscustomobject]@{name='Display.Lifecycle.sql';path=$fixture;
    sha256=(Get-FileHash $source).Hash.ToLowerInvariant();expected_error='NONE'})
$helpers=[ordered]@{}
foreach($name in @('Types.Metadata.ps1','Display.Metadata.ps1','Invoke-TypesComposition.ps1','Invoke-DisplayComposition.ps1')){
    $helpers[$name]=Join-Path $repo ('Modules/toolbelt.file.xlsx-memory/Tests/Runtime/'+$name)
}
$runset.qualification_scope='composition-consumer-rest'
$runset|Add-Member -NotePropertyName composition_consumer -NotePropertyValue ([pscustomobject]@{unconfirmed=$unconfirmed;helpers=[pscustomobject]$helpers})
$extra=@($source,$fixture,$unconfirmed,$PSCommandPath,
    (Join-Path $PSScriptRoot 'Xlsx.CompositionConsumer.Workload.ps1'),
    (Join-Path $PSScriptRoot 'Test-XlsxCompositionConsumerAdmission.ps1'),
    (Join-Path $PSScriptRoot 'Xlsx.OwnedDatabase.ps1'),
    (Join-Path $PSScriptRoot 'Xlsx.CallerCatalog.Workload.ps1'),
    (Join-Path $PSScriptRoot 'Xlsx.LifecycleNegative.Workload.ps1'),
    (Join-Path $repo 'Tests/CI/run-xlsx-types-lab.ps1'))
$extra+=@($helpers.Values)
foreach($name in @('Types.Composition.xlsx','Types.Composition.sql','Display.Composition.sql')){
    $extra+=@(Join-Path $repo ('Modules/toolbelt.file.xlsx-memory/Tests/Runtime/'+$name))
}
foreach($file in $extra){
    $existing=@($runset.pins|Where-Object path -CEQ $file)
    if($existing.Count){
        if($existing.Count -ne 1 -or $existing[0].sha256 -cne (Get-FileHash $file).Hash){throw 'XLSX_COMPOSITION_PREPARATION_PIN_DRIFT'}
    }else{$runset.pins+=@([pscustomobject]@{path=$file;sha256=(Get-FileHash $file).Hash})}
}
Assert-XlsxCompositionConsumerInputs $runset $repo
[IO.File]::WriteAllText($path,($runset|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
'PASS XLSX_COMPOSITION_CONSUMER original helpers and fixture bytes prepared; no SQL'
