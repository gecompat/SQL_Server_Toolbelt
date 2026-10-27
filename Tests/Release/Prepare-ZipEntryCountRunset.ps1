# Bindet die einzelne ZIP-Reader-Grenzprobe an das bestehende Releasepaket.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunRoot,
    [Parameter(Mandatory)][string]$FixtureOutput,
    [Parameter(Mandatory)][string]$PythonPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'ZIP_ENTRY_COUNT_PWSH7_REQUIRED' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runtime = [IO.Path]::GetFullPath((Join-Path $repo '.runtime'))
$runRoot = [IO.Path]::GetFullPath($RunRoot)
$fixtureOutput = [IO.Path]::GetFullPath($FixtureOutput)
if ((Get-Item -LiteralPath $runtime -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw 'ZIP_ENTRY_COUNT_RUNTIME_REPARSE'
}
foreach ($path in @($runRoot, $fixtureOutput)) {
    if ([IO.Path]::GetDirectoryName($path) -cne $runtime -or (Test-Path -LiteralPath $path)) {
        throw 'ZIP_ENTRY_COUNT_FRESH_RUNTIME_CHILD_REQUIRED'
    }
}
if (-not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) { throw 'ZIP_ENTRY_COUNT_PYTHON_MISSING' }

. (Join-Path $PSScriptRoot 'ZipEntryCount.DeploymentDiscovery.ps1')
. (Join-Path $repo 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1')
$pythonPathResolved = [IO.Path]::GetFullPath($PythonPath)
. (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
$labSource = Join-Path $repo 'Tests/CI/run-lab-local.ps1'
$labParseErrors = $null
$labAst = [Management.Automation.Language.Parser]::ParseFile($labSource, [ref]$null, [ref]$labParseErrors)
if ($labParseErrors.Count) { throw 'ZIP_ENTRY_COUNT_LAB_SOURCE_PARSE' }
foreach ($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')) {
    $nodes = @($labAst.FindAll({ param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name
    }, $true))
    if ($nodes.Count -ne 1) { throw 'ZIP_ENTRY_COUNT_LAB_SOURCE_AMBIGUOUS' }
    . ([scriptblock]::Create($nodes[0].Extent.Text))
}
$contract = Resolve-LabContract -TestPurpose Functional
$promptPath = Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
$packagePath = Join-Path $repo 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
$sidecarPath = $packagePath + '.sha256'
$repoPaths = @(
    'Tests/Release/Invoke-ZipEntryCountLab.ps1', 'Tests/Release/Prepare-ZipEntryCountRunset.ps1',
    'Tests/Release/compose_zip_entry_count.py', 'Tests/Release/Runtime/ZipEntryCount.Contract.sql',
    'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
    'Tests/Release/ClrCaller.Environment.ps1', 'Tests/CI/run-csv-memory-lab.ps1', 'Tests/CI/run-lab-local.ps1',
    'Tests/CI/LabQualifiedContract.ps1', 'Deployment/Deploy-All.ps1',
    'Tests/Release/ZipEntryCount.DeploymentDiscovery.ps1',
    'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1',
    'Modules/toolbelt.archive.zip-memory/module.yaml', 'Modules/toolbelt.core.result-table/module.yaml',
    'Modules/toolbelt.archive.zip-memory/Source/USP_ListZipEntriesFromBinary.sql',
    'Modules/toolbelt.archive.zip-memory/Source/TVF_InternalListZipEntriesClr.sql',
    'Modules/toolbelt.archive.zip-memory/Deployment/Deploy.sql',
    'Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql',
    'Modules/toolbelt.core.result-table/Deployment/Deploy.sql')
$deployDiscovery = @(Get-ZipEntryCountDeploymentDiscovery (Join-Path $repo 'Modules'))
$repoPaths += @($deployDiscovery)
foreach ($modulePath in @('Modules/toolbelt.archive.zip-memory/Source','Modules/toolbelt.archive.zip-memory/Deployment',
                         'Modules/toolbelt.core.result-table/Source','Modules/toolbelt.core.result-table/Deployment')) {
    $repoPaths += @(Get-ChildItem -LiteralPath (Join-Path $repo $modulePath) -File -Recurse |
        ForEach-Object { [IO.Path]::GetRelativePath($repo, $_.FullName).Replace('\','/') })
}
$repoPaths = @($repoPaths | Sort-Object -Unique)
$repoInputsBefore = @{}
foreach ($relative in $repoPaths) {
    $path = Join-Path $repo $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'ZIP_ENTRY_COUNT_SOURCE_PIN_MISSING' }
    $repoInputsBefore[$relative] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
$runtimeInputsBefore = @{}
$runtimeInputPaths = @($packagePath, $sidecarPath, $pythonPathResolved, (Join-Path $PSHOME 'pwsh.exe'),
    $contract.Path, $contract.SchemaPath)
if (-not [string]::IsNullOrWhiteSpace($promptPath)) { $runtimeInputPaths += $promptPath }
foreach ($path in $runtimeInputPaths) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'ZIP_ENTRY_COUNT_RUNTIME_INPUT_MISSING' }
    $fullPath = [IO.Path]::GetFullPath($path)
    $runtimeInputsBefore[$fullPath] = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
}
$composer = Join-Path $PSScriptRoot 'compose_zip_entry_count.py'
$composition = Invoke-OwnedProcess -FileName $pythonPathResolved -Arguments @('-B', $composer, '--output', $fixtureOutput) -TimeoutMilliseconds 30000
if ($composition.ExitCode -ne 0 -or -not $composition.CaptureComplete -or $composition.Stderr) {
    throw 'ZIP_ENTRY_COUNT_FIXTURE_COMPOSITION_FAILED'
}
$packageSha = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
$sidecarLines = @(Get-Content -LiteralPath $sidecarPath)
if ($sidecarLines.Count -ne 1 -or $sidecarLines[0] -notmatch '^([a-fA-F0-9]{64})\s+\*?(.+)$' -or
    $Matches[1].ToLowerInvariant() -cne $packageSha -or
    [IO.Path]::GetFileName($packagePath) -cne $Matches[2]) { throw 'ZIP_ENTRY_COUNT_PACKAGE_SIDECAR_INVALID' }

$archive = [IO.Compression.ZipFile]::OpenRead($packagePath)
$packagePrefix = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/'
try {
    $manifestEntry = $archive.GetEntry($packagePrefix + 'CLR-PACKAGE.json')
    if (-not $manifestEntry) { throw 'ZIP_ENTRY_COUNT_PACKAGE_MANIFEST_MISSING' }
    $reader = [IO.StreamReader]::new($manifestEntry.Open(), [Text.Encoding]::UTF8)
    try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
    if ($manifest.state -cne 'prepared_not_published' -or
        $manifest.publication_authorized -isnot [bool] -or $manifest.publication_authorized) {
        throw 'ZIP_ENTRY_COUNT_PACKAGE_NOT_APPROVED_SOURCE'
    }
} finally { $archive.Dispose() }

$artifact = @($manifest.artifacts | Where-Object module_id -CEQ 'toolbelt.archive.zip-memory')
if ($artifact.Count -ne 1 -or $artifact[0].origin -cne 'reproducible_double_build') {
    throw 'ZIP_ENTRY_COUNT_PACKAGE_ARTIFACT_ORIGIN'
}
$artifactRelative = 'Binaries/' + $artifact[0].file
if (-not ($manifest.files.PSObject.Properties.Name -ccontains $artifactRelative)) { throw 'ZIP_ENTRY_COUNT_PACKAGE_DLL_MISSING' }
$archive = [IO.Compression.ZipFile]::OpenRead($packagePath)
try {
    $dllEntry = $archive.GetEntry($packagePrefix + $artifactRelative)
    if (-not $dllEntry) { throw 'ZIP_ENTRY_COUNT_PACKAGE_DLL_MISSING' }
    $stream = $dllEntry.Open(); $memory = [IO.MemoryStream]::new()
    try { $stream.CopyTo($memory); $dllBytes = $memory.ToArray() } finally { $memory.Dispose(); $stream.Dispose() }
} finally { $archive.Dispose() }
$filePin = $manifest.files.PSObject.Properties[$artifactRelative].Value
$dllSha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($dllBytes))
$dllSha512 = [Convert]::ToHexString([Security.Cryptography.SHA512]::HashData($dllBytes))
if ($dllSha256.ToLowerInvariant() -cne $artifact[0].sha256.ToLowerInvariant() -or
    $dllSha512.ToLowerInvariant() -cne $artifact[0].sha512.ToLowerInvariant() -or
    $dllSha256.ToLowerInvariant() -cne $filePin.sha256.ToLowerInvariant() -or $dllBytes.Length -ne $filePin.size) {
    throw 'ZIP_ENTRY_COUNT_PACKAGE_DLL_PIN'
}

New-Item -ItemType Directory -Path $runRoot -ErrorAction Stop | Out-Null
$exportsDir = Join-Path $runRoot 'exports'; New-Item -ItemType Directory -Path $exportsDir | Out-Null
$artifactDir = Join-Path $runRoot 'artifact'; New-Item -ItemType Directory -Path $artifactDir | Out-Null
$artifactPath = Join-Path $artifactDir $artifact[0].file
[IO.File]::WriteAllBytes($artifactPath, $dllBytes)

$zipVersionText = [IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.archive.zip-memory/module.yaml'), [Text.Encoding]::UTF8)
$coreVersionText = [IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.core.result-table/module.yaml'), [Text.Encoding]::UTF8)
if ($zipVersionText -notmatch '(?m)^version:\s*["'']?1\.4\.0["'']?\s*$' -or
    $coreVersionText -notmatch '(?m)^version:\s*["'']?1\.0\.0["'']?\s*$') { throw 'ZIP_ENTRY_COUNT_MODULE_VERSION_DRIFT' }
$moduleVariables = @{ 'toolbelt.archive.zip-memory' = @{ AssemblyBits = '0x' + [Convert]::ToHexString($dllBytes) } }
$deployAll = Join-Path $repo 'Deployment/Deploy-All.ps1'
$moduleIds = @('toolbelt.core.result-table', 'toolbelt.archive.zip-memory')
$exports = [ordered]@{}
foreach ($mode in @('local', 'central')) {
    $output = Join-Path $exportsDir ($mode + '.sql')
    & $deployAll -DeploymentMode $mode -ModuleId $moduleIds -ModuleVariables $moduleVariables -OutputSqlFile $output
    if (-not (Test-Path -LiteralPath $output -PathType Leaf)) { throw 'ZIP_ENTRY_COUNT_EXPORT_MISSING' }
    $exports[$mode] = $output
}

# Dieselbe schema-validierte Functional-Zielauswahl wie der Caller-Guard; keine Verbindung.
$matrix = @(foreach ($platform in @('linux','windows')) {
    foreach ($version in @('2019','2022','2025')) {
        $levels = switch ($version) { '2019' { @(150) } '2022' { @(150,160) } '2025' { @(150,160,170) } }
        foreach ($level in $levels) {
            $patch = if ($platform -eq 'linux') { 'latest' } else { @{'2019'='cu32';'2022'='cu26';'2025'='cu8'}[$version] }
            [pscustomobject]@{Platform=$platform;Version=$version;CL=$level;Patch=$patch}
        }
    }
})
foreach ($case in $matrix) {
    $targets = @(Get-LabTargetsForSelector -Contract $contract.Contract -Selector $case)
    if ($targets.Count -ne 1) { throw 'ZIP_ENTRY_COUNT_MATRIX_TARGET_UNAVAILABLE' }
}

$pins = [Collections.Generic.List[object]]::new()
foreach ($relative in $repoPaths) {
    $path = Join-Path $repo $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'ZIP_ENTRY_COUNT_SOURCE_PIN_MISSING' }
    $sha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($sha -cne $repoInputsBefore[$relative]) { throw 'ZIP_ENTRY_COUNT_REPO_INPUT_CHANGED_DURING_PREPARATION' }
    $pins.Add([pscustomobject]@{path=$path;sha256=$sha})
}
$runtimeFiles = @(
    (Join-Path $fixtureOutput 'ZipEntryCount.Contract.sql'),
    (Join-Path $fixtureOutput 'ZipEntryCount.10000.zip'),
    (Join-Path $fixtureOutput 'ZipEntryCount.10001.zip'),
    (Join-Path $fixtureOutput 'composition.json'), $artifactPath, $exports.local, $exports.central,
    $packagePath, $sidecarPath, $PythonPath, (Join-Path $PSHOME 'pwsh.exe'),
    $contract.Path, $contract.SchemaPath)
if (-not [string]::IsNullOrWhiteSpace($promptPath)) { $runtimeFiles += $promptPath }
foreach ($path in $runtimeInputPaths) {
    $fullPath = [IO.Path]::GetFullPath($path)
    if ((Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash -cne $runtimeInputsBefore[$fullPath]) {
        throw 'ZIP_ENTRY_COUNT_RUNTIME_INPUT_CHANGED_DURING_PREPARATION'
    }
}
foreach ($path in $runtimeFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'ZIP_ENTRY_COUNT_RUNTIME_INPUT_MISSING' }
    $pins.Add([pscustomobject]@{path=[IO.Path]::GetFullPath($path);sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash})
}
$composition = Get-Content -LiteralPath (Join-Path $fixtureOutput 'composition.json') -Raw | ConvertFrom-Json
$runset = [ordered]@{
    schema_version='zip-entry-count-caller/v1'
    contract_sha256=(Get-FileHash -LiteralPath $contract.Path -Algorithm SHA256).Hash
    cases=$matrix
    fixture=(Join-Path $fixtureOutput 'ZipEntryCount.Contract.sql')
    zip_10000=[ordered]@{path=(Join-Path $fixtureOutput 'ZipEntryCount.10000.zip');sha256=$composition.zip_10000_sha256}
    zip_10001=[ordered]@{path=(Join-Path $fixtureOutput 'ZipEntryCount.10001.zip');sha256=$composition.zip_10001_sha256}
    exports=$exports
    artifacts=@([pscustomobject]@{module_id=$artifact[0].module_id;sql_name=$artifact[0].sql_name;path=$artifactPath;sha256=$dllSha256;sha512=$dllSha512})
    module_versions=[ordered]@{'toolbelt.core.result-table'='1.0.0';'toolbelt.archive.zip-memory'='1.4.0'}
    package=[ordered]@{path=$packagePath;sha256=$packageSha;artifact_origin=$artifact[0].origin}
    deployment_discovery=@($deployDiscovery | Sort-Object -Unique)
    tools=[ordered]@{
        python=[ordered]@{path=$pythonPathResolved;sha256=(Get-FileHash -LiteralPath $pythonPathResolved -Algorithm SHA256).Hash}
        powershell=[ordered]@{path=(Join-Path $PSHOME 'pwsh.exe');sha256=(Get-FileHash -LiteralPath (Join-Path $PSHOME 'pwsh.exe') -Algorithm SHA256).Hash;version=$PSVersionTable.PSVersion.ToString()}
    }
    pins=@($pins)
}
$runsetPath = Join-Path $runRoot 'runset.json'
[IO.File]::WriteAllText($runsetPath, ($runset | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
Write-Output 'PASS ZIP_ENTRY_COUNT private runset prepared; no SQL connection opened'
