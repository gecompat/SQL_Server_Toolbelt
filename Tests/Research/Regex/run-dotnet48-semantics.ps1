[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$compiler = Join-Path $env:WINDIR `
    'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw '.NET-Framework-C#-Compiler wurde nicht gefunden.'
}

$source = Join-Path $PSScriptRoot 'DotNet48Semantics.cs'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) `
    ('tbx-r1a-dotnet48-' + [Guid]::NewGuid().ToString('N'))
$executable = Join-Path $temporaryRoot 'DotNet48Semantics.exe'

try {
    [void](New-Item -ItemType Directory -Path $temporaryRoot)
    & $compiler /nologo /optimize+ "/out:$executable" $source
    if ($LASTEXITCODE -ne 0) {
        throw 'Der .NET-Framework-Semantikharness konnte nicht gebaut werden.'
    }

    & $executable
    if ($LASTEXITCODE -ne 0) {
        throw 'Der .NET-Framework-Semantikharness ist fehlgeschlagen.'
    }
}
finally {
    $resolvedTemporaryRoot = [IO.Path]::GetFullPath($temporaryRoot)
    $resolvedSystemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedTemporaryRoot.StartsWith(
            $resolvedSystemTemp, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedTemporaryRoot) -like 'tbx-r1a-dotnet48-*') {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force `
            -ErrorAction SilentlyContinue
    }
}
