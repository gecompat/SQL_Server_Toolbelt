[CmdletBinding()]
param(
 [Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,
 [Parameter(Mandatory)][string]$ModuleDatabase,
 [Parameter(Mandatory)][byte[]]$PackageBytes,
 [Parameter(Mandatory)][string]$Catalog,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
 [Parameter(Mandatory)][string]$JournalDirectory,
 [ValidateRange(1,180)][int]$WaitSeconds=180
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$consumer=$Connection.Database
$token=[guid]::NewGuid().ToString('N')
$receipt='SyntheticGuiAccess_'+$token
[void](Query $Connection ('CREATE TABLE dbo.['+$receipt+'](Token char(32) NOT NULL,Completed bit NOT NULL,ApplicationName nvarchar(128) NULL,AuthScheme nvarchar(40) NULL);INSERT dbo.['+$receipt+"](Token,Completed) VALUES('"+$token+"',0);"))
function Literal-Gui([string]$Value){return "N'"+$Value.Replace("'","''")+"'"}
$header='USE ['+$consumer+"];`n"
$header+='DECLARE @ModuleDatabase sysname='+(Literal-Gui $ModuleDatabase)+",@ConsumerDatabase sysname="+(Literal-Gui $consumer)+",@Catalog nvarchar(max)="+(Literal-Gui $Catalog)+",@PackageBytes varbinary(max)=0x"+[Convert]::ToHexString($PackageBytes)+",@ExpectedAssembly varbinary(max)=0x"+$QualifiedProviderSha512+";`n"
$help='EXEC ['+$ModuleDatabase+"].toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;`n"
$analysis=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'CurrentWindowsAccess.sql'))
# Die SQL-Analyse ist auch für die getrennte SQL-Anmelde-GUIprobe zulässig;
# ausschließlich ihr Windows-Auth-Guard wird entfernt, kein Funktionsorakel.
$authGuard="IF CONVERT(nvarchar(40),CONNECTIONPROPERTY('auth_scheme')) NOT IN(N'NTLM',N'KERBEROS')`n    THROW 51000,N'SSIS_WINDOWS_AUTHENTICATION_REQUIRED',1;"
$analysis=$analysis.Replace("`r`n","`n")
if(($analysis.Split($authGuard).Count-1) -ne 1){throw 'SSIS_GUI_AUTH_GUARD_ANCHOR'}
$analysis=$analysis.Replace($authGuard,'-- GUI-Anmeldung separat über CONNECTIONPROPERTY im Receipt gemessen.')
$debug=[IO.File]::ReadAllText((Join-Path $JournalDirectory 'windows-debug-0.sql'))
$footer="`nGO`nIF DB_NAME()<>"+(Literal-Gui $consumer)+" THROW 51000,N'SSIS_GUI_DATABASE_CHANGED',1;`n"
$footer+="IF APP_NAME() NOT LIKE N'Microsoft SQL Server Management Studio%' THROW 51000,N'SSIS_GUI_APPLICATION_REQUIRED',1;`n"
$footer+='UPDATE dbo.['+$receipt+"] SET Completed=1,ApplicationName=APP_NAME(),AuthScheme=CONVERT(nvarchar(40),CONNECTIONPROPERTY('auth_scheme')) WHERE Token='"+$token+"';`nDROP TABLE #SyntheticGuiAnalysisPass;`nUSE master;`nSELECT N'SSIS_GUI_ACCESS_PASS' AS Result,N'Grüße Ω' AS UnicodeWitness;`n"
$path=Join-Path $JournalDirectory 'gui-walkthrough.sql'
$analysis+="`nCREATE TABLE #SyntheticGuiAnalysisPass(Ok bit NOT NULL);INSERT #SyntheticGuiAnalysisPass VALUES(1);`n"
$footer=$footer.Replace('UPDATE dbo.',"IF OBJECT_ID(N'tempdb..#SyntheticGuiAnalysisPass',N'U') IS NULL THROW 51000,N'SSIS_GUI_ANALYSIS_FAILED',1;`nUPDATE dbo.")
[IO.File]::WriteAllText($path,$header+$help+$analysis+"`nGO`n"+$debug+$footer,[Text.UTF8Encoding]::new($false))
@{schemaVersion=1;state='READY';scriptPath=$path;scriptSha256=(Get-FileHash $path).Hash;deadlineSeconds=$WaitSeconds}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $JournalDirectory 'gui-ready.json') -Encoding utf8
$clock=[Diagnostics.Stopwatch]::StartNew();$passed=$false;$completionRecorded=$false
try{
 while($clock.Elapsed.TotalSeconds -lt $WaitSeconds){
  [void](Get-SsisNativeTimeout 15)
  $row=Query $Connection ('SELECT Completed,ApplicationName,AuthScheme FROM dbo.['+$receipt+"] WHERE Token='"+$token+"';")
  $sqlComplete=$row.Rows.Count -eq 1 -and $row.Rows[0].Completed -and $row.Rows[0].ApplicationName -like 'Microsoft SQL Server Management Studio*' -and $row.Rows[0].AuthScheme -cin @('SQL','NTLM','KERBEROS')
  # SSMS kann nach USE master eine eigene IntelliSense-Verbindung in der
  # Test-DB behalten. Erst Ergebnisse/Messages prüfen und den eigenen Testtab
  # schließen und die eigene IntelliSense-Metadatenverbindung freigeben;
  # der Koordinator trennt keine Sitzung zwangsweise. Für den sichtbaren
  # Testablauf IntelliSense vor dem Öffnen vorübergehend deaktivieren und
  # erst nach abgeschlossenem Cleanup auf den Vorzustand zurückstellen.
  if($sqlComplete -and -not $completionRecorded){
   @{schemaVersion=1;state='SQL_COMPLETE_WAITING_FOR_CLIENT_CLOSE';application='SSMS';authScheme=[string]$row.Rows[0].AuthScheme;scriptSha256=(Get-FileHash $path).Hash}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $JournalDirectory 'gui-sql-complete.json') -Encoding utf8
   $completionRecorded=$true
  }
  $sessions=Query $Connection "SELECT COUNT_BIG(*) AS N FROM sys.dm_exec_sessions WHERE database_id=DB_ID() AND program_name LIKE N'Microsoft SQL Server Management Studio%';"
  if($sqlComplete -and $sessions.Rows[0].N -eq 0){
   @{schemaVersion=1;state='SQL_PASS';visualValidation='pending';application='SSMS';authScheme=[string]$row.Rows[0].AuthScheme;scriptSha256=(Get-FileHash $path).Hash}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $JournalDirectory 'gui-result.json') -Encoding utf8
   $passed=$true;break
  }
  Start-Sleep -Milliseconds 500
 }
 if(-not $passed){
  if($completionRecorded){throw 'SSIS_GUI_CLIENT_CONNECTIONS_REMAIN'}
  throw 'SSIS_GUI_NOT_EXECUTED_WITHIN_BOUNDED_WINDOW'
 }
}finally{[void](Query $Connection ('DROP TABLE dbo.['+$receipt+'];'))}
'SSIS_CURRENT_GUI_SQL_PASS; actual SSMS application; visual inspection is a separate required observation'
