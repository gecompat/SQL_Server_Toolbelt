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
$projectPath = Join-Path $moduleRoot 'Clr/Toolbelt.Tsql.ScriptParser.csproj'
$assemblyPath = Join-Path $moduleRoot "Clr/bin/$Configuration/Toolbelt.Tsql.ScriptParser.dll"
$scriptDomPath = Join-Path $moduleRoot "Clr/bin/$Configuration/Microsoft.SqlServer.TransactSql.ScriptDom.dll"
$deployTemplatePath = Join-Path $moduleRoot 'Deployment/Deploy.sql'

$expectedScriptDomHash = '459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7'
$expectedScriptDomIdentity = 'Microsoft.SqlServer.TransactSql.ScriptDom, Version=18.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91'
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
    throw 'MSBuild und das .NET-Framework-4.8-Targeting-Pack werden benötigt.'
}

& $msbuild.Source $projectPath '/t:Rebuild' "/p:Configuration=$Configuration" '/p:Platform=AnyCPU' "/p:ScriptDomDllPath=$ScriptDomDllPath" '/m:1'
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
$description = 'SQL Server Toolbelt toolbelt.tsql.script-parser CLR provider 2.0.0'
$sourceEntries = @(Get-ChildItem -LiteralPath (Join-Path $moduleRoot 'Clr') -Recurse -File |
    Where-Object { $_.Extension -in '.cs', '.csproj' -and $_.FullName -notmatch '[\\/](bin|obj)[\\/]' } |
    Sort-Object { $_.FullName.Substring($moduleRoot.Length).Replace('\', '/') } |
    ForEach-Object { $_.FullName.Substring($moduleRoot.Length + 1).Replace('\', '/') + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash })
$sourceHasher = [Security.Cryptography.SHA256]::Create()
try { $sourceFingerprint = [BitConverter]::ToString($sourceHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceEntries -join "`n")))).Replace('-', '') }
finally { $sourceHasher.Dispose() }
$deploymentEntries = @('Deployment/Deploy.sql', 'Source/TVF_ParseScriptNodes.sql', 'Source/TVF_ParseScriptNodeProperties.sql', 'Source/TVF_TokenizeScript.sql', 'Source/TVF_ParseScriptErrors.sql') |
    ForEach-Object { $_ + ':' + (Get-FileHash -LiteralPath (Join-Path $moduleRoot $_) -Algorithm SHA256).Hash }
$deploymentHasher = [Security.Cryptography.SHA256]::Create()
try { $deploymentFingerprint = [BitConverter]::ToString($deploymentHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($deploymentEntries -join "`n")))).Replace('-', '') }
finally { $deploymentHasher.Dispose() }

$manifest = [ordered]@{
    schemaVersion = '1.0'
    moduleId = 'toolbelt.tsql.script-parser'
    moduleVersion = '2.0.0'
    sourceVersion = '2.0.0'
    sourceFingerprintSha256 = $sourceFingerprint
    deploymentFingerprintSha256 = $deploymentFingerprint
    deploymentSourceFiles = @($deploymentEntries)
    sourceFiles = $sourceEntries
    buildProfile = 'net48-anycpu-release-deterministic'
    guardProfile = [ordered]@{ significantAtoms = 512; rawUnits = 8192; structuralDepth = 32; nestedComments = 16; tokens = 8192; inputBytes = 2097152; nodes = 32768; properties = 131072; errors = 256; outputBytes = 16777216 }
    assemblySqlName = 'Toolbelt_Tsql_ScriptParser'
    assemblyFileName = [IO.Path]::GetFileName($assemblyPath)
    permissionSet = 'UNSAFE'
    directFrameworkReferences = @('System', 'System.Core', 'System.Data', 'System.Xml')
    scriptDomAssemblySqlName = 'Microsoft.SqlServer.TransactSql.ScriptDom'
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
$deployPath = Join-Path $OutputDirectory 'Deploy.WithAssembly.sql'
$assemblyOutputPath = Join-Path $OutputDirectory 'Toolbelt.Tsql.ScriptParser.dll'
$scriptDomOutputPath = Join-Path $OutputDirectory 'Microsoft.SqlServer.TransactSql.ScriptDom.dll'
$deployTemplate = Get-Content -LiteralPath $deployTemplatePath -Raw
if (([regex]::Matches($deployTemplate, '\$\(AssemblyBits\)')).Count -ne 1 -or
    ([regex]::Matches($deployTemplate, '\$\(ScriptDomAssemblyBits\)')).Count -ne 1) {
    throw 'Deployment/Deploy.sql muss je einen AssemblyBits- und ScriptDomAssemblyBits-Platzhalter enthalten.'
}
$scriptDomHex = [BitConverter]::ToString($scriptDomBytes).Replace('-', '')
$deployScript = $deployTemplate.Replace('$(AssemblyBits)', '0x' + $assemblyHex).Replace('$(ScriptDomAssemblyBits)', '0x' + $scriptDomHex)

foreach ($sourceFileName in @(
    'TVF_ParseScriptNodes.sql',
    'TVF_ParseScriptNodeProperties.sql',
    'TVF_TokenizeScript.sql',
    'TVF_ParseScriptErrors.sql'
)) {
    $includeDirective = ':r ../Source/' + $sourceFileName
    $sourcePath = Join-Path $moduleRoot ('Source/' + $sourceFileName)
    $sourceText = Get-Content -LiteralPath $sourcePath -Raw
    if (-not $deployScript.Contains($includeDirective)) {
        throw "Deployment/Deploy.sql enthält den erwarteten Include nicht: $includeDirective"
    }
    $deployScript = $deployScript.Replace($includeDirective, $sourceText.TrimEnd())
}

if ($deployScript -match '(?m)^:r\s+') {
    throw 'Deploy.WithAssembly.sql darf keine externen SQLCMD-Includes enthalten.'
}

[IO.File]::Copy($assemblyPath, $assemblyOutputPath, $true)
[IO.File]::Copy($scriptDomPath, $scriptDomOutputPath, $true)
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding utf8
$deployScript | Set-Content -LiteralPath $deployPath -Encoding utf8
$manifest['deploymentArtifactSha256'] = (Get-FileHash -LiteralPath $deployPath -Algorithm SHA256).Hash
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding utf8

[pscustomobject]@{
    AssemblyPath = $assemblyOutputPath
    TrustManifestPath = $manifestPath
    DeployScriptPath = $deployPath
    AssemblyHash = '0x' + $sha512
    AssemblyDescription = $description
    ScriptDomAssemblyHash = '0x' + $scriptDomSha512
}
