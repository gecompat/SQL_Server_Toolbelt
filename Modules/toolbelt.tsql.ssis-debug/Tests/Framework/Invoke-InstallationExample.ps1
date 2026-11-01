<#
Begrenzte Offlineprüfung des Installationsbeispiels. Ausschließlich synthetische
Dateien/Manifeste und ein PowerShell-sqlcmd-Doppel; keine SQL-Verbindung,
keine Serverkonfiguration, kein Trusteintrag und keine Assemblyausführung.
#>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$installer = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../Examples/Installation/Install-Local.ps1'))
$taskRoot = Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltSsisInstallExample-' + [guid]::NewGuid().ToString('N'))
$fakeRoot = Join-Path $taskRoot 'repository'
$callLog = Join-Path $taskRoot 'calls.jsonl'
$shim = Join-Path $taskRoot 'synthetic-sqlcmd.ps1'
$priorCallLog = $env:TOOLBELT_SSIS_INSTALL_TEST_CALLS
$priorFailure = $env:TOOLBELT_SSIS_INSTALL_TEST_FAIL_AT
$script:checks = 0
function Check([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('SSIS_INSTALL_EXAMPLE_ASSERT_' + $Name) }
    $script:checks++
}
function Write-Synthetic([string]$RelativePath, [string]$Content) {
    $path = Join-Path $fakeRoot $RelativePath
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
    return $path
}
function Save-Json([string]$Path, $Value) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
}
function Hash-File([string]$Path, [string]$Algorithm = 'SHA512') {
    return (Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash
}
function Reset-Calls {
    if (Test-Path -LiteralPath $callLog) { Remove-Item -LiteralPath $callLog }
    $env:TOOLBELT_SSIS_INSTALL_TEST_FAIL_AT = $null
}
function Calls {
    if (Test-Path -LiteralPath $callLog) {
        foreach ($line in [IO.File]::ReadAllLines($callLog)) { $line | ConvertFrom-Json }
    }
}
function Invoke-FakeInstall([bool]$Trust = $true, [switch]$Validate) {
    & $installer -Server localhost -Database ContosoSsisDebug -RepositoryRoot $fakeRoot `
        -SqlcmdPath $shim -TrustServerCertificate:$Trust -ValidateOnly:$Validate | Out-Null
}
function Expect-Rejection([string]$Code) {
    Reset-Calls
    $rejected = $false
    try { Invoke-FakeInstall } catch { $rejected = $_.Exception.Message.Contains($Code) }
    Check $rejected ('REJECTION_' + $Code)
    Check (@(Calls).Count -eq 0) 'REJECTION_BEFORE_SQLCMD'
}
try {
    [void][IO.Directory]::CreateDirectory($taskRoot)
    $env:TOOLBELT_SSIS_INSTALL_TEST_CALLS = $callLog
    $stubText = @'
$record = [ordered]@{ Arguments = @($args); Directory = (Get-Location).Path }
[IO.File]::AppendAllText($env:TOOLBELT_SSIS_INSTALL_TEST_CALLS,
    ($record | ConvertTo-Json -Compress) + [Environment]::NewLine)
$phase = [IO.File]::ReadAllLines($env:TOOLBELT_SSIS_INSTALL_TEST_CALLS).Length
if ($env:TOOLBELT_SSIS_INSTALL_TEST_FAIL_AT -eq [string]$phase) { exit 19 }
exit 0
'@
    [IO.File]::WriteAllText($shim, $stubText, [Text.UTF8Encoding]::new($false))
    foreach ($relative in @(
        'toolbelt.core.result-table/Deployment/Deploy.sql',
        'toolbelt.core.result-table/Source/SchemaTrustPreflight.sql',
        'toolbelt.core.result-table/Source/USP_PrepareResultTable.sql',
        'toolbelt.tsql.script-parser/Deployment/Add-TrustedAssembly.sql',
        'toolbelt.tsql.ssis-debug/Deployment/Add-TrustedAssembly.sql')) {
        [void](Write-Synthetic ('Modules/' + $relative) '-- synthetic input; no SQL execution')
    }
    $parserDll = Write-Synthetic 'Modules/toolbelt.tsql.script-parser/Artifacts/Toolbelt.Tsql.ScriptParser.dll' 'synthetic parser bytes'
    $domDll = Write-Synthetic 'Modules/toolbelt.tsql.script-parser/Artifacts/Microsoft.SqlServer.TransactSql.ScriptDom.dll' 'synthetic scriptdom bytes'
    $ssisDll = Write-Synthetic 'Modules/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.dll' 'synthetic ssis bytes'
    $parserDeploy = Write-Synthetic 'Modules/toolbelt.tsql.script-parser/Artifacts/Deploy.WithAssembly.sql' '-- synthetic parser deployment'
    $ssisDeploy = Write-Synthetic 'Modules/toolbelt.tsql.ssis-debug/Artifacts/Deploy.WithAssembly.sql' '-- synthetic ssis deployment'
    $pinsPath = Write-Synthetic 'Modules/toolbelt.tsql.ssis-debug/Contracts/DependencyPins.json' '{}'
    $parserManifest = Write-Synthetic 'Modules/toolbelt.tsql.script-parser/Artifacts/Toolbelt.Tsql.ScriptParser.trust-manifest.json' '{}'
    $ssisManifest = Write-Synthetic 'Modules/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.trust-manifest.json' '{}'
    $pins = @{ parserVersion = '2.0.1'; parserSha512 = (Hash-File $parserDll); scriptDomSha512 = (Hash-File $domDll) }
    $parser = @{ moduleId = 'toolbelt.tsql.script-parser'; moduleVersion = '2.0.1'; sha512 = $pins.parserSha512;
        scriptDomSha512 = $pins.scriptDomSha512; deploymentArtifactSha256 = (Hash-File $parserDeploy 'SHA256') }
    $ssis = @{ moduleId = 'toolbelt.tsql.ssis-debug'; moduleVersion = '1.0.0'; parserVersion = '2.0.1';
        parserSha512 = $pins.parserSha512; scriptDomSha512 = $pins.scriptDomSha512;
        sha512 = (Hash-File $ssisDll); deploymentArtifactSha256 = (Hash-File $ssisDeploy 'SHA256') }
    Save-Json $pinsPath $pins; Save-Json $parserManifest $parser; Save-Json $ssisManifest $ssis

    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($installer, [ref]$tokens, [ref]$errors)
    Check ($errors.Count -eq 0) 'POWERSHELL_SYNTAX'
    Invoke-FakeInstall -Validate
    Check (@(Calls).Count -eq 0) 'VALIDATE_ONLY_NO_PROCESS'
    & $installer -Server localhost -RepositoryRoot $fakeRoot -SqlcmdPath 'synthetic-command-does-not-exist' -ValidateOnly | Out-Null
    Check (@(Calls).Count -eq 0) 'VALIDATE_ONLY_NO_SQLCMD_REQUIRED'

    [IO.File]::WriteAllText($ssisDll, 'changed synthetic bytes')
    Expect-Rejection 'SSIS_INSTALL_ARTIFACT_HASH_MISMATCH'
    [IO.File]::WriteAllText($ssisDll, 'synthetic ssis bytes')
    [IO.File]::WriteAllText($parserDeploy, '-- changed synthetic deployment')
    Expect-Rejection 'SSIS_INSTALL_ARTIFACT_HASH_MISMATCH'
    [IO.File]::WriteAllText($parserDeploy, '-- synthetic parser deployment')
    $ssis.parserSha512 = '0' * 128; Save-Json $ssisManifest $ssis
    Expect-Rejection 'SSIS_INSTALL_DEPENDENCY_PIN_MISMATCH'
    $ssis.parserSha512 = $pins.parserSha512; Save-Json $ssisManifest $ssis
    $parser.moduleVersion = '2.0.0'; Save-Json $parserManifest $parser
    Expect-Rejection 'SSIS_INSTALL_DEPENDENCY_PIN_MISMATCH'
    $parser.moduleVersion = '2.0.1'; Save-Json $parserManifest $parser
    Remove-Item -LiteralPath $ssisManifest
    Expect-Rejection 'SSIS_INSTALL_INPUT_MISSING'
    Save-Json $ssisManifest $ssis

    Reset-Calls
    $locationBefore = (Get-Location).Path
    Invoke-FakeInstall
    $records = @(Calls)
    Check ($records.Count -eq 5) 'FIVE_INSTALL_PHASES'
    Check ((Get-Location).Path -ceq $locationBefore) 'CALLER_DIRECTORY_RESTORED'
    $expectedFiles = @(
        './Deploy.sql',
        (Join-Path $fakeRoot 'Modules/toolbelt.tsql.script-parser/Deployment/Add-TrustedAssembly.sql'),
        $parserDeploy,
        (Join-Path $fakeRoot 'Modules/toolbelt.tsql.ssis-debug/Deployment/Add-TrustedAssembly.sql'),
        $ssisDeploy)
    foreach ($index in 0..4) {
        $arguments = @($records[$index].Arguments)
        Check ($arguments[([array]::IndexOf($arguments, '-i') + 1)] -ceq $expectedFiles[$index]) 'PHASE_ORDER'
        $expectedDb = if ($index -in 1,3) { 'master' } else { 'ContosoSsisDebug' }
        Check ($arguments[([array]::IndexOf($arguments, '-d') + 1)] -ceq $expectedDb) 'DATABASE_SCOPE'
        Check (@('-E','-N','-b','-C' | Where-Object { $_ -notin $arguments }).Count -eq 0) 'EXPLICIT_TRANSPORT_AND_ABORT'
        Check ($arguments[([array]::IndexOf($arguments, '-f') + 1)] -ceq '65001' -and '-f' -in $arguments) 'EXPLICIT_UTF8_SQL_INPUT'
    }
    Check ($records[0].Directory -ceq (Join-Path $fakeRoot 'Modules/toolbelt.core.result-table/Deployment')) 'RELATIVE_RESULTTABLE_INCLUDES'
    Check (('AssemblyHash=0x' + $pins.parserSha512) -in @($records[1].Arguments)) 'EXACT_PARSER_TRUST'
    Check (('ScriptDomAssemblyHash=0x' + $pins.scriptDomSha512) -in @($records[1].Arguments)) 'EXACT_SCRIPTDOM_TRUST'
    Check (('AssemblySha512=0x' + $ssis.sha512) -in @($records[3].Arguments)) 'EXACT_SSIS_TRUST'

    Reset-Calls; Invoke-FakeInstall -Trust $false
    $records = @(Calls)
    Check ($records.Count -eq 5) 'FALSE_TRUST_PHASE_COUNT'
    foreach ($record in $records) { Check ('-C' -notin @($record.Arguments)) 'FALSE_TRUST_NO_CERTIFICATE_BYPASS' }

    foreach ($failurePhase in 1..5) {
        Reset-Calls
        $env:TOOLBELT_SSIS_INSTALL_TEST_FAIL_AT = [string]$failurePhase
        $rejected = $false
        try { Invoke-FakeInstall -Trust $false } catch {
            $rejected = $_.Exception.Message.Contains('SSIS_INSTALL_SQLCMD_FAILED')
        }
        Check $rejected 'SQLCMD_ERROR_PROPAGATED'
        Check (@(Calls).Count -eq $failurePhase) 'NO_FOLLOWING_PHASE_OR_TRANSPORT_RETRY'
        Check ((Get-Location).Path -ceq $locationBefore) 'FAILURE_DIRECTORY_RESTORED'
    }
    'SSIS_INSTALL_EXAMPLE_PASS ' + $script:checks + ' assertions; synthetic files and process double; no SQL executed'
}
finally {
    $env:TOOLBELT_SSIS_INSTALL_TEST_CALLS = $priorCallLog
    $env:TOOLBELT_SSIS_INSTALL_TEST_FAIL_AT = $priorFailure
    if (Test-Path -LiteralPath $taskRoot) {
        $resolvedRoot = (Resolve-Path -LiteralPath $taskRoot).Path
        $tempBoundary = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
        if (-not $resolvedRoot.StartsWith($tempBoundary,[StringComparison]::OrdinalIgnoreCase) -or
            -not (Split-Path -Leaf $resolvedRoot).StartsWith('ToolbeltSsisInstallExample-',[StringComparison]::Ordinal)) {
            throw 'SSIS_INSTALL_EXAMPLE_CLEANUP_SCOPE_INVALID'
        }
        Remove-Item -LiteralPath $resolvedRoot -Recurse -Force
    }
}
# Negative Prozessfälle hinterlassen absichtlich einen nativen Exitcode.
# Erst nach erfolgreicher Prüfung und eigener Bereinigung Erfolg zurückgeben.
exit 0
