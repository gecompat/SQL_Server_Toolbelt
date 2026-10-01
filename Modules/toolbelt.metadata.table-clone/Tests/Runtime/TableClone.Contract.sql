SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.SyntheticCloneSource
(
    IdentityValue bigint IDENTITY(7,3) NOT NULL,
    Code varchar(31) COLLATE Latin1_General_100_BIN2 NOT NULL,
    Amount decimal(19,4) NULL CONSTRAINT DF_SyntheticCloneSource_Amount DEFAULT(1.25),
    Note nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
    Created datetime2(3) NOT NULL CONSTRAINT DF_SyntheticCloneSource_Created DEFAULT('2001-02-03'),
    CONSTRAINT PK_SyntheticCloneSource PRIMARY KEY CLUSTERED(IdentityValue),
    CONSTRAINT UQ_SyntheticCloneSource UNIQUE NONCLUSTERED(Code DESC),
    CONSTRAINT CK_SyntheticCloneSource CHECK(Amount>=0)
);
CREATE NONCLUSTERED INDEX IX_SyntheticCloneSource_Amount ON dbo.SyntheticCloneSource(Amount DESC,Code ASC)
    INCLUDE(Note) WITH(FILLFACTOR=80,PAD_INDEX=ON,ALLOW_PAGE_LOCKS=OFF);
