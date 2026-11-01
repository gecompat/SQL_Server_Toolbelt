#Requires -Version 7.5
<#
.SYNOPSIS
    Prüft eine gespeicherte SSMS-Zellenkopie vor deren manueller Ausführung.
.DESCRIPTION
    SQL-freie Testhilfe. Der erwartete Hash muss vom zuletzt erzeugten
    Serverartefakt stammen. Ausschließlich CRLF wird zu LF normalisiert;
    Unicode, Leerzeichen und abschließende Zeilenumbrüche bleiben erhalten.
    Ein PASS bestätigt Dateitransport, keine Anmeldung oder SQL-Ausführung.
#>
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$CopiedScriptPath,
 [Parameter(Mandatory)][ValidatePattern('^[A-F0-9]{64}$')][string]$ExpectedUtf16LfSha256
)
$ErrorActionPreference='Stop'
$copy=[IO.File]::ReadAllText([IO.Path]::GetFullPath($CopiedScriptPath)).Replace("`r`n","`n")
$hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::Unicode.GetBytes($copy)))
if($hash-cne $ExpectedUtf16LfSha256){throw 'SSMS_SCRIPT_COPY_HASH_MISMATCH'}
[ordered]@{result='PASS';scope='saved-copy-only';utf16CodeUnits=$copy.Length;utf16LfSha256=$hash}|ConvertTo-Json -Compress
