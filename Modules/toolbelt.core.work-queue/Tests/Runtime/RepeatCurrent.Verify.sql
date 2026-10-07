:On Error exit
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54928,N'Repeat ließ eine Transaktion offen.',1;
CREATE TABLE #tbx_QueueRepeatActual(TableName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,RowBytes varbinary(max) NOT NULL);
SELECT * INTO #tbx_QueueRepeatIdentityActual FROM #tbx_QueueRepeatIdentity WHERE 1=0;
DECLARE @Table sysname,@Sql nvarchar(max),@ObjectId int;
DECLARE tables_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT TableName,ObjectId FROM #tbx_QueueRepeatObjects ORDER BY TableName;
OPEN tables_cursor;FETCH NEXT FROM tables_cursor INTO @Table,@ObjectId;
WHILE @@FETCH_STATUS=0
BEGIN
 IF ISNULL(OBJECT_ID(N'toolbelt_core.'+QUOTENAME(@Table)),0)<>@ObjectId THROW 54928,N'Repeat ersetzte oder entfernte eine persistente Tabelle.',2;
 INSERT #tbx_QueueRepeatIdentityActual SELECT @Table,name,column_id,system_type_id,CONVERT(decimal(38,0),seed_value),CONVERT(decimal(38,0),increment_value),CONVERT(decimal(38,0),last_value),is_not_for_replication FROM sys.identity_columns WHERE object_id=@ObjectId;
 SET @Sql=N'INSERT #tbx_QueueRepeatActual SELECT @Name,CONVERT(varbinary(max),(SELECT r.* FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER)) FROM toolbelt_core.'+QUOTENAME(@Table)+N' r;';
 EXEC sys.sp_executesql @Sql,N'@Name sysname',@Name=@Table;
 FETCH NEXT FROM tables_cursor INTO @Table,@ObjectId;
END;
CLOSE tables_cursor;DEALLOCATE tables_cursor;
IF (SELECT COUNT(*) FROM #tbx_QueueRepeatIdentity)<>(SELECT COUNT(*) FROM #tbx_QueueRepeatIdentityActual)
 OR EXISTS(SELECT * FROM #tbx_QueueRepeatIdentity EXCEPT SELECT * FROM #tbx_QueueRepeatIdentityActual)
 OR EXISTS(SELECT * FROM #tbx_QueueRepeatIdentityActual EXCEPT SELECT * FROM #tbx_QueueRepeatIdentity)
 THROW 54928,N'Repeat änderte Identitydefinition, Seed, Increment oder LastValue.',3;
IF (SELECT COUNT(*) FROM #tbx_QueueRepeatRows)<>(SELECT COUNT(*) FROM #tbx_QueueRepeatActual)
 OR EXISTS(SELECT TableName,RowBytes FROM #tbx_QueueRepeatRows EXCEPT SELECT TableName,RowBytes FROM #tbx_QueueRepeatActual)
 OR EXISTS(SELECT TableName,RowBytes FROM #tbx_QueueRepeatActual EXCEPT SELECT TableName,RowBytes FROM #tbx_QueueRepeatRows)
 THROW 54928,N'Repeat änderte Zeilen, Payload, History, Rowversion oder Gatetokens.',4;
IF (SELECT COUNT(DISTINCT Status) FROM toolbelt_core.WorkItem)<>7
 OR (SELECT COUNT(*) FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND name IN(N'CK_WorkItem_Status',N'CK_WorkItem_StateMetadata',N'CK_WorkItem_RecoveryMetadata',N'CK_WorkItem_W6cPolicy') AND is_disabled=0 AND is_not_trusted=0)<>4
 OR (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id IN(OBJECT_ID(N'toolbelt_core.WorkItem'),OBJECT_ID(N'toolbelt_core.WorkQueueBarrierBlocker')) AND name IN(N'FK_WorkItem_WorkType',N'FK_WorkQueueBarrierBlocker_Barrier',N'FK_WorkQueueBarrierBlocker_Blocking') AND is_disabled=0 AND is_not_trusted=0)<>3
 THROW 54928,N'Repeat verlor Zustände oder aktive vertrauenswürdige Constraints/FKs.',5;
DROP TABLE #tbx_QueueRepeatActual;
DROP TABLE #tbx_QueueRepeatIdentityActual;
SELECT CAST('PASS' AS varchar(16)) CurrentQueueRepeatRowsPreserved;
GO
