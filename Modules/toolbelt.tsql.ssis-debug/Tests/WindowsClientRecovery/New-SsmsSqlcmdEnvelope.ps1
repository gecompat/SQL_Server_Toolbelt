#Requires -Version 7.5
<#
.SYNOPSIS
    Bindet einen vollständigen mehrbatchigen DebugScript-Body an sein Receipt.
.DESCRIPTION
    SQL-freie Testhilfe für eine eigene SSMS-Abfrage im SQLCMD-Modus.
    :ON ERROR EXIT beendet die Verarbeitung vor späteren Batches und Receipt,
    falls ein SQL-Fehler auftritt. Reguläre GO-Trenner bleiben im Body erhalten.
    Eingebettete SQLCMD-Direktiven, Shellkommandos und Variablensubstitution
    werden vor jeder Dateianlage verweigert. Kein SQL wird hier ausgeführt.
#>
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$CopiedScriptPath,
 [Parameter(Mandatory)][ValidatePattern('^[A-F0-9]{64}$')][string]$ExpectedUtf16LfSha256,
 [Parameter(Mandatory)][string]$ReceiptPath,
 [Parameter(Mandatory)][ValidatePattern('^[A-F0-9]{64}$')][string]$ExpectedReceiptSha256,
 [Parameter(Mandatory)][ValidatePattern('^ContosoSsisRecovery_[a-f0-9]{32}$')][string]$Database,
 [Parameter(Mandatory)][string]$OutputPath,
 [switch]$VerifyExisting
)
$ErrorActionPreference='Stop'
$copy=[IO.File]::ReadAllText($CopiedScriptPath).Replace("`r`n","`n")
$hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::Unicode.GetBytes($copy)))
if($hash-cne $ExpectedUtf16LfSha256){throw 'SSMS_SQLCMD_COPY_CHANGED'}
if((Get-FileHash -LiteralPath $ReceiptPath).Hash-cne $ExpectedReceiptSha256){throw 'SSMS_SQLCMD_RECEIPT_CHANGED'}
$receipt=[IO.File]::ReadAllText($ReceiptPath).Replace("`r`n","`n")
if(-not $receipt.StartsWith("USE [$Database];`n",[StringComparison]::Ordinal) -or
   -not $receipt.Contains('SSIS_WINDOWS_CLIENT_GUI_PASS') -or
   -not $receipt.Contains('SET Phase=2')){throw 'SSMS_SQLCMD_RECEIPT_SCOPE'}
if(-not $copy.Contains("N'$Database'") -or -not $copy.Contains('Grüße Ω')){throw 'SSMS_SQLCMD_COPY_SCOPE'}
foreach($text in @($copy,$receipt)){
 if([regex]::IsMatch($text,'(?im)^[ \t]*(?::|!!)') -or $text.Contains('$(')){throw 'SSMS_SQLCMD_EMBEDDED_CLIENT_COMMAND'}
}
$envelope=":ON ERROR EXIT`nUSE [$Database];`nGO`n"+$copy+"`nGO`n"+$receipt+"`nGO`n"
$output=[IO.Path]::GetFullPath($OutputPath)
if($output-ieq [IO.Path]::GetFullPath($CopiedScriptPath) -or $output-ieq [IO.Path]::GetFullPath($ReceiptPath)){throw 'SSMS_SQLCMD_INPUT_OVERWRITE'}
if($VerifyExisting){
 if([IO.File]::ReadAllText($output).Replace("`r`n","`n")-cne $envelope){throw 'SSMS_SQLCMD_EXECUTED_FILE_CHANGED'}
}else{
 $stream=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write)
 try{$encoding=[Text.UTF8Encoding]::new($true);$stream.Write($encoding.GetPreamble());$stream.Write($encoding.GetBytes($envelope))}finally{$stream.Dispose()}
}
[ordered]@{result='PASS';scope='sqlcmd-execution-envelope-only';copiedUtf16LfSha256=$hash;receiptSha256=$ExpectedReceiptSha256;
 envelopeUtf16LfSha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::Unicode.GetBytes($envelope)));
 copiedUtf16CodeUnits=$copy.Length;envelopeUtf16CodeUnits=$envelope.Length;verifiedExisting=[bool]$VerifyExisting;
 sqlcmdModeRequired=$true;onError='EXIT'}|ConvertTo-Json -Compress
