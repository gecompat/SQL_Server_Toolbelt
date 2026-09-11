[CmdletBinding()]
param(
    [string]$Configuration = 'Release',
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

& $msbuild.Source $projectPath '/t:Rebuild' "/p:Configuration=$Configuration" '/p:Platform=AnyCPU' '/m:1'
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $assemblyPath -PathType Leaf) -or -not (Test-Path -LiteralPath $scriptDomPath -PathType Leaf)) {
    throw 'Der CLR-ScriptParser-Assembly-Build ist fehlgeschlagen.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$assemblyBytes = [IO.File]::ReadAllBytes($assemblyPath)
$scriptDomBytes = [IO.File]::ReadAllBytes($scriptDomPath)
$assemblyHex = [BitConverter]::ToString($assemblyBytes).Replace('-', '')
$sha512 = (Get-FileHash -Algorithm SHA512 -LiteralPath $assemblyPath).Hash.ToUpperInvariant()
$scriptDomSha512 = (Get-FileHash -Algorithm SHA512 -LiteralPath $scriptDomPath).Hash.ToUpperInvariant()
$description = 'SQL Server Toolbelt toolbelt.tsql.script-parser CLR provider 1.0.0'

$manifest = [ordered]@{
    schemaVersion = '1.0'
    moduleId = 'toolbelt.tsql.script-parser'
    moduleVersion = '1.0.0'
    assemblySqlName = 'Toolbelt_Tsql_ScriptParser'
    assemblyFileName = [IO.Path]::GetFileName($assemblyPath)
    permissionSet = 'UNSAFE'
    directFrameworkReferences = @('System', 'System.Core', 'System.Data', 'System.Xml')
    scriptDomAssemblySqlName = 'Microsoft.SqlServer.TransactSql.ScriptDom'
    scriptDomAssemblyFileName = [IO.Path]::GetFileName($scriptDomPath)
    scriptDomSha512 = $scriptDomSha512
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

[pscustomobject]@{
    AssemblyPath = $assemblyOutputPath
    TrustManifestPath = $manifestPath
    DeployScriptPath = $deployPath
    AssemblyHash = '0x' + $sha512
    AssemblyDescription = $description
    ScriptDomAssemblyHash = '0x' + $scriptDomSha512
}
