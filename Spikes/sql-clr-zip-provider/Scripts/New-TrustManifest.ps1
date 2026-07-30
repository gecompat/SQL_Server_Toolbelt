[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$AssemblyPath,

    [Parameter(Mandatory)]
    [string]$OutputPath,

    [string]$AssemblyDescription = 'SQL Server Toolbelt ZIP CLR deployment spike 0.1.0'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$hash = (Get-FileHash -Algorithm SHA512 -LiteralPath $AssemblyPath).Hash.ToUpperInvariant()
$manifest = [ordered]@{
    schemaVersion = '1.0'
    purpose = 'SQL CLR trusted assembly input; non-production deployment spike'
    assemblyFileName = [IO.Path]::GetFileName($AssemblyPath)
    sha512 = $hash
    sqlServerHexLiteral = '0x' + $hash
    description = $AssemblyDescription
}

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$manifest | ConvertTo-Json | Set-Content -LiteralPath $OutputPath -Encoding utf8
Write-Output "SHA2-512-Trust-Manifest erstellt: $OutputPath"
