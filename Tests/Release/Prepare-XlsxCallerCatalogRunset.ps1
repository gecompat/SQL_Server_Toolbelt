[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunRoot,[Parameter(Mandatory)][string]$FixtureOutput,
      [Parameter(Mandatory)][string]$PythonPath,[Parameter(Mandatory)][string]$PackagePath,
      [Parameter(Mandatory)][string]$QualifiedFixtureDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
& (Join-Path $PSScriptRoot 'Prepare-XlsxCellApiRunset.ps1') @PSBoundParameters -QualificationScope cell-client-rest
if(-not $?){throw 'XLSX_CALLER_CATALOG_BASE_PREPARATION'}
$path=Join-Path $RunRoot 'runset.json';$runset=Get-Content $path -Raw|ConvertFrom-Json
. (Join-Path $PSScriptRoot 'Xlsx.CallerCatalog.Workload.ps1')
$binary=@($runset.artifacts|Where-Object module_id -CEQ 'toolbelt.file.xlsx-memory')
if($binary.Count -ne 1){throw 'XLSX_CALLER_CATALOG_CURRENT_ARTIFACT'}
$bits='0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($binary[0].path))
$install=@{}
foreach($mode in @('local','central')){
    $text=Read-XlsxSql (Join-Path $repo 'Modules/toolbelt.file.xlsx-memory/Deployment/Deploy.sql') @{DeploymentMode=$mode;AssemblyBits=$bits}
    $file=Join-Path $FixtureOutput ('Caller-Xlsx-'+$mode+'.sql')
    [IO.File]::WriteAllText($file,$text,[Text.UTF8Encoding]::new($false));$install[$mode]=$file
}
$uninstall=Join-Path $FixtureOutput 'Caller-Xlsx-Uninstall.sql'
$text=Read-XlsxSql (Join-Path $repo 'Modules/toolbelt.file.xlsx-memory/Deployment/Uninstall.sql') @{ConfirmNoExternalConsumers=1}
[IO.File]::WriteAllText($uninstall,$text,[Text.UTF8Encoding]::new($false))
$source=Join-Path $repo 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql'
$fixture=Join-Path $FixtureOutput 'Display.Lifecycle.sql';Copy-Item -LiteralPath $source -Destination $fixture
$runset.workbooks=@([pscustomobject]@{name='Display.Lifecycle.sql';path=$fixture;
    sha256=(Get-FileHash $source -Algorithm SHA256).Hash.ToLowerInvariant();expected_error='NONE'})
$runset.qualification_scope='caller-catalog-rest'
$runset|Add-Member -NotePropertyName caller_catalog -NotePropertyValue ([pscustomobject]@{install=$install;uninstall=$uninstall})
$extra=@($install.local,$install.central,$uninstall,$source,$fixture,$PSCommandPath,
 (Join-Path $PSScriptRoot 'Xlsx.CallerCatalog.Workload.ps1'),
 (Join-Path $PSScriptRoot 'Xlsx.LifecycleNegative.Workload.ps1'),
 (Join-Path $PSScriptRoot 'Test-XlsxCallerCatalogAdmission.ps1'),
 (Join-Path $repo 'Tests/CI/run-xlsx-types-lab.ps1'))
foreach($file in $extra){
    $existing=@($runset.pins|Where-Object path -CEQ $file)
    if($existing.Count){
        if($existing.Count -ne 1 -or $existing[0].sha256 -cne (Get-FileHash $file -Algorithm SHA256).Hash){throw 'XLSX_CALLER_CATALOG_PREPARATION_PIN_DRIFT'}
    }else{$runset.pins+=@([pscustomobject]@{path=$file;sha256=(Get-FileHash $file -Algorithm SHA256).Hash})}
}
Assert-XlsxCallerCatalogInputs $runset $repo
[IO.File]::WriteAllText($path,($runset|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
'PASS XLSX_CALLER_CATALOG_NEGATIVE current sources and original caller/catalog helpers prepared; no SQL'
