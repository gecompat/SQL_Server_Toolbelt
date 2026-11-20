[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ScriptDomDllPath,
    [ValidateSet('Release')][string]$Configuration = 'Release',
    [string]$OutputDirectory =
        (Join-Path (Split-Path -Parent $PSScriptRoot) 'Artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $moduleRoot '../../Scripts/Clr/Resolve-ToolbeltScriptDom.ps1')
$ScriptDomDllPath=Resolve-ToolbeltScriptDom -Path $ScriptDomDllPath
$projectPath = Join-Path $moduleRoot 'Clr/Toolbelt.Tsql.ScriptParser.csproj'
$assemblyPath = Join-Path $moduleRoot "Clr/bin/$Configuration/Toolbelt.Tsql.ScriptParser.dll"
$scriptDomPath = Join-Path $moduleRoot "Clr/bin/$Configuration/tlblt.Microsoft.SqlServer.TransactSql.ScriptDom.dll"

$expectedScriptDomHash = '634EBA3C4D7AB7EBEA4B59C68C3B0C78081686F54359595B8206EADE989BFC51D02A91DAB4CA23065854C1624E93A2B4C2216AB6AA7DF9CA191541BF0F795813'
$expectedScriptDomIdentity = 'tlblt.Microsoft.SqlServer.TransactSql.ScriptDom, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null'
function Assert-ScriptDomPin([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'SCRIPT_DOM_PIN_MISSING' }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA512).Hash -cne $expectedScriptDomHash -or
        [Reflection.AssemblyName]::GetAssemblyName($Path).FullName -cne $expectedScriptDomIdentity -or
        [Diagnostics.FileVersionInfo]::GetVersionInfo($Path).FileVersion -cne '18.0.117.0') {
        throw 'SCRIPT_DOM_PIN_MISMATCH'
    }
}
Assert-ScriptDomPin $ScriptDomDllPath

$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
$msbuildArguments = @()
if ($null -eq $msbuild) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
        $msbuildPath = & $vswhere `
            -latest -products * -requires Microsoft.Component.MSBuild `
            -find 'MSBuild/**/Bin/MSBuild.exe' | Select-Object -First 1
        if ($msbuildPath) { $msbuild = [pscustomobject]@{ Source = $msbuildPath } }
    }
}
if ($null -eq $msbuild) {
    $ssmsMsbuild = 'C:\Program Files\Microsoft SQL Server Management Studio 22\Release\MSBuild\Current\Bin\MSBuild.exe'
    if (Test-Path -LiteralPath $ssmsMsbuild -PathType Leaf) {
        $msbuild = [pscustomobject]@{ Source = $ssmsMsbuild }
    }
}
if ($null -eq $msbuild) {
    $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($null -ne $dotnet) {
        $msbuild = [pscustomobject]@{ Source = $dotnet.Source }
        $msbuildArguments = @('msbuild')
    }
}
if ($null -eq $msbuild) {
    throw 'MSBuild oder dotnet msbuild sowie das .NET-Framework-4.8-Targeting-Pack werden benötigt.'
}

