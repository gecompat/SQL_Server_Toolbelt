-- Nur synthetische Callerwerte; keine Heap- oder allgemeine Clientzusage.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
CREATE TABLE [#CsvAliasCells](RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
INSERT [#CsvAliasCells] VALUES('DATA',99,99,REPLICATE(CONVERT(nvarchar(max),N'p'),8388608));
CREATE TABLE #CsvFaultProgress(Id int NOT NULL PRIMARY KEY CHECK(Id BETWEEN 1 AND 8));
CREATE TABLE #CsvFaultIdentity(TargetId int NOT NULL);
INSERT #CsvFaultIdentity VALUES(OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells')));
DECLARE @TargetId int=(SELECT TargetId FROM #CsvFaultIdentity);
SELECT * INTO #CsvFaultColumns FROM(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultIndexes FROM(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultKeys FROM(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultChecks FROM(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) captured;
-- Identische Quelle/Ziel, DATA, normaler Name, KeepData=0.
DECLARE @Old nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'w'),8388608),@Caught bit=0;
TRUNCATE TABLE [#CsvAliasCells];
INSERT [#CsvAliasCells] VALUES('DATA',1,1,@Old);
IF DATALENGTH(@Old)<>16777216 THROW 55396,N'CSV alias: volle Callerbytes fehlen.',1;
IF (SELECT COUNT_BIG(*) FROM [#CsvAliasCells])<>1 OR (SELECT COUNT_BIG(*) FROM [#CsvAliasCells] WHERE DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND RowOrdinal=1 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: volle Baseline fehlt.',2;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvAliasCells',@HasHeader=0,@LineEnding='CRLF',@KeepData=0,@ResultTable=N'#CsvAliasCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55308 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV alias: exakte55308-Abweisung fehlt.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
IF (SELECT COUNT_BIG(*) FROM [#CsvAliasCells])<>1 OR (SELECT COUNT_BIG(*) FROM [#CsvAliasCells] WHERE DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND RowOrdinal=1 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: voller Quellen-/Zielerhalt fehlt.',8;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
DROP TABLE #CsvFaultColumns;
DROP TABLE #CsvFaultIndexes;
DROP TABLE #CsvFaultKeys;
DROP TABLE #CsvFaultChecks;
DROP TABLE #CsvFaultIdentity;
DROP TABLE [#CsvAliasCells];
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
INSERT #CsvFaultProgress VALUES(1);

GO
-- Nur synthetische Callerwerte; keine Heap- oder allgemeine Clientzusage.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
CREATE TABLE [#Csv.Dot]]Alias](RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
INSERT [#Csv.Dot]]Alias] VALUES('DATA',99,99,REPLICATE(CONVERT(nvarchar(max),N'p'),8388608));
CREATE TABLE #CsvFaultIdentity(TargetId int NOT NULL);
INSERT #CsvFaultIdentity VALUES(OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias')));
DECLARE @TargetId int=(SELECT TargetId FROM #CsvFaultIdentity);
SELECT * INTO #CsvFaultColumns FROM(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultIndexes FROM(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultKeys FROM(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultChecks FROM(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) captured;
-- Identische Quelle/Ziel, DATA, ungewoehnlicher Name, KeepData=0.
DECLARE @Old nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'w'),8388608),@Caught bit=0;
TRUNCATE TABLE [#Csv.Dot]]Alias];
INSERT [#Csv.Dot]]Alias] VALUES('DATA',1,1,@Old);
IF DATALENGTH(@Old)<>16777216 THROW 55396,N'CSV alias: volle Callerbytes fehlen.',1;
IF (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias])<>1 OR (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias] WHERE DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND RowOrdinal=1 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: volle Baseline fehlt.',2;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#Csv.Dot]Alias',@HasHeader=0,@LineEnding='CRLF',@KeepData=0,@ResultTable=N'#Csv.Dot]Alias'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55308 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV alias: exakte55308-Abweisung fehlt.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
IF (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias])<>1 OR (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias] WHERE DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND RowOrdinal=1 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: voller Quellen-/Zielerhalt fehlt.',8;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
DROP TABLE #CsvFaultColumns;
DROP TABLE #CsvFaultIndexes;
DROP TABLE #CsvFaultKeys;
DROP TABLE #CsvFaultChecks;
DROP TABLE #CsvFaultIdentity;
DROP TABLE [#Csv.Dot]]Alias];
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
INSERT #CsvFaultProgress VALUES(2);

GO
-- Nur synthetische Callerwerte; keine Heap- oder allgemeine Clientzusage.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
CREATE TABLE [#CsvAliasCells](RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
INSERT [#CsvAliasCells] VALUES('DATA',99,99,REPLICATE(CONVERT(nvarchar(max),N'p'),8388608));
CREATE TABLE #CsvFaultIdentity(TargetId int NOT NULL);
INSERT #CsvFaultIdentity VALUES(OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells')));
DECLARE @TargetId int=(SELECT TargetId FROM #CsvFaultIdentity);
SELECT * INTO #CsvFaultColumns FROM(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultIndexes FROM(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultKeys FROM(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultChecks FROM(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) captured;
-- Identische Quelle/Ziel, HEADER, normaler Name, KeepData=0.
DECLARE @Old nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'w'),8388608),@Caught bit=0;
TRUNCATE TABLE [#CsvAliasCells];
INSERT [#CsvAliasCells] VALUES('HEADER',0,1,@Old);
IF DATALENGTH(@Old)<>16777216 THROW 55396,N'CSV alias: volle Callerbytes fehlen.',1;
IF (SELECT COUNT_BIG(*) FROM [#CsvAliasCells])<>1 OR (SELECT COUNT_BIG(*) FROM [#CsvAliasCells] WHERE DATALENGTH(RowKind)=6 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND RowOrdinal=0 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: volle Baseline fehlt.',2;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvAliasCells',@HasHeader=1,@LineEnding='CRLF',@KeepData=0,@ResultTable=N'#CsvAliasCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55308 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV alias: exakte55308-Abweisung fehlt.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
IF (SELECT COUNT_BIG(*) FROM [#CsvAliasCells])<>1 OR (SELECT COUNT_BIG(*) FROM [#CsvAliasCells] WHERE DATALENGTH(RowKind)=6 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND RowOrdinal=0 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: voller Quellen-/Zielerhalt fehlt.',8;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
DROP TABLE #CsvFaultColumns;
DROP TABLE #CsvFaultIndexes;
DROP TABLE #CsvFaultKeys;
DROP TABLE #CsvFaultChecks;
DROP TABLE #CsvFaultIdentity;
DROP TABLE [#CsvAliasCells];
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
INSERT #CsvFaultProgress VALUES(3);

GO
-- Nur synthetische Callerwerte; keine Heap- oder allgemeine Clientzusage.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
CREATE TABLE [#Csv.Dot]]Alias](RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
INSERT [#Csv.Dot]]Alias] VALUES('DATA',99,99,REPLICATE(CONVERT(nvarchar(max),N'p'),8388608));
CREATE TABLE #CsvFaultIdentity(TargetId int NOT NULL);
INSERT #CsvFaultIdentity VALUES(OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias')));
DECLARE @TargetId int=(SELECT TargetId FROM #CsvFaultIdentity);
SELECT * INTO #CsvFaultColumns FROM(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultIndexes FROM(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultKeys FROM(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultChecks FROM(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) captured;
-- Identische Quelle/Ziel, HEADER, ungewoehnlicher Name, KeepData=0.
DECLARE @Old nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'w'),8388608),@Caught bit=0;
TRUNCATE TABLE [#Csv.Dot]]Alias];
INSERT [#Csv.Dot]]Alias] VALUES('HEADER',0,1,@Old);
IF DATALENGTH(@Old)<>16777216 THROW 55396,N'CSV alias: volle Callerbytes fehlen.',1;
IF (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias])<>1 OR (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias] WHERE DATALENGTH(RowKind)=6 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND RowOrdinal=0 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: volle Baseline fehlt.',2;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#Csv.Dot]Alias',@HasHeader=1,@LineEnding='CRLF',@KeepData=0,@ResultTable=N'#Csv.Dot]Alias'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55308 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV alias: exakte55308-Abweisung fehlt.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
IF (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias])<>1 OR (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias] WHERE DATALENGTH(RowKind)=6 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND RowOrdinal=0 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: voller Quellen-/Zielerhalt fehlt.',8;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
DROP TABLE #CsvFaultColumns;
DROP TABLE #CsvFaultIndexes;
DROP TABLE #CsvFaultKeys;
DROP TABLE #CsvFaultChecks;
DROP TABLE #CsvFaultIdentity;
DROP TABLE [#Csv.Dot]]Alias];
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
INSERT #CsvFaultProgress VALUES(4);

GO
-- Nur synthetische Callerwerte; keine Heap- oder allgemeine Clientzusage.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
CREATE TABLE [#CsvAliasCells](RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
INSERT [#CsvAliasCells] VALUES('DATA',99,99,REPLICATE(CONVERT(nvarchar(max),N'p'),8388608));
CREATE TABLE #CsvFaultIdentity(TargetId int NOT NULL);
INSERT #CsvFaultIdentity VALUES(OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells')));
DECLARE @TargetId int=(SELECT TargetId FROM #CsvFaultIdentity);
SELECT * INTO #CsvFaultColumns FROM(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultIndexes FROM(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultKeys FROM(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultChecks FROM(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) captured;
-- Identische Quelle/Ziel, DATA, normaler Name, KeepData=1.
DECLARE @Old nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'w'),8388608),@Caught bit=0;
TRUNCATE TABLE [#CsvAliasCells];
INSERT [#CsvAliasCells] VALUES('DATA',1,1,@Old);
IF DATALENGTH(@Old)<>16777216 THROW 55396,N'CSV alias: volle Callerbytes fehlen.',1;
IF (SELECT COUNT_BIG(*) FROM [#CsvAliasCells])<>1 OR (SELECT COUNT_BIG(*) FROM [#CsvAliasCells] WHERE DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND RowOrdinal=1 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: volle Baseline fehlt.',2;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvAliasCells',@HasHeader=0,@LineEnding='CRLF',@KeepData=1,@ResultTable=N'#CsvAliasCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55308 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV alias: exakte55308-Abweisung fehlt.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
IF (SELECT COUNT_BIG(*) FROM [#CsvAliasCells])<>1 OR (SELECT COUNT_BIG(*) FROM [#CsvAliasCells] WHERE DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND RowOrdinal=1 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: voller Quellen-/Zielerhalt fehlt.',8;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
DROP TABLE #CsvFaultColumns;
DROP TABLE #CsvFaultIndexes;
DROP TABLE #CsvFaultKeys;
DROP TABLE #CsvFaultChecks;
DROP TABLE #CsvFaultIdentity;
DROP TABLE [#CsvAliasCells];
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
INSERT #CsvFaultProgress VALUES(5);

GO
-- Nur synthetische Callerwerte; keine Heap- oder allgemeine Clientzusage.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
CREATE TABLE [#Csv.Dot]]Alias](RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
INSERT [#Csv.Dot]]Alias] VALUES('DATA',99,99,REPLICATE(CONVERT(nvarchar(max),N'p'),8388608));
CREATE TABLE #CsvFaultIdentity(TargetId int NOT NULL);
INSERT #CsvFaultIdentity VALUES(OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias')));
DECLARE @TargetId int=(SELECT TargetId FROM #CsvFaultIdentity);
SELECT * INTO #CsvFaultColumns FROM(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultIndexes FROM(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultKeys FROM(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultChecks FROM(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) captured;
-- Identische Quelle/Ziel, DATA, ungewoehnlicher Name, KeepData=1.
DECLARE @Old nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'w'),8388608),@Caught bit=0;
TRUNCATE TABLE [#Csv.Dot]]Alias];
INSERT [#Csv.Dot]]Alias] VALUES('DATA',1,1,@Old);
IF DATALENGTH(@Old)<>16777216 THROW 55396,N'CSV alias: volle Callerbytes fehlen.',1;
IF (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias])<>1 OR (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias] WHERE DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND RowOrdinal=1 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: volle Baseline fehlt.',2;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#Csv.Dot]Alias',@HasHeader=0,@LineEnding='CRLF',@KeepData=1,@ResultTable=N'#Csv.Dot]Alias'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55308 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV alias: exakte55308-Abweisung fehlt.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
IF (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias])<>1 OR (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias] WHERE DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND RowOrdinal=1 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: voller Quellen-/Zielerhalt fehlt.',8;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
DROP TABLE #CsvFaultColumns;
DROP TABLE #CsvFaultIndexes;
DROP TABLE #CsvFaultKeys;
DROP TABLE #CsvFaultChecks;
DROP TABLE #CsvFaultIdentity;
DROP TABLE [#Csv.Dot]]Alias];
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
INSERT #CsvFaultProgress VALUES(6);

GO
-- Nur synthetische Callerwerte; keine Heap- oder allgemeine Clientzusage.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
CREATE TABLE [#CsvAliasCells](RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
INSERT [#CsvAliasCells] VALUES('DATA',99,99,REPLICATE(CONVERT(nvarchar(max),N'p'),8388608));
CREATE TABLE #CsvFaultIdentity(TargetId int NOT NULL);
INSERT #CsvFaultIdentity VALUES(OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells')));
DECLARE @TargetId int=(SELECT TargetId FROM #CsvFaultIdentity);
SELECT * INTO #CsvFaultColumns FROM(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultIndexes FROM(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultKeys FROM(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultChecks FROM(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) captured;
-- Identische Quelle/Ziel, HEADER, normaler Name, KeepData=1.
DECLARE @Old nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'w'),8388608),@Caught bit=0;
TRUNCATE TABLE [#CsvAliasCells];
INSERT [#CsvAliasCells] VALUES('HEADER',0,1,@Old);
IF DATALENGTH(@Old)<>16777216 THROW 55396,N'CSV alias: volle Callerbytes fehlen.',1;
IF (SELECT COUNT_BIG(*) FROM [#CsvAliasCells])<>1 OR (SELECT COUNT_BIG(*) FROM [#CsvAliasCells] WHERE DATALENGTH(RowKind)=6 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND RowOrdinal=0 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: volle Baseline fehlt.',2;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvAliasCells',@HasHeader=1,@LineEnding='CRLF',@KeepData=1,@ResultTable=N'#CsvAliasCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55308 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV alias: exakte55308-Abweisung fehlt.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
IF (SELECT COUNT_BIG(*) FROM [#CsvAliasCells])<>1 OR (SELECT COUNT_BIG(*) FROM [#CsvAliasCells] WHERE DATALENGTH(RowKind)=6 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND RowOrdinal=0 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: voller Quellen-/Zielerhalt fehlt.',8;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#CsvAliasCells'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
DROP TABLE #CsvFaultColumns;
DROP TABLE #CsvFaultIndexes;
DROP TABLE #CsvFaultKeys;
DROP TABLE #CsvFaultChecks;
DROP TABLE #CsvFaultIdentity;
DROP TABLE [#CsvAliasCells];
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
INSERT #CsvFaultProgress VALUES(7);

GO
-- Nur synthetische Callerwerte; keine Heap- oder allgemeine Clientzusage.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
CREATE TABLE [#Csv.Dot]]Alias](RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
INSERT [#Csv.Dot]]Alias] VALUES('DATA',99,99,REPLICATE(CONVERT(nvarchar(max),N'p'),8388608));
CREATE TABLE #CsvFaultIdentity(TargetId int NOT NULL);
INSERT #CsvFaultIdentity VALUES(OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias')));
DECLARE @TargetId int=(SELECT TargetId FROM #CsvFaultIdentity);
SELECT * INTO #CsvFaultColumns FROM(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultIndexes FROM(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultKeys FROM(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) captured;
SELECT * INTO #CsvFaultChecks FROM(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) captured;
-- Identische Quelle/Ziel, HEADER, ungewoehnlicher Name, KeepData=1.
DECLARE @Old nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'w'),8388608),@Caught bit=0;
TRUNCATE TABLE [#Csv.Dot]]Alias];
INSERT [#Csv.Dot]]Alias] VALUES('HEADER',0,1,@Old);
IF DATALENGTH(@Old)<>16777216 THROW 55396,N'CSV alias: volle Callerbytes fehlen.',1;
IF (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias])<>1 OR (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias] WHERE DATALENGTH(RowKind)=6 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND RowOrdinal=0 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: volle Baseline fehlt.',2;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#Csv.Dot]Alias',@HasHeader=1,@LineEnding='CRLF',@KeepData=1,@ResultTable=N'#Csv.Dot]Alias'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55308 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV alias: exakte55308-Abweisung fehlt.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
IF (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias])<>1 OR (SELECT COUNT_BIG(*) FROM [#Csv.Dot]]Alias] WHERE DATALENGTH(RowKind)=6 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND RowOrdinal=0 AND ColumnOrdinal=1 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Old) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Old))<>1 THROW 55396,N'CSV alias: voller Quellen-/Zielerhalt fehlt.',8;
IF OBJECT_ID(N'tempdb..'+QUOTENAME(N'#Csv.Dot]Alias'))<>@TargetId THROW 55396,N'CSV fault preservation: Calleridentitaet weicht ab.',3;
IF EXISTS(SELECT * FROM #CsvFaultColumns EXCEPT SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId) OR EXISTS(SELECT column_id,CONVERT(varbinary(256),name) ColumnName,system_type_id,user_type_id,max_length,precision,scale,is_nullable,CONVERT(varbinary(256),collation_name) CollationName,is_identity,is_computed FROM tempdb.sys.columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultColumns) THROW 55396,N'CSV fault preservation: Columns-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultIndexes EXCEPT SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,CONVERT(varbinary(256),name) IndexName,type,is_unique,is_primary_key,is_unique_constraint,has_filter,filter_definition FROM tempdb.sys.indexes WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultIndexes) THROW 55396,N'CSV fault preservation: Indexes-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultKeys EXCEPT SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId) OR EXISTS(SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column FROM tempdb.sys.index_columns WHERE object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultKeys) THROW 55396,N'CSV fault preservation: Keys-Snapshot driftet.',4;
IF EXISTS(SELECT * FROM #CsvFaultChecks EXCEPT SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId) OR EXISTS(SELECT CONVERT(varbinary(256),name) ConstraintName,definition,is_disabled,is_not_trusted,is_not_for_replication FROM tempdb.sys.check_constraints WHERE parent_object_id=@TargetId EXCEPT SELECT * FROM #CsvFaultChecks) THROW 55396,N'CSV fault preservation: Checks-Snapshot driftet.',4;
DROP TABLE #CsvFaultColumns;
DROP TABLE #CsvFaultIndexes;
DROP TABLE #CsvFaultKeys;
DROP TABLE #CsvFaultChecks;
DROP TABLE #CsvFaultIdentity;
DROP TABLE [#Csv.Dot]]Alias];
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
INSERT #CsvFaultProgress VALUES(8);
DECLARE @Cases int=(SELECT COUNT(*) FROM #CsvFaultProgress);
IF @Cases<>8 THROW 55396,N'CSV caller names: Abschluss fehlt.',6;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV fault preservation: Transaktionszustand weicht ab.',5;
DROP TABLE #CsvFaultProgress;
SELECT CONVERT(nvarchar(32),N'CSV_SOURCE_TARGET_ALIAS_GUARDS') Fixture,CONVERT(int,@Cases) CasesPassed;
