# Eigene synthetische Safe-Cast-Lifecyclevorbereitung; kein Top-level-SQL.
function Assert-SafeCastForeignSlotPrepared($Connection,[string]$Deploy,[string]$Uninstall,[string]$Mode){
 # Fremdslot im eigenen bereits deinstallierten Modulzustand: kein Produktobjekt adoptieren.
 $baseline=Get-SafeCastSnapshot $Connection
 $setup=@(Invoke-SafeCastSql $Connection @'
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51595,N'Foreign fixture session not neutral.',11;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Test.SafeCast.Owner'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner))
 OR OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt') IS NOT NULL
 OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version')
 THROW 51595,N'Foreign fixture absent ownership preflight failed.',12;
BEGIN TRY
 BEGIN TRAN;
 DECLARE @Snapshot nvarchar(max);
 EXEC sys.sp_executesql @SnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@Snapshot OUTPUT;
 IF @Snapshot IS NULL OR CONVERT(varbinary(max),@Snapshot)<>CONVERT(varbinary(max),@Baseline)
  THROW 51595,N'Foreign fixture baseline changed.',13;
 EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_conversion.TVF_TryCastBigInt(@Text nvarchar(max),@MaxInputBytes int=8192) RETURNS TABLE AS RETURN(SELECT CONVERT(int,73) SyntheticMarker);';
 DECLARE @ObjectId int=OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt',N'IF'),@DefinitionHash varchar(64);
 SELECT @DefinitionHash=CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),definition)),2) FROM sys.sql_modules WHERE object_id=@ObjectId;
 IF @ObjectId IS NULL OR @DefinitionHash IS NULL THROW 51595,N'Foreign fixture creation was not established.',14;
 EXEC sys.sp_executesql @SnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@Snapshot OUTPUT;
 IF @Snapshot IS NULL OR CONVERT(varbinary(max),@Snapshot)=CONVERT(varbinary(max),@Baseline)
  THROW 51595,N'Foreign fixture snapshot was not established.',15;
 COMMIT;
 SELECT @ObjectId ObjectId,@DefinitionHash DefinitionHash,@Snapshot ForeignSnapshot;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
