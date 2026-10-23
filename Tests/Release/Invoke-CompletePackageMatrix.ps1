[CmdletBinding()]
param(
    [string]$PackagePath='.runtime/release-support-inputs/complete.zip',
    [Parameter(Mandatory)][string]$EvidenceDirectory,
    [switch]$PlanOnly,
    [ValidateSet('full','install-uninstall')][string]$QualificationScope='full',
    [ValidateRange(0,11)][int]$StartCaseIndex=0,
    [string]$SharedBudgetFile
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Get-ReleaseMatrixAllowance([double]$Elapsed,[switch]$CaseStart) {
    # Arbeit und separaten Audit vor dem ersten mutierenden Prozess reservieren.
    # Ohne diese Reserve könnte ein kurz vor dem Wellenende gestarteter Fall
    # seine zwei Prozessgrenzen noch über das gemeinsame Budget hinausschieben.
    $reserve=if ($CaseStart) {805} else {405}
    if ((4800-$Elapsed) -lt $reserve) {throw 'RELEASE_WAVE_BUDGET_EXHAUSTED'}
    return 400000
}
function Assert-ClrWaveCoverage($Budget,[int]$Start,[switch]$Final) {
    $done=@($Budget.completed)
    if (@($done|Select-Object -Unique).Count -ne $done.Count -or @($done|Where-Object {$_ -lt 0 -or $_ -gt 11}).Count) {throw 'RELEASE_CLR_INVALID_HISTORY'}
    if ($Start -gt 0) {foreach($prior in 0..($Start-1)){if($prior -notin $done){throw 'RELEASE_CLR_PREFIX_NOT_COMPLETE'}}}
    if ($Final -and $done.Count -ne 12){throw 'RELEASE_CLR_FULL_COVERAGE_REQUIRED'}
}
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$driver=Join-Path $PSScriptRoot 'Invoke-CompletePackageLab.ps1'
$private=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))+[IO.Path]::DirectorySeparatorChar
$evidence=[IO.Path]::GetFullPath($EvidenceDirectory)
if (-not $evidence.StartsWith($private,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $evidence)) {
    throw 'RELEASE_NEW_PRIVATE_DIRECTORY_REQUIRED'
}
$parent=[IO.DirectoryInfo]::new([IO.Path]::GetDirectoryName($evidence))
while ($parent -and $parent.FullName.Length -ge $private.TrimEnd('\','/').Length) {
    if (($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {throw 'RELEASE_REPARSE_PATH'}
    $parent=$parent.Parent
}
$package=(Resolve-Path -LiteralPath $PackagePath).Path
. (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
$errors=$null
$helper=Join-Path $repo 'Tests/CI/run-lab-local.ps1'
$tree=[Management.Automation.Language.Parser]::ParseFile($helper,[ref]$null,[ref]$errors)
if ($errors.Count) {throw 'RELEASE_LAB_HELPER_PARSE'}
foreach ($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector')) {
    $nodes=@($tree.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
    if ($nodes.Count -ne 1) {throw 'RELEASE_LAB_HELPER_AMBIGUOUS'}
    . ([scriptblock]::Create($nodes[0].Extent.Text))
}
$lab=Resolve-LabContract -TestPurpose Functional
$prompt=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
if (-not $prompt -or -not (Test-Path -LiteralPath $prompt)) {throw 'RELEASE_REVIEWED_LAB_PROMPT_REQUIRED'}
$cases=@()
foreach ($platform in @('linux','windows')) {
    foreach ($version in @('2019','2022','2025')) {
        $patch=if ($platform -ceq 'windows') {'base'} else {'latest'}
        $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$platform;Version=$version;Patch=$patch}))
        if (-not $targets.Count) {throw 'RELEASE_TARGET_NOT_READY'}
        foreach ($target in $targets) {
            foreach ($cl in @(150,160,170)|Where-Object {$_ -le @{'2019'=150;'2022'=160;'2025'=170}[$version]}) {
                $cases+=@([ordered]@{Platform=$platform;Version=$version;Patch=[string]$target.patch;CL=$cl})
            }
        }
    }
}
if ($cases.Count -ne 12) {throw 'RELEASE_FINITE_TWELVE_CASE_BOUNDARY'}
if ($PlanOnly) {'PASS RELEASE_PLAN twelve target/CL cases, local/central/consumer; no SQL connection'; return}
# Vor dem ersten SQL-Zugriff das tatsächliche Archiv samt Quell-/Exportbindung prüfen.
& python -B (Join-Path $repo 'Scripts/Release/prepare_release.py') --verify (Join-Path $repo 'Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip')
if ($LASTEXITCODE -ne 0) {throw 'RELEASE_PACKAGE_VERIFICATION_FAILED'}
[void][IO.Directory]::CreateDirectory($evidence)
$paths=@($driver,$PSCommandPath,(Join-Path $repo 'Tests/Release/Invoke-StablePackageLab.ps1'),(Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),(Join-Path $repo 'Scripts/Release/check_clr_builds.py'),(Join-Path $repo 'Scripts/Release/prepare_release.py'),(Join-Path $repo 'Modules/toolbelt.tsql.ssis-debug/Tests/Static/validate_install_package.py'),$helper,(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),
    (Join-Path $repo 'Scripts/Release/prepare_clr_package.py'),(Join-Path $repo 'Tests/Release/prepare_complete_package.py'),(Join-Path $repo 'Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip'),$package,($package+'.sha256'),$lab.Path,$lab.SchemaPath,$prompt)
$sum=((Get-Content -LiteralPath ($package+'.sha256') -Raw).Trim() -split '\s+')[0]
if((Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash -ine $sum){throw 'RELEASE_COMPLETE_CHECKSUM'}
$archive=[IO.Compression.ZipFile]::OpenRead($package)
try{
 $entry=$archive.GetEntry('Toolbelt-Complete-Qualification/CLR-PACKAGE.json')
 if($null -eq $entry){throw 'RELEASE_COMPLETE_METADATA'}
 $reader=[IO.StreamReader]::new($entry.Open(),[Text.Encoding]::UTF8)
 try{$productCommit=($reader.ReadToEnd()|ConvertFrom-Json).product_commit}finally{$reader.Dispose()}
}finally{$archive.Dispose()}
if($productCommit -cnotmatch '^[a-f0-9]{40}$'){throw 'RELEASE_COMPLETE_PRODUCT_COMMIT'}
$pins=@($paths|Sort-Object -Unique|ForEach-Object {[ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
$runset=[ordered]@{schemaVersion='1.0';productCommit=$productCommit;
    package=$package;qualificationScope=$QualificationScope;contractSha256=(Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash;
    schemaSha256=(Get-FileHash -LiteralPath $lab.SchemaPath -Algorithm SHA256).Hash;
    promptSha256=(Get-FileHash -LiteralPath $prompt -Algorithm SHA256).Hash;pins=$pins;cases=$cases;
    budget=@{cases=12;attempts=12;workSecondsPerCase=300;cleanupDeadlineSecondsPerCase=360;outerWatchdogSecondsPerCase=400;waveSeconds=4800;modelCost='UNKNOWN'}}
$runsetPath=Join-Path $evidence 'runset.json'
[IO.File]::WriteAllText($runsetPath,($runset|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
$runsetHash=(Get-FileHash -LiteralPath $runsetPath -Algorithm SHA256).Hash
# Eine Korrekturfortsetzung verwendet denselben privaten Restbudget-Ledger.
if (-not $SharedBudgetFile) {$SharedBudgetFile=Join-Path $evidence 'wave-budget.json'}
$budgetPath=[IO.Path]::GetFullPath($SharedBudgetFile)
if (-not $budgetPath.StartsWith($private,[StringComparison]::OrdinalIgnoreCase)){throw 'RELEASE_PRIVATE_BUDGET_REQUIRED'}
$parent=[IO.DirectoryInfo]::new([IO.Path]::GetDirectoryName($budgetPath))
while ($parent -and $parent.FullName.Length -ge $private.TrimEnd('\','/').Length) {
    if (($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'RELEASE_REPARSE_BUDGET'}
    $parent=$parent.Parent
}
if (Test-Path -LiteralPath $budgetPath) {$budget=Get-Content -LiteralPath $budgetPath -Raw|ConvertFrom-Json -AsHashtable}
else {$budget=@{startedUtc=[DateTime]::UtcNow.ToString('o');attempts=0;limit=30;seconds=10800;completed=@();completedScopes=@{full=@();'install-uninstall'=@()}}}
if ($budget.limit -ne 30 -or $budget.seconds -ne 10800 -or -not $budget.ContainsKey('completedScopes')) {throw 'RELEASE_BUDGET_CONTRACT'}
$scopeDone=@($budget.completedScopes[$QualificationScope])
Assert-ClrWaveCoverage @{completed=$scopeDone} $StartCaseIndex
function Save-ClrBudget {[IO.File]::WriteAllText($budgetPath,($budget|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))}
Save-ClrBudget
$watch=[Diagnostics.Stopwatch]::StartNew()
foreach ($index in $StartCaseIndex..11) {
    $elapsed=([DateTime]::UtcNow-([DateTime]$budget.startedUtc).ToUniversalTime()).TotalSeconds
    if ($elapsed -gt ($budget.seconds-805) -or $budget.attempts -ge $budget.limit -or $index -in $scopeDone){throw 'RELEASE_SHARED_BUDGET_EXHAUSTED_OR_CASE_COMPLETE'}
    $budget.attempts++;Save-ClrBudget
    if ((Get-FileHash -LiteralPath $runsetPath -Algorithm SHA256).Hash -cne $runsetHash) {throw 'RELEASE_RUNSET_DRIFT'}
    foreach ($audit in @($false,$true)) {
        $start=[Diagnostics.ProcessStartInfo]::new((Get-Command pwsh -ErrorAction Stop).Source)
        $start.UseShellExecute=$false; $start.CreateNoWindow=$true
        $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
        foreach ($arg in @('-NoProfile','-NonInteractive','-File',$driver,'-RunsetPath',$runsetPath,'-CaseIndex',[string]$index)) {$start.ArgumentList.Add($arg)}
        if ($audit) {$start.ArgumentList.Add('-AuditOnly')}
        $child=[Diagnostics.Process]::new(); $child.StartInfo=$start
        try {
            $elapsed=([DateTime]::UtcNow-([DateTime]$budget.startedUtc).ToUniversalTime()).TotalSeconds
            if ($elapsed -gt ($budget.seconds-405)){throw 'RELEASE_SHARED_BUDGET_EXHAUSTED'}
            $allowance=400000
            [void]$child.Start(); $stdout=$child.StandardOutput.ReadToEndAsync(); $stderr=$child.StandardError.ReadToEndAsync()
            if (-not $child.WaitForExit($allowance)) {
                $child.Kill($true); $child.WaitForExit()
                throw 'RELEASE_OUTER_WATCHDOG_CLEANUP_UNKNOWN_STOP'
            }
            $out=$stdout.GetAwaiter().GetResult(); $err=$stderr.GetAwaiter().GetResult()
            $label=if ($audit) {'audit'} else {'run'}
            [IO.File]::WriteAllText((Join-Path $evidence "case-$index-$label.stdout.txt"),$out)
            [IO.File]::WriteAllText((Join-Path $evidence "case-$index-$label.stderr.txt"),$err)
            if ($child.ExitCode -ne 0 -or $err.Length -ne 0 -or $out -cnotmatch '^PASS RELEASE_') {
                throw ('RELEASE_CASE_FAILED_'+$index+'_'+$label)
            }
        } finally {$child.Dispose()}
    }
    $scopeDone+=@($index);$budget.completedScopes[$QualificationScope]=$scopeDone;Save-ClrBudget
    Write-Output "PASS RELEASE_CASE $index scope=$QualificationScope; independent cleanup/pins"
}
Assert-ClrWaveCoverage @{completed=$scopeDone} $StartCaseIndex -Final
Write-Output "PASS RELEASE_COMPLETE_MATRIX scope=$QualificationScope; 12 target/CL cases; 24 deployment paths; no publication or full API qualification"
