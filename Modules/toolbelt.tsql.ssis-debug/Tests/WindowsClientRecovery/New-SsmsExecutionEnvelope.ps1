#Requires -Version 7.5
<#
.SYNOPSIS
    Bindet die unveränderte SSMS-Zellenkopie und das native Receipt für einen Lauf.
.DESCRIPTION
    SQL-freie Testinstrumentierung, keine SQL-Ausführung. Der kopierte Body wird
    ausschließlich von CRLF auf LF normalisiert. Datenbankkontext und Receipt
    stehen außerhalb dieses hashgeprüften Bodys. VerifyExisting prüft die aus
    dem tatsächlich verwendeten SSMS-Editor gespeicherte Ausführungsdatei.
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
if($hash-cne $ExpectedUtf16LfSha256){throw 'SSMS_ENVELOPE_COPY_CHANGED'}
if((Get-FileHash -LiteralPath $ReceiptPath).Hash-cne $ExpectedReceiptSha256){throw 'SSMS_ENVELOPE_RECEIPT_CHANGED'}
$receipt=[IO.File]::ReadAllText($ReceiptPath).Replace("`r`n","`n")
if(-not $receipt.StartsWith("USE [$Database];`n",[StringComparison]::Ordinal) -or
   -not $receipt.Contains('SSIS_WINDOWS_CLIENT_GUI_PASS') -or
   -not $receipt.Contains('SET Phase=2')){throw 'SSMS_ENVELOPE_RECEIPT_SCOPE'}
if(-not $copy.Contains("N'$Database'") -or -not $copy.Contains('Grüße Ω')){throw 'SSMS_ENVELOPE_COPY_SCOPE'}
# SSMS darf nach einem Bodyfehler nicht mit einem zweiten Receiptbatch fortfahren.
if([regex]::IsMatch($copy+"`n"+$receipt,'(?im)^[ \t]*GO(?:[ \t/;]|$)')){throw 'SSMS_ENVELOPE_MULTIPLE_BATCHES'}
$envelope="USE [$Database];`n"+$copy+"`n"+$receipt
$output=[IO.Path]::GetFullPath($OutputPath)
if($output-ieq [IO.Path]::GetFullPath($CopiedScriptPath) -or $output-ieq [IO.Path]::GetFullPath($ReceiptPath)){throw 'SSMS_ENVELOPE_INPUT_OVERWRITE'}
if($VerifyExisting){
 if([IO.File]::ReadAllText($output).Replace("`r`n","`n")-cne $envelope){throw 'SSMS_ENVELOPE_EXECUTED_FILE_CHANGED'}
}else{
 # CreateNew verhindert stille Wiederverwendung oder Überschreiben von Nachweisen.
 $stream=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write)
 try{$encoding=[Text.UTF8Encoding]::new($true);$bom=$encoding.GetPreamble();$stream.Write($bom);$stream.Write($encoding.GetBytes($envelope))}finally{$stream.Dispose()}
}
[ordered]@{result='PASS';scope='execution-envelope-only';copiedUtf16LfSha256=$hash;receiptSha256=$ExpectedReceiptSha256;
 envelopeUtf16LfSha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::Unicode.GetBytes($envelope)));
 copiedUtf16CodeUnits=$copy.Length;envelopeUtf16CodeUnits=$envelope.Length;verifiedExisting=[bool]$VerifyExisting}|ConvertTo-Json -Compress
