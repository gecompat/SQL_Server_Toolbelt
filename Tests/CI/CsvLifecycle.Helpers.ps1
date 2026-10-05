# Eigene synthetische CSV-Lifecyclevorbereitung; kein Top-level-SQL.
function Assert-CsvCallerPrepared($Connection,[string]$Deploy,[string]$Uninstall,[ValidateSet('ON','OFF')][string]$Abort,[bool]$Doomed){
 $installers=@(([regex]::Split($Deploy,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$'))[0],([regex]::Split($Uninstall,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$'))[0])
 if($Doomed){
  $index=0
  foreach($installer in $installers){
   $setup=@'
CREATE TABLE #CsvCaller(Value int NOT NULL CHECK(Value>0));
DECLARE @CsvOptions int,@CsvBefore nvarchar(max),@CsvAfter nvarchar(max),@CsvRejected bit=0;
BEGIN TRY
 BEGIN TRAN;INSERT #CsvCaller VALUES(7);
 SET XACT_ABORT ON;
 BEGIN TRY INSERT #CsvCaller VALUES(-1);END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW;END CATCH;
 IF @CsvAbort=N'OFF' SET XACT_ABORT OFF;ELSE SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>-1 THROW 51593,N'Caller doom not established.',1;
 SET @CsvOptions=@@OPTIONS;
 EXEC sys.sp_executesql @CsvSnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@CsvBefore OUTPUT;
 BEGIN TRY
'@
   $tail=@'
 END TRY
 BEGIN CATCH
  IF ERROR_NUMBER()<>50000 OR ERROR_STATE()<>1
   OR LEFT(ERROR_MESSAGE(),LEN(@CsvPrefix))<>@CsvPrefix THROW 51593,N'Caller error oracle mismatch.',2;
  SET @CsvRejected=1;
 END CATCH;
 IF @CsvRejected<>1 OR @@TRANCOUNT<>1 OR XACT_STATE()<>-1 OR @@OPTIONS<>@CsvOptions
  OR (SELECT COUNT(*) FROM #CsvCaller)<>1 OR (SELECT SUM(Value) FROM #CsvCaller)<>7
  THROW 51593,N'Caller state changed.',3;
 EXEC sys.sp_executesql @CsvSnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@CsvAfter OUTPUT;
 IF @CsvBefore IS NULL OR @CsvAfter IS NULL OR CONVERT(varbinary(max),@CsvBefore)<>CONVERT(varbinary(max),@CsvAfter)
  THROW 51593,N'Caller metadata changed.',4;
 ROLLBACK;DROP TABLE #CsvCaller;
 SELECT CONVERT(int,1) Witness,@CsvIndex InstallerIndex;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF OBJECT_ID(N'tempdb..#CsvCaller') IS NOT NULL DROP TABLE #CsvCaller;
 THROW;
END CATCH;
'@
   # Die Originalbytes des Erstbatches bleiben unverändert als Teilstring;
   # kein EXEC des Installers. RETURN ohne CATCH würde die Witnesszeile überspringen.
   $sql=$setup+"`n"+$installer+"`n"+$tail
   $rows=@(Invoke-CsvSql $Connection $sql @{'@CsvAbort'=$Abort;'@CsvPrefix'='TBX_CSV_LIFECYCLE_CALLER_TRANSACTION:';'@CsvSnapshotSql'=(Get-CsvCompleteSnapshotSql);'@CsvIndex'=[int]$index} -Rows)
   if($rows.Count -ne 1 -or $rows[0].Witness -ne 1 -or $rows[0].InstallerIndex -ne $index){throw 'CSV_DOOM_CALLER_WITNESS_MISSING'}
   $index++
  }
  return
 }
 try{
  Invoke-CsvSql $Connection ("SET XACT_ABORT $Abort;CREATE TABLE #CsvCaller(Value int NOT NULL CHECK(Value>0));BEGIN TRAN;INSERT #CsvCaller VALUES(7);")
  $before=Get-CsvSnapshot $Connection
  $baseline=@(Invoke-CsvSql $Connection 'SELECT @@OPTIONS Options;' -Rows)
  if($baseline.Count -ne 1){throw 'CSV_CALLER_OPTIONS_SHAPE'}
  foreach($installer in $installers){
   $caught=$false
   # Direkter Clientbatch ohne SQL-CATCH-/EXEC-Hülle um RAISERROR.
   try{Invoke-CsvSql $Connection $installer}catch{
    $sqlError=$null;$cursor=$_.Exception
    while($cursor){if($cursor -is [Data.SqlClient.SqlException]){$sqlError=$cursor};$cursor=$cursor.InnerException}
    if($null -eq $sqlError -or $sqlError.Errors.Count -lt 1){throw 'CSV_CALLER_ERROR_MISSING'}
    foreach($errorEntry in $sqlError.Errors){
     if($errorEntry.Number -ne 50000 -or $errorEntry.State -ne 1 -or -not $errorEntry.Message.StartsWith('TBX_CSV_LIFECYCLE_CALLER_TRANSACTION:',[StringComparison]::Ordinal)){throw 'CSV_CALLER_ERROR_ORACLE_MISMATCH'}
    }
    $caught=$true
   }
   $state=@(Invoke-CsvSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState,@@OPTIONS Options,(SELECT COUNT(*) FROM #CsvCaller) SentinelCount,(SELECT SUM(Value) FROM #CsvCaller) SentinelSum;' -Rows)
   if(-not $caught -or $state.Count -ne 1 -or $state[0].TranCount -ne 1 -or $state[0].TranState -ne 1 -or $state[0].Options -ne $baseline[0].Options -or $state[0].SentinelCount -ne 1 -or $state[0].SentinelSum -ne 7){throw 'CSV_INTACT_CALLER_STATE_CHANGED'}
   if((Get-CsvSnapshot $Connection) -cne $before){throw 'CSV_INTACT_CALLER_METADATA_CHANGED'}
  }
 }finally{Invoke-CsvSql $Connection 'IF @@TRANCOUNT>0 ROLLBACK;IF OBJECT_ID(N''tempdb..#CsvCaller'') IS NOT NULL DROP TABLE #CsvCaller;'}
}

function Assert-CsvLockPrepared($Target,[string]$Database,$Connection,[string]$Deploy,[string]$Uninstall){
 $holder=Open-CsvConnection $Target $Database
 try{
  Invoke-CsvSql $holder @'
BEGIN TRAN;
DECLARE @Result int;
EXEC @Result=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.file.csv-memory',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
IF @Result<0 THROW 51593,N'Synthetic holder lock not acquired.',5;
'@
  foreach($scriptText in @($Deploy,$Uninstall)){
   $before=Get-CsvSnapshot $Connection
   $caught=$false
   try{Invoke-CsvBatches $Connection $scriptText}catch{$failure=Get-CsvFailure $_.Exception;if($failure.SqlNumber-ne55323-or$failure.SqlState-ne1){throw};$caught=$true}
   if(-not$caught){throw 'CSV_LOCK_REJECTION_MISSING'}
   if((Get-CsvSnapshot $Connection) -cne $before){throw 'CSV_LOCK_METADATA_CHANGED'}
   $state=@(Invoke-CsvSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState;' -Rows)
   if($state.Count -ne 1 -or $state[0].TranCount -ne 0 -or $state[0].TranState -ne 0){throw 'CSV_LOCK_TRANSACTION_LEFT'}
  }
 }finally{
  try{if($holder.State -eq [Data.ConnectionState]::Open){Invoke-CsvSql $holder 'IF @@TRANCOUNT>0 ROLLBACK;'}}finally{$holder.Dispose()}
 }
}
function Get-CsvCompleteSnapshotSql {
 @'
SELECT @Snapshot=CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT o.object_id,o.name,o.type,o.principal_id,m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier,m.is_schema_bound,m.execute_as_principal_id,
  am.assembly_id,am.assembly_class,am.assembly_method,am.null_on_null_input,am.execute_as_principal_id AS ClrExecuteAs,
  TRY_CONVERT(int,OBJECTPROPERTYEX(o.object_id,'IsDeterministic')) AS IsDeterministic,
  (SELECT p.name,p.minor_id,TRY_CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'BaseType')) AS BaseType,TRY_CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'MaxLength')) AS MaxLength,
    CONVERT(varchar(max),CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),p.value)),2) AS ValueBytes
   FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id ORDER BY p.name,p.minor_id FOR JSON PATH,INCLUDE_NULL_VALUES) AS Properties,
  (SELECT p.parameter_id,p.name,p.system_type_id,p.user_type_id,p.max_length,p.precision,p.scale,p.is_output,p.is_nullable,p.has_default_value
   FROM sys.parameters p WHERE p.object_id=o.object_id ORDER BY p.parameter_id FOR JSON PATH,INCLUDE_NULL_VALUES) AS Parameters,
  (SELECT c.column_id,c.name,c.system_type_id,c.user_type_id,c.max_length,c.precision,c.scale,c.is_nullable,c.collation_name
   FROM sys.columns c WHERE c.object_id=o.object_id ORDER BY c.column_id FOR JSON PATH,INCLUDE_NULL_VALUES) AS Columns
 FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id LEFT JOIN sys.assembly_modules am ON am.object_id=o.object_id
 WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') ORDER BY o.name,o.object_id FOR JSON PATH,INCLUDE_NULL_VALUES))),2)
 +'|'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT class,major_id,minor_id,name,TRY_CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,'BaseType')) AS BaseType,TRY_CONVERT(int,SQL_VARIANT_PROPERTY(value,'MaxLength')) AS MaxLength,
  CONVERT(varchar(max),CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value)),2) AS ValueBytes
 FROM sys.extended_properties WHERE (class=0 AND name LIKE N'Toolbelt.Module.toolbelt.file.csv-memory.%')
  OR(class=3 AND major_id=SCHEMA_ID(N'toolbelt_file'))
  OR(class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_File_CsvMemory'))
 ORDER BY class,major_id,minor_id,name FOR JSON PATH,INCLUDE_NULL_VALUES))),2)
 +'|'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT a.assembly_id,a.name,a.principal_id,a.permission_set,a.is_user_defined,f.file_id,f.name AS FileName,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) AS BinaryHash
 FROM sys.assemblies a LEFT JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id
 WHERE a.name=N'Toolbelt_File_CsvMemory' ORDER BY a.assembly_id,f.file_id FOR JSON PATH,INCLUDE_NULL_VALUES))),2)
 +'|'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT schema_id,name,principal_id FROM sys.schemas WHERE schema_id=SCHEMA_ID(N'toolbelt_file') FOR JSON PATH,INCLUDE_NULL_VALUES))),2);
