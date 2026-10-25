Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'GeoContract.Execution.ps1')
class GeoFakeCommand {
 [int]$CommandTimeout
 [string]$CommandText
 [bool]$Disposed=$false
 [bool]$Fail=$false
 [int]ExecuteNonQuery(){if($this.Fail){throw 'SYNTHETIC_GEO_SQL_FAILURE'};return 0}
 [void]Dispose(){$this.Disposed=$true}
}
class GeoFakeConnection {
 [Collections.Generic.List[GeoFakeCommand]]$Commands=[Collections.Generic.List[GeoFakeCommand]]::new()
 [bool]$Fail=$false
 [GeoFakeCommand]CreateCommand(){
  $command=[GeoFakeCommand]::new();$command.Fail=$this.Fail;$this.Commands.Add($command);return $command
 }
}
$connection=[GeoFakeConnection]::new()
$script:clock=[pscustomobject]@{ElapsedMilliseconds=0}
Invoke-GeoCanonicalBatches $connection "SELECT 1;`nGO`nSELECT 2;"|Out-Null
if($connection.Commands.Count -ne 2 -or @($connection.Commands|Where-Object {$_.CommandTimeout -ne 120 -or -not $_.Disposed}).Count){throw 'GEO_CANONICAL_120_OR_DISPOSE'}
$script:clock.ElapsedMilliseconds=239000
Invoke-GeoCanonicalBatches $connection 'SELECT 3;'|Out-Null
if($connection.Commands[2].CommandTimeout -ne 61){throw 'GEO_REMAINING_WORK_CAP'}
$script:clock.ElapsedMilliseconds=299000
Invoke-GeoCanonicalBatches $connection 'SELECT 4;'|Out-Null
if($connection.Commands[3].CommandTimeout -ne 1){throw 'GEO_LAST_SECOND_CAP'}
$script:clock.ElapsedMilliseconds=299001
try{Invoke-GeoCanonicalBatches $connection 'SELECT 5;'|Out-Null;throw 'GEO_DEADLINE_NOT_REJECTED'}
catch{if($_.Exception.Message -cne 'RELEASE_DEADLINE'){throw}}
if($connection.Commands.Count -ne 4){throw 'GEO_COMMAND_AFTER_DEADLINE'}
$script:clock.ElapsedMilliseconds=0;$connection.Fail=$true
try{Invoke-GeoCanonicalBatches $connection 'SELECT 6;'|Out-Null;throw 'GEO_ERROR_NOT_PROPAGATED'}
catch{if($_.Exception.Message -notmatch 'SYNTHETIC_GEO_SQL_FAILURE'){throw}}
if(-not $connection.Commands[4].Disposed){throw 'GEO_ERROR_DISPOSE'}
Write-Output 'PASS canonical Geo120s, remaining300s clamp, deadline before command, exception propagation and disposal; no SQL connection'
