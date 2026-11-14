[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
      [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedRunsetSha256,
      [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,
      [ValidateSet('Run','Audit')][string]$Action='Run',[switch]$ValidateOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$private=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))+[IO.Path]::DirectorySeparatorChar
$path=[IO.Path]::GetFullPath($RunsetPath)
if(-not $path.StartsWith($private,[StringComparison]::OrdinalIgnoreCase) -or (Get-FileHash -LiteralPath $path).Hash -cne $ExpectedRunsetSha256){throw 'SSIS_COPY_RUNSET_BINDING'}
$runset=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -DateKind String
if($runset.schema -cne 'ssis-copy-column-v1' -or $runset.approved -isnot [bool] -or -not $runset.approved -or $runset.cases.Count -ne 12){throw 'SSIS_COPY_AUTHORITY_SCOPE'}
$keys=@('2019/CU32/150/local','2019/CU32/150/central','2022/CU26/150/local','2022/CU26/150/central','2022/CU26/160/local','2022/CU26/160/central','2025/CU8/150/local','2025/CU8/150/central','2025/CU8/160/local','2025/CU8/160/central','2025/CU8/170/local','2025/CU8/170/central')
for($i=0;$i -lt 12;$i++){$c=$runset.cases[$i];if(($c.version+'/'+$c.patch+'/'+$c.cl+'/'+$c.mode) -cne $keys[$i]){throw 'SSIS_COPY_CASE_ROSTER'}}
$started=[DateTimeOffset]::Parse($runset.startedUtc);$deadline=[DateTimeOffset]::Parse($runset.deadlineUtc)
if($deadline -ne $started.AddMinutes(60) -or $started -gt [DateTimeOffset]::UtcNow -or ($Action -ceq 'Run' -and [DateTimeOffset]::UtcNow.AddMinutes(7) -ge $deadline)){throw 'SSIS_COPY_ADMISSION_CLOSED'}
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($pin in $runset.pins){
 $file=[IO.Path]::GetFullPath($pin.path)
 if(-not $file.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($file) -or (Get-FileHash -LiteralPath $file).Hash -cne $pin.sha256){throw 'SSIS_COPY_INPUT_DRIFT'}
}
foreach($required in @($PSCommandPath,(Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'),(Join-Path $PSScriptRoot 'Invoke-CopyColumnCases.ps1'),(Join-Path $PSScriptRoot 'Invoke-CurrentCases.ps1'),(Join-Path $PSScriptRoot 'Invoke-ComponentsV2Lab.ps1'),(Join-Path $PSScriptRoot 'Invoke-ComponentsV2Audit.ps1'),(Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){if(-not $seen.Contains([IO.Path]::GetFullPath($required))){throw 'SSIS_COPY_REQUIRED_PIN'}}
if(-not $seen.Contains([IO.Path]::GetFullPath($runset.framework))){throw 'SSIS_COPY_FRAMEWORK_PIN'}
$framework=Get-Content -LiteralPath $runset.framework -Raw|ConvertFrom-Json
if($framework.result -cne 'PASS' -or $framework.scope -cne 'offline-framework' -or $framework.profile -cne 'Full' -or $framework.cases -ne 29 -or $framework.sqlExecuted -isnot [bool] -or $framework.sqlExecuted -or $framework.providerSha512 -cne $runset.providerSha512){throw 'SSIS_COPY_FRAMEWORK_BINDING'}
foreach($folder in @('Clr','Exchange/Core')){
 foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo "Modules/toolbelt.tsql.ssis-debug/$folder") -File|Where-Object Extension -IN @('.cs','.csproj')){
  if(-not $seen.Contains($source.FullName)){throw 'SSIS_COPY_PRODUCT_PIN'}
 }
}
foreach($format in @(6,8)){foreach($kind in @('int','text')){if(-not $seen.Contains([IO.Path]::GetFullPath((Join-Path $runset.fixtureRoot "format-$format/copy-column-$kind/package.dtsx")))){throw 'SSIS_COPY_FIXTURE_PIN'}}}
$case=$runset.cases[$CaseIndex]
if(-not ([IO.Path]::GetFullPath($case.journal)).StartsWith($private,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_COPY_JOURNAL_SCOPE'}
$caseProfile=if($runset.PSObject.Properties['caseProfile']){[string]$runset.caseProfile}else{'explain'}
if($caseProfile -cnotin @('explain','procedure-guard-only') -or ($caseProfile -ceq 'procedure-guard-only' -and $CaseIndex -notin 10,11)){throw 'SSIS_COPY_CASE_PROFILE'}
if($ValidateOnly){'SSIS_COPY_COLUMN_ADMISSION_PASS; no SQL';return}
if($Action -ceq 'Audit'){
 $journal=Join-Path $case.journal 'target-1.json'
 & (Join-Path $PSScriptRoot 'Invoke-ComponentsV2Audit.ps1') -Version $case.version -Patch $case.patch -ExpectedTargetKey $case.targetKey -ExpectedContractSha256 $runset.contractSha256 -JournalPath $journal -ExpectedJournalSha256 (Get-FileHash -LiteralPath $journal).Hash
 return
}
$original=Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'
if((Get-FileHash -LiteralPath $original).Hash -cne '4411A966484EAF55FB05778B5E26829D7AFED94D6028CB6F77323F92C5C7E570'){throw 'SSIS_COPY_OWNED_HARNESS_CHANGED'}
$text=[IO.File]::ReadAllText($original)
$anchor="& (Join-Path `$PSScriptRoot 'Invoke-ApiCases.ps1') -Connection `$connection"
if($text.Split($anchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_COPY_CASE_HOOK'}
$fixture=$runset.fixtureRoot.Replace("'","''")
$guard=if($caseProfile -ceq 'procedure-guard-only'){' -ProcedureGuardOnly'}else{''}
$text=$text.Replace($anchor,"& (Join-Path `$PSScriptRoot 'Invoke-CopyColumnCases.ps1') -Connection `$connection -FixtureRoot '$fixture'$guard")
# Der geprüfte Binder ersetzt nur AST-Variablen, keine SQL-/Metadatenliterale.
$errors=$null;$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ComponentsV2Lab.ps1'),[ref]$null,[ref]$errors)
$binders=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Bind-ComponentsV2ScriptRoot'},$true))
if($errors.Count -or $binders.Count -ne 1){throw 'SSIS_COPY_BINDER_SCOPE'}
. ([scriptblock]::Create($binders[0].Extent.Text))
$text=Bind-ComponentsV2ScriptRoot $text $PSScriptRoot
& ([scriptblock]::Create($text)) -Version $case.version -Patch $case.patch -Modes @($case.mode) -ApiOnly -CompatibilityLevel $case.cl -JournalDirectory $case.journal -ExpectedTargetKey $case.targetKey -ExpectedContractSha256 $runset.contractSha256 -SsisReleaseDirectory $runset.ssisRelease -ParserReleaseDirectory $runset.parserRelease -QualifiedProviderSha512 $runset.providerSha512
