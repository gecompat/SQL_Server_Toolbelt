[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedRunsetSha256,
 [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,
 [ValidateSet('Run','Audit')][string]$Action='Run',[switch]$ValidateOnly,[switch]$DescribeOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$private=Join-Path $repo '.runtime'
function Assert-FunctionalLocalPath([string]$Path,[bool]$PrivateOnly=$false){
 $full=[IO.Path]::GetFullPath($Path)
 $boundary=if($PrivateOnly){$private}else{$repo}
 if(-not $full.StartsWith($boundary+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_COPY_FUNCTIONAL_PRIVATE_PATH'}
 $item=Get-Item -LiteralPath $full -Force -ErrorAction Stop
 if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'SSIS_COPY_FUNCTIONAL_REDIRECTED_PATH'}
 if(-not $item.PSIsContainer){$item=$item.Directory}
 while($item -and $item.FullName.Length -ge $boundary.Length){
  if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'SSIS_COPY_FUNCTIONAL_REDIRECTED_PATH'}
  $item=$item.Parent
 }
 return $full
}
$path=Assert-FunctionalLocalPath $RunsetPath $true
if((Get-FileHash -LiteralPath $path).Hash -cne $ExpectedRunsetSha256){throw 'SSIS_COPY_FUNCTIONAL_RUNSET_BINDING'}
$r=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -DateKind String
if($r.schema -cne 'ssis-copy-column-functional/1' -or $r.approved -isnot [bool] -or -not $r.approved -or $r.cases.Count -ne 12){throw 'SSIS_COPY_FUNCTIONAL_DECLARED_SCOPE'}
$keys=@('2019/CU32/150/local','2019/CU32/150/central','2022/CU26/150/local','2022/CU26/150/central','2022/CU26/160/local','2022/CU26/160/central','2025/CU8/150/local','2025/CU8/150/central','2025/CU8/160/local','2025/CU8/160/central','2025/CU8/170/local','2025/CU8/170/central')
for($i=0;$i -lt 12;$i++){$c=$r.cases[$i];if(($c.version+'/'+$c.patch+'/'+$c.cl+'/'+$c.mode) -cne $keys[$i]){throw 'SSIS_COPY_FUNCTIONAL_ROSTER'}}
$start=[DateTimeOffset]::Parse($r.startedUtc);$end=[DateTimeOffset]::Parse($r.deadlineUtc)
if($end -ne $start.AddMinutes(180) -or $start -gt [DateTimeOffset]::UtcNow -or ($Action -ceq 'Run' -and [DateTimeOffset]::UtcNow.AddMinutes(17) -ge $end)){throw 'SSIS_COPY_FUNCTIONAL_ADMISSION_CLOSED'}
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($pin in $r.pins){
 $file=Assert-FunctionalLocalPath $pin.path
 if(-not $file.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($file) -or (Get-FileHash -LiteralPath $file).Hash -cne $pin.sha256){throw 'SSIS_COPY_FUNCTIONAL_INPUT_DRIFT'}
}
foreach($required in @($PSCommandPath,(Join-Path $PSScriptRoot 'Invoke-FreshBuildLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-ProcedureDefinitionLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'),(Join-Path $PSScriptRoot 'Invoke-PackageInstallCases.ps1'),(Join-Path $PSScriptRoot 'Invoke-ComponentsV2Lab.ps1'),(Join-Path $PSScriptRoot 'Invoke-ComponentsV2Audit.ps1'),(Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),$r.archive,$r.framework,(Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.V1.20261114.json'))){
 if(-not $seen.Contains([IO.Path]::GetFullPath($required))){throw 'SSIS_COPY_FUNCTIONAL_REQUIRED_PIN'}
}
$qualification=Get-Content -LiteralPath (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.V1.20261114.json') -Raw|ConvertFrom-Json
if($qualification.result -cne 'PASS_FOR_COMPOSED_DELTA' -or $qualification.qualified_assembly_sha512.ToUpperInvariant() -cne $r.providerSha512){throw 'SSIS_COPY_FUNCTIONAL_QUALIFIED_ARTIFACT'}
$deliveryRecord=Join-Path $PSScriptRoot '../Qualification/CopyColumn.Delivery.20261115.json'
$deliveryRecord=Assert-FunctionalLocalPath $deliveryRecord
if(-not $seen.Contains($deliveryRecord)){throw 'SSIS_COPY_FUNCTIONAL_DELIVERY_PIN'}
$delivery=Get-Content -LiteralPath $deliveryRecord -Raw|ConvertFrom-Json
$expectedArchive=[IO.Path]::GetFullPath((Join-Path $repo $delivery.package.path))
if($delivery.result -cne 'PASS_FOR_DECLARED_SCOPE' -or
   -not [string]::Equals($expectedArchive,[IO.Path]::GetFullPath($r.archive),[StringComparison]::OrdinalIgnoreCase) -or
   (Get-FileHash -LiteralPath $r.archive).Hash.ToLowerInvariant() -cne $delivery.package.sha256 -or
   $r.packageManifestSha256.ToLowerInvariant() -cne $delivery.package.manifest_sha256 -or
   $r.providerSha512.ToLowerInvariant() -cne $delivery.package.provider_sha512){throw 'SSIS_COPY_FUNCTIONAL_DELIVERY_BINDING'}
$products=@(Get-ChildItem -LiteralPath (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Clr') -File|Where-Object Extension -IN @('.cs','.csproj'))
$products+=@(Get-ChildItem -LiteralPath (Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Exchange/Core') -File -Filter '*.cs')
$products+=Get-Item -LiteralPath (Join-Path $repo 'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs')
foreach($sourceFile in $products){
 $relative=[IO.Path]::GetRelativePath($repo,$sourceFile.FullName).Replace('\','/')
 $expected=$qualification.source_sha256.PSObject.Properties[$relative]
 if(-not $seen.Contains($sourceFile.FullName) -or -not $expected -or (Get-FileHash -LiteralPath $sourceFile.FullName).Hash.ToLowerInvariant() -cne [string]$expected.Value){throw 'SSIS_COPY_FUNCTIONAL_PRODUCT_SOURCE'}
}
$framework=Get-Content -LiteralPath $r.framework -Raw|ConvertFrom-Json
if($framework.result -cne 'PASS' -or $framework.scope -cne 'offline-framework' -or $framework.profile -cne 'Full' -or $framework.cases -ne 29 -or $framework.sqlExecuted -isnot [bool] -or $framework.sqlExecuted -or $framework.providerSha512 -cne $r.providerSha512){throw 'SSIS_COPY_FUNCTIONAL_FRAMEWORK'}
$packageRoot=Assert-FunctionalLocalPath $r.packageRoot $true
$manifestPath=Join-Path $packageRoot 'PACKAGE-MANIFEST.json'
if(-not $seen.Contains($manifestPath) -or (Get-FileHash -LiteralPath $manifestPath).Hash -cne $r.packageManifestSha256){throw 'SSIS_COPY_FUNCTIONAL_EXTRACTED_MANIFEST'}
$manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
if($manifest.packageName -cne 'SSIS-Debug-CopyColumnV1-Install-Windows'){throw 'SSIS_COPY_FUNCTIONAL_PACKAGE_NAME'}
foreach($entry in $manifest.files){
 $file=[IO.Path]::GetFullPath((Join-Path $packageRoot $entry.path))
 if(-not $file.StartsWith($packageRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or -not $seen.Contains($file) -or (Get-FileHash -LiteralPath $file).Hash -cne $entry.sha256){throw 'SSIS_COPY_FUNCTIONAL_PAYLOAD'}
}
$provider=Join-Path $packageRoot 'Modules/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.dll'
if((Get-FileHash -LiteralPath $provider -Algorithm SHA512).Hash -cne $r.providerSha512){throw 'SSIS_COPY_FUNCTIONAL_PROVIDER'}
$case=$r.cases[$CaseIndex]
$journal=[IO.Path]::GetFullPath($case.journal)
if(-not $journal.StartsWith($private+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_COPY_FUNCTIONAL_PRIVATE_PATH'}
[void](Assert-FunctionalLocalPath ([IO.Path]::GetDirectoryName($journal)) $true)
if($Action -ceq 'Run' -and (Test-Path -LiteralPath $journal)){throw 'SSIS_COPY_FUNCTIONAL_JOURNAL_COLLISION'}
if($Action -ceq 'Audit' -and -not (Test-Path -LiteralPath $journal -PathType Container)){throw 'SSIS_COPY_FUNCTIONAL_JOURNAL_MISSING'}
# Alle Laufzeitmethoden und Fixtures sind Eingaben des kombinierten Falls.
$execution=@{}
foreach($pin in $r.pins){
 $relative=[IO.Path]::GetRelativePath($repo,$pin.path).Replace('\','/')
 $execution[$relative]=$pin.sha256
}
foreach($folder in @($PSScriptRoot,(Join-Path $PSScriptRoot '../Fixtures'))){
 foreach($file in Get-ChildItem -LiteralPath $folder -File -Recurse){
  if(-not $seen.Contains($file.FullName)){throw 'SSIS_COPY_FUNCTIONAL_METHOD_CLOSURE'}
 }
}
if($r.rightsScope -cne 'synthetic-api-user-and-procedure-login-v1' -or $r.rightsApproved -isnot [bool] -or -not $r.rightsApproved){throw 'SSIS_COPY_FUNCTIONAL_RIGHTS_NOT_APPROVED'}
if($DescribeOnly -and $Action -ceq 'Audit'){throw 'SSIS_COPY_FUNCTIONAL_DESCRIBE_RUN_ONLY'}
if($ValidateOnly -and -not $DescribeOnly){'SSIS_COPY_FUNCTIONAL_ADMISSION_PASS; no SQL';return}
# Der historische kombinierte Fall bleibt bytegleich erhalten. Nur der feste
# Archivname wird vor seiner vorhandenen Komposition ersetzt; Orakel, Rechte,
# Lowpriv-Audit und ein gemeinsames 900s-/60s-Cleanupfenster bleiben erhalten.
$freshMethodPath=Join-Path $PSScriptRoot 'Invoke-FreshBuildLab.ps1'
if((Get-FileHash -LiteralPath $freshMethodPath).Hash -cne '2D80521394D7FB8491FDA2933521E7F92D3BB99A2E16A643BA4EDAC09F136A12'){throw 'SSIS_COPY_FUNCTIONAL_METHOD_CHANGED'}
$method=[IO.File]::ReadAllText($freshMethodPath)
$anchor='$source=[IO.File]::ReadAllText($prior)'
$injection=@'
$source=[IO.File]::ReadAllText($prior)
$oldName="'SSIS-Debug-Qualified-Install-Windows'"
if($source.Split($oldName,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_COPY_FUNCTIONAL_PACKAGE_ANCHOR'}
$source=$source.Replace($oldName,"'SSIS-Debug-CopyColumnV1-Install-Windows'")
'@
if($method.Split($anchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_COPY_FUNCTIONAL_COMPOSITION_ANCHOR'}
$method=$method.Replace($anchor,$injection)
$functionalSourceRoot=$PSScriptRoot
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($method,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_COPY_FUNCTIONAL_SYNTAX'}
foreach($node in @($ast.FindAll({param($n)$n -is [Management.Automation.Language.VariableExpressionAst] -and $n.VariablePath.UserPath -cin @('PSScriptRoot','PSCommandPath')},$true)|Sort-Object {$_.Extent.StartOffset} -Descending)){
 $replacement=if($node.VariablePath.UserPath -ceq 'PSScriptRoot'){'$functionalSourceRoot'}else{'$freshMethodPath'}
 $method=$method.Substring(0,$node.Extent.StartOffset)+$replacement+$method.Substring($node.Extent.EndOffset)
}
$arguments=@{Action=$Action;Version=$case.version;Patch=$case.patch;CompatibilityLevel=$case.cl;DeploymentMode=$case.mode;
 ExpectedTargetKey=$case.targetKey;ExpectedContractSha256=$r.contractSha256;JournalDirectory=$journal;
 SsisReleaseDirectory=(Join-Path $packageRoot 'Modules/toolbelt.tsql.ssis-debug/Artifacts');
 ParserReleaseDirectory=(Join-Path $packageRoot 'Modules/toolbelt.tsql.script-parser/Artifacts');
 QualifiedProviderSha512=$r.providerSha512;ExecutionInputSha256=$execution;QualificationPhase='Full';
 InstallationPackageRoot=$packageRoot;ExpectedPackageManifestSha256=$r.packageManifestSha256;
 ValidateOnly=($ValidateOnly -or $DescribeOnly);DescribeOnly=$DescribeOnly}
. ([scriptblock]::Create($method)) @arguments
