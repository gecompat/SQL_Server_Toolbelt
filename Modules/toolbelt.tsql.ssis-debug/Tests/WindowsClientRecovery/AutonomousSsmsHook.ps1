# Historische Methoden bleiben unverändert; dieser Test bindet nur den neuen Ablauf.
$prior=Join-Path $PSScriptRoot 'SsmsGuiHook.ps1'
if((Get-FileHash $prior).Hash-cne '96733D52B24895B378112AD1601FCD86D55C7AEECE7BA5D81FFA14A920AF2824'){throw 'AUTONOMOUS_SSMS_PRIOR_HOOK_CHANGED'}
. $prior
# Keine automatisch geöffnete Query-Datei. SSMS22 bestätigt auch -S separat;
# dies ist kein dialogfreier Anmeldeweg. Ein blockierter Vorcheck legt keine DB an.
# Explizites Ziel/master, vorhandene Windowsidentität und TLS-Vertrag bleiben.
$preflight=(Get-Command Invoke-SsmsTargetPreflight).Definition
$preflight=Replace-SsmsHookOnce $preflight "@(`$path,'-S'" "@('-S'"
. ([scriptblock]::Create('function Invoke-SsmsTargetPreflight {'+$preflight+'}'))
$gui=(Get-Command Invoke-ClientGui).Definition
$gui=Replace-SsmsHookOnce $gui ' [IO.File]::WriteAllText($completePath,$complete,[Text.UTF8Encoding]::new($true))' @'
 [IO.File]::WriteAllText($completePath,$complete,[Text.UTF8Encoding]::new($true))
 $completeSha256=(Get-FileHash $completePath).Hash
'@
$gui=Replace-SsmsHookOnce $gui "   `$visual=Get-Content (`$JournalPath+'.visual.json')" @'
   $envelope=& (Join-Path $PSScriptRoot 'New-SsmsExecutionEnvelope.ps1') -CopiedScriptPath ($JournalPath+'.02-Copied-DebugScript.sql') -ExpectedUtf16LfSha256 ([string]$r.Rows[0].H) -ReceiptPath $completePath -ExpectedReceiptSha256 $completeSha256 -Database $db -OutputPath ($JournalPath+'.05-ExecutedEnvelope.sql') -VerifyExisting | ConvertFrom-Json
   Check ($envelope.result-ceq 'PASS' -and $envelope.verifiedExisting) 'EXECUTION_ENVELOPE_PRESERVES_COMPLETE_COPY_AND_RECEIPT'
   Save-ClientPrivate ($JournalPath+'.envelope-binding.json') $envelope
   $visual=Get-Content ($JournalPath+'.visual.json')
'@
# Die Definition wird im nativen Dot-Scope ausgeführt, nicht über einen GUI-Helfer.
$gui=$gui.Replace('$PSScriptRoot',("'"+$PSScriptRoot.Replace("'","''")+"'"))
. ([scriptblock]::Create('function Invoke-ClientGui {'+$gui+'}'))