& $msbuild.Source @msbuildArguments $projectPath '/t:Rebuild' "/p:Configuration=$Configuration" '/p:Platform=AnyCPU' "/p:ScriptDomDllPath=$ScriptDomDllPath" '/m:1'
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $assemblyPath -PathType Leaf) -or -not (Test-Path -LiteralPath $scriptDomPath -PathType Leaf)) {
    throw 'Der CLR-ScriptParser-Assembly-Build ist fehlgeschlagen.'
}
Assert-ScriptDomPin $scriptDomPath

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$assemblyBytes = [IO.File]::ReadAllBytes($assemblyPath)
$scriptDomBytes = [IO.File]::ReadAllBytes($scriptDomPath)
$assemblyHex = [BitConverter]::ToString($assemblyBytes).Replace('-', '')
$sha512 = (Get-FileHash -Algorithm SHA512 -LiteralPath $assemblyPath).Hash.ToUpperInvariant()
$scriptDomSha512 = (Get-FileHash -Algorithm SHA512 -LiteralPath $scriptDomPath).Hash.ToUpperInvariant()
$description = 'SQL Server Toolbelt toolbelt.tsql.script-parser CLR provider 2.0.1'
$sourceEntries = @(Get-ChildItem -LiteralPath (Join-Path $moduleRoot 'Clr') -Recurse -File |
    Where-Object { $_.Extension -in '.cs', '.csproj' -and $_.FullName -notmatch '[\\/](bin|obj)[\\/]' } |
    Sort-Object { $_.FullName.Substring($moduleRoot.Length).Replace('\', '/') } |
    ForEach-Object { $_.FullName.Substring($moduleRoot.Length + 1).Replace('\', '/') + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash })
$sourceHasher = [Security.Cryptography.SHA256]::Create()
try { $sourceFingerprint = [BitConverter]::ToString($sourceHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceEntries -join "`n")))).Replace('-', '') }
finally { $sourceHasher.Dispose() }
$deploymentEntries = @('Source/TVF_ParseScriptNodes.sql', 'Source/TVF_ParseScriptNodeProperties.sql', 'Source/TVF_TokenizeScript.sql', 'Source/TVF_ParseScriptErrors.sql') |
    ForEach-Object { $_ + ':' + (Get-FileHash -LiteralPath (Join-Path $moduleRoot $_) -Algorithm SHA256).Hash }
$deploymentHasher = [Security.Cryptography.SHA256]::Create()
try { $deploymentFingerprint = [BitConverter]::ToString($deploymentHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($deploymentEntries -join "`n")))).Replace('-', '') }
finally { $deploymentHasher.Dispose() }

$manifest = [ordered]@{
    schemaVersion = '1.0'
    moduleId = 'toolbelt.tsql.script-parser'
    moduleVersion = '2.0.1'
    sourceVersion = '2.0.1'
    sourceFingerprintSha256 = $sourceFingerprint
    deploymentFingerprintSha256 = $deploymentFingerprint
    deploymentSourceFiles = @($deploymentEntries)
    sourceFiles = $sourceEntries
    buildProfile = 'net48-anycpu-release-deterministic'
    guardProfile = [ordered]@{ significantAtoms = 512; rawUnits = 8192; structuralDepth = 32; nestedComments = 16; tokens = 8192; inputBytes = 2097152; nodes = 32768; properties = 131072; errors = 256; outputBytes = 16777216 }
    assemblySqlName = 'tlblt_Tsql_ScriptParser'
    assemblyFileName = [IO.Path]::GetFileName($assemblyPath)
    permissionSet = 'UNSAFE'
    directFrameworkReferences = @('System', 'System.Core', 'System.Data', 'System.Xml')
    scriptDomAssemblySqlName = 'tlblt.Microsoft.SqlServer.TransactSql.ScriptDom'
    scriptDomAssemblyFileName = [IO.Path]::GetFileName($scriptDomPath)
    scriptDomSha512 = $scriptDomSha512
    scriptDomAssemblyIdentity = $expectedScriptDomIdentity
    scriptDomFileVersion = '18.0.117.0'
    scriptDomSqlServerHexLiteral = '0x' + $scriptDomSha512
    sha512 = $sha512
    sqlServerHexLiteral = '0x' + $sha512
    description = $description
}

$manifestPath = Join-Path $OutputDirectory 'Toolbelt.Tsql.ScriptParser.trust-manifest.json'
$assemblyOutputPath = Join-Path $OutputDirectory 'Toolbelt.Tsql.ScriptParser.dll'
$scriptDomOutputPath = Join-Path $OutputDirectory 'tlblt.Microsoft.SqlServer.TransactSql.ScriptDom.dll'
[IO.File]::Copy($assemblyPath, $assemblyOutputPath, $true)
[IO.File]::Copy($scriptDomPath, $scriptDomOutputPath, $true)
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding utf8

[pscustomobject]@{
    AssemblyPath = $assemblyOutputPath
    TrustManifestPath = $manifestPath
    InstallBuilder = "Deployment/Build-Install.ps1"
    AssemblyHash = '0x' + $sha512
    AssemblyDescription = $description
    ScriptDomAssemblyHash = '0x' + $scriptDomSha512
}