'@
}
function Get-CsvSnapshot($Connection){
 $sql=(Get-CsvCompleteSnapshotSql).Replace('SELECT @Snapshot=','SELECT ')
 $sql=$sql.Replace('FOR JSON PATH,INCLUDE_NULL_VALUES))),2);','FOR JSON PATH,INCLUDE_NULL_VALUES))),2) AS Snapshot;')
 $rows=@(Invoke-CsvSql $Connection $sql -Rows)
 if($rows.Count-ne1-or$rows[0].Snapshot-is[DBNull]-or[string]$rows[0].Snapshot-notmatch'\A[A-F0-9]{64}(\|[A-F0-9]{64}){3}\z'){throw 'CSV_COMPLETE_SNAPSHOT_INVALID'}
 return [string]$rows[0].Snapshot
}
function Assert-CsvRollbackPrepared($Connection,[string]$Deploy,[string]$Uninstall){
 $injected=[Collections.Generic.List[string]]::new()
 $dropNeedle='DROP PROCEDURE toolbelt_file.USP_ParseCsv;'
 foreach($text in @($Deploy,$Uninstall)){
  if([regex]::Matches($text,[regex]::Escape($dropNeedle)).Count-ne1){throw 'CSV_POSTDROP_SEAM_AMBIGUOUS'}
  $injected.Add($text.Replace($dropNeedle,$dropNeedle+"`n THROW 51593,N'Synthetic CSV postDROP fault.',6;"))
 }
 $commitMatches=[regex]::Matches($Deploy,'(?m)^ COMMIT TRANSACTION;\r?$')
 if($commitMatches.Count-ne1){throw 'CSV_DEPLOY_COMMIT_SEAM_AMBIGUOUS'}
 $injected.Add($Deploy.Insert($commitMatches[0].Index," THROW 51593,N'Synthetic CSV preCOMMIT fault.',6;`n"))
 $uninstallNeedle='COMMIT TRANSACTION;SET @OwnTransaction=0;'
 if([regex]::Matches($Uninstall,[regex]::Escape($uninstallNeedle)).Count-ne1){throw 'CSV_UNINSTALL_COMMIT_SEAM_AMBIGUOUS'}
 $injected.Add($Uninstall.Replace($uninstallNeedle,"THROW 51593,N'Synthetic CSV preCOMMIT fault.',6;`n  "+$uninstallNeedle))
 foreach($text in $injected){
  $before=Get-CsvSnapshot $Connection;$caught=$false
  try{Invoke-CsvBatches $Connection $text}catch{$failure=Get-CsvFailure $_.Exception;if($failure.SqlNumber-ne51593-or$failure.SqlState-ne6){throw};$caught=$true}
  if(-not$caught){throw 'CSV_ROLLBACK_REJECTION_MISSING'}
  if((Get-CsvSnapshot $Connection)-cne$before){throw 'CSV_ROLLBACK_METADATA_CHANGED'}
  $state=@(Invoke-CsvSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState;' -Rows)
  if($state.Count-ne1-or$state[0].TranCount-ne0-or$state[0].TranState-ne0){throw 'CSV_ROLLBACK_TRANSACTION_LEFT'}
 }
}
function Assert-CsvConfirmPrepared($Connection,[string]$Uninstall){
 # Der Caller liefert den bereits expandierten Confirm0-Uninstall; keine Textmutation.
 $before=Get-CsvSnapshot $Connection;$caught=$false
 try{Invoke-CsvBatches $Connection $Uninstall}catch{$failure=Get-CsvFailure $_.Exception;if($failure.SqlNumber-ne55326-or$failure.SqlState-ne1){throw};$caught=$true}
 if(-not$caught){throw 'CSV_CONFIRM_REJECTION_MISSING'}
 if((Get-CsvSnapshot $Connection)-cne$before){throw 'CSV_CONFIRM_METADATA_CHANGED'}
 $state=@(Invoke-CsvSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState;' -Rows)
 if($state.Count-ne1-or$state[0].TranCount-ne0-or$state[0].TranState-ne0){throw 'CSV_CONFIRM_TRANSACTION_LEFT'}
}