INSERT dbo.SyntheticCloneSource(Code,Amount) VALUES('one',1),('two',2);
CREATE TABLE #ClonePlan(Dummy int);
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'SyntheticCloneTarget',1,@ResultTable=N'#ClonePlan';
IF OBJECT_ID(N'dbo.SyntheticCloneTarget') IS NOT NULL THROW 54900,N'Planner executed DDL.',1;
IF (SELECT COUNT(*) FROM #ClonePlan)<>7 OR EXISTS(SELECT 1 FROM #ClonePlan WHERE Ordinal IS NULL OR ScriptText IS NULL)
    THROW 54900,N'Incomplete plan.',2;
CREATE TABLE #CloneRepeat(Dummy int);
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'SyntheticCloneTarget',1,@ResultTable=N'#CloneRepeat';
IF EXISTS(SELECT Ordinal,ObjectKind,CONVERT(varbinary(max),TargetName),CONVERT(varbinary(max),ScriptText) FROM #ClonePlan
          EXCEPT SELECT Ordinal,ObjectKind,CONVERT(varbinary(max),TargetName),CONVERT(varbinary(max),ScriptText) FROM #CloneRepeat)
    THROW 54900,N'Plan is not deterministic.',3;
-- Nur synthetischer Test führt Vorschautext aus; öffentliche API tut dies niemals.
DECLARE @Ordinal int=1,@Script nvarchar(max);
WHILE @Ordinal<=(SELECT COUNT(*) FROM #ClonePlan)
BEGIN
    SELECT @Script=ScriptText FROM #ClonePlan WHERE Ordinal=@Ordinal;
    EXEC sys.sp_executesql @Script;
    SET @Ordinal+=1;
END;
DECLARE @Source int=OBJECT_ID(N'dbo.SyntheticCloneSource'),@Clone int=OBJECT_ID(N'dbo.SyntheticCloneTarget');
IF EXISTS(SELECT name,system_type_id,max_length,precision,scale,collation_name,is_nullable,is_identity FROM sys.columns WHERE object_id=@Source
          EXCEPT SELECT name,system_type_id,max_length,precision,scale,collation_name,is_nullable,is_identity FROM sys.columns WHERE object_id=@Clone)
   OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=@Source)<>(SELECT COUNT(*) FROM sys.columns WHERE object_id=@Clone)
    THROW 54900,N'Column structure differs.',4;
IF EXISTS(SELECT seed_value,increment_value FROM sys.identity_columns WHERE object_id=@Source
          EXCEPT SELECT seed_value,increment_value FROM sys.identity_columns WHERE object_id=@Clone)
   OR EXISTS(SELECT 1 FROM sys.identity_columns WHERE object_id=@Clone AND last_value IS NOT NULL)
    THROW 54900,N'Identity seed/increment/current value contract failed.',5;
IF (SELECT COUNT(*) FROM sys.indexes WHERE object_id=@Source)<>(SELECT COUNT(*) FROM sys.indexes WHERE object_id=@Clone)
    THROW 54900,N'Index count differs.',6;
IF EXISTS(SELECT type,is_unique,is_primary_key,is_unique_constraint,CASE WHEN fill_factor=0 THEN 100 ELSE fill_factor END,is_padded,ignore_dup_key,allow_row_locks,allow_page_locks
          FROM sys.indexes WHERE object_id=@Source
          EXCEPT SELECT type,is_unique,is_primary_key,is_unique_constraint,CASE WHEN fill_factor=0 THEN 100 ELSE fill_factor END,is_padded,ignore_dup_key,allow_row_locks,allow_page_locks
          FROM sys.indexes WHERE object_id=@Clone)
    THROW 54900,N'Index options differ.',7;
-- Schlüsselrichtung, INCLUDE und Spaltennamen je semantischer Indexgruppe.
-- Keine Gleichsetzung über veränderliche index_id/Constraintnamen.
DECLARE @IndexShape TABLE(IsSource bit,IndexType tinyint,IsUnique bit,IsPrimary bit,IsConstraint bit,ColumnsText nvarchar(max));
INSERT @IndexShape
SELECT CASE WHEN i.object_id=@Source THEN 1 ELSE 0 END,i.type,i.is_unique,i.is_primary_key,i.is_unique_constraint,
    STRING_AGG(CONVERT(nvarchar(max),CONCAT(DATALENGTH(c.name),N':',c.name,N':',ic.key_ordinal,N':',ic.is_descending_key,N':',ic.is_included_column)),N';')
        WITHIN GROUP(ORDER BY ic.is_included_column,ic.key_ordinal,ic.index_column_id)
FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE i.object_id IN(@Source,@Clone) AND i.index_id>0 AND (ic.key_ordinal>0 OR ic.is_included_column=1)
GROUP BY i.object_id,i.index_id,i.type,i.is_unique,i.is_primary_key,i.is_unique_constraint;
IF EXISTS(SELECT IndexType,IsUnique,IsPrimary,IsConstraint,ColumnsText FROM @IndexShape WHERE IsSource=1
    EXCEPT SELECT IndexType,IsUnique,IsPrimary,IsConstraint,ColumnsText FROM @IndexShape WHERE IsSource=0)
   OR EXISTS(SELECT IndexType,IsUnique,IsPrimary,IsConstraint,ColumnsText FROM @IndexShape WHERE IsSource=0
    EXCEPT SELECT IndexType,IsUnique,IsPrimary,IsConstraint,ColumnsText FROM @IndexShape WHERE IsSource=1)
    THROW 54900,N'Index keys/include/direction differ.',35;
IF EXISTS(SELECT definition FROM sys.default_constraints WHERE parent_object_id=@Source
          EXCEPT SELECT definition FROM sys.default_constraints WHERE parent_object_id=@Clone)
   OR EXISTS(SELECT definition,is_disabled,is_not_trusted FROM sys.check_constraints WHERE parent_object_id=@Source
          EXCEPT SELECT definition,is_disabled,is_not_trusted FROM sys.check_constraints WHERE parent_object_id=@Clone)
    THROW 54900,N'Default/check definitions differ.',8;
IF EXISTS(SELECT 1 FROM dbo.SyntheticCloneTarget) THROW 54900,N'Rows copied.',9;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'SyntheticCloneTarget'; THROW 54900,N'Existing target accepted.',10; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53902 THROW; END CATCH;
CREATE TABLE #CloneNoIdentity(Dummy int);
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'SyntheticCloneWithoutIdentity',0,@ResultTable=N'#CloneNoIdentity';
IF EXISTS(SELECT 1 FROM #CloneNoIdentity WHERE ObjectKind='TABLE' AND ScriptText LIKE N'%IDENTITY(%') THROW 54900,N'Identity0 retained identity.',11;
-- Replace/Append sowie leeres unpassendes, befülltes unpassendes und blocked Schema.
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'SyntheticCloneWithoutIdentity',0,@ResultTable=N'#CloneNoIdentity',@KeepData=1;
IF (SELECT COUNT(*) FROM #CloneNoIdentity)<>14 THROW 54900,N'Append failed.',12;
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'SyntheticCloneWithoutIdentity',0,@ResultTable=N'#CloneNoIdentity',@KeepData=0;
IF (SELECT COUNT(*) FROM #CloneNoIdentity)<>7 THROW 54900,N'Replace failed.',13;
CREATE TABLE #CloneWrong(Dummy int); INSERT #CloneWrong VALUES(19);
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'UnusedClone',@ResultTable=N'#CloneWrong',@KeepData=1; THROW 54900,N'Wrong append accepted.',14; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>51025 THROW; END CATCH;
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'UnusedClone',@ResultTable=N'#CloneWrong';
IF COL_LENGTH(N'tempdb..#CloneWrong',N'ScriptText') IS NULL THROW 54900,N'Wrong schema not replaced.',15;
CREATE TABLE #CloneBlocked(Dummy int PRIMARY KEY); INSERT #CloneBlocked VALUES(29);
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'UnusedClone',@ResultTable=N'#CloneBlocked'; THROW 54900,N'Blocker ignored.',16; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>51026 THROW; END CATCH;
IF (SELECT Dummy FROM #CloneBlocked)<>29 THROW 54900,N'Blocked target changed.',17;
CREATE TABLE #CloneConstrained(Ordinal int NOT NULL CHECK(Ordinal<0),ObjectKind varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
    TargetName nvarchar(776) COLLATE Latin1_General_100_BIN2 NOT NULL,ScriptText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #CloneConstrained VALUES(-1,'TABLE',N'old',N'old');
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'UnusedClone',@ResultTable=N'#CloneConstrained'; THROW 54900,N'Constraint accepted.',18; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>547 THROW; END CATCH;
IF @@TRANCOUNT<>0 OR (SELECT COUNT(*) FROM #CloneConstrained)<>1 OR (SELECT Ordinal FROM #CloneConstrained)<>-1
    THROW 54900,N'Own transaction restoration failed.',19;
BEGIN TRANSACTION;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'UnusedClone',@ResultTable=N'#CloneConstrained'; THROW 54900,N'Caller constraint accepted.',20; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>547 THROW; END CATCH;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR (SELECT Ordinal FROM #CloneConstrained)<>-1 THROW 54900,N'Caller savepoint failed.',21;
ROLLBACK TRANSACTION;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'UnusedClone',@ResultTable=N'#CloneConstrained'; THROW 54900,N'Doomed constraint accepted.',36; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>547 THROW; END CATCH;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>-1 THROW 54900,N'Doomed caller state not preserved.',37;
ROLLBACK TRANSACTION;
SET XACT_ABORT OFF;
-- Unsupported muss vor Zielmutation abbrechen.
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone @ResultTable=N'#tbx_TableClone_Plan'; THROW 54900,N'Reserved output accepted.',40; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53908 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone @ResultTable=N'#TBX_TableClone_Plan'; THROW 54900,N'Uppercase reserved output accepted.',41; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53908 THROW; END CATCH;
CREATE TABLE dbo.SyntheticSequential(Id int PRIMARY KEY WITH(OPTIMIZE_FOR_SEQUENTIAL_KEY=ON));
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticSequential',N'dbo',N'UnusedClone',@ResultTable=N'#CloneBlocked'; THROW 54900,N'Sequential-key option accepted.',42; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
IF (SELECT Dummy FROM #CloneBlocked)<>29 THROW 54900,N'Sequential-key rejection mutated target.',43;
DROP TABLE dbo.SyntheticSequential;
CREATE TABLE dbo.SyntheticUnsupported(Id int,Calculated AS Id+1);
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticUnsupported',N'dbo',N'UnusedClone',@ResultTable=N'#CloneBlocked'; THROW 54900,N'Computed accepted.',22; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
IF (SELECT Dummy FROM #CloneBlocked)<>29 THROW 54900,N'Unsupported mutated target.',23;
DROP TABLE dbo.SyntheticUnsupported;
CREATE TABLE dbo.SyntheticUnsupported(Id int); CREATE INDEX IX_SyntheticUnsupported ON dbo.SyntheticUnsupported(Id) WHERE Id>0;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticUnsupported',N'dbo',N'UnusedClone'; THROW 54900,N'Filtered index accepted.',24; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
DROP TABLE dbo.SyntheticUnsupported;
CREATE TABLE dbo.SyntheticUnsupported(Id int SPARSE NULL);
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticUnsupported',N'dbo',N'UnusedClone'; THROW 54900,N'Sparse accepted.',25; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
DROP TABLE dbo.SyntheticUnsupported;
DECLARE @Long nvarchar(max)=REPLICATE(N'a',129),@Nul nvarchar(max)=N'a'+NCHAR(0)+N'b';
CREATE TABLE dbo.SyntheticUnsupported(Id int CONSTRAINT CK_SyntheticUnsupported CHECK(Id>0));
ALTER TABLE dbo.SyntheticUnsupported NOCHECK CONSTRAINT CK_SyntheticUnsupported;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticUnsupported',N'dbo',N'UnusedClone'; THROW 54900,N'Disabled check accepted.',30; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
DROP TABLE dbo.SyntheticUnsupported;
CREATE TABLE dbo.SyntheticUnsupported(Id int);
EXEC sys.sp_addextendedproperty @name=N'SyntheticProperty',@value=N'synthetic',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticUnsupported';
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticUnsupported',N'dbo',N'UnusedClone'; THROW 54900,N'Extended Property accepted.',31; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
DROP TABLE dbo.SyntheticUnsupported;
CREATE TABLE dbo.SyntheticUnsupported(Id int);
EXEC sys.sp_executesql N'CREATE TRIGGER dbo.SyntheticUnsupportedTrigger ON dbo.SyntheticUnsupported AFTER INSERT AS RETURN;';
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticUnsupported',N'dbo',N'UnusedClone'; THROW 54900,N'Trigger accepted.',32; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
DROP TABLE dbo.SyntheticUnsupported;
CREATE TABLE dbo.SyntheticUnsupported(Id int PRIMARY KEY);
CREATE TABLE dbo.SyntheticForeign(Id int CONSTRAINT FK_SyntheticForeign FOREIGN KEY REFERENCES dbo.SyntheticUnsupported(Id));
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticUnsupported',N'dbo',N'UnusedClone'; THROW 54900,N'Incoming FK accepted.',33; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
DROP TABLE dbo.SyntheticForeign; DROP TABLE dbo.SyntheticUnsupported;
CREATE TABLE dbo.SyntheticUnsupported(Id int) WITH(DATA_COMPRESSION=PAGE);
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticUnsupported',N'dbo',N'UnusedClone'; THROW 54900,N'Compression accepted.',34; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
DROP TABLE dbo.SyntheticUnsupported;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',@Long; THROW 54900,N'Long name truncated.',26; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53900 THROW; END CATCH;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',@Nul; THROW 54900,N'NUL accepted.',27; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53900 THROW; END CATCH;
CREATE TABLE dbo.SyntheticQuoted([a]]b] nvarchar(4) NULL);
CREATE TABLE #CloneQuoted(Dummy int);
DECLARE @QuotedTarget nvarchar(max)=N'clone]; THROW 54900,N''injection'',1;--';
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticQuoted',N'dbo',@QuotedTarget,@ResultTable=N'#CloneQuoted';
SELECT @Script=ScriptText FROM #CloneQuoted WHERE Ordinal=1; EXEC sys.sp_executesql @Script;
IF OBJECT_ID(QUOTENAME(N'dbo')+N'.'+QUOTENAME(@QuotedTarget),N'U') IS NULL THROW 54900,N'Identifier quoting failed.',28;
SET @Script=N'DROP TABLE dbo.'+QUOTENAME(@QuotedTarget); EXEC sys.sp_executesql @Script;
DROP TABLE dbo.SyntheticQuoted;
-- Maximale128-Codeeinheiten ohne Constraint: kein stilles Trunkieren.
SET @Long=REPLICATE(N'x',128);
CREATE TABLE dbo.SyntheticQuoted(Id int);
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticQuoted',N'dbo',@Long,@ResultTable=N'#CloneQuoted';
SELECT @Script=ScriptText FROM #CloneQuoted WHERE Ordinal=1; EXEC sys.sp_executesql @Script;
SET @Script=N'DROP TABLE dbo.'+QUOTENAME(@Long); EXEC sys.sp_executesql @Script;
DROP TABLE dbo.SyntheticQuoted;
-- Deterministische Constraint-Kollision im Zielschema.
DECLARE @CollisionName sysname;
SELECT TOP(1) @CollisionName=PARSENAME(TargetName,1) FROM #CloneNoIdentity WHERE ObjectKind='DEFAULT';
SET @Script=N'CREATE TABLE dbo.SyntheticNameBlocker(Id int CONSTRAINT '+QUOTENAME(@CollisionName)+N' DEFAULT0);';
SET @Script=REPLACE(@Script,N'DEFAULT0',N'DEFAULT(0)'); EXEC sys.sp_executesql @Script;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCloneSource',N'dbo',N'SyntheticCloneWithoutIdentity'; THROW 54900,N'Name collision ignored.',29; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>53904 THROW; END CATCH;
DROP TABLE dbo.SyntheticNameBlocker;
DROP TABLE dbo.SyntheticCloneTarget;
DROP TABLE dbo.SyntheticCloneSource;
