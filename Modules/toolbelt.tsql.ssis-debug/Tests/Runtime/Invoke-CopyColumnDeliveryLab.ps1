[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedRunsetSha256,
 [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,
 [ValidateSet('Run','Audit')][string]$Action='Run',[switch]$ValidateOnly,[switch]$DescribeOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$private=Join-Path $repo '.runtime'
function Assert-DeliveryLocalPath([string]$Path,[bool]$PrivateOnly=$false){
 $full=[IO.Path]::GetFullPath($Path)
 $boundary=if($PrivateOnly){$private}else{$repo}
 if(-not $full.StartsWith($boundary+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_COPY_DELIVERY_PRIVATE_PATH'}
 $item=Get-Item -LiteralPath $full -Force -ErrorAction Stop
 if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'SSIS_COPY_DELIVERY_REDIRECTED_PATH'}
 if(-not $item.PSIsContainer){$item=$item.Directory}
 while($item -and $item.FullName.Length -ge $boundary.Length){
  if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'SSIS_COPY_DELIVERY_REDIRECTED_PATH'}
  $item=$item.Parent
 }
 return $full
}
$path=Assert-DeliveryLocalPath $RunsetPath $true
if((Get-FileHash -LiteralPath $path).Hash -cne $ExpectedRunsetSha256){throw 'SSIS_COPY_DELIVERY_RUNSET_BINDING'}
$r=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -DateKind String
if($r.schema -cne 'ssis-copy-column-zip-delivery/1' -or $r.approved -isnot [bool] -or -not $r.approved -or $r.cases.Count -ne 12){throw 'SSIS_COPY_DELIVERY_DECLARED_SCOPE'}
$keys=@('2019/CU32/150/local','2019/CU32/150/central','2022/CU26/150/local','2022/CU26/150/central','2022/CU26/160/local','2022/CU26/160/central','2025/CU8/150/local','2025/CU8/150/central','2025/CU8/160/local','2025/CU8/160/central','2025/CU8/170/local','2025/CU8/170/central')
for($i=0;$i -lt 12;$i++){$c=$r.cases[$i];if(($c.version+'/'+$c.patch+'/'+$c.cl+'/'+$c.mode) -cne $keys[$i]){throw 'SSIS_COPY_DELIVERY_ROSTER'}}
$start=[DateTimeOffset]::Parse($r.startedUtc);$end=[DateTimeOffset]::Parse($r.deadlineUtc)
if($end -ne $start.AddMinutes(60) -or $start -gt [DateTimeOffset]::UtcNow -or ($Action -ceq 'Run' -and [DateTimeOffset]::UtcNow.AddMinutes(8) -ge $end)){throw 'SSIS_COPY_DELIVERY_ADMISSION_CLOSED'}
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($pin in $r.pins){
 $file=Assert-DeliveryLocalPath $pin.path
 if(-not $file.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($file) -or (Get-FileHash -LiteralPath $file).Hash -cne $pin.sha256){throw 'SSIS_COPY_DELIVERY_INPUT_DRIFT'}
}
foreach($required in @($PSCommandPath,(Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'),(Join-Path $PSScriptRoot 'Invoke-PackageInstallCases.ps1'),(Join-Path $PSScriptRoot 'Invoke-ComponentsV2Lab.ps1'),(Join-Path $PSScriptRoot 'Invoke-ComponentsV2Audit.ps1'),(Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),$r.archive,$r.framework,(Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.V1.20261114.json'))){
 if(-not $seen.Contains([IO.Path]::GetFullPath($required))){throw 'SSIS_COPY_DELIVERY_REQUIRED_PIN'}
}
$qualification=Get-Content -LiteralPath (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.V1.20261114.json') -Raw|ConvertFrom-Json
if($qualification.result -cne 'PASS_FOR_COMPOSED_DELTA' -or $qualification.qualified_assembly_sha512.ToUpperInvariant() -cne $r.providerSha512){throw 'SSIS_COPY_DELIVERY_QUALIFIED_ARTIFACT'}
$products=@(Get-ChildItem -LiteralPath (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Clr') -File|Where-Object Extension -IN @('.cs','.csproj'))
$products+=@(Get-ChildItem -LiteralPath (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Exchange/Core') -File -Filter '*.cs')
$products+=Get-Item -LiteralPath (Join-Path $repo 'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs')
foreach($sourceFile in $products){
 $relative=[IO.Path]::GetRelativePath($repo,$sourceFile.FullName).Replace('\','/')
 $expected=$qualification.source_sha256.PSObject.Properties[$relative]
 if(-not $seen.Contains($sourceFile.FullName) -or -not $expected -or (Get-FileHash -LiteralPath $sourceFile.FullName).Hash.ToLowerInvariant() -cne [string]$expected.Value){throw 'SSIS_COPY_DELIVERY_PRODUCT_SOURCE'}
}
$framework=Get-Content -LiteralPath $r.framework -Raw|ConvertFrom-Json
if($framework.result -cne 'PASS' -or $framework.scope -cne 'offline-framework' -or $framework.profile -cne 'Full' -or $framework.cases -ne 29 -or $framework.sqlExecuted -isnot [bool] -or $framework.sqlExecuted -or $framework.providerSha512 -cne $r.providerSha512){throw 'SSIS_COPY_DELIVERY_FRAMEWORK'}
$packageRoot=Assert-DeliveryLocalPath $r.packageRoot $true
$manifestPath=Join-Path $packageRoot 'PACKAGE-MANIFEST.json'
if(-not $seen.Contains($manifestPath) -or (Get-FileHash -LiteralPath $manifestPath).Hash -cne $r.packageManifestSha256){throw 'SSIS_COPY_DELIVERY_EXTRACTED_MANIFEST'}
$manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
if($manifest.packageName -cne 'SSIS-Debug-CopyColumnV1-Install-Windows'){throw 'SSIS_COPY_DELIVERY_PACKAGE_NAME'}
foreach($entry in $manifest.files){
 $file=[IO.Path]::GetFullPath((Join-Path $packageRoot $entry.path))
 if(-not $file.StartsWith($packageRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or -not $seen.Contains($file) -or (Get-FileHash -LiteralPath $file).Hash -cne $entry.sha256){throw 'SSIS_COPY_DELIVERY_PAYLOAD'}
}
$provider=Join-Path $packageRoot 'Modules/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.dll'
if((Get-FileHash -LiteralPath $provider -Algorithm SHA512).Hash -cne $r.providerSha512){throw 'SSIS_COPY_DELIVERY_PROVIDER'}
$case=$r.cases[$CaseIndex]
$journal=Assert-DeliveryLocalPath $case.journal $true
if($ValidateOnly -and -not $DescribeOnly){'SSIS_COPY_DELIVERY_ADMISSION_PASS; no SQL';return}
if($Action -ceq 'Audit' -and -not $DescribeOnly){
 $file=Join-Path $journal 'target-1.json'
 & (Join-Path $PSScriptRoot 'Invoke-ComponentsV2Audit.ps1') -Version $case.version -Patch $case.patch -ExpectedTargetKey $case.targetKey -ExpectedContractSha256 $r.contractSha256 -JournalPath $file -ExpectedJournalSha256 (Get-FileHash -LiteralPath $file).Hash
 return
}
$source=Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'
if((Get-FileHash -LiteralPath $source).Hash -cne '4411A966484EAF55FB05778B5E26829D7AFED94D6028CB6F77323F92C5C7E570'){throw 'SSIS_COPY_DELIVERY_OWNED_HARNESS'}
$text=[IO.File]::ReadAllText($source)
$old="'SSIS-Debug-1.0.0-Install-Windows'"
if($text.Split($old,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_COPY_DELIVERY_PACKAGE_ANCHOR'}
$text=$text.Replace($old,"'SSIS-Debug-CopyColumnV1-Install-Windows'")
# Bereits gültige Fach-/API-Quellnachweise werden wiederverwendet. Die neue
# Archivschnittstelle führt ausschließlich ihren echten Installationsfall aus.
$line=@($text -split "`n"|Where-Object {$_ -match 'Invoke-ApiCases\.ps1'})
if($line.Count -ne 1 -or $text.Split($line[0],[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_COPY_DELIVERY_API_ANCHOR'}
$text=$text.Replace($line[0],'')
$errors=$null;$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ComponentsV2Lab.ps1'),[ref]$null,[ref]$errors)
$binders=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Bind-ComponentsV2ScriptRoot'},$true))
if($errors.Count -or $binders.Count -ne 1){throw 'SSIS_COPY_DELIVERY_BINDER'}
. ([scriptblock]::Create($binders[0].Extent.Text))
$bound=Bind-ComponentsV2ScriptRoot $text $PSScriptRoot
if($DescribeOnly){$bound;return}
& ([scriptblock]::Create($bound)) -Version $case.version -Patch $case.patch -Modes @($case.mode) -ApiOnly -CompatibilityLevel $case.cl -JournalDirectory $journal -ExpectedTargetKey $case.targetKey -ExpectedContractSha256 $r.contractSha256 -InstallationPackageRoot $packageRoot -QualifiedProviderSha512 $r.providerSha512