'@ @{'@Owner'=$script:ledger.RunId;'@Baseline'=$baseline;'@SnapshotSql'=(Get-SafeCastCompleteSnapshotSql)} -Rows)
 if($setup.Count-ne1-or$setup[0].ObjectId-is[DBNull]-or$setup[0].ObjectId-le0-or$setup[0].DefinitionHash-notmatch'\A[A-F0-9]{64}\z'-or$setup[0].ForeignSnapshot-notmatch'\A[A-F0-9]{64}(\|[A-F0-9]{64}){2}\z'){throw 'SAFE_CAST_FOREIGN_FIXTURE_SHAPE'}
 $objectId=[int]$setup[0].ObjectId;$definition=[string]$setup[0].DefinitionHash;$foreign=[string]$setup[0].ForeignSnapshot
 $fixture=[ordered]@{Mode=$Mode;ObjectId=$objectId;DefinitionSHA256=$definition;BaselineSnapshot=$baseline;ForeignSnapshot=$foreign;Restored=$false;Rejections=0}
 $script:ledger.ForeignFixtures+=@($fixture);Save-SafeCastJournal
 $rejections=0
 try{
  foreach($installer in @($Deploy,$Uninstall)){
   Assert-SafeCastPins
   if((Get-SafeCastSnapshot $Connection)-cne$foreign){throw 'SAFE_CAST_FOREIGN_SNAPSHOT_CHANGED_BEFORE_REJECTION'}
   $caught=$false
   try{Invoke-SafeCastBatches $Connection $installer}catch{
    $sqlError=$null;$cursor=$_.Exception
    while($cursor){if($cursor-is[Data.SqlClient.SqlException]){$sqlError=$cursor};$cursor=$cursor.InnerException}
    if($null-eq$sqlError-or$sqlError.Errors.Count-lt1){throw 'SAFE_CAST_FOREIGN_REJECTION_SQL_MISSING'}
    foreach($entry in $sqlError.Errors){if($entry.Number-ne55424-or$entry.State-ne3){throw 'SAFE_CAST_FOREIGN_REJECTION_ORACLE'}}
    $caught=$true
   }
   if(-not$caught){throw 'SAFE_CAST_FOREIGN_REJECTION_MISSING'}
   Invoke-SafeCastSql $Connection 'IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51595,N''Foreign rejected session not neutral.'',16;'
   if((Get-SafeCastSnapshot $Connection)-cne$foreign){throw 'SAFE_CAST_FOREIGN_REJECTION_METADATA_CHANGED'}
   $rejections++
  }
 }finally{
  # Fremde Zwischenänderungen bleiben unangetastet; nur exakt die eigene Fixture wird entfernt.
  Invoke-SafeCastSql $Connection @'
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51595,N'Foreign restore session not neutral.',17;
BEGIN TRY
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Test.SafeCast.Owner'
  AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner))
  OR OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt',N'IF') IS NULL
  OR OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt',N'IF')<>@ObjectId
  OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId)
  OR NOT EXISTS(SELECT 1 FROM sys.sql_modules WHERE object_id=@ObjectId AND CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),definition)),2)=@DefinitionHash)
  THROW 51595,N'Foreign restore identity changed.',18;
 DECLARE @Snapshot nvarchar(max);
 EXEC sys.sp_executesql @SnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@Snapshot OUTPUT;
 IF @Snapshot IS NULL OR CONVERT(varbinary(max),@Snapshot)<>CONVERT(varbinary(max),@ForeignSnapshot)
  THROW 51595,N'Foreign snapshot changed before restore.',19;
 DROP FUNCTION toolbelt_conversion.TVF_TryCastBigInt;
 EXEC sys.sp_executesql @SnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@Snapshot OUTPUT;
 IF @Snapshot IS NULL OR CONVERT(varbinary(max),@Snapshot)<>CONVERT(varbinary(max),@Baseline)
  THROW 51595,N'Foreign exact baseline restoration failed.',20;
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
'@ @{'@Owner'=$script:ledger.RunId;'@ObjectId'=$objectId;'@DefinitionHash'=$definition;'@ForeignSnapshot'=$foreign;'@Baseline'=$baseline;'@SnapshotSql'=(Get-SafeCastCompleteSnapshotSql)}
  if((Get-SafeCastSnapshot $Connection)-cne$baseline){throw 'SAFE_CAST_FOREIGN_RESTORED_BASELINE_CHANGED'}
  $fixture.Restored=$true;Save-SafeCastJournal
 }
 if($rejections-ne2){throw 'SAFE_CAST_FOREIGN_COMPLETED_COUNT_INVALID'}
 $fixture.Rejections=2;Save-SafeCastJournal
}
function Assert-SafeCastCallerPrepared($Connection,[string]$Deploy,[string]$Uninstall,[ValidateSet('ON','OFF')][string]$Abort,[bool]$Doomed){
 $installers=@(([regex]::Split($Deploy,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$'))[0],([regex]::Split($Uninstall,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$'))[0])
 if($Doomed){
  $index=0
  foreach($installer in $installers){
   $setup=@'
IF OBJECT_ID(N'tempdb..#tbx_SafeCastCaller') IS NOT NULL THROW 51593,N'Synthetic caller table collision.',7;
CREATE TABLE #tbx_SafeCastCaller(Value int NOT NULL CHECK(Value>0));
DECLARE @SafeCastOptions int,@SafeCastBefore nvarchar(max),@SafeCastAfter nvarchar(max),@SafeCastRejected bit=0;
BEGIN TRY
 BEGIN TRAN;INSERT #tbx_SafeCastCaller VALUES(7);
 SET XACT_ABORT ON;
 BEGIN TRY INSERT #tbx_SafeCastCaller VALUES(-1);END TRY BEGIN CATCH IF ERROR_NUMBER()<>547 THROW;END CATCH;
 IF @SafeCastAbort=N'OFF' SET XACT_ABORT OFF;ELSE SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>-1 THROW 51593,N'Caller doom not established.',1;
 SET @SafeCastOptions=@@OPTIONS;
 EXEC sys.sp_executesql @SafeCastSnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@SafeCastBefore OUTPUT;
 BEGIN TRY
'@
   $tail=@'
 END TRY
 BEGIN CATCH
  IF ERROR_NUMBER()<>50000 OR ERROR_STATE()<>1
   OR LEFT(ERROR_MESSAGE(),LEN(@SafeCastPrefix))<>@SafeCastPrefix THROW 51593,N'Caller error oracle mismatch.',2;
  SET @SafeCastRejected=1;
 END CATCH;
 IF @SafeCastRejected<>1 OR @@TRANCOUNT<>1 OR XACT_STATE()<>-1 OR @@OPTIONS<>@SafeCastOptions
  OR (SELECT COUNT(*) FROM #tbx_SafeCastCaller)<>1 OR (SELECT SUM(Value) FROM #tbx_SafeCastCaller)<>7
  THROW 51593,N'Caller state changed.',3;
 EXEC sys.sp_executesql @SafeCastSnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@SafeCastAfter OUTPUT;
 IF @SafeCastBefore IS NULL OR @SafeCastAfter IS NULL OR CONVERT(varbinary(max),@SafeCastBefore)<>CONVERT(varbinary(max),@SafeCastAfter)
  THROW 51593,N'Caller metadata changed.',4;
 ROLLBACK;DROP TABLE #tbx_SafeCastCaller;
 SELECT CONVERT(int,1) Witness,@SafeCastIndex InstallerIndex;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 IF OBJECT_ID(N'tempdb..#tbx_SafeCastCaller') IS NOT NULL DROP TABLE #tbx_SafeCastCaller;
 THROW;
END CATCH;
'@
   # Die Originalbytes des Erstbatches bleiben unverändert als Teilstring;
   # kein EXEC des Installers. RETURN ohne CATCH würde die Witnesszeile überspringen.
   $sql=$setup+"`n"+$installer+"`n"+$tail
   $rows=@(Invoke-SafeCastSql $Connection $sql @{'@SafeCastAbort'=$Abort;'@SafeCastPrefix'='TBX_SAFE_CAST_LIFECYCLE_CALLER_TRANSACTION:';'@SafeCastSnapshotSql'=(Get-SafeCastCompleteSnapshotSql);'@SafeCastIndex'=[int]$index} -Rows)
   if($rows.Count -ne 1 -or $rows[0].Witness -ne 1 -or $rows[0].InstallerIndex -ne $index){throw 'SAFE_CAST_DOOM_CALLER_WITNESS_MISSING'}
   $index++
  }
  return
 }
 Invoke-SafeCastSql $Connection "IF OBJECT_ID(N'tempdb..#tbx_SafeCastCaller') IS NOT NULL THROW 51593,N'Synthetic caller table collision.',7;"
 $ownsCaller=$true
 try{
  Invoke-SafeCastSql $Connection ("SET XACT_ABORT $Abort;IF OBJECT_ID(N'tempdb..#tbx_SafeCastCaller') IS NOT NULL THROW 51593,N'Synthetic caller table collision.',7;
CREATE TABLE #tbx_SafeCastCaller(Value int NOT NULL CHECK(Value>0));BEGIN TRAN;INSERT #tbx_SafeCastCaller VALUES(7);")
  $before=Get-SafeCastSnapshot $Connection
  $baseline=@(Invoke-SafeCastSql $Connection 'SELECT @@OPTIONS Options;' -Rows)
  if($baseline.Count -ne 1){throw 'SAFE_CAST_CALLER_OPTIONS_SHAPE'}
  foreach($installer in $installers){
   $caught=$false
   # Direkter Clientbatch ohne SQL-CATCH-/EXEC-Hülle um RAISERROR.
   try{Invoke-SafeCastSql $Connection $installer}catch{
    $sqlError=$null;$cursor=$_.Exception
    while($cursor){if($cursor -is [Data.SqlClient.SqlException]){$sqlError=$cursor};$cursor=$cursor.InnerException}
    if($null -eq $sqlError -or $sqlError.Errors.Count -lt 1){throw 'SAFE_CAST_CALLER_ERROR_MISSING'}
    foreach($errorEntry in $sqlError.Errors){
     if($errorEntry.Number -ne 50000 -or $errorEntry.State -ne 1 -or -not $errorEntry.Message.StartsWith('TBX_SAFE_CAST_LIFECYCLE_CALLER_TRANSACTION:',[StringComparison]::Ordinal)){throw 'SAFE_CAST_CALLER_ERROR_ORACLE_MISMATCH'}
    }
    $caught=$true
   }
   $state=@(Invoke-SafeCastSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState,@@OPTIONS Options,(SELECT COUNT(*) FROM #tbx_SafeCastCaller) SentinelCount,(SELECT SUM(Value) FROM #tbx_SafeCastCaller) SentinelSum;' -Rows)
   if(-not $caught -or $state.Count -ne 1 -or $state[0].TranCount -ne 1 -or $state[0].TranState -ne 1 -or $state[0].Options -ne $baseline[0].Options -or $state[0].SentinelCount -ne 1 -or $state[0].SentinelSum -ne 7){throw 'SAFE_CAST_INTACT_CALLER_STATE_CHANGED'}
   if((Get-SafeCastSnapshot $Connection) -cne $before){throw 'SAFE_CAST_INTACT_CALLER_METADATA_CHANGED'}
  }
 }finally{if($ownsCaller){Invoke-SafeCastSql $Connection 'IF @@TRANCOUNT>0 ROLLBACK;IF OBJECT_ID(N''tempdb..#tbx_SafeCastCaller'') IS NOT NULL DROP TABLE #tbx_SafeCastCaller;'}}
}

function Assert-SafeCastLockPrepared($Target,[string]$Database,$Connection,[string]$Deploy,[string]$Uninstall){
 $holder=Open-SafeCastConnection $Target $Database
 try{
  Invoke-SafeCastSql $holder @'
BEGIN TRAN;
DECLARE @Result int;
EXEC @Result=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.conversion.safe-cast',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
IF @Result<0 THROW 51593,N'Synthetic holder lock not acquired.',5;
'@
  foreach($scriptText in @($Deploy,$Uninstall)){
   $before=Get-SafeCastSnapshot $Connection
   $caught=$false
   try{Invoke-SafeCastBatches $Connection $scriptText}catch{$failure=Get-SafeCastFailure $_.Exception;if($failure.SqlNumber-ne55423-or$failure.SqlState-ne1){throw};$caught=$true}
   if(-not$caught){throw 'SAFE_CAST_LOCK_REJECTION_MISSING'}
   if((Get-SafeCastSnapshot $Connection) -cne $before){throw 'SAFE_CAST_LOCK_METADATA_CHANGED'}
   $state=@(Invoke-SafeCastSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState;' -Rows)
   if($state.Count -ne 1 -or $state[0].TranCount -ne 0 -or $state[0].TranState -ne 0){throw 'SAFE_CAST_LOCK_TRANSACTION_LEFT'}
  }
 }finally{
  try{if($holder.State -eq [Data.ConnectionState]::Open){Invoke-SafeCastSql $holder 'IF @@TRANCOUNT>0 ROLLBACK;'}}finally{$holder.Dispose()}
 }
}
function Get-SafeCastCompleteSnapshotSql {
 @'
SELECT @Snapshot=CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),ISNULL((
 SELECT o.object_id,o.name,o.type,o.principal_id,COALESCE(o.principal_id,s.principal_id) EffectiveOwner,
  m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier,m.is_schema_bound,m.execute_as_principal_id,
  (SELECT p.name,p.minor_id,TRY_CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'BaseType')) BaseType,
    TRY_CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'MaxLength')) MaxLength,
    TRY_CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'Precision')) PrecisionValue,
    TRY_CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'Scale')) ScaleValue,
    TRY_CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'Collation')) CollationValue,
    CONVERT(varchar(max),CONVERT(varbinary(max),p.value),2) ValueBytes
   FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id ORDER BY p.name,p.minor_id FOR JSON PATH,INCLUDE_NULL_VALUES) Properties,
  (SELECT p.parameter_id,p.name,p.system_type_id,p.user_type_id,p.max_length,p.precision,p.scale,p.is_output,p.is_nullable,p.has_default_value
   FROM sys.parameters p WHERE p.object_id=o.object_id ORDER BY p.parameter_id FOR JSON PATH,INCLUDE_NULL_VALUES) Parameters,
  (SELECT c.column_id,c.name,c.system_type_id,c.user_type_id,c.max_length,c.precision,c.scale,c.is_nullable,c.collation_name
   FROM sys.columns c WHERE c.object_id=o.object_id ORDER BY c.column_id FOR JSON PATH,INCLUDE_NULL_VALUES) Columns
 FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
 WHERE o.schema_id=SCHEMA_ID(N'toolbelt_conversion') ORDER BY o.name,o.object_id FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]'))),2)
 +'|'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),ISNULL((
 SELECT class,major_id,minor_id,name,TRY_CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,'BaseType')) BaseType,
  TRY_CONVERT(int,SQL_VARIANT_PROPERTY(value,'MaxLength')) MaxLength,
  TRY_CONVERT(int,SQL_VARIANT_PROPERTY(value,'Precision')) PrecisionValue,
  TRY_CONVERT(int,SQL_VARIANT_PROPERTY(value,'Scale')) ScaleValue,
  TRY_CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,'Collation')) CollationValue,
  CONVERT(varchar(max),CONVERT(varbinary(max),value),2) ValueBytes
 FROM sys.extended_properties WHERE (class=0 AND name LIKE N'Toolbelt.Module.toolbelt.conversion.safe-cast.%')
  OR(class=3 AND major_id=SCHEMA_ID(N'toolbelt_conversion'))
 ORDER BY class,major_id,minor_id,name FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]'))),2)
 +'|'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),ISNULL((
 SELECT schema_id,name,principal_id FROM sys.schemas WHERE schema_id=SCHEMA_ID(N'toolbelt_conversion') FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]'))),2);
'@
}
function Get-SafeCastSnapshot($Connection){
 $sql='DECLARE @Snapshot nvarchar(max);'+[Environment]::NewLine+(Get-SafeCastCompleteSnapshotSql)+[Environment]::NewLine+'SELECT @Snapshot AS Snapshot;'
 $rows=@(Invoke-SafeCastSql $Connection $sql -Rows)
 if($rows.Count-ne1-or$rows[0].Snapshot-is[DBNull]-or[string]$rows[0].Snapshot-notmatch'\A[A-F0-9]{64}(\|[A-F0-9]{64}){2}\z'){throw 'SAFE_CAST_COMPLETE_SNAPSHOT_INVALID'}
 return [string]$rows[0].Snapshot
}
function Assert-SafeCastRollbackPrepared($Connection,[string]$Deploy,[string]$Uninstall){
 $injected=[Collections.Generic.List[string]]::new()
 foreach($text in @($Deploy,$Uninstall)){
  $dropNeedle='DROP FUNCTION toolbelt_conversion.TVF_TryCastBigInt;'
  if([regex]::Matches($text,[regex]::Escape($dropNeedle)).Count-ne1){throw 'SAFE_CAST_POSTDROP_SEAM_AMBIGUOUS'}
  $injected.Add($text.Replace($dropNeedle,$dropNeedle+"`n THROW 51593,N'Synthetic Safe Cast postDROP fault.',6;"))
  $commitNeedle='COMMIT TRANSACTION;SET @OwnTransaction=0;'
  if([regex]::Matches($text,[regex]::Escape($commitNeedle)).Count-ne1){throw 'SAFE_CAST_PRECOMMIT_SEAM_AMBIGUOUS'}
  $injected.Add($text.Replace($commitNeedle,"THROW 51593,N'Synthetic Safe Cast preCOMMIT fault.',6;`n "+$commitNeedle))
 }
 foreach($text in $injected){
  Assert-SafeCastPins
  $before=Get-SafeCastSnapshot $Connection;$caught=$false
  try{Invoke-SafeCastBatches $Connection $text}catch{$failure=Get-SafeCastFailure $_.Exception;if($failure.SqlNumber-ne51593-or$failure.SqlState-ne6){throw};$caught=$true}
  if(-not$caught){throw 'SAFE_CAST_ROLLBACK_REJECTION_MISSING'}
  if((Get-SafeCastSnapshot $Connection)-cne$before){throw 'SAFE_CAST_ROLLBACK_METADATA_CHANGED'}
  $state=@(Invoke-SafeCastSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState;' -Rows)
  if($state.Count-ne1-or$state[0].TranCount-ne0-or$state[0].TranState-ne0){throw 'SAFE_CAST_ROLLBACK_TRANSACTION_LEFT'}
 }
}
function Assert-SafeCastConfirmPrepared($Connection,[string]$Uninstall){
 # Tatsächlicher neutraler Confirm0-Pfad und ein gesunder Caller-TX-Gatepfad.
 $before=Get-SafeCastSnapshot $Connection;$caught=$false
 try{Invoke-SafeCastBatches $Connection $Uninstall}catch{$failure=Get-SafeCastFailure $_.Exception;if($failure.SqlNumber-ne55426-or$failure.SqlState-ne1){throw};$caught=$true}
 if(-not$caught){throw 'SAFE_CAST_CONFIRM_REJECTION_MISSING'}
 if((Get-SafeCastSnapshot $Connection)-cne$before){throw 'SAFE_CAST_CONFIRM_METADATA_CHANGED'}
 $state=@(Invoke-SafeCastSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState;' -Rows)
 if($state.Count-ne1-or$state[0].TranCount-ne0-or$state[0].TranState-ne0){throw 'SAFE_CAST_CONFIRM_TRANSACTION_LEFT'}
 Invoke-SafeCastSql $Connection "IF OBJECT_ID(N'tempdb..#tbx_SafeCastConfirmCaller') IS NOT NULL THROW 51593,N'Synthetic confirm table collision.',7;"
 $ownsConfirm=$true
 try{
  Invoke-SafeCastSql $Connection 'SET XACT_ABORT ON;IF OBJECT_ID(N''tempdb..#tbx_SafeCastConfirmCaller'') IS NOT NULL THROW 51593,N''Synthetic confirm table collision.'',7;CREATE TABLE #tbx_SafeCastConfirmCaller(Value int NOT NULL);BEGIN TRAN;INSERT #tbx_SafeCastConfirmCaller VALUES(73);'
  $baseline=@(Invoke-SafeCastSql $Connection 'SELECT @@OPTIONS Options;' -Rows)
  $snapshot=Get-SafeCastSnapshot $Connection;$caught=$false
  try{Invoke-SafeCastBatches $Connection $Uninstall}catch{
   $sqlError=$null;$cursor=$_.Exception
   while($cursor){if($cursor-is[Data.SqlClient.SqlException]){$sqlError=$cursor};$cursor=$cursor.InnerException}
   if($null-eq$sqlError-or$sqlError.Errors.Count-lt1){throw 'SAFE_CAST_CONFIRM_CALLER_ERROR_MISSING'}
   foreach($entry in $sqlError.Errors){if($entry.Number-ne50000-or$entry.State-ne1-or-not$entry.Message.StartsWith('TBX_SAFE_CAST_LIFECYCLE_CALLER_TRANSACTION:',[StringComparison]::Ordinal)){throw 'SAFE_CAST_CONFIRM_CALLER_ERROR_ORACLE'}}
   $caught=$true
  }
  $actual=@(Invoke-SafeCastSql $Connection 'SELECT @@TRANCOUNT TranCount,XACT_STATE() TranState,@@OPTIONS Options,(SELECT COUNT(*) FROM #tbx_SafeCastConfirmCaller) SentinelCount,(SELECT SUM(Value) FROM #tbx_SafeCastConfirmCaller) SentinelSum;' -Rows)
  if(-not$caught-or$baseline.Count-ne1-or$actual.Count-ne1-or$actual[0].TranCount-ne1-or$actual[0].TranState-ne1-or$actual[0].Options-ne$baseline[0].Options-or$actual[0].SentinelCount-ne1-or$actual[0].SentinelSum-ne73){throw 'SAFE_CAST_CONFIRM_CALLER_STATE_CHANGED'}
  if((Get-SafeCastSnapshot $Connection)-cne$snapshot){throw 'SAFE_CAST_CONFIRM_CALLER_SNAPSHOT_CHANGED'}
 }finally{if($ownsConfirm){Invoke-SafeCastSql $Connection 'IF @@TRANCOUNT>0 ROLLBACK;IF OBJECT_ID(N''tempdb..#tbx_SafeCastConfirmCaller'') IS NOT NULL DROP TABLE #tbx_SafeCastConfirmCaller;'}}
}

function Assert-SafeCastTypedMarkerPrepared($Connection,[string]$Deploy,[string]$Uninstall,[string]$Mode){
 $baseline=Get-SafeCastSnapshot $Connection
 $original=@(Invoke-SafeCastSql $Connection @'
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51595,N'Marker baseline session not neutral.',1;
SELECT p.class,p.major_id,p.minor_id,p.name,
 CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,N'BaseType')) BaseType,
 CONVERT(int,SQL_VARIANT_PROPERTY(p.value,N'MaxLength')) MaxLength,
 CONVERT(varchar(max),CONVERT(varbinary(max),p.value),2) ValueBytes
FROM sys.extended_properties p
WHERE p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt',N'IF') AND p.minor_id=0 AND p.name=N'Toolbelt.Managed';
'@ -Rows)
 if($original.Count-ne1-or$original[0].class-ne1-or$original[0].major_id-le0-or$original[0].minor_id-ne0-or
  $original[0].name-cne'Toolbelt.Managed'-or$original[0].BaseType-cne'bit'-or$original[0].MaxLength-ne1-or$original[0].ValueBytes-cne'01'){
  throw 'SAFE_CAST_MARKER_BASELINE_TUPLE_INVALID'
 }
 $objectId=[int]$original[0].major_id
 $fixture=[ordered]@{Mode=$Mode;ObjectId=$objectId;Class=1;MinorId=0;Name='Toolbelt.Managed';BaseType='bit';MaxLength=1;ValueBytes='01';BaselineSnapshot=$baseline;DriftSnapshot=$null;Restored=$false;Rejections=0}
 Save-SafeCastJournal
 $script:ledger.MarkerFixtures+=@($fixture);Save-SafeCastJournal
 $parameters=@{'@Owner'=$script:ledger.RunId;'@ObjectId'=$objectId;'@Baseline'=$baseline;'@SnapshotSql'=(Get-SafeCastCompleteSnapshotSql)}
 $setup=@(Invoke-SafeCastSql $Connection @'
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51595,N'Marker setup session not neutral.',2;
BEGIN TRY
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Test.SafeCast.Owner'
  AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner))
  OR OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt',N'IF')<>@ObjectId OR OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt',N'IF') IS NULL
  OR (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=N'Toolbelt.Managed'
    AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'bit' AND SQL_VARIANT_PROPERTY(value,N'MaxLength')=1
    AND CONVERT(varbinary(max),value)=CONVERT(varbinary(max),CONVERT(bit,1)))<>1
  THROW 51595,N'Marker setup ownership changed.',3;
 DECLARE @Snapshot nvarchar(max);
 EXEC sys.sp_executesql @SnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@Snapshot OUTPUT;
 IF @Snapshot IS NULL OR CONVERT(varbinary(max),@Snapshot)<>CONVERT(varbinary(max),@Baseline)
  THROW 51595,N'Marker baseline changed before setup.',4;
 DECLARE @SyntheticMarker int=1;
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Managed',@value=@SyntheticMarker,
  @level0type=N'SCHEMA',@level0name=N'toolbelt_conversion',@level1type=N'FUNCTION',@level1name=N'TVF_TryCastBigInt';
 EXEC sys.sp_executesql @SnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@Snapshot OUTPUT;
 IF @Snapshot IS NULL OR CONVERT(varbinary(max),@Snapshot)=CONVERT(varbinary(max),@Baseline)
  THROW 51595,N'Marker drift was not established.',5;
 COMMIT;
 SELECT @Snapshot DriftSnapshot;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
