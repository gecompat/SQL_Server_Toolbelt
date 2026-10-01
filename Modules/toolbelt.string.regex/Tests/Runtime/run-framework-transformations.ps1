[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath)
$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 lädt die echte .NET-Framework-4.8-Assembly. Der
# Whitebox-Test qualifiziert den Restbudgetpfad ohne SQL-/Lab-Verbindung.
Add-Type -Path (Resolve-Path -LiteralPath $AssemblyPath).Path
$type = [Toolbelt.String.Regex.RegexProvider]
$nested = $type.GetNestedType('TransformationContext', [Reflection.BindingFlags]::NonPublic)
$binding = [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic
$context = [Activator]::CreateInstance($nested, $binding, $null,
    [object[]]@([Data.SqlTypes.SqlString]::new('standard')), $null)
$initialize = $nested.GetMethod('Initialize', $binding)
$search = $nested.GetMethod('Search', $binding)
$remaining = $nested.GetMethod('Remaining', $binding)
$nested.GetMethod('ValidateFlags', $binding).Invoke($context, [object[]]@([Data.SqlTypes.SqlString]::new('c'))) | Out-Null
$initialize.Invoke($context, [object[]]@('')) | Out-Null
Start-Sleep -Milliseconds 300
# Ein echtes Match im Restbudget erzwingt die kleinere Regexinstanz. Weitere
# Empty-Matches müssen dieselbe Instanz wiederverwenden können.
for ($index = 0; $index -lt 100; $index++) {
    $match = $search.Invoke($context, [object[]]@('abc', 0))
    if (-not $match.Success -or $match.Length -ne 0) { throw 'Restbudget-Empty-Match falsch.' }
}
Start-Sleep -Milliseconds 550
$caught = $false
try { $remaining.Invoke($context, @()) | Out-Null }
catch { $caught = $_.Exception.ToString().Contains('TBX_REGEX_TIMEOUT') }
if (-not $caught) { throw 'Gesamtbudget wurde nicht durchgesetzt.' }

$plain = [Data.SqlTypes.SqlString]::new('abc')
$flags = [Data.SqlTypes.SqlString]::new('c')
$profile = [Data.SqlTypes.SqlString]::new('standard')
$result = $type::RegexSubstring($plain, [Data.SqlTypes.SqlString]::new(''),
    [Data.SqlTypes.SqlInt32]::new(1), [Data.SqlTypes.SqlInt32]::new(4), $flags, $profile)
if ($result.IsNull -or $result.Value -ne '') { throw 'Empty-Match-Occurrence falsch.' }
Write-Output 'Framework R2a Restbudget/Enumeration: PASSED'
