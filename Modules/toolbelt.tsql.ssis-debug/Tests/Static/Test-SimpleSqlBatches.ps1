param([Parameter(Mandatory)][string]$ScriptDomDllPath)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot '../Runtime/SimpleSqlBatches.ps1')
$text="SELECT N'one`nGO`ntwo' AS Value;`nGO`n-- GO is a comment`nSELECT 2;"
$batches=@(Get-SimpleSqlBatches $text $ScriptDomDllPath)
if($batches.Count -ne 2 -or -not $batches[0].Contains("GO`ntwo")){throw 'SIMPLE_BATCH_CONTROL_FAILED'}
$rejected=$false
try{[void]@(Get-SimpleSqlBatches 'SELECT FROM;' $ScriptDomDllPath)}catch{
    if($_.Exception.Message -cne 'SIMPLE_BATCH_INVALID_SQL'){throw};$rejected=$true
}
if(-not $rejected){throw 'SIMPLE_BATCH_INVALID_ACCEPTED'}
'SIMPLE_BATCH_CONTROL_PASS no SQL executed'
