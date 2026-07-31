[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $AssemblyPath,
    [Parameter(Mandatory = $true)]
    [string] $OutputDirectory
)

$ErrorActionPreference = 'Stop'
$assembly = [IO.Path]::GetFullPath($AssemblyPath)
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (-not (Test-Path -LiteralPath $assembly -PathType Leaf)) { throw 'AssemblyPath does not exist.' }
New-Item -ItemType Directory -Force -Path $output | Out-Null
$hash = (Get-FileHash -LiteralPath $assembly -Algorithm SHA512).Hash.ToLowerInvariant()
$hex = '0x' + $hash
Set-Content -LiteralPath (Join-Path $output 'Toolbelt.Filesystem.Windows.sha2-512.txt') -Value $hex -NoNewline -Encoding ascii
Set-Content -LiteralPath (Join-Path $output 'Toolbelt.Filesystem.Windows.assembly-bits.sqlcmd.txt') -Value ([Convert]::ToHexString([IO.File]::ReadAllBytes($assembly)).Insert(0, '0x')) -NoNewline -Encoding ascii
