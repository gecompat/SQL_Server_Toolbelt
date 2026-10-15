# Offline-Intake für die tatsächlich konsumierten Exportfixtures. Keine SQLverbindung.
[CmdletBinding()]
param()
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$driver=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Invoke-ExportPopulatedRepeat.ps1'))
$fixtures=@([regex]::Matches($driver,"Name='(ExportQueue11(?:Repeat)?\.[A-Za-z]+\.sql)';Hash='([A-F0-9]{64})'"))
if($fixtures.Count-ne4){throw 'EXPORT_BINDING_FIXTURE_SET'}
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
foreach($definition in $definitions){
 $name=$definition.Groups[1].Value
 $text=[IO.File]::ReadAllText((Join-Path $repo ('Modules/toolbelt.core.work-queue/Source/'+$name+'.sql'))).Replace("`r`n","`n")
 $identifier='[toolbelt_core].['+$name+']'
 $batches=@([regex]::Split($text,'(?im)^\s*GO\s*$')|Where-Object {$_-match('(?i)CREATE OR ALTER (?:PROCEDURE|VIEW)\s+'+[regex]::Escape($identifier))})
 if($batches.Count-ne1){throw 'EXPORT_BINDING_DEFINITION_BATCH'}
 $body=$batches[0].Substring($batches[0].IndexOf($identifier,[StringComparison]::Ordinal)).Trim([char[]]" `t`r`n")
 $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::Unicode.GetBytes($body)))
 if($hash-cne$definition.Groups[2].Value){throw 'EXPORT_BINDING_DEFINITION_BYTES'}
}
Write-Output 'EXPORT_FIXTURE_BINDINGS_PASS files=5 declarations=8 no-sql'
