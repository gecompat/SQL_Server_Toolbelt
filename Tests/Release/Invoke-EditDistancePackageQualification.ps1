[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunsetPath,
    [Parameter(Mandatory)][string]$OutputPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$runtime = Join-Path $root '.runtime'
$output = [IO.Path]::GetFullPath($OutputPath)
if (-not [string]::Equals([IO.Path]::GetDirectoryName($output), $runtime, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'EDIT_DISTANCE_OUTPUT_SCOPE'
}
foreach ($scopePath in @($runtime)) {
    if (Test-Path -LiteralPath $scopePath) {
        $scopeItem = Get-Item -LiteralPath $scopePath -Force
        if (($scopeItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or -not $scopeItem.PSIsContainer) {
            throw 'EDIT_DISTANCE_RUNTIME_SCOPE'
        }
    }
}
if ((Test-Path -LiteralPath $output) -or (Test-Path -LiteralPath ($output + '.stages'))) { throw 'EDIT_DISTANCE_OUTPUT_NOT_FRESH' }
$runsetFile = (Resolve-Path -LiteralPath $RunsetPath).Path
$runset = Get-Content -LiteralPath $runsetFile -Raw | ConvertFrom-Json
if ($runset.schema -cne 'edit-distance-package-runset/v1') { throw 'EDIT_DISTANCE_RUNSET_SCHEMA' }
if (@($runset.PSObject.Properties.Name | Sort-Object) -join ',' -cne 'schema,tools' -or
    @($runset.tools.PSObject.Properties.Name | Sort-Object) -join ',' -cne 'python,roslyn_csc,windows_powershell') {
    throw 'EDIT_DISTANCE_RUNSET_FIELDS'
}
foreach ($toolName in @('python','roslyn_csc','windows_powershell')) {
    $toolRecord = $runset.tools.$toolName
    if (@($toolRecord.PSObject.Properties.Name | Sort-Object) -join ',' -cne 'path,sha256' -or
        -not [IO.Path]::IsPathRooted([string]$toolRecord.path) -or
        [string]$toolRecord.sha256 -notmatch '^[0-9a-fA-F]{64}$') {
        throw 'EDIT_DISTANCE_RUNSET_TOOL_FIELDS'
    }
}

$moduleRoot = Join-Path $root 'Modules/toolbelt.string.edit-distance'
if ($PSEdition -cne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) { throw 'EDIT_DISTANCE_REQUIRES_PWSH7' }
. (Join-Path $moduleRoot 'Scripts/Invoke-OwnedProcess.ps1')
$python = [string]$runset.tools.python.path
$csc = [string]$runset.tools.roslyn_csc.path
$winps = [string]$runset.tools.windows_powershell.path
$toolHashes = [ordered]@{}
foreach ($tool in @(
    [pscustomobject]@{Path=$python;Sha256=[string]$runset.tools.python.sha256},
    [pscustomobject]@{Path=$csc;Sha256=[string]$runset.tools.roslyn_csc.sha256},
    [pscustomobject]@{Path=$winps;Sha256=[string]$runset.tools.windows_powershell.sha256}
)) {
    if (-not (Test-Path -LiteralPath $tool.Path -PathType Leaf)) { throw 'EDIT_DISTANCE_TOOL_MISSING' }
    $actual = (Get-FileHash -LiteralPath $tool.Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -cne $tool.Sha256.ToLowerInvariant()) { throw 'EDIT_DISTANCE_TOOL_PIN' }
    $toolHashes[[IO.Path]::GetFileName($tool.Path)] = $actual
}

$stageDir = $output + '.stages'
$null = [IO.Directory]::CreateDirectory($stageDir)
$stages = [Collections.Generic.List[object]]::new()
function Invoke-CapturedStage([string]$Name, [string]$File, [string[]]$Arguments, [int]$TimeoutMs) {
    $result = Invoke-OwnedProcess -FileName $File -Arguments $Arguments -TimeoutMilliseconds $TimeoutMs
    $record = [ordered]@{ stage=$Name; exit_code=$result.ExitCode; stdout=$result.Stdout; stderr=$result.Stderr; capture_complete=$result.CaptureComplete }
    $stages.Add($record)
    $safeName = $Name -replace '[^A-Za-z0-9_-]', '_'
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($record | ConvertTo-Json -Depth 4))
    [IO.File]::WriteAllBytes((Join-Path $stageDir ($safeName + '.private.json')), $bytes)
    if ($result.ExitCode -ne 0 -or $result.Stderr.Length -ne 0 -or -not $result.CaptureComplete) {
        throw ('EDIT_DISTANCE_STAGE_' + $Name)
    }
    return $result.Stdout
}

$helper = Join-Path $root 'Scripts/Release/edit_distance_package.py'
$contract = Join-Path $root 'Tests/Release/EditDistancePackageContract.cs'
$ilScript = Join-Path $root 'Tests/Release/Test-EditDistancePackageIL.ps1'
$referenceScript = Join-Path $moduleRoot 'Tests/Framework/reference.py'
$goldenScript = Join-Path $moduleRoot 'Tests/Framework/make_goldens.py'
$jaroOracle = Join-Path $moduleRoot 'Tests/Framework/JaroContract.cs'
$hiddenPython = Join-Path $root 'Tests/Release/run_hidden_python.py'
$hiddenProbe = Join-Path $root 'Tests/Release/hidden_python_probe.py'
$ownedHelper = Join-Path $moduleRoot 'Scripts/Invoke-OwnedProcess.ps1'
$qualification = Join-Path $root 'Releases/1.0.0/clr-qualification.json'
$sourceReport = Join-Path $root 'Releases/1.0.0/clr-string-caller-qualification.json'
$packagePath = Join-Path $root 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
$sourcePaths = @(
    'Modules/toolbelt.string.edit-distance/Clr/DistanceKernel.cs',
    'Modules/toolbelt.string.edit-distance/Clr/DistanceProvider.cs',
    'Modules/toolbelt.string.edit-distance/Clr/JaroKernel.cs',
    'Modules/toolbelt.string.edit-distance/Clr/JaroProvider.cs',
    'Modules/toolbelt.string.edit-distance/Clr/Properties/AssemblyInfo.cs',
    'Modules/toolbelt.string.edit-distance/Clr/Toolbelt.String.EditDistance.csproj',
    'Modules/toolbelt.string.edit-distance/Clr/UnicodeScalar.cs',
    'Modules/toolbelt.string.edit-distance/Deployment/Add-TrustedAssembly.sql',
    'Modules/toolbelt.string.edit-distance/Deployment/Deploy.sql',
    'Modules/toolbelt.string.edit-distance/Deployment/Uninstall.sql',
    'Modules/toolbelt.string.edit-distance/module.yaml',
    'Modules/toolbelt.string.edit-distance/Source/EditDistance.sql',
    'Modules/toolbelt.string.edit-distance/Source/JaroWinkler.sql'
)
$oraclePaths = @(
    'Modules/toolbelt.string.edit-distance/Tests/Framework/reference.py',
    'Modules/toolbelt.string.edit-distance/Tests/Framework/make_goldens.py',
    'Modules/toolbelt.string.edit-distance/Tests/Framework/JaroContract.cs',
    'Modules/toolbelt.string.edit-distance/Tests/Framework/DistanceContract.cs'
)
$pinnedInputPaths = @($packagePath, ($packagePath + '.sha256'), $qualification, $sourceReport)
$pinnedInputPaths += @($sourcePaths | ForEach-Object { Join-Path $root $_ })
$pinnedInputPaths += @($oraclePaths | ForEach-Object { Join-Path $root $_ })
$pinnedInputPaths += @($helper, $contract, $ilScript, $hiddenPython, $hiddenProbe, $ownedHelper, $PSCommandPath, $runsetFile)
$inputPinsBefore = [ordered]@{}
foreach ($path in $pinnedInputPaths) {
    if (-not $inputPinsBefore.Contains([IO.Path]::GetFullPath($path))) {
        $inputPinsBefore[[IO.Path]::GetFullPath($path)] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}
$implementationBefore = [ordered]@{
    adapter=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
    package_helper=(Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash.ToLowerInvariant()
    contract=(Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash.ToLowerInvariant()
    il_script=(Get-FileHash -LiteralPath $ilScript -Algorithm SHA256).Hash.ToLowerInvariant()
    hidden_python_probe=(Get-FileHash -LiteralPath $hiddenProbe -Algorithm SHA256).Hash.ToLowerInvariant()
    owned_process_helper=(Get-FileHash -LiteralPath (Join-Path $moduleRoot 'Scripts/Invoke-OwnedProcess.ps1') -Algorithm SHA256).Hash.ToLowerInvariant()
    runset=(Get-FileHash -LiteralPath $runsetFile -Algorithm SHA256).Hash.ToLowerInvariant()
}
$hiddenProbeResult = Invoke-CapturedStage 'hidden_process_chain' $python @('-B',$hiddenPython,'--python',$python,'--root',$root,'--',$hiddenProbe) 45000
if ($hiddenProbeResult -cnotmatch '^PASS HIDDEN_CHAIN WINDOW=0 CHILD_ENV=REBOUND CLASS=PRESERVED ISOLATED=REJECTED\r?\n?$') {
    throw 'EDIT_DISTANCE_HIDDEN_CHAIN'
}
$referenceResult = Invoke-CapturedStage 'python_reference' $python @('-B',$hiddenPython,'--python',$python,'--root',$root,'--',$referenceScript) 90000 | ConvertFrom-Json
if ($referenceResult.status -cne 'PASS' -or $referenceResult.assertions -ne 21185 -or
    $referenceResult.scope -cne 'Python private reference; SQL/Framework/provider NOT_EXECUTED') {
    throw 'EDIT_DISTANCE_REFERENCE_ORACLE'
}
$packageBinding = Invoke-CapturedStage 'package_binding' $python @('-B', $helper, '--root', $root, '--output', $output) 60000
$bound = $packageBinding | ConvertFrom-Json
if ($bound.module_id -cne 'toolbelt.string.edit-distance' -or $bound.module_version -cne '1.1.0' -or
    $bound.package_sha256 -cne '896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287' -or
    $bound.assembly_sha512 -cne 'c81e7a841dc0670b850f46d932337f55b6225d2a834d4480ae3d514875b84bf56261ff580df56155a59c0f8a56b6fe54e798d046329f4122e7228467cca90404') {
    throw 'EDIT_DISTANCE_PACKAGE_RESULT_BINDING'
}
$goldens = Join-Path $output 'goldens.txt'
$goldenResult = Invoke-CapturedStage 'golden_generation' $python @('-B',$hiddenPython,'--python',$python,'--root',$root,'--',$goldenScript,$goldens) 120000
if ($goldenResult -cnotmatch '^GOLDEN_ROWS=27104\r?\n?$' -or -not (Test-Path -LiteralPath $goldens -PathType Leaf)) {
    throw 'EDIT_DISTANCE_GOLDEN_GENERATION'
}
$goldenSha = (Get-FileHash -LiteralPath $goldens -Algorithm SHA256).Hash.ToLowerInvariant()
$dll = Join-Path $output 'package/Toolbelt.String.EditDistance.dll'
$exe = Join-Path $output 'package/EditDistancePackageContract.exe'
$dllSha = (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash.ToLowerInvariant()
if ($dllSha -cne $bound.assembly_sha256) { throw 'EDIT_DISTANCE_DLL_POST_PIN' }

$compileArgs = @('/nologo','/target:exe','/checked+','/optimize+',('/reference:' + $dll),'/reference:System.Data.dll',('/out:' + $exe),$contract)
[void](Invoke-CapturedStage 'framework_compile' $csc $compileArgs 30000)
$exeShaBefore = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()
$contractResult = Invoke-CapturedStage 'framework_contract' $exe @($goldens) 120000
if ($contractResult -cnotmatch '^PASS;GOLDEN_ROWS=27104;JARO_CASES=60;ASSERTIONS=109333\r?\n?$') { throw 'EDIT_DISTANCE_CONTRACT_OUTPUT' }
$exeShaAfter = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()
if ($exeShaAfter -cne $exeShaBefore) { throw 'EDIT_DISTANCE_FIXTURE_POST_PIN' }

$ilResult = Invoke-CapturedStage 'direct_il_inspection' $winps @('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$ilScript,'-AssemblyPath',$dll) 30000
if ($ilResult -cnotmatch '^PASS EDIT_DISTANCE_IL_INSPECTION METHODS=[0-9]+ REFERENCES=[0-9]+\r?\n?$') { throw 'EDIT_DISTANCE_IL_OUTPUT' }
$implementationAfter = [ordered]@{
    adapter=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
    package_helper=(Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash.ToLowerInvariant()
    contract=(Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash.ToLowerInvariant()
    il_script=(Get-FileHash -LiteralPath $ilScript -Algorithm SHA256).Hash.ToLowerInvariant()
    hidden_python_probe=(Get-FileHash -LiteralPath $hiddenProbe -Algorithm SHA256).Hash.ToLowerInvariant()
    owned_process_helper=(Get-FileHash -LiteralPath (Join-Path $moduleRoot 'Scripts/Invoke-OwnedProcess.ps1') -Algorithm SHA256).Hash.ToLowerInvariant()
    runset=(Get-FileHash -LiteralPath $runsetFile -Algorithm SHA256).Hash.ToLowerInvariant()
}
foreach ($key in $implementationBefore.Keys) {
    if ($implementationAfter[$key] -cne $implementationBefore[$key]) { throw 'EDIT_DISTANCE_IMPLEMENTATION_DRIFT' }
}
foreach ($tool in @(
    [pscustomobject]@{Path=$python;Name=[IO.Path]::GetFileName($python)},
    [pscustomobject]@{Path=$csc;Name=[IO.Path]::GetFileName($csc)},
    [pscustomobject]@{Path=$winps;Name=[IO.Path]::GetFileName($winps)}
)) {
    if ((Get-FileHash -LiteralPath $tool.Path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $toolHashes[$tool.Name]) {
        throw 'EDIT_DISTANCE_TOOL_DRIFT'
    }
}
$inputPinsAfter = [ordered]@{}
foreach ($path in $pinnedInputPaths) {
    $fullPath = [IO.Path]::GetFullPath($path)
    $inputPinsAfter[$fullPath] = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash.ToLowerInvariant()
}
if (($inputPinsBefore | ConvertTo-Json -Compress) -cne ($inputPinsAfter | ConvertTo-Json -Compress)) {
    throw 'EDIT_DISTANCE_INPUT_DRIFT'
}
if ((Get-FileHash -LiteralPath $goldens -Algorithm SHA256).Hash.ToLowerInvariant() -cne $goldenSha) {
    throw 'EDIT_DISTANCE_GOLDEN_POST_PIN'
}
$packageBytes = [IO.File]::ReadAllBytes($packagePath)
$archiveStream = [IO.MemoryStream]::new($packageBytes)
$archive = [IO.Compression.ZipArchive]::new($archiveStream, [IO.Compression.ZipArchiveMode]::Read, $false)
try {
    $entry = $archive.GetEntry('SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.String.EditDistance.dll')
    if ($null -eq $entry) { throw 'EDIT_DISTANCE_FINAL_PACKAGE_ENTRY' }
    $entryStream = $entry.Open()
    $binaryStream = [IO.MemoryStream]::new()
    try {
        $entryStream.CopyTo($binaryStream)
        $originalBinary = $binaryStream.ToArray()
    } finally {
        $entryStream.Dispose(); $binaryStream.Dispose()
    }
} finally {
    $archive.Dispose(); $archiveStream.Dispose()
}
$finalPackageSha = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
$finalBinarySha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::Create().ComputeHash($originalBinary)).ToLowerInvariant()
$finalBinarySha512 = [Convert]::ToHexString([Security.Cryptography.SHA512]::Create().ComputeHash($originalBinary)).ToLowerInvariant()
$extractedBinary = [IO.File]::ReadAllBytes($dll)
if ($finalPackageSha -cne '896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287' -or
    $finalBinarySha256 -cne $dllSha -or $finalBinarySha512 -cne $bound.assembly_sha512 -or
    [Convert]::ToBase64String($originalBinary) -cne [Convert]::ToBase64String($extractedBinary)) {
    throw 'EDIT_DISTANCE_FINAL_PACKAGE_BINDING'
}
$post = [ordered]@{
    schema='edit-distance-package-result/v1'
    package_sha256=$bound.package_sha256
    module_id=$bound.module_id
    module_version=$bound.module_version
    assembly_sha256=$dllSha
    assembly_sha512=$bound.assembly_sha512
    source_sha256=$bound.source_sha256
    implementation_sha256=$implementationAfter
    tool_sha256=$toolHashes
    input_sha256=$inputPinsAfter
    generated_golden_sha256=$goldenSha
    independent_reference_assertions=21185
    framework_golden_rows=27104
    jaro_golden_pairs=60
    oracle_source_sha256=[ordered]@{
        reference=(Get-FileHash -LiteralPath $referenceScript -Algorithm SHA256).Hash.ToLowerInvariant()
        generator=(Get-FileHash -LiteralPath $goldenScript -Algorithm SHA256).Hash.ToLowerInvariant()
        jaro=(Get-FileHash -LiteralPath $jaroOracle -Algorithm SHA256).Hash.ToLowerInvariant()
        distance=(Get-FileHash -LiteralPath (Join-Path $moduleRoot 'Tests/Framework/DistanceContract.cs') -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    framework_executable_sha256=$exeShaAfter
    stages=@($stages)
    qualification_scope='package-bound canonical Edit-Distance API output fixtures and bounded direct assembly IL inspection; no transitive no-I/O or general CLR/platform qualification'
}
[IO.File]::WriteAllBytes((Join-Path $output 'Result.private.json'), [Text.UTF8Encoding]::new($false).GetBytes(($post | ConvertTo-Json -Depth 8)))
Write-Output 'PASS EDIT_DISTANCE_PACKAGE_QUALIFICATION'
