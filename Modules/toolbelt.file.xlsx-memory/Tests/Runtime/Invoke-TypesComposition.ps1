param([Parameter(Mandatory)][System.Data.SqlClient.SqlConnection]$Connection,[Parameter(Mandatory)][string]$ToolbeltDatabase)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$command=$null; $reader=$null
try {
 if($Connection.State -ne [Data.ConnectionState]::Open -or $ToolbeltDatabase -notmatch '\A[A-Za-z][A-Za-z0-9_]{0,127}\z'){throw 'COMPOSITION_INPUT'}
 $fixture=Join-Path $PSScriptRoot 'Types.Composition.xlsx'; $sqlFile=Join-Path $PSScriptRoot 'Types.Composition.sql'
 if((Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash -cne '7B690C7C0EC6C2EEBBEA180B031C7BDAED1A6D1DC5F2D3CEC360135B8F530BC1'){throw 'COMPOSITION_FIXTURE_PIN'}
 if((Get-FileHash -LiteralPath $sqlFile -Algorithm SHA256).Hash -cne '9C63E84B28B066555A20D6354F2154E8C5A830CA3372C52D40F73B02F13B923E'){throw 'COMPOSITION_SQL_PIN'}
 $bytes=[IO.File]::ReadAllBytes($fixture)
 $sha=[Security.Cryptography.SHA256]::Create()
 try {$snapshotHash=[BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','')}finally{$sha.Dispose()}
 if($snapshotHash -cne '7B690C7C0EC6C2EEBBEA180B031C7BDAED1A6D1DC5F2D3CEC360135B8F530BC1'){throw 'COMPOSITION_SNAPSHOT_PIN'}
 $sqlBytes=[IO.File]::ReadAllBytes($sqlFile)
 $sqlSha=[Security.Cryptography.SHA256]::Create()
 try {$sqlSnapshotHash=[BitConverter]::ToString($sqlSha.ComputeHash($sqlBytes)).Replace('-','')}finally{$sqlSha.Dispose()}
 if($sqlSnapshotHash -cne '9C63E84B28B066555A20D6354F2154E8C5A830CA3372C52D40F73B02F13B923E'){throw 'COMPOSITION_SQL_SNAPSHOT_PIN'}
 $sql=[Text.UTF8Encoding]::new($false,$true).GetString($sqlBytes).Replace('$(ToolbeltDatabase)',$ToolbeltDatabase)
 $command=$Connection.CreateCommand(); $command.CommandTimeout=120; $command.CommandText=$sql
 $parameter=$command.Parameters.Add('@Workbook',[Data.SqlDbType]::VarBinary,-1); $parameter.Value=$bytes
 $reader=$command.ExecuteReader(); do {while($reader.Read()) {throw 'COMPOSITION_UNEXPECTED_ROW'}}while($reader.NextResult())
 $reader.Dispose(); $reader=$null
 if((Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash -cne $snapshotHash -or (Get-FileHash -LiteralPath $sqlFile -Algorithm SHA256).Hash -cne '9C63E84B28B066555A20D6354F2154E8C5A830CA3372C52D40F73B02F13B923E'){throw 'COMPOSITION_POST_PIN'}
 [pscustomobject]@{Status='PASS';SyntheticCells=9;PublicComposition='RawCells-to-InterpretXlsxCell';Scope='Single existing owned database; no installation or cleanup'}
} catch {
 $exception=$_.Exception; $number=0; $state=0
 while($null -ne $exception){if($exception -is [Data.SqlClient.SqlException]){$number=$exception.Number; $state=$exception.State;break};$exception=$exception.InnerException}
 throw [InvalidOperationException]::new(('COMPOSITION_FAILED SQL_{0}_STATE{1}' -f $number,$state))
} finally {
 try {if($null -ne $reader){$reader.Dispose()}}
 catch {throw [InvalidOperationException]::new('COMPOSITION_READER_DISPOSE_FAILED')}
 finally {try {if($null -ne $command){$command.Dispose()}}catch {throw [InvalidOperationException]::new('COMPOSITION_COMMAND_DISPOSE_FAILED')}}
}