'@ $parameters -Rows)
 if($setup.Count-ne1-or$setup[0].DriftSnapshot-is[DBNull]-or[string]$setup[0].DriftSnapshot-notmatch'\A[A-F0-9]{64}(\|[A-F0-9]{64}){2}\z'){
  throw 'SAFE_CAST_MARKER_DRIFT_SNAPSHOT_INVALID'
 }
 $drift=[string]$setup[0].DriftSnapshot
 $fixture.DriftSnapshot=$drift;Save-SafeCastJournal
 $rejections=0
 try{
  foreach($installer in @($Deploy,$Uninstall)){
   Assert-SafeCastPins
   if((Get-SafeCastSnapshot $Connection)-cne$drift){throw 'SAFE_CAST_MARKER_DRIFT_CHANGED_BEFORE_REJECTION'}
   $caught=$false
   try{Invoke-SafeCastBatches $Connection $installer}catch{
    $sqlError=$null;$cursor=$_.Exception
    while($cursor){if($cursor-is[Data.SqlClient.SqlException]){$sqlError=$cursor};$cursor=$cursor.InnerException}
    if($null-eq$sqlError-or$sqlError.Errors.Count-lt1){throw 'SAFE_CAST_MARKER_REJECTION_SQL_MISSING'}
    foreach($item in $sqlError.Errors){if($item.Number-ne55424-or$item.State-ne5){throw 'SAFE_CAST_MARKER_REJECTION_ORACLE_MISMATCH'}}
    $caught=$true
   }
   if(-not$caught){throw 'SAFE_CAST_MARKER_REJECTION_MISSING'}
   Invoke-SafeCastSql $Connection 'IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51595,N''Marker rejected session not neutral.'',6;'
   if((Get-SafeCastSnapshot $Connection)-cne$drift){throw 'SAFE_CAST_MARKER_REJECTION_SNAPSHOT_CHANGED'}
   $rejections++
  }
 }finally{
  # Compare-and-restore im eigenen Batch: keine fremde zwischenzeitliche Änderung überschreiben.
  $restore=@{'@Owner'=$script:ledger.RunId;'@ObjectId'=$objectId;'@Drift'=$drift;'@Baseline'=$baseline;'@SnapshotSql'=(Get-SafeCastCompleteSnapshotSql)}
  Invoke-SafeCastSql $Connection @'
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51595,N'Marker restore session not neutral.',7;
BEGIN TRY
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Test.SafeCast.Owner'
  AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Owner))
  OR OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt',N'IF')<>@ObjectId OR OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt',N'IF') IS NULL
  OR (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=N'Toolbelt.Managed'
    AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'int' AND SQL_VARIANT_PROPERTY(value,N'MaxLength')=4
    AND CONVERT(varbinary(max),value)=CONVERT(varbinary(max),CONVERT(int,1)))<>1
  THROW 51595,N'Marker restore ownership changed.',8;
 DECLARE @Snapshot nvarchar(max);
 EXEC sys.sp_executesql @SnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@Snapshot OUTPUT;
 IF @Snapshot IS NULL OR CONVERT(varbinary(max),@Snapshot)<>CONVERT(varbinary(max),@Drift)
  THROW 51595,N'Marker drift changed before restore.',9;
 DECLARE @OriginalMarker bit=CONVERT(bit,1);
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Managed',@value=@OriginalMarker,
  @level0type=N'SCHEMA',@level0name=N'toolbelt_conversion',@level1type=N'FUNCTION',@level1name=N'TVF_TryCastBigInt';
 EXEC sys.sp_executesql @SnapshotSql,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@Snapshot OUTPUT;
 IF @Snapshot IS NULL OR CONVERT(varbinary(max),@Snapshot)<>CONVERT(varbinary(max),@Baseline)
  THROW 51595,N'Marker restoration did not restore exact baseline.',10;
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
'@ $restore
  if((Get-SafeCastSnapshot $Connection)-cne$baseline){throw 'SAFE_CAST_MARKER_RESTORED_SNAPSHOT_CHANGED'}
  $fixture.Restored=$true;Save-SafeCastJournal
 }
 if($rejections-ne2){throw 'SAFE_CAST_MARKER_COMPLETED_COUNT_INVALID'}
 $fixture.Rejections=2
 Save-SafeCastJournal
}
