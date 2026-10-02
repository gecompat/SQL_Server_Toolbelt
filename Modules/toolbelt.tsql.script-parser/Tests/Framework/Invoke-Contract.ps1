[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ScriptDomDllPath,
    [Parameter(Mandatory)][string]$ProviderAssemblyPath,
    [Parameter(Mandatory)][string]$TrustManifestPath,
    [string]$EvidencePath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pin = '24BDEE1CC5296488C3609BB6911DD76935B510F823CAAE4D39E8C45C84D272F3D28E3F6156E1E185C0F81D5812C9100E9C71CBE788966AC477A5B213BCE672D0'
$manifest = Get-Content -LiteralPath $TrustManifestPath -Raw | ConvertFrom-Json
if ($manifest.moduleVersion -cne '2.0.0' -or $manifest.buildProfile -cne 'net48-anycpu-release-deterministic') { throw 'RELEASE_PROFILE_MISMATCH' }
$sourceEntries = @(Get-ChildItem -LiteralPath (Join-Path $moduleRoot 'Clr') -Recurse -File |
    Where-Object { $_.Extension -in '.cs', '.csproj' -and $_.FullName -notmatch '[\\/](bin|obj)[\\/]' } |
    Sort-Object { $_.FullName.Substring($moduleRoot.Length).Replace('\', '/') } |
    ForEach-Object { $_.FullName.Substring($moduleRoot.Length + 1).Replace('\', '/') + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash })
function Get-Fingerprint($Entries) {
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($Entries -join "`n")))).Replace('-', '') }
    finally { $hasher.Dispose() }
}
$sourceFingerprint = Get-Fingerprint $sourceEntries
$deploymentEntries = @('Deployment/Deploy.sql', 'Source/TVF_ParseScriptNodes.sql', 'Source/TVF_ParseScriptNodeProperties.sql', 'Source/TVF_TokenizeScript.sql', 'Source/TVF_ParseScriptErrors.sql') |
    ForEach-Object { $_ + ':' + (Get-FileHash -LiteralPath (Join-Path $moduleRoot $_) -Algorithm SHA256).Hash }
$deploymentFingerprint = Get-Fingerprint $deploymentEntries
$providerHash = (Get-FileHash -LiteralPath $ProviderAssemblyPath -Algorithm SHA512).Hash
if ((Get-FileHash -LiteralPath $ScriptDomDllPath -Algorithm SHA512).Hash -cne $pin -or $manifest.scriptDomSha512 -cne $pin -or
    $manifest.sha512 -cne $providerHash -or $manifest.sourceFingerprintSha256 -cne $sourceFingerprint -or
    $manifest.deploymentFingerprintSha256 -cne $deploymentFingerprint) { throw 'RELEASE_FINGERPRINT_MISMATCH' }
if ([Reflection.AssemblyName]::GetAssemblyName($ProviderAssemblyPath).Version.ToString() -cne '2.0.0.0') { throw 'PROVIDER_VERSION_MISMATCH' }
$deploymentArtifact = Join-Path (Split-Path -Parent $TrustManifestPath) 'Deploy.WithAssembly.sql'
if ((Get-FileHash -LiteralPath $deploymentArtifact -Algorithm SHA256).Hash -cne $manifest.deploymentArtifactSha256) { throw 'DEPLOYMENT_ARTIFACT_MISMATCH' }
$harnessEntries = @(Get-ChildItem -LiteralPath $PSScriptRoot -File | Sort-Object Name |
    ForEach-Object { $_.Name + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash })
$harnessFingerprint = Get-Fingerprint $harnessEntries
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltParserFramework-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
[IO.File]::Copy($ScriptDomDllPath, (Join-Path $tempRoot 'Microsoft.SqlServer.TransactSql.ScriptDom.dll'))
[IO.File]::Copy($ProviderAssemblyPath, (Join-Path $tempRoot 'Toolbelt.Tsql.ScriptParser.dll'))
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$guardExe = Join-Path $tempRoot 'GuardTests.exe'
$providerExe = Join-Path $tempRoot 'ProviderTests.exe'
$compileOutput = & $compiler /nologo /optimize+ /target:exe "/out:$guardExe" (Join-Path $moduleRoot 'Clr/PreparseGuard.cs') (Join-Path $PSScriptRoot 'GuardTests.cs') (Join-Path $PSScriptRoot 'TestInputs.cs') 2>&1
if ($LASTEXITCODE -ne 0) { throw 'GUARD_HARNESS_BUILD_FAILED' }
$compileOutput = & $compiler /nologo /optimize+ /target:exe "/out:$providerExe" /reference:System.Data.dll "/reference:$ProviderAssemblyPath" (Join-Path $PSScriptRoot 'ProviderTests.cs') (Join-Path $PSScriptRoot 'TestInputs.cs') 2>&1
if ($LASTEXITCODE -ne 0) { throw 'PROVIDER_HARNESS_BUILD_FAILED' }
$childCases = 0
function Invoke-Bounded([string]$Executable, [string[]]$Arguments, [string]$Expected) {
    $psi = [Diagnostics.ProcessStartInfo]::new($Executable)
    $psi.Arguments = ($Arguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }) -join ' '
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.WindowStyle = 'Hidden'
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $child = [Diagnostics.Process]::Start($psi)
    $stdout = $child.StandardOutput.ReadToEndAsync(); $stderr = $child.StandardError.ReadToEndAsync()
    try {
        if (-not $child.WaitForExit(10000)) { $child.Kill(); throw 'FRAMEWORK_CHILD_TIMEOUT' }
        $output = $stdout.GetAwaiter().GetResult(); $errorOutput = $stderr.GetAwaiter().GetResult()
        if ($child.ExitCode -ne 0 -or $output.Length -gt 4096 -or $errorOutput.Length -gt 4096 -or -not $output.StartsWith($Expected, [StringComparison]::Ordinal)) { throw ('FRAMEWORK_CHILD_FAILED_' + $script:childCases) }
        $script:childCases++
    } finally { $child.Dispose() }
}
Invoke-Bounded $guardExe @() 'GUARD_PASS '
Invoke-Bounded $providerExe @('parameters') 'FRAMEWORK_PASS'
Invoke-Bounded $providerExe @('quotas') 'FRAMEWORK_PASS'
foreach ($version in @(80,90,100,110,120,130,140,150,160,170)) { Invoke-Bounded $providerExe @('legacy', [string]$version) 'FRAMEWORK_PASS' }
$cases=[Collections.Generic.List[object]]::new()
function Add-Case($Version,$Name,$N,$Status,[int]$Atoms=-1,[int]$Comments=-1){$cases.Add([pscustomobject]@{Version=$Version;Name=$Name;N=$N;Status=$Status;Atoms=$Atoms;Comments=$Comments})}
$base=@'
Name,N,Status
unary,128,ACCEPT
unary,509,ACCEPT
unary,510,REJECT
binary,254,ACCEPT
binary,255,REJECT
not,505,ACCEPT
paren,32,ACCEPT
paren,33,REJECT
comment,16,ACCEPT
comment,17,REJECT
case,32,ACCEPT
case,33,REJECT
begin,32,ACCEPT
begin,33,REJECT
union,127,ACCEPT
union,128,REJECT
subquery,32,ACCEPT
subquery,33,REJECT
batches,128,ACCEPT
batches,129,REJECT
semicolons,170,ACCEPT
semicolons,171,REJECT
spaces,8183,ACCEPT
spaces,8184,REJECT
trivia,1000,REJECT
quoted,1,ACCEPT
unclosed,1,ACCEPT
unclosedcomment,1,ACCEPT
numericrun,8193,REJECT
'@ | ConvertFrom-Csv
foreach($case in $base){Add-Case 160 $case.Name ([int]$case.N) $case.Status}
$cross=@'
Name,N,Status
unary,509,ACCEPT
unary,510,REJECT
paren,32,ACCEPT
paren,33,REJECT
comment,16,ACCEPT
comment,17,REJECT
mixed,0,ACCEPT
mixed,1,REJECT
mixedunary,500,ACCEPT
mixedunary,501,REJECT
commentmarkers,1,ACCEPT
linemarkers,1,ACCEPT
unicode,1,ACCEPT
surrogate,1,ACCEPT
quotedbytes,1048566,ACCEPT
quotedbytes,1048567,INPUT
'@ | ConvertFrom-Csv
foreach($version in @(150,170)){foreach($case in $cross){Add-Case $version $case.Name ([int]$case.N) $case.Status}}
Add-Case 160 exponents 1 ACCEPT 5
Add-Case 160 exponents 254 ACCEPT 511
Add-Case 160 exponents 255 REJECT 513
Add-Case 160 dotted 1 ACCEPT 6
Add-Case 160 dotted 169 ACCEPT 510
Add-Case 160 dotted 170 REJECT 513
Add-Case 160 symbols 1 ACCEPT 6
Add-Case 160 symbols 169 ACCEPT 510
Add-Case 160 symbols 170 REJECT 513
Add-Case 160 combining 1 ACCEPT 4
Add-Case 160 combining 509 ACCEPT 512
Add-Case 160 combining 510 REJECT 513
Add-Case 160 commentpriority 1 REJECT 0 16
foreach($case in @(@('unary',508),@('paren',31),@('comment',15),@('case',31),@('begin',31),@('subquery',31),@('spaces',8182),@('quotedbytes',1048565))){
 Add-Case 160 $case[0] $case[1] ACCEPT
}
# Public legacy constructors receive the same high-risk accepted profile and immediate rejection witnesses.
# These are Framework qualification cases, not a claim of SQL-host matrix execution.
foreach ($version in @(80,90,100,110,120,130,140)) {
    foreach ($pair in @(
        @('unary',509,510), @('not',505,506), @('paren',32,33),
        @('case',32,33), @('begin',32,33), @('subquery',32,33), @('mixed',0,1)
    )) {
        Add-Case $version $pair[0] $pair[1] ACCEPT
        Add-Case $version $pair[0] $pair[2] REJECT
    }
}

foreach ($case in $cases) { Invoke-Bounded $providerExe @('boundary', $case.Name, [string]$case.N, [string]$case.Version, $case.Status) 'FRAMEWORK_PASS' }
$corpus = @(
    'SELECT 1;',
    "SELECT N'𝄞é' AS [x];",
    'WITH c AS (SELECT 1 AS n) SELECT n FROM c WHERE EXISTS (SELECT 1);',
    'SELECT a.n FROM (SELECT 1 AS n) a JOIN (SELECT 2 AS n) b ON a.n=b.n CROSS APPLY (SELECT a.n) c;',
    'SELECT 1 UNION ALL SELECT 2 INTERSECT SELECT 3 EXCEPT SELECT 4;',
    'INSERT INTO dbo.t(n) VALUES(1); UPDATE dbo.t SET n=n+1; DELETE FROM dbo.t WHERE n>2;',
    'MERGE dbo.t AS t USING (SELECT 1 AS n) s ON t.n=s.n WHEN MATCHED THEN UPDATE SET n=s.n WHEN NOT MATCHED THEN INSERT(n) VALUES(s.n);',
    'CREATE TABLE dbo.t(n int NOT NULL CONSTRAINT pk PRIMARY KEY); CREATE INDEX ix ON dbo.t(n); ALTER TABLE dbo.t ADD x int; DROP TABLE dbo.t;',
    'CREATE PROCEDURE dbo.p AS BEGIN SELECT 1; END;',
    'CREATE FUNCTION dbo.f() RETURNS int AS BEGIN RETURN 1; END;',
    'CREATE TRIGGER dbo.tr ON dbo.t AFTER INSERT AS BEGIN SELECT 1; END;',
    'BEGIN TRY BEGIN TRANSACTION; SAVE TRANSACTION s; COMMIT; END TRY BEGIN CATCH ROLLBACK; THROW; END CATCH;',
    'CREATE ROLE demo; GRANT SELECT ON dbo.t TO demo; DENY INSERT ON dbo.t TO demo; REVOKE SELECT ON dbo.t FROM demo;',
    "/* quoted '' [ ] */ SELECT 1;`nGO`n-- unicode é`nSELECT 2;",
    ('SELECT ' + ('1+' * 120) + '1 WHERE ' + ('1=1 AND ' * 20) + '1=1;'),
    'SELECT 1;'
)
# The repeated JOIN corpus uses distinct aliases and stays within the cumulative budget.
$corpus[$corpus.Count - 1] = 'SELECT 1 FROM (SELECT 1 AS n) a' + ((1..12 | ForEach-Object { ' CROSS JOIN (SELECT 1 AS n) b' + $_ }) -join '') + ';'
foreach ($version in @(150,160,170)) {
    $index = 0
    foreach ($sql in $corpus) {
        $file = Join-Path $tempRoot ('corpus-' + $version + '-' + $index++ + '.sql')
        [IO.File]::WriteAllText($file, $sql, [Text.UTF8Encoding]::new($false))
        Invoke-Bounded $providerExe @('corpus', $file, [string]$version) 'FRAMEWORK_PASS'
    }
}
foreach ($case in @(
    @{ Sql = 'SELECT SUM(x) OVER w FROM (VALUES(1))v(x) WINDOW w AS(ORDER BY x);'; Positive = 160; Negative = 150 },
    @{ Sql = 'SELECT JSON_ARRAYAGG(x ORDER BY x) FROM (VALUES(1))v(x);'; Positive = 170; Negative = 160 }
)) {
    $file = Join-Path $tempRoot ('version-' + $case.Positive + '.sql')
    [IO.File]::WriteAllText($file, $case.Sql, [Text.UTF8Encoding]::new($false))
    Invoke-Bounded $providerExe @('corpus', $file, [string]$case.Positive) 'FRAMEWORK_PASS'
    Invoke-Bounded $providerExe @('negative', $file, [string]$case.Negative) 'FRAMEWORK_PASS'
}
$evidence = [ordered]@{ status = 'PASS'; providerSha512 = $providerHash; scriptDomSha512 = $pin; sourceFingerprint = $sourceFingerprint;
    deploymentFingerprint = $deploymentFingerprint; deploymentArtifactSha256 = $manifest.deploymentArtifactSha256; harnessFingerprint = $harnessFingerprint; guardProfile = $manifest.guardProfile; buildProfile = $manifest.buildProfile; childCases = $childCases;
    configuredThreadStackBytes = 262144; sqlExecuted = $false; quotaEvidence = 'private lowered-limit accounting helper'; actualOutputCeilings = 'not qualified by helper' }
$json = $evidence | ConvertTo-Json -Depth 5 -Compress
if ($EvidencePath) { [IO.File]::WriteAllText($EvidencePath, $json, [Text.UTF8Encoding]::new($false)) }
$json
