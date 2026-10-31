# Ergänzende native API-, Daten-/Sicherheits- und Grenzorakel. Alle Mutationen
# betreffen ausschließlich die äußere, journalisierte eigene Testdatenbank.
$bytes=[IO.File]::ReadAllBytes((Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
$api=Get-Content (Join-Path $moduleRoot 'Contracts/Api.json') -Raw|ConvertFrom-Json
foreach($limit in @(($bytes.Length-1),$bytes.Length,($bytes.Length+1))){
 if($limit -lt $bytes.Length){Reject-V2 {Invoke-V2Explain -Bytes $bytes -Limits @{'@MaxPackageBytes'=$limit}} 'resource_limit' 'packageBytes'}
 else{Assert-V2 ((Invoke-V2Explain -Bytes $bytes -Limits @{'@MaxPackageBytes'=$limit}).Rows.Count -eq 1) 'PACKAGE_EXACT_AND_ABOVE'}
}
foreach($entry in @(@{name='@MaxXmlCharacters';counter='xmlCharacters'},@{name='@MaxXmlNodes';counter='xmlNodes'},@{name='@MaxComponents';counter='components'},@{name='@MaxInputs';counter='inputs'},@{name='@MaxPaths';counter='paths'},@{name='@MaxColumns';counter='columns'},@{name='@MaxModelNodes';counter='modelNodes'},@{name='@MaxModelEdges';counter='modelEdges'})){
 $limits=@{};$limits[$entry.name]=1
 Reject-V2 {Invoke-V2Explain -Bytes $bytes -Limits $limits} 'resource_limit' $entry.counter
}
Reject-V2 {Invoke-V2Explain -Bytes $bytes -Limits @{'@MaxTotalOutputBytes'=32}} 'resource_limit'
Reject-V2 {Invoke-V2Explain -Bytes ([Text.Encoding]::UTF8.GetBytes('<!DOCTYPE x SYSTEM "file:///synthetic.dtd"><x/>'))} 'unsupported_package_format'
Reject-V2 {Invoke-V2Explain -Bytes $bytes -Context '{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"preset":"unlimited"}}'} 'invalid_template'
$template=Invoke-V2Explain -Bytes $bytes
$binding=[string]$template.Rows[0].Content
$bindingBytes=[long]$binding.Length*2
foreach($limit in @(($bindingBytes-1),$bindingBytes,($bindingBytes+1))){
 if($limit -lt $bindingBytes){Reject-V2 {Invoke-V2Explain -Bytes $bytes -Operation 'explain' -Bindings $binding -Limits @{'@MaxJsonDocumentBytes'=$limit}} 'resource_limit' 'jsonDocumentBytes'}
 else{Assert-V2 ((Invoke-V2Explain -Bytes $bytes -Operation 'explain' -Bindings $binding -Limits @{'@MaxJsonDocumentBytes'=$limit}).Rows.Count -gt 0) 'JSON_DOCUMENT_EXACT_AND_ABOVE'}
}
foreach($name in @('@MaxAllJsonBytes','@MaxJsonNodes')){
 $limits=@{};$limits[$name]=1
 Reject-V2 {Invoke-V2Explain -Bytes $bytes -Operation 'explain' -Bindings $binding -Limits $limits} 'resource_limit'
}
foreach($bad in @('{invalid',$binding.Replace('"schemaVersion":2','"schemaVersion":3'))){
 if($bad -cne $binding){Reject-V2 {Invoke-V2Explain -Bytes $bytes -Operation 'explain' -Bindings $bad} 'invalid_template'}
}
$messages=[Collections.Generic.List[string]]::new()
$handler=[Data.SqlClient.SqlInfoMessageEventHandler]{param($sender,$eventArgs)foreach($e in $eventArgs.Errors){$messages.Add($e.Message)}}
$Connection.add_InfoMessage($handler)
try{
 $debug=Invoke-V2Explain -Bytes $bytes -Debug 1
 Assert-V2 ($debug.Columns.Count -eq 13 -and $messages.Count -gt 0) 'DEBUG_MESSAGES_ONLY'
}finally{$Connection.remove_InfoMessage($handler)}
foreach($keep in @($false,$true)){
 Assert-V2 ((Invoke-V2Explain -Bytes $bytes -Keep $keep).Rows.Count -eq 1) 'KEEP_WITHOUT_RESULTTABLE'
}
[void](Invoke-V2Sql 'CREATE TABLE #CurrentQualificationResult(AnyName decimal(9,2));')
try{
 [void](Invoke-V2Explain -Bytes $bytes -ResultTable '#CurrentQualificationResult')
 [void](Invoke-V2Sql 'CREATE INDEX IX_CurrentQualification ON #CurrentQualificationResult(Ordinal);')
 [void](Invoke-V2Explain -Bytes $bytes -ResultTable '#CurrentQualificationResult' -Keep $true)
 Assert-V2 ((Invoke-V2Sql 'SELECT COUNT_BIG(*) AS N FROM #CurrentQualificationResult;').Rows[0].N -eq 2) 'KEEP_APPEND_WITH_INDEX'
 [void](Invoke-V2Explain -Bytes $bytes -ResultTable '#CurrentQualificationResult' -Keep $false)
 Assert-V2 ((Invoke-V2Sql 'SELECT COUNT_BIG(*) AS N FROM #CurrentQualificationResult;').Rows[0].N -eq 1) 'KEEP_REPLACE_WITH_INDEX'
 Reject-V2 {Invoke-V2Explain -Bytes $bytes -Bindings '{invalid' -Operation 'explain' -ResultTable '#CurrentQualificationResult'} 'invalid_template'
 Assert-V2 ((Invoke-V2Sql 'SELECT COUNT_BIG(*) AS N FROM #CurrentQualificationResult;').Rows[0].N -eq 1) 'FAILED_OUTPUT_UNCHANGED'
}finally{[void](Invoke-V2Sql 'DROP TABLE #CurrentQualificationResult;')}
$before=Invoke-V2Sql 'SELECT @@OPTIONS AS O,@@TRANCOUNT AS T,XACT_STATE() AS S;'
[void](Invoke-V2Sql 'BEGIN TRANSACTION;')
try{
 $in=Invoke-V2Sql 'SELECT @@OPTIONS AS O,@@TRANCOUNT AS T,XACT_STATE() AS S;'
 [void](Invoke-V2Explain -Bytes $bytes)
 $after=Invoke-V2Sql 'SELECT @@OPTIONS AS O,@@TRANCOUNT AS T,XACT_STATE() AS S;'
 Assert-V2 ($in.Rows[0].O -eq $after.Rows[0].O -and $in.Rows[0].T -eq $after.Rows[0].T -and $after.Rows[0].S -eq 1) 'CALLER_TRANSACTION_OPTIONS'
}finally{[void](Invoke-V2Sql 'IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;')}
$after=Invoke-V2Sql 'SELECT @@OPTIONS AS O,@@TRANCOUNT AS T,XACT_STATE() AS S;'
Assert-V2 ($before.Rows[0].O -eq $after.Rows[0].O -and $before.Rows[0].T -eq $after.Rows[0].T -and $before.Rows[0].S -eq $after.Rows[0].S) 'SESSION_RESTORED'
