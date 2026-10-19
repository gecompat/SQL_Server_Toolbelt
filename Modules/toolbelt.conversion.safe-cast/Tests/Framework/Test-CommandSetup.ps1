[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Der unveraenderte Helper wird aus der kanonischen Quelle geladen. Echte
# SqlCommand-Disposed-Events bilden das Oracle; keine Verbindung wird geoeffnet.
$source = Join-Path $PSScriptRoot '../Runtime/Metadata.Tests.ps1'
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'SAFE_CAST_SETUP_SOURCE_PARSE' }
$helpers = @($ast.FindAll({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -ceq 'New-SafeCastCommand'
}, $true))
if ($helpers.Count -ne 1) { throw 'SAFE_CAST_SETUP_EXACT_HELPER_REQUIRED' }
. ([scriptblock]::Create($helpers[0].Extent.Text))

$Connection = [Data.SqlClient.SqlConnection]::new()
$connectionDisposition = [pscustomobject]@{ Count = 0 }
$Connection.add_Disposed({ $connectionDisposition.Count++ }.GetNewClosure())
try {
    foreach ($kind in @('ProviderThrows', 'InvalidTimeout')) {
        $probeState = [pscustomobject]@{ Command = $null; Disposed = 0; Seen = $false }
        $CommandTimeoutProvider = {
            # Scope 1 ist der aufrufende kanonische Helper. Der Beobachter
            # erfasst dessen echtes Objekt vor dem gezielten Setupfehler.
            $commandUnderTest = Get-Variable -Name command -Scope 1 -ValueOnly
            $probeState.Command = $commandUnderTest
            $probeState.Seen = $true
            $commandUnderTest.add_Disposed({ $probeState.Disposed++ }.GetNewClosure())
            if ($kind -ceq 'ProviderThrows') { throw 'SAFE_CAST_EXPECTED_SETUP_FAILURE' }
            return -1
        }
        $caught = $false
        try {
            $unexpected = New-SafeCastCommand 'SELECT 1'
            if ($unexpected) { $unexpected.Dispose() }
        } catch {
            if ($kind -ceq 'ProviderThrows') {
                $caught = $_.Exception.Message -ceq 'SAFE_CAST_EXPECTED_SETUP_FAILURE'
            } else {
                $cursor = $_.Exception
                while ($null -ne $cursor) {
                    if ($cursor -is [ArgumentException]) { $caught = $true }
                    $cursor = $cursor.InnerException
                }
            }
        }
        if (-not $caught -or -not $probeState.Seen -or
            $probeState.Command -isnot [Data.SqlClient.SqlCommand] -or
            $probeState.Disposed -ne 1 -or $connectionDisposition.Count -ne 0 -or
            $Connection.State -ne [Data.ConnectionState]::Closed) {
            throw 'SAFE_CAST_SETUP_DISPOSAL_ORACLE'
        }
    }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $sourceHash) {
        throw 'SAFE_CAST_SETUP_SOURCE_CHANGED'
    }
    Write-Output 'PASS: Safe Cast command setup; two real SqlCommand disposal oracles, no SQL executed.'
} finally {
    $Connection.Dispose()
}
