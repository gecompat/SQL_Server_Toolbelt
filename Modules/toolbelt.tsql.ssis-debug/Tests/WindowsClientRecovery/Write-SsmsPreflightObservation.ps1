#Requires -Version 7.5
<#
Speichert die vom Operator kopierte SSMS-Ergebniszeile. Der Koordinator prüft
denselben Nachweis mit der beim Start ermittelten Bindung. Kein SQL- oder
GUI-Zugriff. Die Zeile ist eine Bedienerbeobachtung, kein eigener SQL-Nachweis.
#>
[CmdletBinding(DefaultParameterSetName='Record')]
param(
    [Parameter(Mandatory)][string]$ReadyPath,
    [Parameter(Mandatory, ParameterSetName='Record')][string]$ObservedRow,
    [Parameter(Mandatory, ParameterSetName='Verify')][switch]$Verify,
    [Parameter(Mandatory, ParameterSetName='Verify')][ValidatePattern('^[A-F0-9]{64}$')][string]$ExpectedReadySha256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$runtime = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../.runtime'))
$readyFile = [IO.Path]::GetFullPath($ReadyPath)
$readySuffix = '.preflight-ready.json'
if (-not $readyFile.StartsWith($runtime + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
    -not $readyFile.EndsWith($readySuffix, [StringComparison]::Ordinal)) {
    throw 'SSMS_PREFLIGHT_PRIVATE_READY_PATH_REQUIRED'
}
$prefix = $readyFile.Substring(0, $readyFile.Length - $readySuffix.Length)
$queryFile = $prefix + '.00-Lab-Login.sql'
$visualFile = $prefix + '.preflight-visual.json'

$readyBytes = [IO.File]::ReadAllBytes($readyFile)
$readySha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($readyBytes))
if ($Verify -and $readySha256 -cne $ExpectedReadySha256) {
    throw 'SSMS_PREFLIGHT_READY_CHANGED'
}
$ready = [Text.Encoding]::UTF8.GetString($readyBytes) | ConvertFrom-Json -AsHashtable -DateKind String
if ($ready.contract -cne 'ssis-ssms-preflight-ready/1' -or $ready.state -cne 'SSMS_TARGET_PREFLIGHT' -or
    $ready.expectedPatch -cne 'CU8' -or $ready.sqlPath -cne $queryFile -or $ready.visualPath -cne $visualFile -or
    $ready.observationId -cnotmatch '^[a-f0-9]{32}$' -or
    $ready.querySha256 -cnotmatch '^[A-F0-9]{64}$' -or $ready.ssmsPid -isnot [long] -or
    $ready.ssmsPid -le 0 -or $ready.ssmsPid -gt [int]::MaxValue) {
    throw 'SSMS_PREFLIGHT_READY_INVALID'
}
$deadline = [datetimeoffset]::ParseExact($ready.deadlineUtc, 'o', [Globalization.CultureInfo]::InvariantCulture)
if ([datetimeoffset]::UtcNow -ge $deadline) { throw 'SSMS_PREFLIGHT_OBSERVATION_EXPIRED' }
if ((Get-FileHash -LiteralPath $queryFile).Hash -cne $ready.querySha256) {
    throw 'SSMS_PREFLIGHT_QUERY_CHANGED'
}
$app = Get-Process -Id ([int]$ready.ssmsPid) -ErrorAction SilentlyContinue
if (-not $app -or $app.HasExited -or $app.StartTime.ToUniversalTime().ToString('o') -cne $ready.ssmsStartedUtc) {
    throw 'SSMS_PREFLIGHT_PROCESS_CHANGED'
}

if ($Verify) {
    $proof = Get-Content -LiteralPath $visualFile -Raw | ConvertFrom-Json -AsHashtable -DateKind String
    if ($proof.contract -cne 'ssis-ssms-preflight-observation/1' -or $proof.readySha256 -cne $readySha256 -or
        $proof.querySha256 -cne $ready.querySha256 -or $proof.ssmsPid -isnot [long] -or
        $proof.ssmsPid -ne $ready.ssmsPid -or $proof.ssmsStartedUtc -cne $ready.ssmsStartedUtc) {
        throw 'SSMS_PREFLIGHT_OBSERVATION_BINDING'
    }
    $row = $proof.row
} else {
    $row = $ObservedRow.TrimEnd([char[]]"`r`n")
}
if ($row -isnot [string] -or $row -match '[\r\n]') { throw 'SSMS_PREFLIGHT_OBSERVATION_ROW' }
$columns = $row.Split("`t")
if ($columns.Length -ne 4 -or $columns[0] -cne 'SSMS_LAB_WINDOWS_PREFLIGHT_PASS' -or
    $columns[1] -cnotin @('NTLM', 'KERBEROS') -or $columns[2] -cne $ready.expectedPatch -or
    $columns[3] -cne $ready.observationId) {
    throw 'SSMS_PREFLIGHT_OBSERVATION_ROW'
}
if ([datetimeoffset]::UtcNow -ge $deadline -or $app.HasExited) { throw 'SSMS_PREFLIGHT_OBSERVATION_EXPIRED' }
if ($Verify) {
    [pscustomobject]@{result='PASS'; authScheme=$columns[1]; patch=$columns[2]}
    return
}

$proof = @{
    contract = 'ssis-ssms-preflight-observation/1'
    readySha256 = $readySha256
    querySha256 = $ready.querySha256
    ssmsPid = $ready.ssmsPid
    ssmsStartedUtc = $ready.ssmsStartedUtc
    row = $row
}
$temp = $visualFile + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
try {
    [IO.File]::WriteAllText($temp, ($proof | ConvertTo-Json -Compress))
    if ([datetimeoffset]::UtcNow -ge $deadline -or $app.HasExited) { throw 'SSMS_PREFLIGHT_OBSERVATION_EXPIRED' }
    [IO.File]::Move($temp, $visualFile)
} finally {
    [IO.File]::Delete($temp)
}
'SSMS_PREFLIGHT_OBSERVATION_RECORDED'
