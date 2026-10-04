param([Parameter(Mandatory)][System.Data.SqlClient.SqlConnection]$Connection,[Parameter(Mandatory)][string]$ToolbeltDatabase,
 [scriptblock]$CommandTimeoutProvider,[scriptblock]$ReadBudgetProvider)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$command=$null; $reader=$null; $primaryError=$null; $success=$null; $secondaryErrors=[Collections.Generic.List[string]]::new()
try {
 if($Connection.State -ne [Data.ConnectionState]::Open -or $ToolbeltDatabase -notmatch '\A[A-Za-z][A-Za-z0-9_]{0,127}\z'){throw 'COMPOSITION_INPUT'}
 $fixture=Join-Path $PSScriptRoot 'Types.Composition.xlsx'; $sqlFile=Join-Path $PSScriptRoot 'Display.Composition.sql'
 if((Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash -cne '7B690C7C0EC6C2EEBBEA180B031C7BDAED1A6D1DC5F2D3CEC360135B8F530BC1'){throw 'COMPOSITION_FIXTURE_PIN'}
 if((Get-FileHash -LiteralPath $sqlFile -Algorithm SHA256).Hash -cne 'A44F37281DEC7D74E82DE44D62D9A6A929A47AAF9849D4458E68278713901A44'){throw 'COMPOSITION_SQL_PIN'}
 $bytes=[IO.File]::ReadAllBytes($fixture)
 $sha=[Security.Cryptography.SHA256]::Create()
 try {$snapshotHash=[BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','')}finally{$sha.Dispose()}
 if($snapshotHash -cne '7B690C7C0EC6C2EEBBEA180B031C7BDAED1A6D1DC5F2D3CEC360135B8F530BC1'){throw 'COMPOSITION_SNAPSHOT_PIN'}
 $sqlBytes=[IO.File]::ReadAllBytes($sqlFile)
 $sqlSha=[Security.Cryptography.SHA256]::Create()
 try {$sqlSnapshotHash=[BitConverter]::ToString($sqlSha.ComputeHash($sqlBytes)).Replace('-','')}finally{$sqlSha.Dispose()}
 if($sqlSnapshotHash -cne 'A44F37281DEC7D74E82DE44D62D9A6A929A47AAF9849D4458E68278713901A44'){throw 'COMPOSITION_SQL_SNAPSHOT_PIN'}
 $sql=[Text.UTF8Encoding]::new($false,$true).GetString($sqlBytes).Replace('$(ToolbeltDatabase)',$ToolbeltDatabase)
 $command=$Connection.CreateCommand(); $command.CommandTimeout=120; $command.CommandText=$sql
 $parameter=$command.Parameters.Add('@Workbook',[Data.SqlDbType]::VarBinary,-1); $parameter.Value=$bytes
 if($CommandTimeoutProvider){$command.CommandTimeout=& $CommandTimeoutProvider}
 $reader=$command.ExecuteReader(); do {if($ReadBudgetProvider){& $ReadBudgetProvider $command};while($reader.Read()) {throw 'COMPOSITION_UNEXPECTED_ROW'};if($ReadBudgetProvider){& $ReadBudgetProvider $command}}while($reader.NextResult())
 $reader.Dispose(); $reader=$null
 if((Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash -cne $snapshotHash -or (Get-FileHash -LiteralPath $sqlFile -Algorithm SHA256).Hash -cne 'A44F37281DEC7D74E82DE44D62D9A6A929A47AAF9849D4458E68278713901A44'){throw 'COMPOSITION_POST_PIN'}
 $success=[pscustomobject]@{Status='PASS';SyntheticCells=9;PublicComposition='RawCells-to-Interpret-and-FormatXlsxCell';Scope='Single existing owned database; no installation or cleanup'}
} catch {
 $primaryError=$_
} finally {
 # Beide Ressourcen schließen; der erste Fehler bleibt maßgeblich.
 try {if($null -ne $reader){$reader.Dispose()}}
 catch {if($null -eq $primaryError){$primaryError=$_}else{$secondaryErrors.Add('COMPOSITION_READER_DISPOSE_FAILED')}}
 finally {
  try {if($null -ne $command){$command.Dispose()}}
  catch {if($null -eq $primaryError){$primaryError=$_}else{$secondaryErrors.Add('COMPOSITION_COMMAND_DISPOSE_FAILED')}}
 }
}
if($null -ne $primaryError){
 $primaryError.Exception.Data['XlsxCompositionSecondaryFailures']=$secondaryErrors.ToArray()
 throw $primaryError
}
$success
