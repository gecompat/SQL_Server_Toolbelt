# Source-/Paketvorbereitung ohne Verbindung; keine Sourceänderung am Vorgänger.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunRoot,[Parameter(Mandatory)][string]$FixtureOutput,
      [Parameter(Mandatory)][string]$PythonPath,[Parameter(Mandatory)][string]$PackagePath,
      [Parameter(Mandatory)][string]$QualifiedFixtureDirectory,[Parameter(Mandatory)][string]$LegacyDirectory,
      [Parameter(Mandatory)][string]$ReproDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$legacy=[IO.Path]::GetFullPath($LegacyDirectory)
$baseParameters=@{}+$PSBoundParameters;[void]$baseParameters.Remove('LegacyDirectory');[void]$baseParameters.Remove('ReproDirectory')
& (Join-Path $PSScriptRoot 'Prepare-XlsxCellApiRunset.ps1') @baseParameters -QualificationScope cell-client-rest
if(-not $?){throw 'XLSX_GENUINE10_BASE_PREPARATION'}
$path=Join-Path $RunRoot 'runset.json';$runset=Get-Content $path -Raw|ConvertFrom-Json
$module=Join-Path $legacy 'original/Modules/toolbelt.file.xlsx-memory'
$provenance=Join-Path $legacy 'LegacyProvenance.json'
$p=Get-Content $provenance -Raw|ConvertFrom-Json
$binary=Join-Path $module 'Artifacts/Toolbelt.File.XlsxMemory.dll'
$repro=Join-Path ([IO.Path]::GetFullPath($ReproDirectory)) 'original/Modules/toolbelt.file.xlsx-memory/Artifacts/Toolbelt.File.XlsxMemory.dll'
if($p.revision -cne 'fdafa8038e4d5240dd727096f144c8d5fd884117' -or $p.moduleVersion -cne '1.0.0' -or
   (Get-FileHash $binary -Algorithm SHA512).Hash -cne $p.assemblySHA512 -or
   (Get-FileHash $repro -Algorithm SHA512).Hash -cne $p.assemblySHA512){throw 'XLSX_GENUINE10_BUILD_PROVENANCE'}
$artifact=[pscustomobject]@{module_id='toolbelt.file.xlsx-memory';sql_name='Toolbelt_File_XlsxMemory';path=$binary;
 sha256=(Get-FileHash $binary -Algorithm SHA256).Hash;sha512=(Get-FileHash $binary -Algorithm SHA512).Hash}
$install=@{};$bits='0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($binary))
$parseErrors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tests/CI/run-xlsx-types-lab.ps1'),[ref]$null,[ref]$parseErrors)
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Read-XlsxSql'},$true))
if($parseErrors.Count -or $nodes.Count -ne 1){throw 'XLSX_GENUINE10_SQL_READER'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($mode in @('local','central')){
    $text=Read-XlsxSql (Join-Path $module 'Deployment/Deploy.sql') @{DeploymentMode=$mode;AssemblyBits=$bits}
    if($text -match '\$\(' -or $text -match '(?m)^\s*:'){throw 'XLSX_GENUINE10_TEMPLATE_UNRESOLVED'}
    $file=Join-Path $FixtureOutput ('Legacy10-'+$mode+'.sql');[IO.File]::WriteAllText($file,$text,[Text.UTF8Encoding]::new($false));$install[$mode]=$file
}
$remove=Join-Path $FixtureOutput 'Remove-Current-Xlsx.sql'
$text=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.file.xlsx-memory/Deployment/Uninstall.sql')).Replace('$(ConfirmNoExternalConsumers)','1')
$text=[regex]::Replace($text,'(?im)^\s*:On\s+Error\s+exit\s*$','')
if($text -match '\$\(' -or $text -match '(?m)^\s*:'){throw 'XLSX_GENUINE10_REMOVE_TEMPLATE'}
[IO.File]::WriteAllText($remove,$text,[Text.UTF8Encoding]::new($false))
$runset.qualification_scope='genuine10-rest'
$runset|Add-Member -NotePropertyName legacy -NotePropertyValue ([pscustomobject]@{module=$module;provenance=$provenance;artifact=$artifact;repro=$repro;install=$install;remove_current=$remove})
$extra=@($provenance,$binary,$repro,$remove,$install.local,$install.central,
 (Join-Path $repo 'Tests/Release/Xlsx.Genuine10.Workload.ps1'),$PSCommandPath,
 (Join-Path $repo 'Modules/toolbelt.file.xlsx-memory/Scripts/New-Xlsx10LegacyFixture.ps1'),
 (Join-Path $repo 'Tests/CI/run-xlsx-types-lab.ps1'))
$extra+=@($p.sourcePins.PSObject.Properties|ForEach-Object{Join-Path $module $_.Name})
foreach($file in $extra){
    if(@($runset.pins|Where-Object path -CEQ $file).Count){throw 'XLSX_GENUINE10_DUPLICATE_PIN'}
    $runset.pins+=@([pscustomobject]@{path=$file;sha256=(Get-FileHash $file -Algorithm SHA256).Hash})
}
. (Join-Path $PSScriptRoot 'Xlsx.Genuine10.Workload.ps1')
Assert-XlsxGenuine10Inputs $runset $repo
[IO.File]::WriteAllText($path,($runset|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
'PASS XLSX_GENUINE10 original source and current package prepared; no SQL'
