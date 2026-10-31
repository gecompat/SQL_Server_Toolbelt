[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('2019','2022','2025')][string]$Version,
 [string]$Patch='base',
 [Parameter(Mandatory)][ValidateSet('local','central')][string]$Mode,
 [Parameter(Mandatory)][ValidateSet(150,160,170)][int]$CompatibilityLevel,
 [Parameter(Mandatory)][string]$JournalDirectory,
 [Parameter(Mandatory)][string]$ExpectedTargetKey,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedContractSha256,
 [Parameter(Mandatory)][string]$SsisReleaseDirectory,
 [Parameter(Mandatory)][string]$ParserReleaseDirectory,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
 [Parameter(Mandatory)][string]$InputManifestPath,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedInputManifestSha256,
 [Parameter(Mandatory)][string]$LabModuleFile,
 [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedLabCommit,
 [ValidateRange(0,180)][int]$GuiWaitSeconds=0,
 [ValidateSet('Latin1_General_100_BIN2','Latin1_General_100_CS_AS','Latin1_General_100_CI_AS_SC_UTF8')][string]$DatabaseCollation='Latin1_General_100_BIN2',
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -ne 7){throw 'SSIS_ACCESS_POWERSHELL_7_REQUIRED'}
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$journal=[IO.Path]::GetFullPath($JournalDirectory)
$runtime=[IO.Path]::GetFullPath((Join-Path $repository '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not $journal.StartsWith($runtime,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_ACCESS_PRIVATE_JOURNAL_REQUIRED'}
if((Get-FileHash -LiteralPath $InputManifestPath).Hash -cne $ExpectedInputManifestSha256){throw 'SSIS_ACCESS_INPUT_MANIFEST_CHANGED'}
$manifest=Get-Content -LiteralPath $InputManifestPath -Raw|ConvertFrom-Json -Depth 12
if($manifest.schemaVersion -ne 1 -or $manifest.profile -cne 'ssis-current-access' -or -not $manifest.files.Count){throw 'SSIS_ACCESS_INPUT_MANIFEST_SCHEMA'}
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($entry in $manifest.files){
 $path=[IO.Path]::GetFullPath((Join-Path $repository ([string]$entry.path)))
 if(-not $path.StartsWith($repository+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($path)){throw 'SSIS_ACCESS_INPUT_PATH'}
 if([string]$entry.sha256 -cnotmatch '^[0-9A-F]{64}$' -or (Get-FileHash -LiteralPath $path).Hash -cne [string]$entry.sha256){throw 'SSIS_ACCESS_EXECUTION_INPUT_CHANGED'}
}
foreach($relative in @('Invoke-CurrentAccessLab.ps1','Invoke-CurrentAccessCases.ps1','Invoke-CurrentAccessAudit.ps1','Invoke-CurrentWindowsAccessCases.ps1','Invoke-CurrentGuiAccessCase.ps1','CurrentWindowsAccess.sql','Invoke-LabContract.ps1','Invoke-ComponentsV2Audit.ps1','Invoke-CurrentQualificationLab.ps1','Invoke-CurrentQualificationCases.ps1','Invoke-CurrentCases.ps1','../Fixtures/synthetic-8.dtsx')){
 if(-not $seen.Contains([IO.Path]::GetFullPath((Join-Path $PSScriptRoot $relative)))){throw 'SSIS_ACCESS_TRANSITIVE_INPUT_MISSING'}
}
# Der vom Operator ausgewählte Labcode ist kein aus dem Export abgeleiteter
# Codepfad. Sein sauberer Gitstand wird vor jeder Import-/SQL-Operation gebunden.
$labRoot=Split-Path -Parent ([IO.Path]::GetFullPath($LabModuleFile))
if((Split-Path -Leaf $LabModuleFile) -cne 'SqlServerLab.psd1' -or -not (Test-Path -LiteralPath $LabModuleFile)){throw 'SSIS_ACCESS_LAB_MODULE_REQUIRED'}
$labCommit=git -C $labRoot rev-parse HEAD
if($LASTEXITCODE -ne 0 -or $labCommit -cne $ExpectedLabCommit){throw 'SSIS_ACCESS_LAB_COMMIT_CHANGED'}
$labChanges=git -C $labRoot status --porcelain --untracked-files=all
if($LASTEXITCODE -ne 0 -or $labChanges){throw 'SSIS_ACCESS_LAB_WORKTREE_CHANGED'}
$original=Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'
if((Get-FileHash -LiteralPath $original).Hash -cne '4411A966484EAF55FB05778B5E26829D7AFED94D6028CB6F77323F92C5C7E570'){throw 'SSIS_ACCESS_ORIGINAL_HARNESS_CHANGED'}
$binder=Join-Path $PSScriptRoot 'Invoke-CurrentQualificationLab.ps1'
$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseFile($binder,[ref]$null,[ref]$errors)
$definition=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Bind-CurrentScriptRoot'},$true))
if($errors.Count -or $definition.Count -ne 1){throw 'SSIS_ACCESS_ROOT_BINDER_INVALID'}
. ([scriptblock]::Create($definition[0].Extent.Text))
$text=[IO.File]::ReadAllText($original)
foreach($line in @($text -split "`n"|Where-Object {$_ -match 'Invoke-(CoreContract|ApiCases|ReleaseRightsCases|LifecycleCases)\.ps1'})){
 if(($text.Split($line).Count-1) -ne 1){throw 'SSIS_ACCESS_CASE_HOOK_AMBIGUOUS'}
 $text=$text.Replace($line,'')
}
$anchor="    `$phase=`$mode+'-repeat';Batches `$connection ([IO.File]::ReadAllText((Join-Path `$ssisRelease 'Deploy.WithAssembly.sql'))) `$mode"
if(($text.Split($anchor).Count-1) -ne 1){throw 'SSIS_ACCESS_INSTALL_HOOK_AMBIGUOUS'}
$literal="'"+$LabModuleFile.Replace("'","''")+"'"
$call=@'
    $phase=$mode+'-current-access'
    & (Join-Path $PSScriptRoot 'Invoke-CurrentAccessCases.ps1') -Connection $connection -MasterConnection $master -AdminConnectionString $builder.ConnectionString -CrossDatabase $clientDatabase -RunId $runId -JournalPath (Join-Path $journalRoot 'identity.json') -LabModuleFile __LABMODULE__ -TargetRunId ([string]$target.runId) -TargetInstanceId ([string]$target.instanceId) -QualifiedProviderSha512 $qualifiedProvider -GuiWaitSeconds __GUIWAIT__
'@
$text=$text.Replace($anchor,$anchor+"`n"+$call.Replace('__LABMODULE__',$literal).Replace('__GUIWAIT__',[string]$GuiWaitSeconds))
$adapted=Bind-CurrentScriptRoot -Text $text -Root $PSScriptRoot
[void][Management.Automation.Language.Parser]::ParseInput($adapted,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_ACCESS_ADAPTED_HARNESS_SYNTAX'}
if($ValidateOnly){'SSIS_CURRENT_ACCESS_ADAPTER_VALIDATED; no SQL';return}
& ([scriptblock]::Create($adapted)) -Version $Version -Patch $Patch -Modes @($Mode) -CompatibilityLevel $CompatibilityLevel -Full -JournalDirectory $journal -ExpectedTargetKey $ExpectedTargetKey -ExpectedContractSha256 $ExpectedContractSha256 -SsisReleaseDirectory $SsisReleaseDirectory -ParserReleaseDirectory $ParserReleaseDirectory -QualifiedProviderSha512 $QualifiedProviderSha512 -DatabaseCollation $DatabaseCollation
