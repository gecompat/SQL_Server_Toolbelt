-- Late map/FK faults preserve caller input/output and transaction tuple.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE dbo.SyntheticW2Safe(Id int NOT NULL PRIMARY KEY);
CREATE TABLE dbo.SyntheticW2Referenced(Id int NOT NULL PRIMARY KEY);
CREATE TABLE dbo.SyntheticW2Fk(Id int NULL CONSTRAINT FK_SyntheticW2Safe FOREIGN KEY REFERENCES dbo.SyntheticW2Referenced(Id));
CREATE TABLE #W2SafetyMap(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
INSERT #W2SafetyMap VALUES(1,N'dbo',N'SyntheticW2Safe',N'dbo',N'SyntheticW2SafeClone'),(9,N'dbo',N'SyntheticW2Fk',N'dbo',N'SyntheticW2FkClone');
CREATE TABLE #W2Prior(Ordinal int NOT NULL,ObjectKind varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,TargetName nvarchar(776) COLLATE Latin1_General_100_BIN2 NOT NULL,ScriptText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #W2Prior VALUES(-1,'SENTINEL',N'Synthetic',N'unchanged');
DECLARE @ObservedNumber int,@ObservedState int,@BeforeTC int=@@TRANCOUNT,@BeforeXS int=XACT_STATE();
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2SafetyMap',@ResultTable=N'#W2Prior'; END TRY
BEGIN CATCH SELECT @ObservedNumber=ERROR_NUMBER(),@ObservedState=ERROR_STATE(); END CATCH;
DECLARE @ObservedTC int=@@TRANCOUNT,@ObservedXS int=XACT_STATE();
IF @ObservedNumber<>53903 OR @ObservedState<>13 OR @ObservedNumber IS NULL OR @ObservedTC<>@BeforeTC OR @ObservedXS<>@BeforeXS THROW 54933,N'W2 REJECT/transaction oracle.',1;
IF (SELECT COUNT(*) FROM #W2Prior)<>1 OR NOT EXISTS(SELECT 1 FROM #W2Prior WHERE Ordinal=-1 AND ScriptText=N'unchanged')
    OR (SELECT COUNT(*) FROM #W2SafetyMap)<>2 THROW 54933,N'W2 failed publication changed caller.',2;
-- FK EP is never silently skipped, including Include1.
DECLARE @SyntheticFkProperty int=7;
EXEC sys.sp_addextendedproperty @name=N'SyntheticFkProperty',@value=@SyntheticFkProperty,@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticW2Fk',@level2type=N'CONSTRAINT',@level2name=N'FK_SyntheticW2Safe';
SET @ObservedNumber=NULL; SET @ObservedState=NULL;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2SafetyMap',@ExternalReferenceRule='KEEP',@IncludeExtendedProperties=1,@ResultTable=N'#W2Prior'; END TRY
BEGIN CATCH SELECT @ObservedNumber=ERROR_NUMBER(),@ObservedState=ERROR_STATE(); END CATCH;
IF @ObservedNumber IS NULL OR @ObservedNumber<>53903 OR @ObservedState<>10 THROW 54933,N'W2 FK-property gate.',3;
EXEC sys.sp_dropextendedproperty @name=N'SyntheticFkProperty',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticW2Fk',@level2type=N'CONSTRAINT',@level2name=N'FK_SyntheticW2Safe';
-- Same-object routing rejects before any caller mutation.
SET @ObservedNumber=NULL;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2SafetyMap',@ResultTable=N'#W2SafetyMap',@ExternalReferenceRule='KEEP'; END TRY BEGIN CATCH SET @ObservedNumber=ERROR_NUMBER(); END CATCH;
IF @ObservedNumber IS NULL OR @ObservedNumber<>53900 THROW 54933,N'W2 input/output alias gate.',4;
-- Actual resolved source identity, not text case, detects aliases.
INSERT #W2SafetyMap VALUES(11,N'dbo',N'SyntheticW2Safe',N'dbo',N'SyntheticW2OtherClone');
SET @ObservedNumber=NULL;SET @ObservedState=NULL;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2SafetyMap',@ExternalReferenceRule='KEEP',@ResultTable=N'#W2Prior'; END TRY BEGIN CATCH SELECT @ObservedNumber=ERROR_NUMBER(),@ObservedState=ERROR_STATE(); END CATCH;
IF @ObservedNumber IS NULL OR @ObservedNumber<>53900 OR @ObservedState<>9 THROW 54933,N'W2 duplicate source identity.',5;
DELETE #W2SafetyMap WHERE MapOrdinal=11;
-- Distinct sources with the same catalog target are also rejected before publication.
UPDATE #W2SafetyMap SET TargetTable=N'SyntheticW2SameTarget';
SET @ObservedNumber=NULL;SET @ObservedState=NULL;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2SafetyMap',@ExternalReferenceRule='KEEP',@ResultTable=N'#W2Prior'; END TRY BEGIN CATCH SELECT @ObservedNumber=ERROR_NUMBER(),@ObservedState=ERROR_STATE(); END CATCH;
IF @ObservedNumber IS NULL OR @ObservedNumber<>53900 OR @ObservedState<>9 THROW 54933,N'W2 target identity collision.',7;
-- Help ignores an invalid map/rule/output and NULL flags without touching either caller object.
EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1,@TableMap=N'##Invalid',@ExternalReferenceRule=NULL,@IncludeIdentity=NULL,@IncludeExtendedProperties=NULL,@ResultTable=N'#W2SafetyMap';

IF (SELECT COUNT(*) FROM #W2Prior)<>1 OR NOT EXISTS(SELECT 1 FROM #W2Prior WHERE Ordinal=-1 AND ScriptText=N'unchanged') THROW 54933,N'W2 negative output preserved.',6;
DROP TABLE dbo.SyntheticW2Fk;DROP TABLE dbo.SyntheticW2Referenced;DROP TABLE dbo.SyntheticW2Safe;
PRINT N'PASS W2_SAFETY';
