Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'API_CAPTURE_DIAGNOSTIC_PARSE'}
foreach($name in @('Add-ApiCaptureFailureContext','New-ApiCaptureDiagnostic')){
 $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
 if($nodes.Count -ne 1){throw 'API_CAPTURE_DIAGNOSTIC_FUNCTION'}
 . ([scriptblock]::Create($nodes[0].Extent.Text))
}
$original=[IO.File]::ReadAllText((Join-Path $root 'Modules/toolbelt.string.regex/Tests/Runtime/Captures.Contract.sql'))
$annotated=Add-ApiCaptureFailureContext $original
# Alle ursprünglichen Bytes einschließlich der strikten negativen Orakel
# müssen nach Entfernen ausschließlich der Annotation wiederherstellbar sein.
$begin="DECLARE @ApiCapturePhase nvarchar(20)=N'rows';`nBEGIN TRY`n"
if(-not $annotated.StartsWith($begin,[StringComparison]::Ordinal)){throw 'API_CAPTURE_CONTEXT_BEGIN'}
$end=$annotated.LastIndexOf("`nEND TRY",[StringComparison]::Ordinal)
if($end -le $begin.Length){throw 'API_CAPTURE_CONTEXT_END'}
$restored=$annotated.Substring($begin.Length,$end-$begin.Length)
foreach($phase in @('row-oracle','replace','defaults','negative')){
 $restored=$restored.Replace("SET @ApiCapturePhase=N'$phase';`n",'')
}
if($restored -cne $original){throw 'API_CAPTURE_ORACLE_CHANGED'}
if($annotated -cnotmatch '(?s)RAISERROR\(N''TBX_REGEX_CAPTURE_CASE\|%s\|%d'',10,1,@ApiCapturePhase,@Case\) WITH NOWAIT;\s+THROW;'){
 throw 'API_CAPTURE_ORIGINAL_ERROR_NOT_RETHROWN'
}
foreach($bad in @($annotated,$original.Replace('DECLARE @Errors table','DECLARE @Changed table'))){
 $rejected=$false
 try{[void](Add-ApiCaptureFailureContext $bad)}catch{$rejected=$_.Exception.Message -cin @('RELEASE_API_CAPTURE_ALREADY_ANNOTATED','RELEASE_API_CAPTURE_FIXTURE_DRIFT')}
 if(-not $rejected){throw 'API_CAPTURE_DRIFT_ACCEPTED'}
}
# Den tatsächlich gebundenen Eventcallback in einem anderen ScriptScope
# ausführen: fremde Meldungen ignorieren, nur synthetische feste Marker halten.
$probe=New-ApiCaptureDiagnostic
$consumer=New-Module -ScriptBlock {Set-StrictMode -Version Latest}
foreach($message in @('private synthetic message','TBX_REGEX_CAPTURE_CASE|negative|27 extra','TBX_REGEX_CAPTURE_CASE|unknown|1')){
 & $consumer {param($callback,$value) & $callback $null ([pscustomobject]@{Errors=@([pscustomobject]@{Message=$value})})} $probe.Action $message
}
if($probe.State.Marker -cne ''){throw 'API_CAPTURE_UNFILTERED_MESSAGE'}
& $consumer {param($callback) & $callback $null ([pscustomobject]@{Errors=@([pscustomobject]@{Message='TBX_REGEX_CAPTURE_CASE|negative|27'})})} $probe.Action
if($probe.State.Marker -cne 'TBX_REGEX_CAPTURE_CASE|negative|27'){throw 'API_CAPTURE_CALLBACK_SCOPE_LOST'}
'PASS API_CAPTURE_DIAGNOSTIC unchanged fixture bytes/oracles, fail-closed annotation, original rethrow, scoped filtered event; no SQL'
