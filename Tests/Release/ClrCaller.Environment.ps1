# Funktionen für den eng begrenzten CLR-Caller-Testscope; kein Teststart.
# Fingerprints und Verbraucherprüfungen aus dem vorhandenen CLR-Labweg erhalten.
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1') @('Get-CsvTrust','Assert-CsvTrustCleanupScope') @{
 'Get-CsvTrust'='Get-ClrCallerTrust';'Assert-CsvTrustCleanupScope'='Assert-ClrCallerTrustCleanupScope';
 'Invoke-CsvOwnSql'='Invoke-ReleaseSql';'Invoke-CsvSql'='Invoke-ReleaseSql'}){. $block}

function Get-ClrCallerConfiguration($Control){
 @(Invoke-ReleaseSql $Control 'SELECT name Name,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective,CONVERT(int,is_advanced) IsAdvanced FROM sys.configurations ORDER BY configuration_id;' -Rows)
}
function Get-ClrCallerPendingConfiguration($Rows){
 # Dokumentierte Engine-Normalisierung ist keine vorgemerkte Änderung.
 # https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-configurations-transact-sql
 @($Rows|Where-Object {
  $_.Configured -ne $_.Effective -and
  -not ($_.Name -ceq 'min server memory (MB)' -and $_.Configured -eq 0 -and $_.Effective -in @(8,16)) -and
  -not ($_.Name -ceq 'max server memory (MB)' -and $_.Configured -eq 0 -and $_.Effective -eq 2147483647)
 })
}
function Get-ClrCallerUserAssemblyCount($Control){
 $rows=@(Invoke-ReleaseSql $Control @'
IF EXISTS(SELECT 1 FROM sys.databases WHERE state<>0) THROW 52095,N'CLR consumer visibility uncertain.',1;
DECLARE @D table(Id int,Name sysname,Created varbinary(16));
INSERT @D SELECT database_id,name,CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases;
DECLARE @Name sysname,@Sql nvarchar(max),@Count int,@Total bigint=0;
DECLARE C CURSOR LOCAL FAST_FORWARD FOR SELECT Name FROM @D;
OPEN C; FETCH NEXT FROM C INTO @Name;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Count=NULL;
 SET @Sql=N'SELECT @Count=COUNT(*) FROM '+QUOTENAME(@Name)+N'.sys.assemblies WHERE is_user_defined=1;';
 EXEC sys.sp_executesql @Sql,N'@Count int OUTPUT',@Count OUTPUT;
 IF @Count IS NULL THROW 52095,N'CLR consumer result uncertain.',2;
 SET @Total+=@Count; FETCH NEXT FROM C INTO @Name;
END;
CLOSE C; DEALLOCATE C;
IF EXISTS(SELECT database_id,name,CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases
 EXCEPT SELECT Id,Name,Created FROM @D)
 OR EXISTS(SELECT Id,Name,Created FROM @D EXCEPT SELECT database_id,name,CONVERT(varbinary(max),CONVERT(datetime2(7),create_date)) FROM sys.databases)
 THROW 52095,N'CLR consumer inventory changed.',3;
SELECT @Total Count;
'@ -Rows)
 if($rows.Count -ne 1){throw 'CLR_CALLER_CONSUMER_COUNT'}
 return [long]$rows[0].Count
}
function Assert-ClrCallerConfiguration($Control,$Configuration){
 if(-not @($Configuration.before).Count){return}
 $now=@(Get-ClrCallerConfiguration $Control);$before=@($Configuration.before|Where-Object Name -ceq 'clr enabled');$actual=@($now|Where-Object Name -ceq 'clr enabled')
 if($before.Count -ne 1 -or $actual.Count -ne 1 -or $before[0].Configured -ne $actual[0].Configured -or $before[0].Effective -ne $actual[0].Effective){throw 'CLR_CALLER_CONFIGURATION_AUDIT_DRIFT'}
 if($Configuration.changed -and $Configuration.state -cne 'RESTORED'){throw 'CLR_CALLER_CONFIGURATION_NOT_RESTORED'}
}
function Start-ClrCallerConfiguration($Control){
 $before=@(Get-ClrCallerConfiguration $Control);$clr=@($before|Where-Object Name -ceq 'clr enabled');$strict=@($before|Where-Object Name -ceq 'clr strict security')
 if($clr.Count -ne 1 -or $strict.Count -ne 1 -or $strict[0].Configured -ne 1 -or $strict[0].Effective -ne 1){throw 'CLR_CALLER_STRICT_SECURITY_REQUIRED'}
 $ledger.configuration.before=$before;$ledger.configuration.state='CAPTURED';Save-ReleaseJournal
 if($clr[0].Configured -ne $clr[0].Effective){throw 'CLR_CALLER_PENDING_CONFIGURATION'}
 if($clr[0].Effective -eq 1){$ledger.configuration.state='PREEXISTING';Save-ReleaseJournal;return}
 if($clr[0].Effective -ne 0 -or $clr[0].IsAdvanced -ne 0 -or @(Get-ClrCallerPendingConfiguration $before).Count){throw 'CLR_CALLER_CONFIGURATION_SCOPE_UNSAFE'}
 if((Get-ClrCallerUserAssemblyCount $Control) -ne 0){throw 'CLR_CALLER_EXISTING_CONSUMERS_NO_ENABLE'}
 $ledger.configuration.changed=$true;$ledger.configuration.state='ACTIVATING';Save-ReleaseJournal
 Invoke-ReleaseSql $Control @'
IF EXISTS(SELECT 1 FROM sys.configurations WHERE value<>value_in_use
 AND NOT(name=N'min server memory (MB)' AND value=0 AND value_in_use IN(8,16))
 AND NOT(name=N'max server memory (MB)' AND value=0 AND value_in_use=2147483647))
 THROW 52095,N'Pending configuration changed.',4;
IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value=0 AND value_in_use=0 AND is_advanced=0) THROW 52095,N'CLR configuration changed.',5;
EXEC sys.sp_configure N'clr enabled',1; RECONFIGURE;
'@
 $now=@(Get-ClrCallerConfiguration $Control);$actual=@($now|Where-Object Name -ceq 'clr enabled')
 if($actual.Count -ne 1 -or $actual[0].Configured -ne 1 -or $actual[0].Effective -ne 1){throw 'CLR_CALLER_ENABLE_NOT_EFFECTIVE'}
 $ledger.configuration.state='OWNED';Save-ReleaseJournal
}
function Restore-ClrCallerConfiguration($Control){
 $cfg=$ledger.configuration
 if(-not $cfg.changed){Assert-ClrCallerConfiguration $Control $cfg;return}
 if($cfg.state -cnotin @('ACTIVATING','OWNED','RESTORING')){throw 'CLR_CALLER_CONFIGURATION_OWNERSHIP_UNKNOWN'}
 if((Get-ClrCallerUserAssemblyCount $Control) -ne 0){throw 'CLR_CALLER_NEW_CONSUMERS_NO_RESTORE'}
 $now=@(Get-ClrCallerConfiguration $Control)
 $beforeOther=@($cfg.before|Where-Object Name -cne 'clr enabled')|ConvertTo-Json -Depth 4 -Compress
 $nowOther=@($now|Where-Object Name -cne 'clr enabled')|ConvertTo-Json -Depth 4 -Compress
 if($beforeOther -cne $nowOther){throw 'CLR_CALLER_FOREIGN_CONFIGURATION_DRIFT'}
 $actual=@($now|Where-Object Name -ceq 'clr enabled')
 if($actual.Count -ne 1 -or $actual[0].Configured -notin @(0,1) -or $actual[0].Effective -notin @(0,1)){throw 'CLR_CALLER_CONFIGURATION_STATE_UNKNOWN'}
 # Nur zum eigenen Journalzustand passende Übergänge sind eigene Änderungen.
 # Insbesondere eine fremde vorgemerkte Abschaltung bei OWNED nicht aktivieren.
 $pair=([string]$actual[0].Configured)+'/'+([string]$actual[0].Effective)
 $allowed=@{ACTIVATING=@('0/0','1/0','1/1');OWNED=@('1/1');RESTORING=@('1/1','0/1','0/0')}
 if($pair -cnotin $allowed[$cfg.state]){throw 'CLR_CALLER_CONFIGURATION_OWNERSHIP_DRIFT'}
 $cfg.state='RESTORING';Save-ReleaseJournal
 Invoke-ReleaseSql $Control @'
IF EXISTS(SELECT 1 FROM sys.configurations WHERE name<>N'clr enabled' AND value<>value_in_use
 AND NOT(name=N'min server memory (MB)' AND value=0 AND value_in_use IN(8,16))
 AND NOT(name=N'max server memory (MB)' AND value=0 AND value_in_use=2147483647))
 THROW 52095,N'Foreign pending configuration.',6;
EXEC sys.sp_configure N'clr enabled',0; RECONFIGURE;
'@
 $cfg.state='RESTORED';Save-ReleaseJournal;Assert-ClrCallerConfiguration $Control $cfg
}
