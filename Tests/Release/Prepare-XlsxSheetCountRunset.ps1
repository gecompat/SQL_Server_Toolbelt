# Bindet die feste Worksheetgrenze an das ausgelieferte XLSX-/ZIP-Paket.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunRoot,
    [Parameter(Mandatory)][string]$FixtureOutput,
    [Parameter(Mandatory)][string]$PythonPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'XLSX_SHEET_PWSH7_REQUIRED' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runtime = [IO.Path]::GetFullPath((Join-Path $repo '.runtime'))
if (-not (Test-Path -LiteralPath $runtime -PathType Container)) { throw 'XLSX_SHEET_RUNTIME_REQUIRED' }
$runtimeItem = Get-Item -LiteralPath $runtime -Force
if (($runtimeItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
    [IO.Path]::GetFullPath($runtimeItem.FullName) -cne $runtime) { throw 'XLSX_SHEET_RUNTIME_REPARSE' }
$runRoot = [IO.Path]::GetFullPath($RunRoot)
$fixtureOutput = [IO.Path]::GetFullPath($FixtureOutput)
foreach ($path in @($runRoot, $fixtureOutput)) {
    if ([IO.Path]::GetDirectoryName($path) -cne $runtime -or [IO.File]::Exists($path) -or [IO.Directory]::Exists($path)) {
        throw 'XLSX_SHEET_FRESH_RUNTIME_CHILD_REQUIRED'
    }
}
if ($runRoot -ceq $fixtureOutput) { throw 'XLSX_SHEET_OUTPUTS_MUST_BE_DISTINCT' }
if (-not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) { throw 'XLSX_SHEET_PYTHON_MISSING' }

. (Join-Path $PSScriptRoot 'ZipEntryCount.DeploymentDiscovery.ps1')
. (Join-Path $repo 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1')
. (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
$labSource = Join-Path $repo 'Tests/CI/run-lab-local.ps1'
$labErrors = $null
$labAst = [Management.Automation.Language.Parser]::ParseFile($labSource, [ref]$null, [ref]$labErrors)
if ($labErrors.Count) { throw 'XLSX_SHEET_LAB_SOURCE_PARSE' }
foreach ($name in @('Get-EnvironmentVariableValue', 'Resolve-LabContract', 'Test-LabTargetReady', 'Get-LabTargetsForSelector')) {
    $nodes = @($labAst.FindAll({ param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name
    }, $true))
    if ($nodes.Count -ne 1) { throw 'XLSX_SHEET_LAB_HELPER_AMBIGUOUS' }
    . ([scriptblock]::Create($nodes[0].Extent.Text))
}
$contract = Resolve-LabContract -TestPurpose Functional
$promptPath = Get-EnvironmentVariableValue -Name 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
$packagePath = Join-Path $repo 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip'
$sidecarPath = $packagePath + '.sha256'
$pythonPathResolved = [IO.Path]::GetFullPath($PythonPath)
$powershellPath = Join-Path $PSHOME 'pwsh.exe'

$repoPaths = @(
    'Tests/Release/Invoke-XlsxSheetCountLab.ps1',
    'Tests/Release/Prepare-XlsxSheetCountRunset.ps1',
    'Tests/Release/compose_xlsx_sheet_count.py',
    'Tests/Release/Runtime/Xlsx.SheetCount.sql',
    'Tests/Release/ZipEntryCount.DeploymentDiscovery.ps1',
    'Tests/Release/Invoke-ApiQualificationLab.ps1',
    'Tests/Release/Invoke-StablePackageLab.ps1',
    'Tests/Release/ClrCaller.Environment.ps1',
    'Tests/CI/run-csv-memory-lab.ps1', 'Tests/CI/run-lab-local.ps1',
    'Tests/CI/LabQualifiedContract.ps1', 'Deployment/Deploy-All.ps1',
    'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1',
    'Modules/toolbelt.file.xlsx-memory/module.yaml', 'Modules/toolbelt.archive.zip-memory/module.yaml',
    'Modules/toolbelt.core.result-table/module.yaml',
    'Modules/toolbelt.file.xlsx-memory/Clr/Workbook.cs', 'Modules/toolbelt.file.xlsx-memory/Clr/XlsxEntryPoints.cs',
    'Modules/toolbelt.file.xlsx-memory/Source/USP_ListXlsxWorksheets.sql',
    'Modules/toolbelt.file.xlsx-memory/Source/USP_InternalXlsxRead.sql',
    'Modules/toolbelt.file.xlsx-memory/Source/TVF_InternalXlsxSheets.sql'
)
$deployDiscovery = @(Get-ZipEntryCountDeploymentDiscovery (Join-Path $repo 'Modules'))
$repoPaths += $deployDiscovery
foreach ($modulePath in @(
    'Modules/toolbelt.file.xlsx-memory/Source', 'Modules/toolbelt.file.xlsx-memory/Deployment',
    'Modules/toolbelt.archive.zip-memory/Source', 'Modules/toolbelt.archive.zip-memory/Deployment',
    'Modules/toolbelt.core.result-table/Source', 'Modules/toolbelt.core.result-table/Deployment')) {
    $repoPaths += @(Get-ChildItem -LiteralPath (Join-Path $repo $modulePath) -File -Recurse |
        ForEach-Object { [IO.Path]::GetRelativePath($repo, $_.FullName).Replace('\', '/') })
}
$repoPaths = @($repoPaths | Sort-Object -Unique)
$repoInputsBefore = @{}
foreach ($relative in $repoPaths) {
    $path = Join-Path $repo $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'XLSX_SHEET_SOURCE_PIN_MISSING' }
    $repoInputsBefore[$relative] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
$runtimeInputs = @($packagePath, $sidecarPath, $pythonPathResolved, $powershellPath, $contract.Path, $contract.SchemaPath)
if (-not [string]::IsNullOrWhiteSpace($promptPath)) { $runtimeInputs += $promptPath }
$runtimeInputsBefore = @{}
foreach ($path in $runtimeInputs) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'XLSX_SHEET_RUNTIME_INPUT_MISSING' }
    $full = [IO.Path]::GetFullPath($path)
    $runtimeInputsBefore[$full] = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
}

$packageBytes = [IO.File]::ReadAllBytes($packagePath)
$packageSha = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($packageBytes)).ToLowerInvariant()
$sidecarLines = @(Get-Content -LiteralPath $sidecarPath)
if ($sidecarLines.Count -ne 1 -or $sidecarLines[0] -notmatch '^([a-fA-F0-9]{64})\s+\*?(.+)$' -or
    $Matches[1].ToLowerInvariant() -cne $packageSha -or [IO.Path]::GetFileName($packagePath) -cne $Matches[2]) {
    throw 'XLSX_SHEET_PACKAGE_SIDECAR_INVALID'
}
$packageStream = [IO.MemoryStream]::new($packageBytes, $false)
$archive = [IO.Compression.ZipArchive]::new($packageStream, [IO.Compression.ZipArchiveMode]::Read, $true)
$prefix = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/'
$wantedIds = @('toolbelt.archive.zip-memory', 'toolbelt.file.xlsx-memory')
try {
    $manifestEntry = $archive.GetEntry($prefix + 'CLR-PACKAGE.json')
    if (-not $manifestEntry) { throw 'XLSX_SHEET_PACKAGE_MANIFEST_MISSING' }
    $reader = [IO.StreamReader]::new($manifestEntry.Open(), [Text.Encoding]::UTF8)
    try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
    if ($manifest.state -cne 'prepared_not_published' -or $manifest.publication_authorized -isnot [bool] -or
        $manifest.publication_authorized) { throw 'XLSX_SHEET_PACKAGE_STATE' }
    $artifacts = @($manifest.artifacts | Where-Object { $_.module_id -cin $wantedIds })
    if ($artifacts.Count -ne 2 -or @($artifacts.module_id | Sort-Object -Unique).Count -ne 2 -or
        @($artifacts | Where-Object origin -CNE 'reproducible_double_build').Count) { throw 'XLSX_SHEET_PACKAGE_ARTIFACT_SCOPE' }
    $artifactBytes = @{}
    foreach ($artifact in $artifacts) {
        $relative = 'Binaries/' + [string]$artifact.file
        $filePin = $manifest.files.PSObject.Properties[$relative].Value
        $entry = $archive.GetEntry($prefix + $relative)
        if (-not $entry -or -not $filePin -or $entry.Length -ne $filePin.size) { throw 'XLSX_SHEET_PACKAGE_DLL_MISSING' }
        $stream = $entry.Open(); $memory = [IO.MemoryStream]::new()
        try { $stream.CopyTo($memory); $bytes = $memory.ToArray() } finally { $memory.Dispose(); $stream.Dispose() }
        $sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
        $sha512 = [Convert]::ToHexString([Security.Cryptography.SHA512]::HashData($bytes)).ToLowerInvariant()
        if ($sha256 -cne $artifact.sha256.ToLowerInvariant() -or $sha512 -cne $artifact.sha512.ToLowerInvariant() -or
            $sha256 -cne $filePin.sha256.ToLowerInvariant()) { throw 'XLSX_SHEET_PACKAGE_DLL_PIN' }
        $artifactBytes[[string]$artifact.module_id] = [pscustomobject]@{record=$artifact;relative=$relative;bytes=$bytes;sha256=$sha256;sha512=$sha512}
    }
} finally { $archive.Dispose(); $packageStream.Dispose() }

$versions = [ordered]@{'toolbelt.core.result-table'='1.0.0';'toolbelt.archive.zip-memory'='1.4.0';'toolbelt.file.xlsx-memory'='1.2.0'}
foreach ($module in $versions.Keys) {
    $moduleRelativePath = switch ($module) {
        'toolbelt.core.result-table' { 'Modules/toolbelt.core.result-table' }
        'toolbelt.archive.zip-memory' { 'Modules/toolbelt.archive.zip-memory' }
        'toolbelt.file.xlsx-memory' { 'Modules/toolbelt.file.xlsx-memory' }
        default { throw 'XLSX_SHEET_MODULE_PATH_UNEXPECTED' }
    }
    $yaml = [IO.File]::ReadAllText((Join-Path (Join-Path $repo $moduleRelativePath) 'module.yaml'), [Text.Encoding]::UTF8)
    if ($yaml -notmatch ('(?m)^version:\s*["'']?' + [regex]::Escape($versions[$module]) + '["'']?\s*$')) {
        throw 'XLSX_SHEET_MODULE_VERSION_DRIFT'
    }
}

New-Item -ItemType Directory -Path $RunRoot -ErrorAction Stop | Out-Null
$exportsDir = Join-Path $RunRoot 'exports'; New-Item -ItemType Directory -Path $exportsDir | Out-Null
$artifactDir = Join-Path $RunRoot 'artifacts'; New-Item -ItemType Directory -Path $artifactDir | Out-Null
$artifactRecords = @()
foreach ($module in $wantedIds) {
    $record = $artifactBytes[$module]
    $path = Join-Path $artifactDir ([string]$record.record.file)
    [IO.File]::WriteAllBytes($path, $record.bytes)
    $artifactRecords += [pscustomobject]@{module_id=$module;sql_name=[string]$record.record.sql_name;path=$path;
        sha256=$record.sha256.ToUpperInvariant();sha512=$record.sha512.ToUpperInvariant();size=$record.bytes.Length}
}
$moduleVariables = @{}
foreach ($module in $wantedIds) { $moduleVariables[$module] = @{AssemblyBits='0x' + [Convert]::ToHexString($artifactBytes[$module].bytes)} }
$deployAll = Join-Path $repo 'Deployment/Deploy-All.ps1'
$moduleIds = @('toolbelt.core.result-table','toolbelt.archive.zip-memory','toolbelt.file.xlsx-memory')
$exports = [ordered]@{}
foreach ($mode in @('local','central')) {
    $output = Join-Path $exportsDir ($mode + '.sql')
    & $deployAll -DeploymentMode $mode -ModuleId $moduleIds -ModuleVariables $moduleVariables -OutputSqlFile $output
    if (-not (Test-Path -LiteralPath $output -PathType Leaf)) { throw 'XLSX_SHEET_EXPORT_MISSING' }
    $exports[$mode] = $output
}

$composer = Join-Path $PSScriptRoot 'compose_xlsx_sheet_count.py'
$compositionRun = Invoke-OwnedProcess -FileName $pythonPathResolved -Arguments @('-B',$composer,'--output',$fixtureOutput) -TimeoutMilliseconds 30000
if ($compositionRun.ExitCode -ne 0 -or -not $compositionRun.CaptureComplete -or $compositionRun.Stderr) {
    throw 'XLSX_SHEET_COMPOSITION_FAILED'
}
$composition = $compositionRun.Stdout.Trim() | ConvertFrom-Json
$expectedSheetNames = (1..32 | ForEach-Object { 'Sheet{0:D2}' -f $_ }) -join '|'
if ($composition.schema -cne 'xlsx-sheet-count-composition/v1' -or
    $composition.fixture_sha256 -cne (Get-FileHash -LiteralPath (Join-Path $repo 'Tests/Release/Runtime/Xlsx.SheetCount.sql') -Algorithm SHA256).Hash.ToLowerInvariant() -or
    $composition.counts.positive -ne 32 -or $composition.counts.overflow -ne 33 -or
    ($composition.names -join '|') -cne $expectedSheetNames -or
    $composition.overflow_name -cne 'Sheet33' -or $composition.visibility -cne 'visible' -or $composition.date1904 -ne $false) {
    throw 'XLSX_SHEET_COMPOSITION_ORACLE_DRIFT'
}
$fixturePath = Join-Path $fixtureOutput 'Xlsx.SheetCount.sql'
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
    if (@(Get-LabTargetsForSelector -Contract $contract.Contract -Selector $case).Count -ne 1) {
        throw 'XLSX_SHEET_MATRIX_TARGET_UNAVAILABLE'
    }
}

$pins = [Collections.Generic.List[object]]::new()
foreach ($relative in $repoPaths) {
    $path = Join-Path $repo $relative
    $sha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($sha -cne $repoInputsBefore[$relative]) { throw 'XLSX_SHEET_REPO_INPUT_CHANGED_DURING_PREPARATION' }
    $pins.Add([pscustomobject]@{path=$path;sha256=$sha})
}
foreach ($path in $runtimeInputs) {
    $full = [IO.Path]::GetFullPath($path)
    if ((Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash -cne $runtimeInputsBefore[$full]) {
        throw 'XLSX_SHEET_RUNTIME_INPUT_CHANGED_DURING_PREPARATION'
    }
}
$runtimeFiles = @($packagePath,$sidecarPath,$pythonPathResolved,$powershellPath,$contract.Path,$contract.SchemaPath,
    (Join-Path $fixtureOutput 'composition.json'),$fixturePath,
    (Join-Path $fixtureOutput 'Xlsx.Sheets.32.xlsx'),(Join-Path $fixtureOutput 'Xlsx.Sheets.33.xlsx'),
    $exports.local,$exports.central) + @($artifactRecords | ForEach-Object path)
if (-not [string]::IsNullOrWhiteSpace($promptPath)) { $runtimeFiles += $promptPath }
if (@($runtimeFiles | Where-Object { $_ -isnot [string] }).Count -or
    @($runtimeFiles | Sort-Object -Unique).Count -ne $runtimeFiles.Count) { throw 'XLSX_SHEET_RUNTIME_FILE_SET_INVALID' }
foreach ($path in $runtimeFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'XLSX_SHEET_RUNTIME_FILE_MISSING' }
    $pins.Add([pscustomobject]@{path=[IO.Path]::GetFullPath($path);sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash})
}
$runset = [ordered]@{
    schema_version='xlsx-sheet-count-boundary/v1'
    contract_sha256=(Get-FileHash -LiteralPath $contract.Path -Algorithm SHA256).Hash
    cases=$matrix
    fixture=$fixturePath
    workbooks=[ordered]@{
        positive=[ordered]@{path=(Join-Path $fixtureOutput 'Xlsx.Sheets.32.xlsx');sha256=$composition.outputs.'Xlsx.Sheets.32.xlsx'.sha256;count=32}
        overflow=[ordered]@{path=(Join-Path $fixtureOutput 'Xlsx.Sheets.33.xlsx');sha256=$composition.outputs.'Xlsx.Sheets.33.xlsx'.sha256;count=33}
    }
    exports=$exports;artifacts=$artifactRecords;module_versions=$versions
    package=[ordered]@{path=$packagePath;sha256=$packageSha;artifact_origin='reproducible_double_build'}
    deployment_discovery=@($deployDiscovery | Sort-Object -Unique)
    tools=[ordered]@{python=[ordered]@{path=$pythonPathResolved;sha256=(Get-FileHash -LiteralPath $pythonPathResolved -Algorithm SHA256).Hash};
        powershell=[ordered]@{path=$powershellPath;sha256=(Get-FileHash -LiteralPath $powershellPath -Algorithm SHA256).Hash;version=$PSVersionTable.PSVersion.ToString()}}
    composition=$composition;pins=@($pins)
}
$runsetPath = Join-Path $runRoot 'runset.json'
[IO.File]::WriteAllText($runsetPath, ($runset | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
Write-Output 'PASS XLSX_SHEET private runset prepared; no SQL connection opened'
