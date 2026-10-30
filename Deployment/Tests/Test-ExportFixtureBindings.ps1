# Offline-Intake für die tatsächlich konsumierten Exportfixtures. Keine SQLverbindung.
[CmdletBinding()]
param()
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$driver=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Invoke-ExportPopulatedRepeat.ps1'))
$fixtures=@([regex]::Matches($driver,"Name='(ExportQueue11(?:Repeat|Help)?\.[A-Za-z]+\.sql)';Hash='([A-F0-9]{64})'"))
if($fixtures.Count-ne5){throw 'EXPORT_BINDING_FIXTURE_SET'}
foreach($fixture in $fixtures){
 $actual=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot ('Runtime/'+$fixture.Groups[1].Value)) -Algorithm SHA256).Hash
 if($actual-cne$fixture.Groups[2].Value){throw 'EXPORT_BINDING_FIXTURE_BYTES'}
}
$helperPins=@([regex]::Matches($driver,"Hash-ceq'([A-F0-9]{64})'\) 'HISTORICAL_CAPTURE_HELPER'"))
$helper=(Get-FileHash -LiteralPath (Join-Path $repo 'Workers/ExternalQueue/Tests/Runtime/New-GenuineQueue20Capture.ps1') -Algorithm SHA256).Hash
if($helperPins.Count-ne2){throw 'EXPORT_BINDING_HELPER_SET'}
foreach($pin in $helperPins){if($pin.Groups[1].Value-cne$helper){throw 'EXPORT_BINDING_HELPER_BYTES'}}
$assert=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Runtime/ExportQueue11.Assert.sql'))
$start=$assert.IndexOf('CREATE TABLE #ExpectedDefinitions',[StringComparison]::Ordinal)
$end=$assert.IndexOf('IF (SELECT COUNT(*) FROM #ExpectedDefinitions',$start,[StringComparison]::Ordinal)
$definitions=@([regex]::Matches($assert.Substring($start,$end-$start),"\(1,N'([^']+)',0x([A-F0-9]{64})\)"))
if($definitions.Count-ne8){throw 'EXPORT_BINDING_DEFINITION_SET'}
. (Join-Path $repo 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1')
$python=Get-Command python -ErrorAction Stop
$projection=Invoke-OwnedProcess -FileName $python.Source -Arguments @((Join-Path $PSScriptRoot 'export_parameter_help_definition_pins.py'),'--check-current') -TimeoutMilliseconds 30000
if($projection.ExitCode-ne0){throw 'EXPORT_BINDING_HELP_PROJECTION'}
$historicalPins=$projection.Stdout|ConvertFrom-Json -AsHashtable
if($historicalPins.Count-ne8){throw 'EXPORT_BINDING_HELP_PROJECTION_SET'}
foreach($definition in $definitions){
 $name=$definition.Groups[1].Value
 $text=[IO.File]::ReadAllText((Join-Path $repo ('Modules/toolbelt.core.work-queue/Source/'+$name+'.sql'))).Replace("`r`n","`n")
 $identifier='[toolbelt_core].['+$name+']'
 $batches=@([regex]::Split($text,'(?im)^\s*GO\s*$')|Where-Object {$_-match('(?i)CREATE OR ALTER (?:PROCEDURE|VIEW)\s+'+[regex]::Escape($identifier))})
 if($batches.Count-ne1){throw 'EXPORT_BINDING_DEFINITION_BATCH'}
 $body=$batches[0].Substring($batches[0].IndexOf($identifier,[StringComparison]::Ordinal)).Trim([char[]]" `t`r`n")
 $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::Unicode.GetBytes($body)))
 # The frozen fixture asserts its executed predecessor definition. Only the
 # canonical Help branch may differ in current source; business drift is rejected.
 if($hash-cne$definition.Groups[2].Value -and $historicalPins[$name]-cne$definition.Groups[2].Value){throw 'EXPORT_BINDING_DEFINITION_BYTES'}
}
# Jeder deklarierte aktuelle Tabellen-Shape benötigt auch einen eigenen Count-
# Zeugen; sonst würde ein leerer neuer Policybestand still aus dem Snapshot fallen.
foreach($binding in @(@{Name='ExportUpgradeRepeat.Capture.sql';Prefix='Upgrade'},@{Name='ExportQueue11Repeat.Capture.sql';Prefix='Queue11'})){
 $text=[IO.File]::ReadAllText((Join-Path $PSScriptRoot ('Runtime/'+$binding.Name)))
 $marker='INSERT #tbx_'+$binding.Prefix+'RepeatCounts VALUES'
 $begin=$text.IndexOf($marker,[StringComparison]::Ordinal)
 $end=$text.IndexOf(';',$begin)
 $counts=@([regex]::Matches($text.Substring($begin,$end-$begin),"\(N'toolbelt_(?:core|file)',N'([^']+)',[0-9]+\)"))
 $fieldPattern="\(N'toolbelt_(?:core|file)',N'([^']+)',[0-9]+,N'[^']+'\)"
 $fields=@([regex]::Matches($text,$fieldPattern))
 $countNames=@($counts|ForEach-Object {$_.Groups[1].Value}|Sort-Object -Unique)
 $fieldNames=@($fields|ForEach-Object {$_.Groups[1].Value}|Sort-Object -Unique)
 if($counts.Count-ne15-or$fields.Count-ne166-or($countNames-join ',')-cne($fieldNames-join ',')){throw 'EXPORT_BINDING_REPEAT_WITNESS_CLOSURE'}
}
$current=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Runtime/ExportQueue11Repeat.Capture.sql'))
$start=$current.IndexOf('INSERT #tbx_Queue11RepeatObjects VALUES',[StringComparison]::Ordinal)
$end=$current.IndexOf(';',$start)
$objects=@([regex]::Matches($current.Substring($start,$end-$start),"\(N'toolbelt_(?:core|file)',N'([^']+)','([A-Z]+)'\)"))
$names=@($objects|ForEach-Object {$_.Groups[1].Value}|Sort-Object -Unique)
if($objects.Count-ne83-or$names.Count-ne83){throw 'EXPORT_BINDING_CURRENT_OBJECT_CLOSURE'}
foreach($name in @('WorkTypePermission','TVF_WorkTypeAuthorization','USP_SetWorkTypePermission','USP_DeleteRecordedEventsBefore')){
 if($names-cnotcontains$name){throw 'EXPORT_BINDING_SECURITY_OBJECT_MISSING'}
}
Write-Output 'EXPORT_FIXTURE_BINDINGS_PASS files=6 declarations=8 no-sql'
